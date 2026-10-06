import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/files/durable_file_store.dart';
import '../../../core/sync/outbox_service.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../core/sync/sync_models.dart';
import 'local/attendance_local_data_source.dart';
import 'local/attendance_projection.dart';
import 'models/attendance_operation_payload.dart';
import 'models/effective_today_attendance.dart';
import 'workforce_repository.dart';

class AttendanceRepository {
  AttendanceRepository({
    required SyncScope scope,
    required WorkforceRepository remote,
    required AttendanceLocalDataSource local,
    required AppDatabase database,
    required OutboxService outbox,
    required SyncCoordinator coordinator,
    required DurableFileStore fileStore,
    Uuid? uuid,
  }) : _scope = scope,
       _remote = remote,
       _local = local,
       _database = database,
       _outbox = outbox,
       _coordinator = coordinator,
       _fileStore = fileStore,
       _uuid = uuid ?? const Uuid();

  final SyncScope _scope;
  final WorkforceRepository _remote;
  final AttendanceLocalDataSource _local;
  final AppDatabase _database;
  final OutboxService _outbox;
  final SyncCoordinator _coordinator;
  final DurableFileStore _fileStore;
  final Uuid _uuid;
  bool _attendanceMutationInProgress = false;

  Stream<EffectiveTodayAttendance> watchToday(DateTime workDate) =>
      _local.watchEffectiveToday(_scope, workDate: workDate);

  Future<EffectiveTodayAttendance> fetchToday() async {
    final snapshot = await _remote.fetchTodayAttendance();
    await _local.putTodaySnapshot(scope: _scope, attendance: snapshot);
    final operations = await _database.listAttendanceOperations(_scope);
    return AttendanceProjection.project(
      snapshot: snapshot,
      operations: operations,
      hasApprovedOvertimeReferences: false,
      lastUpdatedAt: DateTime.now().toUtc(),
    );
  }

  Stream<List<AttendanceOvertimeReference>> watchApprovedOvertimeReferences(
    DateTime workDate,
  ) => _local.watchApprovedReferences(_scope, workDate);

  Future<AttendanceEnqueueResult> enqueueCheckIn({
    required AttendanceCapture capture,
    required AttendanceType type,
    String? overtimeId,
    String? overtimeLabel,
  }) async {
    if (_attendanceMutationInProgress) {
      return const AttendanceStoreFailed(
        'Presensi sedang diproses. Tunggu sebentar lalu coba lagi.',
      );
    }
    _attendanceMutationInProgress = true;
    try {
      return await _enqueueCheckIn(
        capture: capture,
        type: type,
        overtimeId: overtimeId,
        overtimeLabel: overtimeLabel,
      );
    } finally {
      _attendanceMutationInProgress = false;
    }
  }

  Future<AttendanceEnqueueResult> _enqueueCheckIn({
    required AttendanceCapture capture,
    required AttendanceType type,
    String? overtimeId,
    String? overtimeLabel,
  }) async {
    if (type == AttendanceType.overtime &&
        (overtimeId == null || overtimeId.isEmpty)) {
      return const AttendanceStoreFailed(
        'Jadwal lembur approved belum tersedia di perangkat.',
      );
    }

    final today = await _local
        .watchEffectiveToday(_scope, workDate: DateTime.now())
        .first;
    final openPresence = today.openPresence;
    if (openPresence != null) {
      return _activeSessionFailure(openPresence.type);
    }
    if (today.hasCompletedOvertime) {
      return const AttendanceStoreFailed(
        'Presensi lembur hari ini sudah selesai.',
      );
    }

    final localTransition = await _localTransitionState();
    if (localTransition.openType case final AttendanceType openType) {
      return _activeSessionFailure(openType);
    }
    return _enqueue(
      capture: capture,
      action: AttendanceAction.checkIn,
      type: type,
      sessionId: _uuid.v4(),
      overtimeId: overtimeId,
      overtimeLabel: overtimeLabel,
      dependsOnOperationId: localTransition.checkoutDependency,
    );
  }

  Future<AttendanceEnqueueResult> enqueueCheckOut({
    required AttendanceCapture capture,
    required EffectivePresence session,
  }) async {
    if (_attendanceMutationInProgress) {
      return const AttendanceStoreFailed(
        'Presensi sedang diproses. Tunggu sebentar lalu coba lagi.',
      );
    }
    _attendanceMutationInProgress = true;
    try {
      return await _enqueueCheckOut(capture: capture, session: session);
    } finally {
      _attendanceMutationInProgress = false;
    }
  }

  Future<AttendanceEnqueueResult> _enqueueCheckOut({
    required AttendanceCapture capture,
    required EffectivePresence session,
  }) async {
    if (!session.hasOpenAttendance) {
      return const AttendanceStoreFailed('Tidak ada sesi presensi aktif.');
    }
    final sessionId = session.clientSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return const AttendanceStoreFailed(
        'Sesi check-in belum memiliki clientSessionId. '
        'Muat ulang presensi saat online sebelum melakukan check-out.',
      );
    }
    String? dependency;
    if (session.checkInOperationId != null) {
      final operations = await _database.listAttendanceOperations(_scope);
      final checkIn = operations
          .where((item) => item.operationId == session.checkInOperationId)
          .firstOrNull;
      if (checkIn != null && checkIn.state != OutboxState.done.name) {
        dependency = checkIn.operationId;
      }
    }
    return _enqueue(
      capture: capture,
      action: AttendanceAction.checkOut,
      type: session.type,
      sessionId: sessionId,
      overtimeId: session.overtimeId,
      dependsOnOperationId: dependency,
    );
  }

  Future<({AttendanceType? openType, String? checkoutDependency})>
  _localTransitionState() async {
    final operations = await _database.listAttendanceOperations(_scope);
    final sessions =
        <String, List<(OutboxOperation, AttendanceOperationPayload)>>{};
    for (final operation in operations) {
      try {
        final decoded = jsonDecode(operation.payloadJson);
        if (decoded is! Map<String, dynamic>) continue;
        final payload = AttendanceOperationPayload.fromJson(decoded);
        sessions.putIfAbsent(payload.clientSessionId, () => []).add((
          operation,
          payload,
        ));
      } catch (_) {
        // Malformed legacy operations cannot determine an active session.
      }
    }

    String? checkoutDependency;
    DateTime? checkoutCreatedAt;
    for (final items in sessions.values) {
      items.sort((left, right) {
        final occurred = left.$2.occurredAt.compareTo(right.$2.occurredAt);
        return occurred != 0
            ? occurred
            : left.$1.createdAt.compareTo(right.$1.createdAt);
      });
      final last = items.last;
      if (last.$2.action == AttendanceAction.checkIn &&
          last.$1.state != OutboxState.done.name) {
        return (openType: last.$2.type, checkoutDependency: null);
      }
      if (last.$2.action == AttendanceAction.checkOut &&
          last.$1.state != OutboxState.done.name &&
          (checkoutCreatedAt == null ||
              last.$1.createdAt.isAfter(checkoutCreatedAt))) {
        checkoutDependency = last.$1.operationId;
        checkoutCreatedAt = last.$1.createdAt;
      }
    }
    return (openType: null, checkoutDependency: checkoutDependency);
  }

  AttendanceStoreFailed _activeSessionFailure(AttendanceType type) {
    final activeLabel = type == AttendanceType.regular ? 'regular' : 'lembur';
    return AttendanceStoreFailed(
      'Selesaikan check-out $activeLabel sebelum memulai presensi lain.',
    );
  }

  Future<AttendanceEnqueueResult> _enqueue({
    required AttendanceCapture capture,
    required AttendanceAction action,
    required AttendanceType type,
    required String sessionId,
    String? overtimeId,
    String? overtimeLabel,
    String? dependsOnOperationId,
  }) async {
    final occurredAt = capture.occurredAt ?? DateTime.now();
    final payload = AttendanceOperationPayload(
      clientSessionId: sessionId,
      action: action,
      type: type,
      overtimeId: overtimeId,
      overtimeLabel: overtimeLabel,
      occurredAt: occurredAt,
      timezoneOffsetMinutes: occurredAt.timeZoneOffset.inMinutes,
      latitude: capture.latitude,
      longitude: capture.longitude,
      accuracyMeters: capture.accuracyMeters,
      isMocked: capture.isMocked,
    );
    try {
      final operationId = await _outbox.enqueue(
        EnqueueOperationInput(
          scope: _scope,
          operationType: action == AttendanceAction.checkIn
              ? SyncOperationType.attendanceCheckIn
              : SyncOperationType.attendanceCheckOut,
          targetResourceKey:
              'attendance:${_scope.accountId}:${type.name}:$sessionId',
          endpoint: action == AttendanceAction.checkIn
              ? '/v1/mobile/attendance/check-in'
              : '/v1/mobile/attendance/check-out',
          payload: payload.toJson(),
          attachments: [
            AttachmentInput(
              sourcePath: capture.selfiePath,
              fieldName: 'selfie',
              mimeType: 'image/jpeg',
            ),
          ],
          dependsOnOperationId: dependsOnOperationId,
        ),
      );
      return AttendanceStored(
        operationId: operationId,
        clientSessionId: sessionId,
      );
    } catch (error) {
      return AttendanceStoreFailed(_safeMessage(error));
    }
  }

  Future<void> refreshReferences() async {
    final now = DateTime.now();
    final rangeStart = DateTime(now.year, now.month, now.day - 1);
    final rangeEnd = DateTime(now.year, now.month, now.day + 3);
    Object? firstError;
    StackTrace? firstStack;
    try {
      final snapshot = await _remote.fetchTodayAttendance();
      await _local.putTodaySnapshot(scope: _scope, attendance: snapshot);
    } catch (error, stack) {
      firstError = error;
      firstStack = stack;
    }
    try {
      final records = await _remote.fetchAllApprovedOvertimeReferences(
        startDate: rangeStart,
        endDate: rangeEnd,
      );
      await _local.replaceOvertimeReferences(
        scope: _scope,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        records: records,
      );
    } catch (error, stack) {
      firstError ??= error;
      firstStack ??= stack;
    }
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }

  Future<void> requestSync() => _coordinator.syncNow(SyncTrigger.userInitiated);

  Future<void> deleteRejected(String operationId) async {
    final attachments = await _database.attachmentsFor(operationId);
    await _database.deleteRejectedOperation(operationId);
    for (final attachment in attachments) {
      await _fileStore.delete(attachment.durablePath);
    }
  }

  String _safeMessage(Object error) {
    final value = error.toString();
    return value
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '');
  }
}

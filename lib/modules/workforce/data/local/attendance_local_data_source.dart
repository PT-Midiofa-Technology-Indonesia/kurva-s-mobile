import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_models.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../models/attendance_operation_payload.dart';
import '../models/attendance_list.dart';
import '../models/effective_today_attendance.dart';
import '../models/local_attendance_record.dart';
import '../models/overtime.dart';
import '../models/today_attendance.dart';
import 'attendance_projection.dart';

class AttendanceLocalDataSource {
  const AttendanceLocalDataSource({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Stream<List<LocalAttendanceRecord>> watchPendingRecords(SyncScope scope) {
    return _database.watchAttendanceOperations(scope).map((operations) {
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
          // Ignore malformed legacy operations; they cannot form a list item.
        }
      }

      final records = <LocalAttendanceRecord>[];
      for (final entry in sessions.entries) {
        final items = entry.value
          ..sort(
            (left, right) => left.$2.occurredAt.compareTo(right.$2.occurredAt),
          );
        final states = items
            .map((item) => _outboxState(item.$1.state))
            .toList(growable: false);
        if (states.every((state) => state == OutboxState.done)) continue;

        final first = items.first.$2;
        records.add(
          LocalAttendanceRecord(
            clientSessionId: entry.key,
            type: first.type,
            occurredAt: first.occurredAt,
            checkInAt: items
                .where((item) => item.$2.action == AttendanceAction.checkIn)
                .firstOrNull
                ?.$2
                .occurredAt,
            checkOutAt: items
                .where((item) => item.$2.action == AttendanceAction.checkOut)
                .firstOrNull
                ?.$2
                .occurredAt,
            state: _aggregateState(states),
          ),
        );
      }
      records.sort(
        (left, right) => right.occurredAt.compareTo(left.occurredAt),
      );
      return records;
    });
  }

  OutboxState _outboxState(String value) => OutboxState.values.firstWhere(
    (state) => state.name == value,
    orElse: () => OutboxState.failed,
  );

  OutboxState _aggregateState(List<OutboxState> states) {
    const priority = [
      OutboxState.rejected,
      OutboxState.conflict,
      OutboxState.failed,
      OutboxState.retry,
      OutboxState.processing,
      OutboxState.pending,
      OutboxState.done,
    ];
    return priority.firstWhere(states.contains);
  }

  Future<void> putTodaySnapshot({
    required SyncScope scope,
    required TodayAttendance attendance,
  }) async {
    final fetchedAt = DateTime.now().toUtc();
    await _database.putAttendanceSnapshot(
      AttendanceDaySnapshotsCompanion.insert(
        accountId: scope.accountId,
        companyId: scope.companyId,
        attendanceDate: attendance.date.length >= 10
            ? attendance.date.substring(0, 10)
            : formatDateParam(DateTime.now())!,
        payloadJson: jsonEncode(attendance.toJson()),
        serverTime: Value(parseApiDateTime(attendance.serverTime)?.toUtc()),
        fetchedAt: fetchedAt,
      ),
    );
  }

  Future<void> putTodaySnapshotFromList({
    required SyncScope scope,
    required List<AttendanceRecord> records,
    DateTime? workDate,
  }) async {
    final date = formatDateParam(workDate ?? DateTime.now())!;
    final todaysRecords = records
        .where((record) => record.attendanceDate == date)
        .toList(growable: false);
    if (todaysRecords.isEmpty) return;

    final cachedRow = await _database.getAttendanceSnapshot(scope, date);
    TodayAttendance? cachedAttendance;
    if (cachedRow != null) {
      try {
        final json = jsonDecode(cachedRow.payloadJson);
        if (json is Map<String, dynamic>) {
          cachedAttendance = TodayAttendance.fromJson(json);
        }
      } catch (_) {
        // Riwayat masih dapat membentuk snapshot jika cache lama rusak.
      }
    }

    RegularAttendance regular =
        cachedAttendance?.regular ??
        const RegularAttendance(
          checkedIn: false,
          checkedOut: false,
          workplace: null,
        );
    OvertimeAttendance overtime =
        cachedAttendance?.overtime ??
        const OvertimeAttendance(available: false);

    for (final record in todaysRecords) {
      final checkedIn =
          record.checkIn != null || record.checkInOccurredAt != null;
      final checkedOut =
          record.checkOut != null || record.checkOutOccurredAt != null;
      if (!checkedIn && !checkedOut) continue;

      if (record.type == AttendanceType.regular.name) {
        regular = RegularAttendance(
          checkedIn: checkedIn,
          checkedOut: checkedOut,
          attendanceId: record.id,
          clientSessionId: record.clientSessionId,
          checkInOccurredAt: record.checkInOccurredAt,
          checkInSyncedAt: record.checkInSyncedAt,
          checkOutOccurredAt: record.checkOutOccurredAt,
          checkOutSyncedAt: record.checkOutSyncedAt,
          workplace: regular.workplace,
        );
      } else if (record.type == AttendanceType.overtime.name) {
        overtime = OvertimeAttendance(
          available: true,
          overtimeId: overtime.overtimeId,
          reason: overtime.reason,
          startTime: overtime.startTime,
          endTime: overtime.endTime,
          window: overtime.window,
          checkedIn: checkedIn,
          checkedOut: checkedOut,
          attendanceId: record.id,
          workplace: overtime.workplace,
          clientSessionId: record.clientSessionId,
          checkInOccurredAt: record.checkInOccurredAt,
          checkInSyncedAt: record.checkInSyncedAt,
          checkOutOccurredAt: record.checkOutOccurredAt,
          checkOutSyncedAt: record.checkOutSyncedAt,
        );
      }
    }

    await putTodaySnapshot(
      scope: scope,
      attendance: TodayAttendance(
        date: date,
        serverTime:
            cachedAttendance?.serverTime ??
            DateTime.now().toUtc().toIso8601String(),
        regular: regular,
        overtime: overtime,
      ),
    );
  }

  Future<void> replaceOvertimeReferences({
    required SyncScope scope,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required List<OvertimeRecord> records,
  }) async {
    final start = formatDateParam(rangeStart)!;
    final end = formatDateParam(rangeEnd)!;
    final references = _overtimeCompanions(
      scope: scope,
      records: records,
      rangeStart: start,
      rangeEnd: end,
    );
    await _database.replaceAttendanceOvertimeReferences(
      scope: scope,
      rangeStart: start,
      rangeEnd: end,
      references: references,
    );
  }

  Future<void> upsertOvertimeReferences({
    required SyncScope scope,
    required List<OvertimeRecord> records,
    required DateTime? rangeStart,
    required DateTime? rangeEnd,
  }) {
    final start = formatDateParam(rangeStart) ?? '';
    final end = formatDateParam(rangeEnd) ?? '';
    return _database.upsertAttendanceOvertimeReferences(
      _overtimeCompanions(
        scope: scope,
        records: records,
        rangeStart: start,
        rangeEnd: end,
      ),
    );
  }

  List<AttendanceOvertimeReferencesCompanion> _overtimeCompanions({
    required SyncScope scope,
    required List<OvertimeRecord> records,
    required String rangeStart,
    required String rangeEnd,
  }) {
    final fetchedAt = DateTime.now().toUtc();
    return records
        .where((record) => record.id.isNotEmpty)
        .map((record) {
          final localStart = parseLocalDateAndTime(
            record.overtimeDate,
            record.startTime,
          );
          var localEnd = parseLocalDateAndTime(
            record.overtimeDate,
            record.endTime,
          );
          if (localStart == null || localEnd == null) return null;
          if (!localEnd.isAfter(localStart)) {
            localEnd = localEnd.add(const Duration(days: 1));
          }
          return AttendanceOvertimeReferencesCompanion.insert(
            overtimeId: record.id,
            accountId: scope.accountId,
            companyId: scope.companyId,
            overtimeDate: record.overtimeDate,
            startTime: record.startTime,
            endTime: record.endTime,
            startAtUtc: localStart.toUtc(),
            endAtUtc: localEnd.toUtc(),
            localWorkDate: formatDateParam(localStart)!,
            status: record.status.trim().toLowerCase(),
            title: Value(record.title),
            reason: Value(record.reason),
            locationType: Value(record.locationType),
            locationId: Value(record.location?.id),
            locationName: Value(record.location?.name),
            projectId: Value(record.project?.id),
            projectName: Value(record.project?.name),
            fetchedAt: fetchedAt,
            sourceRangeStart: rangeStart,
            sourceRangeEnd: rangeEnd,
          );
        })
        .whereType<AttendanceOvertimeReferencesCompanion>()
        .toList(growable: false);
  }

  Stream<List<AttendanceOvertimeReference>> watchApprovedReferences(
    SyncScope scope,
    DateTime workDate,
  ) => _database.watchApprovedOvertimeReferences(
    scope,
    formatDateParam(workDate)!,
  );

  Stream<EffectiveTodayAttendance> watchEffectiveToday(
    SyncScope scope, {
    DateTime? workDate,
  }) {
    final date = formatDateParam(workDate ?? DateTime.now())!;
    late StreamController<EffectiveTodayAttendance> controller;
    StreamSubscription<Object?>? snapshotSubscription;
    StreamSubscription<Object?>? operationsSubscription;
    StreamSubscription<Object?>? referencesSubscription;
    AttendanceDaySnapshot? snapshot;
    List<OutboxOperation> operations = const [];
    List<AttendanceOvertimeReference> references = const [];
    var snapshotReady = false;
    var operationsReady = false;
    var referencesReady = false;

    void emit() {
      if (!snapshotReady || !operationsReady || !referencesReady) return;
      TodayAttendance? parsed;
      if (snapshot != null) {
        try {
          final json = jsonDecode(snapshot!.payloadJson);
          if (json is Map<String, dynamic>) {
            parsed = TodayAttendance.fromJson(json);
          }
        } catch (_) {
          // A malformed cache is ignored; local operations still form the UI.
        }
      }
      controller.add(
        AttendanceProjection.project(
          snapshot: parsed,
          operations: operations,
          hasApprovedOvertimeReferences: references.isNotEmpty,
          lastUpdatedAt: snapshot?.fetchedAt,
          workDate: workDate,
        ),
      );
    }

    controller = StreamController<EffectiveTodayAttendance>(
      onListen: () {
        snapshotSubscription = _database
            .watchAttendanceSnapshot(scope, date)
            .listen((value) {
              snapshot = value;
              snapshotReady = true;
              emit();
            }, onError: controller.addError);
        operationsSubscription = _database
            .watchAttendanceOperations(scope)
            .listen((value) {
              operations = value;
              operationsReady = true;
              emit();
            }, onError: controller.addError);
        referencesSubscription = _database
            .watchApprovedOvertimeReferences(scope, date)
            .listen((value) {
              references = value;
              referencesReady = true;
              emit();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await snapshotSubscription?.cancel();
        await operationsSubscription?.cancel();
        await referencesSubscription?.cancel();
      },
    );
    return controller.stream;
  }
}

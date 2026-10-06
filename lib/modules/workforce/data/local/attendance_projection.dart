import 'dart:convert';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_models.dart';
import '../models/attendance_operation_payload.dart';
import '../models/effective_today_attendance.dart';
import '../models/today_attendance.dart';

abstract final class AttendanceProjection {
  static EffectiveTodayAttendance project({
    required TodayAttendance? snapshot,
    required List<OutboxOperation> operations,
    required bool hasApprovedOvertimeReferences,
    DateTime? lastUpdatedAt,
    DateTime? workDate,
  }) {
    var regular = EffectivePresence(
      type: AttendanceType.regular,
      clientSessionId: snapshot?.regular.clientSessionId,
      checkedIn: snapshot?.regular.checkedIn ?? false,
      checkedOut: snapshot?.regular.checkedOut ?? false,
    );
    final overtime = <String, EffectivePresence>{};
    final snapshotOvertime = snapshot?.overtime;
    if (snapshotOvertime != null &&
        (snapshotOvertime.checkedIn || snapshotOvertime.checkedOut)) {
      final key =
          snapshotOvertime.clientSessionId ??
          snapshotOvertime.overtimeId ??
          'server-overtime';
      overtime[key] = EffectivePresence(
        type: AttendanceType.overtime,
        clientSessionId: snapshotOvertime.clientSessionId,
        overtimeId: snapshotOvertime.overtimeId,
        checkedIn: snapshotOvertime.checkedIn,
        checkedOut: snapshotOvertime.checkedOut,
      );
    }

    final targetDate = workDate ?? DateTime.now();
    final decoded = <String, AttendanceOperationPayload>{};
    for (final operation in operations) {
      final payload = _payload(operation);
      if (payload != null) decoded[operation.operationId] = payload;
    }
    final relevantSessions = decoded.values
        .where((payload) => _sameLocalDate(payload.occurredAt, targetDate))
        .map((payload) => payload.clientSessionId)
        .toSet();
    final sorted =
        operations.where((operation) {
          final payload = decoded[operation.operationId];
          return payload != null &&
              relevantSessions.contains(payload.clientSessionId);
        }).toList()..sort((left, right) {
          final leftPayload = _payload(left);
          final rightPayload = _payload(right);
          final occurred = (leftPayload?.occurredAt ?? left.createdAt)
              .compareTo(rightPayload?.occurredAt ?? right.createdAt);
          return occurred != 0
              ? occurred
              : left.createdAt.compareTo(right.createdAt);
        });

    for (final operation in sorted) {
      final payload = _payload(operation);
      if (payload == null) continue;
      final state = OutboxState.values
          .where((item) => item.name == operation.state)
          .firstOrNull;
      if (state == null) continue;
      if (payload.type == AttendanceType.regular) {
        regular = _apply(regular, operation, payload, state);
      } else {
        final current =
            overtime[payload.clientSessionId] ??
            EffectivePresence(
              type: AttendanceType.overtime,
              clientSessionId: payload.clientSessionId,
              overtimeId: payload.overtimeId,
            );
        overtime[payload.clientSessionId] = _apply(
          current,
          operation,
          payload,
          state,
        );
      }
    }

    int count(OutboxState state) =>
        sorted.where((item) => item.state == state.name).length;
    final hasCompletedOvertime = overtime.values.any(
      (session) => session.checkedOut,
    );
    return EffectiveTodayAttendance(
      regular: regular,
      overtimeSessions: overtime.values.toList(growable: false),
      referenceState:
          !hasCompletedOvertime &&
              (snapshotOvertime?.canCheckIn == true ||
                  hasApprovedOvertimeReferences)
          ? AttendanceReferenceState.available
          : AttendanceReferenceState.regularOnly,
      syncSummary: AttendanceSyncSummary(
        pending: count(OutboxState.pending),
        syncing: count(OutboxState.processing),
        retry: count(OutboxState.retry),
        needsAttention:
            count(OutboxState.failed) +
            count(OutboxState.conflict) +
            count(OutboxState.rejected),
      ),
      lastUpdatedAt: lastUpdatedAt,
      snapshot: snapshot,
    );
  }

  static EffectivePresence _apply(
    EffectivePresence current,
    OutboxOperation operation,
    AttendanceOperationPayload payload,
    OutboxState state,
  ) => EffectivePresence(
    type: payload.type,
    clientSessionId: payload.clientSessionId,
    overtimeId: payload.overtimeId ?? current.overtimeId,
    checkedIn: payload.action == AttendanceAction.checkIn
        ? true
        : current.checkedIn,
    checkedOut: payload.action == AttendanceAction.checkOut ? true : false,
    checkInOperationId: payload.action == AttendanceAction.checkIn
        ? operation.operationId
        : current.checkInOperationId,
    checkOutOperationId: payload.action == AttendanceAction.checkOut
        ? operation.operationId
        : null,
    state: state,
  );

  static AttendanceOperationPayload? _payload(OutboxOperation operation) {
    try {
      final json = jsonDecode(operation.payloadJson);
      return json is Map<String, dynamic>
          ? AttendanceOperationPayload.fromJson(json)
          : null;
    } catch (_) {
      return null;
    }
  }

  static bool _sameLocalDate(DateTime instant, DateTime date) {
    final local = instant.toLocal();
    return local.year == date.year &&
        local.month == date.month &&
        local.day == date.day;
  }
}

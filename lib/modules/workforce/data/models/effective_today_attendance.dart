import '../../../../core/sync/sync_models.dart';
import 'attendance_operation_payload.dart';
import 'today_attendance.dart';

enum AttendanceReferenceState { available, regularOnly }

class AttendanceSyncSummary {
  const AttendanceSyncSummary({
    this.pending = 0,
    this.syncing = 0,
    this.retry = 0,
    this.needsAttention = 0,
  });

  final int pending;
  final int syncing;
  final int retry;
  final int needsAttention;

  int get waiting => pending + syncing + retry;
}

class EffectivePresence {
  const EffectivePresence({
    required this.type,
    this.clientSessionId,
    this.overtimeId,
    this.checkedIn = false,
    this.checkedOut = false,
    this.checkInOperationId,
    this.checkOutOperationId,
    this.state,
  });

  final AttendanceType type;
  final String? clientSessionId;
  final String? overtimeId;
  final bool checkedIn;
  final bool checkedOut;
  final String? checkInOperationId;
  final String? checkOutOperationId;
  final OutboxState? state;

  bool get hasOpenAttendance => checkedIn && !checkedOut;
  bool get canCheckIn => !checkedIn;
  bool get needsAttention =>
      state == OutboxState.failed ||
      state == OutboxState.conflict ||
      state == OutboxState.rejected;
}

class EffectiveTodayAttendance {
  const EffectiveTodayAttendance({
    required this.regular,
    required this.overtimeSessions,
    required this.referenceState,
    required this.syncSummary,
    required this.lastUpdatedAt,
    this.snapshot,
  });

  final EffectivePresence regular;
  final List<EffectivePresence> overtimeSessions;
  final AttendanceReferenceState referenceState;
  final AttendanceSyncSummary syncSummary;
  final DateTime? lastUpdatedAt;
  final TodayAttendance? snapshot;

  /// Completion is scoped to the work date used to build this projection.
  bool get hasCompletedOvertime =>
      overtimeSessions.any((session) => session.checkedOut);

  EffectivePresence? get openPresence {
    if (regular.hasOpenAttendance) return regular;
    for (final item in overtimeSessions.reversed) {
      if (item.hasOpenAttendance) return item;
    }
    return null;
  }
}

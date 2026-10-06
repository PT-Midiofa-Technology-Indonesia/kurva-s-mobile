enum OutboxState {
  pending,
  processing,
  retry,
  failed,
  conflict,
  rejected,
  done,
}

enum SyncOperationType {
  attendanceCheckIn,
  attendanceCheckOut,
  projectTaskDone,
  qcTaskDecision,
  logisticInboundReceive,
  logisticOutboundIssue,
  logisticLoadingReport,
  logisticPickupReport,
}

extension SyncOperationTypeStorage on SyncOperationType {
  /// Stable value persisted in the outbox. Enum names are deliberately not
  /// used because renaming a Dart symbol must not invalidate durable rows.
  String get storageName => switch (this) {
    SyncOperationType.projectTaskDone => 'project.task.done.v1',
    SyncOperationType.qcTaskDecision => 'project.qc.decision.v1',
    SyncOperationType.logisticInboundReceive => 'logistic.inbound.receive.v1',
    SyncOperationType.logisticOutboundIssue => 'logistic.outbound.issue.v1',
    SyncOperationType.logisticLoadingReport => 'logistic.loading.report.v1',
    SyncOperationType.logisticPickupReport => 'logistic.pickup.report.v1',
    SyncOperationType.attendanceCheckIn => 'attendance.check_in.v1',
    SyncOperationType.attendanceCheckOut => 'attendance.check_out.v1',
  };
}

enum SyncRunState { idle, syncing, completed, paused, failed }

enum SyncTrigger {
  bootstrap,
  foreground,
  connectivityRestored,
  userInitiated,
  operationEnqueued,
}

class SyncScope {
  const SyncScope({required this.accountId, required this.companyId});

  final String accountId;
  final String companyId;
}

class SyncStatus {
  const SyncStatus({
    this.state = SyncRunState.idle,
    this.pendingCount = 0,
    this.completedCount = 0,
    this.lastSyncedAt,
    this.message,
  });

  final SyncRunState state;
  final int pendingCount;
  final int completedCount;
  final DateTime? lastSyncedAt;
  final String? message;

  SyncStatus copyWith({
    SyncRunState? state,
    int? pendingCount,
    int? completedCount,
    DateTime? lastSyncedAt,
    String? message,
    bool clearMessage = false,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      pendingCount: pendingCount ?? this.pendingCount,
      completedCount: completedCount ?? this.completedCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

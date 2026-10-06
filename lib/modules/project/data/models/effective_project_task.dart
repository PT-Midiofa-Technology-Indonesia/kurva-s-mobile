import 'dart:convert';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_models.dart';
import 'project_models.dart';

class ProjectTaskSyncOverlay {
  const ProjectTaskSyncOverlay({
    required this.operationId,
    required this.operationType,
    required this.state,
    required this.attemptCount,
    required this.createdAt,
    this.decision,
    this.nextAttemptAt,
    this.lastErrorCode,
    this.lastErrorMessage,
  });

  final String operationId;
  final String operationType;
  final OutboxState state;
  final String? decision;
  final int attemptCount;
  final DateTime? nextAttemptAt;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final DateTime createdAt;

  bool get isActive => const {
    OutboxState.pending,
    OutboxState.processing,
    OutboxState.retry,
  }.contains(state);

  factory ProjectTaskSyncOverlay.fromOperation(OutboxOperation operation) {
    final payload = jsonDecode(operation.payloadJson);
    return ProjectTaskSyncOverlay(
      operationId: operation.operationId,
      operationType: operation.operationType,
      state: OutboxState.values.firstWhere(
        (value) => value.name == operation.state,
        orElse: () => OutboxState.failed,
      ),
      decision: payload is Map<String, dynamic>
          ? payload['decision'] as String?
          : null,
      attemptCount: operation.attemptCount,
      nextAttemptAt: operation.nextAttemptAt,
      lastErrorCode: operation.lastErrorCode,
      lastErrorMessage: operation.lastErrorMessage,
      createdAt: operation.createdAt,
    );
  }
}

class EffectiveProjectTask {
  const EffectiveProjectTask({required this.serverTask, this.syncOverlay});

  final ProjectTask serverTask;
  final ProjectTaskSyncOverlay? syncOverlay;

  bool get hasActiveOperation => syncOverlay?.isActive ?? false;
}

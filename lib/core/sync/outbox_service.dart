import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../files/durable_file_store.dart';
import 'sync_models.dart';
import 'sync_policy.dart';

class AttachmentInput {
  const AttachmentInput({
    required this.sourcePath,
    required this.fieldName,
    required this.mimeType,
  });

  final String sourcePath;
  final String fieldName;
  final String mimeType;
}

class EnqueueOperationInput {
  const EnqueueOperationInput({
    required this.scope,
    required this.operationType,
    required this.targetResourceKey,
    required this.endpoint,
    required this.payload,
    this.payloadVersion = 1,
    this.clientEventId,
    this.attachments = const [],
    this.dependsOnOperationId,
  });

  final SyncScope scope;
  final SyncOperationType operationType;
  final String targetResourceKey;
  final String endpoint;
  final Map<String, Object?> payload;
  final int payloadVersion;
  final String? clientEventId;
  final List<AttachmentInput> attachments;
  final String? dependsOnOperationId;
}

class OutboxService {
  OutboxService({
    required AppDatabase database,
    required DurableFileStore fileStore,
    required SyncPolicy policy,
    void Function()? onEnqueued,
    Uuid? uuid,
  }) : _database = database,
       _fileStore = fileStore,
       _policy = policy,
       _onEnqueued = onEnqueued,
       _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final DurableFileStore _fileStore;
  final SyncPolicy _policy;
  final void Function()? _onEnqueued;
  final Uuid _uuid;

  Future<String?> activeOperationId({
    required SyncScope scope,
    required SyncOperationType operationType,
    required String targetResourceKey,
  }) async {
    final operation = await _database.activeOperation(
      scope,
      operationType,
      targetResourceKey,
    );
    return operation?.operationId;
  }

  Future<String> enqueue(EnqueueOperationInput input) async {
    if (!_policy.canQueue(input.operationType)) {
      throw StateError(
        '${input.operationType.name} masih online-only dan tidak boleh diantrekan.',
      );
    }
    if (input.scope.accountId.isEmpty || input.scope.companyId.isEmpty) {
      throw ArgumentError('Scope account/company wajib diisi.');
    }
    if (await _database.hasActiveOperation(
      input.scope,
      input.operationType,
      input.targetResourceKey,
    )) {
      throw StateError('Aksi yang sama sudah menunggu sinkronisasi.');
    }

    final operationId = _uuid.v4();
    final idempotencyKey = input.clientEventId ?? operationId;
    final now = DateTime.now().toUtc();
    final durableAttachments =
        <({AttachmentInput input, DurableAttachment file})>[];

    try {
      for (final attachment in input.attachments) {
        final durable = await _fileStore.persist(
          sourcePath: attachment.sourcePath,
          scope: input.scope,
          operationId: operationId,
        );
        durableAttachments.add((input: attachment, file: durable));
      }

      await _database.enqueueOperation(
        OutboxOperationsCompanion.insert(
          operationId: operationId,
          idempotencyKey: idempotencyKey,
          accountId: input.scope.accountId,
          companyId: input.scope.companyId,
          operationType: input.operationType.storageName,
          targetResourceKey: input.targetResourceKey,
          endpoint: input.endpoint,
          payloadJson: jsonEncode({
            ...input.payload,
            'clientOperationId': operationId,
            if (_requiresClientEventId(input.operationType))
              'clientEventId': input.clientEventId ?? operationId,
          }),
          payloadVersion: Value(input.payloadVersion),
          state: Value(OutboxState.pending.name),
          dependsOnOperationId: Value(input.dependsOnOperationId),
          createdAt: now,
          updatedAt: now,
        ),
        durableAttachments
            .map((attachment) {
              return OutboxAttachmentsCompanion.insert(
                attachmentId: _uuid.v4(),
                operationId: operationId,
                fieldName: attachment.input.fieldName,
                durablePath: attachment.file.path,
                originalName: attachment.file.originalName,
                mimeType: attachment.input.mimeType,
                sizeBytes: attachment.file.sizeBytes,
                checksum: attachment.file.checksum,
                createdAt: now,
              );
            })
            .toList(growable: false),
      );
      _onEnqueued?.call();
      return operationId;
    } catch (_) {
      for (final attachment in durableAttachments) {
        await _fileStore.delete(attachment.file.path);
      }
      rethrow;
    }
  }

  bool _requiresClientEventId(SyncOperationType operationType) =>
      operationType == SyncOperationType.attendanceCheckIn ||
      operationType == SyncOperationType.attendanceCheckOut ||
      operationType == SyncOperationType.projectTaskDone ||
      operationType == SyncOperationType.qcTaskDecision ||
      operationType == SyncOperationType.logisticInboundReceive ||
      operationType == SyncOperationType.logisticOutboundIssue;
}

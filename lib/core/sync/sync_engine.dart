import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:http_parser/http_parser.dart';

import '../database/app_database.dart';
import '../database/cache_key.dart';
import '../../modules/project/data/models/project_models.dart';
import '../errors/error_mapper.dart';
import '../errors/sync_failure.dart';
import '../files/durable_file_store.dart';
import '../network/dio_client.dart';
import 'retry_policy.dart';
import 'sync_models.dart';

class SyncRunResult {
  const SyncRunResult({
    required this.processedCount,
    required this.completedCount,
    required this.remainingCount,
    this.pausedForAuth = false,
  });

  final int processedCount;
  final int completedCount;
  final int remainingCount;
  final bool pausedForAuth;
}

class _PushResult {
  const _PushResult({required this.shouldContinue, required this.completed});

  final bool shouldContinue;
  final bool completed;
}

class SyncEngine {
  SyncEngine({
    required AppDatabase database,
    required DioClient dioClient,
    required DurableFileStore fileStore,
    required RetryPolicy retryPolicy,
  }) : _database = database,
       _dioClient = dioClient,
       _fileStore = fileStore,
       _retryPolicy = retryPolicy;

  final AppDatabase _database;
  final DioClient _dioClient;
  final DurableFileStore _fileStore;
  final RetryPolicy _retryPolicy;

  Future<DateTime?> nextRetryAtForAccount(String accountId) =>
      _database.nextRetryAtForAccount(accountId);

  Future<void> makeRetriesDueForAccount(String accountId) async {
    final now = DateTime.now().toUtc();
    await _database.recoverLegacyAttendanceNetworkFailures(accountId, now);
    await _database.makeRetriesDueForAccount(accountId, now);
  }

  Future<SyncRunResult> pushPendingForAccount(String accountId) async {
    final scopes = await _database.pendingScopesForAccount(accountId);
    var processed = 0;
    var completed = 0;
    var remaining = 0;
    for (final scope in scopes) {
      final result = await pushPending(scope);
      processed += result.processedCount;
      completed += result.completedCount;
      remaining += result.remainingCount;
      if (result.pausedForAuth) {
        return SyncRunResult(
          processedCount: processed,
          completedCount: completed,
          remainingCount: remaining,
          pausedForAuth: true,
        );
      }
    }
    return SyncRunResult(
      processedCount: processed,
      completedCount: completed,
      remainingCount: remaining,
    );
  }

  Future<SyncRunResult> pushPending(SyncScope scope) async {
    var processed = 0;
    var completed = 0;
    var pausedForAuth = false;

    while (true) {
      final operation = await _database.claimNextOperation(
        scope,
        now: DateTime.now().toUtc(),
      );
      if (operation == null) break;

      final result = await _push(operation);
      processed += 1;
      if (result.completed) completed += 1;
      if (!result.shouldContinue) {
        pausedForAuth = true;
        break;
      }
    }

    final remaining = await _database.listOperations(scope);
    return SyncRunResult(
      processedCount: processed,
      completedCount: completed,
      remainingCount: remaining.where((operation) {
        return operation.state == OutboxState.pending.name ||
            operation.state == OutboxState.processing.name ||
            operation.state == OutboxState.retry.name;
      }).length,
      pausedForAuth: pausedForAuth,
    );
  }

  Future<_PushResult> _push(OutboxOperation operation) async {
    final now = DateTime.now().toUtc();
    final attempt = operation.attemptCount + 1;
    try {
      final attachments = await _database.attachmentsFor(operation.operationId);
      if (operation.payloadVersion != 1) {
        throw SyncFailure(
          kind: SyncFailureKind.permanent,
          message: 'Versi payload antrean tidak didukung.',
          code: 'UNSUPPORTED_PAYLOAD_VERSION',
        );
      }
      final payload = _decodePayload(operation.payloadJson);
      final Object requestData;
      if (_isLogistic(operation)) {
        requestData = await _logisticFormData(payload, attachments);
      } else if (_isAttendance(operation)) {
        requestData = await _attendanceFormData(
          operation,
          payload,
          attachments,
        );
      } else if (attachments.isEmpty) {
        requestData = payload;
      } else {
        final formData = FormData.fromMap(payload);
        for (final attachment in attachments) {
          if (!await _fileStore.exists(attachment.durablePath)) {
            throw SyncFailure(
              kind: SyncFailureKind.permanent,
              message: 'File lampiran tidak lagi tersedia di perangkat.',
              code: 'ATTACHMENT_MISSING',
            );
          }
          if (await _fileStore.checksumFor(attachment.durablePath) !=
              attachment.checksum) {
            throw SyncFailure(
              kind: SyncFailureKind.permanent,
              message: 'File lampiran berubah atau rusak.',
              code: 'ATTACHMENT_CHECKSUM_MISMATCH',
            );
          }
          formData.files.add(
            MapEntry(
              attachment.fieldName,
              await MultipartFile.fromFile(
                attachment.durablePath,
                filename: attachment.originalName,
                contentType: MediaType.parse(attachment.mimeType),
              ),
            ),
          );
        }
        requestData = formData;
      }

      final response = await _dioClient.dio.request<Object?>(
        operation.endpoint,
        data: requestData,
        options: Options(
          method: operation.httpMethod,
          headers: {
            'Idempotency-Key': operation.idempotencyKey,
            'X-Operation-Id': operation.operationId,
            'X-Company-Id': operation.companyId,
          },
        ),
      );
      final canonicalCache = await _projectCacheEntry(
        operation,
        payload,
        response.data,
      );
      await _database.completeOperation(
        operationId: operation.operationId,
        attemptCount: attempt,
        updatedAt: now,
        canonicalCache: canonicalCache,
      );
      for (final attachment in attachments) {
        await _fileStore.delete(attachment.durablePath);
      }
      await _database.deleteAttachmentMetadata(operation.operationId);
      return const _PushResult(shouldContinue: true, completed: true);
    } on DioException catch (error) {
      return _recordFailure(
        operation,
        attempt,
        ErrorMapper.toSyncFailure(error),
      );
    } on SyncFailure catch (failure) {
      return _recordFailure(operation, attempt, failure);
    } catch (error) {
      return _recordFailure(
        operation,
        attempt,
        SyncFailure(
          kind: SyncFailureKind.retryable,
          message: error.toString(),
          code: 'UNEXPECTED_SYNC_ERROR',
        ),
      );
    }
  }

  Future<_PushResult> _recordFailure(
    OutboxOperation operation,
    int attempt,
    SyncFailure failure,
  ) async {
    final now = DateTime.now().toUtc();
    final state = switch (failure.kind) {
      SyncFailureKind.auth => OutboxState.retry,
      SyncFailureKind.retryable => OutboxState.retry,
      SyncFailureKind.permanent => OutboxState.failed,
      SyncFailureKind.conflict => OutboxState.conflict,
      SyncFailureKind.rejected => OutboxState.rejected,
    };
    final retryDelay = _retryDelay(operation, attempt, failure.retryAfter);
    final retryAt = state == OutboxState.retry
        ? now.add(
            retryDelay < const Duration(seconds: 1)
                ? const Duration(seconds: 1)
                : retryDelay,
          )
        : null;
    await _database.updateOperationState(
      operationId: operation.operationId,
      state: state,
      attemptCount: attempt,
      nextAttemptAt: retryAt,
      errorCode: failure.code,
      errorMessage: failure.message,
      updatedAt: now,
    );
    return _PushResult(
      shouldContinue: failure.kind != SyncFailureKind.auth,
      completed: false,
    );
  }

  Duration _retryDelay(
    OutboxOperation operation,
    int attempt,
    Duration? retryAfter,
  ) {
    final isProject =
        operation.operationType ==
            SyncOperationType.projectTaskDone.storageName ||
        operation.operationType == SyncOperationType.qcTaskDecision.storageName;
    return isProject
        ? _retryPolicy.projectDelayForAttempt(attempt, retryAfter: retryAfter)
        : _retryPolicy.delayForAttempt(attempt, retryAfter: retryAfter);
  }

  Map<String, Object?> _decodePayload(String payloadJson) {
    final decoded = jsonDecode(payloadJson);
    if (decoded is! Map<String, dynamic>) {
      throw const SyncFailure(
        kind: SyncFailureKind.permanent,
        message: 'Payload antrean tidak valid.',
        code: 'INVALID_OUTBOX_PAYLOAD',
      );
    }
    return decoded;
  }

  bool _isLogistic(OutboxOperation operation) =>
      operation.operationType ==
          SyncOperationType.logisticInboundReceive.storageName ||
      operation.operationType ==
          SyncOperationType.logisticOutboundIssue.storageName ||
      operation.operationType ==
          SyncOperationType.logisticLoadingReport.storageName ||
      operation.operationType ==
          SyncOperationType.logisticPickupReport.storageName;

  bool _isAttendance(OutboxOperation operation) =>
      operation.operationType ==
          SyncOperationType.attendanceCheckIn.storageName ||
      operation.operationType ==
          SyncOperationType.attendanceCheckOut.storageName;

  Future<FormData> _attendanceFormData(
    OutboxOperation operation,
    Map<String, Object?> payload,
    List<OutboxAttachment> attachments,
  ) async {
    final type = payload['type'];
    final clientEventId = payload['clientEventId'];
    final clientSessionId = payload['clientSessionId'];
    final occurredAt = payload['occurredAt'];
    final latitude = payload['latitude'];
    final longitude = payload['longitude'];
    if ((type != 'regular' && type != 'overtime') ||
        clientEventId is! String ||
        clientEventId.isEmpty ||
        clientSessionId is! String ||
        clientSessionId.isEmpty ||
        occurredAt is! String ||
        DateTime.tryParse(occurredAt) == null ||
        latitude is! num ||
        longitude is! num) {
      throw const SyncFailure(
        kind: SyncFailureKind.permanent,
        message: 'Payload presensi tidak lengkap atau tidak valid.',
        code: 'INVALID_ATTENDANCE_PAYLOAD',
      );
    }
    final formData = FormData.fromMap({
      'type': type,
      'latitude': '$latitude',
      'longitude': '$longitude',
      'clientEventId': clientEventId,
      'clientSessionId': clientSessionId,
      'occurredAt': DateTime.parse(occurredAt).toUtc().toIso8601String(),
      if (payload['timezoneOffsetMinutes'] case final num offset)
        'timezoneOffsetMinutes': '${offset.toInt()}',
      if (payload['accuracyMeters'] case final num accuracy)
        'accuracyMeters': '$accuracy',
      'isMocked': payload['isMocked'] == true ? 'true' : 'false',
      if (payload['overtimeId'] case final String overtimeId
          when overtimeId.isNotEmpty)
        'overtimeId': overtimeId,
    });
    for (final attachment in attachments) {
      if (!await _fileStore.exists(attachment.durablePath)) {
        throw const SyncFailure(
          kind: SyncFailureKind.permanent,
          message: 'Selfie presensi tidak lagi tersedia di perangkat.',
          code: 'ATTACHMENT_MISSING',
        );
      }
      if (await _fileStore.checksumFor(attachment.durablePath) !=
          attachment.checksum) {
        throw const SyncFailure(
          kind: SyncFailureKind.permanent,
          message: 'Selfie presensi berubah atau rusak.',
          code: 'ATTACHMENT_CHECKSUM_MISMATCH',
        );
      }
      formData.files.add(
        MapEntry(
          attachment.fieldName,
          await MultipartFile.fromFile(
            attachment.durablePath,
            filename: attachment.originalName,
            contentType: MediaType.parse(attachment.mimeType),
          ),
        ),
      );
    }
    return formData;
  }

  Future<FormData> _logisticFormData(
    Map<String, Object?> payload,
    List<OutboxAttachment> attachments,
  ) async {
    final formData = FormData.fromMap({
      'notes': payload['notes'] ?? '',
      'clientOperationId': payload['clientOperationId'],
      if (payload['clientEventId'] case final String clientEventId
          when clientEventId.isNotEmpty)
        'clientEventId': clientEventId,
      'clientOccurredAt': payload['clientOccurredAt'],
      if (payload['expectedVersion'] != null)
        'expectedVersion': payload['expectedVersion'],
      'payloadVersion': payload['payloadVersion'] ?? 1,
    });
    final items = payload['items'];
    if (items is List) {
      for (var index = 0; index < items.length; index += 1) {
        final item = items[index];
        if (item is! Map<String, dynamic>) continue;
        formData.fields.addAll([
          MapEntry(
            'items[$index][deliveryOrderItemId]',
            '${item['deliveryOrderItemId'] ?? ''}',
          ),
          MapEntry(
            'items[$index][quantityReceived]',
            '${item['quantityReceived'] ?? ''}',
          ),
        ]);
      }
    }
    for (final attachment in attachments) {
      if (!await _fileStore.exists(attachment.durablePath)) {
        throw const SyncFailure(
          kind: SyncFailureKind.permanent,
          message: 'File lampiran tidak lagi tersedia di perangkat.',
          code: 'ATTACHMENT_MISSING',
        );
      }
      if (await _fileStore.checksumFor(attachment.durablePath) !=
          attachment.checksum) {
        throw const SyncFailure(
          kind: SyncFailureKind.permanent,
          message: 'File lampiran berubah atau rusak.',
          code: 'ATTACHMENT_CHECKSUM_MISMATCH',
        );
      }
      formData.files.add(
        MapEntry(
          attachment.fieldName,
          await MultipartFile.fromFile(
            attachment.durablePath,
            filename: attachment.originalName,
            contentType: MediaType.parse(attachment.mimeType),
          ),
        ),
      );
    }
    return formData;
  }

  Future<ApiCacheCompanion?> _projectCacheEntry(
    OutboxOperation operation,
    Map<String, Object?> payload,
    Object? responseBody,
  ) async {
    if (_isLogistic(operation)) {
      return _logisticCacheEntry(operation, payload, responseBody);
    }
    final isTaskDone =
        operation.operationType ==
        SyncOperationType.projectTaskDone.storageName;
    final isQcDecision =
        operation.operationType == SyncOperationType.qcTaskDecision.storageName;
    if (!isTaskDone && !isQcDecision) return null;
    if (responseBody is! Map<String, dynamic>) return null;

    final data = responseBody['data'];
    final dataMap = data is Map<String, dynamic> ? data : responseBody;
    final candidate = dataMap['task'] ?? dataMap['qcTask'];
    if (candidate is! Map<String, dynamic>) return null;

    final projectId = payload['projectId'] as String? ?? '';
    final taskId = isQcDecision
        ? payload['qcTaskId'] as String? ?? ''
        : payload['taskId'] as String? ?? '';
    if (projectId.isEmpty || taskId.isEmpty) return null;

    final scope = SyncScope(
      accountId: operation.accountId,
      companyId: operation.companyId,
    );
    final endpointKey = isQcDecision
        ? 'project:qc-detail:$projectId:$taskId'
        : 'project:task-detail:$projectId:$taskId';
    final cacheKey = CacheKey.create(scope: scope, endpointKey: endpointKey);
    final now = DateTime.now().toUtc();
    return ApiCacheCompanion.insert(
      cacheKey: cacheKey,
      accountId: scope.accountId,
      companyId: scope.companyId,
      endpointKey: endpointKey,
      queryHash: cacheKey,
      payloadJson: jsonEncode(
        ProjectTask.fromJson(
          candidate,
          useWorkTaskPeople: isQcDecision,
        ).toJson(),
      ),
      fetchedAt: now,
      expiresAt: Value(now.add(const Duration(hours: 24))),
    );
  }

  Future<ApiCacheCompanion?> _logisticCacheEntry(
    OutboxOperation operation,
    Map<String, Object?> payload,
    Object? responseBody,
  ) async {
    if (responseBody is! Map<String, dynamic>) return null;
    final responseData = responseBody['data'];
    if (responseData is! Map<String, dynamic>) return null;
    final deliveryOrderId =
        responseData['deliveryOrderId'] as String? ??
        responseData['loadingOrderId'] as String? ??
        responseData['pickupOrderId'] as String? ??
        payload['deliveryOrderId'] as String? ??
        '';
    if (deliveryOrderId.isEmpty) return null;

    final resourceType = switch (operation.operationType) {
      final type
          when type == SyncOperationType.logisticInboundReceive.storageName =>
        'inbound',
      final type
          when type == SyncOperationType.logisticOutboundIssue.storageName =>
        'outbound',
      final type
          when type == SyncOperationType.logisticLoadingReport.storageName =>
        'loading',
      _ => 'pickup',
    };
    final endpointKey = 'logistic:$resourceType:detail:$deliveryOrderId';
    final scope = SyncScope(
      accountId: operation.accountId,
      companyId: operation.companyId,
    );
    final cacheKey = CacheKey.create(scope: scope, endpointKey: endpointKey);
    final existing = await _database.getCache(cacheKey, scope);
    Map<String, dynamic> existingPayload = const {};
    if (existing != null) {
      final decoded = jsonDecode(existing.payloadJson);
      if (decoded is Map<String, dynamic>) existingPayload = decoded;
    }
    final merged = <String, dynamic>{...existingPayload, ...responseData};
    final now = DateTime.now().toUtc();
    return ApiCacheCompanion.insert(
      cacheKey: cacheKey,
      accountId: scope.accountId,
      companyId: scope.companyId,
      endpointKey: endpointKey,
      queryHash: cacheKey,
      payloadJson: jsonEncode(merged),
      fetchedAt: now,
      expiresAt: Value(now.add(const Duration(hours: 24))),
    );
  }
}

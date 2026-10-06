import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/database/app_database.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';

void main() {
  late AppDatabase database;
  const scope = SyncScope(accountId: 'account-1', companyId: 'company-1');

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('idempotency key is unique', () async {
    await database.enqueueOperation(
      _operation('operation-1', 'same-key'),
      const [],
    );

    await expectLater(
      database.enqueueOperation(
        _operation('operation-2', 'same-key', targetResource: 'other-target'),
        const [],
      ),
      throwsA(anything),
    );
  });

  test('operation and attachments roll back atomically', () async {
    final attachment = _attachment('attachment-1', 'operation-1');

    await expectLater(
      database.enqueueOperation(_operation('operation-1', 'key-1'), [
        attachment,
        attachment,
      ]),
      throwsA(anything),
    );

    expect(await database.listOperations(scope), isEmpty);
  });

  test('tenant queries do not leak operations', () async {
    await database.enqueueOperation(
      _operation('operation-1', 'key-1'),
      const [],
    );

    expect(await database.listOperations(scope), hasLength(1));
    expect(
      await database.listOperations(
        const SyncScope(accountId: 'account-2', companyId: 'company-1'),
      ),
      isEmpty,
    );
  });

  test('claim waits for dependency and recovers stuck processing', () async {
    final old = DateTime.now().toUtc().subtract(const Duration(hours: 1));
    await database.enqueueOperation(
      _operation(
        'parent',
        'parent-key',
        state: OutboxState.processing,
        processingStartedAt: old,
      ),
      const [],
    );
    await database.enqueueOperation(
      _operation(
        'child',
        'child-key',
        dependsOn: 'parent',
        operationType: SyncOperationType.attendanceCheckOut,
      ),
      const [],
    );

    final recovered = await database.claimNextOperation(
      scope,
      now: DateTime.now().toUtc(),
    );
    expect(recovered?.operationId, 'parent');

    await database.updateOperationState(
      operationId: 'parent',
      state: OutboxState.done,
      updatedAt: DateTime.now().toUtc(),
    );
    final child = await database.claimNextOperation(
      scope,
      now: DateTime.now().toUtc(),
    );
    expect(child?.operationId, 'child');
  });

  test(
    'legacy network failure and dependent check-out are recovered',
    () async {
      await database.enqueueOperation(
        _operation(
          'parent',
          'parent-key',
          state: OutboxState.failed,
          errorMessage: 'SocketException: Network is unreachable',
        ),
        const [],
      );
      await database.enqueueOperation(
        _operation(
          'child',
          'child-key',
          state: OutboxState.failed,
          dependsOn: 'parent',
          errorCode: 'DEPENDENCY_FAILED',
          operationType: SyncOperationType.attendanceCheckOut,
        ),
        const [],
      );

      final now = DateTime.now().toUtc();
      await database.recoverLegacyAttendanceNetworkFailures(
        scope.accountId,
        now,
      );

      final operations = await database.listOperations(scope);
      expect(
        operations.singleWhere((item) => item.operationId == 'parent').state,
        OutboxState.retry.name,
      );
      expect(
        operations.singleWhere((item) => item.operationId == 'child').state,
        OutboxState.pending.name,
      );
    },
  );

  test('cache watch is scoped by account and company', () async {
    final now = DateTime.now().toUtc();
    await database.putCache(
      ApiCacheCompanion.insert(
        cacheKey: 'cache-key',
        accountId: scope.accountId,
        companyId: scope.companyId,
        endpointKey: 'locations',
        queryHash: 'hash',
        payloadJson: '{"data":[]}',
        fetchedAt: now,
      ),
    );

    expect(await database.watchCache('cache-key', scope).first, isNotNull);
    expect(
      await database
          .watchCache(
            'cache-key',
            const SyncScope(accountId: 'other', companyId: 'company-1'),
          )
          .first,
      isNull,
    );
  });

  test('clearAllData removes data from every table', () async {
    final now = DateTime.now().toUtc();
    await database.enqueueOperation(_operation('operation-1', 'key-1'), [
      _attachment('attachment-1', 'operation-1'),
    ]);
    await database.putCache(
      ApiCacheCompanion.insert(
        cacheKey: 'cache-key',
        accountId: scope.accountId,
        companyId: scope.companyId,
        endpointKey: 'locations',
        queryHash: 'hash',
        payloadJson: '{}',
        fetchedAt: now,
      ),
    );
    await database
        .into(database.attendanceDaySnapshots)
        .insert(
          AttendanceDaySnapshotsCompanion.insert(
            accountId: scope.accountId,
            companyId: scope.companyId,
            attendanceDate: '2026-07-27',
            payloadJson: '{}',
            fetchedAt: now,
          ),
        );
    await database
        .into(database.attendanceOvertimeReferences)
        .insert(
          AttendanceOvertimeReferencesCompanion.insert(
            overtimeId: 'overtime-1',
            accountId: scope.accountId,
            companyId: scope.companyId,
            overtimeDate: '2026-07-27',
            startTime: '09:00',
            endTime: '10:00',
            startAtUtc: now,
            endAtUtc: now.add(const Duration(hours: 1)),
            localWorkDate: '2026-07-27',
            status: 'approved',
            fetchedAt: now,
            sourceRangeStart: '2026-07-27',
            sourceRangeEnd: '2026-07-27',
          ),
        );

    await database.clearAllData();

    expect(await database.select(database.outboxAttachments).get(), isEmpty);
    expect(await database.select(database.outboxOperations).get(), isEmpty);
    expect(await database.select(database.apiCache).get(), isEmpty);
    expect(
      await database.select(database.attendanceDaySnapshots).get(),
      isEmpty,
    );
    expect(
      await database.select(database.attendanceOvertimeReferences).get(),
      isEmpty,
    );
  });
}

OutboxOperationsCompanion _operation(
  String id,
  String idempotencyKey, {
  OutboxState state = OutboxState.pending,
  DateTime? processingStartedAt,
  String? dependsOn,
  String targetResource = 'attendance:today',
  SyncOperationType operationType = SyncOperationType.attendanceCheckIn,
  String? errorCode,
  String? errorMessage,
}) {
  final now = DateTime.now().toUtc();
  return OutboxOperationsCompanion.insert(
    operationId: id,
    idempotencyKey: idempotencyKey,
    accountId: 'account-1',
    companyId: 'company-1',
    operationType: operationType.storageName,
    targetResourceKey: targetResource,
    endpoint: '/v1/mobile/attendance/check-in',
    payloadJson: '{}',
    state: Value(state.name),
    processingStartedAt: Value(processingStartedAt),
    dependsOnOperationId: Value(dependsOn),
    lastErrorCode: Value(errorCode),
    lastErrorMessage: Value(errorMessage),
    createdAt: now,
    updatedAt: now,
  );
}

OutboxAttachmentsCompanion _attachment(String id, String operationId) {
  return OutboxAttachmentsCompanion.insert(
    attachmentId: id,
    operationId: operationId,
    fieldName: 'selfie',
    durablePath: '/durable/selfie.jpg',
    originalName: 'selfie.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 12,
    checksum: 'checksum',
    createdAt: DateTime.now().toUtc(),
  );
}

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../sync/sync_models.dart';

part 'app_database.g.dart';

@TableIndex(name: 'outbox_retry_idx', columns: {#state, #nextAttemptAt})
@TableIndex(name: 'outbox_scope_idx', columns: {#accountId, #companyId})
@TableIndex(name: 'outbox_resource_idx', columns: {#targetResourceKey})
@TableIndex(name: 'outbox_created_idx', columns: {#createdAt})
@TableIndex(
  name: 'outbox_attendance_scope_idx',
  columns: {#accountId, #companyId, #operationType, #state},
)
class OutboxOperations extends Table {
  TextColumn get operationId => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get accountId => text()();
  TextColumn get companyId => text()();
  TextColumn get operationType => text()();
  TextColumn get targetResourceKey => text()();
  TextColumn get endpoint => text()();
  TextColumn get httpMethod => text().withDefault(const Constant('POST'))();
  TextColumn get payloadJson => text()();
  IntColumn get payloadVersion => integer().withDefault(const Constant(1))();
  TextColumn get state => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  DateTimeColumn get processingStartedAt => dateTime().nullable()();
  TextColumn get dependsOnOperationId => text().nullable()();
  TextColumn get lastErrorCode => text().nullable()();
  TextColumn get lastErrorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {operationId};
}

@TableIndex(name: 'attachment_operation_idx', columns: {#operationId})
class OutboxAttachments extends Table {
  TextColumn get attachmentId => text()();
  TextColumn get operationId => text().references(
    OutboxOperations,
    #operationId,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get fieldName => text()();
  TextColumn get durablePath => text()();
  TextColumn get originalName => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get checksum => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {attachmentId};
}

@TableIndex(name: 'cache_scope_idx', columns: {#accountId, #companyId})
@TableIndex(name: 'cache_expiry_idx', columns: {#expiresAt})
class ApiCache extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get accountId => text()();
  TextColumn get companyId => text()();
  TextColumn get endpointKey => text()();
  TextColumn get queryHash => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get etag => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {cacheKey};
}

@TableIndex(
  name: 'attendance_snapshot_scope_idx',
  columns: {#accountId, #companyId, #attendanceDate},
)
class AttendanceDaySnapshots extends Table {
  TextColumn get accountId => text()();
  TextColumn get companyId => text()();
  TextColumn get attendanceDate => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get serverTime => dateTime().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {accountId, companyId, attendanceDate};
}

@TableIndex(
  name: 'attendance_overtime_work_date_idx',
  columns: {#accountId, #companyId, #localWorkDate, #status},
)
class AttendanceOvertimeReferences extends Table {
  TextColumn get overtimeId => text()();
  TextColumn get accountId => text()();
  TextColumn get companyId => text()();
  TextColumn get overtimeDate => text()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  DateTimeColumn get startAtUtc => dateTime()();
  DateTimeColumn get endAtUtc => dateTime()();
  TextColumn get localWorkDate => text()();
  TextColumn get status => text()();
  TextColumn get title => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get locationType => text().nullable()();
  TextColumn get locationId => text().nullable()();
  TextColumn get locationName => text().nullable()();
  TextColumn get projectId => text().nullable()();
  TextColumn get projectName => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();
  TextColumn get sourceRangeStart => text()();
  TextColumn get sourceRangeEnd => text()();

  @override
  Set<Column<Object>> get primaryKey => {accountId, companyId, overtimeId};
}

@DriftDatabase(
  tables: [
    OutboxOperations,
    OutboxAttachments,
    ApiCache,
    AttendanceDaySnapshots,
    AttendanceOvertimeReferences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'curva_business'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(attendanceDaySnapshots);
        await migrator.createTable(attendanceOvertimeReferences);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS outbox_attendance_scope_idx '
          'ON outbox_operations '
          '(account_id, company_id, operation_type, state)',
        );
        await customStatement(
          "UPDATE outbox_operations SET operation_type = "
          "'attendance.check_in.v1' WHERE operation_type = "
          "'attendanceCheckIn'",
        );
        await customStatement(
          "UPDATE outbox_operations SET operation_type = "
          "'attendance.check_out.v1' WHERE operation_type = "
          "'attendanceCheckOut'",
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> clearAllData() {
    return transaction(() async {
      await delete(outboxAttachments).go();
      await delete(outboxOperations).go();
      await delete(apiCache).go();
      await delete(attendanceDaySnapshots).go();
      await delete(attendanceOvertimeReferences).go();
    });
  }

  Future<void> enqueueOperation(
    OutboxOperationsCompanion operation,
    List<OutboxAttachmentsCompanion> attachments,
  ) {
    return transaction(() async {
      final duplicate =
          await (select(outboxOperations)
                ..where(
                  (row) =>
                      row.accountId.equals(operation.accountId.value) &
                      row.companyId.equals(operation.companyId.value) &
                      row.operationType.equals(operation.operationType.value) &
                      row.targetResourceKey.equals(
                        operation.targetResourceKey.value,
                      ) &
                      row.state.isIn([
                        OutboxState.pending.name,
                        OutboxState.processing.name,
                        OutboxState.retry.name,
                        OutboxState.failed.name,
                        OutboxState.conflict.name,
                      ]),
                )
                ..limit(1))
              .getSingleOrNull();
      if (duplicate != null) {
        throw StateError(
          duplicate.state == OutboxState.failed.name ||
                  duplicate.state == OutboxState.conflict.name
              ? 'Aksi sebelumnya perlu diperiksa atau dibatalkan terlebih dahulu.'
              : 'Aksi yang sama sudah menunggu sinkronisasi.',
        );
      }
      await into(outboxOperations).insert(operation);
      if (attachments.isNotEmpty) {
        await batch((batch) {
          batch.insertAll(outboxAttachments, attachments);
        });
      }
    });
  }

  Stream<int> watchPendingCount(SyncScope scope) {
    final count = outboxOperations.operationId.count();
    final query = selectOnly(outboxOperations)
      ..addColumns([count])
      ..where(
        outboxOperations.accountId.equals(scope.accountId) &
            outboxOperations.companyId.equals(scope.companyId) &
            outboxOperations.state.isIn([
              OutboxState.pending.name,
              OutboxState.processing.name,
              OutboxState.retry.name,
            ]),
      );
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Stream<int> watchPendingCountForAccount(String accountId) {
    final count = outboxOperations.operationId.count();
    final query = selectOnly(outboxOperations)
      ..addColumns([count])
      ..where(
        outboxOperations.accountId.equals(accountId) &
            outboxOperations.state.isIn([
              OutboxState.pending.name,
              OutboxState.processing.name,
              OutboxState.retry.name,
            ]),
      );
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<List<SyncScope>> pendingScopesForAccount(String accountId) async {
    final query = selectOnly(outboxOperations, distinct: true)
      ..addColumns([outboxOperations.accountId, outboxOperations.companyId])
      ..where(
        outboxOperations.accountId.equals(accountId) &
            outboxOperations.state.isIn([
              OutboxState.pending.name,
              OutboxState.processing.name,
              OutboxState.retry.name,
            ]),
      );
    final rows = await query.get();
    return rows
        .map(
          (row) => SyncScope(
            accountId: row.read(outboxOperations.accountId)!,
            companyId: row.read(outboxOperations.companyId)!,
          ),
        )
        .toList(growable: false);
  }

  Future<int> makeRetriesDueForAccount(String accountId, DateTime now) {
    return (update(outboxOperations)..where(
          (row) =>
              row.accountId.equals(accountId) &
              row.state.equals(OutboxState.retry.name),
        ))
        .write(
          OutboxOperationsCompanion(
            nextAttemptAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> recoverLegacyAttendanceNetworkFailures(
    String accountId,
    DateTime now,
  ) {
    return transaction(() async {
      final failedAttendance =
          await (select(outboxOperations)..where(
                (row) =>
                    row.accountId.equals(accountId) &
                    row.operationType.isIn([
                      SyncOperationType.attendanceCheckIn.storageName,
                      SyncOperationType.attendanceCheckOut.storageName,
                    ]) &
                    row.state.equals(OutboxState.failed.name) &
                    row.lastErrorCode.isNull(),
              ))
              .get();
      final recoverableIds = failedAttendance
          .where(
            (operation) =>
                _looksLikeLegacyNetworkFailure(operation.lastErrorMessage),
          )
          .map((operation) => operation.operationId)
          .toSet();
      if (recoverableIds.isEmpty) return;

      await (update(outboxOperations)..where(
            (row) =>
                row.operationId.isIn(recoverableIds) &
                row.state.equals(OutboxState.failed.name),
          ))
          .write(
            OutboxOperationsCompanion(
              state: Value(OutboxState.retry.name),
              nextAttemptAt: Value(now),
              processingStartedAt: const Value(null),
              lastErrorCode: const Value(null),
              lastErrorMessage: const Value(null),
              updatedAt: Value(now),
            ),
          );

      await (update(outboxOperations)..where(
            (row) =>
                row.accountId.equals(accountId) &
                row.operationType.equals(
                  SyncOperationType.attendanceCheckOut.storageName,
                ) &
                row.state.equals(OutboxState.failed.name) &
                row.lastErrorCode.equals('DEPENDENCY_FAILED') &
                row.dependsOnOperationId.isIn(recoverableIds),
          ))
          .write(
            OutboxOperationsCompanion(
              state: Value(OutboxState.pending.name),
              nextAttemptAt: Value(now),
              processingStartedAt: const Value(null),
              lastErrorCode: const Value(null),
              lastErrorMessage: const Value(null),
              updatedAt: Value(now),
            ),
          );
    });
  }

  bool _looksLikeLegacyNetworkFailure(String? message) {
    final normalized = message?.toLowerCase() ?? '';
    return normalized.contains('socketexception') ||
        normalized.contains('socket exception') ||
        normalized.contains('failed host lookup') ||
        normalized.contains('network is unreachable') ||
        normalized.contains('connection error') ||
        normalized.contains('connection reset') ||
        normalized.contains('connection refused') ||
        normalized.contains('connection aborted') ||
        normalized.contains('sinkronisasi gagal');
  }

  Future<List<OutboxOperation>> listOperations(SyncScope scope) {
    return (select(outboxOperations)
          ..where(
            (row) =>
                row.accountId.equals(scope.accountId) &
                row.companyId.equals(scope.companyId),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
        .get();
  }

  Stream<List<OutboxOperation>> watchOperations(SyncScope scope) {
    return (select(outboxOperations)
          ..where(
            (row) =>
                row.accountId.equals(scope.accountId) &
                row.companyId.equals(scope.companyId),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .watch();
  }

  Future<List<OutboxAttachment>> attachmentsFor(String operationId) {
    return (select(
      outboxAttachments,
    )..where((row) => row.operationId.equals(operationId))).get();
  }

  Future<bool> hasActiveOperation(
    SyncScope scope,
    SyncOperationType operationType,
    String targetResourceKey,
  ) async {
    final row =
        await (select(outboxOperations)
              ..where(
                (row) =>
                    row.accountId.equals(scope.accountId) &
                    row.companyId.equals(scope.companyId) &
                    row.operationType.equals(operationType.storageName) &
                    row.targetResourceKey.equals(targetResourceKey) &
                    row.state.isIn([
                      OutboxState.pending.name,
                      OutboxState.processing.name,
                      OutboxState.retry.name,
                    ]),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<DateTime?> nextRetryAtForAccount(String accountId) async {
    final query = select(outboxOperations)
      ..where(
        (row) =>
            row.accountId.equals(accountId) &
            row.state.equals(OutboxState.retry.name) &
            row.nextAttemptAt.isNotNull(),
      )
      ..orderBy([(row) => OrderingTerm.asc(row.nextAttemptAt)])
      ..limit(1);
    return (await query.getSingleOrNull())?.nextAttemptAt;
  }

  Future<OutboxOperation?> activeOperation(
    SyncScope scope,
    SyncOperationType operationType,
    String targetResourceKey,
  ) {
    return (select(outboxOperations)
          ..where(
            (row) =>
                row.accountId.equals(scope.accountId) &
                row.companyId.equals(scope.companyId) &
                row.operationType.equals(operationType.storageName) &
                row.targetResourceKey.equals(targetResourceKey) &
                row.state.isIn([
                  OutboxState.pending.name,
                  OutboxState.processing.name,
                  OutboxState.retry.name,
                ]),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<OutboxOperation?> claimNextOperation(
    SyncScope scope, {
    required DateTime now,
    Duration processingTimeout = const Duration(minutes: 10),
  }) {
    return transaction(() async {
      final stuckBefore = now.subtract(processingTimeout);
      await (update(outboxOperations)..where(
            (row) =>
                row.accountId.equals(scope.accountId) &
                row.companyId.equals(scope.companyId) &
                row.state.equals(OutboxState.processing.name) &
                row.processingStartedAt.isSmallerThanValue(stuckBefore),
          ))
          .write(
            OutboxOperationsCompanion(
              state: Value(OutboxState.retry.name),
              nextAttemptAt: Value(now),
              processingStartedAt: const Value(null),
              updatedAt: Value(now),
            ),
          );

      final candidates =
          await (select(outboxOperations)
                ..where(
                  (row) =>
                      row.accountId.equals(scope.accountId) &
                      row.companyId.equals(scope.companyId) &
                      row.state.isIn([
                        OutboxState.pending.name,
                        OutboxState.retry.name,
                      ]) &
                      (row.nextAttemptAt.isNull() |
                          row.nextAttemptAt.isSmallerOrEqualValue(now)),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.createdAt)])
                ..limit(20))
              .get();

      for (final candidate in candidates) {
        final dependencyId = candidate.dependsOnOperationId;
        if (dependencyId != null) {
          final dependency =
              await (select(outboxOperations)
                    ..where((row) => row.operationId.equals(dependencyId)))
                  .getSingleOrNull();
          if (dependency?.state != OutboxState.done.name) {
            if (dependency == null ||
                dependency.state == OutboxState.failed.name ||
                dependency.state == OutboxState.conflict.name ||
                dependency.state == OutboxState.rejected.name) {
              await (update(outboxOperations)..where(
                    (row) => row.operationId.equals(candidate.operationId),
                  ))
                  .write(
                    OutboxOperationsCompanion(
                      state: Value(OutboxState.failed.name),
                      lastErrorCode: const Value('DEPENDENCY_FAILED'),
                      lastErrorMessage: const Value(
                        'Check-in terkait gagal sehingga check-out tidak dapat dikirim.',
                      ),
                      nextAttemptAt: const Value(null),
                      updatedAt: Value(now),
                    ),
                  );
            }
            continue;
          }
        }

        final claimed =
            await (update(outboxOperations)..where(
                  (row) =>
                      row.operationId.equals(candidate.operationId) &
                      row.state.isIn([
                        OutboxState.pending.name,
                        OutboxState.retry.name,
                      ]),
                ))
                .write(
                  OutboxOperationsCompanion(
                    state: Value(OutboxState.processing.name),
                    processingStartedAt: Value(now),
                    updatedAt: Value(now),
                  ),
                );
        if (claimed == 1) {
          return candidate.copyWith(
            state: OutboxState.processing.name,
            processingStartedAt: Value(now),
            updatedAt: now,
          );
        }
      }
      return null;
    });
  }

  Future<void> updateOperationState({
    required String operationId,
    required OutboxState state,
    required DateTime updatedAt,
    int? attemptCount,
    DateTime? nextAttemptAt,
    String? errorCode,
    String? errorMessage,
  }) {
    return (update(
      outboxOperations,
    )..where((row) => row.operationId.equals(operationId))).write(
      OutboxOperationsCompanion(
        state: Value(state.name),
        attemptCount: attemptCount == null
            ? const Value.absent()
            : Value(attemptCount),
        nextAttemptAt: Value(nextAttemptAt),
        processingStartedAt: const Value(null),
        lastErrorCode: Value(errorCode),
        lastErrorMessage: Value(errorMessage),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<void> completeOperation({
    required String operationId,
    required int attemptCount,
    required DateTime updatedAt,
    ApiCacheCompanion? canonicalCache,
  }) {
    return transaction(() async {
      if (canonicalCache != null) {
        await into(apiCache).insertOnConflictUpdate(canonicalCache);
      }
      await (update(
        outboxOperations,
      )..where((row) => row.operationId.equals(operationId))).write(
        OutboxOperationsCompanion(
          state: Value(OutboxState.done.name),
          attemptCount: Value(attemptCount),
          nextAttemptAt: const Value(null),
          processingStartedAt: const Value(null),
          lastErrorCode: const Value(null),
          lastErrorMessage: const Value(null),
          updatedAt: Value(updatedAt),
        ),
      );
    });
  }

  Future<void> deleteAttachmentMetadata(String operationId) {
    return (delete(
      outboxAttachments,
    )..where((row) => row.operationId.equals(operationId))).go();
  }

  Stream<OutboxOperation?> watchTargetOperation({
    required SyncScope scope,
    required SyncOperationType operationType,
    required String targetResourceKey,
  }) {
    final query = select(outboxOperations)
      ..where(
        (row) =>
            row.accountId.equals(scope.accountId) &
            row.companyId.equals(scope.companyId) &
            row.operationType.equals(operationType.storageName) &
            row.targetResourceKey.equals(targetResourceKey) &
            row.state.isNotValue(OutboxState.done.name),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Stream<ApiCacheData?> watchCache(String cacheKey, SyncScope scope) {
    return (select(apiCache)..where(
          (row) =>
              row.cacheKey.equals(cacheKey) &
              row.accountId.equals(scope.accountId) &
              row.companyId.equals(scope.companyId),
        ))
        .watchSingleOrNull();
  }

  Future<ApiCacheData?> getCache(String cacheKey, SyncScope scope) {
    return (select(apiCache)..where(
          (row) =>
              row.cacheKey.equals(cacheKey) &
              row.accountId.equals(scope.accountId) &
              row.companyId.equals(scope.companyId),
        ))
        .getSingleOrNull();
  }

  Stream<List<ApiCacheData>> watchCacheForScope(SyncScope scope) {
    return (select(apiCache)..where(
          (row) =>
              row.accountId.equals(scope.accountId) &
              row.companyId.equals(scope.companyId),
        ))
        .watch();
  }

  Future<void> putCache(ApiCacheCompanion entry) {
    return into(apiCache).insertOnConflictUpdate(entry);
  }

  Future<int> deleteExpiredCache(DateTime now) {
    return (delete(apiCache)..where(
          (row) =>
              row.expiresAt.isNotNull() & row.expiresAt.isSmallerThanValue(now),
        ))
        .go();
  }

  Future<void> deleteScope(SyncScope scope) {
    return transaction(() async {
      await (delete(apiCache)..where(
            (row) =>
                row.accountId.equals(scope.accountId) &
                row.companyId.equals(scope.companyId),
          ))
          .go();
      await (delete(attendanceDaySnapshots)..where(
            (row) =>
                row.accountId.equals(scope.accountId) &
                row.companyId.equals(scope.companyId),
          ))
          .go();
      await (delete(attendanceOvertimeReferences)..where(
            (row) =>
                row.accountId.equals(scope.accountId) &
                row.companyId.equals(scope.companyId),
          ))
          .go();
      await (delete(outboxOperations)..where(
            (row) =>
                row.accountId.equals(scope.accountId) &
                row.companyId.equals(scope.companyId),
          ))
          .go();
    });
  }

  Future<void> putAttendanceSnapshot(
    AttendanceDaySnapshotsCompanion snapshot,
  ) => into(attendanceDaySnapshots).insertOnConflictUpdate(snapshot);

  Stream<AttendanceDaySnapshot?> watchAttendanceSnapshot(
    SyncScope scope,
    String attendanceDate,
  ) =>
      (select(attendanceDaySnapshots)..where(
            (row) =>
                row.accountId.equals(scope.accountId) &
                row.companyId.equals(scope.companyId) &
                row.attendanceDate.equals(attendanceDate),
          ))
          .watchSingleOrNull();

  Future<AttendanceDaySnapshot?> getAttendanceSnapshot(
    SyncScope scope,
    String attendanceDate,
  ) =>
      (select(attendanceDaySnapshots)..where(
            (row) =>
                row.accountId.equals(scope.accountId) &
                row.companyId.equals(scope.companyId) &
                row.attendanceDate.equals(attendanceDate),
          ))
          .getSingleOrNull();

  Future<void> replaceAttendanceOvertimeReferences({
    required SyncScope scope,
    required String rangeStart,
    required String rangeEnd,
    required List<AttendanceOvertimeReferencesCompanion> references,
  }) {
    return transaction(() async {
      if (references.isNotEmpty) {
        await batch((batch) {
          batch.insertAllOnConflictUpdate(
            attendanceOvertimeReferences,
            references,
          );
        });
      }
      // A successful full-page refresh is authoritative for this range. Keep
      // rows referenced by an outbox payload; deleting those is deferred until
      // the operation is reconciled.
      final existing =
          await (select(attendanceOvertimeReferences)..where(
                (row) =>
                    row.accountId.equals(scope.accountId) &
                    row.companyId.equals(scope.companyId) &
                    row.overtimeDate.isBiggerOrEqualValue(rangeStart) &
                    row.overtimeDate.isSmallerOrEqualValue(rangeEnd),
              ))
              .get();
      final incoming = references.map((item) => item.overtimeId.value).toSet();
      final operations = await listAttendanceOperations(scope);
      for (final row in existing.where(
        (row) => !incoming.contains(row.overtimeId),
      )) {
        final referenced = operations.any(
          (operation) => operation.payloadJson.contains(row.overtimeId),
        );
        if (!referenced) {
          await (delete(attendanceOvertimeReferences)..where(
                (item) =>
                    item.accountId.equals(scope.accountId) &
                    item.companyId.equals(scope.companyId) &
                    item.overtimeId.equals(row.overtimeId),
              ))
              .go();
        }
      }
    });
  }

  Future<void> upsertAttendanceOvertimeReferences(
    List<AttendanceOvertimeReferencesCompanion> references,
  ) async {
    if (references.isEmpty) return;
    await batch((batch) {
      batch.insertAllOnConflictUpdate(attendanceOvertimeReferences, references);
    });
  }

  Stream<List<AttendanceOvertimeReference>> watchApprovedOvertimeReferences(
    SyncScope scope,
    String localWorkDate,
  ) =>
      (select(attendanceOvertimeReferences)
            ..where(
              (row) =>
                  row.accountId.equals(scope.accountId) &
                  row.companyId.equals(scope.companyId) &
                  row.localWorkDate.equals(localWorkDate) &
                  row.status.equals('approved'),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.startAtUtc)]))
          .watch();

  Stream<List<OutboxOperation>> watchAttendanceOperations(SyncScope scope) =>
      (select(outboxOperations)
            ..where(
              (row) =>
                  row.accountId.equals(scope.accountId) &
                  row.companyId.equals(scope.companyId) &
                  row.operationType.isIn([
                    SyncOperationType.attendanceCheckIn.storageName,
                    SyncOperationType.attendanceCheckOut.storageName,
                  ]),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .watch();

  Future<List<OutboxOperation>> listAttendanceOperations(SyncScope scope) =>
      (select(outboxOperations)
            ..where(
              (row) =>
                  row.accountId.equals(scope.accountId) &
                  row.companyId.equals(scope.companyId) &
                  row.operationType.isIn([
                    SyncOperationType.attendanceCheckIn.storageName,
                    SyncOperationType.attendanceCheckOut.storageName,
                  ]),
            )
            ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
          .get();

  Future<void> deleteRejectedOperation(String operationId) {
    return transaction(() async {
      final operation = await (select(
        outboxOperations,
      )..where((row) => row.operationId.equals(operationId))).getSingleOrNull();
      if (operation == null || operation.state != OutboxState.rejected.name) {
        throw StateError('Hanya presensi rejected yang dapat dihapus.');
      }
      await (delete(
        outboxOperations,
      )..where((row) => row.operationId.equals(operationId))).go();
    });
  }
}

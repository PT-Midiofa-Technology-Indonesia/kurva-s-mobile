import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/database/app_database.dart';
import 'package:curva_mobile/core/errors/error_mapper.dart';
import 'package:curva_mobile/core/errors/sync_failure.dart';
import 'package:curva_mobile/core/files/durable_file_store.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/core/sync/outbox_service.dart';
import 'package:curva_mobile/core/sync/retry_policy.dart';
import 'package:curva_mobile/core/sync/sync_coordinator.dart';
import 'package:curva_mobile/core/sync/sync_engine.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/core/sync/sync_policy.dart';
import 'package:curva_mobile/modules/workforce/data/attendance_repository.dart';
import 'package:curva_mobile/modules/workforce/data/local/attendance_local_data_source.dart';
import 'package:curva_mobile/modules/workforce/data/local/attendance_projection.dart';
import 'package:curva_mobile/modules/workforce/data/local/workforce_get_cache.dart';
import 'package:curva_mobile/modules/workforce/data/models/attendance_list.dart';
import 'package:curva_mobile/modules/workforce/data/models/attendance_operation_payload.dart';
import 'package:curva_mobile/modules/workforce/data/models/effective_today_attendance.dart';
import 'package:curva_mobile/modules/workforce/data/models/overtime.dart';
import 'package:curva_mobile/modules/workforce/data/models/today_attendance.dart';
import 'package:curva_mobile/modules/workforce/data/workforce_repository.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';

void main() {
  const scope = SyncScope(accountId: 'account-1', companyId: 'company-1');

  setUpAll(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
  });

  test('attendance payload serializes occurredAt as UTC', () {
    final payload = AttendanceOperationPayload(
      clientSessionId: 'session-1',
      action: AttendanceAction.checkIn,
      type: AttendanceType.regular,
      occurredAt: DateTime.parse('2026-07-22T08:15:20+07:00'),
      timezoneOffsetMinutes: 420,
      latitude: -6.2,
      longitude: 106.8,
    );

    final json = payload.toJson();
    final restored = AttendanceOperationPayload.fromJson(json);

    expect(json['payloadVersion'], 1);
    expect(json['occurredAt'], '2026-07-22T01:15:20.000Z');
    expect(restored.occurredAt.isUtc, isTrue);
    expect(restored.clientSessionId, 'session-1');
  });

  test('overtime check-in is blocked while regular session is open', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final harness = await _attendanceHarness(database, scope);
    final now = DateTime.now();
    await harness.local.putTodaySnapshot(
      scope: scope,
      attendance: TodayAttendance(
        date: formatDateParam(now)!,
        serverTime: now.toUtc().toIso8601String(),
        regular: const RegularAttendance(
          checkedIn: true,
          checkedOut: false,
          clientSessionId: 'regular-session',
          workplace: null,
        ),
        overtime: const OvertimeAttendance(available: true),
      ),
    );

    final result = await harness.repository.enqueueCheckIn(
      capture: AttendanceCapture(
        selfiePath: harness.selfiePath,
        latitude: -6.2,
        longitude: 106.8,
      ),
      type: AttendanceType.overtime,
      overtimeId: 'overtime-1',
    );

    expect(result, isA<AttendanceStoreFailed>());
    expect(
      (result as AttendanceStoreFailed).message,
      contains('check-out regular'),
    );
    expect(await database.listAttendanceOperations(scope), isEmpty);
  });

  test('regular check-in is blocked while overtime session is open', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final harness = await _attendanceHarness(database, scope);
    final now = DateTime.now();
    await harness.local.putTodaySnapshot(
      scope: scope,
      attendance: TodayAttendance(
        date: formatDateParam(now)!,
        serverTime: now.toUtc().toIso8601String(),
        regular: const RegularAttendance(
          checkedIn: false,
          checkedOut: false,
          workplace: null,
        ),
        overtime: const OvertimeAttendance(
          available: true,
          overtimeId: 'overtime-1',
          checkedIn: true,
          checkedOut: false,
          clientSessionId: 'overtime-session',
        ),
      ),
    );

    final result = await harness.repository.enqueueCheckIn(
      capture: AttendanceCapture(
        selfiePath: harness.selfiePath,
        latitude: -6.2,
        longitude: 106.8,
      ),
      type: AttendanceType.regular,
    );

    expect(result, isA<AttendanceStoreFailed>());
    expect(
      (result as AttendanceStoreFailed).message,
      contains('check-out lembur'),
    );
    expect(await database.listAttendanceOperations(scope), isEmpty);
  });

  test('a completed overtime blocks another attendance check-in', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final harness = await _attendanceHarness(database, scope);
    final now = DateTime.now();
    await harness.local.putTodaySnapshot(
      scope: scope,
      attendance: TodayAttendance(
        date: formatDateParam(now)!,
        serverTime: now.toUtc().toIso8601String(),
        regular: const RegularAttendance(
          checkedIn: false,
          checkedOut: false,
          workplace: null,
        ),
        overtime: const OvertimeAttendance(
          available: true,
          overtimeId: 'overtime-1',
          checkedIn: true,
          checkedOut: true,
          clientSessionId: 'completed-overtime-session',
        ),
      ),
    );

    for (final type in AttendanceType.values) {
      final result = await harness.repository.enqueueCheckIn(
        capture: AttendanceCapture(
          selfiePath: harness.selfiePath,
          latitude: -6.2,
          longitude: 106.8,
        ),
        type: type,
        overtimeId: type == AttendanceType.overtime ? 'overtime-1' : null,
      );

      expect(result, isA<AttendanceStoreFailed>());
      expect(
        (result as AttendanceStoreFailed).message,
        'Presensi lembur hari ini sudah selesai.',
      );
    }
    expect(await database.listAttendanceOperations(scope), isEmpty);
  });

  test(
    'a completed overtime yesterday allows regular and overtime today',
    () async {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1, 18);

      for (final newType in AttendanceType.values) {
        final database = AppDatabase(NativeDatabase.memory());
        final harness = await _attendanceHarness(database, scope);
        final today = formatDateParam(now)!;
        await database
            .into(database.attendanceOvertimeReferences)
            .insert(
              AttendanceOvertimeReferencesCompanion.insert(
                overtimeId: 'today-approved-overtime',
                accountId: scope.accountId,
                companyId: scope.companyId,
                overtimeDate: today,
                startTime: '18:00:00',
                endTime: '20:00:00',
                startAtUtc: DateTime(now.year, now.month, now.day, 18).toUtc(),
                endAtUtc: DateTime(now.year, now.month, now.day, 20).toUtc(),
                localWorkDate: today,
                status: 'approved',
                fetchedAt: now.toUtc(),
                sourceRangeStart: today,
                sourceRangeEnd: today,
              ),
            );

        for (final action in AttendanceAction.values) {
          final occurredAt = yesterday.add(
            action == AttendanceAction.checkIn
                ? Duration.zero
                : const Duration(hours: 2),
          );
          final operationId = '${newType.name}-${action.name}-yesterday';
          await database.enqueueOperation(
            OutboxOperationsCompanion.insert(
              operationId: operationId,
              idempotencyKey: operationId,
              accountId: scope.accountId,
              companyId: scope.companyId,
              operationType: action == AttendanceAction.checkIn
                  ? SyncOperationType.attendanceCheckIn.storageName
                  : SyncOperationType.attendanceCheckOut.storageName,
              targetResourceKey: 'attendance:a:overtime:yesterday-session',
              endpoint: '/attendance',
              payloadJson: jsonEncode(
                AttendanceOperationPayload(
                  clientSessionId: 'yesterday-session',
                  action: action,
                  type: AttendanceType.overtime,
                  overtimeId: 'yesterday-overtime',
                  occurredAt: occurredAt,
                  timezoneOffsetMinutes: occurredAt.timeZoneOffset.inMinutes,
                  latitude: -6.2,
                  longitude: 106.8,
                ).toJson(),
              ),
              state: Value(OutboxState.done.name),
              createdAt: occurredAt.toUtc(),
              updatedAt: occurredAt.toUtc(),
            ),
            const [],
          );
        }

        final beforeCheckIn = await harness.local
            .watchEffectiveToday(scope, workDate: now)
            .first;
        expect(beforeCheckIn.hasCompletedOvertime, isFalse);
        expect(beforeCheckIn.regular.canCheckIn, isTrue);
        expect(
          beforeCheckIn.referenceState,
          AttendanceReferenceState.available,
        );

        final result = await harness.repository.enqueueCheckIn(
          capture: AttendanceCapture(
            selfiePath: harness.selfiePath,
            latitude: -6.2,
            longitude: 106.8,
          ),
          type: newType,
          overtimeId: newType == AttendanceType.overtime
              ? 'today-approved-overtime'
              : null,
        );

        expect(result, isA<AttendanceStored>());
        await database.close();
      }
    },
  );

  test(
    'an unsynced open session from yesterday still blocks check-in',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final harness = await _attendanceHarness(database, scope);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await database.enqueueOperation(
        OutboxOperationsCompanion.insert(
          operationId: 'yesterday-regular-check-in',
          idempotencyKey: 'yesterday-regular-check-in',
          accountId: scope.accountId,
          companyId: scope.companyId,
          operationType: SyncOperationType.attendanceCheckIn.storageName,
          targetResourceKey: 'attendance:a:regular:yesterday-session',
          endpoint: '/attendance',
          payloadJson: jsonEncode(
            AttendanceOperationPayload(
              clientSessionId: 'yesterday-session',
              action: AttendanceAction.checkIn,
              type: AttendanceType.regular,
              occurredAt: yesterday,
              timezoneOffsetMinutes: yesterday.timeZoneOffset.inMinutes,
              latitude: -6.2,
              longitude: 106.8,
            ).toJson(),
          ),
          state: Value(OutboxState.pending.name),
          createdAt: yesterday.toUtc(),
          updatedAt: yesterday.toUtc(),
        ),
        const [],
      );

      final result = await harness.repository.enqueueCheckIn(
        capture: AttendanceCapture(
          selfiePath: harness.selfiePath,
          latitude: -6.2,
          longitude: 106.8,
        ),
        type: AttendanceType.overtime,
        overtimeId: 'overtime-1',
      );

      expect(result, isA<AttendanceStoreFailed>());
      expect(
        (result as AttendanceStoreFailed).message,
        contains('check-out regular'),
      );
    },
  );

  test(
    'new attendance waits for the previous local check-out before syncing',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final harness = await _attendanceHarness(database, scope);
      final now = DateTime.now();

      for (final action in AttendanceAction.values) {
        final operationId = action == AttendanceAction.checkIn
            ? 'regular-check-in'
            : 'regular-check-out';
        await database.enqueueOperation(
          OutboxOperationsCompanion.insert(
            operationId: operationId,
            idempotencyKey: operationId,
            accountId: scope.accountId,
            companyId: scope.companyId,
            operationType: action == AttendanceAction.checkIn
                ? SyncOperationType.attendanceCheckIn.storageName
                : SyncOperationType.attendanceCheckOut.storageName,
            targetResourceKey: 'attendance:a:regular:regular-session',
            endpoint: '/attendance',
            payloadJson: jsonEncode(
              AttendanceOperationPayload(
                clientSessionId: 'regular-session',
                action: action,
                type: AttendanceType.regular,
                occurredAt: now.add(
                  action == AttendanceAction.checkIn
                      ? Duration.zero
                      : const Duration(minutes: 1),
                ),
                timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
                latitude: -6.2,
                longitude: 106.8,
              ).toJson(),
            ),
            state: Value(
              action == AttendanceAction.checkIn
                  ? OutboxState.done.name
                  : OutboxState.pending.name,
            ),
            createdAt: now.toUtc(),
            updatedAt: now.toUtc(),
          ),
          const [],
        );
      }

      final result = await harness.repository.enqueueCheckIn(
        capture: AttendanceCapture(
          selfiePath: harness.selfiePath,
          latitude: -6.2,
          longitude: 106.8,
        ),
        type: AttendanceType.overtime,
        overtimeId: 'overtime-1',
      );

      expect(result, isA<AttendanceStored>());
      final operations = await database.listAttendanceOperations(scope);
      final stored = result as AttendanceStored;
      final overtimeCheckIn = operations.singleWhere(
        (operation) => operation.operationId == stored.operationId,
      );
      expect(overtimeCheckIn.dependsOnOperationId, 'regular-check-out');
    },
  );

  test('client accepts attendance event without an age limit', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final harness = await _attendanceHarness(database, scope);

    final result = await harness.repository.enqueueCheckIn(
      capture: AttendanceCapture(
        selfiePath: harness.selfiePath,
        latitude: -6.2,
        longitude: 106.8,
        occurredAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      type: AttendanceType.regular,
    );

    expect(result, isA<AttendanceStored>());
  });

  test('regular projection works without a server snapshot', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.parse('2026-07-22T01:15:20Z');
    await database.enqueueOperation(
      OutboxOperationsCompanion.insert(
        operationId: 'event-1',
        idempotencyKey: 'event-1',
        accountId: scope.accountId,
        companyId: scope.companyId,
        operationType: SyncOperationType.attendanceCheckIn.storageName,
        targetResourceKey: 'attendance:account-1:regular:session-1',
        endpoint: '/v1/mobile/attendance/check-in',
        payloadJson: jsonEncode(
          AttendanceOperationPayload(
            clientSessionId: 'session-1',
            action: AttendanceAction.checkIn,
            type: AttendanceType.regular,
            occurredAt: now,
            timezoneOffsetMinutes: 420,
            latitude: -6.2,
            longitude: 106.8,
          ).toJson(),
        ),
        createdAt: now,
        updatedAt: now,
      ),
      const [],
    );

    final effective = AttendanceProjection.project(
      snapshot: null,
      operations: await database.listAttendanceOperations(scope),
      hasApprovedOvertimeReferences: false,
      workDate: DateTime(2026, 7, 22),
    );

    expect(effective.regular.checkedIn, isTrue);
    expect(effective.regular.hasOpenAttendance, isTrue);
    expect(effective.referenceState.name, 'regularOnly');
    expect(effective.syncSummary.pending, 1);
  });

  test('today attendance exposes overtime before cached references', () {
    final effective = AttendanceProjection.project(
      snapshot: const TodayAttendance(
        date: '2026-07-22',
        serverTime: '2026-07-22T10:00:00Z',
        regular: RegularAttendance(
          checkedIn: false,
          checkedOut: false,
          workplace: null,
        ),
        overtime: OvertimeAttendance(
          available: true,
          overtimeId: 'today-overtime',
          reason: 'Stock opname',
          startTime: '18:00:00',
          endTime: '20:00:00',
        ),
      ),
      operations: const [],
      hasApprovedOvertimeReferences: false,
      workDate: DateTime(2026, 7, 22),
    );

    expect(effective.referenceState, AttendanceReferenceState.available);
    expect(effective.snapshot?.overtime.overtimeId, 'today-overtime');
  });

  test('completed overtime disables cached overtime references', () {
    final effective = AttendanceProjection.project(
      snapshot: const TodayAttendance(
        date: '2026-07-22',
        serverTime: '2026-07-22T13:00:00Z',
        regular: RegularAttendance(
          checkedIn: false,
          checkedOut: false,
          workplace: null,
        ),
        overtime: OvertimeAttendance(
          available: true,
          overtimeId: 'completed-overtime',
          checkedIn: true,
          checkedOut: true,
          clientSessionId: 'completed-session',
        ),
      ),
      operations: const [],
      hasApprovedOvertimeReferences: true,
      workDate: DateTime(2026, 7, 22),
    );

    expect(effective.hasCompletedOvertime, isTrue);
    expect(effective.referenceState, AttendanceReferenceState.regularOnly);
  });

  test('yesterday overtime does not hide today approved reference', () {
    final yesterdayCheckIn = DateTime(2026, 7, 21, 18);
    final operations = AttendanceAction.values
        .map((action) {
          final occurredAt = yesterdayCheckIn.add(
            action == AttendanceAction.checkIn
                ? Duration.zero
                : const Duration(hours: 2),
          );
          return OutboxOperation(
            operationId: action.name,
            idempotencyKey: action.name,
            accountId: scope.accountId,
            companyId: scope.companyId,
            operationType: action == AttendanceAction.checkIn
                ? SyncOperationType.attendanceCheckIn.storageName
                : SyncOperationType.attendanceCheckOut.storageName,
            targetResourceKey: 'attendance:a:overtime:yesterday-session',
            endpoint: '/attendance',
            httpMethod: 'POST',
            payloadJson: jsonEncode(
              AttendanceOperationPayload(
                clientSessionId: 'yesterday-session',
                action: action,
                type: AttendanceType.overtime,
                overtimeId: 'yesterday-overtime',
                occurredAt: occurredAt,
                timezoneOffsetMinutes: occurredAt.timeZoneOffset.inMinutes,
                latitude: -6.2,
                longitude: 106.8,
              ).toJson(),
            ),
            payloadVersion: 1,
            state: OutboxState.done.name,
            attemptCount: 0,
            createdAt: occurredAt.toUtc(),
            updatedAt: occurredAt.toUtc(),
          );
        })
        .toList(growable: false);

    final effective = AttendanceProjection.project(
      snapshot: null,
      operations: operations,
      hasApprovedOvertimeReferences: true,
      workDate: DateTime(2026, 7, 22),
    );

    expect(effective.hasCompletedOvertime, isFalse);
    expect(effective.regular.canCheckIn, isTrue);
    expect(effective.referenceState, AttendanceReferenceState.available);
  });

  test(
    'a new check-in resets a completed snapshot to an open session',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final now = DateTime.now();
      await database.enqueueOperation(
        OutboxOperationsCompanion.insert(
          operationId: 'new-check-in',
          idempotencyKey: 'new-check-in',
          accountId: scope.accountId,
          companyId: scope.companyId,
          operationType: SyncOperationType.attendanceCheckIn.storageName,
          targetResourceKey: 'attendance:a:regular:new-session',
          endpoint: '/v1/mobile/attendance/check-in',
          payloadJson: jsonEncode(
            AttendanceOperationPayload(
              clientSessionId: 'new-session',
              action: AttendanceAction.checkIn,
              type: AttendanceType.regular,
              occurredAt: now,
              timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
              latitude: -6.2,
              longitude: 106.8,
            ).toJson(),
          ),
          state: Value(OutboxState.done.name),
          createdAt: now.toUtc(),
          updatedAt: now.toUtc(),
        ),
        const [],
      );

      final effective = AttendanceProjection.project(
        snapshot: TodayAttendance(
          date: formatDateParam(now)!,
          serverTime: now.toUtc().toIso8601String(),
          regular: const RegularAttendance(
            checkedIn: false,
            checkedOut: true,
            workplace: null,
          ),
          overtime: const OvertimeAttendance(available: false),
        ),
        operations: await database.listAttendanceOperations(scope),
        hasApprovedOvertimeReferences: false,
        workDate: now,
      );

      expect(effective.regular.checkedIn, isTrue);
      expect(effective.regular.checkedOut, isFalse);
      expect(effective.regular.hasOpenAttendance, isTrue);
      expect(effective.openPresence, same(effective.regular));
      expect(effective.regular.clientSessionId, 'new-session');
    },
  );

  test(
    'effective attendance first emission includes the new local check-in',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final local = AttendanceLocalDataSource(database: database);
      final now = DateTime.now();
      await local.putTodaySnapshot(
        scope: scope,
        attendance: TodayAttendance(
          date: formatDateParam(now)!,
          serverTime: now.toUtc().toIso8601String(),
          regular: const RegularAttendance(
            checkedIn: true,
            checkedOut: true,
            workplace: null,
          ),
          overtime: const OvertimeAttendance(available: false),
        ),
      );
      await database.enqueueOperation(
        OutboxOperationsCompanion.insert(
          operationId: 'latest-check-in',
          idempotencyKey: 'latest-check-in',
          accountId: scope.accountId,
          companyId: scope.companyId,
          operationType: SyncOperationType.attendanceCheckIn.storageName,
          targetResourceKey: 'attendance:a:regular:latest-session',
          endpoint: '/v1/mobile/attendance/check-in',
          payloadJson: jsonEncode(
            AttendanceOperationPayload(
              clientSessionId: 'latest-session',
              action: AttendanceAction.checkIn,
              type: AttendanceType.regular,
              occurredAt: now,
              timezoneOffsetMinutes: now.timeZoneOffset.inMinutes,
              latitude: -6.2,
              longitude: 106.8,
            ).toJson(),
          ),
          state: Value(OutboxState.done.name),
          createdAt: now.toUtc(),
          updatedAt: now.toUtc(),
        ),
        const [],
      );

      final first = await local.watchEffectiveToday(scope).first;

      expect(first.openPresence, isA<EffectivePresence>());
      expect(first.regular.hasOpenAttendance, isTrue);
      expect(first.regular.clientSessionId, 'latest-session');
    },
  );

  test('a locally stored check-in remains open after a sync failure', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now().toUtc();
    await database.enqueueOperation(
      OutboxOperationsCompanion.insert(
        operationId: 'failed-check-in',
        idempotencyKey: 'failed-check-in',
        accountId: scope.accountId,
        companyId: scope.companyId,
        operationType: SyncOperationType.attendanceCheckIn.storageName,
        targetResourceKey: 'attendance:a:regular:session-failed',
        endpoint: '/attendance',
        payloadJson: jsonEncode(
          AttendanceOperationPayload(
            clientSessionId: 'session-failed',
            action: AttendanceAction.checkIn,
            type: AttendanceType.regular,
            occurredAt: now,
            timezoneOffsetMinutes: 420,
            latitude: -6.2,
            longitude: 106.8,
          ).toJson(),
        ),
        state: Value(OutboxState.failed.name),
        createdAt: now,
        updatedAt: now,
      ),
      const [],
    );

    final effective = AttendanceProjection.project(
      snapshot: null,
      operations: await database.listAttendanceOperations(scope),
      hasApprovedOvertimeReferences: false,
    );

    expect(effective.regular.hasOpenAttendance, isTrue);
    expect(effective.openPresence, same(effective.regular));
    expect(effective.regular.state, OutboxState.failed);
  });

  test(
    'local attendance list combines check-in and check-out by session',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final local = AttendanceLocalDataSource(database: database);
      final checkInAt = DateTime.parse('2026-07-22T01:15:20Z');
      final checkOutAt = DateTime.parse('2026-07-22T10:15:20Z');

      for (final action in AttendanceAction.values) {
        final occurredAt = action == AttendanceAction.checkIn
            ? checkInAt
            : checkOutAt;
        await database.enqueueOperation(
          OutboxOperationsCompanion.insert(
            operationId: action.name,
            idempotencyKey: action.name,
            accountId: scope.accountId,
            companyId: scope.companyId,
            operationType: action == AttendanceAction.checkIn
                ? SyncOperationType.attendanceCheckIn.storageName
                : SyncOperationType.attendanceCheckOut.storageName,
            targetResourceKey: 'attendance:a:regular:session-1',
            endpoint: '/attendance',
            payloadJson: jsonEncode(
              AttendanceOperationPayload(
                clientSessionId: 'session-1',
                action: action,
                type: AttendanceType.regular,
                occurredAt: occurredAt,
                timezoneOffsetMinutes: 420,
                latitude: -6.2,
                longitude: 106.8,
              ).toJson(),
            ),
            state: Value(
              action == AttendanceAction.checkIn
                  ? OutboxState.done.name
                  : OutboxState.retry.name,
            ),
            createdAt: occurredAt,
            updatedAt: occurredAt,
          ),
          const [],
        );
      }

      final records = await local.watchPendingRecords(scope).first;

      expect(records, hasLength(1));
      expect(records.single.clientSessionId, 'session-1');
      expect(records.single.checkInAt, checkInAt);
      expect(records.single.checkOutAt, checkOutAt);
      expect(records.single.state, OutboxState.retry);
    },
  );

  test(
    'attendance list response seeds today snapshot for offline checkout',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final local = AttendanceLocalDataSource(database: database);
      final today = formatDateParam(DateTime.now())!;

      await local.putTodaySnapshot(
        scope: scope,
        attendance: TodayAttendance(
          date: today,
          serverTime: DateTime.now().toUtc().toIso8601String(),
          regular: const RegularAttendance(
            checkedIn: false,
            checkedOut: false,
            workplace: AttendanceWorkplace(
              type: 'warehouse',
              id: 'loc-1',
              name: 'Gudang Mobile',
              latitude: '-6.200000',
              longitude: '106.800000',
              radiusMeters: 100,
              workStartTime: '08:00',
              workEndTime: '17:00',
            ),
          ),
          overtime: const OvertimeAttendance(available: false),
        ),
      );

      final result = AttendanceListResult.fromJson({
        'data': [
          {
            'id': 'attendance-1',
            'type': 'regular',
            'attendanceDate': today,
            'checkIn': '09:40',
            'checkOut': null,
            'status': 'late',
            'lateMinutes': 100,
            'earlyLeaveMinutes': 0,
            'locationType': 'Warehouse',
            'location': {'id': 'loc-1', 'name': 'Gudang Mobile'},
            'project': {'id': 'project-1', 'name': 'Proyek Mobile'},
            'checkInDistanceMeters': 32767,
            'checkOutDistanceMeters': null,
            'adminNote': null,
            'clientSessionId': 'session-from-list',
            'checkInOccurredAt': '2026-07-24T02:40:55+00:00',
            'checkInSyncedAt': '2026-07-24T02:40:57+00:00',
            'checkOutOccurredAt': null,
            'checkOutSyncedAt': null,
            'createdAt': '2026-07-24T02:40:57+00:00',
          },
        ],
        'meta': <String, dynamic>{},
        'links': <String, dynamic>{},
      });

      await local.putTodaySnapshotFromList(
        scope: scope,
        records: result.records,
      );

      final effective = await local.watchEffectiveToday(scope).first;

      expect(result.records.single.clientSessionId, 'session-from-list');
      expect(effective.regular.hasOpenAttendance, isTrue);
      expect(effective.regular.clientSessionId, 'session-from-list');
      expect(effective.snapshot?.regular.workplace?.latitude, '-6.200000');
      expect(effective.snapshot?.regular.workplace?.longitude, '106.800000');
      expect(effective.snapshot?.regular.workplace?.radiusMeters, 100);
    },
  );

  test('failed check-in permanently blocks its dependent check-out', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now().toUtc();
    OutboxOperationsCompanion operation({
      required String id,
      required SyncOperationType type,
      required OutboxState state,
      String? dependency,
    }) => OutboxOperationsCompanion.insert(
      operationId: id,
      idempotencyKey: id,
      accountId: scope.accountId,
      companyId: scope.companyId,
      operationType: type.storageName,
      targetResourceKey: 'attendance:a:regular:session-1',
      endpoint: '/attendance',
      payloadJson: '{}',
      state: Value(state.name),
      dependsOnOperationId: Value(dependency),
      createdAt: now,
      updatedAt: now,
    );
    await database.enqueueOperation(
      operation(
        id: 'check-in',
        type: SyncOperationType.attendanceCheckIn,
        state: OutboxState.failed,
      ),
      const [],
    );
    await database.enqueueOperation(
      operation(
        id: 'check-out',
        type: SyncOperationType.attendanceCheckOut,
        state: OutboxState.pending,
        dependency: 'check-in',
      ),
      const [],
    );

    expect(await database.claimNextOperation(scope, now: now), isNull);
    final child = (await database.listOperations(scope)).last;
    expect(child.state, OutboxState.failed.name);
    expect(child.lastErrorCode, 'DEPENDENCY_FAILED');
  });

  test(
    'a completed operation from a previous work date does not block today',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final yesterday = DateTime(2026, 7, 21, 8).toUtc();
      for (final action in AttendanceAction.values) {
        final id = action.name;
        await database.enqueueOperation(
          OutboxOperationsCompanion.insert(
            operationId: id,
            idempotencyKey: id,
            accountId: scope.accountId,
            companyId: scope.companyId,
            operationType: action == AttendanceAction.checkIn
                ? SyncOperationType.attendanceCheckIn.storageName
                : SyncOperationType.attendanceCheckOut.storageName,
            targetResourceKey: 'attendance:a:regular:old-session',
            endpoint: '/attendance',
            payloadJson: jsonEncode(
              AttendanceOperationPayload(
                clientSessionId: 'old-session',
                action: action,
                type: AttendanceType.regular,
                occurredAt: yesterday.add(
                  action == AttendanceAction.checkIn
                      ? Duration.zero
                      : const Duration(hours: 9),
                ),
                timezoneOffsetMinutes: 0,
                latitude: 0,
                longitude: 0,
              ).toJson(),
            ),
            state: Value(OutboxState.done.name),
            createdAt: yesterday,
            updatedAt: yesterday,
          ),
          const [],
        );
      }

      final effective = AttendanceProjection.project(
        snapshot: null,
        operations: await database.listAttendanceOperations(scope),
        hasApprovedOvertimeReferences: false,
        workDate: DateTime(2026, 7, 22),
      );

      expect(effective.regular.canCheckIn, isTrue);
      expect(effective.syncSummary.waiting, 0);
    },
  );

  test('an open attendance from the previous date does not block today', () {
    final occurredAt = DateTime.parse('2026-07-21T01:15:20Z');
    final operation = OutboxOperation(
      operationId: 'expired-check-in',
      idempotencyKey: 'expired-check-in',
      accountId: scope.accountId,
      companyId: scope.companyId,
      operationType: SyncOperationType.attendanceCheckIn.storageName,
      targetResourceKey: 'attendance:a:regular:expired-session',
      endpoint: '/attendance',
      httpMethod: 'POST',
      payloadJson: jsonEncode(
        AttendanceOperationPayload(
          clientSessionId: 'expired-session',
          action: AttendanceAction.checkIn,
          type: AttendanceType.regular,
          occurredAt: occurredAt,
          timezoneOffsetMinutes: 420,
          latitude: -6.2,
          longitude: 106.8,
        ).toJson(),
      ),
      payloadVersion: 1,
      state: OutboxState.pending.name,
      attemptCount: 0,
      createdAt: occurredAt,
      updatedAt: occurredAt,
    );

    final effective = AttendanceProjection.project(
      snapshot: null,
      operations: [operation],
      hasApprovedOvertimeReferences: false,
      workDate: DateTime.parse('2026-07-22T08:00:00Z'),
    );

    expect(effective.regular.canCheckIn, isTrue);
    expect(effective.regular.hasOpenAttendance, isFalse);
  });

  test(
    'pending regular check-in and check-out from the previous date do not block today',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final previousDate = DateTime.parse('2026-07-23T01:00:00Z');

      for (final action in AttendanceAction.values) {
        final occurredAt = previousDate.add(
          action == AttendanceAction.checkIn
              ? Duration.zero
              : const Duration(hours: 9),
        );
        await database.enqueueOperation(
          OutboxOperationsCompanion.insert(
            operationId: 'previous-${action.name}',
            idempotencyKey: 'previous-${action.name}',
            accountId: scope.accountId,
            companyId: scope.companyId,
            operationType: action == AttendanceAction.checkIn
                ? SyncOperationType.attendanceCheckIn.storageName
                : SyncOperationType.attendanceCheckOut.storageName,
            targetResourceKey: 'attendance:a:regular:previous-session',
            endpoint: '/attendance',
            payloadJson: jsonEncode(
              AttendanceOperationPayload(
                clientSessionId: 'previous-session',
                action: action,
                type: AttendanceType.regular,
                occurredAt: occurredAt,
                timezoneOffsetMinutes: 0,
                latitude: 0,
                longitude: 0,
              ).toJson(),
            ),
            state: const Value.absent(),
            createdAt: occurredAt,
            updatedAt: occurredAt,
          ),
          const [],
        );
      }

      final effective = AttendanceProjection.project(
        snapshot: null,
        operations: await database.listAttendanceOperations(scope),
        hasApprovedOvertimeReferences: false,
        workDate: DateTime(2026, 7, 24),
      );

      expect(effective.regular.canCheckIn, isTrue);
      expect(effective.regular.hasOpenAttendance, isFalse);
      expect(effective.syncSummary.waiting, 0);
    },
  );

  test('recognized occurredAt 422 is rejected without retry', () {
    final failure = ErrorMapper.toSyncFailure(
      DioException(
        requestOptions: RequestOptions(path: '/attendance'),
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/attendance'),
          statusCode: 422,
          data: {
            'errorCode': 'ATTENDANCE_OCCURRED_AT_TOO_OLD',
            'message': 'occurredAt is older than 7 days',
          },
        ),
      ),
    );

    expect(failure.kind, SyncFailureKind.rejected);
    expect(failure.retryAfter, isNull);
  });

  test('iOS socket error without a response remains retryable', () {
    final failure = ErrorMapper.toSyncFailure(
      DioException(
        requestOptions: RequestOptions(path: '/attendance/check-in'),
        type: DioExceptionType.unknown,
        error: const SocketException('Network is unreachable'),
      ),
    );

    expect(failure.kind, SyncFailureKind.retryable);
  });

  test('legacy attendance network failure is retried on reconnect', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final createdAt = DateTime.now().toUtc().subtract(
      const Duration(minutes: 5),
    );
    final now = DateTime.now().toUtc();

    await database.enqueueOperation(
      OutboxOperationsCompanion.insert(
        operationId: 'legacy-network-failure',
        idempotencyKey: 'legacy-network-failure',
        accountId: scope.accountId,
        companyId: scope.companyId,
        operationType: SyncOperationType.attendanceCheckIn.storageName,
        targetResourceKey: 'attendance:a:regular:session-legacy',
        endpoint: '/attendance',
        payloadJson: jsonEncode(
          AttendanceOperationPayload(
            clientSessionId: 'session-legacy',
            action: AttendanceAction.checkIn,
            type: AttendanceType.regular,
            occurredAt: createdAt,
            timezoneOffsetMinutes: 420,
            latitude: -6.2,
            longitude: 106.8,
          ).toJson(),
        ),
        state: Value(OutboxState.failed.name),
        lastErrorMessage: const Value('Sinkronisasi gagal.'),
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      const [],
    );

    await database.recoverLegacyAttendanceNetworkFailures(scope.accountId, now);

    final operation = (await database.listOperations(scope)).single;
    expect(operation.state, OutboxState.retry.name);
    expect(operation.lastErrorMessage, isNull);
    expect(
      await database.claimNextOperation(
        scope,
        now: now.add(const Duration(seconds: 1)),
      ),
      isA<OutboxOperation>(),
    );
  });

  test(
    'approved evening overtime stays on its local work date in attendance',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final client = DioClient(secureStorage: _FakeSecureStorage());
      var online = true;
      client.dio.httpClientAdapter = _CallbackAdapter((options) async {
        if (!online) return _jsonResponse('{"message":"offline"}', 503);
        return _jsonResponse(_overtimeListResponse, 200);
      });
      final local = AttendanceLocalDataSource(database: database);
      final repository = WorkforceRepository(
        dioClient: client,
        getCache: WorkforceGetCache(database: database),
        attendanceLocalDataSource: local,
        scope: scope,
        cacheReadEnabled: true,
      );
      final filter = OvertimeListFilter(
        status: 'approved',
        startDate: DateTime(2026, 7, 21),
        endDate: DateTime(2026, 7, 25),
        perPage: 100,
      );

      final onlineResult = await repository.fetchOvertimeList(filter: filter);
      online = false;
      final cachedResult = await repository.fetchOvertimeList(filter: filter);
      final localDate = DateTime(2026, 7, 22);
      final references = await local
          .watchApprovedReferences(scope, localDate)
          .first;
      final effective = await local
          .watchEffectiveToday(scope, workDate: localDate)
          .firstWhere(
            (value) =>
                value.referenceState == AttendanceReferenceState.available,
          );

      expect(onlineResult.records.single.id, 'overtime-1');
      expect(cachedResult.records.single.id, 'overtime-1');
      expect(references.single.overtimeId, 'overtime-1');
      expect(references.single.localWorkDate, '2026-07-22');
      expect(
        references.single.startAtUtc.toUtc(),
        DateTime(2026, 7, 22, 18).toUtc(),
      );
      expect(effective.referenceState, AttendanceReferenceState.available);
    },
  );
}

Future<
  ({
    AttendanceRepository repository,
    AttendanceLocalDataSource local,
    String selfiePath,
  })
>
_attendanceHarness(AppDatabase database, SyncScope scope) async {
  final root = await Directory.systemTemp.createTemp('curva-attendance-test-');
  addTearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });
  final selfie = File('${root.path}/selfie.jpg');
  await selfie.writeAsBytes(const [1, 2, 3]);

  final fileStore = DurableFileStore(rootDirectory: () async => root);
  final client = DioClient(secureStorage: _FakeSecureStorage());
  final local = AttendanceLocalDataSource(database: database);
  final engine = SyncEngine(
    database: database,
    dioClient: client,
    fileStore: fileStore,
    retryPolicy: RetryPolicy(),
  );
  final coordinator = SyncCoordinator(
    engine: engine,
    accountIdResolver: () => null,
  );
  addTearDown(coordinator.dispose);
  final outbox = OutboxService(
    database: database,
    fileStore: fileStore,
    policy: const SyncPolicy(
      writeCapabilities: {
        SyncOperationType.attendanceCheckIn: WriteCapability.queuedWrite,
        SyncOperationType.attendanceCheckOut: WriteCapability.queuedWrite,
      },
    ),
  );
  return (
    repository: AttendanceRepository(
      scope: scope,
      remote: WorkforceRepository(dioClient: client),
      local: local,
      database: database,
      outbox: outbox,
      coordinator: coordinator,
      fileStore: fileStore,
    ),
    local: local,
    selfiePath: selfie.path,
  );
}

const _overtimeListResponse = '''
{
  "data": [{
    "id": "overtime-1",
    "title": "Stock opname",
    "reason": "Closing",
    "overtimeDate": "2026-07-22",
    "startTime": "18:00:00",
    "endTime": "20:00:00",
    "totalMinutes": 120,
    "status": "approved",
    "locationType": "warehouse",
    "location": {"id": "location-1", "name": "Gudang"},
    "project": null,
    "adminNote": null,
    "createdAt": "2026-07-20T00:00:00Z"
  }],
  "meta": {
    "currentPage": 1,
    "perPage": 100,
    "total": 1,
    "lastPage": 1,
    "from": 1,
    "to": 1
  },
  "links": {"first": null, "last": null, "prev": null, "next": null}
}
''';

ResponseBody _jsonResponse(String body, int statusCode) =>
    ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _CallbackAdapter implements HttpClientAdapter {
  _CallbackAdapter(this.callback);

  final Future<ResponseBody> Function(RequestOptions options) callback;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => callback(options);

  @override
  void close({bool force = false}) {}
}

class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> readAccessToken() async => 'token';

  @override
  Future<String?> readRefreshToken() async => null;
}

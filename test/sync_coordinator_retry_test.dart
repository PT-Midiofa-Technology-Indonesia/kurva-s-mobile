import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/database/app_database.dart';
import 'package:curva_mobile/core/files/durable_file_store.dart';
import 'package:curva_mobile/core/network/dio_client.dart';
import 'package:curva_mobile/core/storage/secure_storage_service.dart';
import 'package:curva_mobile/core/sync/retry_policy.dart';
import 'package:curva_mobile/core/sync/sync_coordinator.dart';
import 'package:curva_mobile/core/sync/sync_engine.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';

void main() {
  late AppDatabase database;
  late _Engine engine;
  late SyncCoordinator coordinator;
  String? accountId;

  setUp(() {
    dotenv.testLoad(fileInput: 'BASE_URL=https://api.example.test');
    database = AppDatabase(NativeDatabase.memory());
    engine = _Engine(database);
    accountId = 'account';
    coordinator = SyncCoordinator(
      engine: engine,
      accountIdResolver: () => accountId,
    );
  });
  tearDown(() async {
    await coordinator.dispose();
    await database.close();
    dotenv.clean();
  });

  testWidgets(
    'automatically retries at due time without another external trigger',
    (tester) async {
      await coordinator.syncNow(SyncTrigger.operationEnqueued);
      expect(engine.calls, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(engine.calls, 2);
      expect(engine.forceDueCalls, 0);
      expect(coordinator.currentStatus.pendingCount, 0);
    },
  );

  testWidgets('scheduled retry does not cross accounts', (tester) async {
    await coordinator.syncNow(SyncTrigger.operationEnqueued);
    accountId = 'other';
    await tester.pump(const Duration(seconds: 2));
    expect(engine.calls, 1);
  });

  testWidgets('dispose cancels scheduled retry', (tester) async {
    await coordinator.syncNow(SyncTrigger.operationEnqueued);
    await coordinator.dispose();
    await tester.pump(const Duration(seconds: 2));
    expect(engine.calls, 1);
  });

  testWidgets('authentication pause does not schedule a retry', (tester) async {
    engine.authFailure = true;
    await coordinator.syncNow(SyncTrigger.operationEnqueued);
    await tester.pump(const Duration(seconds: 2));
    expect(engine.calls, 1);
    expect(coordinator.currentStatus.state, SyncRunState.paused);
  });

  testWidgets('dispose during an active run cannot install a new timer', (
    tester,
  ) async {
    final pending = Completer<void>();
    engine.waitFor = pending.future;
    final run = coordinator.syncNow(SyncTrigger.operationEnqueued);
    await coordinator.dispose();
    pending.complete();
    await run;
    await tester.pump(const Duration(seconds: 2));
    expect(engine.calls, 1);
  });
}

class _Engine extends SyncEngine {
  _Engine(AppDatabase database)
    : super(
        database: database,
        dioClient: DioClient(secureStorage: SecureStorageService()),
        fileStore: DurableFileStore(),
        retryPolicy: RetryPolicy(),
      );
  int calls = 0;
  int forceDueCalls = 0;
  bool authFailure = false;
  Future<void>? waitFor;

  @override
  Future<SyncRunResult> pushPendingForAccount(String accountId) async {
    calls++;
    await waitFor;
    return SyncRunResult(
      processedCount: 1,
      completedCount: calls > 1 ? 1 : 0,
      remainingCount: calls > 1 ? 0 : 1,
      pausedForAuth: authFailure,
    );
  }

  @override
  Future<DateTime?> nextRetryAtForAccount(String accountId) async => calls == 1
      ? DateTime.now().toUtc().add(const Duration(seconds: 1))
      : null;

  @override
  Future<void> makeRetriesDueForAccount(String accountId) async {
    forceDueCalls++;
  }
}

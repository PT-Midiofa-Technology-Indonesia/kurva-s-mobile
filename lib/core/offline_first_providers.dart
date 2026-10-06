import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modules/auth/auth_providers.dart';
import 'connectivity/connectivity_service.dart';
import 'connectivity/connectivity_state.dart';
import 'database/app_database.dart';
import 'files/durable_file_store.dart';
import 'sync/outbox_service.dart';
import 'sync/retry_policy.dart';
import 'sync/sync_coordinator.dart';
import 'sync/sync_engine.dart';
import 'sync/sync_models.dart';
import 'sync/sync_policy.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectivityStateProvider = StreamProvider<ConnectivityState>((ref) {
  return ref.watch(connectivityServiceProvider).watch();
});

final syncPolicyProvider = Provider<SyncPolicy>((ref) {
  return SyncPolicy(
    showGlobalStatusUi: _envFlag('OFFLINE_STATUS_UI_ENABLED'),
    readCapabilities: {
      if (_envFlag('OFFLINE_ATTENDANCE_CACHE_READ_ENABLED'))
        'attendanceCacheRead': ReadCapability.cacheRead,
      if (_envFlag('OFFLINE_PROJECT_CACHE_READ_ENABLED'))
        'projectCacheRead': ReadCapability.cacheRead,
      if (_envFlag('OFFLINE_LOGISTIC_CACHE_READ_ENABLED'))
        'logisticCacheRead': ReadCapability.cacheRead,
    },
    writeCapabilities: {
      if (_envFlag('OFFLINE_QUEUE_ATTENDANCE_CHECK_IN_ENABLED'))
        SyncOperationType.attendanceCheckIn: WriteCapability.queuedWrite,
      if (_envFlag('OFFLINE_QUEUE_ATTENDANCE_CHECK_OUT_ENABLED'))
        SyncOperationType.attendanceCheckOut: WriteCapability.queuedWrite,
      if (_envFlag('OFFLINE_QUEUE_PROJECT_TASK_DONE_ENABLED'))
        SyncOperationType.projectTaskDone: WriteCapability.queuedWrite,
      if (_envFlag('OFFLINE_QUEUE_QC_TASK_DECISION_ENABLED'))
        SyncOperationType.qcTaskDecision: WriteCapability.queuedWrite,
      if (_envFlag('OFFLINE_QUEUE_LOGISTIC_INBOUND_RECEIVE_ENABLED'))
        SyncOperationType.logisticInboundReceive: WriteCapability.queuedWrite,
      if (_envFlag('OFFLINE_QUEUE_LOGISTIC_OUTBOUND_ISSUE_ENABLED'))
        SyncOperationType.logisticOutboundIssue: WriteCapability.queuedWrite,
      if (_envFlag('OFFLINE_QUEUE_LOGISTIC_LOADING_REPORT_ENABLED'))
        SyncOperationType.logisticLoadingReport: WriteCapability.queuedWrite,
      if (_envFlag('OFFLINE_QUEUE_LOGISTIC_PICKUP_REPORT_ENABLED'))
        SyncOperationType.logisticPickupReport: WriteCapability.queuedWrite,
    },
  );
});

bool _envFlag(String key) {
  if (!dotenv.isInitialized) return false;
  final value = dotenv.env[key]?.toLowerCase();
  if (value == null || value.isEmpty) return false;
  return value == 'true';
}

final durableFileStoreProvider = Provider<DurableFileStore>((ref) {
  return DurableFileStore();
});

final retryPolicyProvider = Provider<RetryPolicy>((ref) {
  return RetryPolicy();
});

final currentAccountIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authControllerProvider).valueOrNull;
  if (authState == null || !authState.isAuthenticated) return null;
  final accountId = authState.user?.id;
  return accountId == null || accountId.isEmpty ? null : accountId;
});

final currentAccountNameProvider = Provider<String?>((ref) {
  final authState = ref.watch(authControllerProvider).valueOrNull;
  if (authState == null || !authState.isAuthenticated) return null;
  final accountName = authState.user?.name.trim();
  return accountName == null || accountName.isEmpty ? null : accountName;
});

final syncScopeProvider = Provider<SyncScope?>((ref) {
  final authState = ref.watch(authControllerProvider).valueOrNull;
  final user = authState?.user;
  if (authState == null || !authState.isAuthenticated || user == null) {
    return null;
  }

  String? companyId;
  if (user.companies.isNotEmpty) {
    companyId = user.companies.first.id;
  } else {
    for (final assignment in user.assignments) {
      final candidate = assignment.company?.id;
      if (candidate != null && candidate.isNotEmpty) {
        companyId = candidate;
        break;
      }
    }
  }
  if (companyId == null || companyId.isEmpty) return null;
  return SyncScope(accountId: user.id, companyId: companyId);
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    database: ref.watch(appDatabaseProvider),
    dioClient: ref.watch(dioClientProvider),
    fileStore: ref.watch(durableFileStoreProvider),
    retryPolicy: ref.watch(retryPolicyProvider),
  );
});

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(
    engine: ref.watch(syncEngineProvider),
    accountIdResolver: () => ref.read(currentAccountIdProvider),
  );
  ref.onDispose(() => unawaited(coordinator.dispose()));
  return coordinator;
});

final pendingOperationCountProvider = StreamProvider<int>((ref) {
  final accountId = ref.watch(currentAccountIdProvider);
  if (accountId == null) return Stream.value(0);
  return ref.watch(appDatabaseProvider).watchPendingCountForAccount(accountId);
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) async* {
  final coordinator = ref.watch(syncCoordinatorProvider);
  yield coordinator.currentStatus;
  yield* coordinator.status;
});

final outboxServiceProvider = Provider<OutboxService>((ref) {
  return OutboxService(
    database: ref.watch(appDatabaseProvider),
    fileStore: ref.watch(durableFileStoreProvider),
    policy: ref.watch(syncPolicyProvider),
    onEnqueued: () {
      ref
          .read(syncCoordinatorProvider)
          .requestSync(SyncTrigger.operationEnqueued);
    },
  );
});

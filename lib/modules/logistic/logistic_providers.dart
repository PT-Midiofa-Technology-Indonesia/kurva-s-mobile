import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/errors/app_exception.dart';
import '../../core/offline_first_providers.dart';
import '../../core/sync/sync_models.dart';
import '../../core/sync/sync_policy.dart';
import '../auth/auth_providers.dart';
import 'data/local/logistic_local_data_source.dart';
import 'data/logistic_repository.dart';
import 'data/models/logistic_models.dart';

final logisticLocalDataSourceProvider = Provider<LogisticLocalDataSource>((
  ref,
) {
  return LogisticLocalDataSource(database: ref.watch(appDatabaseProvider));
});

final logisticRepositoryProvider = Provider<LogisticRepository>((ref) {
  return LogisticRepository(
    dioClient: ref.watch(dioClientProvider),
    localDataSource: ref.watch(logisticLocalDataSourceProvider),
    outboxService: ref.watch(outboxServiceProvider),
    scope: ref.watch(syncScopeProvider),
  );
});

final logisticCacheReadEnabledProvider = Provider<bool>((ref) {
  return ref.watch(syncPolicyProvider).readMode('logisticCacheRead') ==
      ReadCapability.cacheRead;
});

final loadingOrdersProvider =
    StreamProvider.family<List<LogisticLoadingOrder>, LogisticListQuery>((
      ref,
      query,
    ) {
      final repository = ref.watch(logisticRepositoryProvider);
      if (!ref.watch(logisticCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(repository.fetchLoadingOrders(tab: query.tab));
      }
      return _cachedStream(
        watch: () => repository.watchLoadingOrders(tab: query.tab),
        refresh: () => repository.fetchLoadingOrders(tab: query.tab),
        missingMessage:
            'Daftar loading belum tersimpan di perangkat. Sambungkan internet dan buka menu ini sekali.',
      );
    });

final pickupOrdersProvider =
    StreamProvider.family<List<LogisticPickupOrder>, LogisticListQuery>((
      ref,
      query,
    ) {
      final repository = ref.watch(logisticRepositoryProvider);
      if (!ref.watch(logisticCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(repository.fetchPickupOrders(tab: query.tab));
      }
      return _cachedStream(
        watch: () => repository.watchPickupOrders(tab: query.tab),
        refresh: () => repository.fetchPickupOrders(tab: query.tab),
        missingMessage:
            'Daftar pickup belum tersimpan di perangkat. Sambungkan internet dan buka menu ini sekali.',
      );
    });

final pickupDetailProvider =
    StreamProvider.family<LogisticPickupOrderDetail, String>((
      ref,
      pickupOrderId,
    ) {
      final repository = ref.watch(logisticRepositoryProvider);
      if (!ref.watch(logisticCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(repository.fetchPickupDetail(pickupOrderId));
      }
      return _cachedStream(
        watch: () => repository.watchPickupDetail(pickupOrderId),
        refresh: () => repository.fetchPickupDetail(pickupOrderId),
        missingMessage:
            'Detail pickup belum tersedia offline. Sambungkan internet dan buka detail ini sekali.',
      );
    });

final loadingDetailProvider =
    StreamProvider.family<LogisticLoadingOrderDetail, String>((
      ref,
      loadingOrderId,
    ) {
      final repository = ref.watch(logisticRepositoryProvider);
      if (!ref.watch(logisticCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(repository.fetchLoadingDetail(loadingOrderId));
      }
      return _cachedStream(
        watch: () => repository.watchLoadingDetail(loadingOrderId),
        refresh: () => repository.fetchLoadingDetail(loadingOrderId),
        missingMessage:
            'Detail loading belum tersedia offline. Sambungkan internet dan buka detail ini sekali.',
      );
    });

final inboundOrdersProvider =
    StreamProvider.family<List<LogisticDeliveryOrder>, LogisticListQuery>((
      ref,
      query,
    ) {
      final repository = ref.watch(logisticRepositoryProvider);
      if (!ref.watch(logisticCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(
          repository.fetchInboundOrders(tab: query.tab, search: query.search),
        );
      }
      return _cachedOrdersStream(
        watch: () => repository.watchOrders(
          inbound: true,
          tab: query.tab,
          search: query.search,
        ),
        refresh: () =>
            repository.fetchInboundOrders(tab: query.tab, search: query.search),
        noun: 'inbound',
      );
    });

final inboundDetailProvider =
    StreamProvider.family<LogisticDeliveryOrderDetail, String>((
      ref,
      deliveryOrderId,
    ) {
      final repository = ref.watch(logisticRepositoryProvider);
      if (!ref.watch(logisticCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(
          repository.fetchInboundDetail(deliveryOrderId),
        );
      }
      return _cachedDetailStream(
        watch: () => repository.watchDetail(
          inbound: true,
          deliveryOrderId: deliveryOrderId,
        ),
        refresh: () => repository.fetchInboundDetail(deliveryOrderId),
        noun: 'inbound',
      );
    });

final outboundOrdersProvider =
    StreamProvider.family<List<LogisticDeliveryOrder>, LogisticListQuery>((
      ref,
      query,
    ) {
      final repository = ref.watch(logisticRepositoryProvider);
      if (!ref.watch(logisticCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(
          repository.fetchOutboundOrders(tab: query.tab, search: query.search),
        );
      }
      return _cachedOrdersStream(
        watch: () => repository.watchOrders(
          inbound: false,
          tab: query.tab,
          search: query.search,
        ),
        refresh: () => repository.fetchOutboundOrders(
          tab: query.tab,
          search: query.search,
        ),
        noun: 'outbound',
      );
    });

final outboundDetailProvider =
    StreamProvider.family<LogisticDeliveryOrderDetail, String>((
      ref,
      deliveryOrderId,
    ) {
      final repository = ref.watch(logisticRepositoryProvider);
      if (!ref.watch(logisticCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(
          repository.fetchOutboundDetail(deliveryOrderId),
        );
      }
      return _cachedDetailStream(
        watch: () => repository.watchDetail(
          inbound: false,
          deliveryOrderId: deliveryOrderId,
        ),
        refresh: () => repository.fetchOutboundDetail(deliveryOrderId),
        noun: 'outbound',
      );
    });

final logisticTargetOperationProvider =
    StreamProvider.family<OutboxOperation?, LogisticTargetOperationQuery>((
      ref,
      query,
    ) {
      final scope = ref.watch(syncScopeProvider);
      if (scope == null) return Stream.value(null);
      return ref
          .watch(appDatabaseProvider)
          .watchTargetOperation(
            scope: scope,
            operationType: query.operationType,
            targetResourceKey:
                'logistic:${query.resourceType}:${query.resourceId}',
          );
    });

final logisticSyncStateByDeliveryOrderProvider =
    StreamProvider<Map<String, String>>((ref) {
      final scope = ref.watch(syncScopeProvider);
      if (scope == null) return Stream.value(const {});
      return ref.watch(appDatabaseProvider).watchOperations(scope).map((rows) {
        final result = <String, String>{};
        for (final operation in rows) {
          final isLogistic =
              operation.operationType ==
                  SyncOperationType.logisticInboundReceive.storageName ||
              operation.operationType ==
                  SyncOperationType.logisticOutboundIssue.storageName;
          if (!isLogistic || operation.state == OutboxState.done.name) continue;
          const prefix = 'logistic:delivery-order:';
          if (operation.targetResourceKey.startsWith(prefix)) {
            result[operation.targetResourceKey.substring(prefix.length)] =
                operation.state;
          }
        }
        return result;
      });
    });

final logisticSyncStateByResourceProvider =
    StreamProvider.family<Map<String, String>, String>((ref, resourceType) {
      final scope = ref.watch(syncScopeProvider);
      if (scope == null) return Stream.value(const {});
      final prefix = 'logistic:$resourceType:';
      return ref.watch(appDatabaseProvider).watchOperations(scope).map((rows) {
        final result = <String, String>{};
        for (final operation in rows) {
          if (operation.state == OutboxState.done.name ||
              !operation.targetResourceKey.startsWith(prefix)) {
            continue;
          }
          result[operation.targetResourceKey.substring(prefix.length)] =
              operation.state;
        }
        return result;
      });
    });

class LogisticTargetOperationQuery {
  const LogisticTargetOperationQuery({
    required this.resourceId,
    required this.operationType,
    this.resourceType = 'delivery-order',
  });

  final String resourceId;
  final String resourceType;
  final SyncOperationType operationType;

  @override
  bool operator ==(Object other) =>
      other is LogisticTargetOperationQuery &&
      other.resourceId == resourceId &&
      other.resourceType == resourceType &&
      other.operationType == operationType;

  @override
  int get hashCode => Object.hash(resourceId, resourceType, operationType);
}

class LogisticListQuery {
  const LogisticListQuery({required this.tab, this.search = ''});

  final String tab;
  final String search;

  @override
  bool operator ==(Object other) {
    return other is LogisticListQuery &&
        other.tab == tab &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(tab, search);
}

Stream<List<LogisticDeliveryOrder>> _cachedOrdersStream({
  required Stream<LogisticCachedReference<List<LogisticDeliveryOrder>>?>
  Function()
  watch,
  required Future<List<LogisticDeliveryOrder>> Function() refresh,
  required String noun,
}) async* {
  final cached = await watch().first;
  if (cached != null) yield cached.value;
  try {
    await refresh();
  } catch (error) {
    if (error is AppException && error.isAccessDenied) rethrow;
    if (cached == null &&
        (error is! AppException || error.kind != AppExceptionKind.connection)) {
      rethrow;
    }
    if (cached == null) {
      throw AppException(
        'Daftar $noun belum tersimpan di perangkat. Sambungkan internet dan buka menu ini sekali.',
        kind: AppExceptionKind.offlineCacheMiss,
      );
    }
  }
  yield* watch().where((value) => value != null).map((value) => value!.value);
}

Stream<LogisticDeliveryOrderDetail> _cachedDetailStream({
  required Stream<LogisticCachedReference<LogisticDeliveryOrderDetail>?>
  Function()
  watch,
  required Future<LogisticDeliveryOrderDetail> Function() refresh,
  required String noun,
}) async* {
  final cached = await watch().first;
  if (cached != null) yield cached.value;
  try {
    await refresh();
  } catch (error) {
    if (error is AppException && error.isAccessDenied) rethrow;
    if (cached == null &&
        (error is! AppException || error.kind != AppExceptionKind.connection)) {
      rethrow;
    }
    if (cached == null) {
      throw AppException(
        'Detail $noun belum tersedia offline. Sambungkan internet dan buka detail ini sekali.',
        kind: AppExceptionKind.offlineCacheMiss,
      );
    }
  }
  yield* watch().where((value) => value != null).map((value) => value!.value);
}

Stream<T> _cachedStream<T>({
  required Stream<LogisticCachedReference<T>?> Function() watch,
  required Future<T> Function() refresh,
  required String missingMessage,
}) async* {
  final cached = await watch().first;
  if (cached != null) yield cached.value;
  try {
    await refresh();
  } catch (error) {
    if (error is AppException && error.isAccessDenied) rethrow;
    if (cached == null &&
        (error is! AppException || error.kind != AppExceptionKind.connection)) {
      rethrow;
    }
    if (cached == null) {
      throw AppException(
        missingMessage,
        kind: AppExceptionKind.offlineCacheMiss,
      );
    }
  }
  yield* watch().where((value) => value != null).map((value) => value!.value);
}

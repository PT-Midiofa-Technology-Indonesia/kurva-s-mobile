import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/cache_key.dart';
import '../../../../core/sync/sync_models.dart';
import '../models/logistic_models.dart';

class LogisticCachedReference<T> {
  const LogisticCachedReference({required this.value, required this.fetchedAt});

  final T value;
  final DateTime fetchedAt;
}

class LogisticLocalDataSource {
  const LogisticLocalDataSource({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Stream<LogisticCachedReference<List<LogisticDeliveryOrder>>?> watchOrders({
    required SyncScope scope,
    required bool inbound,
    required String tab,
    String search = '',
  }) {
    final descriptor = _listDescriptor(inbound, tab, search);
    final key = CacheKey.create(
      scope: scope,
      endpointKey: descriptor.endpointKey,
      query: descriptor.query,
    );
    return _database.watchCache(key, scope).map((row) {
      if (row == null) return null;
      try {
        return LogisticCachedReference(
          value: LogisticDeliveryOrder.listFromPayload(
            jsonDecode(row.payloadJson),
          ),
          fetchedAt: row.fetchedAt,
        );
      } on FormatException {
        return null;
      }
    });
  }

  Stream<LogisticCachedReference<LogisticDeliveryOrderDetail>?> watchDetail({
    required SyncScope scope,
    required bool inbound,
    required String deliveryOrderId,
  }) {
    final endpointKey = _detailEndpoint(inbound, deliveryOrderId);
    final key = CacheKey.create(scope: scope, endpointKey: endpointKey);
    return _database.watchCache(key, scope).map((row) {
      if (row == null) return null;
      try {
        final decoded = jsonDecode(row.payloadJson);
        if (decoded is! Map<String, dynamic>) return null;
        return LogisticCachedReference(
          value: LogisticDeliveryOrderDetail.fromJson(decoded),
          fetchedAt: row.fetchedAt,
        );
      } on FormatException {
        return null;
      }
    });
  }

  Future<void> putOrders({
    required SyncScope scope,
    required bool inbound,
    required String tab,
    required String search,
    required List<LogisticDeliveryOrder> orders,
  }) {
    final descriptor = _listDescriptor(inbound, tab, search);
    return _put(
      scope: scope,
      endpointKey: descriptor.endpointKey,
      query: descriptor.query,
      payload: orders.map((order) => order.toJson()).toList(growable: false),
    );
  }

  Future<void> putDetail({
    required SyncScope scope,
    required bool inbound,
    required LogisticDeliveryOrderDetail detail,
  }) {
    return _put(
      scope: scope,
      endpointKey: _detailEndpoint(inbound, detail.deliveryOrderId),
      payload: detail.toJson(),
    );
  }

  Stream<LogisticCachedReference<List<LogisticLoadingOrder>>?>
  watchLoadingOrders({required SyncScope scope, required String tab}) => _watch(
    scope: scope,
    endpointKey: 'logistic:loading:list',
    query: {'tab': tab},
    decode: (payload) =>
        LogisticLoadingOrder.listFromPayload(jsonDecode(payload)),
  );

  Stream<LogisticCachedReference<LogisticLoadingOrderDetail>?>
  watchLoadingDetail({
    required SyncScope scope,
    required String loadingOrderId,
  }) => _watch(
    scope: scope,
    endpointKey: 'logistic:loading:detail:$loadingOrderId',
    decode: (payload) {
      final decoded = jsonDecode(payload);
      return LogisticLoadingOrderDetail.fromJson(
        decoded as Map<String, dynamic>,
      );
    },
  );

  Stream<LogisticCachedReference<List<LogisticPickupOrder>>?>
  watchPickupOrders({required SyncScope scope, required String tab}) => _watch(
    scope: scope,
    endpointKey: 'logistic:pickup:list',
    query: {'tab': tab},
    decode: (payload) =>
        LogisticPickupOrder.listFromPayload(jsonDecode(payload)),
  );

  Stream<LogisticCachedReference<LogisticPickupOrderDetail>?>
  watchPickupDetail({
    required SyncScope scope,
    required String pickupOrderId,
  }) => _watch(
    scope: scope,
    endpointKey: 'logistic:pickup:detail:$pickupOrderId',
    decode: (payload) {
      final decoded = jsonDecode(payload);
      return LogisticPickupOrderDetail.fromJson(
        decoded as Map<String, dynamic>,
      );
    },
  );

  Future<void> putLoadingOrders({
    required SyncScope scope,
    required String tab,
    required List<LogisticLoadingOrder> orders,
  }) => _put(
    scope: scope,
    endpointKey: 'logistic:loading:list',
    query: {'tab': tab},
    payload: orders.map((order) => order.toJson()).toList(growable: false),
  );

  Future<void> putLoadingDetail({
    required SyncScope scope,
    required LogisticLoadingOrderDetail detail,
  }) => _put(
    scope: scope,
    endpointKey: 'logistic:loading:detail:${detail.loadingOrderId}',
    payload: detail.toJson(),
  );

  Future<void> putPickupOrders({
    required SyncScope scope,
    required String tab,
    required List<LogisticPickupOrder> orders,
  }) => _put(
    scope: scope,
    endpointKey: 'logistic:pickup:list',
    query: {'tab': tab},
    payload: orders.map((order) => order.toJson()).toList(growable: false),
  );

  Future<void> putPickupDetail({
    required SyncScope scope,
    required LogisticPickupOrderDetail detail,
  }) => _put(
    scope: scope,
    endpointKey: 'logistic:pickup:detail:${detail.pickupOrderId}',
    payload: detail.toJson(),
  );

  Stream<LogisticCachedReference<T>?> _watch<T>({
    required SyncScope scope,
    required String endpointKey,
    required T Function(String payload) decode,
    Map<String, Object?> query = const {},
  }) {
    final key = CacheKey.create(
      scope: scope,
      endpointKey: endpointKey,
      query: query,
    );
    return _database.watchCache(key, scope).map((row) {
      if (row == null) return null;
      try {
        return LogisticCachedReference(
          value: decode(row.payloadJson),
          fetchedAt: row.fetchedAt,
        );
      } on Object {
        return null;
      }
    });
  }

  Future<void> _put({
    required SyncScope scope,
    required String endpointKey,
    required Object payload,
    Map<String, Object?> query = const {},
  }) {
    final now = DateTime.now().toUtc();
    final key = CacheKey.create(
      scope: scope,
      endpointKey: endpointKey,
      query: query,
    );
    return _database.putCache(
      ApiCacheCompanion.insert(
        cacheKey: key,
        accountId: scope.accountId,
        companyId: scope.companyId,
        endpointKey: endpointKey,
        queryHash: key,
        payloadJson: jsonEncode(payload),
        fetchedAt: now,
        expiresAt: Value(now.add(const Duration(hours: 24))),
      ),
    );
  }

  ({String endpointKey, Map<String, Object?> query}) _listDescriptor(
    bool inbound,
    String tab,
    String search,
  ) {
    return (
      endpointKey: 'logistic:${inbound ? 'inbound' : 'outbound'}:list',
      query: {'tab': tab, 'search': search.trim()},
    );
  }

  String _detailEndpoint(bool inbound, String id) =>
      'logistic:${inbound ? 'inbound' : 'outbound'}:detail:$id';
}

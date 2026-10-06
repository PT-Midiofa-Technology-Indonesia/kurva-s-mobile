import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/cache_key.dart';
import '../../../../core/sync/sync_models.dart';

class WorkforceGetCache {
  const WorkforceGetCache({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Future<void> put({
    required SyncScope scope,
    required String endpointKey,
    required Map<String, dynamic> response,
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
        payloadJson: jsonEncode(response),
        fetchedAt: now,
        expiresAt: Value(now.add(const Duration(days: 7))),
      ),
    );
  }

  Future<Map<String, dynamic>?> get({
    required SyncScope scope,
    required String endpointKey,
    Map<String, Object?> query = const {},
  }) async {
    final key = CacheKey.create(
      scope: scope,
      endpointKey: endpointKey,
      query: query,
    );
    final row = await _database.getCache(key, scope);
    if (row == null) return null;
    try {
      final decoded = jsonDecode(row.payloadJson);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}

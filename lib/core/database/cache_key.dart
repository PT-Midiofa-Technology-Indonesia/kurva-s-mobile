import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../sync/sync_models.dart';

abstract final class CacheKey {
  static String create({
    required SyncScope scope,
    required String endpointKey,
    Map<String, Object?> query = const {},
  }) {
    final canonicalQuery = _canonicalize(query);
    final queryJson = jsonEncode(canonicalQuery);
    final queryHash = sha256.convert(utf8.encode(queryJson)).toString();
    return '${scope.accountId}:${scope.companyId}:$endpointKey:$queryHash';
  }

  static Map<String, Object?> _canonicalize(Map<String, Object?> value) {
    final keys = value.keys.toList()..sort();
    return {for (final key in keys) key: _canonicalValue(value[key])};
  }

  static Object? _canonicalValue(Object? value) {
    if (value is Map<String, Object?>) return _canonicalize(value);
    if (value is List) return value.map(_canonicalValue).toList();
    return value;
  }
}

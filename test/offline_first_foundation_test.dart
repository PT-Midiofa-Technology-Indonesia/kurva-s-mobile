import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/database/cache_key.dart';
import 'package:curva_mobile/core/errors/error_mapper.dart';
import 'package:curva_mobile/core/errors/sync_failure.dart';
import 'package:curva_mobile/core/sync/retry_policy.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/core/sync/sync_policy.dart';

void main() {
  test('cache key is deterministic and tenant-specific', () {
    const scope = SyncScope(accountId: 'a', companyId: 'c');
    final first = CacheKey.create(
      scope: scope,
      endpointKey: 'items',
      query: {'page': 1, 'search': 'bolt'},
    );
    final reordered = CacheKey.create(
      scope: scope,
      endpointKey: 'items',
      query: {'search': 'bolt', 'page': 1},
    );
    final otherTenant = CacheKey.create(
      scope: const SyncScope(accountId: 'a', companyId: 'other'),
      endpointKey: 'items',
      query: {'page': 1, 'search': 'bolt'},
    );

    expect(first, reordered);
    expect(first, isNot(otherTenant));
  });

  test('all writes are online-only by default', () {
    const policy = SyncPolicy();
    for (final operation in SyncOperationType.values) {
      expect(policy.writeMode(operation), WriteCapability.onlineOnly);
      expect(policy.canQueue(operation), isFalse);
    }
  });

  test('retry policy grows and honors Retry-After', () {
    final policy = RetryPolicy(random: Random(0));
    final first = policy.delayForAttempt(1);
    final third = policy.delayForAttempt(3);

    expect(first, greaterThanOrEqualTo(const Duration(minutes: 2)));
    expect(third, greaterThanOrEqualTo(const Duration(minutes: 15)));
    expect(
      policy.delayForAttempt(3, retryAfter: const Duration(seconds: 90)),
      const Duration(seconds: 90),
    );
  });

  test('Dio status codes map to sync failure categories', () {
    expect(_failureFor(409).kind, SyncFailureKind.conflict);
    expect(_failureFor(422).kind, SyncFailureKind.permanent);
    expect(_failureFor(429).kind, SyncFailureKind.retryable);
    expect(_failureFor(503).kind, SyncFailureKind.retryable);
    expect(_failureFor(401).kind, SyncFailureKind.auth);
  });

  test('Dio unknown without response remains retryable for sync', () {
    final failure = ErrorMapper.toSyncFailure(
      DioException(
        requestOptions: RequestOptions(path: '/sync'),
        type: DioExceptionType.unknown,
        error: StateError('network unavailable'),
      ),
    );

    expect(failure.kind, SyncFailureKind.retryable);
  });
}

SyncFailure _failureFor(int statusCode) {
  final request = RequestOptions(path: '/sync');
  return ErrorMapper.toSyncFailure(
    DioException(
      requestOptions: request,
      response: Response<Object?>(
        requestOptions: request,
        statusCode: statusCode,
        data: {'message': 'failed', 'errorCode': 'TEST'},
      ),
    ),
  );
}

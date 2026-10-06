import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:curva_mobile/core/connectivity/connectivity_state.dart';
import 'package:curva_mobile/core/database/app_database.dart';
import 'package:curva_mobile/core/media/offline_image_providers.dart';
import 'package:curva_mobile/core/media/offline_image_store.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/core/sync/sync_policy.dart';

void main() {
  const scope = SyncScope(accountId: 'account', companyId: 'company');
  const url = 'https://storage.example/photo.jpg';
  late Directory root;
  late AppDatabase database;
  late StreamController<ConnectivityState> connectivity;
  late ProviderContainer container;
  late OfflineImageStore store;
  var attempts = 0;
  var fail = false;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('image_provider_test_');
    database = AppDatabase(NativeDatabase.memory());
    connectivity = StreamController<ConnectivityState>.broadcast();
    attempts = 0;
    fail = false;
    store = OfflineImageStore(
      rootDirectory: () async => root,
      download: (_) async {
        attempts++;
        if (fail) throw const SocketException('offline');
        return Stream.value([1, 2, 3]);
      },
    );
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        syncScopeProvider.overrideWithValue(scope),
        syncPolicyProvider.overrideWithValue(
          const SyncPolicy(
            readCapabilities: {'projectCacheRead': ReadCapability.cacheRead},
          ),
        ),
        connectivityStateProvider.overrideWith((_) => connectivity.stream),
        offlineImageStoreProvider.overrideWithValue(store),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await connectivity.close();
    await database.close();
    await root.delete(recursive: true);
  });

  Future<void> put(
    String key, {
    String company = 'company',
    String endpoint = 'project:detail',
  }) => database.putCache(
    ApiCacheCompanion.insert(
      cacheKey: key,
      accountId: 'account',
      companyId: company,
      endpointKey: endpoint,
      queryHash: key,
      payloadJson: jsonEncode({
        'files': [
          {'url': url},
        ],
      }),
      fetchedAt: DateTime.now().toUtc(),
    ),
  );

  test(
    'replays saved response on restart and prefetches newly saved images',
    () async {
      await put('saved');
      final sub = container.listen(offlineImagePrefetchProvider, (_, __) {});
      await container.read(offlineImagePrefetchProvider.future);
      expect(await store.lookup(scope, url), isNotNull);
      expect(attempts, 1);
      await put('another');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(attempts, 1);
      sub.close();
    },
  );

  test(
    'failed prefetch retries when connectivity returns without changing data',
    () async {
      fail = true;
      await put('saved');
      final sub = container.listen(offlineImagePrefetchProvider, (_, __) {});
      await container.read(offlineImagePrefetchProvider.future);
      expect(attempts, 1);
      connectivity.add(const ConnectivityState.offline());
      await container.read(connectivityStateProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      fail = false;
      connectivity.add(const ConnectivityState.online());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await container.read(offlineImagePrefetchProvider.future);
      expect(await store.lookup(scope, url), isNotNull);
      expect(await database.getCache('saved', scope), isNotNull);
      sub.close();
    },
  );

  test('prefetch excludes other companies and disabled features', () async {
    await put('other', company: 'other');
    await put('disabled', endpoint: 'logistic:detail');
    final sub = container.listen(offlineImagePrefetchProvider, (_, __) {});
    await container.read(offlineImagePrefetchProvider.future);
    expect(attempts, 0);
    sub.close();
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/auth/auth_providers.dart';
import '../offline_first_providers.dart';
import '../sync/sync_models.dart';
import '../sync/sync_policy.dart';
import 'offline_image_store.dart';

final offlineImagesEnabledProvider = Provider<bool>(
  (ref) => ref
      .watch(syncPolicyProvider)
      .readCapabilities
      .values
      .contains(ReadCapability.cacheRead),
);

final offlineImageStoreProvider = Provider<OfflineImageStore>((ref) {
  final client = ref.watch(dioClientProvider);
  return OfflineImageStore(
    download: (url) async {
      // Existing image URLs are public/signed. Never forward API bearer tokens
      // to storage hosts or expire the session because an image URL expired.
      final response = await client.dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'image/*'},
          extra: {'skipAuth': true},
        ),
      );
      final body = response.data;
      if (body == null) throw const FormatException('Gambar kosong.');
      final type = response.headers.value(Headers.contentTypeHeader) ?? '';
      if (!type.toLowerCase().startsWith('image/')) {
        await body.stream.listen(null).cancel();
        throw const FormatException('Respons bukan gambar.');
      }
      return body.stream;
    },
  );
});

bool _sameScope(SyncScope? a, SyncScope b) =>
    a?.accountId == b.accountId && a?.companyId == b.companyId;

final offlineImageFileProvider = FutureProvider.autoDispose
    .family<File?, String>((ref, url) async {
      final scope = ref.watch(syncScopeProvider);
      final offline =
          ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;
      if (scope == null || !ref.watch(offlineImagesEnabledProvider)) {
        return null;
      }
      final store = ref.watch(offlineImageStoreProvider);
      var active = true;
      ref.onDispose(() => active = false);
      return store.resolve(
        scope,
        url,
        canDownload: () =>
            active &&
            !offline &&
            _sameScope(ref.read(syncScopeProvider), scope),
      );
    });

/// Replays the existing durable response cache on startup/reconnect and watches
/// subsequent saves. No separate upload outbox or database migration is needed.
final offlineImagePrefetchProvider = StreamProvider<void>((ref) async* {
  final scope = ref.watch(syncScopeProvider);
  final offline =
      ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;
  final enabled = ref.watch(offlineImagesEnabledProvider);
  if (scope == null || offline || !enabled) return;
  final database = ref.watch(appDatabaseProvider);
  final store = ref.watch(offlineImageStoreProvider);
  final policy = ref.watch(syncPolicyProvider);
  var active = true;
  ref.onDispose(() => active = false);
  bool canDownload() =>
      active && _sameScope(ref.read(syncScopeProvider), scope);
  await for (final rows in database.watchCacheForScope(scope)) {
    if (!active) return;
    final urls = <String>{};
    for (final row in rows) {
      final capability = row.endpointKey.startsWith('project:')
          ? 'projectCacheRead'
          : row.endpointKey.startsWith('logistic:')
          ? 'logisticCacheRead'
          : row.endpointKey.startsWith('workforce:')
          ? 'attendanceCacheRead'
          : '';
      if (policy.readMode(capability) != ReadCapability.cacheRead) continue;
      try {
        urls.addAll(OfflineImageStore.urlsIn(jsonDecode(row.payloadJson)));
      } on FormatException {
        /* Leave malformed response handling to its repository. */
      }
    }
    for (final url in urls) {
      if (!canDownload()) return;
      await store.resolve(scope, url, canDownload: canDownload);
    }
    yield null;
  }
});

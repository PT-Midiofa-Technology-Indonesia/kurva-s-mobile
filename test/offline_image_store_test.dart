import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:curva_mobile/core/media/offline_image_store.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';

void main() {
  late Directory root;
  const scope = SyncScope(accountId: 'account', companyId: 'company');
  const url = 'https://storage.example/photo.jpg?signature=one';
  setUp(() async {
    root = await Directory.systemTemp.createTemp('offline_image_test_');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  OfflineImageStore store(
    Future<Stream<List<int>>> Function(String) download, {
    int quota = 250,
    int maxImage = 20,
  }) => OfflineImageStore(
    download: download,
    rootDirectory: () async => root,
    maxStorageBytes: quota,
    maxImageBytes: maxImage,
  );

  test(
    'image survives store restart and reads offline without downloading',
    () async {
      final first = store((_) async => Stream.value([1, 2, 3]));
      final file = await first.resolve(scope, url, canDownload: () => true);
      expect(file, isNotNull);
      final restarted = store(
        (_) async => throw StateError('Must not download'),
      );
      final cached = await restarted.resolve(
        scope,
        url,
        canDownload: () => false,
      );
      expect(await cached!.readAsBytes(), [1, 2, 3]);
      expect(cached.path, isNot(contains('signature')));
    },
  );

  test(
    'same URL is isolated across account and company, including unsafe IDs',
    () async {
      final cache = store((_) async => Stream.value([1]));
      await cache.resolve(scope, url, canDownload: () => true);
      for (final other in [
        const SyncScope(accountId: 'other', companyId: 'company'),
        const SyncScope(accountId: 'account', companyId: 'other'),
        const SyncScope(accountId: '../account', companyId: 'company'),
      ]) {
        expect(
          await cache.resolve(other, url, canDownload: () => false),
          isNull,
        );
      }
    },
  );

  test('offline miss never starts a request', () async {
    var calls = 0;
    final cache = store((_) async {
      calls++;
      return Stream.value([1]);
    });
    expect(await cache.resolve(scope, url, canDownload: () => false), isNull);
    expect(calls, 0);
  });

  test('concurrent thumbnail and preview download only once', () async {
    var calls = 0;
    final cache = store((_) async {
      calls++;
      return Stream.value([1]);
    });
    final results = await Future.wait(
      List.generate(
        5,
        (_) => cache.resolve(scope, url, canDownload: () => true),
      ),
    );
    expect(calls, 1);
    expect(results.every((file) => file?.path == results.first?.path), isTrue);
  });

  test('partial failure leaves no image and succeeds on retry', () async {
    var calls = 0;
    final cache = store((_) async {
      calls++;
      return calls == 1 ? failingStream() : Stream.value([4, 5]);
    });
    expect(await cache.resolve(scope, url, canDownload: () => true), isNull);
    expect(await cache.lookup(scope, url), isNull);
    expect(
      await root.list(recursive: true).where((e) => e is File).toList(),
      isEmpty,
    );
    final retry = await cache.resolve(scope, url, canDownload: () => true);
    expect(await retry!.readAsBytes(), [4, 5]);
  });

  test('size limit rejects stream and cleans partial file', () async {
    final cache = store((_) async => Stream.value(List.filled(21, 1)));
    expect(await cache.resolve(scope, url, canDownload: () => true), isNull);
    expect(
      await root.list(recursive: true).where((e) => e is File).toList(),
      isEmpty,
    );
  });

  test(
    'quota removes oldest downloaded image but preserves pending attachment',
    () async {
      final attachment = File('${root.path}/offline_attachments/pending.jpg');
      await attachment.parent.create(recursive: true);
      await attachment.writeAsBytes([9]);
      final cache = store((_) async => Stream.value([1, 2, 3]), quota: 5);
      final first = await cache.resolve(scope, url, canDownload: () => true);
      final second = await cache.resolve(
        scope,
        '$url-two',
        canDownload: () => true,
      );
      expect(await first!.exists(), isFalse);
      expect(await second!.exists(), isTrue);
      expect(await attachment.readAsBytes(), [9]);
    },
  );

  test(
    'scope invalidation during download prevents publishing the file',
    () async {
      var active = true;
      final cache = store((_) async {
        active = false;
        return Stream.value([1]);
      });
      expect(
        await cache.resolve(scope, url, canDownload: () => active),
        isNull,
      );
      expect(await cache.lookup(scope, url), isNull);
    },
  );

  test(
    'extracts known attachment and selfie URLs without visiting arbitrary links',
    () {
      expect(
        OfflineImageStore.urlsIn({
          'selfies': {
            'checkIn': url,
            'checkOut': 'https://storage.example/out',
          },
          'files': [
            {'url': url},
            {'url': 'https://storage.example/report.pdf'},
          ],
          'photos': ['https://storage.example/photo.png'],
          'website': 'https://company.example',
          'url': 'file:///private/photo.jpg',
        }),
        {
          url,
          'https://storage.example/out',
          'https://storage.example/photo.png',
        },
      );
    },
  );
}

Stream<List<int>> failingStream() async* {
  yield [1, 2];
  throw const SocketException('offline');
}

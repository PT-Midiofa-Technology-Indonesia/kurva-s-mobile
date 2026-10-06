import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:curva_mobile/core/files/durable_file_store.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';

void main() {
  late Directory temporaryDirectory;
  late Directory supportDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'curva_offline_test_',
    );
    supportDirectory = Directory('${temporaryDirectory.path}/support');
    await supportDirectory.create();
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'copies attachment into durable scoped storage and deletes it',
    () async {
      final source = File('${temporaryDirectory.path}/selfie.jpg');
      await source.writeAsBytes([1, 2, 3, 4]);
      final store = DurableFileStore(
        rootDirectory: () async => supportDirectory,
      );

      final attachment = await store.persist(
        sourcePath: source.path,
        scope: const SyncScope(accountId: 'account', companyId: 'company'),
        operationId: 'operation',
      );

      expect(attachment.path, contains('offline_attachments/account/company'));
      expect(await File(attachment.path).readAsBytes(), [1, 2, 3, 4]);
      expect(await store.checksumFor(attachment.path), attachment.checksum);

      await store.delete(attachment.path);
      expect(await File(attachment.path).exists(), isFalse);
    },
  );

  test('rejects attachment when durable storage quota is exceeded', () async {
    final source = File('${temporaryDirectory.path}/large.bin');
    await source.writeAsBytes([1, 2, 3, 4]);
    final store = DurableFileStore(
      rootDirectory: () async => supportDirectory,
      maxStorageBytes: 3,
    );

    await expectLater(
      store.persist(
        sourcePath: source.path,
        scope: const SyncScope(accountId: 'account', companyId: 'company'),
        operationId: 'operation',
      ),
      throwsA(isA<FileSystemException>()),
    );
  });
}

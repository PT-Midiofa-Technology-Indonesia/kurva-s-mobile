import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../sync/sync_models.dart';

class DurableAttachment {
  const DurableAttachment({
    required this.path,
    required this.originalName,
    required this.sizeBytes,
    required this.checksum,
  });

  final String path;
  final String originalName;
  final int sizeBytes;
  final String checksum;
}

class DurableFileStore {
  DurableFileStore({
    Future<Directory> Function()? rootDirectory,
    Uuid? uuid,
    this.maxStorageBytes = 250 * 1024 * 1024,
  }) : _rootDirectory = rootDirectory ?? getApplicationSupportDirectory,
       _uuid = uuid ?? const Uuid();

  final Future<Directory> Function() _rootDirectory;
  final Uuid _uuid;
  final int maxStorageBytes;

  Future<DurableAttachment> persist({
    required String sourcePath,
    required SyncScope scope,
    required String operationId,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('File lampiran tidak ditemukan.', sourcePath);
    }

    final sourceSize = await source.length();
    final root = await _attachmentRoot();
    final usedBytes = await _directorySize(root);
    if (usedBytes + sourceSize > maxStorageBytes) {
      throw const FileSystemException(
        'Penyimpanan lampiran offline sudah penuh.',
      );
    }

    final directory = Directory(
      p.join(
        root.path,
        _safeSegment(scope.accountId),
        _safeSegment(scope.companyId),
        _safeSegment(operationId),
      ),
    );
    await directory.create(recursive: true);
    final extension = p.extension(source.path);
    final destination = File(p.join(directory.path, '${_uuid.v4()}$extension'));
    await source.copy(destination.path);

    try {
      final checksum = await checksumFor(destination.path);
      return DurableAttachment(
        path: destination.path,
        originalName: p.basename(source.path),
        sizeBytes: sourceSize,
        checksum: checksum,
      );
    } catch (_) {
      await delete(destination.path);
      rethrow;
    }
  }

  Future<bool> exists(String path) => File(path).exists();

  Future<String> checksumFor(String path) async {
    final digest = await sha256.bind(File(path).openRead()).first;
    return digest.toString();
  }

  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();

    var directory = file.parent;
    final root = await _attachmentRoot();
    while (directory.path.startsWith(root.path) &&
        directory.path != root.path) {
      if (!await directory.exists() || await directory.list().isEmpty) {
        if (await directory.exists()) await directory.delete();
        directory = directory.parent;
      } else {
        break;
      }
    }
  }

  Future<Directory> _attachmentRoot() async {
    final support = await _rootDirectory();
    final root = Directory(p.join(support.path, 'offline_attachments'));
    await root.create(recursive: true);
    return root;
  }

  Future<int> _directorySize(Directory directory) async {
    if (!await directory.exists()) return 0;
    var total = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  String _safeSegment(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
  }
}

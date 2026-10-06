import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../sync/sync_models.dart';

/// Downloaded media is deliberately separate from pending upload attachments.
/// Paths are derived from the scoped URL already held in the API cache in Drift.
class OfflineImageStore {
  OfflineImageStore({
    required this.download,
    Future<Directory> Function()? rootDirectory,
    this.maxStorageBytes = 250 * 1024 * 1024,
    this.maxImageBytes = 20 * 1024 * 1024,
  }) : _rootDirectory = rootDirectory ?? getApplicationSupportDirectory;

  final Future<Stream<List<int>>> Function(String url) download;
  final Future<Directory> Function() _rootDirectory;
  final int maxStorageBytes;
  final int maxImageBytes;
  final Map<String, Future<File?>> _pending = {};
  Future<void> _tail = Future.value();

  static String _hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  Future<Directory> _root() async =>
      Directory(p.join((await _rootDirectory()).path, 'offline_images'));

  Future<File> _file(SyncScope scope, String url) async => File(
    p.join(
      (await _root()).path,
      _hash(jsonEncode([scope.accountId, scope.companyId])),
      _hash(url),
    ),
  );

  Future<File?> lookup(SyncScope scope, String url) async {
    final file = await _file(scope, url);
    if (!await file.exists() || await file.length() == 0) return null;
    await file.setLastModified(DateTime.now());
    return file;
  }

  /// Failures are best effort: they must never invalidate cached response data.
  Future<File?> resolve(
    SyncScope scope,
    String url, {
    required bool Function() canDownload,
  }) async {
    try {
      final cached = await lookup(scope, url);
      if (cached != null) return cached;
      if (!canDownload() || !isRemoteUrl(url)) return null;
      final key = jsonEncode([scope.accountId, scope.companyId, url]);
      final existing = _pending[key];
      if (existing != null) {
        final result = await existing;
        if (result != null || !canDownload()) return result;
        // A previous widget/scope lifecycle may have cancelled the shared job.
        if (identical(_pending[key], existing)) _pending.remove(key);
        return await resolve(scope, url, canDownload: canDownload);
      }
      final task = _tail.then((_) => _fetch(scope, url, canDownload));
      _pending[key] = task;
      _tail = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
      try {
        return await task;
      } finally {
        _pending.remove(key);
      }
    } on Object {
      return null;
    }
  }

  Future<File?> _fetch(
    SyncScope scope,
    String url,
    bool Function() canDownload,
  ) async {
    final cached = await lookup(scope, url);
    if (cached != null) return cached;
    if (!canDownload()) return null;
    final file = await _file(scope, url);
    await file.parent.create(recursive: true);
    // A killed process may leave incomplete downloads. The queue is serial,
    // so no other .part file belongs to an active download in this store.
    await for (final entity in (await _root()).list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.part')) {
        await entity.delete();
      }
    }
    final partial = File('${file.path}.part');
    try {
      final stream = await download(url);
      final sink = partial.openWrite();
      var size = 0;
      try {
        await sink.addStream(
          stream.map((chunk) {
            size += chunk.length;
            if (!canDownload() ||
                size > maxImageBytes ||
                size > maxStorageBytes) {
              throw const FileSystemException(
                'Unduhan gambar dibatalkan atau terlalu besar.',
              );
            }
            return chunk;
          }),
        );
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (size == 0 || !canDownload()) return null;
      await _makeRoom(size);
      return await partial.rename(file.path);
    } finally {
      if (await partial.exists()) await partial.delete();
    }
  }

  Future<void> _makeRoom(int incoming) async {
    final root = await _root();
    final files = <({File file, FileStat stat})>[];
    var used = 0;
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File || entity.path.endsWith('.part')) continue;
      final stat = await entity.stat();
      used += stat.size;
      files.add((file: entity, stat: stat));
    }
    files.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
    for (final entry in files) {
      if (used + incoming <= maxStorageBytes) break;
      await entry.file.delete();
      used -= entry.stat.size;
    }
  }

  static bool isRemoteUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  /// These fields mirror attachment and selfie contracts in the API models.
  static Set<String> urlsIn(Object? payload) {
    final urls = <String>{};
    void visit(Object? value, String? key) {
      if (value is Map) {
        for (final entry in value.entries) {
          visit(entry.value, entry.key.toString());
        }
      } else if (value is List) {
        for (final child in value) {
          visit(child, key);
        }
      } else if (value is String &&
          isRemoteUrl(value) &&
          const {
            'url',
            'fileUrl',
            'photoUrl',
            'imageUrl',
            'downloadUrl',
            'path',
            'checkIn',
            'checkOut',
            'photos',
            'files',
            'attachments',
          }.contains(key)) {
        final extension = p.extension(Uri.parse(value).path).toLowerCase();
        if (!const {
          '.pdf',
          '.doc',
          '.docx',
          '.xls',
          '.xlsx',
          '.zip',
        }.contains(extension)) {
          urls.add(value);
        }
      }
    }

    visit(payload, null);
    return urls;
  }
}

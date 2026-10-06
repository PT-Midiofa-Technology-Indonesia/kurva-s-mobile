import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/cache_key.dart';
import '../../../../core/sync/sync_models.dart';
import '../models/project_models.dart';

class CachedReference<T> {
  const CachedReference({required this.value, required this.fetchedAt});

  final T value;
  final DateTime fetchedAt;
}

class ProjectLocalDataSource {
  const ProjectLocalDataSource({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Stream<CachedReference<ProjectListResult>?> watchProjects({
    required SyncScope scope,
    Map<String, Object?> query = const {},
  }) {
    const endpointKey = 'project:list';
    final key = CacheKey.create(
      scope: scope,
      endpointKey: endpointKey,
      query: query,
    );
    return _database.watchCache(key, scope).map((row) {
      if (row == null) return null;
      final decoded = jsonDecode(row.payloadJson);
      if (decoded is! Map<String, dynamic>) return null;
      return CachedReference(
        value: ProjectListResult.fromJson(decoded),
        fetchedAt: row.fetchedAt,
      );
    });
  }

  Stream<CachedReference<Project>?> watchProjectDetail({
    required SyncScope scope,
    required String projectId,
  }) {
    final endpointKey = 'project:detail:$projectId';
    final key = CacheKey.create(scope: scope, endpointKey: endpointKey);
    return _database.watchCache(key, scope).map((row) {
      if (row == null) return null;
      final decoded = jsonDecode(row.payloadJson);
      if (decoded is! Map<String, dynamic>) return null;
      return CachedReference(
        value: Project.fromJson(decoded),
        fetchedAt: row.fetchedAt,
      );
    });
  }

  Future<void> putProjects({
    required SyncScope scope,
    required ProjectListResult result,
    Map<String, Object?> query = const {},
  }) {
    return _put(
      scope: scope,
      endpointKey: 'project:list',
      query: query,
      payload: result.toJson(),
    );
  }

  Future<void> putProjectDetail({
    required SyncScope scope,
    required Project project,
  }) {
    return _put(
      scope: scope,
      endpointKey: 'project:detail:${project.id}',
      payload: project.toJson(),
    );
  }

  Stream<CachedReference<List<ProjectBreakdownOption>>?> watchBreakdownOptions({
    required SyncScope scope,
    required String projectId,
    required String taskId,
  }) {
    final endpointKey = 'project:breakdown-options:$projectId:$taskId';
    final key = CacheKey.create(scope: scope, endpointKey: endpointKey);
    return _database.watchCache(key, scope).map((row) {
      if (row == null) return null;
      final decoded = jsonDecode(row.payloadJson);
      return CachedReference(
        value: ProjectBreakdownOption.listFromPayload(decoded),
        fetchedAt: row.fetchedAt,
      );
    });
  }

  Stream<CachedReference<List<ProjectReference>>?> watchSubordinates({
    required SyncScope scope,
    required String projectId,
  }) {
    final endpointKey = 'project:subordinates:$projectId';
    final key = CacheKey.create(scope: scope, endpointKey: endpointKey);
    return _database.watchCache(key, scope).map((row) {
      if (row == null) return null;
      final decoded = jsonDecode(row.payloadJson);
      final items = decoded is List ? decoded : const [];
      return CachedReference(
        value: items
            .whereType<Map<String, dynamic>>()
            .map(ProjectReference.fromJson)
            .toList(growable: false),
        fetchedAt: row.fetchedAt,
      );
    });
  }

  Future<void> putBreakdownOptions({
    required SyncScope scope,
    required String projectId,
    required String taskId,
    required List<ProjectBreakdownOption> options,
  }) {
    return _put(
      scope: scope,
      endpointKey: 'project:breakdown-options:$projectId:$taskId',
      payload: options.map((option) => option.toJson()).toList(),
    );
  }

  Future<void> putSubordinates({
    required SyncScope scope,
    required String projectId,
    required List<ProjectReference> subordinates,
  }) {
    return _put(
      scope: scope,
      endpointKey: 'project:subordinates:$projectId',
      payload: subordinates.map((item) => item.toJson()).toList(),
    );
  }

  Stream<CachedReference<List<ProjectTask>>?> watchTasks({
    required SyncScope scope,
    required String projectId,
    String? tab,
    bool qc = false,
    bool children = false,
    String? taskId,
  }) {
    final descriptor = _listDescriptor(
      projectId: projectId,
      tab: tab,
      qc: qc,
      children: children,
      taskId: taskId,
    );
    final key = CacheKey.create(
      scope: scope,
      endpointKey: descriptor.endpointKey,
      query: descriptor.query,
    );
    return _database.watchCache(key, scope).map((row) {
      if (row == null) return null;
      final decoded = jsonDecode(row.payloadJson);
      return CachedReference(
        value: ProjectTask.listFromPayload(decoded),
        fetchedAt: row.fetchedAt,
      );
    });
  }

  Stream<CachedReference<ProjectTasksResult>?> watchTaskResult({
    required SyncScope scope,
    required String projectId,
    String? tab,
  }) {
    final descriptor = _listDescriptor(
      projectId: projectId,
      tab: tab,
      qc: false,
      children: false,
      taskId: null,
    );
    final key = CacheKey.create(
      scope: scope,
      endpointKey: descriptor.endpointKey,
      query: descriptor.query,
    );
    return _database.watchCache(key, scope).map((row) {
      if (row == null) return null;
      return CachedReference(
        value: ProjectTasksResult.fromPayload(jsonDecode(row.payloadJson)),
        fetchedAt: row.fetchedAt,
      );
    });
  }

  Stream<CachedReference<ProjectTask>?> watchTaskDetail({
    required SyncScope scope,
    required String projectId,
    required String taskId,
    bool qc = false,
  }) {
    final endpointKey = qc
        ? 'project:qc-detail:$projectId:$taskId'
        : 'project:task-detail:$projectId:$taskId';
    final key = CacheKey.create(scope: scope, endpointKey: endpointKey);
    return _database.watchCache(key, scope).map((row) {
      if (row == null) return null;
      final decoded = jsonDecode(row.payloadJson);
      if (decoded is! Map<String, dynamic>) return null;
      return CachedReference(
        value: ProjectTask.fromJson(decoded),
        fetchedAt: row.fetchedAt,
      );
    });
  }

  Future<void> putTasks({
    required SyncScope scope,
    required String projectId,
    required List<ProjectTask> tasks,
    String? tab,
    bool qc = false,
    bool children = false,
    String? taskId,
  }) async {
    final descriptor = _listDescriptor(
      projectId: projectId,
      tab: tab,
      qc: qc,
      children: children,
      taskId: taskId,
    );
    await _put(
      scope: scope,
      endpointKey: descriptor.endpointKey,
      query: descriptor.query,
      payload: tasks.map((task) => task.toJson()).toList(),
    );
  }

  Future<void> putTaskResult({
    required SyncScope scope,
    required String projectId,
    required ProjectTasksResult result,
    String? tab,
  }) {
    final descriptor = _listDescriptor(
      projectId: projectId,
      tab: tab,
      qc: false,
      children: false,
      taskId: null,
    );
    return _put(
      scope: scope,
      endpointKey: descriptor.endpointKey,
      query: descriptor.query,
      payload: result.toJson(),
    );
  }

  Future<void> putTaskDetail({
    required SyncScope scope,
    required String projectId,
    required ProjectTask task,
    bool qc = false,
  }) {
    final endpointKey = qc
        ? 'project:qc-detail:$projectId:${task.id}'
        : 'project:task-detail:$projectId:${task.id}';
    return _put(scope: scope, endpointKey: endpointKey, payload: task.toJson());
  }

  Future<void> putHistory({
    required SyncScope scope,
    required String projectId,
    required String taskId,
    required List<Object?> items,
    bool qc = false,
  }) => _put(
    scope: scope,
    endpointKey:
        'project:${qc ? 'qc-history' : 'task-history'}:$projectId:$taskId',
    payload: items,
  );

  Future<List<ProjectTaskHistoryEntry>?> readHistory({
    required SyncScope scope,
    required String projectId,
    required String taskId,
    bool qc = false,
  }) async {
    final key = CacheKey.create(
      scope: scope,
      endpointKey:
          'project:${qc ? 'qc-history' : 'task-history'}:$projectId:$taskId',
    );
    final row = await _database.getCache(key, scope);
    if (row == null) return null;
    final decoded = jsonDecode(row.payloadJson);
    if (decoded is! List) return null;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ProjectTaskHistoryEntry.fromJson)
        .toList(growable: false);
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

  ({String endpointKey, Map<String, Object?> query}) _listDescriptor({
    required String projectId,
    required String? tab,
    required bool qc,
    required bool children,
    required String? taskId,
  }) {
    final endpointKey = children
        ? 'project:task-children:$projectId:${taskId ?? ''}'
        : qc
        ? 'project:qc-tasks:$projectId'
        : 'project:tasks:$projectId';
    return (endpointKey: endpointKey, query: {'tab': tab ?? ''});
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline_first_providers.dart';
import '../../core/network/server_refresh_delay.dart';
import '../../core/errors/app_exception.dart';
import '../../core/sync/sync_models.dart';
import '../../core/sync/sync_policy.dart';
import '../../shared/utils/date_formatter.dart';
import '../auth/auth_providers.dart';
import 'data/local/project_local_data_source.dart';
import 'data/models/effective_project_task.dart';
import 'data/models/project_models.dart';
import 'data/project_repository.dart';

// Refresh server-backed views after delivery without recreating form controllers.
final projectSyncRefreshProvider = Provider<void>((ref) {
  Timer? refreshTimer;
  ref.onDispose(() => refreshTimer?.cancel());
  ref.listen(syncStatusProvider, (previous, next) {
    final status = next.valueOrNull;
    if (previous?.valueOrNull?.state == SyncRunState.syncing &&
        status?.state == SyncRunState.completed &&
        (status?.completedCount ?? 0) > 0) {
      refreshTimer?.cancel();
      refreshTimer = Timer(serverRefreshDelay, () {
        ref
          ..invalidate(projectListProvider)
          ..invalidate(projectDetailProvider)
          ..invalidate(projectTasksProvider)
          ..invalidate(projectTaskChildrenProvider)
          ..invalidate(projectTaskDetailProvider)
          ..invalidate(projectQcTasksProvider)
          ..invalidate(projectQcTaskDetailProvider)
          ..invalidate(projectTaskHistoryProvider)
          ..invalidate(projectQcTaskHistoryProvider)
          ..invalidate(projectHistoryHasUnreadProvider)
          ..invalidate(projectTaskChildrenHistoryHasUnreadProvider)
          ..invalidate(projectManpowerHistoryHasUnreadProvider)
          ..invalidate(projectQcHistoryHasUnreadProvider);
      });
    }
  });
});

final projectLocalDataSourceProvider = Provider<ProjectLocalDataSource>((ref) {
  return ProjectLocalDataSource(database: ref.watch(appDatabaseProvider));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  var disposed = false;
  ref.onDispose(() => disposed = true);
  return ProjectRepository(
    dioClient: ref.watch(dioClientProvider),
    localDataSource: ref.watch(projectLocalDataSourceProvider),
    outboxService: ref.watch(outboxServiceProvider),
    scope: ref.watch(syncScopeProvider),
    cacheReadEnabled: ref.watch(projectCacheReadEnabledProvider),
    onHistoryRead: (path) {
      if (!disposed) {
        ref.read(projectHistoryReadProvider(path).notifier).state = true;
      }
    },
  );
});

// Keep the acknowledgement while the corresponding screen is mounted.
final projectHistoryReadProvider = StateProvider.autoDispose
    .family<bool, String>((ref, path) {
      ref.watch(syncScopeProvider);
      return false;
    });

final projectCacheReadEnabledProvider = Provider<bool>((ref) {
  return ref.watch(syncPolicyProvider).readMode('projectCacheRead') ==
      ReadCapability.cacheRead;
});

final projectFilterProvider = StateProvider<ProjectListFilter>((ref) {
  return const ProjectListFilter();
});

final projectListProvider =
    AutoDisposeAsyncNotifierProvider<ProjectListController, ProjectListState>(
      ProjectListController.new,
    );

class ProjectListState {
  const ProjectListState({
    required this.result,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final ProjectListResult result;
  final bool isLoadingMore;
  final Object? loadMoreError;
  bool get hasMore => result.meta.currentPage < result.meta.lastPage;
}

class ProjectListController extends AutoDisposeAsyncNotifier<ProjectListState> {
  int _generation = 0;

  @override
  Future<ProjectListState> build() async {
    _generation++;
    final generation = _generation;
    final filter = ref.watch(projectFilterProvider);
    final repository = ref.watch(projectRepositoryProvider);
    final canReadCache =
        ref.watch(projectCacheReadEnabledProvider) &&
        ref.watch(syncScopeProvider) != null;
    if (canReadCache) {
      final cached = await repository
          .watchProjects(
            status: filter.status,
            startDate: filter.startDateParam,
            endDate: filter.endDateParam,
            year: filter.year?.toString(),
          )
          .first;
      if (cached != null) {
        unawaited(_refreshFirstPage(filter, generation));
        return ProjectListState(result: cached.value);
      }
    }
    try {
      final result = await repository.fetchProjects(
        status: filter.status,
        startDate: filter.startDateParam,
        endDate: filter.endDateParam,
        year: filter.year?.toString(),
      );
      return ProjectListState(result: result);
    } catch (error) {
      if (canReadCache &&
          error is AppException &&
          error.kind == AppExceptionKind.connection) {
        throw const AppException(
          'Daftar project belum tersimpan di perangkat. Sambungkan internet dan buka menu Project sekali untuk menyiapkan akses offline.',
          kind: AppExceptionKind.offlineCacheMiss,
        );
      }
      rethrow;
    }
  }

  Future<void> _refreshFirstPage(
    ProjectListFilter filter,
    int generation,
  ) async {
    try {
      final result = await ref
          .read(projectRepositoryProvider)
          .fetchProjects(
            status: filter.status,
            startDate: filter.startDateParam,
            endDate: filter.endDateParam,
            year: filter.year?.toString(),
          );
      if (generation == _generation) {
        state = AsyncData(ProjectListState(result: result));
      }
    } catch (error, stack) {
      if (generation == _generation &&
          error is AppException &&
          error.isAccessDenied) {
        state = AsyncError(error, stack);
      }
      // Stale cache remains visible; connectivity UI already reports offline.
    }
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    final generation = _generation;
    state = AsyncData(
      ProjectListState(result: current.result, isLoadingMore: true),
    );
    try {
      final filter = ref.read(projectFilterProvider);
      final repository = ref.read(projectRepositoryProvider);
      final nextPage = current.result.meta.currentPage + 1;
      ProjectListResult? next;
      if (ref.read(projectCacheReadEnabledProvider) &&
          ref.read(syncScopeProvider) != null) {
        next =
            (await repository
                    .watchProjects(
                      status: filter.status,
                      startDate: filter.startDateParam,
                      endDate: filter.endDateParam,
                      year: filter.year?.toString(),
                      page: nextPage,
                    )
                    .first)
                ?.value;
      }
      next ??= await repository.fetchProjects(
        status: filter.status,
        startDate: filter.startDateParam,
        endDate: filter.endDateParam,
        year: filter.year?.toString(),
        page: nextPage,
      );
      if (generation != _generation) return;
      final projectsById = {
        for (final project in current.result.projects) project.id: project,
        for (final project in next.projects) project.id: project,
      };
      state = AsyncData(
        ProjectListState(
          result: ProjectListResult(
            projects: projectsById.values.toList(growable: false),
            meta: next.meta,
            links: next.links,
          ),
        ),
      );
    } catch (error) {
      if (generation != _generation) return;
      state = AsyncData(
        ProjectListState(result: current.result, loadMoreError: error),
      );
    }
  }
}

final projectDetailProvider = StreamProvider.family<Project, String>((
  ref,
  projectId,
) {
  final repository = ref.watch(projectRepositoryProvider);
  if (!ref.watch(projectCacheReadEnabledProvider) ||
      ref.watch(syncScopeProvider) == null) {
    return Stream.fromFuture(repository.fetchProjectDetail(projectId));
  }
  return _cachedProjectStream(
    watch: () => repository.watchProjectDetail(projectId),
    refresh: () => repository.fetchProjectDetail(projectId),
  );
});

final projectTasksProvider = StreamProvider.autoDispose
    .family<ProjectTasksResult, ProjectTasksQuery>((ref, query) {
      final repository = ref.watch(projectRepositoryProvider);
      if (!ref.watch(projectCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(
          repository.fetchProjectTasks(query.projectId, tab: query.tab),
        );
      }
      return _cachedValueStream(
        watch: () =>
            repository.watchProjectTaskResult(query.projectId, tab: query.tab),
        refresh: () =>
            repository.fetchProjectTasks(query.projectId, tab: query.tab),
      );
    });

final projectTaskChildrenProvider = StreamProvider.autoDispose
    .family<List<ProjectTask>, ProjectTaskQuery>((ref, query) {
      final repository = ref.watch(projectRepositoryProvider);
      if (!ref.watch(projectCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(
          repository.fetchTaskChildren(
            projectId: query.projectId,
            taskId: query.taskId,
            tab: query.tab,
          ),
        );
      }
      return _cachedListStream(
        watch: () => repository.watchProjectTasks(
          query.projectId,
          tab: query.tab,
          children: true,
          taskId: query.taskId,
        ),
        refresh: () => repository.fetchTaskChildren(
          projectId: query.projectId,
          taskId: query.taskId,
          tab: query.tab,
        ),
      );
    });

final projectTaskDetailProvider =
    StreamProvider.family<ProjectTask, ProjectTaskQuery>((ref, query) {
      final repository = ref.watch(projectRepositoryProvider);
      if (!ref.watch(projectCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(
          repository.fetchTaskDetail(
            projectId: query.projectId,
            taskId: query.taskId,
          ),
        );
      }
      return _cachedDetailStream(
        watch: () => repository.watchProjectTaskDetail(
          projectId: query.projectId,
          taskId: query.taskId,
        ),
        refresh: () => repository.fetchTaskDetail(
          projectId: query.projectId,
          taskId: query.taskId,
        ),
      );
    });

final projectHistoryHasUnreadProvider = FutureProvider.autoDispose
    .family<bool, ({String projectId, bool isQc})>((ref, query) {
      return ref
          .watch(projectRepositoryProvider)
          .fetchHistoryHasUnread(query.projectId, isQc: query.isQc);
    });

final projectTaskChildrenHistoryHasUnreadProvider = FutureProvider.autoDispose
    .family<bool, ({String projectId, String parentTaskId})>((ref, query) {
      return ref
          .watch(projectRepositoryProvider)
          .fetchTaskChildrenHistoryHasUnread(
            projectId: query.projectId,
            parentTaskId: query.parentTaskId,
          );
    });

final projectManpowerHistoryHasUnreadProvider = FutureProvider.autoDispose
    .family<bool, ({String projectId, String manpowerTaskId})>((ref, query) {
      return ref
          .watch(projectRepositoryProvider)
          .fetchManpowerHistoryHasUnread(
            projectId: query.projectId,
            manpowerTaskId: query.manpowerTaskId,
          );
    });

final projectTaskHistoryProvider = FutureProvider.autoDispose
    .family<List<ProjectTaskHistoryEntry>, ProjectTaskQuery>((ref, query) {
      return ref
          .watch(projectRepositoryProvider)
          .fetchTaskHistory(
            projectId: query.projectId,
            manpowerTaskId: query.taskId,
          );
    });

final projectQcHistoryHasUnreadProvider = FutureProvider.autoDispose
    .family<bool, ({String projectId, String qcTaskId})>((ref, query) {
      return ref
          .watch(projectRepositoryProvider)
          .fetchQcHistoryHasUnread(
            projectId: query.projectId,
            qcTaskId: query.qcTaskId,
          );
    });

final projectQcTaskHistoryProvider = FutureProvider.autoDispose
    .family<List<ProjectTaskHistoryEntry>, ProjectTaskQuery>((ref, query) {
      return ref
          .watch(projectRepositoryProvider)
          .fetchQcTaskHistory(
            projectId: query.projectId,
            qcTaskId: query.taskId,
          );
    });

final projectBreakdownOptionsProvider =
    StreamProvider.family<List<ProjectBreakdownOption>, ProjectTaskQuery>((
      ref,
      query,
    ) {
      final repository = ref.watch(projectRepositoryProvider);
      if (!ref.watch(projectCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(
          repository.fetchBreakdownOptions(
            projectId: query.projectId,
            taskId: query.taskId,
          ),
        );
      }
      return _cachedListStream(
        watch: () => repository.watchBreakdownOptions(
          projectId: query.projectId,
          taskId: query.taskId,
        ),
        refresh: () => repository.fetchBreakdownOptions(
          projectId: query.projectId,
          taskId: query.taskId,
        ),
        unavailableMessage:
            'Pilihan breakdown belum tersedia di perangkat. Buka halaman ini sekali saat online.',
      );
    });

final projectSubordinatesProvider =
    StreamProvider.family<List<ProjectReference>, String>((ref, projectId) {
      final repository = ref.watch(projectRepositoryProvider);
      if (!ref.watch(projectCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(
          repository.fetchProjectSubordinates(projectId),
        );
      }
      return _cachedListStream(
        watch: () => repository.watchSubordinates(projectId),
        refresh: () => repository.fetchProjectSubordinates(projectId),
        unavailableMessage:
            'Daftar assignee belum tersedia di perangkat. Buka halaman ini sekali saat online.',
      );
    });

final projectHelpersProvider = FutureProvider.autoDispose
    .family<List<ProjectHelper>, String>((ref, projectId) {
      return ref
          .watch(projectRepositoryProvider)
          .fetchProjectHelpers(projectId);
    });

final projectQcTasksProvider = StreamProvider.autoDispose
    .family<List<ProjectTask>, ProjectTasksQuery>((ref, query) {
      final repository = ref.watch(projectRepositoryProvider);
      if (!ref.watch(projectCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(
          repository.fetchQcTasks(query.projectId, tab: query.tab),
        );
      }
      return _cachedListStream(
        watch: () => repository.watchProjectTasks(
          query.projectId,
          tab: query.tab,
          qc: true,
        ),
        refresh: () => repository.fetchQcTasks(query.projectId, tab: query.tab),
      );
    });

final projectQcTaskDetailProvider =
    StreamProvider.family<ProjectTask, ProjectTaskQuery>((ref, query) {
      final repository = ref.watch(projectRepositoryProvider);
      if (!ref.watch(projectCacheReadEnabledProvider) ||
          ref.watch(syncScopeProvider) == null) {
        return Stream.fromFuture(
          repository.fetchQcTaskDetail(
            projectId: query.projectId,
            qcTaskId: query.taskId,
          ),
        );
      }
      return _cachedDetailStream(
        watch: () => repository.watchProjectTaskDetail(
          projectId: query.projectId,
          taskId: query.taskId,
          qc: true,
        ),
        refresh: () => repository.fetchQcTaskDetail(
          projectId: query.projectId,
          qcTaskId: query.taskId,
        ),
      );
    });

final projectTargetOperationProvider =
    StreamProvider.family<ProjectTaskSyncOverlay?, ProjectTargetOperationQuery>(
      (ref, query) {
        final scope = ref.watch(syncScopeProvider);
        if (scope == null) return Stream.value(null);
        return ref
            .watch(appDatabaseProvider)
            .watchTargetOperation(
              scope: scope,
              operationType: query.operationType,
              targetResourceKey: query.targetResourceKey,
            )
            .map(
              (operation) => operation == null
                  ? null
                  : ProjectTaskSyncOverlay.fromOperation(operation),
            );
      },
    );

class ProjectTargetOperationQuery {
  const ProjectTargetOperationQuery({
    required this.operationType,
    required this.targetResourceKey,
  });

  final SyncOperationType operationType;
  final String targetResourceKey;

  @override
  bool operator ==(Object other) =>
      other is ProjectTargetOperationQuery &&
      operationType == other.operationType &&
      targetResourceKey == other.targetResourceKey;

  @override
  int get hashCode => Object.hash(operationType, targetResourceKey);
}

Stream<List<T>> _cachedListStream<T>({
  required Stream<CachedReference<List<T>>?> Function() watch,
  required Future<List<T>> Function() refresh,
  String unavailableMessage =
      'Data task belum tersedia di perangkat. Sambungkan internet dan buka kembali project ini untuk menyiapkan data offline.',
}) async* {
  final cached = await watch().first;
  if (cached != null) yield cached.value;
  try {
    await refresh();
  } catch (error) {
    if (error is AppException && error.isAccessDenied) rethrow;
    if (cached == null &&
        (error is! AppException || error.kind != AppExceptionKind.connection)) {
      rethrow;
    }
    if (cached == null) {
      throw AppException(
        unavailableMessage,
        kind: AppExceptionKind.offlineCacheMiss,
      );
    }
  }
  yield* watch().where((value) => value != null).map((value) => value!.value);
}

Stream<T> _cachedValueStream<T>({
  required Stream<CachedReference<T>?> Function() watch,
  required Future<T> Function() refresh,
}) async* {
  final cached = await watch().first;
  if (cached != null) yield cached.value;
  try {
    await refresh();
  } catch (error) {
    if (error is AppException && error.isAccessDenied) rethrow;
    if (cached == null &&
        (error is! AppException || error.kind != AppExceptionKind.connection)) {
      rethrow;
    }
    if (cached == null) {
      throw const AppException(
        'Data task belum tersedia di perangkat. Sambungkan internet dan buka kembali project ini untuk menyiapkan data offline.',
        kind: AppExceptionKind.offlineCacheMiss,
      );
    }
  }
  yield* watch().where((value) => value != null).map((value) => value!.value);
}

Stream<ProjectTask> _cachedDetailStream({
  required Stream<CachedReference<ProjectTask>?> Function() watch,
  required Future<ProjectTask> Function() refresh,
}) async* {
  final cached = await watch().first;
  if (cached != null) yield cached.value;
  try {
    await refresh();
  } catch (error) {
    if (error is AppException && error.isAccessDenied) rethrow;
    if (cached == null &&
        (error is! AppException || error.kind != AppExceptionKind.connection)) {
      rethrow;
    }
    if (cached == null) {
      throw const AppException(
        'Data task belum tersedia di perangkat. Sambungkan internet dan buka kembali project ini untuk menyiapkan data offline.',
        kind: AppExceptionKind.offlineCacheMiss,
      );
    }
  }
  yield* watch().where((value) => value != null).map((value) => value!.value);
}

Stream<Project> _cachedProjectStream({
  required Stream<CachedReference<Project>?> Function() watch,
  required Future<Project> Function() refresh,
}) async* {
  final cached = await watch().first;
  if (cached != null) yield cached.value;
  try {
    await refresh();
  } catch (error) {
    if (error is AppException && error.isAccessDenied) rethrow;
    if (cached == null &&
        (error is! AppException || error.kind != AppExceptionKind.connection)) {
      rethrow;
    }
    if (cached == null) {
      throw const AppException(
        'Data project belum tersedia di perangkat. Sambungkan internet dan buka kembali project ini untuk menyiapkan data offline.',
        kind: AppExceptionKind.offlineCacheMiss,
      );
    }
  }
  yield* watch().where((value) => value != null).map((value) => value!.value);
}

class ProjectTasksQuery {
  const ProjectTasksQuery({required this.projectId, this.tab});

  final String projectId;
  final String? tab;

  @override
  bool operator ==(Object other) {
    return other is ProjectTasksQuery &&
        other.projectId == projectId &&
        other.tab == tab;
  }

  @override
  int get hashCode => Object.hash(projectId, tab);
}

class ProjectTaskQuery {
  const ProjectTaskQuery({
    required this.projectId,
    required this.taskId,
    this.tab,
  });

  final String projectId;
  final String taskId;
  final String? tab;

  @override
  bool operator ==(Object other) {
    return other is ProjectTaskQuery &&
        other.projectId == projectId &&
        other.taskId == taskId &&
        other.tab == tab;
  }

  @override
  int get hashCode => Object.hash(projectId, taskId, tab);
}

class ProjectListFilter {
  const ProjectListFilter({
    this.status,
    this.startDate,
    this.endDate,
    this.year,
  });

  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? year;

  int get activeCount {
    return [
      status,
      startDate,
      endDate,
      year,
    ].where((value) => value != null).length;
  }

  String? get startDateParam => formatDateParam(startDate);

  String? get endDateParam => formatDateParam(endDate);
}

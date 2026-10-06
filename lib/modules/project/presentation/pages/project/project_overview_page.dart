import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_underline_tabs.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/project/project_detail_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_task_list_page.dart';

class ProjectOverviewPage extends ConsumerStatefulWidget {
  const ProjectOverviewPage({required this.detail, super.key});

  final ProjectOverviewData detail;

  static const _fontFamily = AppFonts.inter;
  static const _backgroundColor = AppColors.white;

  @override
  ConsumerState<ProjectOverviewPage> createState() =>
      _ProjectOverviewPageState();
}

class _ProjectOverviewPageState extends ConsumerState<ProjectOverviewPage> {
  _OverviewTab _activeTab = _OverviewTab.task;
  var _taskCount = 0;

  Future<void> _refreshOverview({
    required String projectId,
    required bool isQc,
  }) async {
    ref.invalidate(
      projectHistoryHasUnreadProvider((projectId: projectId, isQc: isQc)),
    );
    final tasksQueries = [
      ProjectTasksQuery(projectId: projectId, tab: _activeTab.apiValue),
    ];
    final usesProjectCache =
        ref.read(projectCacheReadEnabledProvider) &&
        ref.read(syncScopeProvider) != null;
    if (usesProjectCache) {
      final repository = ref.read(projectRepositoryProvider);
      try {
        await Future.wait<Object?>([
          for (final query in tasksQueries)
            isQc
                ? repository.fetchQcTasks(projectId, tab: query.tab)
                : repository.fetchProjectTasks(projectId, tab: query.tab),
          if (isQc)
            repository.fetchProjectTasks(
              projectId,
              tab: _OverviewTab.task.apiValue,
            ),
          repository.fetchProjectDetail(projectId),
        ]);
      } catch (_) {
        // Keep showing cached data when a queued submission is still offline.
      }
      return;
    }

    await Future.wait<void>([
      for (final query in tasksQueries)
        ref
            .refresh(
              isQc
                  ? projectQcTasksProvider(query).future
                  : projectTasksProvider(query).future,
            )
            .then<void>((_) {}),
      if (isQc)
        ref
            .refresh(
              projectTasksProvider(
                ProjectTasksQuery(
                  projectId: projectId,
                  tab: _OverviewTab.task.apiValue,
                ),
              ).future,
            )
            .then<void>((_) {}),
      ref.refresh(projectDetailProvider(projectId).future).then<void>((_) {}),
    ]);
  }

  void _onTaskCountChanged(int count) {
    if (_taskCount == count) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _taskCount != count) setState(() => _taskCount = count);
    });
  }

  @override
  Widget build(BuildContext context) {
    final latestProject = widget.detail.projectId.isEmpty
        ? null
        : ref.watch(projectDetailProvider(widget.detail.projectId)).valueOrNull;
    final detail = latestProject == null
        ? widget.detail
        : ProjectOverviewData.fromProject(
            latestProject,
            title: widget.detail.title,
          );
    final isQc = detail.title == ProjectTaskListPage.qualityProjectTitle;
    final historyPath = '${detail.projectId}/${isQc ? 'qc-tasks' : 'tasks'}';
    final historyRead = ref.watch(projectHistoryReadProvider(historyPath));
    final hasUnreadHistory =
        !historyRead &&
        detail.projectId.isNotEmpty &&
        (ref
                .watch(
                  projectHistoryHasUnreadProvider((
                    projectId: detail.projectId,
                    isQc: isQc,
                  )),
                )
                .valueOrNull ??
            false);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ColoredBox(
          color: ProjectOverviewPage._backgroundColor,
          child: Column(
            children: [
              AppHeader(
                title: detail.title,
                onBackPressed: () => context.pop(),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: detail.projectId.isEmpty
                      ? () async {}
                      : () => _refreshOverview(
                          projectId: detail.projectId,
                          isQc: isQc,
                        ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _OverviewTabs(
                        activeTab: _activeTab,
                        taskCount: _taskCount,
                        hasUnreadHistory: hasUnreadHistory,
                        onTabSelected: (tab) {
                          if (tab == _OverviewTab.history) {
                            ref
                                    .read(
                                      projectHistoryReadProvider(
                                        historyPath,
                                      ).notifier,
                                    )
                                    .state =
                                true;
                          }
                          setState(() => _activeTab = tab);
                        },
                      ),
                      const SizedBox(height: 16),
                      _OverviewTaskList(
                        detail: detail,
                        tab: _activeTab,
                        onTaskCountChanged: _onTaskCountChanged,
                        onRefreshRequested: () => _refreshOverview(
                          projectId: detail.projectId,
                          isQc: isQc,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _OverviewTab {
  task('Task', 'open', 118),
  history('History', 'history', 104);

  const _OverviewTab(this.label, this.apiValue, this.width);

  final String label;
  final String apiValue;
  final double width;
}

class _OverviewTabs extends StatelessWidget {
  const _OverviewTabs({
    required this.activeTab,
    required this.taskCount,
    required this.hasUnreadHistory,
    required this.onTabSelected,
  });

  final _OverviewTab activeTab;
  final int taskCount;
  final bool hasUnreadHistory;
  final ValueChanged<_OverviewTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return AppUnderlineTabs(
      items: [
        for (final tab in _OverviewTab.values)
          AppUnderlineTabItem(
            label: tab == _OverviewTab.task
                ? '${tab.label} ($taskCount)'
                : tab.label,
            width: tab.width,
            showIndicatorDot: tab == _OverviewTab.history && hasUnreadHistory,
          ),
      ],
      selectedIndex: _OverviewTab.values.indexOf(activeTab),
      onTabSelected: (index) => onTabSelected(_OverviewTab.values[index]),
      fontFamily: ProjectOverviewPage._fontFamily,
      horizontalPadding: const EdgeInsets.symmetric(horizontal: 16),
      inactiveColor: AppColors.muted,
      expandItems: true,
    );
  }
}

class _OverviewTaskList extends ConsumerWidget {
  const _OverviewTaskList({
    required this.detail,
    required this.tab,
    required this.onTaskCountChanged,
    required this.onRefreshRequested,
  });

  static const _emptyStateHeight = 400.0;

  final ProjectOverviewData detail;
  final _OverviewTab tab;
  final ValueChanged<int> onTaskCountChanged;
  final Future<void> Function() onRefreshRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (detail.projectId.isEmpty) {
      return const SizedBox(
        height: _emptyStateHeight,
        child: EmptyView(message: 'Data tugas belum tersedia.'),
      );
    }

    final tasksQuery = ProjectTasksQuery(
      projectId: detail.projectId,
      tab: tab.apiValue,
    );
    final isQc = detail.title == ProjectTaskListPage.qualityProjectTitle;
    final AsyncValue<_OverviewTasksData> tasksState = isQc
        ? ref
              .watch(projectQcTasksProvider(tasksQuery))
              .whenData(
                (tasks) =>
                    _OverviewTasksData(tasks: tasks, count: tasks.length),
              )
        : ref
              .watch(projectTasksProvider(tasksQuery))
              .whenData(
                (result) => _OverviewTasksData(
                  tasks: result.tasks,
                  count: tab == _OverviewTab.task
                      ? result.inProgressCount
                      : result.doneCount,
                ),
              );

    return tasksState.when(
      loading: () =>
          const SizedBox(height: 180, child: AppSkeletonSectionList()),
      error: (error, _) => SizedBox(
        height: 180,
        child: NetworkAwareErrorView(
          error: error,
          cacheFeatureKey: 'projectCacheRead',
          message: error.toString(),
          onRetry: () => ref.invalidate(
            isQc
                ? projectQcTasksProvider(tasksQuery)
                : projectTasksProvider(tasksQuery),
          ),
        ),
      ),
      data: (data) {
        final cards = data.tasks
            .map(
              (task) => ProjectTaskListItemData.fromTask(
                task,
                fallbackProjectId: detail.projectId,
                isQc: isQc,
              ),
            )
            .toList(growable: false);
        if (tab == _OverviewTab.task) {
          onTaskCountChanged(data.count);
        }
        if (cards.isEmpty) {
          return const SizedBox(
            height: _emptyStateHeight,
            child: EmptyView(message: 'Data tugas belum tersedia.'),
          );
        }

        return _OverviewTaskCards(
          tasks: cards,
          type: detail.title,
          onRefreshRequested: onRefreshRequested,
        );
      },
    );
  }
}

class _OverviewTasksData {
  const _OverviewTasksData({required this.tasks, required this.count});

  final List<ProjectTask> tasks;
  final int count;
}

class _OverviewTaskCards extends StatelessWidget {
  const _OverviewTaskCards({
    required this.tasks,
    required this.type,
    required this.onRefreshRequested,
  });

  final List<ProjectTaskListItemData> tasks;
  final String type;
  final Future<void> Function() onRefreshRequested;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          for (var index = 0; index < tasks.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == tasks.length - 1 ? 0 : 16,
              ),
              child: ProjectTaskCardAction(
                task: tasks[index],
                type: type,
                onRefreshRequested: onRefreshRequested,
              ),
            ),
        ],
      ),
    );
  }
}

class ProjectOverviewData {
  const ProjectOverviewData({
    required this.projectId,
    required this.projectName,
    required this.title,
    required this.taskProject,
    required this.qualityControl,
    required this.taskMeeting,
    required this.qualityMeeting,
  });

  final String projectId;
  final String projectName;
  final String title;
  final int taskProject;
  final int qualityControl;
  final int taskMeeting;
  final int qualityMeeting;

  factory ProjectOverviewData.fromProject(
    Project project, {
    required String title,
  }) {
    final summary = project.summary;
    return ProjectOverviewData(
      projectId: project.id,
      projectName: project.name,
      title: title,
      taskProject: summary?.taskProject ?? project.nodesCount,
      qualityControl: summary?.qualityControl ?? 0,
      taskMeeting: summary?.taskMeeting ?? 0,
      qualityMeeting: summary?.qualityMeeting ?? 0,
    );
  }

  factory ProjectOverviewData.fallback() {
    return const ProjectOverviewData(
      projectId: '',
      projectName: 'Project',
      title: ProjectTaskListPage.taskProjectTitle,
      taskProject: 210,
      qualityControl: 20,
      taskMeeting: 0,
      qualityMeeting: 0,
    );
  }

  ProjectDetailData toDetailData() {
    return ProjectDetailData(
      projectId: projectId,
      title: title,
      projectName: projectName,
      status: '-',
      client: '-',
      period: '-',
      description: '-',
      workingDays: '-',
      taskCount: taskProject.toString(),
    );
  }
}

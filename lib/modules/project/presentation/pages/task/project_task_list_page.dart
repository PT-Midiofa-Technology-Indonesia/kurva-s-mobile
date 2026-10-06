import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/core/network/server_refresh_delay.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/full_page_search_bottom_sheet.dart';
import 'package:curva_mobile/shared/widgets/app_underline_tabs.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/selection_bottom_sheet.dart';
import 'package:curva_mobile/modules/project/data/models/project_models.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_assignee_picker_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_qc_assignment_picker_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/task/project_sub_task_picker_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/project/project_detail_page.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_task_detail_page.dart';
import 'package:curva_mobile/modules/project/presentation/widgets/project_task_card.dart';

class ProjectTaskListPage extends ConsumerStatefulWidget {
  const ProjectTaskListPage({
    required this.detail,
    this.title = taskProjectTitle,
    this.parentTaskId = '',
    this.parentTaskCode = '',
    this.initialTabIndex = 0,
    super.key,
  });

  final ProjectDetailData detail;
  final String title;
  final String parentTaskId;
  final String parentTaskCode;
  final int initialTabIndex;

  static const taskProjectTitle = 'Task Project';
  static const qualityProjectTitle = 'Quality Project';
  static const _fontFamily = AppFonts.inter;
  static const _backgroundColor = AppColors.cardBackground;
  static const _green = AppColors.assigneeGreen;
  static const _magenta = AppColors.assigneeMagenta;
  static const _purple = AppColors.assigneePurple;

  @override
  ConsumerState<ProjectTaskListPage> createState() =>
      _ProjectTaskListPageState();
}

class _ProjectTaskListPageState extends ConsumerState<ProjectTaskListPage> {
  late _SubTaskTab _activeTab;
  var _taskCount = 0;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex == 1
        ? _SubTaskTab.history
        : _SubTaskTab.task;
  }

  void _onTaskCountChanged(int count) {
    if (_taskCount == count) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _taskCount != count) setState(() => _taskCount = count);
    });
  }

  Future<void> _showSearch() async {
    final tasks = await _searchableTasks();
    if (!mounted) return;

    if (tasks.isEmpty) {
      AppToast.info(context, 'Data task belum tersedia.');
      return;
    }

    final selectedTask =
        await FullPageSearchBottomSheet.show<ProjectTaskListItemData>(
          context,
          title: 'Pencarian',
          options: tasks,
          labelBuilder: _searchTaskLabel,
          searchTextBuilder: (task) => '${task.code} ${task.title}',
        );

    if (!mounted || selectedTask == null) return;

    final didUpdate = await context.push<bool>(
      widget.title == ProjectTaskListPage.qualityProjectTitle
          ? RouteNames.projectQualityControl
          : RouteNames.projectSubTaskDetail,
      extra: selectedTask.toDetailData(),
    );
    if (didUpdate == true && mounted) {
      await _reloadActiveTasks();
    }
  }

  Future<void> _reloadActiveTasks() async {
    final projectId = widget.detail.projectId;
    if (projectId.isEmpty) return;

    final tab = _activeTab.apiValue;
    if (widget.title == ProjectTaskListPage.qualityProjectTitle) {
      await ref
          .refresh(
            projectQcTasksProvider(
              ProjectTasksQuery(projectId: projectId, tab: tab),
            ).future,
          )
          .then<void>((_) {});
      return;
    }
    if (widget.parentTaskId.isNotEmpty) {
      ref.invalidate(
        projectTaskChildrenHistoryHasUnreadProvider((
          projectId: projectId,
          parentTaskId: widget.parentTaskId,
        )),
      );
      await ref
          .refresh(
            projectTaskChildrenProvider(
              ProjectTaskQuery(
                projectId: projectId,
                taskId: widget.parentTaskId,
                tab: tab,
              ),
            ).future,
          )
          .then<void>((_) {});
      return;
    }

    await ref
        .refresh(
          projectTasksProvider(
            ProjectTasksQuery(projectId: projectId, tab: tab),
          ).future,
        )
        .then<void>((_) {});
  }

  Future<List<ProjectTaskListItemData>> _searchableTasks() async {
    if (widget.detail.projectId.isEmpty) {
      return const [];
    }

    try {
      final tasks = await _loadBackendTasks();
      return tasks
          .map(
            (task) => ProjectTaskListItemData.fromTask(
              task,
              fallbackProjectId: widget.detail.projectId,
              isQc: widget.title == ProjectTaskListPage.qualityProjectTitle,
            ),
          )
          .toList(growable: false);
    } catch (error) {
      if (mounted) {
        AppToast.error(context, error);
      }
      return const [];
    }
  }

  Future<List<ProjectTask>> _loadBackendTasks() {
    final tab = _activeTab.apiValue;
    final tasksQuery = ProjectTasksQuery(
      projectId: widget.detail.projectId,
      tab: tab,
    );

    if (widget.title == ProjectTaskListPage.qualityProjectTitle) {
      return ref.read(projectQcTasksProvider(tasksQuery).future);
    }
    if (widget.parentTaskId.isNotEmpty) {
      return ref.read(
        projectTaskChildrenProvider(
          ProjectTaskQuery(
            projectId: widget.detail.projectId,
            taskId: widget.parentTaskId,
            tab: tab,
          ),
        ).future,
      );
    }

    return ref
        .read(projectTasksProvider(tasksQuery).future)
        .then((result) => result.tasks);
  }

  @override
  Widget build(BuildContext context) {
    final usesChildren =
        widget.title != ProjectTaskListPage.qualityProjectTitle &&
        widget.parentTaskId.isNotEmpty;
    final historyPath = usesChildren
        ? '${widget.detail.projectId}/tasks/${widget.parentTaskId}/children'
        : '${widget.detail.projectId}/${widget.title == ProjectTaskListPage.qualityProjectTitle ? 'qc-tasks' : 'tasks'}';
    final historyRead = ref.watch(projectHistoryReadProvider(historyPath));
    final hasUnreadHistory = usesChildren
        ? widget.detail.projectId.isNotEmpty &&
              (ref
                      .watch(
                        projectTaskChildrenHistoryHasUnreadProvider((
                          projectId: widget.detail.projectId,
                          parentTaskId: widget.parentTaskId,
                        )),
                      )
                      .valueOrNull ??
                  false)
        : true;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ColoredBox(
          color: ProjectTaskListPage._backgroundColor,
          child: Column(
            children: [
              Container(
                color: AppColors.white,
                child: Column(
                  children: [
                    _ProjectSubTaskHeader(
                      title: widget.parentTaskCode.isEmpty
                          ? widget.title
                          : '${widget.title} ${widget.parentTaskCode}',
                      onBackPressed: () => context.pop(),
                      onSearchPressed: _showSearch,
                    ),
                    _SubTaskTabs(
                      activeTab: _activeTab,
                      taskCount: _taskCount,
                      hasUnreadHistory:
                          !historyRead &&
                          _activeTab != _SubTaskTab.history &&
                          hasUnreadHistory,
                      onTabSelected: (tab) {
                        if (tab == _SubTaskTab.history) {
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
                  ],
                ),
              ),
              Expanded(
                child: _SubTaskTabView(
                  tab: _activeTab,
                  type: widget.title,
                  detail: widget.detail,
                  parentTaskId: widget.parentTaskId,
                  onTaskCountChanged: _onTaskCountChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectSubTaskHeader extends StatelessWidget {
  const _ProjectSubTaskHeader({
    required this.title,
    required this.onBackPressed,
    required this.onSearchPressed,
  });

  final String title;
  final VoidCallback onBackPressed;
  final VoidCallback onSearchPressed;

  @override
  Widget build(BuildContext context) {
    return AppHeader(
      title: title,
      onBackPressed: onBackPressed,
      actions: [
        AppHeaderAction(
          icon: Icons.search,
          tooltip: 'Cari',
          onPressed: onSearchPressed,
        ),
      ],
    );
  }
}

enum _SubTaskTab {
  task('Task', 118),
  history('History', 104);

  const _SubTaskTab(this.label, this.width);

  final String label;
  final double width;

  String get apiValue {
    return switch (this) {
      _SubTaskTab.task => 'open',
      _SubTaskTab.history => 'history',
    };
  }
}

class _SubTaskTabs extends StatelessWidget {
  const _SubTaskTabs({
    required this.activeTab,
    required this.taskCount,
    required this.hasUnreadHistory,
    required this.onTabSelected,
  });

  final _SubTaskTab activeTab;
  final int taskCount;
  final bool hasUnreadHistory;
  final ValueChanged<_SubTaskTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return AppUnderlineTabs(
      items: [
        for (final tab in _SubTaskTab.values)
          AppUnderlineTabItem(
            label: tab == _SubTaskTab.task ? 'Task ($taskCount)' : tab.label,
            width: tab.width,
            showIndicatorDot: tab == _SubTaskTab.history && hasUnreadHistory,
          ),
      ],
      selectedIndex: _SubTaskTab.values.indexOf(activeTab),
      onTabSelected: (index) => onTabSelected(_SubTaskTab.values[index]),
      fontFamily: ProjectTaskListPage._fontFamily,
      horizontalPadding: const EdgeInsets.symmetric(horizontal: 16),
      inactiveColor: AppColors.muted,
      expandItems: true,
    );
  }
}

class _SubTaskTabView extends ConsumerWidget {
  const _SubTaskTabView({
    required this.tab,
    required this.type,
    required this.detail,
    required this.parentTaskId,
    required this.onTaskCountChanged,
  });

  final _SubTaskTab tab;
  final String type;
  final ProjectDetailData detail;
  final String parentTaskId;
  final ValueChanged<int> onTaskCountChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (detail.projectId.isEmpty) {
      if (tab == _SubTaskTab.task) onTaskCountChanged(0);
      return const EmptyView(
        title: 'Belum ada tugas diberikan',
        message: 'Belum ada tugas diberikan. Silakan\nhubungi Admin.',
      );
    }

    final tabValue = tab.apiValue;
    final tasksQuery = ProjectTasksQuery(
      projectId: detail.projectId,
      tab: tabValue,
    );
    final taskQuery = ProjectTaskQuery(
      projectId: detail.projectId,
      taskId: parentTaskId,
      tab: tabValue,
    );
    final AsyncValue<List<ProjectTask>> tasksState =
        type == ProjectTaskListPage.qualityProjectTitle
        ? ref.watch(projectQcTasksProvider(tasksQuery))
        : parentTaskId.isEmpty
        ? ref
              .watch(projectTasksProvider(tasksQuery))
              .whenData((result) => result.tasks)
        : ref.watch(projectTaskChildrenProvider(taskQuery));

    Future<void> reloadTasks() async {
      if (type == ProjectTaskListPage.qualityProjectTitle) {
        await ref
            .refresh(projectQcTasksProvider(tasksQuery).future)
            .then<void>((_) {});
        return;
      }
      if (parentTaskId.isNotEmpty) {
        ref.invalidate(
          projectTaskChildrenHistoryHasUnreadProvider((
            projectId: detail.projectId,
            parentTaskId: parentTaskId,
          )),
        );
        await ref
            .refresh(projectTaskChildrenProvider(taskQuery).future)
            .then<void>((_) {});
        return;
      }

      await ref
          .refresh(projectTasksProvider(tasksQuery).future)
          .then<void>((_) {});
    }

    Future<void> refreshTasks() async {
      await ref
          .read(syncCoordinatorProvider)
          .syncNow(SyncTrigger.userInitiated);
      await reloadTasks();
    }

    return tasksState.when(
      loading: () => const AppSkeletonListView(
        variant: AppSkeletonListVariant.detailed,
        itemCount: 4,
        showSectionHeader: false,
        padding: EdgeInsets.all(AppSpacing.md),
      ),
      error: (error, _) => NetworkAwareErrorView(
        error: error,
        cacheFeatureKey: 'projectCacheRead',
        message: error.toString(),
        onRetry: () {
          if (type == ProjectTaskListPage.qualityProjectTitle) {
            ref.invalidate(projectQcTasksProvider(tasksQuery));
          } else if (parentTaskId.isNotEmpty) {
            ref.invalidate(projectTaskChildrenProvider(taskQuery));
          } else {
            ref.invalidate(projectTasksProvider(tasksQuery));
          }
        },
      ),
      data: (tasks) {
        final filteredTasks = tasks
            .map(
              (task) => ProjectTaskListItemData.fromTask(
                task,
                fallbackProjectId: detail.projectId,
                isQc: type == ProjectTaskListPage.qualityProjectTitle,
              ),
            )
            .toList(growable: false);

        if (tab == _SubTaskTab.task) {
          onTaskCountChanged(filteredTasks.length);
        }

        if (filteredTasks.isEmpty) {
          return RefreshIndicator(
            onRefresh: refreshTasks,
            child: const _ProjectTaskEmptyState(),
          );
        }

        return RefreshIndicator(
          onRefresh: refreshTasks,
          child: _TaskList(
            tasks: filteredTasks,
            type: type,
            onRefreshRequested: reloadTasks,
          ),
        );
      },
    );
  }
}

class _ProjectTaskEmptyState extends StatelessWidget {
  const _ProjectTaskEmptyState();

  @override
  Widget build(BuildContext context) {
    return const EmptyView(
      title: 'Belum ada tugas diberikan',
      message: 'Belum ada tugas diberikan. Silakan\nhubungi Admin.',
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.tasks,
    required this.type,
    required this.onRefreshRequested,
  });

  final List<ProjectTaskListItemData> tasks;
  final String type;
  final Future<void> Function() onRefreshRequested;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return ProjectTaskCardAction(
          task: tasks[index],
          type: type,
          onRefreshRequested: onRefreshRequested,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemCount: tasks.length,
    );
  }
}

String _searchTaskLabel(ProjectTaskListItemData task) {
  if (task.code.isEmpty || task.code == '-') return task.title;
  return '${task.code} - ${task.title}';
}

Color _avatarColor(String value) {
  const colors = [
    ProjectTaskListPage._purple,
    ProjectTaskListPage._green,
    ProjectTaskListPage._magenta,
  ];
  if (value.isEmpty) return colors.first;

  return colors[value.codeUnits.fold<int>(0, (sum, code) => sum + code) %
      colors.length];
}

String _taskTitle(ProjectTask task) {
  if (task.title.isNotEmpty) return task.title;
  if (task.description != null && task.description!.isNotEmpty) {
    return task.description!;
  }
  return '-';
}

String _assigneeName(ProjectTask task, {required bool isQc}) {
  final name = task.assignee?.name.trim();
  if (name != null && name.isNotEmpty) return name;
  if (isQc) return 'Unassigned';
  if (task.assignees.isNotEmpty &&
      task.assignees.first.name.trim().isNotEmpty) {
    return task.assignees.first.name.trim();
  }
  return 'Unassigned';
}

extension on ProjectTaskListItemData {
  bool get hasBackendIdentity => projectId.isNotEmpty && id.isNotEmpty;
}

class ProjectTaskCardAction extends ConsumerWidget {
  const ProjectTaskCardAction({
    required this.task,
    required this.type,
    required this.onRefreshRequested,
    this.openSubTaskDirectly = false,
    super.key,
  });

  final ProjectTaskListItemData task;
  final String type;
  final Future<void> Function() onRefreshRequested;
  final bool openSubTaskDirectly;

  static const _taskProjectMenuOptions = [
    _SubTaskCardMenu.subTask,
    _SubTaskCardMenu.assignee,
    _SubTaskCardMenu.detail,
  ];

  static const _taskBreakdownMenuOptions = [_SubTaskCardMenu.detail];

  static const _qualityProjectMenuOptions = [
    _SubTaskCardMenu.assignee,
    _SubTaskCardMenu.claimQc,
    _SubTaskCardMenu.detail,
  ];

  static const _onlineOnlyMenuOptions = {
    _SubTaskCardMenu.assignee,
    _SubTaskCardMenu.claimQc,
  };

  Future<void> _showActionMenu(BuildContext context, WidgetRef ref) async {
    final baseMenuOptions = switch (type) {
      ProjectTaskListPage.qualityProjectTitle => _qualityProjectMenuOptions,
      _ when task.canBreakdown => _taskBreakdownMenuOptions,
      _ => _taskProjectMenuOptions,
    };
    final isOffline =
        ref.read(connectivityStateProvider).valueOrNull?.isOffline ?? false;
    final canShowAssignee = type == ProjectTaskListPage.qualityProjectTitle
        ? task.canClaim
        : task.canAssign;
    final menuOptions = baseMenuOptions
        .where(
          (option) =>
              (option != _SubTaskCardMenu.subTask || task.hasChild) &&
              (option != _SubTaskCardMenu.assignee || canShowAssignee) &&
              (option != _SubTaskCardMenu.claimQc || task.canClaim) &&
              (!isOffline || !_onlineOnlyMenuOptions.contains(option)),
        )
        .toList(growable: false);

    if (menuOptions.isEmpty) return;

    final selectedAction = menuOptions.length == 1
        ? menuOptions.single
        : await SelectionBottomSheet.show<_SubTaskCardMenu>(
            context,
            title: 'Pilih Aksi Selanjutnya',
            options: menuOptions,
            selectedOption: null,
            labelBuilder: (option) =>
                type == ProjectTaskListPage.qualityProjectTitle
                ? switch (option) {
                    _SubTaskCardMenu.assignee => 'Assign Terpilih',
                    _SubTaskCardMenu.claimQc => 'Claim',
                    _ => option.label,
                  }
                : option.label,
          );

    if (!context.mounted || selectedAction == null) return;

    switch (selectedAction) {
      case _SubTaskCardMenu.detail:
        await _openDetail(context);
      case _SubTaskCardMenu.subTask:
        await _openSubTask(context);
      case _SubTaskCardMenu.assignee:
        final isQc = type == ProjectTaskListPage.qualityProjectTitle;
        final didUpdate = await context.push<bool>(
          isQc
              ? RouteNames.projectQcAssignmentPicker
              : RouteNames.projectAssignee,
          extra: isQc
              ? ProjectQcAssignmentPickerArgs(
                  projectId: task.projectId,
                  initialTaskId: task.id,
                )
              : ProjectAssigneePickerArgs(
                  projectId: task.projectId,
                  taskId: task.id,
                ),
        );
        if (didUpdate == true && context.mounted) {
          await onRefreshRequested();
        }
      case _SubTaskCardMenu.claimQc:
        await _claimQcTask(context, ref);
    }
  }

  Future<void> _openDetail(BuildContext context) async {
    await context.push<bool>(
      type == ProjectTaskListPage.qualityProjectTitle
          ? RouteNames.projectQualityControl
          : RouteNames.projectSubTaskDetail,
      extra: task.toDetailData(),
    );
    if (context.mounted) {
      await onRefreshRequested();
    }
  }

  Future<void> _openSubTask(BuildContext context) async {
    await context.push<void>(
      RouteNames.projectSubTask,
      extra: ProjectTaskListPageArgs(
        detail: ProjectDetailData(
          projectId: task.projectId,
          projectName: task.title,
          status: '-',
          client: '-',
          period: '-',
          description: '-',
          workingDays: '-',
          taskCount: task.childCount.toString(),
        ),
        title: type,
        parentTaskId: task.id,
        parentTaskCode: task.code,
      ),
    );
    if (context.mounted) {
      await onRefreshRequested();
    }
  }

  Future<void> _claimQcTask(BuildContext context, WidgetRef ref) async {
    if (!task.hasBackendIdentity) return;

    try {
      await ref
          .read(projectRepositoryProvider)
          .claimQcTask(projectId: task.projectId, qcTaskId: task.id);
      await waitForServerRefresh();
      if (!context.mounted) return;
      ref.invalidate(projectQcTasksProvider);
      AppToast.success(context, 'QC task berhasil di-claim.');
    } catch (error) {
      if (context.mounted) {
        AppToast.error(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operationType = task.isQc
        ? SyncOperationType.qcTaskDecision
        : SyncOperationType.projectTaskDone;
    final target = task.isQc
        ? 'project:${task.projectId}:qc-task:${task.id}'
        : 'project:${task.projectId}:task:${task.id}';
    final overlay = task.hasBackendIdentity
        ? ref
              .watch(
                projectTargetOperationProvider(
                  ProjectTargetOperationQuery(
                    operationType: operationType,
                    targetResourceKey: target,
                  ),
                ),
              )
              .valueOrNull
        : null;
    final normalizedStatus = task.status.toLowerCase();
    final normalizedQcStatus = task.qcStatus.toLowerCase();
    final qcCompletedOnServer =
        task.isQc &&
        (const {
              'qc_passed',
              'qc_failed',
              'passed',
              'failed',
            }.contains(normalizedStatus) ||
            const {
              'disetujui',
              'ditolak',
              'pass',
              'fail',
            }.contains(normalizedQcStatus));
    final visibleOverlay = qcCompletedOnServer ? null : overlay;
    final effectiveStatus = switch (visibleOverlay?.state) {
      OutboxState.pending || OutboxState.retry =>
        task.isQc
            ? '${visibleOverlay?.decision == 'fail' ? 'QC gagal' : 'QC lulus'} - menunggu sinkronisasi'
            : 'Menunggu pengajuan ke QC',
      OutboxState.processing => 'Sedang menyinkronkan',
      OutboxState.failed => 'Perubahan perlu diperiksa',
      OutboxState.conflict => 'Data berubah di server',
      _ => task.status,
    };
    return Material(
      color: AppColors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: openSubTaskDirectly
            ? () => _openSubTask(context)
            : type != ProjectTaskListPage.qualityProjectTitle &&
                  !task.hasChild &&
                  !task.canBreakdown
            ? () => _openDetail(context)
            : () => _showActionMenu(context, ref),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ProjectTaskCard(
          task: task.toProjectMenuTaskData(
            type: type,
            statusOverride: effectiveStatus,
          ),
        ),
      ),
    );
  }
}

enum _SubTaskCardMenu {
  detail('Detail'),
  assignee('Assignee'),
  claimQc('Claim QC'),
  subTask('Go to sub task');

  const _SubTaskCardMenu(this.label);

  final String label;
}

class ProjectTaskListItemData {
  const ProjectTaskListItemData({
    this.id = '',
    this.projectId = '',
    this.isQc = false,
    this.childCount = 0,
    this.version = 0,
    this.canClaim = false,
    this.canBreakdown = false,
    this.canAssign = false,
    this.progress = '-',
    this.lastUpdatedDate = '-',
    this.manpowerName = '-',
    this.target = '-',
    this.note = '-',
    this.retryCount = 0,
    required this.code,
    required this.title,
    required this.assignees,
    required this.assigneeName,
    this.status = '',
    this.qcStatus = '',
  });

  final String id;
  final String projectId;
  final bool isQc;
  final int childCount;
  final int version;
  final bool canClaim;
  final bool canBreakdown;
  final bool canAssign;
  final String progress;
  final String lastUpdatedDate;
  final String manpowerName;
  final String target;
  final String note;
  final int retryCount;
  final String code;
  final String title;
  final List<ProjectTaskAssigneeData> assignees;
  final String assigneeName;
  final String status;
  final String qcStatus;

  factory ProjectTaskListItemData.fromTask(
    ProjectTask task, {
    required String fallbackProjectId,
    required bool isQc,
  }) {
    final sourceAssignees = isQc
        ? (task.assignee == null
              ? const <ProjectReference>[]
              : <ProjectReference>[task.assignee!])
        : task.assignees;
    final assignees = sourceAssignees
        .map(
          (assignee) => ProjectTaskAssigneeData(
            initials: assignee.initials,
            color: _avatarColor(assignee.id + assignee.name),
          ),
        )
        .toList(growable: false);

    return ProjectTaskListItemData(
      id: task.id,
      projectId: task.projectId.isNotEmpty ? task.projectId : fallbackProjectId,
      isQc: isQc,
      childCount: task.childCount,
      version: task.version,
      canClaim: task.canClaim,
      canBreakdown: task.canBreakdown,
      canAssign: task.canAssign,
      progress: _taskProgress(task),
      lastUpdatedDate: formatIndonesianDate(
        task.assignDate ?? task.updatedAt ?? task.createdAt,
        shortMonth: true,
      ),
      manpowerName: task.manpowerName.trim().isEmpty
          ? '-'
          : task.manpowerName.trim(),
      target: _taskTarget(task),
      retryCount: task.retryCount,
      note: task.description?.trim().isNotEmpty ?? false
          ? task.description!.trim()
          : '-',
      code: task.code.isNotEmpty ? task.code : '-',
      title: _taskTitle(task),
      assignees: assignees,
      assigneeName: _assigneeName(task, isQc: isQc),
      status: task.statusLabel,
      qcStatus: task.qcStatus,
    );
  }

  bool get hasChild => childCount > 0;

  ProjectTaskDetailData toDetailData() {
    if (hasBackendIdentity) {
      return ProjectTaskDetailData(
        projectId: projectId,
        taskId: id,
        isQc: isQc,
        canAssign: canAssign,
        version: version,
        childCount: childCount,
        code: code,
        task: title,
        creator: '-',
        createdDate: '-',
        status: '-',
        assignee: '-',
        updatedDate: '-',
        previousEvidence: const [],
        updatedEvidence: const [],
        qcApproval: '-',
        qcUpdateDate: '-',
        qcStatus: '-',
        qcNote: '-',
        qcEvidence: const [],
      );
    }

    return ProjectTaskDetailData.sample(
      code: '$code.1.1',
      task: title == 'Pekerjaan Civil' ? 'Penataan Bata Dinding' : title,
    );
  }

  ProjectMenuTaskData toProjectMenuTaskData({
    String type = ProjectTaskListPage.taskProjectTitle,
    String? statusOverride,
  }) {
    return ProjectMenuTaskData(
      code: code,
      title: title,
      assignees: assignees
          .map(
            (assignee) => ProjectMenuAssigneeData(
              initials: assignee.initials,
              color: assignee.color,
            ),
          )
          .toList(),
      assigneeName: assigneeName,
      childCount: childCount,
      status: statusOverride ?? status,
      type: type,
      progress: progress,
      lastUpdatedDate: lastUpdatedDate,
      manpowerName: manpowerName,
      target: target,
      note: note,
      retryCount: retryCount,
    );
  }

  ProjectSubTaskPickerData toSubTaskPickerData() {
    if (hasBackendIdentity) {
      return ProjectSubTaskPickerData(
        projectId: projectId,
        taskId: id,
        tasks: const [],
      );
    }

    return ProjectSubTaskPickerData.sample(firstCode: code, firstTitle: title);
  }
}

String _taskProgress(ProjectTask task) {
  final completed = task.completedVolume;
  final target = task.targetVolume > 0
      ? task.targetVolume
      : task.maxTargetVolume > 0
      ? task.maxTargetVolume
      : task.volumeBoq;
  final unit = task.uom?.code.trim() ?? '';
  final suffix = unit.isEmpty ? '' : ' $unit';
  return '${_formatVolume(completed)}/${_formatVolume(target)}$suffix';
}

String _taskTarget(ProjectTask task) {
  final unit = _compactTaskUnit(task.uom);
  final suffix = unit.isEmpty ? '' : ' $unit';
  return '${_formatVolume(task.targetVolume)}$suffix';
}

String _compactTaskUnit(ProjectTaskUom? uom) {
  final rawUnit = uom?.code.trim().isNotEmpty ?? false
      ? uom!.code.trim()
      : uom?.name.trim() ?? '';
  return switch (rawUnit.toLowerCase().replaceAll(' ', '')) {
    'm2' || 'meterpersegi' => 'm²',
    'm3' || 'meterkubik' => 'm³',
    _ => rawUnit,
  };
}

String _formatVolume(double value) {
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(4)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

class ProjectTaskListPageArgs {
  const ProjectTaskListPageArgs({
    required this.detail,
    this.title = ProjectTaskListPage.taskProjectTitle,
    this.parentTaskId = '',
    this.parentTaskCode = '',
    this.initialTabIndex = 0,
  });

  final ProjectDetailData detail;
  final String title;
  final String parentTaskId;
  final String parentTaskCode;
  final int initialTabIndex;
}

class ProjectTaskAssigneeData {
  const ProjectTaskAssigneeData({required this.initials, required this.color});

  final String initials;
  final Color color;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/modules/meeting/data/models/meeting_models.dart';
import 'package:curva_mobile/modules/meeting/meeting_providers.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/detail/task_meeting_detail_page.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/task/meeting_assignee_picker_page.dart';
import 'package:curva_mobile/modules/meeting/presentation/widgets/meeting_task_card.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/app_underline_tabs.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/full_page_search_bottom_sheet.dart';
import 'package:curva_mobile/shared/widgets/selection_bottom_sheet.dart';

class MeetingTaskListPage extends ConsumerStatefulWidget {
  const MeetingTaskListPage({required this.args, super.key});

  final MeetingTaskListPageArgs args;

  static const taskMeetingTitle = 'Task Meeting';
  static const qualityMeetingTitle = 'Quality Meeting';
  static const _backgroundColor = AppColors.cardBackground;

  @override
  ConsumerState<MeetingTaskListPage> createState() =>
      _MeetingTaskListPageState();
}

class _MeetingTaskListPageState extends ConsumerState<MeetingTaskListPage> {
  late var _activeTab =
      _MeetingTaskListTab.values[widget.args.initialTabIndex.clamp(
        0,
        _MeetingTaskListTab.values.length - 1,
      )];
  var _taskCount = 0;

  MeetingTasksQuery get _query => MeetingTasksQuery(
    meetingId: widget.args.meetingId,
    isQuality: widget.args.isQualityMeeting,
    tab: _activeTab.apiValue,
  );

  void _onTaskCountChanged(int count) {
    if (_taskCount == count) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _taskCount != count) setState(() => _taskCount = count);
    });
  }

  Future<void> _showSearch() async {
    if (widget.args.meetingId.isEmpty) {
      AppToast.info(context, 'Data task belum tersedia.');
      return;
    }

    try {
      final tasks = await ref.read(meetingTasksProvider(_query).future);
      if (!mounted) return;
      if (tasks.isEmpty) {
        AppToast.info(context, 'Data task belum tersedia.');
        return;
      }

      final selectedTask = await FullPageSearchBottomSheet.show<MeetingTask>(
        context,
        title: 'Pencarian',
        options: tasks,
        labelBuilder: _searchTaskLabel,
        searchTextBuilder: (task) => '${task.code} ${task.title}',
      );
      if (!mounted || selectedTask == null) return;

      final didUpdate = await showMeetingTaskActionMenu(
        context,
        widget.args,
        selectedTask,
      );
      if (didUpdate && mounted) {
        await ref
            .refresh(meetingTasksProvider(_query).future)
            .then<void>((_) {});
      }
    } catch (error) {
      if (mounted) AppToast.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ColoredBox(
          color: MeetingTaskListPage._backgroundColor,
          child: Column(
            children: [
              Container(
                color: AppColors.white,
                child: Column(
                  children: [
                    AppHeader(
                      title: widget.args.title,
                      onBackPressed: () => context.pop(),
                      actions: [
                        AppHeaderAction(
                          icon: Icons.search,
                          tooltip: 'Cari task',
                          onPressed: _showSearch,
                        ),
                      ],
                    ),
                    AppUnderlineTabs(
                      items: [
                        AppUnderlineTabItem(
                          label: 'Task ($_taskCount)',
                          width: 118,
                        ),
                        const AppUnderlineTabItem(label: 'History', width: 104),
                      ],
                      selectedIndex: _MeetingTaskListTab.values.indexOf(
                        _activeTab,
                      ),
                      onTabSelected: (index) => setState(
                        () => _activeTab = _MeetingTaskListTab.values[index],
                      ),
                      fontFamily: AppFonts.inter,
                      horizontalPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      inactiveColor: AppColors.muted,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _MeetingTaskTabView(
                  args: widget.args,
                  tab: _activeTab,
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

enum _MeetingTaskListTab {
  task('Task', 'open'),
  history('History', 'history');

  const _MeetingTaskListTab(this.label, this.apiValue);

  final String label;
  final String apiValue;
}

class _MeetingTaskTabView extends ConsumerWidget {
  const _MeetingTaskTabView({
    required this.args,
    required this.tab,
    required this.onTaskCountChanged,
  });

  final MeetingTaskListPageArgs args;
  final _MeetingTaskListTab tab;
  final ValueChanged<int> onTaskCountChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (args.meetingId.isEmpty) {
      if (tab == _MeetingTaskListTab.task) onTaskCountChanged(0);
      return const EmptyView(
        title: 'Belum ada tugas diberikan',
        message: 'Belum ada tugas diberikan. Silakan\nhubungi Admin.',
      );
    }

    final query = MeetingTasksQuery(
      meetingId: args.meetingId,
      isQuality: args.isQualityMeeting,
      tab: tab.apiValue,
    );
    final tasksState = ref.watch(meetingTasksProvider(query));

    return tasksState.when(
      loading: () => const AppSkeletonListView(
        variant: AppSkeletonListVariant.detailed,
        itemCount: 4,
        showSectionHeader: false,
        padding: EdgeInsets.all(AppSpacing.md),
      ),
      error: (error, _) => NetworkAwareErrorView(
        error: error,
        message: error.toString(),
        onRetry: () => ref.invalidate(meetingTasksProvider(query)),
      ),
      data: (tasks) {
        if (tab == _MeetingTaskListTab.task) {
          onTaskCountChanged(tasks.length);
        }
        if (tasks.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(meetingTasksProvider(query).future),
            child: const _MeetingTaskEmptyState(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(meetingTasksProvider(query).future),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) => MeetingTaskCard(
              task: _toCardData(tasks[index], args.title),
              onTap: () async {
                final didUpdate = await showMeetingTaskActionMenu(
                  context,
                  args,
                  tasks[index],
                );
                if (didUpdate && context.mounted) {
                  await ref
                      .refresh(meetingTasksProvider(query).future)
                      .then<void>((_) {});
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _MeetingTaskEmptyState extends StatelessWidget {
  const _MeetingTaskEmptyState();

  @override
  Widget build(BuildContext context) {
    return const EmptyView(
      title: 'Belum ada tugas diberikan',
      message: 'Belum ada tugas diberikan. Silakan\nhubungi Admin.',
    );
  }
}

enum _MeetingTaskMenu {
  assignee('Assignee'),
  detail('Detail');

  const _MeetingTaskMenu(this.label);

  final String label;
}

Future<bool> showMeetingTaskActionMenu(
  BuildContext context,
  MeetingTaskListPageArgs args,
  MeetingTask task,
) async {
  if (args.isQualityMeeting) {
    final didUpdate = await context.push<bool>(
      RouteNames.meetingTaskAction,
      extra: MeetingTaskActionData.fromModel(
        task,
        meetingId: args.meetingId,
        isQualityMeeting: true,
      ),
    );
    return didUpdate == true;
  }

  final selectedAction = await SelectionBottomSheet.show<_MeetingTaskMenu>(
    context,
    title: 'Pilih Aksi Selanjutnya',
    options: [
      if (task.canAssign) _MeetingTaskMenu.assignee,
      _MeetingTaskMenu.detail,
    ],
    selectedOption: null,
    labelBuilder: (option) => option.label,
  );

  if (!context.mounted || selectedAction == null) return false;

  switch (selectedAction) {
    case _MeetingTaskMenu.assignee:
      final didUpdate = await context.push<bool>(
        RouteNames.meetingAssignee,
        extra: MeetingAssigneePickerArgs(
          meetingId: args.meetingId,
          taskId: task.id,
        ),
      );
      return didUpdate == true;
    case _MeetingTaskMenu.detail:
      final didUpdate = await context.push<bool>(
        RouteNames.meetingTaskAction,
        extra: MeetingTaskActionData.fromModel(
          task,
          meetingId: args.meetingId,
          isQualityMeeting: args.isQualityMeeting,
        ),
      );
      return didUpdate == true;
  }
}

String _searchTaskLabel(MeetingTask task) {
  if (task.code.isEmpty || task.code == '-') return task.title;
  return '${task.code} - ${task.title}';
}

MeetingMenuTaskData _toCardData(MeetingTask task, String type) {
  final assignee = task.assignee;
  return MeetingMenuTaskData(
    code: task.code.isEmpty ? '-' : task.code,
    title: task.title.isEmpty ? '-' : task.title,
    assignees: assignee == null
        ? const []
        : [
            MeetingMenuAssigneeData(
              initials: assignee.initials,
              color:
                  _colorFromHex(assignee.colorHex) ??
                  _assigneeColor(assignee.id + assignee.name),
            ),
          ],
    assigneeName: assignee?.name ?? 'Unassigned',
    processCount: task.retryCount,
    status: task.statusLabel.isEmpty
        ? task.status.replaceAll('_', ' ')
        : task.statusLabel,
    taskInfo: 'Dalam Proses',
    type: type,
  );
}

Color? _colorFromHex(String value) {
  final hex = value.replaceFirst('#', '');
  if (hex.length != 6) return null;
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? null : AppColors.fromHex(value);
}

Color _assigneeColor(String value) {
  const colors = [
    AppColors.assigneePurple,
    AppColors.assigneeGreen,
    AppColors.assigneeMagenta,
  ];
  if (value.isEmpty) return colors.first;
  return colors[value.codeUnits.fold<int>(0, (sum, code) => sum + code) %
      colors.length];
}

class MeetingTaskListPageArgs {
  const MeetingTaskListPageArgs({
    required this.meetingId,
    required this.title,
    required this.isQualityMeeting,
    this.initialTabIndex = 0,
  });

  final String meetingId;
  final String title;
  final bool isQualityMeeting;
  final int initialTabIndex;

  factory MeetingTaskListPageArgs.fallback() {
    return const MeetingTaskListPageArgs(
      meetingId: '',
      title: MeetingTaskListPage.taskMeetingTitle,
      isQualityMeeting: false,
    );
  }
}

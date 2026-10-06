import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/modules/meeting/data/models/meeting_models.dart';
import 'package:curva_mobile/modules/meeting/meeting_providers.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/task/meeting_task_list_page.dart';
import 'package:curva_mobile/modules/meeting/presentation/widgets/meeting_task_card.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_underline_tabs.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';

class MeetingOverviewPage extends ConsumerStatefulWidget {
  const MeetingOverviewPage({required this.data, super.key});

  final MeetingOverviewData data;

  static const _summaryBackground = AppColors.tabBackground;

  @override
  ConsumerState<MeetingOverviewPage> createState() =>
      _MeetingOverviewPageState();
}

class _MeetingOverviewPageState extends ConsumerState<MeetingOverviewPage> {
  _MeetingOverviewTab _activeTab = _MeetingOverviewTab.task;

  Future<void> _refreshOverview(MeetingOverviewData data) async {
    if (data.meetingId.isEmpty) return;

    await Future.wait<void>([
      for (final tab in _MeetingOverviewTab.values)
        ref
            .refresh(
              meetingOverviewTasksProvider(
                MeetingTasksQuery(
                  meetingId: data.meetingId,
                  isQuality: data.isQualityMeeting,
                  tab: tab.apiValue,
                ),
              ).future,
            )
            .then<void>((_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final taskQuery = MeetingTasksQuery(
      meetingId: data.meetingId,
      isQuality: data.isQualityMeeting,
      tab: _MeetingOverviewTab.task.apiValue,
    );
    final activeQuery = MeetingTasksQuery(
      meetingId: data.meetingId,
      isQuality: data.isQualityMeeting,
      tab: _activeTab.apiValue,
    );
    final taskState = data.meetingId.isEmpty
        ? null
        : ref.watch(meetingOverviewTasksProvider(taskQuery));
    final activeState = _activeTab == _MeetingOverviewTab.task
        ? taskState
        : ref.watch(meetingOverviewTasksProvider(activeQuery));
    final taskResult = taskState?.valueOrNull;
    final doneCount = taskResult?.doneCount ?? 0;
    final processCount = taskResult?.inProgressCount ?? 0;
    final taskCount = taskResult?.tasks.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ColoredBox(
          color: AppColors.cardBackground,
          child: Column(
            children: [
              AppHeader(title: data.title, onBackPressed: () => context.pop()),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _refreshOverview(data),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      ColoredBox(
                        color: AppColors.white,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                16,
                              ),
                              child: _SummaryGrid(
                                processCount: processCount,
                                doneCount: doneCount,
                              ),
                            ),
                            _MeetingOverviewTabs(
                              activeTab: _activeTab,
                              taskCount: taskCount,
                              onTabSelected: (tab) =>
                                  setState(() => _activeTab = tab),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (activeState == null)
                        const EmptyView(message: 'Data tugas belum tersedia.')
                      else
                        activeState.when(
                          loading: () => const SizedBox(
                            height: 180,
                            child: AppSkeletonSectionList(),
                          ),
                          error: (error, _) => SizedBox(
                            height: 180,
                            child: NetworkAwareErrorView(
                              error: error,
                              message: error.toString(),
                              onRetry: () => ref.invalidate(
                                meetingOverviewTasksProvider(activeQuery),
                              ),
                            ),
                          ),
                          data: (result) => result.tasks.isEmpty
                              ? const EmptyView(
                                  message: 'Data tugas belum tersedia.',
                                )
                              : _TaskCards(
                                  tasks: result.tasks,
                                  data: data,
                                  onRefreshRequested: () =>
                                      _refreshOverview(data),
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

enum _MeetingOverviewTab {
  task('Task', 'open', 118),
  history('History', 'history', 104);

  const _MeetingOverviewTab(this.label, this.apiValue, this.width);

  final String label;
  final String apiValue;
  final double width;
}

class _MeetingOverviewTabs extends StatelessWidget {
  const _MeetingOverviewTabs({
    required this.activeTab,
    required this.taskCount,
    required this.onTabSelected,
  });

  final _MeetingOverviewTab activeTab;
  final int taskCount;
  final ValueChanged<_MeetingOverviewTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return AppUnderlineTabs(
      items: [
        for (final tab in _MeetingOverviewTab.values)
          AppUnderlineTabItem(
            label: tab == _MeetingOverviewTab.task
                ? '${tab.label} ($taskCount)'
                : tab.label,
            width: tab.width,
          ),
      ],
      selectedIndex: _MeetingOverviewTab.values.indexOf(activeTab),
      onTabSelected: (index) =>
          onTabSelected(_MeetingOverviewTab.values[index]),
      fontFamily: AppFonts.inter,
      horizontalPadding: const EdgeInsets.symmetric(horizontal: 16),
      inactiveColor: AppColors.muted,
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.processCount, required this.doneCount});

  final int processCount;
  final int doneCount;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      primary: false,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.72,
      ),
      children: [
        _SummaryCard(label: 'Proses', value: processCount),
        _SummaryCard(label: 'Done', value: doneCount),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MeetingOverviewPage._summaryBackground,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontFamily: AppFonts.inter,
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            value.toString(),
            style: const TextStyle(
              color: AppColors.dashboardTeal,
              fontFamily: AppFonts.inter,
              fontSize: 36,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCards extends StatelessWidget {
  const _TaskCards({
    required this.tasks,
    required this.data,
    required this.onRefreshRequested,
  });

  final List<MeetingTask> tasks;
  final MeetingOverviewData data;
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
              child: MeetingTaskCard(
                task: _toCardData(tasks[index], data.title),
                onTap: () async {
                  final didUpdate = await showMeetingTaskActionMenu(
                    context,
                    MeetingTaskListPageArgs(
                      meetingId: data.meetingId,
                      title: data.title,
                      isQualityMeeting: data.isQualityMeeting,
                    ),
                    tasks[index],
                  );
                  if (didUpdate && context.mounted) {
                    await onRefreshRequested();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class MeetingOverviewData {
  const MeetingOverviewData({
    required this.meetingId,
    required this.title,
    required this.isQualityMeeting,
  });

  final String meetingId;
  final String title;
  final bool isQualityMeeting;

  factory MeetingOverviewData.fallback({String title = 'Task Meeting'}) {
    return MeetingOverviewData(
      meetingId: '',
      title: title,
      isQualityMeeting: title == 'Quality Meeting',
    );
  }
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_underline_tabs.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_quality_review_tab.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_quality_review_history_tab.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_task_detail_page.dart';

class ProjectQualityReviewPage extends ConsumerStatefulWidget {
  const ProjectQualityReviewPage({required this.detail, super.key});

  final ProjectTaskDetailData detail;

  @override
  ConsumerState<ProjectQualityReviewPage> createState() =>
      _ProjectQualityReviewPageState();
}

class _ProjectQualityReviewPageState
    extends ConsumerState<ProjectQualityReviewPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final assignee = widget.detail.assignee.trim();
    final historyPath =
        '${widget.detail.projectId}/qc-tasks/${widget.detail.taskId}/history';
    final historyRead = ref.watch(projectHistoryReadProvider(historyPath));
    final hasUnreadHistory =
        !historyRead &&
        widget.detail.projectId.isNotEmpty &&
        widget.detail.taskId.isNotEmpty &&
        (ref
                .watch(
                  projectQcHistoryHasUnreadProvider((
                    projectId: widget.detail.projectId,
                    qcTaskId: widget.detail.taskId,
                  )),
                )
                .valueOrNull ??
            false);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: assignee.isEmpty || assignee == '-'
                  ? 'Quality Project'
                  : assignee,
              onBackPressed: () => context.pop(),
            ),
            AppUnderlineTabs(
              horizontalPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              items: [
                const AppUnderlineTabItem(label: 'QC Review'),
                AppUnderlineTabItem(
                  label: 'History',
                  showIndicatorDot: hasUnreadHistory,
                ),
              ],
              selectedIndex: _selectedTab,
              onTabSelected: (index) {
                if (index == 1) {
                  ref
                          .read(
                            projectHistoryReadProvider(historyPath).notifier,
                          )
                          .state =
                      true;
                }
                FocusScope.of(context).unfocus();
                setState(() => _selectedTab = index);
              },
              expandItems: true,
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  ProjectQualityReviewTab(detail: widget.detail),
                  if (_selectedTab == 1)
                    ProjectQualityReviewHistoryTab(
                      manpowerName: widget.detail.assignee,
                      projectId: widget.detail.projectId,
                      qcTaskId: widget.detail.taskId,
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

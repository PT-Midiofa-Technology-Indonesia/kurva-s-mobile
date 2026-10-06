import 'package:flutter/material.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/modules/project/presentation/controllers/project_manpower_report_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/modules/project/data/project_repository.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/app_underline_tabs.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_manpower_report_history_tab.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_manpower_daily_report_tab.dart';

class ProjectManpowerReportArgs {
  const ProjectManpowerReportArgs({
    required this.projectId,
    required this.taskId,
    required this.manpowerName,
    this.canSubmit = true,
  });

  final String projectId;
  final String taskId;
  final String manpowerName;
  final bool canSubmit;
}

class ProjectManpowerReportPage extends ConsumerStatefulWidget {
  const ProjectManpowerReportPage({
    required this.manpowerName,
    this.projectId = '',
    this.taskId = '',
    this.canSubmit = true,
    super.key,
  });

  final String manpowerName;
  final String projectId;
  final String taskId;
  final bool canSubmit;

  @override
  ConsumerState<ProjectManpowerReportPage> createState() =>
      _ProjectManpowerReportPageState();
}

class _ProjectManpowerReportPageState
    extends ConsumerState<ProjectManpowerReportPage> {
  int _selectedTab = 0;

  Future<void> _submitDailyReport({
    required double completedVolume,
    required String note,
    required List<ProjectFileUpload> files,
  }) async {
    try {
      final queued = await ref
          .read(
            projectManpowerReportControllerProvider(
              ProjectTaskQuery(
                projectId: widget.projectId,
                taskId: widget.taskId,
              ),
            ),
          )
          .submit(completedVolume: completedVolume, note: note, files: files);
      if (!mounted) return;
      AppToast.success(
        context,
        queued
            ? 'Laporan tersimpan dan akan disinkronkan otomatis.'
            : 'Laporan berhasil diajukan ke QC.',
      );
      context.pop(true);
    } catch (error) {
      if (mounted) AppToast.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
      projectManpowerReportControllerProvider(
        ProjectTaskQuery(projectId: widget.projectId, taskId: widget.taskId),
      ),
    );
    final overlay = ref
        .watch(
          projectTargetOperationProvider(
            ProjectTargetOperationQuery(
              operationType: SyncOperationType.projectTaskDone,
              targetResourceKey:
                  'project:${widget.projectId}:task:${widget.taskId}',
            ),
          ),
        )
        .valueOrNull;
    final hasPending = overlay != null;
    final historyPath = '${widget.projectId}/tasks/${widget.taskId}/history';
    final historyRead = ref.watch(projectHistoryReadProvider(historyPath));
    final hasUnreadHistory =
        !historyRead &&
        widget.projectId.isNotEmpty &&
        widget.taskId.isNotEmpty &&
        (ref
                .watch(
                  projectManpowerHistoryHasUnreadProvider((
                    projectId: widget.projectId,
                    manpowerTaskId: widget.taskId,
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
              title: widget.manpowerName,
              onBackPressed: () => context.pop(),
            ),
            AppUnderlineTabs(
              items: [
                const AppUnderlineTabItem(label: 'Laporan Harian'),
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
              horizontalPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              expandItems: true,
            ),
            if (hasPending)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  overlay.isActive
                      ? 'Laporan menunggu sinkronisasi.'
                      : (overlay.lastErrorMessage ??
                            'Laporan perlu diperiksa sebelum dikirim ulang.'),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  ProjectManpowerDailyReportTab(
                    onSubmit:
                        widget.canSubmit &&
                            widget.projectId.isNotEmpty &&
                            widget.taskId.isNotEmpty
                        ? _submitDailyReport
                        : null,
                    canSubmit: widget.canSubmit && !hasPending,
                  ),
                  if (_selectedTab == 1)
                    ProjectManpowerReportHistoryTab(
                      manpowerName: widget.manpowerName,
                      projectId: widget.projectId,
                      manpowerTaskId: widget.taskId,
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

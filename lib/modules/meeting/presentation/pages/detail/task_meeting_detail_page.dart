import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/modules/meeting/data/models/meeting_models.dart';
import 'package:curva_mobile/modules/meeting/meeting_providers.dart';
import 'package:curva_mobile/modules/meeting/presentation/controllers/meeting_action_controllers.dart';
import 'package:curva_mobile/shared/forms/form_submit_result.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';
import 'package:curva_mobile/shared/widgets/app_button.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/upload_image_list.dart';

class TaskMeetingDetailPage extends ConsumerStatefulWidget {
  const TaskMeetingDetailPage({required this.data, super.key});

  final MeetingTaskActionData data;

  @override
  ConsumerState<TaskMeetingDetailPage> createState() =>
      _TaskMeetingDetailPageState();
}

class _TaskMeetingDetailPageState extends ConsumerState<TaskMeetingDetailPage> {
  final _evidenceKey = GlobalKey();

  Future<void> _pickEvidence() async {
    try {
      await ref
          .read(meetingTaskDoneControllerProvider(_query))
          .pickEvidence(context);
    } catch (error) {
      if (mounted) AppToast.error(context, error);
    }
  }

  Future<void> _submit() async {
    try {
      final result = await ref
          .read(meetingTaskDoneControllerProvider(_query))
          .submit();
      if (!mounted) return;
      switch (result) {
        case FormSubmitSuccess():
          AppToast.success(context, result.message);
          context.pop(true);
        case FormSubmitInvalid(:final message):
          if (message != null) AppToast.warning(context, message);
          final evidenceContext = _evidenceKey.currentContext;
          if (evidenceContext != null && evidenceContext.mounted) {
            await Scrollable.ensureVisible(evidenceContext);
          }
        case FormSubmitIgnored():
      }
    } catch (error) {
      if (mounted) AppToast.error(context, error);
    }
  }

  MeetingTaskQuery get _query => MeetingTaskQuery(
    meetingId: widget.data.meetingId,
    taskId: widget.data.taskId,
    isQuality: false,
  );

  @override
  Widget build(BuildContext context) {
    final query = _query;
    final actionController = ref.watch(
      meetingTaskDoneControllerProvider(query),
    );
    final detailState = widget.data.canLoadFromApi
        ? ref.watch(meetingTaskDetailProvider(query))
        : null;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Task Meeting',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: detailState == null
                  ? _content(widget.data, actionController)
                  : detailState.when(
                      loading: () => const AppSkeletonDetailView(),
                      error: (error, _) => NetworkAwareErrorView(
                        error: error,
                        message: error.toString(),
                        onRetry: () =>
                            ref.invalidate(meetingTaskDetailProvider(query)),
                      ),
                      data: (task) => RefreshIndicator(
                        onRefresh: () => ref.refresh(
                          meetingTaskDetailProvider(query).future,
                        ),
                        child: _content(
                          MeetingTaskActionData.fromModel(
                            task,
                            meetingId: widget.data.meetingId,
                            isQualityMeeting: false,
                          ),
                          actionController,
                        ),
                      ),
                    ),
            ),
            if ((detailState?.valueOrNull?.canSubmit ?? widget.data.canSubmit))
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: AppColors.white,
                  child: AppButton(
                    label: actionController.isSubmitting
                        ? 'Mengajukan...'
                        : 'Ajukan ke QC',
                    isLoading: actionController.isSubmitting,
                    backgroundColor: AppColors.dashboardTeal,
                    textStyle: const TextStyle(
                      color: AppColors.white,
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    onPressed: actionController.isSubmitting ? null : _submit,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    MeetingTaskActionData data,
    MeetingTaskDoneController controller,
  ) {
    final isReadOnly = !data.canSubmit;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        MeetingTaskInfoSection(data: data),
        KeyedSubtree(
          key: _evidenceKey,
          child: MeetingActionSection(
            hasBorder: data.showQcDetails,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MeetingActionSectionTitle(
                  isReadOnly ? 'Bukti' : 'Unggah bukti',
                  required: !isReadOnly,
                ),
                const SizedBox(height: AppSpacing.md),
                UploadImageList(
                  items: isReadOnly
                      ? data.previousEvidence
                      : controller.evidence
                            .map(
                              (file) => UploadImageItem(
                                name: file.name,
                                path: file.path,
                                size: file.size,
                              ),
                            )
                            .toList(growable: false),
                  showAddButton: !isReadOnly,
                  onAddPressed: isReadOnly ? null : _pickEvidence,
                  onRemovePressed: isReadOnly
                      ? null
                      : controller.removeEvidenceAt,
                ),
                if (!isReadOnly && controller.evidenceError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    controller.evidenceError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (data.showQcDetails)
          MeetingActionSection(
            hasBorder: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MeetingActionSectionTitle('Catatan QC'),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  data.qcNote?.trim().isNotEmpty == true ? data.qcNote! : '-',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    height: 1.43,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const MeetingActionSectionTitle('Bukti QC'),
                const SizedBox(height: AppSpacing.md),
                UploadImageList(
                  items: data.qcEvidence,
                  showEmptyMessage: false,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class MeetingTaskInfoSection extends StatelessWidget {
  const MeetingTaskInfoSection({required this.data, super.key});

  final MeetingTaskActionData data;

  @override
  Widget build(BuildContext context) {
    return MeetingActionSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MeetingActionDetailField(label: 'Kode', value: data.code),
          const SizedBox(height: 20),
          MeetingActionDetailField(label: 'Tugas', value: data.task),
          const SizedBox(height: 20),
          MeetingActionDetailField(label: 'Project', value: data.project),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MeetingActionDetailField(
                  label: 'Dibuat oleh',
                  value: data.creator,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: MeetingActionDetailField(
                  label: 'Tanggal',
                  value: data.createdDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          MeetingActionDetailField(
            label: 'Status',
            value: data.status,
            valueColor: data.isQualityMeeting
                ? AppColors.dashboardTeal
                : AppColors.orange,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MeetingActionDetailField(
                  label: 'Penerima tugas',
                  value: data.assignee,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: MeetingActionDetailField(
                  label: 'Update',
                  value: data.updatedDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MeetingActionSection extends StatelessWidget {
  const MeetingActionSection({
    required this.child,
    this.hasBorder = true,
    super.key,
  });

  final Widget child;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: hasBorder
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: child,
    );
  }
}

class MeetingActionDetailField extends StatelessWidget {
  const MeetingActionDetailField({
    required this.label,
    required this.value,
    this.valueColor = AppColors.muted,
    super.key,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: AppFonts.inter,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontFamily: AppFonts.inter,
            fontSize: 14,
            height: 1.43,
          ),
        ),
      ],
    );
  }
}

class MeetingActionSectionTitle extends StatelessWidget {
  const MeetingActionSectionTitle(
    this.title, {
    this.required = false,
    super.key,
  });

  final String title;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: AppColors.ink,
          fontFamily: AppFonts.inter,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

class MeetingTaskActionData {
  const MeetingTaskActionData({
    required this.meetingId,
    required this.taskId,
    required this.isQualityMeeting,
    required this.code,
    required this.task,
    required this.project,
    required this.creator,
    required this.createdDate,
    required this.status,
    required this.assignee,
    required this.updatedDate,
    required this.previousEvidence,
    this.rawStatus = '',
    this.qcNote,
    this.decision,
    this.canSubmit = true,
    this.qcEvidence = const [],
  });

  final String meetingId;
  final String taskId;
  final bool isQualityMeeting;
  final String code;
  final String task;
  final String project;
  final String creator;
  final String createdDate;
  final String status;
  final String assignee;
  final String updatedDate;
  final List<UploadImageItem> previousEvidence;
  final String rawStatus;
  final String? qcNote;
  final String? decision;
  final bool canSubmit;
  final List<UploadImageItem> qcEvidence;

  bool get canLoadFromApi => meetingId.isNotEmpty && taskId.isNotEmpty;

  bool get showQcDetails {
    if (qcNote?.trim().isNotEmpty == true || qcEvidence.isNotEmpty) return true;

    return const {
      'done',
      'reopen',
      'reopened',
      'qc_passed',
      'qc_failed',
    }.contains(rawStatus.trim().toLowerCase());
  }

  factory MeetingTaskActionData.fromModel(
    MeetingTask task, {
    required String meetingId,
    required bool isQualityMeeting,
  }) {
    return MeetingTaskActionData(
      meetingId: meetingId.isEmpty ? task.meetingId : meetingId,
      taskId: task.id,
      isQualityMeeting: isQualityMeeting,
      code: task.code.isEmpty ? '-' : task.code,
      task: task.title,
      project: task.projectName.isEmpty ? '-' : task.projectName,
      creator: task.creator?.name ?? '-',
      createdDate: formatIndonesianDate(task.createdAt, shortMonth: true),
      status: task.statusLabel.isNotEmpty
          ? task.statusLabel
          : (task.status.isEmpty ? '-' : task.status.replaceAll('_', ' ')),
      assignee:
          task.assignee?.name ??
          (task.assignees.isEmpty
              ? 'Unassigned'
              : task.assignees.map((item) => item.name).join(', ')),
      updatedDate: formatIndonesianDate(task.updatedAt, shortMonth: true),
      rawStatus: task.status,
      previousEvidence: task.previousEvidence
          .map(
            (file) => UploadImageItem(
              name: file.name,
              path: file.path,
              size: file.size,
            ),
          )
          .toList(growable: false),
      qcNote: isQualityMeeting ? task.qcNote : task.downstreamQc?.qcNote,
      decision: task.decision,
      canSubmit: task.canSubmit,
      qcEvidence:
          (isQualityMeeting
                  ? task.qcEvidence
                  : task.downstreamQc?.evidence ?? const <MeetingAttachment>[])
              .map(
                (file) => UploadImageItem(
                  name: file.name,
                  path: file.path,
                  size: file.size,
                ),
              )
              .toList(growable: false),
    );
  }

  factory MeetingTaskActionData.fallback() {
    return const MeetingTaskActionData(
      meetingId: '',
      taskId: '',
      isQualityMeeting: false,
      code: '-',
      task: '-',
      project: '-',
      creator: '-',
      createdDate: '-',
      status: '-',
      assignee: '-',
      updatedDate: '-',
      previousEvidence: [],
      qcEvidence: [],
    );
  }
}

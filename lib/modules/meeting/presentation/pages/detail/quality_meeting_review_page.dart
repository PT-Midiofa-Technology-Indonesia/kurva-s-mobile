import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/modules/meeting/meeting_providers.dart';
import 'package:curva_mobile/modules/meeting/presentation/controllers/meeting_action_controllers.dart';
import 'package:curva_mobile/modules/meeting/presentation/pages/detail/task_meeting_detail_page.dart';
import 'package:curva_mobile/shared/forms/form_submit_result.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/input_multiline_with_border.dart';
import 'package:curva_mobile/shared/widgets/upload_image_list.dart';

class QualityMeetingReviewPage extends ConsumerStatefulWidget {
  const QualityMeetingReviewPage({required this.data, super.key});

  final MeetingTaskActionData data;

  @override
  ConsumerState<QualityMeetingReviewPage> createState() =>
      _QualityMeetingReviewPageState();
}

class _QualityMeetingReviewPageState
    extends ConsumerState<QualityMeetingReviewPage> {
  final _noteKey = GlobalKey();
  final _evidenceKey = GlobalKey();
  String? _initializedFormSignature;

  void _initializeForm(
    MeetingTaskActionData data,
    MeetingQualityDecisionController controller,
  ) {
    final signature = '${data.taskId}:${data.qcNote ?? ''}:${data.canSubmit}';
    if (_initializedFormSignature == signature) return;
    _initializedFormSignature = signature;
    controller.noteController.text = data.qcNote ?? '';
  }

  Future<void> _pickEvidence() async {
    try {
      await ref
          .read(meetingQualityDecisionControllerProvider(_query))
          .pickEvidence(context);
    } catch (error) {
      if (mounted) AppToast.error(context, error);
    }
  }

  Future<void> _submit(String decision) async {
    try {
      final result = await ref
          .read(meetingQualityDecisionControllerProvider(_query))
          .submit(decision);
      if (!mounted) return;
      switch (result) {
        case FormSubmitSuccess():
          AppToast.success(context, result.message);
          context.pop(true);
        case FormSubmitInvalid(:final message):
          if (message != null) AppToast.warning(context, message);
          final controller = ref.read(
            meetingQualityDecisionControllerProvider(_query),
          );
          final target = controller.noteError != null
              ? _noteKey.currentContext
              : _evidenceKey.currentContext;
          if (target != null && target.mounted) {
            await Scrollable.ensureVisible(target);
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
    isQuality: true,
  );

  @override
  Widget build(BuildContext context) {
    final query = _query;
    final actionController = ref.watch(
      meetingQualityDecisionControllerProvider(query),
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
              title: 'Quality Meeting',
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
                            isQualityMeeting: true,
                          ),
                          actionController,
                        ),
                      ),
                    ),
            ),
            if ((detailState?.valueOrNull?.canSubmit ?? widget.data.canSubmit))
              SafeArea(
                top: false,
                child: _QualityActions(
                  rejecting: actionController.submittingDecision == 'fail',
                  approving: actionController.submittingDecision == 'pass',
                  onReject: actionController.isSubmitting
                      ? null
                      : () => _submit('fail'),
                  onApprove: actionController.isSubmitting
                      ? null
                      : () => _submit('pass'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    MeetingTaskActionData data,
    MeetingQualityDecisionController controller,
  ) {
    _initializeForm(data, controller);
    final isReadOnly = !data.canSubmit;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        MeetingTaskInfoSection(data: data),
        MeetingActionSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MeetingActionSectionTitle('Bukti'),
              const SizedBox(height: AppSpacing.lg),
              UploadImageList(
                items: data.previousEvidence,
                emptyMessage: 'Belum ada bukti pengerjaan',
                showAddButton: false,
              ),
            ],
          ),
        ),
        MeetingActionSection(
          hasBorder: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MeetingActionSectionTitle('Catatan QC', required: !isReadOnly),
              const SizedBox(height: AppSpacing.lg),
              KeyedSubtree(
                key: _noteKey,
                child: isReadOnly
                    ? Text(
                        data.qcNote?.trim().isNotEmpty == true
                            ? data.qcNote!
                            : '-',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontFamily: AppFonts.inter,
                          fontSize: 14,
                          height: 1.43,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      )
                    : InputMultilineWithBorder(
                        controller: controller.noteController,
                        hintText: 'Masukkan deskripsi...',
                        errorText: controller.noteError,
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              MeetingActionSectionTitle(
                isReadOnly ? 'Bukti QC' : 'Unggah bukti',
                required: !isReadOnly,
              ),
              const SizedBox(height: AppSpacing.md),
              KeyedSubtree(
                key: _evidenceKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UploadImageList(
                      items: isReadOnly
                          ? data.qcEvidence
                          : controller.evidence
                                .map(
                                  (file) => UploadImageItem(
                                    name: file.name,
                                    path: file.path,
                                    size: file.size,
                                  ),
                                )
                                .toList(growable: false),
                      showEmptyMessage: false,
                      showAddButton: !isReadOnly,
                      onAddPressed: isReadOnly ? null : _pickEvidence,
                      onRemovePressed: isReadOnly
                          ? null
                          : controller.removeEvidenceAt,
                    ),
                    if (controller.evidenceError != null) ...[
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
            ],
          ),
        ),
      ],
    );
  }
}

class _QualityActions extends StatelessWidget {
  const _QualityActions({
    required this.onReject,
    required this.onApprove,
    required this.rejecting,
    required this.approving,
  });

  final VoidCallback? onReject;
  final VoidCallback? onApprove;
  final bool rejecting;
  final bool approving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.white,
      child: Row(
        children: [
          Expanded(
            child: _DecisionButton(
              label: 'Tolak',
              icon: Icons.close,
              color: AppColors.rose,
              isLoading: rejecting,
              onPressed: onReject,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _DecisionButton(
              label: 'Setujui',
              icon: Icons.check,
              color: AppColors.green,
              isLoading: approving,
              onPressed: onApprove,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null ? color.withValues(alpha: 0.55) : color,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading) ...[
                        const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        isLoading ? 'Memproses...' : label,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontFamily: AppFonts.inter,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: double.infinity,
                color: AppColors.white.withValues(alpha: 0.2),
              ),
              SizedBox(
                width: 48,
                child: Icon(icon, color: AppColors.white, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

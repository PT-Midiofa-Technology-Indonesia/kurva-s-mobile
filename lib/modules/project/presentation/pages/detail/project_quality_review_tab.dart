import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/core/offline_first_providers.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/input_multiline_with_border.dart';
import 'package:curva_mobile/shared/widgets/upload_image_list.dart';
import 'package:curva_mobile/shared/utils/upload_file_picker.dart';
import 'package:curva_mobile/modules/project/project_providers.dart';
import 'package:curva_mobile/modules/project/data/project_repository.dart';
import 'package:curva_mobile/modules/project/presentation/controllers/project_task_action_controllers.dart';
import 'package:curva_mobile/modules/project/presentation/pages/detail/project_task_detail_page.dart';

extension on ProjectTaskDetailData {
  bool get isQcCompleted {
    final normalizedQcStatus = qcStatus.toLowerCase();
    return const {'qc_passed', 'qc_failed'}.contains(statusKey) ||
        const {
          'pass',
          'fail',
          'passed',
          'failed',
        }.contains(normalizedQcStatus) ||
        normalizedQcStatus == 'disetujui' ||
        normalizedQcStatus == 'ditolak';
  }
}

class ProjectQualityReviewTab extends ConsumerStatefulWidget {
  const ProjectQualityReviewTab({required this.detail, super.key});

  final ProjectTaskDetailData detail;

  @override
  ConsumerState<ProjectQualityReviewTab> createState() =>
      _ProjectQualityReviewTabState();
}

class _ProjectQualityReviewTabState
    extends ConsumerState<ProjectQualityReviewTab> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final controller = ref.watch(
      projectQualityActionControllerProvider(detail),
    );
    final actionDetail = controller.actionDetail;
    final queuedWriteEnabled = ref
        .watch(syncPolicyProvider)
        .canQueue(SyncOperationType.qcTaskDecision);
    final isOffline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;
    final offlineQueueActive = queuedWriteEnabled && isOffline;
    final isQcOwner = actionDetail.isQcOwnedByName(
      ref.watch(currentAccountNameProvider),
    );
    // The QC detail endpoint is the source of truth for whether a decision
    // may be submitted. Ownership is only additionally required for a queued
    // offline write, where the server cannot validate it immediately.
    final canSubmitDecision =
        actionDetail.canSubmitFromApi == true &&
        (!offlineQueueActive || isQcOwner);
    final overlay = actionDetail.canLoadFromApi
        ? ref
              .watch(
                projectTargetOperationProvider(
                  ProjectTargetOperationQuery(
                    operationType: SyncOperationType.qcTaskDecision,
                    targetResourceKey:
                        'project:${actionDetail.projectId}:qc-task:${actionDetail.taskId}',
                  ),
                ),
              )
              .valueOrNull
        : null;

    return Column(
      children: [
        Expanded(
          child: detail.canLoadFromApi
              ? _QualityReviewLoader(
                  initialDetail: detail,
                  noteController: _noteController,
                  selectedEvidence: controller.selectedEvidence,
                  onAddEvidence: _pickEvidence,
                  onRemoveSelectedEvidence: _removeEvidenceAt,
                  onStatusChanged: _updateQcStatus,
                  onLoaded: controller.setLoadedDetail,
                )
              : _QualityReviewContent(
                  detail: detail,
                  noteController: _noteController,
                  selectedEvidence: controller.selectedEvidence,
                  onAddEvidence: _pickEvidence,
                  onRemoveSelectedEvidence: _removeEvidenceAt,
                  onStatusChanged: _updateQcStatus,
                ),
        ),
        if (!controller.isQcCompleted && actionDetail.canSubmitFromApi == true)
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (offlineQueueActive && !isQcOwner)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'QC task belum di-claim atau ditugaskan kepada Anda.',
                      semanticsLabel:
                          'Keputusan QC dinonaktifkan karena task belum menjadi milik Anda',
                    ),
                  ),
                _BottomActions(
                  rejecting: controller.submittingDecision == 'fail',
                  approving: controller.submittingDecision == 'pass',
                  onReject:
                      actionDetail.canLoadFromApi &&
                          canSubmitDecision &&
                          !controller.isSubmitting &&
                          !(overlay?.isActive ?? false)
                      ? () => _submitDecision(context, 'fail')
                      : null,
                  onApprove:
                      actionDetail.canLoadFromApi &&
                          canSubmitDecision &&
                          !controller.isSubmitting &&
                          !(overlay?.isActive ?? false)
                      ? () => _submitDecision(context, 'pass')
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _updateQcStatus(bool isCompleted) {
    ref
        .read(projectQualityActionControllerProvider(widget.detail))
        .setQcCompleted(isCompleted);
  }

  Future<void> _pickEvidence() async {
    final selected = await UploadFilePicker.pick(context);
    if (selected.isEmpty) return;

    final files = selected
        .where((file) => file.path != null && file.path!.isNotEmpty)
        .map((file) => ProjectFileUpload(name: file.name, path: file.path))
        .toList(growable: false);

    if (files.isEmpty) {
      if (mounted) {
        AppToast.info(context, 'File tidak dapat dibaca.');
      }
      return;
    }

    ref
        .read(projectQualityActionControllerProvider(widget.detail))
        .addEvidence(files);
  }

  void _removeEvidenceAt(int index) {
    ref
        .read(projectQualityActionControllerProvider(widget.detail))
        .removeEvidenceAt(index);
  }

  Future<void> _submitDecision(BuildContext context, String decision) async {
    final note = _noteController.text.trim();

    if (note.isEmpty) {
      AppToast.warning(context, 'Catatan QC wajib diisi.');
      return;
    }
    final controller = ref.read(
      projectQualityActionControllerProvider(widget.detail),
    );
    if (controller.selectedEvidence.isEmpty) {
      AppToast.warning(context, 'Bukti QC wajib diunggah.');
      return;
    }

    try {
      final queued = await controller.submitDecision(
        decision: decision,
        note: note,
      );
      _noteController.clear();
      if (context.mounted) {
        AppToast.success(
          context,
          queued
              ? 'Keputusan QC tersimpan dan akan disinkronkan otomatis.'
              : 'Keputusan QC berhasil dikirim.',
        );
        context.pop(true);
      }
    } catch (error) {
      if (context.mounted) {
        AppToast.error(context, error);
      }
    }
  }
}

class _QualityReviewLoader extends ConsumerWidget {
  const _QualityReviewLoader({
    required this.initialDetail,
    required this.noteController,
    required this.selectedEvidence,
    required this.onAddEvidence,
    required this.onRemoveSelectedEvidence,
    required this.onStatusChanged,
    required this.onLoaded,
  });

  final ProjectTaskDetailData initialDetail;
  final TextEditingController noteController;
  final List<ProjectFileUpload> selectedEvidence;
  final VoidCallback onAddEvidence;
  final ValueChanged<int> onRemoveSelectedEvidence;
  final ValueChanged<bool> onStatusChanged;
  final ValueChanged<ProjectTaskDetailData> onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ProjectTaskQuery(
      projectId: initialDetail.projectId,
      taskId: initialDetail.taskId,
    );
    final detailState = ref.watch(projectQcTaskDetailProvider(query));

    return detailState.when(
      loading: () => const AppSkeletonDetailView(),
      error: (error, _) => NetworkAwareErrorView(
        error: error,
        cacheFeatureKey: 'projectCacheRead',
        message: error.toString(),
        onRetry: () => ref.invalidate(projectQcTaskDetailProvider(query)),
      ),
      data: (task) {
        final detail = ProjectTaskDetailData.fromTask(
          task,
          isQc: true,
          fallbackProjectId: initialDetail.projectId,
          fallbackTaskId: initialDetail.taskId,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) onLoaded(detail);
        });
        return RefreshIndicator(
          onRefresh: () =>
              ref.refresh(projectQcTaskDetailProvider(query).future),
          child: _QualityReviewContent(
            detail: detail,
            noteController: noteController,
            selectedEvidence: selectedEvidence,
            onAddEvidence: onAddEvidence,
            onRemoveSelectedEvidence: onRemoveSelectedEvidence,
            onStatusChanged: onStatusChanged,
          ),
        );
      },
    );
  }
}

class _QualityReviewContent extends StatelessWidget {
  const _QualityReviewContent({
    required this.detail,
    required this.noteController,
    required this.selectedEvidence,
    required this.onAddEvidence,
    required this.onRemoveSelectedEvidence,
    required this.onStatusChanged,
  });

  final ProjectTaskDetailData detail;
  final TextEditingController noteController;
  final List<ProjectFileUpload> selectedEvidence;
  final VoidCallback onAddEvidence;
  final ValueChanged<int> onRemoveSelectedEvidence;
  final ValueChanged<bool> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final isQcCompleted = detail.isQcCompleted;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onStatusChanged(isQcCompleted);
    });

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _TaskInfoSection(detail: detail),
        _EvidenceSection(attachments: detail.previousEvidence),
        if (detail.canSubmitFromApi != true && detail.hasQcFeedback) ...[
          _QcResultSection(detail: detail),
          _QcResultDetailsSection(detail: detail),
        ],
        if (!isQcCompleted && detail.canSubmitFromApi == true) ...[
          if (detail.assignee == '-')
            const _UnassignedNotice()
          else
            _QcFormSection(
              noteController: noteController,
              selectedEvidence: selectedEvidence,
              onAddEvidence: onAddEvidence,
              onRemoveSelectedEvidence: onRemoveSelectedEvidence,
            ),
        ],
      ],
    );
  }
}

class _UnassignedNotice extends StatelessWidget {
  const _UnassignedNotice();

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.dashboardTeal),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Task belum diassign, sehingga keputusan QC belum dapat dikirim.',
              style: TextStyle(
                color: AppColors.muted,
                fontFamily: AppFonts.inter,
                fontSize: 14,
                height: 1.43,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskInfoSection extends StatelessWidget {
  const _TaskInfoSection({required this.detail});

  final ProjectTaskDetailData detail;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailField(label: 'Kode', value: detail.code),
          const SizedBox(height: 20),
          _DetailField(label: 'Tugas', value: detail.task),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Dibuat oleh',
                  value: detail.creator,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Tanggal',
                  value: detail.createdDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DetailField(
            label: 'Status',
            value: detail.status,
            valueColor: AppColors.dashboardTeal,
            valueFontFamily: AppFonts.geist,
            valueFontWeight: FontWeight.w500,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Penerima tugas',
                  value: detail.assignee,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(label: 'Update', value: detail.updatedDate),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Helper',
                  value: detail.helperSummary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(label: 'Target', value: detail.target),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DetailField(label: 'Catatan Atasan', value: detail.supervisorNote),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Dilaporkan',
                  value: detail.reportedDate,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Capaian',
                  value: detail.completedVolume,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DetailField(label: 'Catatan Manpower', value: detail.manpowerNote),
        ],
      ),
    );
  }
}

class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({required this.attachments});

  final List<TaskEvidenceAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Bukti'),
          const SizedBox(height: AppSpacing.lg),
          UploadImageList(
            items: attachments
                .map(
                  (attachment) => UploadImageItem(
                    name: attachment.name,
                    path: attachment.path,
                    size: _parseFileSize(attachment.size),
                  ),
                )
                .toList(growable: false),
            showEmptyMessage: false,
            onAddPressed: null,
          ),
        ],
      ),
    );
  }
}

class _QcResultSection extends StatelessWidget {
  const _QcResultSection({required this.detail});

  final ProjectTaskDetailData detail;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = detail.qcStatus.trim().toLowerCase();
    final rejected = const {
      'fail',
      'failed',
      'qc_failed',
      'rejected',
      'ditolak',
    }.contains(normalizedStatus);

    return _Section(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailField(label: 'QC approval', value: detail.qcApproval),
                const SizedBox(height: 20),
                _DetailField(
                  label: 'Status',
                  value: _qcStatusLabel(detail.qcStatus),
                  valueColor: rejected
                      ? AppColors.error
                      : AppColors.dashboardTeal,
                  valueFontFamily: AppFonts.geist,
                  valueFontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _DetailField(label: 'Update', value: detail.qcUpdateDate),
          ),
        ],
      ),
    );
  }
}

class _QcResultDetailsSection extends StatelessWidget {
  const _QcResultDetailsSection({required this.detail});

  final ProjectTaskDetailData detail;

  @override
  Widget build(BuildContext context) {
    return _Section(
      hasBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Catatan QC'),
          const SizedBox(height: AppSpacing.lg),
          Text(
            detail.qcNote,
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
          const _SectionTitle('Bukti QC'),
          const SizedBox(height: AppSpacing.md),
          UploadImageList(
            items: detail.qcEvidence
                .map(
                  (attachment) => UploadImageItem(
                    name: attachment.name,
                    path: attachment.path,
                    size: _parseFileSize(attachment.size),
                  ),
                )
                .toList(growable: false),
            showEmptyMessage: false,
            onAddPressed: null,
          ),
        ],
      ),
    );
  }
}

String _qcStatusLabel(String status) {
  final normalizedStatus = status.trim().toLowerCase();
  if (const {
    'pass',
    'passed',
    'qc_passed',
    'approved',
    'disetujui',
    'diterima',
  }.contains(normalizedStatus)) {
    return 'Diterima';
  }
  if (const {
    'fail',
    'failed',
    'qc_failed',
    'rejected',
    'ditolak',
  }.contains(normalizedStatus)) {
    return 'Ditolak';
  }
  return status.trim().isEmpty ? '-' : status;
}

class _QcFormSection extends StatelessWidget {
  const _QcFormSection({
    required this.noteController,
    required this.selectedEvidence,
    required this.onAddEvidence,
    required this.onRemoveSelectedEvidence,
  });

  final TextEditingController noteController;
  final List<ProjectFileUpload> selectedEvidence;
  final VoidCallback onAddEvidence;
  final ValueChanged<int> onRemoveSelectedEvidence;

  @override
  Widget build(BuildContext context) {
    return _Section(
      hasBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Catatan QC', required: true),
          const SizedBox(height: AppSpacing.lg),
          InputMultilineWithBorder(
            controller: noteController,
            hintText: 'Masukkan deskripsi...',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle('Unggah bukti', required: true),
          const SizedBox(height: AppSpacing.md),
          UploadImageList(
            items: selectedEvidence
                .map(
                  (file) => UploadImageItem(
                    name: file.name,
                    path: file.path ?? '',
                    size: 0,
                  ),
                )
                .toList(growable: false),
            onAddPressed: onAddEvidence,
            onRemovePressed: onRemoveSelectedEvidence,
          ),
        ],
      ),
    );
  }
}

int _parseFileSize(String value) {
  final match = RegExp(
    r'([\d.]+)\s*(B|KB|MB|GB)?',
    caseSensitive: false,
  ).firstMatch(value);
  if (match == null) return 0;

  final number = double.tryParse(match.group(1)!) ?? 0;
  final unit = (match.group(2) ?? 'B').toUpperCase();
  final multiplier = switch (unit) {
    'GB' => 1024 * 1024 * 1024,
    'MB' => 1024 * 1024,
    'KB' => 1024,
    _ => 1,
  };
  return (number * multiplier).round();
}

class _Section extends StatelessWidget {
  const _Section({required this.child, this.hasBorder = true});

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

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.valueColor = AppColors.muted,
    this.valueFontFamily = AppFonts.inter,
    this.valueFontWeight = FontWeight.w400,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String valueFontFamily;
  final FontWeight valueFontWeight;

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
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontFamily: valueFontFamily,
            fontSize: 14,
            height: 1.43,
            fontWeight: valueFontWeight,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.required = false});

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
          letterSpacing: 0,
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

class _BottomActions extends StatelessWidget {
  const _BottomActions({
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
              backgroundColor: AppColors.rose,
              isLoading: rejecting,
              onPressed: onReject,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _DecisionButton(
              label: 'Setujui',
              icon: Icons.check,
              backgroundColor: AppColors.green,
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
    required this.backgroundColor,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null
          ? backgroundColor.withValues(alpha: 0.55)
          : backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.md),
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
                      Flexible(
                        child: Text(
                          isLoading ? 'Memproses...' : label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _buttonTextStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: double.infinity,
                color: AppColors.white.withValues(alpha: 0.18),
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

const _buttonTextStyle = TextStyle(
  color: AppColors.white,
  fontFamily: AppFonts.inter,
  fontSize: 16,
  height: 1.5,
  fontWeight: FontWeight.w600,
  letterSpacing: 0,
);

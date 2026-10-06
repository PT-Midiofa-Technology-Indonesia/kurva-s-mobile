import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/modules/logistic/data/models/logistic_models.dart';
import 'package:curva_mobile/modules/logistic/data/logistic_repository.dart';
import 'package:curva_mobile/modules/logistic/logistic_providers.dart';
import 'package:curva_mobile/modules/logistic/presentation/logistic_action_controllers.dart';
import 'package:curva_mobile/modules/logistic/presentation/widgets/logistic_notes_field.dart';
import 'package:curva_mobile/shared/widgets/app_button.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/error_view.dart';
import 'package:curva_mobile/shared/widgets/upload_image_list.dart';
import 'package:curva_mobile/shared/utils/upload_file_picker.dart';

class LoadingDetailPage extends ConsumerWidget {
  const LoadingDetailPage({required this.loadingOrderId, super.key});

  final String loadingOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (loadingOrderId.isEmpty) {
      return const _InvalidLoadingDetail();
    }
    final detail = ref.watch(loadingDetailProvider(loadingOrderId));
    return detail.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'Detail Loading Order',
                onBackPressed: () => context.pop(),
              ),
              const Expanded(child: AppSkeletonDetailView()),
            ],
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'Detail Loading Order',
                onBackPressed: () => context.pop(),
              ),
              Expanded(
                child: NetworkAwareErrorView(
                  error: error,
                  cacheFeatureKey: 'logisticCacheRead',
                  message: error.toString(),
                  onRetry: () =>
                      ref.invalidate(loadingDetailProvider(loadingOrderId)),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (data) =>
          _LoadingDetailContent(detail: data, loadingOrderId: loadingOrderId),
    );
  }
}

class _InvalidLoadingDetail extends StatelessWidget {
  const _InvalidLoadingDetail();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.white,
    body: SafeArea(
      child: Column(
        children: [
          AppHeader(
            title: 'Detail Loading Order',
            onBackPressed: () => context.pop(),
          ),
          const Expanded(
            child: ErrorView(message: 'ID loading order tidak valid.'),
          ),
        ],
      ),
    ),
  );
}

class _LoadingDetailContent extends ConsumerStatefulWidget {
  const _LoadingDetailContent({
    required this.detail,
    required this.loadingOrderId,
  });

  final LogisticLoadingOrderDetail detail;
  final String loadingOrderId;

  @override
  ConsumerState<_LoadingDetailContent> createState() =>
      _LoadingDetailContentState();
}

class _LoadingDetailContentState extends ConsumerState<_LoadingDetailContent> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.detail.latestReport?.notes ?? '',
    );
    ref
        .read(loadingReportControllerProvider(widget.loadingOrderId))
        .initialize(widget.detail);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    final selected = await UploadFilePicker.pick(context, type: FileType.image);
    if (selected.isEmpty) return;
    final files = selected
        .where((file) => file.path != null && file.path!.isNotEmpty)
        .map(
          (file) => UploadImageItem(
            name: file.name,
            path: file.path!,
            size: file.size,
          ),
        )
        .toList(growable: false);
    if (files.isEmpty) {
      if (mounted) AppToast.info(context, 'File tidak dapat dibaca.');
      return;
    }
    ref
        .read(loadingReportControllerProvider(widget.loadingOrderId))
        .addAttachments(files);
  }

  Future<void> _submit() async {
    final controller = ref.read(
      loadingReportControllerProvider(widget.loadingOrderId),
    );
    if (controller.isSubmitting || !widget.detail.canSubmit) return;
    try {
      final result = await controller.submit(
        notes: _notesController.text.trim(),
        photoPaths: controller.attachments
            .where((attachment) => !Uri.parse(attachment.path).hasScheme)
            .map((attachment) => attachment.path)
            .toList(growable: false),
      );
      if (!mounted) return;
      _showSubmitResult(result);
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, error);
    }
  }

  void _showSubmitResult(LogisticEnqueueResult? result) {
    switch (result) {
      case LogisticServerCompleted(:final message):
        AppToast.success(context, message ?? 'Laporan berhasil disimpan.');
        context.pop(true);
      case LogisticOperationStored():
      case LogisticOperationAlreadyPending():
        AppToast.success(
          context,
          'Tersimpan di perangkat dan akan disinkronkan otomatis.',
        );
        context.pop(true);
      case LogisticOperationNotReadyOffline(:final message):
      case LogisticOperationStoreFailed(:final message):
        AppToast.error(context, message);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final action = ref.watch(
      loadingReportControllerProvider(widget.loadingOrderId),
    );
    final operation = ref
        .watch(
          logisticTargetOperationProvider(
            LogisticTargetOperationQuery(
              resourceId: widget.loadingOrderId,
              resourceType: 'loading',
              operationType: SyncOperationType.logisticLoadingReport,
            ),
          ),
        )
        .valueOrNull;
    final canSubmit = detail.canSubmit;
    final readOnly = !canSubmit || operation != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Detail Loading Order',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(
                  loadingDetailProvider(widget.loadingOrderId).future,
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    _OverviewSection(detail: detail),
                    const _SectionDivider(),
                    _ItemsSection(items: detail.items),
                    const _SectionDivider(),
                    _ReportSection(
                      notesController: _notesController,
                      attachments: action.attachments,
                      readOnly: readOnly,
                      onAddAttachment: _pickAttachments,
                      onRemoveAttachment: (index) => ref
                          .read(
                            loadingReportControllerProvider(
                              widget.loadingOrderId,
                            ),
                          )
                          .removeAttachment(index),
                    ),
                  ],
                ),
              ),
            ),
            if (canSubmit || operation != null)
              SafeArea(
                top: false,
                child: _SubmitBar(
                  isSubmitting: action.isSubmitting,
                  enabled: operation == null,
                  syncState: operation?.state,
                  onPressed: _submit,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.detail});

  final LogisticLoadingOrderDetail detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailField(label: 'Source type', value: _text(detail.sourceType)),
        const SizedBox(height: AppSpacing.lg),
        _DetailField(label: 'Kode loading order', value: _text(detail.code)),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DetailField(
                label: 'Asal',
                value: _text(detail.sourceWarehouseName),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _DetailField(
                label: 'Tujuan',
                value: _text(detail.destinationWarehouseName),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailField(label: 'Catatan', value: _text(detail.notes)),
        const SizedBox(height: AppSpacing.lg),
        _DetailField(
          label: 'Status',
          value: _text(detail.statusLabel ?? detail.status),
          valueColor: AppColors.orange,
        ),
      ],
    ),
  );
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.items});

  final List<LogisticLoadingOrderItem> items;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Items'),
        const SizedBox(height: AppSpacing.lg),
        _ItemsTable(items: items),
      ],
    ),
  );
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.items});

  final List<LogisticLoadingOrderItem> items;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: AppColors.tabBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 560,
          child: Column(
            children: [
              const _TableRow(
                backgroundColor: AppColors.cardBackground,
                minHeight: 40,
                cells: [
                  _TableCell('Item Type', width: 120, showRightBorder: true),
                  _TableCell('Item', width: 220, showRightBorder: true),
                  _TableCell('Qty', width: 80, showRightBorder: true),
                  _TableCell('Satuan', width: 140),
                ],
              ),
              for (var index = 0; index < items.length; index++)
                _TableRow(
                  showDivider: index < items.length - 1,
                  cells: [
                    _TableCell(_text(items[index].itemType), width: 120),
                    _TableCell(_text(items[index].name), width: 220),
                    _TableCell(_text(items[index].quantity), width: 80),
                    _TableCell(_text(items[index].uom), width: 140),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.cells,
    this.backgroundColor = AppColors.white,
    this.showDivider = true,
    this.minHeight = 56,
  });

  final List<Widget> cells;
  final Color backgroundColor;
  final bool showDivider;
  final double minHeight;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: backgroundColor,
      border: Border(
        bottom: BorderSide(
          color: showDivider ? AppColors.tabBorder : AppColors.transparent,
        ),
      ),
    ),
    child: IntrinsicHeight(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cells,
        ),
      ),
    ),
  );
}

class _TableCell extends StatelessWidget {
  const _TableCell(
    this.text, {
    required this.width,
    this.showRightBorder = false,
  });

  final String text;
  final double width;
  final bool showRightBorder;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    decoration: BoxDecoration(
      border: Border(
        right: BorderSide(
          color: showRightBorder ? AppColors.tabBorder : AppColors.transparent,
        ),
      ),
    ),
    child: Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.ink,
        fontFamily: AppFonts.geist,
        fontSize: 14,
        height: 1.43,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.notesController,
    required this.attachments,
    required this.readOnly,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
  });

  final TextEditingController notesController;
  final List<UploadImageItem> attachments;
  final bool readOnly;
  final VoidCallback onAddAttachment;
  final ValueChanged<int> onRemoveAttachment;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Report'),
        const SizedBox(height: AppSpacing.lg),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              if (readOnly)
                _ReadonlyNotes(value: notesController.text)
              else
                LogisticNotesField(
                  controller: notesController,
                  hintText: 'Catatan',
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  18,
                ),
                child: UploadImageList(
                  items: attachments,
                  onAddPressed: readOnly ? null : onAddAttachment,
                  onRemovePressed: readOnly ? null : onRemoveAttachment,
                  showAddButton: !readOnly,
                  supportText: readOnly
                      ? null
                      : 'Format yang diizinkan: IMAGE/*',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReadonlyNotes extends StatelessWidget {
  const _ReadonlyNotes({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Catatan',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.muted,
            fontFamily: AppFonts.inter,
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value.trim().isEmpty ? '-' : value,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: AppFonts.inter,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.valueColor = AppColors.muted,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontFamily: AppFonts.inter,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        value,
        style: TextStyle(
          color: valueColor,
          fontFamily: AppFonts.inter,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: AppColors.ink,
      fontFamily: AppFonts.inter,
      fontSize: 18,
      height: 1.33,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.line);
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.isSubmitting,
    required this.enabled,
    required this.onPressed,
    this.syncState,
  });

  final bool isSubmitting;
  final bool enabled;
  final String? syncState;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.white,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AppButton(
        label: isSubmitting ? 'Menyimpan...' : _syncLabel(syncState),
        isLoading: isSubmitting,
        onPressed: isSubmitting || !enabled ? null : onPressed,
        backgroundColor: AppColors.dashboardTeal,
        borderRadius: AppRadius.md,
        textStyle: const TextStyle(
          color: AppColors.white,
          fontFamily: AppFonts.inter,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

String _syncLabel(String? state) => switch (state) {
  'pending' => 'Menunggu sinkronisasi',
  'processing' => 'Menyinkronkan...',
  'retry' => 'Akan dicoba lagi',
  'failed' => 'Periksa kegagalan',
  'conflict' => 'Tinjau konflik',
  _ => 'Simpan laporan',
};

String _text(Object? value) {
  if (value == null) return '-';
  final text = value.toString().trim();
  return text.isEmpty ? '-' : text;
}

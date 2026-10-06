import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/core/sync/sync_models.dart';
import 'package:curva_mobile/modules/logistic/data/logistic_repository.dart';
import 'package:curva_mobile/modules/logistic/data/models/logistic_models.dart';
import 'package:curva_mobile/modules/logistic/logistic_providers.dart';
import 'package:curva_mobile/modules/logistic/presentation/logistic_action_controllers.dart';
import 'package:curva_mobile/modules/logistic/presentation/widgets/delivery_order_data.dart';
import 'package:curva_mobile/modules/logistic/presentation/widgets/logistic_notes_field.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';
import 'package:curva_mobile/shared/utils/upload_file_picker.dart';
import 'package:curva_mobile/shared/widgets/app_button.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/input_picker_field.dart';
import 'package:curva_mobile/shared/widgets/input_single_line_text_field.dart';
import 'package:curva_mobile/shared/widgets/selection_bottom_sheet.dart';
import 'package:curva_mobile/shared/widgets/upload_image_list.dart';

class InboundDetailPage extends ConsumerWidget {
  const InboundDetailPage({required this.deliveryOrderId, super.key});

  final String deliveryOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (deliveryOrderId.isEmpty) {
      return const _InboundDetailContent(
        detail: InboundDetailData.fallback,
        deliveryOrderId: '',
      );
    }

    final detail = ref.watch(inboundDetailProvider(deliveryOrderId));

    return detail.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'Detail Inbound',
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
                title: 'Detail Inbound',
                onBackPressed: () => context.pop(),
              ),
              Expanded(
                child: NetworkAwareErrorView(
                  error: error,
                  cacheFeatureKey: 'logisticCacheRead',
                  message: error.toString(),
                  onRetry: () =>
                      ref.invalidate(inboundDetailProvider(deliveryOrderId)),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (data) => _InboundDetailContent(
        detail: InboundDetailData.fromDetail(data),
        deliveryOrderId: deliveryOrderId,
      ),
    );
  }
}

class _InboundDetailContent extends ConsumerStatefulWidget {
  const _InboundDetailContent({
    required this.detail,
    required this.deliveryOrderId,
  });

  final InboundDetailData detail;
  final String deliveryOrderId;

  @override
  ConsumerState<_InboundDetailContent> createState() =>
      _InboundDetailContentState();
}

class _InboundDetailContentState extends ConsumerState<_InboundDetailContent> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.detail.submittedNotes,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _addReceiptEntry() {
    ref
        .read(inboundActionControllerProvider(widget.deliveryOrderId))
        .addReceiptEntry();
  }

  void _removeReceiptEntry(int index) {
    ref
        .read(inboundActionControllerProvider(widget.deliveryOrderId))
        .removeReceiptEntry(index);
  }

  Future<void> _selectReceiptItem(int index) async {
    final controller = ref.read(
      inboundActionControllerProvider(widget.deliveryOrderId),
    );
    final selectedItem = await SelectionBottomSheet.show<InboundItemData>(
      context,
      title: 'Pilih Item',
      options: widget.detail.items,
      selectedOption: controller.receiptEntries[index].item,
      labelBuilder: (item) => item.name,
    );
    if (selectedItem == null) return;

    ref
        .read(inboundActionControllerProvider(widget.deliveryOrderId))
        .selectReceiptItem(index, selectedItem);
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
        .read(inboundActionControllerProvider(widget.deliveryOrderId))
        .addAttachments(files);
  }

  void _removeAttachment(int index) {
    ref
        .read(inboundActionControllerProvider(widget.deliveryOrderId))
        .removeAttachment(index);
  }

  Future<void> _submit() async {
    final controller = ref.read(
      inboundActionControllerProvider(widget.deliveryOrderId),
    );
    if (controller.isSubmitting ||
        widget.deliveryOrderId.isEmpty ||
        !widget.detail.canSubmit) {
      return;
    }

    final inputs = <LogisticReceiveItemInput>[];
    for (final entry in controller.receiptEntries) {
      final item = entry.item;
      if (item == null || item.deliveryOrderItemId.isEmpty) {
        AppToast.warning(context, 'Pilih item good receipt terlebih dahulu.');
        return;
      }

      final quantity = num.tryParse(entry.quantityController.text.trim());
      if (quantity == null || quantity <= 0) {
        AppToast.warning(context, 'Qty good receipt harus lebih dari 0.');
        return;
      }

      inputs.add(
        LogisticReceiveItemInput(
          deliveryOrderItemId: item.deliveryOrderItemId,
          quantityReceived: quantity,
        ),
      );
    }

    if (inputs.map((item) => item.deliveryOrderItemId).toSet().length !=
        inputs.length) {
      AppToast.warning(context, 'Item tidak boleh dipilih lebih dari sekali.');
      return;
    }

    if (controller.attachments.isEmpty) {
      AppToast.warning(context, 'Foto penerimaan wajib diunggah.');
      return;
    }

    for (var index = 0; index < inputs.length; index += 1) {
      final remaining =
          controller.receiptEntries[index].item?.remainingQuantity;
      if (remaining != null && inputs[index].quantityReceived > remaining) {
        AppToast.warning(
          context,
          'Qty penerimaan melebihi sisa quantity tersimpan.',
        );
        return;
      }
    }

    try {
      final result = await controller.submit(
        items: inputs,
        expectedVersion: widget.detail.version ?? 0,
        notes: _notesController.text.trim(),
        photoPaths: controller.attachments
            .where((attachment) => !Uri.parse(attachment.path).hasScheme)
            .map((attachment) => attachment.path)
            .toList(growable: false),
      );
      if (!mounted) return;
      switch (result) {
        case LogisticServerCompleted(:final message):
          AppToast.success(context, message ?? 'Barang berhasil diterima.');
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
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final operation = ref
        .watch(
          logisticTargetOperationProvider(
            LogisticTargetOperationQuery(
              resourceId: widget.deliveryOrderId,
              operationType: SyncOperationType.logisticInboundReceive,
            ),
          ),
        )
        .valueOrNull;
    final isEligible = detail.canSubmit;
    final isReadOnly = !isEligible || operation != null;
    final action = ref.watch(
      inboundActionControllerProvider(widget.deliveryOrderId),
    );
    action.initialize(detail);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Detail Inbound',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: widget.deliveryOrderId.isEmpty
                    ? () async {}
                    : () => ref.refresh(
                        inboundDetailProvider(widget.deliveryOrderId).future,
                      ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    _OverviewSection(detail: detail),
                    const _SectionDivider(),
                    _ItemsSection(items: detail.items),
                    const _SectionDivider(),
                    _GoodReceiptSection(
                      entries: action.receiptEntries,
                      attachments: action.attachments,
                      notesController: _notesController,
                      isReadOnly: isReadOnly,
                      onAddItem: _addReceiptEntry,
                      onSelectItem: _selectReceiptItem,
                      onRemoveItem: _removeReceiptEntry,
                      onAddAttachment: _pickAttachments,
                      onRemoveAttachment: _removeAttachment,
                    ),
                  ],
                ),
              ),
            ),
            if (isEligible || operation != null)
              SafeArea(
                top: false,
                child: _ReceiveActionBar(
                  isSubmitting: action.isSubmitting,
                  enabled:
                      widget.deliveryOrderId.isNotEmpty && operation == null,
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

  final InboundDetailData detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailField(label: 'Source type', value: detail.sourceType),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(
            label: 'Nomor delivery order',
            value: detail.documentNumber,
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(label: 'Nomor resi', value: detail.receiptNumber),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(label: 'Asal', value: detail.origin),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(label: 'Tujuan', value: detail.destination),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(label: 'Kurir', value: detail.courier),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Berat total',
                  value: detail.totalWeight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(label: 'Biaya pengiriman', value: detail.shippingCost),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(label: 'ETD', value: detail.etd),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(label: 'ETA', value: detail.eta),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(
            label: 'Status',
            value: detail.status,
            valueColor: AppColors.orange,
          ),
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.items});

  final List<InboundItemData> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Items'),
          const SizedBox(height: AppSpacing.lg),
          _ItemsTable(items: items),
        ],
      ),
    );
  }
}

class _GoodReceiptSection extends StatelessWidget {
  const _GoodReceiptSection({
    required this.entries,
    required this.attachments,
    required this.notesController,
    required this.isReadOnly,
    required this.onAddItem,
    required this.onSelectItem,
    required this.onRemoveItem,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
  });

  final List<GoodReceiptEntry> entries;
  final List<UploadImageItem> attachments;
  final TextEditingController notesController;
  final bool isReadOnly;
  final VoidCallback onAddItem;
  final ValueChanged<int> onSelectItem;
  final ValueChanged<int> onRemoveItem;
  final VoidCallback onAddAttachment;
  final ValueChanged<int> onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Good Receipt'),
          const SizedBox(height: AppSpacing.lg),
          ...entries.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _GoodReceiptCard(
                entry: entry.value,
                isReadOnly: isReadOnly,
                onSelectItem: () => onSelectItem(entry.key),
                onRemove: () => onRemoveItem(entry.key),
              ),
            ),
          ),
          if (!isReadOnly) _DashedAction(label: '+ Tambah', onTap: onAddItem),
          const SizedBox(height: 20),
          _AttachmentCard(
            controller: notesController,
            attachments: attachments,
            isReadOnly: isReadOnly,
            onAddAttachment: onAddAttachment,
            onRemoveAttachment: onRemoveAttachment,
          ),
        ],
      ),
    );
  }
}

class _GoodReceiptCard extends StatelessWidget {
  const _GoodReceiptCard({
    required this.entry,
    required this.isReadOnly,
    required this.onSelectItem,
    required this.onRemove,
  });

  final GoodReceiptEntry entry;
  final bool isReadOnly;
  final VoidCallback onSelectItem;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          if (isReadOnly)
            _ReadonlyItemField(label: 'Item', value: entry.item?.name ?? '')
          else
            InputPickerField(
              label: 'Item',
              isRequired: true,
              value: entry.item?.name ?? '',
              onTap: onSelectItem,
            ),
          AbsorbPointer(
            absorbing: isReadOnly,
            child: InputSingleLineTextField(
              label: 'Qty Adjustment',
              isRequired: true,
              controller: entry.quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
            ),
          ),
          if (!isReadOnly)
            SizedBox(
              height: 56,
              child: Center(
                child: TextButton(
                  onPressed: onRemove,
                  child: const Text(
                    'Hapus Item',
                    style: TextStyle(
                      color: AppColors.rose,
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.controller,
    required this.attachments,
    required this.isReadOnly,
    required this.onAddAttachment,
    required this.onRemoveAttachment,
  });

  final TextEditingController controller;
  final List<UploadImageItem> attachments;
  final bool isReadOnly;
  final VoidCallback onAddAttachment;
  final ValueChanged<int> onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isReadOnly)
            _ReadonlyItemField(
              label: 'Catatan',
              value: controller.text.trim().isEmpty ? '-' : controller.text,
            )
          else
            LogisticNotesField(
              controller: controller,
              hintText: 'Tambahkan catatan penerimaan',
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isReadOnly) ...[
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: AppColors.muted,
                        fontFamily: AppFonts.inter,
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                      children: [
                        TextSpan(text: 'Foto Penerimaan'),
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: AppColors.rose),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                UploadImageList(
                  items: attachments,
                  onAddPressed: isReadOnly ? null : onAddAttachment,
                  onRemovePressed: isReadOnly ? null : onRemoveAttachment,
                  showAddButton: !isReadOnly,
                  supportText: isReadOnly
                      ? null
                      : 'Format yang diizinkan: IMAGE/*',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadonlyItemField extends StatelessWidget {
  const _ReadonlyItemField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              text: label,
              style: TextStyle(
                color: AppColors.muted,
                fontFamily: AppFonts.inter,
                fontSize: hasValue ? 14 : 16,
                height: hasValue ? 1.43 : 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ),
          if (hasValue) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: AppFonts.inter,
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashedAction extends StatelessWidget {
  const _DashedAction({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: CustomPaint(
            painter: _DashedBorderPainter(),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.dashboardTeal,
                  fontFamily: AppFonts.inter,
                  fontSize: 16,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: AppFonts.inter,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontFamily: AppFonts.inter,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.items});

  final List<InboundItemData> items;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.tabBorder),
        ),
        child: Column(
          children: [
            const _ItemsTableRow(
              backgroundColor: AppColors.cardBackground,
              minHeight: 40,
              children: [
                _ItemsCell('Item', flex: 2, showRightBorder: true),
                _ItemsCell('Qty', showRightBorder: true),
                _ItemsCell('UoM', showRightBorder: false),
              ],
            ),
            for (var index = 0; index < items.length; index++)
              _ItemsTableRow(
                minHeight: 56,
                showDivider: index < items.length - 1,
                children: [
                  _ItemsCell(
                    items[index].name,
                    flex: 2,
                    showRightBorder: false,
                  ),
                  _ItemsCell(items[index].quantity, showRightBorder: false),
                  _ItemsCell(items[index].uom, showRightBorder: false),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemsTableRow extends StatelessWidget {
  const _ItemsTableRow({
    required this.children,
    this.backgroundColor = AppColors.white,
    this.minHeight = 40,
    this.showDivider = true,
  });
  final List<Widget> children;
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
        child: Row(children: children),
      ),
    ),
  );
}

class _ItemsCell extends StatelessWidget {
  const _ItemsCell(this.text, {this.flex = 1, this.showRightBorder = true});
  final String text;
  final int flex;
  final bool showRightBorder;
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: showRightBorder
                ? AppColors.tabBorder
                : AppColors.transparent,
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
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.ink,
        fontFamily: AppFonts.inter,
        fontSize: 18,
        height: 1.33,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.line);
  }
}

class _ReceiveActionBar extends StatelessWidget {
  const _ReceiveActionBar({
    required this.isSubmitting,
    required this.enabled,
    required this.onPressed,
    this.syncState,
  });

  final bool isSubmitting;
  final bool enabled;
  final VoidCallback onPressed;
  final String? syncState;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppButton(
          label: isSubmitting ? 'Menyimpan...' : _syncLabel(syncState),
          isLoading: isSubmitting,
          onPressed: isSubmitting || !enabled ? null : onPressed,
          backgroundColor: AppColors.dashboardTeal,
          textStyle: const TextStyle(
            color: AppColors.white,
            fontFamily: AppFonts.inter,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final paint = Paint()
      ..color = AppColors.inputBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.md),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class InboundDetailData {
  const InboundDetailData({
    required this.sourceType,
    required this.documentNumber,
    required this.receiptNumber,
    required this.origin,
    required this.destination,
    required this.courier,
    required this.totalWeight,
    required this.shippingCost,
    required this.etd,
    required this.eta,
    required this.status,
    required this.canSubmit,
    required this.items,
    required this.goodReceipts,
    this.submittedNotes = '',
    this.evidences = const [],
    this.version,
    this.allowedActions = const [],
  });

  factory InboundDetailData.fromOrder(DeliveryOrderData order) {
    return InboundDetailData(
      sourceType: order.orderType,
      documentNumber: order.documentNumber,
      receiptNumber: '-',
      origin: order.sourceLabel == 'Vendor' ? 'Vendor A' : order.source,
      destination: 'Warehouse A',
      courier: order.source,
      totalWeight: '3.7 kg',
      shippingCost: 'Rp 4.500.000',
      etd: 'May 22, 2026',
      eta: 'May 25, 2026',
      status: order.status,
      canSubmit: false,
      items: defaultItems,
      goodReceipts: defaultGoodReceipts,
    );
  }

  factory InboundDetailData.fromDetail(LogisticDeliveryOrderDetail detail) {
    return InboundDetailData(
      sourceType: _fallbackText(detail.sourceType),
      documentNumber: _fallbackText(detail.code),
      receiptNumber: _fallbackText(detail.resi),
      origin: _fallbackText(detail.sourceWarehouseName),
      destination: _fallbackText(detail.destinationWarehouseName),
      courier: _fallbackText(detail.carrier),
      totalWeight: _fallbackText(detail.weight),
      shippingCost: _fallbackText(detail.shippingCost),
      etd: formatDate(detail.etd),
      eta: formatDate(detail.eta),
      status: _fallbackText(detail.statusLabel ?? detail.status),
      canSubmit: detail.canSubmit,
      submittedNotes: detail.submittedNotes ?? '',
      evidences: detail.evidences,
      items: detail.items
          .map(
            (item) => InboundItemData(
              deliveryOrderItemId: item.deliveryOrderItemId,
              name: _fallbackText(item.name),
              quantity: _fallbackText(
                item.remainingQuantity ?? item.plannedQuantity,
              ),
              remainingQuantity: item.remainingQuantity,
              uom: _fallbackText(item.uom),
            ),
          )
          .toList(growable: false),
      version: detail.version,
      allowedActions: detail.allowedActions,
      goodReceipts: detail.items
          .map(
            (item) => GoodReceiptItemData(
              itemName: _fallbackText(item.name),
              quantity: _fallbackText(item.plannedQuantity),
              hasPicker: true,
            ),
          )
          .toList(growable: false),
    );
  }

  static const fallback = InboundDetailData(
    sourceType: 'Purchase Order',
    documentNumber: 'DO/WH-JKT/2024/0045',
    receiptNumber: '-',
    origin: 'Vendor A',
    destination: 'Warehouse A',
    courier: 'JNE Express',
    totalWeight: '3.7 kg',
    shippingCost: 'Rp 4.500.000',
    etd: 'May 22, 2026',
    eta: 'May 25, 2026',
    status: 'Open',
    canSubmit: false,
    items: defaultItems,
    goodReceipts: defaultGoodReceipts,
  );

  static const defaultItems = [
    InboundItemData(
      deliveryOrderItemId: '',
      name: 'Industrial Router Pro Gen 2',
      quantity: '50',
      uom: 'pcs',
    ),
    InboundItemData(
      deliveryOrderItemId: '',
      name: 'Fiber Optic Cable 100m',
      quantity: '70',
      uom: 'roll',
    ),
  ];

  static const defaultGoodReceipts = [
    GoodReceiptItemData(
      itemName: 'Industrial Router Pro Gen 2',
      quantity: '40',
      hasPicker: true,
    ),
    GoodReceiptItemData(itemName: '', quantity: ''),
  ];

  final String sourceType;
  final String documentNumber;
  final String receiptNumber;
  final String origin;
  final String destination;
  final String courier;
  final String totalWeight;
  final String shippingCost;
  final String etd;
  final String eta;
  final String status;
  final bool canSubmit;
  final List<InboundItemData> items;
  final List<GoodReceiptItemData> goodReceipts;
  final String submittedNotes;
  final List<LogisticDeliveryOrderEvidence> evidences;
  final int? version;
  final List<String> allowedActions;

  static String _fallbackText(Object? value) {
    if (value == null) return '-';
    final text = value.toString();
    return text.isEmpty ? '-' : text;
  }
}

class InboundItemData {
  const InboundItemData({
    this.deliveryOrderItemId = '',
    required this.name,
    required this.quantity,
    required this.uom,
    this.remainingQuantity,
  });

  final String deliveryOrderItemId;
  final String name;
  final String quantity;
  final String uom;
  final num? remainingQuantity;
}

String _syncLabel(String? state) => switch (state) {
  'pending' => 'Menunggu sinkronisasi',
  'processing' => 'Menyinkronkan...',
  'retry' => 'Menunggu sinkronisasi',
  'failed' => 'Periksa kegagalan',
  'conflict' => 'Tinjau konflik',
  _ => 'Terima barang (GR)',
};

class GoodReceiptItemData {
  const GoodReceiptItemData({
    required this.itemName,
    required this.quantity,
    this.hasPicker = false,
  });

  final String itemName;
  final String quantity;
  final bool hasPicker;
}

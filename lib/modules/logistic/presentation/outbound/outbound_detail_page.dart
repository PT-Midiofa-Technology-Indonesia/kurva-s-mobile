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
import 'package:curva_mobile/shared/widgets/upload_image_list.dart';

class OutboundDetailPage extends ConsumerWidget {
  const OutboundDetailPage({required this.deliveryOrderId, super.key});

  final String deliveryOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (deliveryOrderId.isEmpty) {
      return const _OutboundDetailContent(
        detail: OutboundDetailData.fallback,
        deliveryOrderId: '',
      );
    }

    final detail = ref.watch(outboundDetailProvider(deliveryOrderId));

    return detail.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'Detail Outbound',
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
                title: 'Detail Outbound',
                onBackPressed: () => context.pop(),
              ),
              Expanded(
                child: NetworkAwareErrorView(
                  error: error,
                  cacheFeatureKey: 'logisticCacheRead',
                  message: error.toString(),
                  onRetry: () =>
                      ref.invalidate(outboundDetailProvider(deliveryOrderId)),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (data) => _OutboundDetailContent(
        detail: OutboundDetailData.fromDetail(data),
        sourceDetail: data,
        deliveryOrderId: deliveryOrderId,
      ),
    );
  }
}

class _OutboundDetailContent extends ConsumerStatefulWidget {
  const _OutboundDetailContent({
    required this.detail,
    required this.deliveryOrderId,
    this.sourceDetail,
  });

  final OutboundDetailData detail;
  final LogisticDeliveryOrderDetail? sourceDetail;
  final String deliveryOrderId;

  @override
  ConsumerState<_OutboundDetailContent> createState() =>
      _OutboundDetailContentState();
}

class _OutboundDetailContentState
    extends ConsumerState<_OutboundDetailContent> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.sourceDetail?.submittedNotes ?? '',
    );
    final sourceDetail = widget.sourceDetail;
    if (sourceDetail != null) {
      ref
          .read(outboundActionControllerProvider(widget.deliveryOrderId))
          .initialize(sourceDetail);
    }
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
        .read(outboundActionControllerProvider(widget.deliveryOrderId))
        .addAttachments(files);
  }

  void _removeAttachment(int index) {
    ref
        .read(outboundActionControllerProvider(widget.deliveryOrderId))
        .removeAttachment(index);
  }

  Future<void> _submit() async {
    final controller = ref.read(
      outboundActionControllerProvider(widget.deliveryOrderId),
    );
    if (controller.isSubmitting ||
        widget.deliveryOrderId.isEmpty ||
        !widget.detail.canSubmit) {
      return;
    }

    try {
      final result = await controller.submit(
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
          AppToast.success(context, message ?? 'Barang berhasil dikirim.');
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
              operationType: SyncOperationType.logisticOutboundIssue,
            ),
          ),
        )
        .valueOrNull;
    final canSubmit = detail.canSubmit;
    final isReadOnly = !canSubmit || operation != null;
    final action = ref.watch(
      outboundActionControllerProvider(widget.deliveryOrderId),
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Detail Outbound',
              onBackPressed: () => context.pop(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: widget.deliveryOrderId.isEmpty
                    ? () async {}
                    : () => ref.refresh(
                        outboundDetailProvider(widget.deliveryOrderId).future,
                      ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    _OverviewSection(detail: detail),
                    const _SectionDivider(),
                    _ItemsSection(items: detail.items),
                    const _SectionDivider(),
                    _GoodIssueSection(
                      notesController: _notesController,
                      attachments: action.attachments,
                      readOnly: isReadOnly,
                      onAddAttachment: _pickAttachments,
                      onRemoveAttachment: _removeAttachment,
                    ),
                  ],
                ),
              ),
            ),
            if (canSubmit || operation != null)
              SafeArea(
                top: false,
                child: _SendActionBar(
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

  final OutboundDetailData detail;

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

  final List<OutboundItemData> items;

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

class _GoodIssueSection extends StatelessWidget {
  const _GoodIssueSection({
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
          const _SectionTitle(title: 'Good Issue'),
          const SizedBox(height: AppSpacing.lg),
          _GoodIssueCard(
            notesController: notesController,
            attachments: attachments,
            readOnly: readOnly,
            onAddAttachment: onAddAttachment,
            onRemoveAttachment: onRemoveAttachment,
          ),
        ],
      ),
    );
  }
}

class _GoodIssueCard extends StatelessWidget {
  const _GoodIssueCard({
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
          if (readOnly)
            _ReadonlyItemField(
              label: 'Catatan',
              value: notesController.text.trim().isEmpty
                  ? '-'
                  : notesController.text,
            )
          else
            LogisticNotesField(
              controller: notesController,
              hintText: 'Tambahkan catatan pengiriman',
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
              supportText: readOnly ? null : 'Format yang diizinkan: IMAGE/*',
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
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.muted,
              fontFamily: AppFonts.inter,
              fontSize: hasValue ? 14 : 16,
              height: hasValue ? 1.43 : 1.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
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
  final List<OutboundItemData> items;

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

class _SendActionBar extends StatelessWidget {
  const _SendActionBar({
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
          borderRadius: AppRadius.md,
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

class OutboundDetailData {
  const OutboundDetailData({
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
    required this.items,
    required this.canSubmit,
    this.version,
    this.allowedActions = const [],
  });

  factory OutboundDetailData.fromOrder(DeliveryOrderData order) {
    final isTransfer = order.orderType == 'Transfer Warehouse';

    return OutboundDetailData(
      sourceType: order.orderType,
      documentNumber: order.documentNumber,
      receiptNumber: 'JNE-123456789',
      origin: isTransfer ? 'Warehouse A' : 'Warehouse A',
      destination: isTransfer ? 'Warehouse B' : order.sourceLabel,
      courier: order.source,
      totalWeight: '3.7 kg',
      shippingCost: 'Rp 4.500.000',
      etd: 'May 22, 2026',
      eta: 'May 25, 2026',
      status: order.status,
      items: defaultItems,
      canSubmit: false,
    );
  }

  factory OutboundDetailData.fromDetail(LogisticDeliveryOrderDetail detail) {
    return OutboundDetailData(
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
      items: detail.items
          .map(
            (item) => OutboundItemData(
              name: _fallbackText(item.name),
              quantity: _fallbackText(item.plannedQuantity),
              uom: _fallbackText(item.uom),
            ),
          )
          .toList(growable: false),
      version: detail.version,
      allowedActions: detail.allowedActions,
      canSubmit: detail.canSubmit,
    );
  }

  static const fallback = OutboundDetailData(
    sourceType: 'Transfer Warehouse',
    documentNumber: 'DO/WH-JKT/2024/0045',
    receiptNumber: 'JNE-123456789',
    origin: 'Warehouse A',
    destination: 'Warehouse B',
    courier: 'JNE Express',
    totalWeight: '3.7 kg',
    shippingCost: 'Rp 4.500.000',
    etd: 'May 22, 2026',
    eta: 'May 25, 2026',
    status: 'Open',
    items: defaultItems,
    canSubmit: false,
  );

  static const defaultItems = [
    OutboundItemData(
      name: 'Industrial Router Pro Gen 2',
      quantity: '50',
      uom: 'pcs',
    ),
    OutboundItemData(
      name: 'Fiber Optic Cable 100m',
      quantity: '70',
      uom: 'roll',
    ),
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
  final List<OutboundItemData> items;
  final bool canSubmit;
  final int? version;
  final List<String> allowedActions;

  static String _fallbackText(Object? value) {
    if (value == null) return '-';
    final text = value.toString();
    return text.isEmpty ? '-' : text;
  }
}

String _syncLabel(String? state) => switch (state) {
  'pending' => 'Menunggu sinkronisasi',
  'processing' => 'Menyinkronkan...',
  'retry' => 'Menunggu sinkronisasi',
  'failed' => 'Periksa kegagalan',
  'conflict' => 'Tinjau konflik',
  _ => 'Kirim barang (GI)',
};

class OutboundItemData {
  const OutboundItemData({
    required this.name,
    required this.quantity,
    required this.uom,
  });

  final String name;
  final String quantity;
  final String uom;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/server_refresh_delay.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/input_single_line_text_field.dart';
import '../../data/models/inventory_models.dart';
import '../../inventory_providers.dart';

class StockAdjustmentBottomSheet extends ConsumerStatefulWidget {
  const StockAdjustmentBottomSheet({
    required this.detail,
    required this.toastContext,
    super.key,
  });

  final InventoryMaterialDetail detail;
  final BuildContext toastContext;

  static Future<void> show(
    BuildContext context,
    InventoryMaterialDetail detail,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) =>
          StockAdjustmentBottomSheet(detail: detail, toastContext: context),
    );
  }

  @override
  ConsumerState<StockAdjustmentBottomSheet> createState() =>
      _StockAdjustmentBottomSheetState();
}

class _StockAdjustmentBottomSheetState
    extends ConsumerState<StockAdjustmentBottomSheet> {
  late final TextEditingController _qtyController;
  late final TextEditingController _reasonController;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSubmitting) return;

    final qty = num.tryParse(_qtyController.text.trim());
    if (qty == null) {
      AppToast.warning(context, 'Qty adjustment harus berupa angka.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final message = await ref
          .read(inventoryRepositoryProvider)
          .submitStockAdjustment(
            itemCatalogId: widget.detail.itemCatalogId,
            adjustmentQty: qty,
            reason: _reasonController.text,
          );
      await waitForServerRefresh();
      if (!mounted) return;
      ref
        ..invalidate(inventoryMaterialsProvider)
        ..invalidate(
          inventoryMaterialDetailProvider(widget.detail.itemCatalogId),
        )
        ..invalidate(inventoryStockAdjustmentsProvider);

      final toastContext = widget.toastContext;
      Navigator.of(context).pop();
      if (toastContext.mounted) {
        AppToast.success(
          toastContext,
          message ?? 'Stock adjustment berhasil diajukan.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      AppToast.error(context, error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _StockAdjustmentHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    child: _StockAdjustmentForm(
                      itemValue: widget.detail.name,
                      qtyController: _qtyController,
                      reasonController: _reasonController,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppButton(
                    label: _isSubmitting ? 'Menyimpan...' : 'Simpan perubahan',
                    isLoading: _isSubmitting,
                    borderRadius: AppRadius.md,
                    backgroundColor: AppColors.dashboardTeal,
                    textStyle: const TextStyle(
                      color: AppColors.white,
                      fontFamily: AppFonts.inter,
                      fontSize: 18,
                      height: 1.33,
                      fontWeight: FontWeight.w700,
                    ),
                    onPressed: _isSubmitting ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockAdjustmentHeader extends StatelessWidget {
  const _StockAdjustmentHeader();

  @override
  Widget build(BuildContext context) => Container(
    height: 88,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.line)),
    ),
    child: Row(
      children: [
        const SizedBox(width: 64),
        const Expanded(
          child: Text(
            'Stok Adjustment',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink,
              fontFamily: AppFonts.inter,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          width: 64,
          height: 64,
          child: IconButton(
            tooltip: 'Tutup',
            icon: const Icon(Icons.close, size: 32),
            color: AppColors.dashboardTeal,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    ),
  );
}

class _StockAdjustmentForm extends StatelessWidget {
  const _StockAdjustmentForm({
    required this.itemValue,
    required this.qtyController,
    required this.reasonController,
  });

  final String itemValue;
  final TextEditingController qtyController;
  final TextEditingController reasonController;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(24),
    ),
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.line, width: 1.5),
    ),
    child: Column(
      children: [
        _ReadonlyItemField(label: 'Item', value: itemValue, isRequired: true),
        InputSingleLineTextField(
          label: 'Qty Adjustment',
          controller: qtyController,
          isRequired: true,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          textInputAction: TextInputAction.next,
        ),
        InputSingleLineTextField(
          label: 'Alasan',
          controller: reasonController,
          textInputAction: TextInputAction.done,
          showBottomBorder: false,
        ),
      ],
    ),
  );
}

class _ReadonlyItemField extends StatelessWidget {
  const _ReadonlyItemField({
    required this.label,
    required this.value,
    this.isRequired = false,
  });

  final String label;
  final String value;
  final bool isRequired;

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
              style: TextStyle(
                color: AppColors.muted,
                fontFamily: AppFonts.inter,
                fontSize: hasValue ? 14 : 16,
                height: hasValue ? 1.43 : 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
              children: [
                TextSpan(text: label),
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.rose),
                  ),
              ],
            ),
          ),
          if (hasValue) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../data/models/inventory_models.dart';
import '../inventory_providers.dart';
import 'widgets/stock_adjustment_bottom_sheet.dart';

class InventoryDetailPage extends ConsumerWidget {
  const InventoryDetailPage({required this.itemCatalogId, super.key});

  static const _fontFamily = AppFonts.inter;
  static const _accentFontFamily = AppFonts.geist;

  final String itemCatalogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(inventoryMaterialDetailProvider(itemCatalogId));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(title: 'Inventory', onBackPressed: () => context.pop()),
            Expanded(
              child: detail.when(
                loading: () => const AppSkeletonDetailView(showHero: false),
                error: (error, _) => NetworkAwareErrorView(
                  error: error,
                  message: error.toString(),
                  onRetry: () => ref.invalidate(
                    inventoryMaterialDetailProvider(itemCatalogId),
                  ),
                ),
                data: (item) => RefreshIndicator(
                  onRefresh: () => ref.refresh(
                    inventoryMaterialDetailProvider(itemCatalogId).future,
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    children: [
                      _DescriptionSection(detail: item),
                      const _Divider(),
                      _AdjustmentSection(adjustments: item.adjustmentHistory),
                    ],
                  ),
                ),
              ),
            ),
            detail.maybeWhen(
              data: (item) =>
                  SafeArea(top: false, child: _MapsActionBar(detail: item)),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.detail});

  final InventoryMaterialDetail detail;

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
          const _SectionHeading(title: 'Keterangan'),
          const SizedBox(height: 20),
          _DetailField(label: 'Kode', value: detail.code),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(label: 'Material', value: detail.name),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Qty on hand',
                  value: detail.quantityLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Reserved',
                  value: detail.reservedLabel,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Tersedia',
                  value: detail.availableLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Terakhir dipindah',
                  value: formatInventoryDate(detail.lastMovementAt),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Update terakhir',
                  value: formatInventoryDate(detail.updatedAt),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailField(label: 'Gudang', value: detail.warehouseName),
          const SizedBox(height: AppSpacing.md),
          _DetailField(
            label: 'Status',
            value: detail.statusLabel,
            valueColor: AppColors.orange,
          ),
        ],
      ),
    );
  }
}

class _AdjustmentSection extends StatelessWidget {
  const _AdjustmentSection({required this.adjustments});

  final List<InventoryStockAdjustment> adjustments;

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
          const _SectionHeading(title: 'Riwayat penyesuaian'),
          const SizedBox(height: AppSpacing.md),
          if (adjustments.isEmpty)
            const Text(
              'Belum ada riwayat penyesuaian.',
              style: TextStyle(
                color: AppColors.muted,
                fontFamily: InventoryDetailPage._fontFamily,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            )
          else
            ...adjustments.map(
              (adjustment) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _AdjustmentEntry(adjustment: adjustment),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdjustmentEntry extends StatelessWidget {
  const _AdjustmentEntry({required this.adjustment});

  final InventoryStockAdjustment adjustment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                adjustment.date,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontFamily: InventoryDetailPage._fontFamily,
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              adjustment.statusLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: adjustment.isApproved
                    ? AppColors.dashboardTeal
                    : AppColors.orange,
                fontFamily: InventoryDetailPage._accentFontFamily,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _AdjustmentCard(adjustment: adjustment),
      ],
    );
  }
}

class _AdjustmentCard extends StatelessWidget {
  const _AdjustmentCard({required this.adjustment});

  final InventoryStockAdjustment adjustment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.softLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Qty on hand',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.muted,
              fontFamily: InventoryDetailPage._fontFamily,
              fontSize: 14,
              height: 1.43,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              _AdjustmentQuantity(adjustment.beforeLabel),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Icon(
                  Icons.arrow_forward,
                  size: 24,
                  color: AppColors.dashboardTeal,
                ),
              ),
              _AdjustmentQuantity(adjustment.afterLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdjustmentQuantity extends StatelessWidget {
  const _AdjustmentQuantity(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.ink,
        fontFamily: InventoryDetailPage._accentFontFamily,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.value,
    this.valueColor = AppColors.secondaryText,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailLabel(label),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontFamily: InventoryDetailPage._fontFamily,
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _DetailLabel extends StatelessWidget {
  const _DetailLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.ink,
        fontFamily: InventoryDetailPage._fontFamily,
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.ink,
        fontFamily: InventoryDetailPage._fontFamily,
        fontSize: 16,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: AppColors.line);
  }
}

class _MapsActionBar extends StatelessWidget {
  const _MapsActionBar({required this.detail});

  final InventoryMaterialDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: AppButton(
        label: 'Stock adjustment',
        backgroundColor: AppColors.dashboardTeal,
        onPressed: () => StockAdjustmentBottomSheet.show(context, detail),
      ),
    );
  }
}

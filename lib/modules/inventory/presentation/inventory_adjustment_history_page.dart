import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../data/models/inventory_models.dart';
import '../inventory_providers.dart';

class InventoryAdjustmentHistoryPage extends ConsumerWidget {
  const InventoryAdjustmentHistoryPage({super.key});

  static const _fontFamily = AppFonts.inter;
  static const _accentFontFamily = AppFonts.geist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adjustments = ref.watch(inventoryStockAdjustmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ColoredBox(
          color: AppColors.cardBackground,
          child: Column(
            children: [
              const _HistoryHeader(),
              Expanded(
                child: adjustments.when(
                  loading: () => const AppSkeletonListView(
                    variant: AppSkeletonListVariant.standard,
                  ),
                  error: (error, _) => NetworkAwareErrorView(
                    error: error,
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(inventoryStockAdjustmentsProvider),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () => ref.refresh(
                          inventoryStockAdjustmentsProvider.future,
                        ),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(
                              height: 320,
                              child: EmptyView(
                                message: 'Riwayat penyesuaian belum tersedia.',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(inventoryStockAdjustmentsProvider.future),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                        ),
                        itemCount: items.length + 1,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              child: Text(
                                'Riwayat',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontFamily: _fontFamily,
                                  fontSize: 16,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                            );
                          }

                          return _AdjustmentHistoryCard(
                            adjustment: items[index - 1],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return AppHeader(
      title: 'History Adjustment',
      onBackPressed: () => context.pop(),
    );
  }
}

class _AdjustmentHistoryCard extends StatelessWidget {
  const _AdjustmentHistoryCard({required this.adjustment});

  final InventoryStockAdjustment adjustment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            adjustment.itemName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: InventoryAdjustmentHistoryPage._fontFamily,
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, thickness: 1, color: AppColors.line),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: _QuantityText(adjustment.beforeLabel)),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            color: AppColors.dashboardTeal,
                            size: 20,
                          ),
                        ),
                        Flexible(child: _QuantityText(adjustment.afterLabel)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      adjustment.warehouseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontFamily:
                            InventoryAdjustmentHistoryPage._accentFontFamily,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    adjustment.statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: adjustment.isApproved
                          ? AppColors.dashboardTeal
                          : AppColors.orange,
                      fontFamily:
                          InventoryAdjustmentHistoryPage._accentFontFamily,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DateBadge(label: adjustment.date),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityText extends StatelessWidget {
  const _QuantityText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.ink,
        fontFamily: InventoryAdjustmentHistoryPage._fontFamily,
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.selectionBackground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.dashboardTeal, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time,
            color: AppColors.dashboardTeal,
            size: 12,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: InventoryAdjustmentHistoryPage._fontFamily,
              fontSize: 12,
              height: 1.43,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

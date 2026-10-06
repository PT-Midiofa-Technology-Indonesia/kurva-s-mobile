import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../data/models/inventory_models.dart';
import '../inventory_providers.dart';

class InventoryEquipmentDetailPage extends ConsumerWidget {
  const InventoryEquipmentDetailPage({required this.resourceUnitId, super.key});

  static const _fontFamily = AppFonts.inter;

  final String resourceUnitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(inventoryEquipmentDetailProvider(resourceUnitId));

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
                    inventoryEquipmentDetailProvider(resourceUnitId),
                  ),
                ),
                data: (item) => RefreshIndicator(
                  onRefresh: () => ref.refresh(
                    inventoryEquipmentDetailProvider(resourceUnitId).future,
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    children: [
                      _DescriptionSection(detail: item),
                      const _Divider(),
                      _AllocationHistorySection(
                        history: item.allocationHistory,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.detail});

  final InventoryEquipmentDetail detail;

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
          const SizedBox(height: 28),
          _DetailField(label: 'Kode', value: detail.unitCode),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(label: 'Peralatan', value: detail.name),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Gudang',
                  value: detail.warehouseName,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DetailField(
                  label: 'Serial number',
                  value: detail.serialNumber ?? '-',
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DetailField(
                  label: 'Akuisisi',
                  value: formatInventoryDate(detail.acquisitionDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(
            label: 'Update terakhir',
            value: formatInventoryDate(detail.updatedAt),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailField(
            label: 'Status',
            value: detail.statusLabel,
            valueColor: detail.statusColor,
          ),
        ],
      ),
    );
  }
}

class _AllocationHistorySection extends StatelessWidget {
  const _AllocationHistorySection({required this.history});

  final List<InventoryEquipmentAllocation> history;

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
          const _SectionHeading(title: 'Riwayat alokasi'),
          const SizedBox(height: AppSpacing.lg),
          if (history.isEmpty)
            const Text(
              'Belum ada riwayat alokasi.',
              style: TextStyle(
                color: AppColors.muted,
                fontFamily: InventoryEquipmentDetailPage._fontFamily,
                fontSize: 14,
                height: 1.43,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            )
          else
            _AllocationHistoryTable(history: history),
        ],
      ),
    );
  }
}

class _AllocationHistoryTable extends StatelessWidget {
  const _AllocationHistoryTable({required this.history});

  final List<InventoryEquipmentAllocation> history;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      const _AllocationRow(from: 'Dari', until: 'Hingga', isHeader: true),
      for (final item in history)
        _AllocationRow(from: item.from, until: item.until),
    ];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(children: rows),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow({
    required this.from,
    required this.until,
    this.isHeader = false,
  });

  final String from;
  final String until;
  final bool isHeader;

  static const _textStyle = TextStyle(
    color: AppColors.ink,
    fontFamily: InventoryEquipmentDetailPage._fontFamily,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: isHeader ? 40 : 52),
      decoration: BoxDecoration(
        color: isHeader ? AppColors.cardBackground : AppColors.white,
        border: isHeader
            ? null
            : const Border(top: BorderSide(color: AppColors.line)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _AllocationCell(value: from, isHeader: isHeader),
            ),
            if (isHeader)
              const SizedBox(
                width: 1,
                child: ColoredBox(color: AppColors.line),
              ),
            Expanded(
              child: _AllocationCell(value: until, isHeader: isHeader),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationCell extends StatelessWidget {
  const _AllocationCell({required this.value, this.isHeader = false});

  final String value;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        isHeader ? AppSpacing.sm : AppSpacing.md,
        20,
        isHeader ? AppSpacing.sm : AppSpacing.md,
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _AllocationRow._textStyle,
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
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontFamily: InventoryEquipmentDetailPage._fontFamily,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w600,
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
            fontFamily: InventoryEquipmentDetailPage._fontFamily,
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
        fontFamily: InventoryEquipmentDetailPage._fontFamily,
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

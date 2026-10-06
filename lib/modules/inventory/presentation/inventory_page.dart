import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/offline_first_providers.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_popup_menu_button.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/app_underline_tabs.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/full_page_search_bottom_sheet.dart';
import '../../../shared/widgets/network_aware_error_view.dart';
import '../data/models/inventory_models.dart';
import '../inventory_providers.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  static const _fontFamily = AppFonts.geist;

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  var _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ColoredBox(
          color: AppColors.cardBackground,
          child: Column(
            children: [
              _InventoryHeader(selectedTabIndex: _selectedTabIndex),
              AppUnderlineTabs(
                items: const [
                  AppUnderlineTabItem(label: 'Material', width: 88),
                  AppUnderlineTabItem(label: 'Peralatan', width: 104),
                ],
                selectedIndex: _selectedTabIndex,
                onTabSelected: (index) {
                  setState(() => _selectedTabIndex = index);
                },
                fontFamily: InventoryPage._fontFamily,
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: const [_InventoryList(), _EquipmentList()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryHeader extends ConsumerWidget {
  const _InventoryHeader({required this.selectedTabIndex});

  final int selectedTabIndex;

  Future<void> _showMaterialSearch(BuildContext context, WidgetRef ref) async {
    final materialsState = ref.read(inventoryMaterialsProvider);
    final materials = materialsState.valueOrNull ?? const <InventoryMaterial>[];

    if (materials.isEmpty) {
      AppToast.info(
        context,
        materialsState.isLoading
            ? 'Daftar material sedang dimuat.'
            : 'Data material belum tersedia.',
      );
      return;
    }

    final selectedMaterial =
        await FullPageSearchBottomSheet.show<InventoryMaterial>(
          context,
          title: 'Pencarian',
          options: materials,
          labelBuilder: (material) =>
              material.name.isEmpty ? '-' : material.name,
          searchTextBuilder: (material) => [
            material.code,
            material.name,
            material.warehouseName,
            material.quantityLabel,
            material.status,
            material.statusLabel,
          ].join(' '),
        );

    if (!context.mounted || selectedMaterial == null) return;

    context.push(
      RouteNames.inventoryDetail,
      extra: selectedMaterial.itemCatalogId,
    );
  }

  Future<void> _showEquipmentSearch(BuildContext context, WidgetRef ref) async {
    final equipmentState = ref.read(inventoryEquipmentProvider);
    final equipment =
        equipmentState.valueOrNull ?? const <InventoryEquipment>[];

    if (equipment.isEmpty) {
      AppToast.info(
        context,
        equipmentState.isLoading
            ? 'Daftar peralatan sedang dimuat.'
            : 'Data peralatan belum tersedia.',
      );
      return;
    }

    final selectedEquipment =
        await FullPageSearchBottomSheet.show<InventoryEquipment>(
          context,
          title: 'Pencarian',
          options: equipment,
          labelBuilder: (item) => item.name.isEmpty ? '-' : item.name,
          searchTextBuilder: (item) => [
            item.unitCode,
            item.name,
            item.warehouseName,
            item.status,
            item.statusLabel,
          ].join(' '),
        );

    if (!context.mounted || selectedEquipment == null) return;

    context.push(
      RouteNames.inventoryEquipmentDetail,
      extra: selectedEquipment.resourceUnitId,
    );
  }

  Future<void> _showSearch(BuildContext context, WidgetRef ref) {
    if (selectedTabIndex == 0) {
      return _showMaterialSearch(context, ref);
    }

    return _showEquipmentSearch(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline =
        ref.watch(connectivityStateProvider).valueOrNull?.isOffline ?? false;

    return AppHeader(
      title: 'Inventory',
      onBackPressed: () => context.pop(),
      actions: isOffline
          ? const []
          : [
              AppHeaderAction(
                icon: Icons.search,
                tooltip: 'Cari',
                onPressed: () => _showSearch(context, ref),
              ),
            ],
      actionWidgets: [if (!isOffline) const _InventoryHeaderMenu()],
    );
  }
}

enum _InventoryHeaderMenuAction {
  adjustmentHistory('Riwayat penyesuaian');

  const _InventoryHeaderMenuAction(this.label);

  final String label;
}

class _InventoryHeaderMenu extends StatelessWidget {
  const _InventoryHeaderMenu();

  Future<void> _handleMenuAction(
    BuildContext context,
    _InventoryHeaderMenuAction action,
  ) async {
    switch (action) {
      case _InventoryHeaderMenuAction.adjustmentHistory:
        context.push(RouteNames.inventoryAdjustmentHistory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPopupMenuButton<_InventoryHeaderMenuAction>(
      items: _InventoryHeaderMenuAction.values,
      labelBuilder: (action) => action.label,
      iconColor: AppColors.dashboardTeal,
      fontFamily: InventoryPage._fontFamily,
      tooltip: 'Menu lainnya',
      onSelected: (action) => _handleMenuAction(context, action),
    );
  }
}

class _InventoryList extends ConsumerWidget {
  const _InventoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materials = ref.watch(inventoryMaterialsProvider);

    return materials.when(
      loading: () =>
          const AppSkeletonListView(variant: AppSkeletonListVariant.standard),
      error: (error, _) => NetworkAwareErrorView(
        error: error,
        message: error.toString(),
        onRetry: () => ref.invalidate(inventoryMaterialsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(inventoryMaterialsProvider.future),
            child: const EmptyView(message: 'Data material belum tersedia.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(inventoryMaterialsProvider.future),
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
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    'Material',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontFamily: InventoryPage._fontFamily,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                );
              }

              final item = items[index - 1];
              return _InventoryCard(
                item: item,
                onTap: () => context.push(
                  RouteNames.inventoryDetail,
                  extra: item.itemCatalogId,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EquipmentList extends ConsumerWidget {
  const _EquipmentList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipment = ref.watch(inventoryEquipmentProvider);

    return equipment.when(
      loading: () =>
          const AppSkeletonListView(variant: AppSkeletonListVariant.compact),
      error: (error, _) => NetworkAwareErrorView(
        error: error,
        message: error.toString(),
        onRetry: () => ref.invalidate(inventoryEquipmentProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(inventoryEquipmentProvider.future),
            child: const EmptyView(message: 'Data peralatan belum tersedia.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(inventoryEquipmentProvider.future),
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
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    'Peralatan',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontFamily: InventoryPage._fontFamily,
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                );
              }

              final item = items[index - 1];
              return _EquipmentCard(
                item: item,
                onTap: () => context.push(
                  RouteNames.inventoryEquipmentDetail,
                  extra: item.resourceUnitId,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  const _EquipmentCard({required this.item, required this.onTap});

  final InventoryEquipment item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontFamily: InventoryPage._fontFamily,
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.warehouseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontFamily: InventoryPage._fontFamily,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                item.statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: item.statusColor,
                  fontFamily: InventoryPage._fontFamily,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.onTap});

  final InventoryMaterial item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontFamily: InventoryPage._fontFamily,
                  fontSize: 16,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, thickness: 1, color: AppColors.line),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.quantityLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontFamily: InventoryPage._fontFamily,
                            fontSize: 14,
                            height: 1.33,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.warehouseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontFamily: InventoryPage._fontFamily,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
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
                        item.statusLabel,
                        style: const TextStyle(
                          color: AppColors.orange,
                          fontFamily: InventoryPage._fontFamily,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _UpdateBadge(
                        label:
                            'Update ${formatInventoryDate(item.lastMovementAt)}',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateBadge extends StatelessWidget {
  const _UpdateBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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
            style: const TextStyle(
              color: AppColors.ink,
              fontFamily: InventoryPage._fontFamily,
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

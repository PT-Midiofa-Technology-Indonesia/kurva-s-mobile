import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/modules/logistic/data/models/logistic_models.dart';
import 'package:curva_mobile/modules/logistic/logistic_providers.dart';
import 'package:curva_mobile/modules/logistic/presentation/widgets/logistic_widgets.dart';
import 'package:curva_mobile/shared/utils/date_formatter.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/full_page_search_bottom_sheet.dart';

class PickupPage extends ConsumerStatefulWidget {
  const PickupPage({super.key});

  @override
  ConsumerState<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends ConsumerState<PickupPage> {
  var _selectedTabIndex = 0;

  Future<void> _openDetail(String pickupOrderId) async {
    final didSubmit = await context.push<bool>(
      RouteNames.pickupDetail,
      extra: pickupOrderId,
    );
    if (!mounted || didSubmit != true) return;

    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    await Future.wait([
      ref.refresh(
        pickupOrdersProvider(const LogisticListQuery(tab: 'open')).future,
      ),
      ref.refresh(
        pickupOrdersProvider(const LogisticListQuery(tab: 'close')).future,
      ),
    ]);
  }

  Future<void> _showSearch() async {
    final query = LogisticListQuery(
      tab: _selectedTabIndex == 0 ? 'open' : 'close',
    );
    final ordersState = ref.read(pickupOrdersProvider(query));
    final orders = ordersState.valueOrNull ?? const <LogisticPickupOrder>[];

    if (orders.isEmpty) {
      AppToast.info(
        context,
        ordersState.isLoading
            ? 'Daftar pickup sedang dimuat.'
            : 'Data pickup belum tersedia.',
      );
      return;
    }

    final selected = await FullPageSearchBottomSheet.show<LogisticPickupOrder>(
      context,
      title: 'Pencarian',
      options: orders,
      labelBuilder: (order) => order.code.isEmpty ? '-' : order.code,
      searchTextBuilder: _searchText,
    );
    if (!mounted || selected == null) return;

    await _openDetail(selected.pickupOrderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ColoredBox(
          color: AppColors.cardBackground,
          child: Column(
            children: [
              AppHeader(
                title: 'Pickup',
                onBackPressed: () => context.pop(),
                actions: [
                  AppHeaderAction(
                    icon: Icons.search,
                    tooltip: 'Cari',
                    onPressed: _showSearch,
                  ),
                ],
              ),
              LogisticOpenCloseTabs(
                selectedIndex: _selectedTabIndex,
                onTabSelected: (index) {
                  setState(() => _selectedTabIndex = index);
                },
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    _PickupOrderList(
                      query: const LogisticListQuery(tab: 'open'),
                      onOpenDetail: _openDetail,
                    ),
                    _PickupOrderList(
                      query: const LogisticListQuery(tab: 'close'),
                      onOpenDetail: _openDetail,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _searchText(LogisticPickupOrder order) {
  return [
    order.code,
    order.warehouseName ?? '',
    order.scheduledDate ?? '',
    order.statusLabel ?? '',
    order.status,
    order.type,
  ].join(' ');
}

class _PickupOrderList extends ConsumerWidget {
  const _PickupOrderList({required this.query, required this.onOpenDetail});

  final LogisticListQuery query;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(pickupOrdersProvider(query));
    final syncStates =
        ref.watch(logisticSyncStateByResourceProvider('pickup')).valueOrNull ??
        const <String, String>{};

    return orders.when(
      loading: () => const AppSkeletonListView(
        variant: AppSkeletonListVariant.standard,
        showSectionHeader: false,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
      ),
      error: (error, _) => NetworkAwareErrorView(
        error: error,
        cacheFeatureKey: 'logisticCacheRead',
        message: error.toString(),
        onRetry: () => ref.invalidate(pickupOrdersProvider(query)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(pickupOrdersProvider(query).future),
            child: const EmptyView(message: 'Data pickup belum tersedia.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(pickupOrdersProvider(query).future),
          child: DeliveryOrderList(
            items: items
                .map(
                  (order) => _pickupOrderData(
                    order,
                    syncState: syncStates[order.pickupOrderId],
                  ),
                )
                .toList(growable: false),
            onItemTap: (item) => onOpenDetail(item.deliveryOrderId),
          ),
        );
      },
    );
  }

  DeliveryOrderData _pickupOrderData(
    LogisticPickupOrder order, {
    String? syncState,
  }) {
    return DeliveryOrderData(
      deliveryOrderId: order.pickupOrderId,
      documentNumber: order.code,
      source: order.warehouseName ?? '-',
      sourceLabel: formatIndonesianDate(order.scheduledDate, shortMonth: true),
      status: order.statusLabel ?? order.status,
      orderType: order.type,
      syncState: syncState,
    );
  }
}

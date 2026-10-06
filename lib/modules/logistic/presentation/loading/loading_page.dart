import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/modules/logistic/data/models/logistic_models.dart';
import 'package:curva_mobile/modules/logistic/logistic_providers.dart';
import 'package:curva_mobile/modules/logistic/presentation/widgets/logistic_widgets.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/full_page_search_bottom_sheet.dart';

class LoadingPage extends ConsumerStatefulWidget {
  const LoadingPage({super.key});

  @override
  ConsumerState<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends ConsumerState<LoadingPage> {
  var _selectedTabIndex = 0;

  Future<void> _openDetail(String loadingOrderId) async {
    final didSubmit = await context.push<bool>(
      RouteNames.loadingDetail,
      extra: loadingOrderId,
    );
    if (!mounted || didSubmit != true) return;

    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    await Future.wait([
      ref.refresh(
        loadingOrdersProvider(const LogisticListQuery(tab: 'open')).future,
      ),
      ref.refresh(
        loadingOrdersProvider(const LogisticListQuery(tab: 'close')).future,
      ),
    ]);
  }

  Future<void> _showSearch() async {
    final query = LogisticListQuery(
      tab: _selectedTabIndex == 0 ? 'open' : 'close',
    );
    final ordersState = ref.read(loadingOrdersProvider(query));
    final orders = ordersState.valueOrNull ?? const <LogisticLoadingOrder>[];

    if (orders.isEmpty) {
      AppToast.info(
        context,
        ordersState.isLoading
            ? 'Daftar loading sedang dimuat.'
            : 'Data loading belum tersedia.',
      );
      return;
    }

    final selected = await FullPageSearchBottomSheet.show<LogisticLoadingOrder>(
      context,
      title: 'Pencarian',
      options: orders,
      labelBuilder: (order) => order.code.isEmpty ? '-' : order.code,
      searchTextBuilder: _searchText,
    );
    if (!mounted || selected == null) return;
    await _openDetail(selected.loadingOrderId);
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
                title: 'Loading',
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
                    _LoadingOrderList(
                      query: const LogisticListQuery(tab: 'open'),
                      onOpenDetail: _openDetail,
                    ),
                    _LoadingOrderList(
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

String _searchText(LogisticLoadingOrder order) {
  return [
    order.code,
    order.sourceWarehouseName ?? '',
    order.destinationWarehouseName ?? '',
    order.statusLabel ?? order.status,
    order.sourceType,
  ].join(' ');
}

class _LoadingOrderList extends ConsumerWidget {
  const _LoadingOrderList({required this.query, required this.onOpenDetail});

  final LogisticListQuery query;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(loadingOrdersProvider(query));
    final syncStates =
        ref.watch(logisticSyncStateByResourceProvider('loading')).valueOrNull ??
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
        onRetry: () => ref.invalidate(loadingOrdersProvider(query)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(loadingOrdersProvider(query).future),
            child: const EmptyView(message: 'Data loading belum tersedia.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(loadingOrdersProvider(query).future),
          child: DeliveryOrderList(
            items: items
                .map(
                  (order) => _deliveryOrderData(
                    order,
                    syncState: syncStates[order.loadingOrderId],
                  ),
                )
                .toList(growable: false),
            onItemTap: (item) => onOpenDetail(item.deliveryOrderId),
          ),
        );
      },
    );
  }

  DeliveryOrderData _deliveryOrderData(
    LogisticLoadingOrder order, {
    String? syncState,
  }) {
    return DeliveryOrderData(
      deliveryOrderId: order.loadingOrderId,
      documentNumber: order.code,
      source: order.sourceWarehouseName ?? '-',
      sourceLabel: order.destinationWarehouseName ?? '-',
      status: order.statusLabel ?? order.status,
      orderType: order.sourceType,
      syncState: syncState,
    );
  }
}

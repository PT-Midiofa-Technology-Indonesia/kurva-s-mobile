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

class OutboundPage extends ConsumerStatefulWidget {
  const OutboundPage({super.key});

  @override
  ConsumerState<OutboundPage> createState() => _OutboundPageState();
}

class _OutboundPageState extends ConsumerState<OutboundPage> {
  var _selectedTabIndex = 0;

  Future<void> _openDetail(String deliveryOrderId) async {
    final didSubmit = await context.push<bool>(
      RouteNames.outboundDetail,
      extra: deliveryOrderId,
    );
    if (!mounted || didSubmit != true) return;

    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    await Future.wait([
      ref.refresh(
        outboundOrdersProvider(const LogisticListQuery(tab: 'open')).future,
      ),
      ref.refresh(
        outboundOrdersProvider(const LogisticListQuery(tab: 'close')).future,
      ),
    ]);
  }

  Future<void> _showSearch() async {
    final query = LogisticListQuery(
      tab: _selectedTabIndex == 0 ? 'open' : 'close',
    );
    final ordersState = ref.read(outboundOrdersProvider(query));
    final orders = ordersState.valueOrNull ?? const <LogisticDeliveryOrder>[];

    if (orders.isEmpty) {
      AppToast.info(
        context,
        ordersState.isLoading
            ? 'Daftar outbound sedang dimuat.'
            : 'Data outbound belum tersedia.',
      );
      return;
    }

    final selectedOrder =
        await FullPageSearchBottomSheet.show<LogisticDeliveryOrder>(
          context,
          title: 'Pencarian',
          options: orders,
          labelBuilder: (order) => order.code.isEmpty ? '-' : order.code,
          searchTextBuilder: _searchText,
        );

    if (!mounted || selectedOrder == null) return;

    await _openDetail(selectedOrder.deliveryOrderId);
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
                title: 'Outbound',
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
                    _OutboundOrderList(
                      query: const LogisticListQuery(tab: 'open'),
                      onOpenDetail: _openDetail,
                    ),
                    _OutboundOrderList(
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

String _searchText(LogisticDeliveryOrder order) {
  return [
    order.code,
    order.sourceWarehouseName ?? '',
    order.destinationWarehouseName ?? '',
    order.carrier ?? '',
    order.resi ?? '',
    order.status,
    order.statusLabel ?? '',
    order.sourceType,
  ].join(' ');
}

class _OutboundOrderList extends ConsumerWidget {
  const _OutboundOrderList({required this.query, required this.onOpenDetail});

  final LogisticListQuery query;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(outboundOrdersProvider(query));
    final syncStates =
        ref.watch(logisticSyncStateByDeliveryOrderProvider).valueOrNull ??
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
        onRetry: () => ref.invalidate(outboundOrdersProvider(query)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(outboundOrdersProvider(query).future),
            child: const EmptyView(message: 'Data outbound belum tersedia.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(outboundOrdersProvider(query).future),
          child: DeliveryOrderList(
            items: items
                .map(
                  (order) => _deliveryOrderData(
                    order,
                    syncState: syncStates[order.deliveryOrderId],
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
    LogisticDeliveryOrder order, {
    String? syncState,
  }) {
    return DeliveryOrderData(
      deliveryOrderId: order.deliveryOrderId,
      documentNumber: order.code,
      source: order.sourceWarehouseName ?? order.carrier ?? '-',
      sourceLabel: order.destinationWarehouseName ?? '-',
      status: order.statusLabel ?? order.status,
      orderType: order.sourceType,
      syncState: syncState,
    );
  }
}

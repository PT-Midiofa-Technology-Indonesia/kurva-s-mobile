import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:curva_mobile/core/constants/route_names.dart';
import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/modules/logistic/data/models/logistic_models.dart';
import 'package:curva_mobile/modules/logistic/logistic_providers.dart';
import 'package:curva_mobile/modules/logistic/presentation/widgets/logistic_widgets.dart';
import 'package:curva_mobile/shared/widgets/app_header.dart';
import 'package:curva_mobile/shared/widgets/app_skeleton.dart';
import 'package:curva_mobile/shared/widgets/app_toast.dart';
import 'package:curva_mobile/shared/widgets/empty_view.dart';
import 'package:curva_mobile/shared/widgets/network_aware_error_view.dart';
import 'package:curva_mobile/shared/widgets/full_page_search_bottom_sheet.dart';

class InboundPage extends ConsumerStatefulWidget {
  const InboundPage({super.key});

  @override
  ConsumerState<InboundPage> createState() => _InboundPageState();
}

class _InboundPageState extends ConsumerState<InboundPage> {
  var _selectedTabIndex = 0;

  Future<void> _openDetail(String deliveryOrderId) async {
    final didSubmit = await context.push<bool>(
      RouteNames.inboundDetail,
      extra: deliveryOrderId,
    );
    if (!mounted || didSubmit != true) return;

    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    await Future.wait([
      ref.refresh(
        inboundOrdersProvider(const LogisticListQuery(tab: 'open')).future,
      ),
      ref.refresh(
        inboundOrdersProvider(const LogisticListQuery(tab: 'close')).future,
      ),
    ]);
  }

  Future<void> _showSearch() async {
    final query = LogisticListQuery(
      tab: _selectedTabIndex == 0 ? 'open' : 'close',
    );
    final ordersState = ref.read(inboundOrdersProvider(query));
    final orders = ordersState.valueOrNull ?? const <LogisticDeliveryOrder>[];

    if (orders.isEmpty) {
      AppToast.info(
        context,
        ordersState.isLoading
            ? 'Daftar inbound sedang dimuat.'
            : 'Data inbound belum tersedia.',
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
                title: 'Inbound',
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
                    _InboundOrderList(
                      query: const LogisticListQuery(tab: 'open'),
                      onOpenDetail: _openDetail,
                    ),
                    _InboundOrderList(
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

class _InboundOrderList extends ConsumerWidget {
  const _InboundOrderList({required this.query, required this.onOpenDetail});

  final LogisticListQuery query;
  final ValueChanged<String> onOpenDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(inboundOrdersProvider(query));
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
        onRetry: () => ref.invalidate(inboundOrdersProvider(query)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(inboundOrdersProvider(query).future),
            child: const EmptyView(message: 'Data inbound belum tersedia.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(inboundOrdersProvider(query).future),
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
    final sourceWarehouse = order.sourceWarehouseName;
    final destinationWarehouse = order.destinationWarehouseName;
    final source = sourceWarehouse?.isNotEmpty == true
        ? sourceWarehouse!
        : order.carrier ?? '-';

    return DeliveryOrderData(
      deliveryOrderId: order.deliveryOrderId,
      documentNumber: order.code,
      source: source,
      sourceLabel: destinationWarehouse ?? '-',
      status: order.statusLabel ?? order.status,
      orderType: order.sourceType,
      syncState: syncState,
    );
  }
}

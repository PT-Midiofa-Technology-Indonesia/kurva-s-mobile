import 'package:flutter/material.dart';

import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/modules/logistic/presentation/widgets/delivery_order_card.dart';
import 'package:curva_mobile/modules/logistic/presentation/widgets/delivery_order_data.dart';

class DeliveryOrderList extends StatelessWidget {
  const DeliveryOrderList({super.key, required this.items, this.onItemTap});

  final List<DeliveryOrderData> items;
  final ValueChanged<DeliveryOrderData>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = items[index];

        return DeliveryOrderCard(
          item: item,
          onTap: onItemTap == null ? null : () => onItemTap!(item),
        );
      },
    );
  }
}

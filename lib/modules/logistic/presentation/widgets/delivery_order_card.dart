import 'package:flutter/material.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';
import 'package:curva_mobile/modules/logistic/presentation/widgets/delivery_order_data.dart';
import 'package:curva_mobile/modules/logistic/presentation/widgets/delivery_order_field.dart';

class DeliveryOrderCard extends StatelessWidget {
  const DeliveryOrderCard({super.key, required this.item, this.onTap});

  final DeliveryOrderData item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 128,
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.documentNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontFamily: AppFonts.geist,
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, thickness: 1, color: AppColors.line),
                const SizedBox(height: 11),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DeliveryOrderField(
                        title: item.source,
                        subtitle: item.sourceLabel,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DeliveryOrderField(
                        title: _syncLabel(item.syncState) ?? item.status,
                        subtitle: item.orderType,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        textAlign: TextAlign.right,
                        titleColor: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _syncLabel(String? state) => switch (state) {
  'pending' => 'Menunggu sinkronisasi',
  'processing' => 'Sedang disinkronkan',
  'retry' => 'Menunggu sinkronisasi',
  'failed' => 'Gagal disinkronkan',
  'conflict' => 'Perlu ditinjau',
  _ => null,
};

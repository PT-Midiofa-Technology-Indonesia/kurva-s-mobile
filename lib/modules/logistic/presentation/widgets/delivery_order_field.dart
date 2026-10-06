import 'package:flutter/material.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';

class DeliveryOrderField extends StatelessWidget {
  const DeliveryOrderField({
    super.key,
    required this.title,
    required this.subtitle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.textAlign = TextAlign.left,
    this.titleColor = AppColors.ink,
  });

  final String title;
  final String subtitle;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign textAlign;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: TextStyle(
            color: titleColor,
            fontFamily: titleColor == AppColors.ink
                ? AppFonts.inter
                : AppFonts.geist,
            fontSize: 14,
            height: 1.43,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: const TextStyle(
            color: AppColors.muted,
            fontFamily: AppFonts.geist,
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

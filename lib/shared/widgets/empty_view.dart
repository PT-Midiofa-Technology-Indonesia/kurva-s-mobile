import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/asset_paths.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.message,
    this.title = 'Belum Ada Data',
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            constraints.hasBoundedHeight
                ? (constraints.maxHeight * 0.28).clamp(96.0, 220.0)
                : AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AssetPaths.projectTaskEmpty,
                width: 128,
                height: 128,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.dashboardTeal,
                  fontFamily: AppFonts.inter,
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontFamily: AppFonts.inter,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        );

        if (!constraints.hasBoundedHeight) {
          return Align(alignment: Alignment.center, child: content);
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: Align(alignment: Alignment.topCenter, child: content),
          ),
        );
      },
    );
  }
}

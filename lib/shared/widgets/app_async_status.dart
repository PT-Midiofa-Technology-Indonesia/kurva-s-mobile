import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

enum AppAsyncStatusType { loading, error, info }

class AppAsyncStatus extends StatelessWidget {
  const AppAsyncStatus({
    required this.message,
    this.type = AppAsyncStatusType.loading,
    this.onRetry,
    super.key,
  });

  final String message;
  final AppAsyncStatusType type;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isError = type == AppAsyncStatusType.error;
    final foreground = isError ? AppColors.rose : AppColors.dashboardTeal;
    final background = isError
        ? AppColors.toastDangerBackground
        : AppColors.workforceIconBackground;

    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: foreground.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            if (type == AppAsyncStatusType.loading)
              SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            else
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
                size: 20,
                color: foreground,
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foreground,
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: AppSpacing.sm),
              TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
            ],
          ],
        ),
      ),
    );
  }
}

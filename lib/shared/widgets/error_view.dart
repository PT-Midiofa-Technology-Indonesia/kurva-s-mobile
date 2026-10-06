import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/asset_paths.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    this.message,
    this.title = 'Terjadi kesalahan',
    this.onRetry,
    this.retryLabel = 'Coba kembali',
    super.key,
  });

  static const _defaultMessage =
      'Gagal memuat halaman. Periksa koneksi Anda dan coba lagi.';

  final String? message;
  final String title;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final description = _resolvedMessage(message);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final maxHeight = hasBoundedHeight ? constraints.maxHeight : 520.0;
        final compact = hasBoundedHeight && maxHeight < 320;
        final imageSize = compact ? 64.0 : 124.0;
        final horizontalPadding = compact ? AppSpacing.md : AppSpacing.xl;
        final verticalPadding = compact ? AppSpacing.md : AppSpacing.lg;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: hasBoundedHeight ? constraints.maxHeight : 0,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AssetPaths.lostConnection,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style:
                            (compact
                                    ? textTheme.titleSmall
                                    : textTheme.titleLarge)
                                ?.copyWith(
                                  color: AppColors.loginTeal,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style:
                            (compact
                                    ? textTheme.labelSmall
                                    : textTheme.bodyMedium)
                                ?.copyWith(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w400,
                                  height: 1.35,
                                ),
                      ),
                      if (onRetry != null) ...[
                        SizedBox(
                          height: compact ? AppSpacing.md : AppSpacing.xl,
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.errorBackground,
                            foregroundColor: AppColors.ink,
                            elevation: 0,
                            minimumSize: Size(compact ? 156 : 224, 56),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            textStyle: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: onRetry,
                          child: Text(retryLabel),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _resolvedMessage(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || _isTechnicalMessage(trimmed)) {
      return _defaultMessage;
    }

    return trimmed;
  }

  bool _isTechnicalMessage(String value) {
    final lower = value.toLowerCase();
    return lower.contains('exception') ||
        lower.contains('requestoptions') ||
        lower.contains('receivetimeout') ||
        lower.contains('socketexception') ||
        lower.contains('dioexception') ||
        lower.contains('stack trace') ||
        lower.contains('0:00:') ||
        lower.contains('null check operator');
  }
}

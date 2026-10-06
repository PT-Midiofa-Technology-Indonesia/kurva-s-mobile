import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

enum AppButtonVariant { primary, danger, outlined }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = true,
    this.height = 48,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = AppRadius.md,
    this.elevation = 0,
    this.shadowColor,
    this.textStyle,
    this.padding,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool fullWidth;
  final double height;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double elevation;
  final Color? shadowColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isOutlined = variant == AppButtonVariant.outlined;
    final resolvedBackgroundColor =
        backgroundColor ??
        switch (variant) {
          AppButtonVariant.primary => AppColors.loginTeal,
          AppButtonVariant.danger => AppColors.rose,
          AppButtonVariant.outlined => AppColors.transparent,
        };
    final resolvedForegroundColor =
        textStyle?.color ??
        (isOutlined ? AppColors.loginTeal : AppColors.white);
    final child = Semantics(
      liveRegion: isLoading,
      label: isLoading ? '$label, sedang diproses' : label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) ...[
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: resolvedForegroundColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(label, maxLines: 1, softWrap: false)),
        ],
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );
    final callback = isLoading ? null : onPressed;
    final button = isOutlined
        ? OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: resolvedForegroundColor,
              side: BorderSide(color: borderColor ?? resolvedForegroundColor),
              padding: padding,
              shape: shape,
              textStyle: textStyle,
            ),
            onPressed: callback,
            child: child,
          )
        : FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: resolvedBackgroundColor,
              foregroundColor: resolvedForegroundColor,
              elevation: elevation,
              shadowColor: shadowColor,
              padding: padding,
              shape: shape,
              textStyle: textStyle,
            ),
            onPressed: callback,
            child: child,
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: button,
    );
  }
}

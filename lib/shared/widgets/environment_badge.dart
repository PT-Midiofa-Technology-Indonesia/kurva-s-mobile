import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_spacing.dart';

/// Global overlay, kept above the navigator and its dialogs.
class EnvironmentBadge extends StatelessWidget {
  const EnvironmentBadge({super.key, required this.flavor});

  final String? flavor;

  @override
  Widget build(BuildContext context) {
    final label = switch (flavor) {
      'staging' => 'STAG',
      'demo' => 'DEMO',
      _ => null,
    };
    if (label == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.xs),
          child: Align(
            alignment: Alignment.topRight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Match the native launcher badges in each flavor's
                // res/drawable/environment_badge.xml.
                color: flavor == 'demo'
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFFB45309),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 1,
                    color: AppColors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

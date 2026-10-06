import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_spacing.dart';

class InputPickerField extends StatelessWidget {
  const InputPickerField({
    required this.label,
    required this.value,
    this.isRequired = false,
    this.isLoading = false,
    this.loadingText = 'Memuat...',
    this.errorText,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final bool isRequired;
  final bool isLoading;
  final String loadingText;
  final String? errorText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    final hasError = errorText?.isNotEmpty ?? false;
    final borderColor = hasError ? AppColors.error : AppColors.line;

    return Semantics(
      button: true,
      enabled: onTap != null && !isLoading,
      liveRegion: isLoading,
      label: isLoading ? '$label, $loadingText' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.white,
            child: InkWell(
              onTap: isLoading ? null : onTap,
              child: Ink(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _FieldLabel(
                                label: label,
                                isRequired: isRequired,
                                hasValue: hasValue,
                                hasError: hasError,
                              ),
                            ),
                            if (isLoading) ...[
                              const SizedBox(width: AppSpacing.sm),
                              const SizedBox.square(
                                dimension: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  loadingText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontFamily: AppFonts.inter,
                                    fontSize: 12,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (hasValue) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontFamily: AppFonts.inter,
                                    fontSize: 16,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Visibility(
                                visible: !isLoading,
                                maintainAnimation: true,
                                maintainSize: true,
                                maintainState: true,
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.ink,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Text(
                errorText!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.isRequired,
    required this.hasValue,
    required this.hasError,
  });

  final String label;
  final bool isRequired;
  final bool hasValue;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          color: hasError ? AppColors.error : AppColors.muted,
          fontFamily: AppFonts.inter,
          fontSize: hasValue ? 14 : 16,
          height: hasValue ? 1.43 : 1.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        children: [
          TextSpan(text: label),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.rose),
            ),
        ],
      ),
    );
  }
}

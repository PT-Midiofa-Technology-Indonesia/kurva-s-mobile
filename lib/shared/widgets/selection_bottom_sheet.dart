import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

class SelectionBottomSheet<T> extends StatelessWidget {
  const SelectionBottomSheet({
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.labelBuilder,
    super.key,
  });

  final String title;
  final List<T> options;
  final T? selectedOption;
  final String Function(T option) labelBuilder;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T? selectedOption,
    required String Function(T option) labelBuilder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => SelectionBottomSheet<T>(
        title: title,
        options: options,
        selectedOption: selectedOption,
        labelBuilder: labelBuilder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SelectionHeader(title: title),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return _SelectionOption(
                    label: labelBuilder(option),
                    selected: selectedOption == option,
                    onTap: () => Navigator.of(context).pop(option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontFamily: AppFonts.inter,
                fontSize: 18,
                height: 1.3,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            height: 56,
            child: IconButton(
              tooltip: 'Tutup',
              padding: EdgeInsets.zero,
              color: AppColors.dashboardTeal,
              icon: const Icon(Icons.close, size: 36),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionOption extends StatelessWidget {
  const _SelectionOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: 56,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontFamily: AppFonts.inter,
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.md),
                  const _SelectedOptionIcon(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedOptionIcon extends StatelessWidget {
  const _SelectedOptionIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.dashboardTeal,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Icon(Icons.check, color: AppColors.white, size: 16),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

class SearchableSelectionBottomSheet<T> extends StatefulWidget {
  const SearchableSelectionBottomSheet({
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.labelBuilder,
    this.initialQuery = '',
    super.key,
  });

  final String title;
  final List<T> options;
  final T? selectedOption;
  final String Function(T option) labelBuilder;
  final String initialQuery;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T? selectedOption,
    required String Function(T option) labelBuilder,
    String initialQuery = '',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => SearchableSelectionBottomSheet<T>(
        title: title,
        options: options,
        selectedOption: selectedOption,
        labelBuilder: labelBuilder,
        initialQuery: initialQuery,
      ),
    );
  }

  @override
  State<SearchableSelectionBottomSheet<T>> createState() =>
      _SearchableSelectionBottomSheetState<T>();
}

class _SearchableSelectionBottomSheetState<T>
    extends State<SearchableSelectionBottomSheet<T>> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery;
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {
      _query = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.65;
    final filteredOptions = widget.options.where((option) {
      final label = widget.labelBuilder(option).toLowerCase();
      return label.contains(_query.trim().toLowerCase());
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _SearchableSelectionHeader(title: widget.title),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: _SelectionSearchField(controller: _searchController),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredOptions.length,
                  itemBuilder: (context, index) {
                    final option = filteredOptions[index];
                    return _SearchableSelectionOption(
                      label: widget.labelBuilder(option),
                      selected: widget.selectedOption == option,
                      onTap: () => Navigator.of(context).pop(option),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchableSelectionHeader extends StatelessWidget {
  const _SearchableSelectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: IconButton(
              tooltip: 'Kembali',
              padding: EdgeInsets.zero,
              color: AppColors.dashboardTeal,
              icon: const Icon(Icons.arrow_back, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: Text(
              title,
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
          const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }
}

class _SelectionSearchField extends StatelessWidget {
  const _SelectionSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        cursorColor: AppColors.dashboardTeal,
        style: const TextStyle(
          color: AppColors.ink,
          fontFamily: AppFonts.inter,
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColors.ink, size: 32),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.dashboardTeal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.dashboardTeal),
          ),
        ),
      ),
    );
  }
}

class _SearchableSelectionOption extends StatelessWidget {
  const _SearchableSelectionOption({
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

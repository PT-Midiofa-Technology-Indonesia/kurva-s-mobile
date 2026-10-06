import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import 'empty_view.dart';

class FullPageSearchBottomSheet<T> extends StatefulWidget {
  const FullPageSearchBottomSheet({
    required this.title,
    required this.options,
    required this.labelBuilder,
    this.searchTextBuilder,
    this.initialQuery = '',
    this.emptyMessage = 'Data tidak ditemukan.',
    super.key,
  });

  final String title;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final String Function(T option)? searchTextBuilder;
  final String initialQuery;
  final String emptyMessage;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required String Function(T option) labelBuilder,
    String Function(T option)? searchTextBuilder,
    String initialQuery = '',
    String emptyMessage = 'Data tidak ditemukan.',
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => FullPageSearchBottomSheet<T>(
        title: title,
        options: options,
        labelBuilder: labelBuilder,
        searchTextBuilder: searchTextBuilder,
        initialQuery: initialQuery,
        emptyMessage: emptyMessage,
      ),
    );
  }

  @override
  State<FullPageSearchBottomSheet<T>> createState() =>
      _FullPageSearchBottomSheetState<T>();
}

class _FullPageSearchBottomSheetState<T>
    extends State<FullPageSearchBottomSheet<T>> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchController = TextEditingController(text: widget.initialQuery)
      ..addListener(_handleSearchChanged);
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
    final filteredOptions = _filteredOptions();

    return Container(
      height: MediaQuery.sizeOf(context).height,
      color: AppColors.white,
      child: Column(
        children: [
          _FullPageSearchHeader(title: widget.title),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: _FullPageSearchField(controller: _searchController),
          ),
          Expanded(
            child: filteredOptions.isEmpty
                ? EmptyView(
                    title: 'Hasil Tidak Ditemukan',
                    message: widget.emptyMessage,
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: filteredOptions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.line),
                    itemBuilder: (context, index) {
                      final option = filteredOptions[index];
                      return _FullPageSearchOption(
                        label: widget.labelBuilder(option),
                        onTap: () => Navigator.of(context).pop(option),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<T> _filteredOptions() {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.options;

    return widget.options
        .where((option) {
          final searchableText =
              widget.searchTextBuilder?.call(option) ??
              widget.labelBuilder(option);
          return searchableText.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }
}

class _FullPageSearchHeader extends StatelessWidget {
  const _FullPageSearchHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
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

class _FullPageSearchField extends StatelessWidget {
  const _FullPageSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        autofocus: true,
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
            borderSide: const BorderSide(
              color: AppColors.dashboardTeal,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(
              color: AppColors.dashboardTeal,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _FullPageSearchOption extends StatelessWidget {
  const _FullPageSearchOption({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
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
          ),
        ),
      ),
    );
  }
}

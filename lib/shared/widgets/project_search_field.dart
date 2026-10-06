import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

class ProjectSearchField extends StatelessWidget {
  const ProjectSearchField({
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.hintText = 'Cari nama...',
    this.autofocus = true,
    this.height = 104,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 24),
    this.hasBottomBorder = false,
    this.fontSize = 16,
    this.textHeight = 1.5,
    this.borderWidth = 1,
    this.prefixIconMinWidth = 58,
    this.prefixIconMinHeight = 56,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final bool autofocus;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool hasBottomBorder;
  final double fontSize;
  final double textHeight;
  final double borderWidth;
  final double prefixIconMinWidth;
  final double prefixIconMinHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: hasBottomBorder
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        onChanged: onChanged,
        cursorColor: AppColors.ink,
        style: TextStyle(
          color: AppColors.ink,
          fontFamily: AppFonts.inter,
          fontSize: fontSize,
          height: textHeight,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.inputBorder,
            fontFamily: AppFonts.inter,
            fontSize: fontSize,
            height: textHeight,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.black,
            size: 30,
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: prefixIconMinWidth,
            minHeight: prefixIconMinHeight,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          enabledBorder: _border(),
          focusedBorder: _border(),
        ),
      ),
    );
  }

  OutlineInputBorder _border() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(
        color: AppColors.dashboardTeal,
        width: borderWidth,
      ),
    );
  }
}

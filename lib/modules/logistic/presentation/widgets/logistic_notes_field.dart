import 'package:flutter/material.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';

class LogisticNotesField extends StatelessWidget {
  const LogisticNotesField({
    required this.controller,
    required this.hintText,
    this.label = 'Catatan',
    this.minLines = 1,
    this.maxLines = 4,
    this.readOnly = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int minLines;
  final int maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line, width: 1.5)),
      ),
      child: TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        readOnly: readOnly,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
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
          labelText: label,
          hintText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          labelStyle: const TextStyle(
            color: AppColors.muted,
            fontFamily: AppFonts.inter,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.muted,
            fontFamily: AppFonts.inter,
            // InputDecoration scales floating labels by 0.75. This keeps the
            // rendered floating label at 14px, matching InputMultilineTextField.
            fontSize: 18.67,
            height: 1.43,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
          hintStyle: const TextStyle(
            color: AppColors.inputBorder,
            fontFamily: AppFonts.inter,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

class InputMultilineWithBorder extends StatelessWidget {
  const InputMultilineWithBorder({
    this.controller,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.height = 136,
    this.borderRadius = AppRadius.md,
    this.borderColor = AppColors.inputBorder,
    this.focusedBorderColor = AppColors.dashboardTeal,
    this.errorBorderColor = AppColors.error,
    this.cursorColor = AppColors.dashboardTeal,
    this.textStyle = _defaultTextStyle,
    this.hintStyle = _defaultHintStyle,
    this.onChanged,
    super.key,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final bool enabled;
  final double height;
  final double borderRadius;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color errorBorderColor;
  final Color cursorColor;
  final TextStyle textStyle;
  final TextStyle hintStyle;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      borderSide: BorderSide(color: borderColor),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      borderSide: BorderSide(color: focusedBorderColor, width: 2),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      borderSide: BorderSide(color: errorBorderColor),
    );

    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        cursorColor: cursorColor,
        style: textStyle,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          border: enabledBorder,
          enabledBorder: enabledBorder,
          focusedBorder: focusedBorder,
          disabledBorder: enabledBorder,
          errorBorder: errorBorder,
          focusedErrorBorder: errorBorder,
          hintText: hintText,
          hintStyle: hintStyle,
          errorText: errorText,
        ),
      ),
    );
  }
}

const TextStyle _defaultTextStyle = TextStyle(
  color: AppColors.ink,
  fontFamily: AppFonts.inter,
  fontSize: 14,
  height: 1.43,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
);

const TextStyle _defaultHintStyle = TextStyle(
  color: AppColors.inputBorder,
  fontFamily: AppFonts.inter,
  fontSize: 14,
  height: 1.43,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
);

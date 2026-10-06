import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../shared/widgets/app_text_field.dart';

class LoginInput extends StatelessWidget {
  const LoginInput({
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText,
    super.key,
  });

  static const height = 56.0;
  static const _errorGap = 6.0;

  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText?.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          height: height,
          controller: controller,
          hintText: hintText,
          keyboardType: keyboardType,
          obscureText: obscureText,
          suffixIcon: suffixIcon,
          hasError: hasError,
        ),
        if (hasError) ...[
          const SizedBox(height: _errorGap),
          Text(
            errorText!,
            style: const TextStyle(
              fontFamily: AppFonts.geist,
              color: AppColors.error,
              fontSize: 14,
              height: 1.43,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

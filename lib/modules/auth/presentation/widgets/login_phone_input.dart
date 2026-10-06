import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_text_field.dart';
import 'login_phone_prefix.dart';

class LoginPhoneInput extends StatelessWidget {
  const LoginPhoneInput({required this.controller, this.errorText, super.key});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText?.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          height: 56,
          controller: controller,
          keyboardType: TextInputType.phone,
          hintText: 'Nomor Telepon',
          hasError: hasError,
          prefixIcon: const SizedBox(
            width: 80,
            height: 56,
            child: Padding(
              padding: EdgeInsets.only(left: AppSpacing.sm, right: 12),
              child: Center(child: LoginPhonePrefix()),
            ),
          ),
          prefixIconConstraints: const BoxConstraints.tightFor(
            width: 80,
            height: 56,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
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

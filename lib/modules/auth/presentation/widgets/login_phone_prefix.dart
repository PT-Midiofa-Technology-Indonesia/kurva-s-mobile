import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_radius.dart';

class LoginPhonePrefix extends StatelessWidget {
  const LoginPhonePrefix({super.key});

  static const _inter = AppFonts.geist;
  static const height = 40.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: AppColors.softShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        '+62',
        style: TextStyle(
          fontFamily: _inter,
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

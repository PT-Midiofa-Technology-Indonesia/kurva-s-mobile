import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import '../core/constants/app_radius.dart';
import '../core/constants/app_spacing.dart';

class AppTheme {
  const AppTheme._();

  static const _fontFamily = AppFonts.inter;

  // App surfaces behind the system bars are light, including in OS dark mode.
  // Flutter 3.47 guards legacy color setters on Android 15+. Transparency is
  // still needed on older Android versions when enabling edge-to-edge.
  static const systemUiOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.loginTeal,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.loginTeal,
          onPrimary: AppColors.white,
          secondary: AppColors.dashboardTeal,
          onSecondary: AppColors.white,
          error: AppColors.error,
          onError: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.ink,
          outline: AppColors.inputBorder,
          outlineVariant: AppColors.line,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: AppColors.white,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: systemUiOverlayStyle,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontFamily: _fontFamily,
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(color: AppColors.dashboardTeal),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.loginTeal,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.inputBorder,
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: _textTheme.bodyLarge?.copyWith(color: AppColors.inputBorder),
        labelStyle: _textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        errorStyle: _textTheme.bodySmall?.copyWith(color: AppColors.error),
        enabledBorder: _inputBorder(AppColors.inputBorder),
        focusedBorder: _inputBorder(AppColors.loginTeal, width: 2),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 2),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.loginTeal,
      ),
    );
  }

  static const _textTheme = TextTheme(
    displayLarge: TextStyle(
      color: AppColors.ink,
      fontFamily: _fontFamily,
      fontSize: 40,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      color: AppColors.ink,
      fontFamily: _fontFamily,
      fontSize: 24,
      height: 1.33,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      color: AppColors.ink,
      fontFamily: _fontFamily,
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      color: AppColors.ink,
      fontFamily: _fontFamily,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      color: AppColors.ink,
      fontFamily: _fontFamily,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    bodyMedium: TextStyle(
      color: AppColors.muted,
      fontFamily: _fontFamily,
      fontSize: 14,
      height: 1.43,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
    labelLarge: TextStyle(
      color: AppColors.white,
      fontFamily: _fontFamily,
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    ),
    labelMedium: TextStyle(
      color: AppColors.secondaryText,
      fontFamily: _fontFamily,
      fontSize: 14,
      height: 1.43,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    bodySmall: TextStyle(
      color: AppColors.muted,
      fontFamily: _fontFamily,
      fontSize: 12,
      height: 1.33,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    ),
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

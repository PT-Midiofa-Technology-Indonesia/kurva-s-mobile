import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const white = Color(0xFFFFFFFF);
  static const transparent = Color(0x00000000);
  static const black = Color(0xFF000000);

  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF4B5563);
  static const secondaryText = Color(0xFF6B7280);

  static const dashboardTeal = Color(0xFF01AAA7);
  static const loginTeal = Color(0xFF0EAAA7);
  static const line = Color(0xFFE5E7EB);
  static const softLine = Color(0xFFD1D5DB);
  static const bottomBarBorder = Color(0xFFECECEC);
  static const rose = Color(0xFFF83F63);
  static const orange = Color(0xFFFF6B16);
  static const pendingApproval = Color(0xFFF97316);
  static const green = Color(0xFF10B981);

  static const inputBorder = Color(0xFF9CA3AF);
  static const error = Color(0xFFF43F5E);
  static const tabBackground = Color(0xFFF8FAFC);
  static const tabBorder = Color(0xFFE2E8F0);
  static const cardBackground = Color(0xFFF9FAFB);
  static const softShadow = Color(0x14000000);
  static const skeletonBase = Color(0xFFE5E7EB);
  static const skeletonHighlight = Color(0xFFF8FAFC);

  static const avatarGradientStart = Color(0xFF334155);
  static const avatarGradientEnd = Color(0xFFB98A62);
  static const attendanceGradientStart = Color(0xFFFFFCF5);
  static const attendanceGradientMiddle = Color(0xFFF6E9FF);
  static const attendanceGradientEnd = Color(0xFFF0EDFF);

  static const workforce = Color(0xFF7DD3FC);
  static const prospect = Color(0xFF86EFAC);
  static const project = Color(0xFFFBBF24);
  static const logistic = Color(0xFFF59E0B);
  static const inventory = Color(0xFF38BDF8);
  static const expense = Color(0xFFFACC15);
  static const successBadge = Color(0xFF7ED957);
  static const workforceIconBackground = Color(0xFFEFFEFC);
  static const workforceStatusInfo = Color(0xFF00AAA6);
  static const workforceStatusWarning = Color(0xFFFF6B16);
  static const workforceHeroStart = Color(0xFFFFFCF5);
  static const workforceHeroEnd = Color(0xFFF3EAFE);

  // Shared UI colors migrated from feature pages/widgets.
  static const overlayShadow = Color(0x33000000);
  static const selectionBackground = Color(0xFFEFFFFE);
  static const errorBackground = Color(0xFFF3F4F6);
  static const taskCardBorder = Color(0xFFE1E7EF);
  static const avatarPlaceholder = Color(0xFFE1E3E5);
  static const avatarPlaceholderIcon = Color(0xFFADB2B7);
  static const strongText = Color(0xFF19191B);
  static const slateBorder = Color(0xFFCBD5E1);
  static const infoBlue = Color(0xFF3B82F6);
  static const assigneePurple = Color(0xFF8356D8);
  static const assigneeGreen = Color(0xFF23864A);
  static const assigneeMagenta = Color(0xFFC84778);
  static const participantPurple = Color(0xFF805AD5);
  static const participantGreen = Color(0xFF25894A);
  static const participantMagenta = Color(0xFFC84470);
  static const prospectChipBackground = Color(0xFFEFFFFD);
  static const warningBackground = Color(0xFFFFF7ED);
  static const dangerBackground = Color(0xFFFFF1F5);
  static const toastSuccessBackground = Color(0xFFEFFDF7);
  static const toastDangerBackground = Color(0xFFFFF1F4);
  static const expenseText = Color(0xFF030712);
  static const attachmentBrown = Color(0xFFB9683F);
  static const attachmentTaupe = Color(0xFF80614C);
  static const attachmentCopper = Color(0xFFC36D44);
  static const attachmentDarkBrown = Color(0xFF9B4A2B);

  static Color fromHex(String value) {
    final normalized = value.trim().replaceFirst('#', '');
    if (normalized.length != 6 && normalized.length != 8) return transparent;
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return transparent;
    return Color(normalized.length == 6 ? 0xFF000000 | parsed : parsed);
  }
}

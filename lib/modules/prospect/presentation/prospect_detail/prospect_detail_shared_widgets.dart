import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';

const prospectDetailFontFamily = AppFonts.inter;
const prospectDetailSupportFontFamily = AppFonts.geist;
const prospectDetailAccentColor = AppColors.dashboardTeal;

class ProspectDetailUploadPlaceholder extends StatelessWidget {
  const ProspectDetailUploadPlaceholder({
    this.height = 80,
    this.showEmptyMessage = true,
    this.onAddPressed,
    super.key,
  });

  final double height;
  final bool showEmptyMessage;
  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const ProspectDetailDashedBorderPainter(
        color: AppColors.inputBorder,
        radius: AppRadius.md,
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showEmptyMessage) ...[
              const Text(
                'Belum ada data di unggah',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontFamily: prospectDetailFontFamily,
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: prospectDetailAccentColor,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
              ),
              onPressed: onAddPressed,
              child: const Text(
                '+ Tambah',
                style: TextStyle(
                  fontFamily: prospectDetailFontFamily,
                  fontSize: 14,
                  height: 1.43,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProspectDetailDashedBorderPainter extends CustomPainter {
  const ProspectDetailDashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + 6;
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance = nextDistance + 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ProspectDetailDashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class ProspectDetailEmptyTab extends StatelessWidget {
  const ProspectDetailEmptyTab({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontFamily: prospectDetailFontFamily,
          fontSize: 14,
          height: 1.43,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:curva_mobile/core/constants/app_colors.dart';
import 'package:curva_mobile/core/constants/app_fonts.dart';
import 'package:curva_mobile/core/constants/app_radius.dart';
import 'package:curva_mobile/core/constants/app_spacing.dart';

class DashedUploadAction extends StatelessWidget {
  const DashedUploadAction({
    required this.hasAttachments,
    this.onTap,
    super.key,
  });

  final bool hasAttachments;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          height: 96,
          width: double.infinity,
          child: CustomPaint(
            painter: _DashedBorderPainter(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!hasAttachments) ...[
                  const Text(
                    'Belum ada bukti di unggah',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontFamily: AppFonts.inter,
                      fontSize: 14,
                      height: 1.43,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Text(
                  hasAttachments ? '+ Tambah bukti' : '+ Tambah',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.dashboardTeal,
                    fontFamily: AppFonts.inter,
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final paint = Paint()
      ..color = AppColors.inputBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadius.md),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

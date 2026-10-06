import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class ProjectTargetIcon extends StatelessWidget {
  const ProjectTargetIcon({
    super.key,
    this.size = 18,
    this.color = AppColors.dashboardTeal,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ProjectTargetIconPainter(color)),
    );
  }
}

class _ProjectTargetIconPainter extends CustomPainter {
  const _ProjectTargetIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07;

    canvas.drawCircle(center, size.width * 0.43, paint);
    canvas.drawCircle(center, size.width * 0.23, paint);

    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.075, paint);
  }

  @override
  bool shouldRepaint(covariant _ProjectTargetIconPainter oldDelegate) =>
      color != oldDelegate.color;
}

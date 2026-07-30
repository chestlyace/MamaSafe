import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShapPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const ShapPainter({
    this.color = AppColors.primary,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final centerX = size.width / 2;
    final maxRadius = size.shortestSide / 2;

    for (double r = maxRadius; r > 0; r -= maxRadius / 3) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, size.height), radius: r),
        0,
        math.pi,
        false,
        paint,
      );
    }

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final dotRadius = strokeWidth * 1.8;

    for (double r = maxRadius; r > 0; r -= maxRadius / 3) {
      for (double angle = math.pi / 6; angle < math.pi; angle += math.pi / 3) {
        final dx = centerX + r * math.cos(angle);
        final dy = size.height + r * math.sin(angle) - size.height;
        canvas.drawCircle(Offset(dx, size.height + dy), dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(ShapPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class ShapDecoration extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final Widget? child;
  final Alignment alignment;

  const ShapDecoration({
    super.key,
    this.color = AppColors.primary,
    this.strokeWidth = 1.5,
    this.child,
    this.alignment = Alignment.bottomCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: alignment,
            child: FractionallySizedBox(
              widthFactor: 1.2,
              heightFactor: 0.5,
              child: CustomPaint(
                painter: ShapPainter(color: color, strokeWidth: strokeWidth),
              ),
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

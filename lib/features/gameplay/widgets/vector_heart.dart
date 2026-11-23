import 'package:flutter/material.dart';

/// Smooth, mathematical cubic-Bézier vector heart widget.
/// Zero pixelation on any screen resolution, completely independent of system fonts.
class VectorHeart extends StatelessWidget {
  final double size;
  final bool isFilled;
  final Color? color;

  const VectorHeart({
    super.key,
    this.size = 22,
    this.isFilled = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HeartPainter(
        isFilled: isFilled,
        color: color ?? (isFilled ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  final bool isFilled;
  final Color color;

  _HeartPainter({required this.isFilled, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = isFilled ? 0 : 2.0;

    final path = Path();
    // Mathematical smooth heart using cubic Béziers
    path.moveTo(w * 0.5, h * 0.85); // Bottom tip
    // Left lobe
    path.cubicTo(w * 0.15, h * 0.60, 0, h * 0.38, 0, h * 0.24);
    path.cubicTo(0, h * 0.08, w * 0.22, 0, w * 0.46, h * 0.12);
    path.cubicTo(w * 0.48, h * 0.13, w * 0.5, h * 0.17, w * 0.5, h * 0.17);
    // Right lobe
    path.cubicTo(w * 0.5, h * 0.17, w * 0.52, h * 0.13, w * 0.54, h * 0.12);
    path.cubicTo(w * 0.78, 0, w, h * 0.08, w, h * 0.24);
    path.cubicTo(w, h * 0.38, w * 0.85, h * 0.60, w * 0.5, h * 0.85);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) =>
      oldDelegate.isFilled != isFilled || oldDelegate.color != color;
}

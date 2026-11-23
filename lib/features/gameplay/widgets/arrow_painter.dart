import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../engine/arrow_direction.dart';
import '../engine/arrow_model.dart';
import '../engine/puzzle_board.dart';

/// Vector CustomPainter rendering snake-like polyline arrows with slithering exit animations.
class ArrowPainter extends CustomPainter {
  final PuzzleBoard board;
  final Map<String, double> exitProgress; // 0.0 -> 1.0
  final Map<String, double> shakeOffsets; // pixel offset
  final String? activeHintId;
  final String? activeBlockedId; // ID of arrow that blocked the move (flashes red)
  final List<GridPoint>? blockedRay;
  final bool isEyeComfortTheme;

  ArrowPainter({
    required this.board,
    this.exitProgress = const {},
    this.shakeOffsets = const {},
    this.activeHintId,
    this.activeBlockedId,
    this.blockedRay,
    this.isEyeComfortTheme = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boardSize = board.size;
    final cellSize = size.width / boardSize;

    // 1. Draw subtle dot grid
    _drawGrid(canvas, size, cellSize, boardSize);

    // 2. Draw blocked ray indication (if any)
    if (blockedRay != null && blockedRay!.isNotEmpty) {
      _drawBlockedRay(canvas, cellSize);
    }

    // 3. Draw All Snake Arrows
    for (final arrow in board.arrows.values) {
      final progress = exitProgress[arrow.id] ?? (arrow.isActive ? 0.0 : 1.0);
      if (progress >= 1.0) continue; // Fully exited off screen

      final shake = shakeOffsets[arrow.id] ?? 0.0;
      final isHinted = arrow.id == activeHintId || arrow.isHighlighted;
      final isShaking = arrow.isShaking || shake.abs() > 0.01;
      final isBlockingFlash = arrow.id == activeBlockedId;

      _drawSnakeArrow(
        canvas: canvas,
        arrow: arrow,
        cellSize: cellSize,
        boardSize: boardSize,
        progress: progress,
        shakeOffset: shake,
        isHinted: isHinted,
        isShaking: isShaking,
        isBlockingFlash: isBlockingFlash,
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size, double cellSize, int boardSize) {
    final dotColor = isEyeComfortTheme
        ? const Color(0xFFE2D6C5)
        : AppColors.gridLine.withOpacity(0.5);

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (int r = 0; r <= boardSize; r++) {
      for (int c = 0; c <= boardSize; c++) {
        canvas.drawCircle(
          Offset(c * cellSize, r * cellSize),
          1.1,
          dotPaint,
        );
      }
    }
  }

  void _drawBlockedRay(Canvas canvas, double cellSize) {
    final rayPaint = Paint()
      ..color = const Color(0x30EF4444)
      ..style = PaintingStyle.fill;

    for (final pt in blockedRay!) {
      final rect = Rect.fromLTWH(
        pt.col * cellSize + 2,
        pt.row * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rrect, rayPaint);
    }
  }

  void _drawSnakeArrow({
    required Canvas canvas,
    required ArrowModel arrow,
    required double cellSize,
    required int boardSize,
    required double progress,
    required double shakeOffset,
    required bool isHinted,
    required bool isShaking,
    required bool isBlockingFlash,
  }) {
    final points = arrow.allPoints;
    if (points.isEmpty) return;

    // Stroke width adapts gracefully to cell size
    final strokeWidth = math.max(3.5, cellSize * 0.22);

    // Color resolution
    Color strokeColor;
    if (isShaking || isBlockingFlash) {
      strokeColor = const Color(0xFFEF4444); // Vibrant Red for blocked feedback
    } else if (isHinted) {
      strokeColor = const Color(0xFFF59E0B); // Amber for hint
    } else if (isEyeComfortTheme) {
      strokeColor = const Color(0xFF3E2723); // Sepia / dark espresso ink
    } else {
      strokeColor = const Color(0xFF1E293B); // Deep slate / obsidian ink
    }

    canvas.save();

    // Blocked shake displacement (perpendicular to direction)
    double sx = 0.0;
    double sy = 0.0;
    if (arrow.direction == ArrowDirection.up || arrow.direction == ArrowDirection.down) {
      sx = shakeOffset;
    } else {
      sy = shakeOffset;
    }
    canvas.translate(sx, sy);

    if (progress <= 0.001) {
      // Static arrow on board
      _drawStaticSnake(canvas, arrow, points, cellSize, strokeWidth, strokeColor, isHinted);
    } else {
      // Slithering exit snake animation:
      // Head leads along exit ray, body follows through the original polyline!
      _drawSlitheringSnake(
        canvas: canvas,
        arrow: arrow,
        points: points,
        cellSize: cellSize,
        boardSize: boardSize,
        progress: progress,
        strokeWidth: strokeWidth,
        strokeColor: strokeColor,
      );
    }

    canvas.restore();
  }

  void _drawStaticSnake(
    Canvas canvas,
    ArrowModel arrow,
    List<GridPoint> points,
    double cellSize,
    double strokeWidth,
    Color strokeColor,
    bool isHinted,
  ) {
    // Hint Glow
    if (isHinted) {
      final glowPaint = Paint()
        ..color = const Color(0x66F59E0B)
        ..strokeWidth = strokeWidth * 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      _paintPolyline(canvas, points, cellSize, glowPaint);
    }

    final bodyPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw snake body polyline
    _paintPolyline(canvas, points, cellSize, bodyPaint);

    // Draw arrowhead at head
    final head = arrow.head;
    final hx = (head.col + 0.5) * cellSize;
    final hy = (head.row + 0.5) * cellSize;
    _paintArrowHead(canvas, Offset(hx, hy), arrow.direction.rotationAngle, strokeColor, cellSize);
  }

  void _drawSlitheringSnake({
    required Canvas canvas,
    required ArrowModel arrow,
    required List<GridPoint> points,
    required double cellSize,
    required int boardSize,
    required double progress,
    required double strokeWidth,
    required Color strokeColor,
  }) {
    // Build extended trajectory: [tail, ..., head, head + 1*dir, ..., head + exitLen*dir]
    final exitCells = boardSize + 2;
    final trajectory = <Offset>[];
    for (final pt in points) {
      trajectory.add(Offset((pt.col + 0.5) * cellSize, (pt.row + 0.5) * cellSize));
    }

    final last = trajectory.last;
    final dx = arrow.direction.dx * cellSize;
    final dy = arrow.direction.dy * cellSize;
    for (int i = 1; i <= exitCells; i++) {
      trajectory.add(Offset(last.dx + i * dx, last.dy + i * dy));
    }

    final bodySegCount = points.length - 1;

    // Total distance the snake must travel to fully exit
    final totalDistance = (bodySegCount + exitCells).toDouble();
    final dTraveled = progress * totalDistance;

    final sTail = dTraveled;
    final sHead = math.min(sTail + bodySegCount, totalDistance);

    if (sTail >= totalDistance) return; // Completely exited

    // Sample active polyline between sTail and sHead
    final activePoints = _sampleSubPolyline(trajectory, sTail, sHead);
    if (activePoints.length < 2) return;

    final opacity = (1.0 - progress * 0.8).clamp(0.0, 1.0);

    final bodyPaint = Paint()
      ..color = strokeColor.withOpacity(opacity)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(activePoints.first.dx, activePoints.first.dy);
    for (int i = 1; i < activePoints.length; i++) {
      path.lineTo(activePoints[i].dx, activePoints[i].dy);
    }
    canvas.drawPath(path, bodyPaint);

    // Arrowhead at active head
    final headPt = activePoints.last;
    final prevPt = activePoints[activePoints.length - 2];
    final angle = math.atan2(headPt.dy - prevPt.dy, headPt.dx - prevPt.dx) + math.pi / 2;

    _paintArrowHead(canvas, headPt, angle, strokeColor.withOpacity(opacity), cellSize);
  }

  List<Offset> _sampleSubPolyline(List<Offset> trajectory, double sStart, double sEnd) {
    final result = <Offset>[];

    // Clamped indices
    final iStart = sStart.floor().clamp(0, trajectory.length - 2);
    final fStart = sStart - iStart;
    final pStart = Offset.lerp(trajectory[iStart], trajectory[iStart + 1], fStart)!;
    result.add(pStart);

    final iEnd = sEnd.floor().clamp(0, trajectory.length - 2);
    final fEnd = sEnd - iEnd;

    for (int k = iStart + 1; k <= iEnd; k++) {
      result.add(trajectory[k]);
    }

    final pEnd = Offset.lerp(trajectory[iEnd], trajectory[iEnd + 1], fEnd)!;
    if (result.isEmpty || (result.last - pEnd).distance > 0.01) {
      result.add(pEnd);
    }

    return result;
  }

  void _paintPolyline(Canvas canvas, List<GridPoint> points, double cellSize, Paint paint) {
    if (points.length == 1) {
      final p = points.first;
      final c = Offset((p.col + 0.5) * cellSize, (p.row + 0.5) * cellSize);
      canvas.drawCircle(c, paint.strokeWidth * 0.6, paint);
      return;
    }

    final path = Path();
    final first = points.first;
    path.moveTo((first.col + 0.5) * cellSize, (first.row + 0.5) * cellSize);

    for (int i = 1; i < points.length; i++) {
      final pt = points[i];
      path.lineTo((pt.col + 0.5) * cellSize, (pt.row + 0.5) * cellSize);
    }

    canvas.drawPath(path, paint);
  }

  void _paintArrowHead(Canvas canvas, Offset position, double rotationAngle, Color color, double cellSize) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotationAngle);

    final headSize = math.max(6.5, cellSize * 0.38);
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Sleek geometric triangle arrowhead
    final path = Path()
      ..moveTo(0, -headSize) // Tip
      ..lineTo(-headSize * 0.72, headSize * 0.42)
      ..lineTo(0, 0.05 * headSize) // Inward notch
      ..lineTo(headSize * 0.72, headSize * 0.42)
      ..close();

    canvas.drawPath(path, fillPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) => true;
}

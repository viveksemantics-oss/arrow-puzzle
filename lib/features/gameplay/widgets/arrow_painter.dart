import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../engine/arrow_direction.dart';
import '../engine/arrow_model.dart';
import '../engine/puzzle_board.dart';

/// Vector CustomPainter rendering thin-line snake polylines with crisp arrowheads and slithering exits.
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
        : const Color(0xFFE2E8F0).withOpacity(0.65);

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (int r = 0; r <= boardSize; r++) {
      for (int c = 0; c <= boardSize; c++) {
        canvas.drawCircle(
          Offset(c * cellSize, r * cellSize),
          0.85,
          dotPaint,
        );
      }
    }
  }

  void _drawBlockedRay(Canvas canvas, double cellSize) {
    final rayPaint = Paint()
      ..color = const Color(0x28EF4444)
      ..style = PaintingStyle.fill;

    for (final pt in blockedRay!) {
      final rect = Rect.fromLTWH(
        pt.col * cellSize + 2,
        pt.row * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
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

    // A. LINE STYLE SPEC:
    // Stroke width = 14% of cell size (min 1.5 px, max 4 px on screen).
    final strokeWidth = (cellSize * 0.14).clamp(1.5, 4.0);

    // Ink color #1B1B2F on white board; #3E2723 for cream/brown theme
    Color strokeColor;
    if (isShaking || isBlockingFlash) {
      strokeColor = const Color(0xFFEF4444); // Red for blocked tap
    } else if (isHinted) {
      strokeColor = const Color(0xFFF59E0B); // Amber for hint
    } else if (isEyeComfortTheme) {
      strokeColor = const Color(0xFF3E2723); // Espresso ink
    } else {
      strokeColor = const Color(0xFF1B1B2F); // Obsidian ink
    }

    canvas.save();

    // Blocked shake displacement
    if (shakeOffset.abs() > 0.001) {
      if (arrow.direction == ArrowDirection.up || arrow.direction == ArrowDirection.down) {
        canvas.translate(shakeOffset, 0);
      } else {
        canvas.translate(0, shakeOffset);
      }
    }

    if (progress <= 0.001) {
      _drawStaticSnake(canvas, arrow, points, cellSize, strokeWidth, strokeColor, isHinted);
    } else {
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
        ..color = const Color(0x55F59E0B)
        ..strokeWidth = strokeWidth * 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      _paintPolyline(canvas, points, cellSize, glowPaint, roundHead: false);
    }

    final bodyPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt // Butt cap at head prevents any blob/protrusion
      ..strokeJoin = StrokeJoin.round // Smooth round joins at bends
      ..style = PaintingStyle.stroke;

    // Draw snake body polyline
    _paintPolyline(canvas, points, cellSize, bodyPaint, roundHead: false);

    // Draw clean round cap explicitly at the tail
    final tailPt = points.first;
    final tailCenter = Offset((tailPt.col + 0.5) * cellSize, (tailPt.row + 0.5) * cellSize);
    final tailPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(tailCenter, strokeWidth / 2, tailPaint);

    // Draw crisp arrowhead at head
    final head = arrow.head;
    final hx = (head.col + 0.5) * cellSize;
    final hy = (head.row + 0.5) * cellSize;
    _paintArrowHead(canvas, Offset(hx, hy), arrow.direction, strokeColor, cellSize);
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
    final totalDistance = (bodySegCount + exitCells).toDouble();
    final dTraveled = progress * totalDistance;

    final sTail = dTraveled;
    final sHead = math.min(sTail + bodySegCount, totalDistance);

    if (sTail >= totalDistance) return;

    final activePoints = _sampleSubPolyline(trajectory, sTail, sHead);
    if (activePoints.length < 2) return;

    final opacity = (1.0 - progress * 0.75).clamp(0.0, 1.0);

    final bodyPaint = Paint()
      ..color = strokeColor.withOpacity(opacity)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(activePoints.first.dx, activePoints.first.dy);
    for (int i = 1; i < activePoints.length; i++) {
      path.lineTo(activePoints[i].dx, activePoints[i].dy);
    }
    canvas.drawPath(path, bodyPaint);

    // Draw round cap at moving tail
    final tailPaint = Paint()
      ..color = strokeColor.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(activePoints.first, strokeWidth / 2, tailPaint);

    // Draw arrowhead at moving head
    if (sHead < totalDistance) {
      _paintArrowHead(canvas, activePoints.last, arrow.direction, strokeColor.withOpacity(opacity), cellSize);
    }
  }

  List<Offset> _sampleSubPolyline(List<Offset> trajectory, double sStart, double sEnd) {
    if (sEnd <= sStart || trajectory.length < 2) return [];

    final result = <Offset>[];
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

  void _paintPolyline(
    Canvas canvas,
    List<GridPoint> points,
    double cellSize,
    Paint paint, {
    required bool roundHead,
  }) {
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

  /// Draws a clean, crisp triangle arrowhead about 0.5 x cell size with no round-cap blobs.
  void _paintArrowHead(
    Canvas canvas,
    Offset position,
    ArrowDirection direction,
    Color color,
    double cellSize,
  ) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(direction.rotationAngle);

    // Arrowhead size: about 0.5 x cell size
    final headLen = cellSize * 0.48;
    final halfWidth = cellSize * 0.22;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Symmetrical crisp triangle: tip pointing in direction, base centered at cell center
    final path = Path()
      ..moveTo(0, -headLen * 0.55) // Tip pointing forward
      ..lineTo(-halfWidth, headLen * 0.45) // Left base
      ..lineTo(0, headLen * 0.15) // Slight modern inward notch
      ..lineTo(halfWidth, headLen * 0.45) // Right base
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) => true;
}

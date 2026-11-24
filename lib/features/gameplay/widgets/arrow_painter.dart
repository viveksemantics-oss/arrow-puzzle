import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../game/animation_config.dart';
import '../engine/arrow_direction.dart';
import '../engine/arrow_model.dart';
import '../engine/puzzle_board.dart';

enum ArrowLayerMode { all, staticOnly, dynamicOnly }

/// CustomPainter rendering thin-line snake polylines with clean solid triangle arrowheads.
///
/// Specifications:
/// - Stroke width = 0.16 x cellSize (never thicker than 0.20 x cellSize, clamped 1.5 to 4.0 px)
/// - Ink color: #1B1B2F on white board; #3E2723 on cream/brown eye-comfort theme
/// - Round cap at tail, round join at bends, smooth 0.25 x cellSize rounded corners
/// - Arrowhead: clean SOLID TRIANGLE, no notch, no outline.
///   Length = 0.55 x cellSize, base width = 0.50 x cellSize.
///   Tip at head cell center + 0.35 x cellSize in exit direction.
///   Base center at head cell center - 0.20 x cellSize in exit direction.
///   Line terminates exactly at base center: zero gap, zero overlap blob.
/// - Tap highlight: tapped arrow & its exit ray in bright blue (#1E88FF)
class ArrowPainter extends CustomPainter {
  final PuzzleBoard board;
  final Map<String, ArrowModel> exitingArrows;
  final Map<String, double> exitProgress; // 0.0 -> 1.0
  final Map<String, double> shakeOffsets; // pixel offset
  final String? activeHintId;
  final String? activeBlockedId; // ID of arrow that blocked the move (flashes red)
  final List<GridPoint>? blockedRay;
  final String? selectedArrowId; // ID of tapped arrow (flashes bright blue #1E88FF)
  final List<GridPoint>? selectedRay; // Exit ray of tapped arrow (bright blue #1E88FF)
  final bool isEyeComfortTheme;
  final bool showHitAreas;
  final ArrowLayerMode layerMode;
  final int staticRevision;

  ArrowPainter({
    super.repaint,
    required this.board,
    this.exitingArrows = const {},
    this.exitProgress = const {},
    this.shakeOffsets = const {},
    this.activeHintId,
    this.activeBlockedId,
    this.blockedRay,
    this.selectedArrowId,
    this.selectedRay,
    this.isEyeComfortTheme = false,
    this.showHitAreas = false,
    this.layerMode = ArrowLayerMode.all,
    this.staticRevision = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final boardSize = board.size;
    final cellSize = size.width / boardSize;

    final drawStatic = layerMode == ArrowLayerMode.all || layerMode == ArrowLayerMode.staticOnly;
    final drawDynamic = layerMode == ArrowLayerMode.all || layerMode == ArrowLayerMode.dynamicOnly;

    if (drawStatic) {
      // 1. Draw subtle dot grid
      _drawGrid(canvas, size, cellSize, boardSize);

      // 2. Debug-only hit area tolerance overlay
      if (kDebugMode && showHitAreas) {
        _drawDebugHitAreas(canvas, cellSize);
      }

      // 3. Draw Static Active Snake Arrows
      for (final arrow in board.arrows.values) {
        if (!arrow.isActive || exitingArrows.containsKey(arrow.id)) continue;
        final hasDynamicShake = (shakeOffsets[arrow.id] ?? 0.0).abs() > 0.001;
        final isDynamic = hasDynamicShake || arrow.id == activeBlockedId || arrow.id == selectedArrowId;
        if (layerMode == ArrowLayerMode.staticOnly && isDynamic) continue;

        _drawSnakeArrow(
          canvas: canvas,
          arrow: arrow,
          cellSize: cellSize,
          boardSize: boardSize,
          progress: 0.0,
          shakeOffset: shakeOffsets[arrow.id] ?? 0.0,
          isHinted: arrow.id == activeHintId || arrow.isHighlighted,
          isShaking: arrow.isShaking,
          isBlockingFlash: arrow.id == activeBlockedId,
          isSelected: arrow.id == selectedArrowId,
        );
      }
    }

    if (drawDynamic) {
      // 4. Draw selected arrow exit ray (bright blue #1E88FF on tap)
      if (selectedRay != null && selectedRay!.isNotEmpty) {
        _drawSelectedRay(canvas, cellSize);
      }

      // 5. Draw blocked ray indication (red flash on blocked move)
      if (blockedRay != null && blockedRay!.isNotEmpty) {
        _drawBlockedRay(canvas, cellSize);
      }

      // 6. Draw shaking / flashing / selected active arrows on top layer
      if (layerMode == ArrowLayerMode.dynamicOnly) {
        for (final arrow in board.arrows.values) {
          if (!arrow.isActive || exitingArrows.containsKey(arrow.id)) continue;
          final shake = shakeOffsets[arrow.id] ?? 0.0;
          final isDynamic = shake.abs() > 0.001 || arrow.id == activeBlockedId || arrow.id == selectedArrowId;
          if (!isDynamic) continue;

          _drawSnakeArrow(
            canvas: canvas,
            arrow: arrow,
            cellSize: cellSize,
            boardSize: boardSize,
            progress: 0.0,
            shakeOffset: shake,
            isHinted: arrow.id == activeHintId || arrow.isHighlighted,
            isShaking: arrow.isShaking || shake.abs() > 0.001,
            isBlockingFlash: arrow.id == activeBlockedId,
            isSelected: arrow.id == selectedArrowId,
          );
        }
      }

      // 7. Draw Sliding-Out Arrows independently
      for (final arrow in exitingArrows.values) {
        final progress = exitProgress[arrow.id] ?? 0.0;
        if (progress >= 1.0) continue;
        _drawSnakeArrow(
          canvas: canvas,
          arrow: arrow,
          cellSize: cellSize,
          boardSize: boardSize,
          progress: progress,
          shakeOffset: 0.0,
          isHinted: false,
          isShaking: false,
          isBlockingFlash: false,
          isSelected: arrow.id == selectedArrowId,
        );
      }
    }
  }

  void _drawDebugHitAreas(Canvas canvas, double cellSize) {
    final tolerance = cellSize * 0.30;
    for (final arrow in board.arrows.values) {
      if (!arrow.isActive || exitingArrows.containsKey(arrow.id)) continue;
      final isSel = arrow.id == selectedArrowId;
      final paint = Paint()
        ..color = (isSel ? const Color(0xFFFF9800) : const Color(0xFF10B981))
            .withOpacity(isSel ? 0.35 : 0.18)
        ..strokeWidth = tolerance * 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final pts = arrow.allPoints;
      if (pts.length >= 2) {
        final path = Path();
        path.moveTo((pts.first.col + 0.5) * cellSize, (pts.first.row + 0.5) * cellSize);
        for (int i = 1; i < pts.length; i++) {
          path.lineTo((pts[i].col + 0.5) * cellSize, (pts[i].row + 0.5) * cellSize);
        }
        canvas.drawPath(path, paint);
      }
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

  void _drawSelectedRay(Canvas canvas, double cellSize) {
    final rayFill = Paint()
      ..color = const Color(0x301E88FF)
      ..style = PaintingStyle.fill;

    final rayBorder = Paint()
      ..color = const Color(0x801E88FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final pt in selectedRay!) {
      final rect = Rect.fromLTWH(
        pt.col * cellSize + 2.5,
        pt.row * cellSize + 2.5,
        cellSize - 5,
        cellSize - 5,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));
      canvas.drawRRect(rrect, rayFill);
      canvas.drawRRect(rrect, rayBorder);
    }
  }

  void _drawBlockedRay(Canvas canvas, double cellSize) {
    final rayPaint = Paint()
      ..color = const Color(0x28EF4444)
      ..style = PaintingStyle.fill;

    final rayBorder = Paint()
      ..color = const Color(0x60EF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final pt in blockedRay!) {
      final rect = Rect.fromLTWH(
        pt.col * cellSize + 2,
        pt.row * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, rayPaint);
      canvas.drawRRect(rrect, rayBorder);
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
    required bool isSelected,
  }) {
    final points = arrow.allPoints;
    if (points.length < 2) return;

    // Stroke width = 16% of cell size (never thicker than 0.20 x cellSize, clamped 1.5 to 4.0 px)
    final strokeWidth = (cellSize * 0.16).clamp(1.5, 4.0);

    // Color resolution:
    // Selected tap = #1E88FF (Bright Blue)
    // Shaking / blocked flash = #EF4444 (Red)
    // Hinted = #F59E0B (Amber)
    // Eye comfort = #3E2723 (Espresso ink)
    // Default = #1B1B2F (Obsidian ink)
    Color strokeColor;
    if (isShaking || isBlockingFlash) {
      strokeColor = const Color(0xFFEF4444);
    } else if (isSelected) {
      strokeColor = const Color(0xFF1E88FF);
    } else if (isHinted) {
      strokeColor = const Color(0xFFF59E0B);
    } else if (isEyeComfortTheme) {
      strokeColor = const Color(0xFF3E2723);
    } else {
      strokeColor = const Color(0xFF1B1B2F);
    }

    canvas.save();

    // Blocked shake displacement
    if (shakeOffset.abs() > 0.001) {
      if (arrow.direction == ArrowDirection.up ||
          arrow.direction == ArrowDirection.down) {
        canvas.translate(shakeOffset, 0);
      } else {
        canvas.translate(0, shakeOffset);
      }
    }

    if (progress <= 0.001) {
      _drawStaticSnake(canvas, arrow, points, cellSize, strokeWidth, strokeColor, isHinted, isSelected);
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
    bool isSelected,
  ) {
    final dir = arrow.direction;
    final dirVec = Offset(dir.dx.toDouble(), dir.dy.toDouble());

    // Head center
    final headPt = points.last;
    final headCenter = Offset(
      (headPt.col + 0.5) * cellSize,
      (headPt.row + 0.5) * cellSize,
    );

    // Arrowhead geometry:
    // Length = 0.55 * cellSize, base width = 0.50 * cellSize
    // Tip at headCenter + 0.35 * cellSize * dirVec
    // Base center at headCenter - 0.20 * cellSize * dirVec
    final headTip = headCenter + dirVec * (cellSize * 0.35);
    final headBaseCenter = headCenter - dirVec * (cellSize * 0.20);
    final perpVec = Offset(-dirVec.dy, dirVec.dx);
    final halfBaseWidth = cellSize * 0.25;
    final headLeftBase = headBaseCenter + perpVec * halfBaseWidth;
    final headRightBase = headBaseCenter - perpVec * halfBaseWidth;

    // 1. Build smooth polyline path starting from tailCenter and ending exactly at headBaseCenter
    final polyPath = _buildPolylinePath(points, cellSize, headBaseCenter);

    // Optional Hint / Selection Glow
    if (isHinted || isSelected) {
      final glowColor = isSelected ? const Color(0x661E88FF) : const Color(0x55F59E0B);
      final glowPaint = Paint()
        ..color = glowColor
        ..strokeWidth = strokeWidth * 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(polyPath, glowPaint);
    }

    // 2. Draw line: StrokeCap.butt at headBaseCenter prevents any blob or overlap into triangle
    final bodyPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(polyPath, bodyPaint);

    // 3. Draw round cap at tail
    final tailPt = points.first;
    final tailCenter = Offset(
      (tailPt.col + 0.5) * cellSize,
      (tailPt.row + 0.5) * cellSize,
    );
    final tailPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(tailCenter, strokeWidth / 2, tailPaint);

    // 4. Draw clean solid triangle arrowhead: no notch, no outline
    final headTriangle = Path()
      ..moveTo(headTip.dx, headTip.dy)
      ..lineTo(headLeftBase.dx, headLeftBase.dy)
      ..lineTo(headRightBase.dx, headRightBase.dy)
      ..close();

    final headPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(headTriangle, headPaint);
  }

  Path _buildPolylinePath(List<GridPoint> points, double cellSize, Offset endPoint) {
    final path = Path();
    final firstPt = points.first;
    final startCenter = Offset(
      (firstPt.col + 0.5) * cellSize,
      (firstPt.row + 0.5) * cellSize,
    );
    path.moveTo(startCenter.dx, startCenter.dy);

    final cornerRadius = cellSize * 0.25;

    for (int i = 1; i < points.length; i++) {
      final curr = points[i];
      final prev = points[i - 1];
      final isLast = i == points.length - 1;

      final currCenter = Offset(
        (curr.col + 0.5) * cellSize,
        (curr.row + 0.5) * cellSize,
      );

      final inDx = (curr.col - prev.col).toDouble();
      final inDy = (curr.row - prev.row).toDouble();

      if (isLast) {
        // Line terminates exactly at base center of triangle
        path.lineTo(endPoint.dx, endPoint.dy);
      } else {
        final next = points[i + 1];
        final outDx = (next.col - curr.col).toDouble();
        final outDy = (next.row - curr.row).toDouble();

        if (inDx == outDx && inDy == outDy) {
          // Straight continuation: draw straight through cell center
          path.lineTo(currCenter.dx, currCenter.dy);
        } else {
          // 90-degree turn: round the bend smoothly with quadratic bezier
          final inVec = Offset(inDx, inDy);
          final outVec = Offset(outDx, outDy);

          final cornerStart = currCenter - inVec * cornerRadius;
          final cornerEnd = currCenter + outVec * cornerRadius;

          path.lineTo(cornerStart.dx, cornerStart.dy);
          path.quadraticBezierTo(
            currCenter.dx,
            currCenter.dy,
            cornerEnd.dx,
            cornerEnd.dy,
          );
        }
      }
    }

    return path;
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
    final exitCells = AnimationConfig.distanceToBoardEdgeCells(arrow, boardSize) + 1;
    final dir = arrow.direction;
    final dirVec = Offset(dir.dx.toDouble(), dir.dy.toDouble());

    // Build center trajectory from tail to head, then exiting forward
    final trajectory = <Offset>[];
    for (final pt in points) {
      trajectory.add(Offset((pt.col + 0.5) * cellSize, (pt.row + 0.5) * cellSize));
    }

    final last = trajectory.last;
    for (int i = 1; i <= exitCells; i++) {
      trajectory.add(last + dirVec * (i * cellSize));
    }

    final bodySegCount = points.length - 1;
    final totalDistance = (bodySegCount + exitCells).toDouble();
    final dTraveled = progress * totalDistance;

    final sTail = dTraveled;
    final sHead = math.min(sTail + bodySegCount, totalDistance);

    if (sTail >= totalDistance) return;

    final fadeStart = 1.0 - AnimationConfig.fadeFraction;
    final opacity = progress <= fadeStart
        ? 1.0
        : ((1.0 - progress) / AnimationConfig.fadeFraction).clamp(0.0, 1.0);
    if (opacity <= 0.001) return;

    // Sample body up to headBaseCenter (0.20 cells behind head center) so line stays flush with triangle base
    final sBodyEnd = math.max(sTail, sHead - 0.20);
    final bodyPoints = _sampleSubPolyline(trajectory, sTail, sBodyEnd);

    if (bodyPoints.length >= 2) {
      final bodyPaint = Paint()
        ..color = strokeColor.withOpacity(opacity)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(bodyPoints.first.dx, bodyPoints.first.dy);
      for (int i = 1; i < bodyPoints.length; i++) {
        path.lineTo(bodyPoints[i].dx, bodyPoints[i].dy);
      }
      canvas.drawPath(path, bodyPaint);

      // Draw moving tail round cap
      final tailPaint = Paint()
        ..color = strokeColor.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(bodyPoints.first, strokeWidth / 2, tailPaint);
    }

    // Draw moving arrowhead at sHead
    final headPoints = _sampleSubPolyline(trajectory, math.max(0.0, sHead - 0.25), sHead);
    if (headPoints.length >= 2) {
      final movingHead = headPoints.last;
      final headDelta = movingHead - headPoints[headPoints.length - 2];
      final headDir = headDelta.distance > 0.001 ? headDelta / headDelta.distance : dirVec;

      final headTip = movingHead + headDir * (cellSize * 0.35);
      final headBaseCenter = movingHead - headDir * (cellSize * 0.20);
      final perpVec = Offset(-headDir.dy, headDir.dx);
      final halfBaseWidth = cellSize * 0.25;
      final headLeftBase = headBaseCenter + perpVec * halfBaseWidth;
      final headRightBase = headBaseCenter - perpVec * halfBaseWidth;

      final headTriangle = Path()
        ..moveTo(headTip.dx, headTip.dy)
        ..lineTo(headLeftBase.dx, headLeftBase.dy)
        ..lineTo(headRightBase.dx, headRightBase.dy)
        ..close();

      final headPaint = Paint()
        ..color = strokeColor.withOpacity(opacity)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawPath(headTriangle, headPaint);
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

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) {
    if (layerMode == ArrowLayerMode.staticOnly) {
      return oldDelegate.board != board ||
          oldDelegate.activeHintId != activeHintId ||
          oldDelegate.isEyeComfortTheme != isEyeComfortTheme ||
          oldDelegate.showHitAreas != showHitAreas ||
          oldDelegate.staticRevision != staticRevision;
    }
    return oldDelegate.board != board ||
        oldDelegate.activeHintId != activeHintId ||
        oldDelegate.isEyeComfortTheme != isEyeComfortTheme ||
        oldDelegate.showHitAreas != showHitAreas ||
        oldDelegate.selectedArrowId != selectedArrowId ||
        oldDelegate.activeBlockedId != activeBlockedId;
  }
}

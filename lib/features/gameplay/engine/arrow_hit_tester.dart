import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'arrow_model.dart';
import 'puzzle_board.dart';

class ArrowHitResult {
  final ArrowModel arrow;
  final double distance;

  const ArrowHitResult(this.arrow, this.distance);
}

/// Fast spatial-indexed hit-tester for snake-polyline arrows.
///
/// Uses a cell bucket grid so hit-testing only inspects nearby candidates,
/// then computes exact point-to-segment and point-to-arrowhead-triangle distances.
class ArrowHitTester {
  PuzzleBoard _board;
  final Set<String> _excludedIds = {};
  final Map<int, List<ArrowModel>> _buckets = {};
  final Map<String, Rect> _cellBounds = {};

  ArrowHitTester(this._board) {
    _rebuild();
  }

  /// Rebuilds the spatial index for the given board and excluded (sliding/removed) IDs.
  void updateBoard(PuzzleBoard board, {Set<String>? excludedIds}) {
    _board = board;
    if (excludedIds != null) {
      _excludedIds
        ..clear()
        ..addAll(excludedIds);
    }
    _rebuild();
  }

  /// Immediately excludes an arrow from hit-testing and removes it from spatial buckets.
  void excludeArrow(String arrowId) {
    if (_excludedIds.add(arrowId)) {
      final arrow = _board.arrows[arrowId];
      if (arrow != null) {
        _removeFromBuckets(arrow);
      }
    }
  }

  void clearExcluded() {
    if (_excludedIds.isNotEmpty) {
      _excludedIds.clear();
      _rebuild();
    }
  }

  void _rebuild() {
    _buckets.clear();
    _cellBounds.clear();
    final size = _board.size;

    for (final arrow in _board.arrows.values) {
      if (!arrow.isActive || _excludedIds.contains(arrow.id)) continue;

      int minR = size, maxR = -1, minC = size, maxC = -1;
      for (final pt in arrow.allPoints) {
        if (pt.row < minR) minR = pt.row;
        if (pt.row > maxR) maxR = pt.row;
        if (pt.col < minC) minC = pt.col;
        if (pt.col > maxC) maxC = pt.col;
        _addToBucket(pt.row, pt.col, arrow);
      }

      // Also index the cell in front of the head in case the arrowhead tip extends into it
      final tipR = arrow.head.row + arrow.direction.dy;
      final tipC = arrow.head.col + arrow.direction.dx;
      if (tipR >= 0 && tipR < size && tipC >= 0 && tipC < size) {
        _addToBucket(tipR, tipC, arrow);
        if (tipR < minR) minR = tipR;
        if (tipR > maxR) maxR = tipR;
        if (tipC < minC) minC = tipC;
        if (tipC > maxC) maxC = tipC;
      }

      _cellBounds[arrow.id] = Rect.fromLTRB(
        minC.toDouble(),
        minR.toDouble(),
        (maxC + 1).toDouble(),
        (maxR + 1).toDouble(),
      );
    }
  }

  void _addToBucket(int r, int c, ArrowModel arrow) {
    final key = r * _board.size + c;
    final list = _buckets.putIfAbsent(key, () => []);
    if (!list.contains(arrow)) {
      list.add(arrow);
    }
  }

  void _removeFromBuckets(ArrowModel arrow) {
    for (final pt in arrow.allPoints) {
      final key = pt.row * _board.size + pt.col;
      _buckets[key]?.removeWhere((a) => a.id == arrow.id);
    }
    final tipR = arrow.head.row + arrow.direction.dy;
    final tipC = arrow.head.col + arrow.direction.dx;
    if (tipR >= 0 && tipR < _board.size && tipC >= 0 && tipC < _board.size) {
      final key = tipR * _board.size + tipC;
      _buckets[key]?.removeWhere((a) => a.id == arrow.id);
    }
    _cellBounds.remove(arrow.id);
  }

  /// Converts a viewport coordinate to board-local coordinates using InteractiveViewer's transform.
  static Offset viewportToBoard({
    required Offset viewportPosition,
    required TransformationController controller,
    required Offset boardOriginInScene,
  }) {
    final scenePos = controller.toScene(viewportPosition);
    return scenePos - boardOriginInScene;
  }

  /// Performs O(1)-ish spatial lookup and exact nearest-wins distance check.
  ArrowHitResult? hitTest({
    required Offset boardPos,
    required double cellSize,
  }) {
    if (cellSize <= 0) return null;

    final tolerance = cellSize * 0.30;
    final tapCol = (boardPos.dx / cellSize).floor();
    final tapRow = (boardPos.dy / cellSize).floor();
    final size = _board.size;

    // Gather unique candidates from the 3x3 grid neighborhood around the tap cell
    final candidates = <String, ArrowModel>{};
    for (int dr = -1; dr <= 1; dr++) {
      final r = tapRow + dr;
      if (r < 0 || r >= size) continue;
      for (int dc = -1; dc <= 1; dc++) {
        final c = tapCol + dc;
        if (c < 0 || c >= size) continue;
        final bucket = _buckets[r * size + c];
        if (bucket == null) continue;
        for (final arrow in bucket) {
          if (arrow.isActive && !_excludedIds.contains(arrow.id)) {
            candidates[arrow.id] = arrow;
          }
        }
      }
    }

    if (candidates.isEmpty) return null;

    ArrowModel? bestArrow;
    double bestDist = double.infinity;
    double bestHeadDist = double.infinity;

    for (final arrow in candidates.values) {
      // Quick bounding box reject (inflated by tolerance)
      final cellRect = _cellBounds[arrow.id];
      if (cellRect != null) {
        final pxRect = Rect.fromLTRB(
          cellRect.left * cellSize - tolerance,
          cellRect.top * cellSize - tolerance,
          cellRect.right * cellSize + tolerance,
          cellRect.bottom * cellSize + tolerance,
        );
        if (!pxRect.contains(boardPos)) continue;
      }

      final dist = _distanceToArrow(boardPos, arrow, cellSize);
      if (dist > tolerance) continue;

      final headCenter = Offset(
        (arrow.head.col + 0.5) * cellSize,
        (arrow.head.row + 0.5) * cellSize,
      );
      final headDist = (boardPos - headCenter).distance;

      if (bestArrow == null) {
        bestArrow = arrow;
        bestDist = dist;
        bestHeadDist = headDist;
      } else {
        final maxDist = math.max(dist, bestDist);
        final withinFivePercent =
            maxDist == 0.0 || (dist - bestDist).abs() <= maxDist * 0.05;
        if (withinFivePercent) {
          if (headDist < bestHeadDist) {
            bestArrow = arrow;
            bestDist = dist;
            bestHeadDist = headDist;
          }
        } else if (dist < bestDist) {
          bestArrow = arrow;
          bestDist = dist;
          bestHeadDist = headDist;
        }
      }
    }

    if (bestArrow == null) return null;
    return ArrowHitResult(bestArrow, bestDist);
  }

  double _distanceToArrow(Offset p, ArrowModel arrow, double cellSize) {
    final pts = arrow.allPoints;
    double minDist = double.infinity;

    for (int i = 0; i < pts.length - 1; i++) {
      final p1 = Offset((pts[i].col + 0.5) * cellSize, (pts[i].row + 0.5) * cellSize);
      final p2 = Offset((pts[i + 1].col + 0.5) * cellSize, (pts[i + 1].row + 0.5) * cellSize);
      final d = _distanceToSegment(p, p1, p2);
      if (d < minDist) minDist = d;
    }

    // Exact arrowhead triangle (matches ArrowPainter geometry)
    final dirX = arrow.direction.dx.toDouble();
    final dirY = arrow.direction.dy.toDouble();
    final headCenter = Offset(
      (arrow.head.col + 0.5) * cellSize,
      (arrow.head.row + 0.5) * cellSize,
    );
    final tip = Offset(
      headCenter.dx + dirX * cellSize * 0.35,
      headCenter.dy + dirY * cellSize * 0.35,
    );
    final baseCenter = Offset(
      headCenter.dx - dirX * cellSize * 0.20,
      headCenter.dy - dirY * cellSize * 0.20,
    );
    final perpX = -dirY;
    final perpY = dirX;
    final halfBase = cellSize * 0.25;
    final leftCorner = Offset(baseCenter.dx + perpX * halfBase, baseCenter.dy + perpY * halfBase);
    final rightCorner = Offset(baseCenter.dx - perpX * halfBase, baseCenter.dy - perpY * halfBase);

    final triDist = _distanceToTriangle(p, tip, leftCorner, rightCorner);
    if (triDist < minDist) minDist = triDist;

    return minDist;
  }

  static double _distanceToSegment(Offset p, Offset v, Offset w) {
    final l2 = (v - w).distanceSquared;
    if (l2 == 0.0) return (p - v).distance;
    final t = (((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2)
        .clamp(0.0, 1.0);
    final proj = Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy));
    return (p - proj).distance;
  }

  static double _distanceToTriangle(Offset p, Offset a, Offset b, Offset c) {
    if (_pointInTriangle(p, a, b, c)) return 0.0;
    final d1 = _distanceToSegment(p, a, b);
    final d2 = _distanceToSegment(p, b, c);
    final d3 = _distanceToSegment(p, c, a);
    return math.min(d1, math.min(d2, d3));
  }

  static bool _pointInTriangle(Offset p, Offset a, Offset b, Offset c) {
    final d1 = _sign(p, a, b);
    final d2 = _sign(p, b, c);
    final d3 = _sign(p, c, a);
    final hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
    final hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);
    return !(hasNeg && hasPos);
  }

  static double _sign(Offset p1, Offset p2, Offset p3) {
    return (p1.dx - p3.dx) * (p2.dy - p3.dy) - (p2.dx - p3.dx) * (p1.dy - p3.dy);
  }
}

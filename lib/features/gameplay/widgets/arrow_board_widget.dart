import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../engine/arrow_model.dart';
import '../engine/puzzle_board.dart';
import 'arrow_painter.dart';

/// Interactive Puzzle Board Widget with card auto-fit, pinch-to-zoom, pan, and sub-cell polyline hit-testing.
class ArrowBoardWidget extends StatefulWidget {
  final PuzzleBoard board;
  final Function(String arrowId) onArrowTapped;
  final String? activeHintId;
  final bool isEyeComfortTheme;

  const ArrowBoardWidget({
    super.key,
    required this.board,
    required this.onArrowTapped,
    this.activeHintId,
    this.isEyeComfortTheme = false,
  });

  @override
  State<ArrowBoardWidget> createState() => ArrowBoardWidgetState();
}

class ArrowBoardWidgetState extends State<ArrowBoardWidget>
    with TickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();

  final Map<String, AnimationController> _exitControllers = {};
  final Map<String, double> _exitProgress = {};

  final Map<String, AnimationController> _shakeControllers = {};
  final Map<String, double> _shakeOffsets = {};

  String? _activeBlockedId;
  List<GridPoint>? _activeBlockedRay;

  @override
  void dispose() {
    _transformationController.dispose();
    for (final c in _exitControllers.values) {
      c.dispose();
    }
    for (final c in _shakeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Triggers a smooth slithering exit animation for the specified arrow.
  void animateArrowExit(ArrowModel arrow, VoidCallback onFinished) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInCubic,
    );

    animation.addListener(() {
      setState(() {
        _exitProgress[arrow.id] = animation.value;
      });
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
        _exitControllers.remove(arrow.id);
        onFinished();
      }
    });

    _exitControllers[arrow.id] = controller;
    controller.forward();
  }

  /// Triggers shake vibration, red flash on blocked arrow and blocking arrow.
  void animateArrowShake(ArrowModel arrow, String? blockingArrowId, List<GridPoint> blockedRay) {
    setState(() {
      _activeBlockedId = blockingArrowId;
      _activeBlockedRay = blockedRay;
    });

    Future.delayed(const Duration(milliseconds: 460), () {
      if (mounted) {
        setState(() {
          _activeBlockedId = null;
          _activeBlockedRay = null;
        });
      }
    });

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    controller.addListener(() {
      final t = controller.value;
      final offset = math.sin(t * math.pi * 6) * (1.0 - t) * 8.5;
      setState(() {
        _shakeOffsets[arrow.id] = offset;
      });
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
        _shakeControllers.remove(arrow.id);
        if (mounted) {
          setState(() {
            _shakeOffsets.remove(arrow.id);
          });
        }
      }
    });

    _shakeControllers[arrow.id] = controller;
    controller.forward();
  }

  /// Clears ongoing animations.
  void resetAnimations() {
    for (final c in _exitControllers.values) {
      c.dispose();
    }
    _exitControllers.clear();
    _exitProgress.clear();

    for (final c in _shakeControllers.values) {
      c.dispose();
    }
    _shakeControllers.clear();
    _shakeOffsets.clear();
    _activeBlockedId = null;
    _activeBlockedRay = null;
    _transformationController.value = Matrix4.identity();
    if (mounted) setState(() {});
  }

  /// Handles touch event by performing distance hit-testing against arrow polyline segments.
  void _handleTap(Offset localPosition, double cellSize) {
    String? closestArrowId;
    double minDistance = double.infinity;
    // SPEC A: Use a hit tolerance of about 0.45 x cell size around the line (touch area generous)
    final maxTouchDistance = cellSize * 0.45;

    for (final arrow in widget.board.arrows.values) {
      if (!arrow.isActive) continue;

      final points = arrow.allPoints;
      if (points.length == 1) {
        final cx = (points.first.col + 0.5) * cellSize;
        final cy = (points.first.row + 0.5) * cellSize;
        final d = (localPosition - Offset(cx, cy)).distance;
        if (d < minDistance) {
          minDistance = d;
          closestArrowId = arrow.id;
        }
      } else {
        for (int i = 0; i < points.length - 1; i++) {
          final p1 = Offset(
            (points[i].col + 0.5) * cellSize,
            (points[i].row + 0.5) * cellSize,
          );
          final p2 = Offset(
            (points[i + 1].col + 0.5) * cellSize,
            (points[i + 1].row + 0.5) * cellSize,
          );

          final d = _distanceToSegment(localPosition, p1, p2);
          if (d < minDistance) {
            minDistance = d;
            closestArrowId = arrow.id;
          }
        }
      }
    }

    if (closestArrowId != null && minDistance <= maxTouchDistance) {
      widget.onArrowTapped(closestArrowId);
    }
  }

  double _distanceToSegment(Offset p, Offset v, Offset w) {
    final l2 = (v - w).distanceSquared;
    if (l2 == 0.0) return (p - v).distance;
    final t = (((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2)
        .clamp(0.0, 1.0);
    final projection = Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy));
    return (p - projection).distance;
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isEyeComfortTheme
        ? const Color(0xFFFAF3E7)
        : Colors.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth;
        final cardH = constraints.maxHeight;
        const padding = 12.0;

        final availW = cardW - padding * 2;
        final availH = cardH - padding * 2;

        // SPEC C: Compute cell size from the level's mask bounding box
        int minR = widget.board.size, maxR = 0, minC = widget.board.size, maxC = 0;
        for (final arrow in widget.board.arrows.values) {
          for (final pt in arrow.allPoints) {
            if (pt.row < minR) minR = pt.row;
            if (pt.row > maxR) maxR = pt.row;
            if (pt.col < minC) minC = pt.col;
            if (pt.col > maxC) maxC = pt.col;
          }
        }
        if (minR > maxR) {
          minR = 0;
          maxR = widget.board.size - 1;
          minC = 0;
          maxC = widget.board.size - 1;
        }

        final boundingCols = (maxC - minC + 1).toDouble();
        final boundingRows = (maxR - minR + 1).toDouble();

        // Fit silhouette bounding box into available card space
        final cellSize = math.min(availW / boundingCols, availH / boundingRows) * 0.94;
        final boardTotalW = widget.board.size * cellSize;
        final boardTotalH = widget.board.size * cellSize;

        // SPEC C: Card = white, 24px rounded corners, soft shadow only (NO thick black border, NO hatched corners)
        return Container(
          width: cardW,
          height: cardH,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(padding),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.6,
              maxScale: 4.5,
              boundaryMargin: const EdgeInsets.all(24.0),
              clipBehavior: Clip.hardEdge,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _handleTap(details.localPosition, cellSize),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(boardTotalW, boardTotalH),
                      painter: ArrowPainter(
                        board: widget.board,
                        exitProgress: _exitProgress,
                        shakeOffsets: _shakeOffsets,
                        activeHintId: widget.activeHintId,
                        activeBlockedId: _activeBlockedId,
                        blockedRay: _activeBlockedRay,
                        isEyeComfortTheme: widget.isEyeComfortTheme,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../game/animation_config.dart';
import '../engine/arrow_hit_tester.dart';
import '../engine/arrow_model.dart';
import '../engine/puzzle_board.dart';
import 'arrow_painter.dart';

/// Interactive Puzzle Board Widget with card auto-fit, pinch-to-zoom, pan, and exact O(1) spatial hit-testing.
class ArrowBoardWidget extends StatefulWidget {
  final PuzzleBoard board;
  final Function(String arrowId) onArrowTapped;
  final String? activeHintId;
  final bool isEyeComfortTheme;
  final bool showHitAreas;

  const ArrowBoardWidget({
    super.key,
    required this.board,
    required this.onArrowTapped,
    this.activeHintId,
    this.isEyeComfortTheme = false,
    this.showHitAreas = false,
  });

  @override
  State<ArrowBoardWidget> createState() => ArrowBoardWidgetState();
}

class ArrowBoardWidgetState extends State<ArrowBoardWidget>
    with TickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);
  late final ArrowHitTester _hitTester;
  int _staticRevision = 0;
  double _lastCellSize = 20.0;

  final Map<int, Offset> _pointerDownPos = {};

  final Map<String, ArrowModel> _exitingArrows = {};
  final Map<String, AnimationController> _exitControllers = {};
  final Map<String, double> _exitProgress = {};

  final Map<String, AnimationController> _shakeControllers = {};
  final Map<String, double> _shakeOffsets = {};

  String? _activeBlockedId;
  List<GridPoint>? _activeBlockedRay;
  String? _selectedArrowId;
  List<GridPoint>? _selectedRay;

  @override
  void initState() {
    super.initState();
    _hitTester = ArrowHitTester(widget.board);
  }

  @override
  void didUpdateWidget(covariant ArrowBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.board != widget.board) {
      _hitTester.updateBoard(
        widget.board,
        excludedIds: _exitingArrows.keys.toSet(),
      );
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _repaintNotifier.dispose();
    for (final c in _exitControllers.values) {
      c.dispose();
    }
    for (final c in _shakeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Exposes TransformationController for testing zoom/pan hit-testing.
  @visibleForTesting
  TransformationController get transformationController => _transformationController;

  /// Triggers a smooth, independent slithering exit animation for the specified arrow.
  void animateArrowExit(ArrowModel arrow, VoidCallback onFinished) {
    if (_exitControllers.containsKey(arrow.id)) return;

    // Immediately exclude from hit-testing and spatial index
    _hitTester.excludeArrow(arrow.id);
    _exitingArrows[arrow.id] = arrow;
    _exitProgress[arrow.id] = 0.0;
    if (mounted) {
      setState(() {
        _staticRevision++;
      });
    }

    final durationMs = AnimationConfig.computeSlideDurationMs(arrow, widget.board.size);
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );

    controller.addListener(() {
      _exitProgress[arrow.id] = AnimationConfig.easeInThenConstant(controller.value, durationMs);
      _repaintNotifier.value++;
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
        _exitControllers.remove(arrow.id);
        _exitingArrows.remove(arrow.id);
        _exitProgress.remove(arrow.id);
        if (_selectedArrowId == arrow.id) {
          _selectedArrowId = null;
          _selectedRay = null;
        }
        if (mounted) {
          setState(() {
            _staticRevision++;
          });
        }
        _repaintNotifier.value++;
        onFinished();
      }
    });

    _exitControllers[arrow.id] = controller;
    controller.forward();
  }

  /// Triggers shake vibration and visual red flash on blocked move.
  void animateArrowShake(ArrowModel arrow, String? blockingArrowId, List<GridPoint> blockedRay) {
    if (_shakeControllers.containsKey(arrow.id)) return;

    _activeBlockedId = blockingArrowId;
    _activeBlockedRay = blockedRay;
    if (mounted) {
      setState(() {
        _staticRevision++;
      });
    }
    _repaintNotifier.value++;

    Future.delayed(const Duration(milliseconds: AnimationConfig.blockFlashDurationMs), () {
      if (mounted && _activeBlockedId == blockingArrowId) {
        _activeBlockedId = null;
        _activeBlockedRay = null;
        setState(() {
          _staticRevision++;
        });
        _repaintNotifier.value++;
      }
    });

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AnimationConfig.shakeDurationMs),
    );

    controller.addListener(() {
      final t = controller.value;
      final amp = _lastCellSize * AnimationConfig.shakeOffsetCells;
      final offset = math.sin(t * math.pi * 2 * AnimationConfig.shakeOscillations) *
          (1.0 - Curves.easeOut.transform(t)) *
          amp;
      _shakeOffsets[arrow.id] = offset;
      _repaintNotifier.value++;
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
        _shakeControllers.remove(arrow.id);
        _shakeOffsets.remove(arrow.id);
        if (mounted) {
          setState(() {
            _staticRevision++;
          });
        }
        _repaintNotifier.value++;
      }
    });

    _shakeControllers[arrow.id] = controller;
    controller.forward();
  }

  /// Clears ongoing animations and resets spatial index.
  void resetAnimations() {
    for (final c in _exitControllers.values) {
      c.dispose();
    }
    _exitControllers.clear();
    _exitingArrows.clear();
    _exitProgress.clear();

    for (final c in _shakeControllers.values) {
      c.dispose();
    }
    _shakeControllers.clear();
    _shakeOffsets.clear();
    _activeBlockedId = null;
    _activeBlockedRay = null;
    _selectedArrowId = null;
    _selectedRay = null;
    _transformationController.value = Matrix4.identity();
    _hitTester.clearExcluded();
    _repaintNotifier.value++;
  }

  void _handlePointerUp(
    PointerUpEvent event,
    double cellSize,
    Offset boardOriginInScene,
  ) {
    final downPos = _pointerDownPos.remove(event.pointer);
    // Ignore if another finger is still down (pinch) or pointer dragged >= 8 px
    if (downPos == null || _pointerDownPos.isNotEmpty) return;
    if ((event.localPosition - downPos).distance >= 8.0) return;

    final boardPos = ArrowHitTester.viewportToBoard(
      viewportPosition: event.localPosition,
      controller: _transformationController,
      boardOriginInScene: boardOriginInScene,
    );

    final result = _hitTester.hitTest(boardPos: boardPos, cellSize: cellSize);
    if (result == null) return;

    final tappedArrow = result.arrow;
    if (kDebugMode && widget.showHitAreas) {
      debugPrint('tap -> ${tappedArrow.id}, ${result.distance.toStringAsFixed(2)}');
    }

    _selectedArrowId = tappedArrow.id;
    _selectedRay = widget.board.getExitRay(tappedArrow);
    _repaintNotifier.value++;

    widget.onArrowTapped(tappedArrow.id);

    final targetId = tappedArrow.id;
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted && _selectedArrowId == targetId) {
        _selectedArrowId = null;
        _selectedRay = null;
        _repaintNotifier.value++;
      }
    });
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

        // Compute cell size from the level's mask bounding box
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

        final cellSize = math.min(availW / boundingCols, availH / boundingRows) * 0.94;
        _lastCellSize = cellSize;
        final boardTotalW = widget.board.size * cellSize;
        final boardTotalH = widget.board.size * cellSize;
        final boardOriginInScene = Offset(
          (availW - boardTotalW) / 2,
          (availH - boardTotalH) / 2,
        );

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
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => _pointerDownPos[e.pointer] = e.localPosition,
              onPointerCancel: (e) => _pointerDownPos.remove(e.pointer),
              onPointerUp: (e) => _handlePointerUp(e, cellSize, boardOriginInScene),
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.6,
                maxScale: 4.5,
                boundaryMargin: const EdgeInsets.all(24.0),
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: availW,
                  height: availH,
                  child: Center(
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: double.infinity,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: Stack(
                        children: [
                          RepaintBoundary(
                            child: CustomPaint(
                              size: Size(boardTotalW, boardTotalH),
                              painter: ArrowPainter(
                                board: widget.board,
                                exitingArrows: _exitingArrows,
                                activeHintId: widget.activeHintId,
                                activeBlockedId: _activeBlockedId,
                                selectedArrowId: _selectedArrowId,
                                isEyeComfortTheme: widget.isEyeComfortTheme,
                                showHitAreas: widget.showHitAreas,
                                layerMode: ArrowLayerMode.staticOnly,
                                staticRevision: _staticRevision,
                              ),
                            ),
                          ),
                          CustomPaint(
                            size: Size(boardTotalW, boardTotalH),
                            painter: ArrowPainter(
                              repaint: _repaintNotifier,
                              board: widget.board,
                              exitingArrows: _exitingArrows,
                              exitProgress: _exitProgress,
                              shakeOffsets: _shakeOffsets,
                              activeHintId: widget.activeHintId,
                              activeBlockedId: _activeBlockedId,
                              blockedRay: _activeBlockedRay,
                              selectedArrowId: _selectedArrowId,
                              selectedRay: _selectedRay,
                              isEyeComfortTheme: widget.isEyeComfortTheme,
                              showHitAreas: widget.showHitAreas,
                              layerMode: ArrowLayerMode.dynamicOnly,
                            ),
                          ),
                        ],
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

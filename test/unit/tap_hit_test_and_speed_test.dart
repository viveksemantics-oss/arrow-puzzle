import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eklavyas_aim/features/gameplay/engine/arrow_hit_tester.dart';
import 'package:eklavyas_aim/features/gameplay/engine/arrow_model.dart';
import 'package:eklavyas_aim/features/gameplay/engine/level_repository.dart';
import 'package:eklavyas_aim/features/gameplay/engine/puzzle_board.dart';
import 'package:eklavyas_aim/features/gameplay/widgets/arrow_board_widget.dart';

void main() {
  group('Exact Tap Target, Rapid Taps & Zoom/Pan Hit-Testing', () {
    test('Parallel arrows 1 cell apart, empty gap, and L-shaped corner', () {
      // 6x6 board:
      // Arrow A: row 1, cols 1->2 (parallel to B, 1 cell apart since gap at row 2)
      // Arrow B: row 3, cols 1->2
      // Arrow L: L-shaped arrow with corner at (1, 4) -> (2, 4) -> (2, 5)
      const cellSize = 40.0;
      final arrowA = ArrowModel(
        id: 'A',
        points: const [GridPoint(1, 1), GridPoint(1, 2)],
      );
      final arrowB = ArrowModel(
        id: 'B',
        points: const [GridPoint(3, 1), GridPoint(3, 2)],
      );
      final arrowL = ArrowModel(
        id: 'L',
        points: const [GridPoint(1, 4), GridPoint(2, 4), GridPoint(2, 5)],
      );

      final board = PuzzleBoard.fromList(
        size: 6,
        arrowsList: [arrowA, arrowB, arrowL],
      );
      final hitTester = ArrowHitTester(board);

      // Tap exactly on Arrow A
      final hitA = hitTester.hitTest(
        boardPos: const Offset(1.5 * cellSize, 1.5 * cellSize),
        cellSize: cellSize,
      );
      expect(hitA?.arrow.id, equals('A'));

      // Tap exactly on Arrow B
      final hitB = hitTester.hitTest(
        boardPos: const Offset(1.5 * cellSize, 3.5 * cellSize),
        cellSize: cellSize,
      );
      expect(hitB?.arrow.id, equals('B'));

      // Tap in the empty gap between A (row 1) and B (row 3) -> row 2 center (2.5 * cellSize)
      // Distance to A and B is 1.0 * cellSize > 0.30 * cellSize tolerance -> must return null
      final hitGap = hitTester.hitTest(
        boardPos: const Offset(1.5 * cellSize, 2.5 * cellSize),
        cellSize: cellSize,
      );
      expect(hitGap, isNull);

      // Tap at the corner of L-shaped arrow (2, 4)
      final hitL = hitTester.hitTest(
        boardPos: const Offset(4.5 * cellSize, 2.5 * cellSize),
        cellSize: cellSize,
      );
      expect(hitL?.arrow.id, equals('L'));
    });

    testWidgets('20 quick consecutive taps without waiting for animations', (tester) async {
      // 20x20 board with 20 free parallel arrows
      final arrows = List.generate(20, (i) {
        return ArrowModel(
          id: 'free_$i',
          points: [GridPoint(i, 1), GridPoint(i, 2)],
        );
      });
      var board = PuzzleBoard.fromList(size: 20, arrowsList: arrows);
      final tappedOrder = <String>[];
      final boardKey = GlobalKey<ArrowBoardWidgetState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return ArrowBoardWidget(
                      key: boardKey,
                      board: board,
                      onArrowTapped: (id) {
                        tappedOrder.add(id);
                        final arrow = board.getArrowById(id)!;
                        boardKey.currentState!.animateArrowExit(arrow, () {});
                        board.setArrowActive(id, false);
                        board = board.clone();
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.renderObject(find.byType(CustomPaint).last) as RenderBox;
      final cellSize = box.size.width / 20.0;

      // Tap all 20 arrows in quick succession with 0ms wait for animations
      for (int i = 0; i < 20; i++) {
        final localCenter = Offset(1.5 * cellSize, (i + 0.5) * cellSize);
        final globalPos = box.localToGlobal(localCenter);
        await tester.tapAt(globalPos);
        await tester.pump(const Duration(milliseconds: 5));
      }

      expect(tappedOrder.length, equals(20));
      expect(tappedOrder, equals(List.generate(20, (i) => 'free_$i')));

      // Drain exit animations cleanly
      await tester.pumpAndSettle();
    });

    testWidgets('Zoom 2x and pan: taps still select the exact right arrows', (tester) async {
      // Anchor corners (0,0) and (5,5) so full 6x6 board fits inside 400x400, and test arrows at center
      final anchorTL = ArrowModel(
        id: 'TL',
        points: const [GridPoint(0, 0), GridPoint(0, 1)],
      );
      final anchorBR = ArrowModel(
        id: 'BR',
        points: const [GridPoint(5, 5), GridPoint(5, 4)],
      );
      final arrowA = ArrowModel(
        id: 'A',
        points: const [GridPoint(2, 2), GridPoint(2, 3)],
      );
      final arrowB = ArrowModel(
        id: 'B',
        points: const [GridPoint(3, 2), GridPoint(3, 3)],
      );
      final board = PuzzleBoard.fromList(
        size: 6,
        arrowsList: [anchorTL, anchorBR, arrowA, arrowB],
      );
      final tapped = <String>[];
      final boardKey = GlobalKey<ArrowBoardWidgetState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: ArrowBoardWidget(
                  key: boardKey,
                  board: board,
                  onArrowTapped: tapped.add,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Apply 2x zoom and (-100, -160) pan on InteractiveViewer's TransformationController
      final controller = boardKey.currentState!.transformationController;
      controller.value = Matrix4.identity()
        ..translateByDouble(-100.0, -160.0, 0.0, 1.0)
        ..scaleByDouble(2.0, 2.0, 1.0, 1.0);
      await tester.pump();

      final box = tester.renderObject(find.byType(CustomPaint).last) as RenderBox;
      final cellSize = box.size.width / 6.0;

      // Global position of arrow B's cell (3, 2) and arrow A's cell (2, 2) after 2x zoom + pan
      final globalB = box.localToGlobal(Offset(2.5 * cellSize, 3.5 * cellSize));
      await tester.tapAt(globalB);
      await tester.pump(const Duration(milliseconds: 10));

      final globalA = box.localToGlobal(Offset(2.5 * cellSize, 2.5 * cellSize));
      await tester.tapAt(globalA);
      await tester.pump(const Duration(milliseconds: 250));

      expect(tapped, equals(['B', 'A']));
    });

    test('Level 1 and Level 100 spatial hit-testing hits exact arrows', () {
      final repo = LevelRepository();
      for (final lvlNum in [1, 100]) {
        final level = repo.getLevel(lvlNum);
        final board = level.createBoard();
        final hitTester = ArrowHitTester(board);
        const cellSize = 20.0;

        for (final arrow in board.arrows.values.take(10)) {
          final headPos = Offset(
            (arrow.head.col + 0.5) * cellSize,
            (arrow.head.row + 0.5) * cellSize,
          );
          final res = hitTester.hitTest(boardPos: headPos, cellSize: cellSize);
          expect(res, isNotNull);
          expect(res!.arrow.id, equals(arrow.id));
        }
      }
    });
  });
}

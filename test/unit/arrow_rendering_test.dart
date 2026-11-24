import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eklavyas_aim/features/gameplay/engine/arrow_direction.dart';
import 'package:eklavyas_aim/features/gameplay/engine/arrow_model.dart';
import 'package:eklavyas_aim/features/gameplay/engine/puzzle_board.dart';
import 'package:eklavyas_aim/features/gameplay/widgets/arrow_painter.dart';

void main() {
  group('Step 1: Arrow Rendering & Model Verification', () {
    test('12 Hand-Made Arrows: Straight, L, U, S Shapes in all 4 Directions', () {
      final arrows = <ArrowModel>[
        // 1. Straight UP
        ArrowModel(
          id: 'straight_up',
          points: const [GridPoint(4, 0), GridPoint(3, 0), GridPoint(2, 0), GridPoint(1, 0)],
        ),
        // 2. Straight DOWN
        ArrowModel(
          id: 'straight_down',
          points: const [GridPoint(1, 1), GridPoint(2, 1), GridPoint(3, 1), GridPoint(4, 1)],
        ),
        // 3. Straight LEFT
        ArrowModel(
          id: 'straight_left',
          points: const [GridPoint(0, 4), GridPoint(0, 3), GridPoint(0, 2), GridPoint(0, 1)],
        ),
        // 4. Straight RIGHT
        ArrowModel(
          id: 'straight_right',
          points: const [GridPoint(5, 0), GridPoint(5, 1), GridPoint(5, 2), GridPoint(5, 3)],
        ),

        // 5. L-shape ending UP
        ArrowModel(
          id: 'l_up',
          points: const [GridPoint(3, 5), GridPoint(3, 4), GridPoint(2, 4), GridPoint(1, 4)],
        ),
        // 6. L-shape ending DOWN
        ArrowModel(
          id: 'l_down',
          points: const [GridPoint(6, 4), GridPoint(6, 5), GridPoint(7, 5), GridPoint(8, 5)],
        ),
        // 7. L-shape ending LEFT
        ArrowModel(
          id: 'l_left',
          points: const [GridPoint(1, 8), GridPoint(2, 8), GridPoint(2, 7), GridPoint(2, 6)],
        ),
        // 8. L-shape ending RIGHT
        ArrowModel(
          id: 'l_right',
          points: const [GridPoint(4, 7), GridPoint(3, 7), GridPoint(3, 8), GridPoint(3, 9)],
        ),

        // 9. U-shape ending UP
        ArrowModel(
          id: 'u_up',
          points: const [
            GridPoint(8, 0),
            GridPoint(7, 0),
            GridPoint(7, 1),
            GridPoint(8, 1),
            GridPoint(9, 1),
            GridPoint(9, 2),
            GridPoint(8, 2),
            GridPoint(7, 2),
          ],
        ),
        // 10. U-shape ending DOWN
        ArrowModel(
          id: 'u_down',
          points: const [
            GridPoint(7, 8),
            GridPoint(8, 8),
            GridPoint(8, 7),
            GridPoint(7, 7),
            GridPoint(6, 7),
            GridPoint(6, 6),
            GridPoint(7, 6),
            GridPoint(8, 6),
          ],
        ),

        // 11. S-shape ending LEFT
        ArrowModel(
          id: 's_left',
          points: const [
            GridPoint(9, 6),
            GridPoint(9, 5),
            GridPoint(10, 5),
            GridPoint(10, 4),
            GridPoint(11, 4),
            GridPoint(11, 3),
          ],
        ),
        // 12. S-shape ending RIGHT
        ArrowModel(
          id: 's_right',
          points: const [
            GridPoint(11, 7),
            GridPoint(11, 8),
            GridPoint(10, 8),
            GridPoint(10, 9),
            GridPoint(9, 9),
            GridPoint(9, 10),
          ],
        ),
      ];

      expect(arrows.length, equals(12));

      // Verify each arrow adheres to strict 4-connectivity and direction rules
      for (final arrow in arrows) {
        expect(arrow.points.length, greaterThanOrEqualTo(2));
        expect(arrow.head, equals(arrow.points.last));
        expect(arrow.tail, equals(arrow.points.first));

        // 4-connectivity assertion: consecutive points differ by exactly 1 in row OR col, NEVER both
        for (int i = 0; i < arrow.points.length - 1; i++) {
          final p1 = arrow.points[i];
          final p2 = arrow.points[i + 1];
          final dr = (p2.row - p1.row).abs();
          final dc = (p2.col - p1.col).abs();
          expect((dr == 1 && dc == 0) || (dr == 0 && dc == 1), isTrue,
              reason: 'Diagonal or disconnected segment detected in ${arrow.id}: $p1 -> $p2');
        }

        // Direction must match the last step exactly
        final pPrev = arrow.points[arrow.points.length - 2];
        final pHead = arrow.points.last;
        final expectedDir = ArrowDirection.fromDelta(pHead.row - pPrev.row, pHead.col - pPrev.col);
        expect(arrow.direction, equals(expectedDir));
      }

      // Verify expected directions
      expect(arrows[0].direction, equals(ArrowDirection.up));
      expect(arrows[1].direction, equals(ArrowDirection.down));
      expect(arrows[2].direction, equals(ArrowDirection.left));
      expect(arrows[3].direction, equals(ArrowDirection.right));
      expect(arrows[4].direction, equals(ArrowDirection.up));
      expect(arrows[5].direction, equals(ArrowDirection.down));
      expect(arrows[6].direction, equals(ArrowDirection.left));
      expect(arrows[7].direction, equals(ArrowDirection.right));
      expect(arrows[8].direction, equals(ArrowDirection.up));
      expect(arrows[9].direction, equals(ArrowDirection.down));
      expect(arrows[10].direction, equals(ArrowDirection.left));
      expect(arrows[11].direction, equals(ArrowDirection.right));

      // Verify no shared cells among all 12 arrows
      final occupied = <GridPoint>{};
      for (final a in arrows) {
        for (final pt in a.points) {
          expect(occupied.contains(pt), isFalse, reason: 'Duplicate cell $pt in arrow ${a.id}');
          occupied.add(pt);
        }
      }

      // Verify Canvas rendering without errors
      final board = PuzzleBoard.fromList(size: 14, arrowsList: arrows);
      final painter = ArrowPainter(
        board: board,
        selectedArrowId: 'straight_up',
        selectedRay: board.getExitRay(arrows[0]),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, const Size(560, 560)), returnsNormally);
      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('ArrowModel throws AssertionError if path has diagonal jump or length < 2', () {
      expect(
        () => ArrowModel(
          id: 'invalid_short',
          points: const [GridPoint(0, 0)],
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => ArrowModel(
          id: 'invalid_diagonal',
          points: const [GridPoint(0, 0), GridPoint(1, 1)],
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

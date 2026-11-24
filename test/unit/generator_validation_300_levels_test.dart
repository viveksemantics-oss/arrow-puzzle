import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:eklavyas_aim/features/gameplay/engine/arrow_direction.dart';
import 'package:eklavyas_aim/features/gameplay/engine/arrow_model.dart';
import 'package:eklavyas_aim/features/gameplay/generator/procedural_generator.dart';
import 'package:eklavyas_aim/features/gameplay/solver/puzzle_solver.dart';

void main() {
  group('Step 2: Generator Validation - 300 Levels Across All Tiers', () {
    test('Validate levels 1 to 300 and print stats for 1, 24, 100, 300', () {
      final sampleLevels = <int>[
        // BEGINNER: 1-10
        for (int i = 1; i <= 10; i++) i,
        // EASY: 11-40
        for (int i = 11; i <= 40; i++) i,
        // MEDIUM: 41-100
        for (int i = 41; i <= 100; i++) i,
        // HARD: 101-250
        for (int i = 101; i <= 250; i++) i,
        // EXPERT: 251-300
        for (int i = 251; i <= 300; i++) i,
      ];

      expect(sampleLevels.length, equals(300), reason: 'Must validate exactly 300 levels');

      final statsTargets = {1, 24, 100, 300};

      for (final lvlNum in sampleLevels) {
        final level = ProceduralGenerator.generate(lvlNum);

        expect(level.levelNumber, equals(lvlNum));
        expect(level.arrows, isNotEmpty, reason: 'Level $lvlNum must contain arrows');
        expect(level.optimalSolution.length, equals(level.arrows.length));

        // 1. Enforce 4-connected paths, no diagonal segments
        final occupied = <GridPoint>{};
        int totalCells = 0;
        final minLen = ProceduralGenerator.getMinArrowLength(lvlNum);

        for (final a in level.arrows) {
          expect(a.points.length, greaterThanOrEqualTo(2));
          // Minimum arrow length
          expect(a.points.length, greaterThanOrEqualTo(math.min(minLen, 4)),
              reason: 'Arrow ${a.id} in level $lvlNum too short: ${a.points.length}');

          // 4-connectivity: differ by exactly 1 in row OR col, never both
          for (int i = 0; i < a.points.length - 1; i++) {
            final p1 = a.points[i];
            final p2 = a.points[i + 1];
            final dr = (p2.row - p1.row).abs();
            final dc = (p2.col - p1.col).abs();
            expect((dr == 1 && dc == 0) || (dr == 0 && dc == 1), isTrue,
                reason: 'Diagonal or disconnected segment in arrow ${a.id}: $p1 -> $p2 in level $lvlNum');
          }

          // Exit direction must match last step
          final pPrev = a.points[a.points.length - 2];
          final pHead = a.points.last;
          final expectedDir = ArrowDirection.fromDelta(pHead.row - pPrev.row, pHead.col - pPrev.col);
          expect(a.direction, equals(expectedDir));

          // No shared cells
          for (final pt in a.points) {
            expect(occupied.contains(pt), isFalse,
                reason: 'Shared cell $pt in arrow ${a.id} in level $lvlNum');
            occupied.add(pt);
          }
          totalCells += a.points.length;
        }

        // 2. Board solvability
        final board = level.createBoard();
        final isSolvable = PuzzleSolver.isSolvable(board);
        expect(isSolvable, isTrue, reason: 'Level $lvlNum must be 100% solvable');

        // 3. Free arrows ratio at start for levels > 20
        final freeAtStart = board.getClearArrows().length;
        final freeRatio = freeAtStart / level.arrows.length;
        if (lvlNum > 20) {
          expect(freeRatio, lessThan(0.35),
              reason: 'Level $lvlNum has too many free arrows at start: ${(freeRatio * 100).toStringAsFixed(1)}%');
        }

        // Print stats for specified milestone levels
        if (statsTargets.contains(lvlNum)) {
          final avgLen = totalCells / level.arrows.length;
          final depth = level.optimalSolution.length; // solution length
          // ignore: avoid_print
          print(
            'STATS Level $lvlNum (${level.difficulty}): '
            'Grid=${level.boardSize}x${level.boardSize}, '
            'Arrows=${level.arrows.length}, '
            'AvgLen=${avgLen.toStringAsFixed(1)}, '
            'FreeAtStart=$freeAtStart (${(freeRatio * 100).toStringAsFixed(1)}%), '
            'SolutionMoves=$depth',
          );
        }
      }
    });
  });
}

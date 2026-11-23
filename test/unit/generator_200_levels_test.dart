import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_escape/features/gameplay/generator/procedural_generator.dart';
import 'package:arrow_escape/features/gameplay/solver/puzzle_solver.dart';

void main() {
  group('Procedural Level Generator - 200 Sample Levels Across All Tiers', () {
    // 200 distinct levels spanning all 5 difficulty tiers:
    // Beginner (1-25): 25 levels
    // Easy (26-60): 35 levels
    // Medium (61-150): 65 levels
    // Hard (151-300): 45 levels
    // Expert (301+): 30 levels
    final sampleLevels = <int>[
      // Beginner (1-25)
      for (int i = 1; i <= 25; i++) i,
      // Easy (26-60)
      for (int i = 26; i <= 60; i++) i,
      // Medium (61-150)
      for (int i = 61; i <= 125; i++) i,
      // Hard (151-300)
      for (int i = 151; i <= 195; i++) i,
      // Expert (301+)
      for (int i = 301; i <= 330; i++) i,
    ];

    test('Verifies that all 200 sample levels across all 5 tiers are 100% solvable', () {
      expect(sampleLevels.length, equals(200), reason: 'Must test exactly 200 sample levels');

      for (final lvlNum in sampleLevels) {
        final level = ProceduralGenerator.generate(lvlNum);

        expect(level.levelNumber, equals(lvlNum));
        expect(level.arrows, isNotEmpty, reason: 'Level $lvlNum must contain arrows');
        expect(level.optimalSolution.length, equals(level.arrows.length));

        // Create board and verify solvability with the solver
        final board = level.createBoard();
        final isSolvable = PuzzleSolver.isSolvable(board);
        expect(
          isSolvable,
          isTrue,
          reason: 'Level $lvlNum (${level.difficulty}) must be 100% solvable with zero deadlocks',
        );

        // Verify that executing the optimalSolution step-by-step clears the board with zero collisions
        for (final arrowId in level.optimalSolution) {
          final arrow = board.getArrowById(arrowId);
          expect(arrow, isNotNull);
          expect(arrow!.isActive, isTrue);
          expect(
            board.isPathClear(arrow),
            isTrue,
            reason: 'Arrow $arrowId in level $lvlNum must have a completely clear exit path when its turn arrives',
          );
          board.setArrowActive(arrowId, false);
        }

        expect(board.isCleared, isTrue, reason: 'Board must be completely cleared after all moves');
      }
    });

    test('Verifies deterministic repeatability: Level N produces identical output across calls', () {
      const testCases = [1, 24, 100, 300];
      for (final lvlNum in testCases) {
        final levelA = ProceduralGenerator.generate(lvlNum);
        final levelB = ProceduralGenerator.generate(lvlNum);

        expect(levelA.arrows.length, equals(levelB.arrows.length));
        expect(levelA.boardSize, equals(levelB.boardSize));
        expect(levelA.seed, equals(levelB.seed));
        expect(levelA.difficulty, equals(levelB.difficulty));
        expect(levelA.optimalSolution, equals(levelB.optimalSolution));
      }
    });
  });
}

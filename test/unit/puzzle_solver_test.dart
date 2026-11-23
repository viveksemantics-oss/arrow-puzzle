import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_escape/features/gameplay/engine/arrow_direction.dart';
import 'package:arrow_escape/features/gameplay/engine/arrow_model.dart';
import 'package:arrow_escape/features/gameplay/engine/puzzle_board.dart';
import 'package:arrow_escape/features/gameplay/solver/level_generator.dart';
import 'package:arrow_escape/features/gameplay/solver/puzzle_solver.dart';

void main() {
  group('PuzzleSolver Tests', () {
    test('Identifies solvable puzzle and returns correct sequence', () {
      final a1 = const ArrowModel(
        id: 'a1',
        row: 0,
        col: 0,
        direction: ArrowDirection.right,
      );
      final a2 = const ArrowModel(
        id: 'a2',
        row: 0,
        col: 2,
        direction: ArrowDirection.down,
      );
      final board = PuzzleBoard.fromList(size: 3, arrowsList: [a1, a2]);

      expect(PuzzleSolver.isSolvable(board), isTrue);
      final solution = PuzzleSolver.solve(board);
      expect(solution, isNotNull);
      expect(solution, equals(['a2', 'a1']));
    });

    test('Detects deadlocked circular puzzle', () {
      // 4 arrows facing each other in a circle
      // (0, 0) -> RIGHT into (0, 1)
      // (0, 1) -> DOWN into (1, 1)
      // (1, 1) -> LEFT into (1, 0)
      // (1, 0) -> UP into (0, 0)
      final circle = [
        const ArrowModel(id: 'c1', row: 0, col: 0, direction: ArrowDirection.right),
        const ArrowModel(id: 'c2', row: 0, col: 1, direction: ArrowDirection.down),
        const ArrowModel(id: 'c3', row: 1, col: 1, direction: ArrowDirection.left),
        const ArrowModel(id: 'c4', row: 1, col: 0, direction: ArrowDirection.up),
      ];
      final board = PuzzleBoard.fromList(size: 2, arrowsList: circle);

      expect(PuzzleSolver.findAvailableArrows(board), isEmpty);
      expect(PuzzleSolver.isSolvable(board), isFalse);
      expect(PuzzleSolver.solve(board), isNull);
    });
  });

  group('LevelGenerator Reverse-Construction Tests', () {
    test('Generates 10 solvable test levels of varying sizes', () {
      final testConfigs = [
        {'size': 4, 'arrows': 6, 'difficulty': 'Beginner'},
        {'size': 4, 'arrows': 8, 'difficulty': 'Beginner'},
        {'size': 5, 'arrows': 10, 'difficulty': 'Easy'},
        {'size': 5, 'arrows': 12, 'difficulty': 'Easy'},
        {'size': 6, 'arrows': 14, 'difficulty': 'Medium'},
        {'size': 6, 'arrows': 16, 'difficulty': 'Medium'},
        {'size': 7, 'arrows': 18, 'difficulty': 'Hard'},
        {'size': 8, 'arrows': 22, 'difficulty': 'Hard'},
        {'size': 9, 'arrows': 26, 'difficulty': 'Expert'},
        {'size': 10, 'arrows': 30, 'difficulty': 'Expert'},
      ];

      for (int i = 0; i < testConfigs.length; i++) {
        final cfg = testConfigs[i];
        final level = LevelGenerator.generateLevel(
          levelNumber: i + 1,
          boardSize: cfg['size'] as int,
          seed: 1000 + i,
          arrowCount: cfg['arrows'] as int,
          difficulty: cfg['difficulty'] as String,
        );

        expect(level.arrows.length, equals(cfg['arrows']));
        expect(level.optimalSolution.length, equals(cfg['arrows']));

        // Verify board is 100% solvable
        final board = level.createBoard();
        expect(PuzzleSolver.isSolvable(board), isTrue);

        // Execute solution step by step
        for (final arrowId in level.optimalSolution) {
          final arrow = board.getArrowById(arrowId);
          expect(arrow, isNotNull);
          expect(board.isPathClear(arrow!), isTrue);
          board.setArrowActive(arrowId, false);
        }

        expect(board.isCleared, isTrue);
      }
    });
  });
}

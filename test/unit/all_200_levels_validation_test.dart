import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_escape/features/gameplay/models/level_model.dart';
import 'package:arrow_escape/features/gameplay/solver/puzzle_solver.dart';

void main() {
  group('200 Winding Levels Automated Verification Test', () {
    test('Verifies that all 200 levels in assets/levels/levels.json are valid and solvable', () {
      final file = File('assets/levels/levels.json');
      expect(file.existsSync(), isTrue, reason: 'assets/levels/levels.json must exist');

      final jsonContent = file.readAsStringSync();
      final List<dynamic> jsonList = jsonDecode(jsonContent) as List<dynamic>;

      expect(jsonList.length, equals(200), reason: 'There must be exactly 200 levels');

      for (int i = 0; i < jsonList.length; i++) {
        final levelMap = jsonList[i] as Map<String, dynamic>;
        final level = LevelModel.fromJson(levelMap);

        expect(level.levelNumber, equals(i + 1));
        expect(level.arrows, isNotEmpty);
        expect(level.boardSize, inInclusiveRange(6, 18));
        expect(level.optimalSolution.length, equals(level.arrows.length));

        // Create board and verify solvability
        final board = level.createBoard();
        expect(
          PuzzleSolver.isSolvable(board),
          isTrue,
          reason: 'Level ${level.levelNumber} must be solvable',
        );

        // Verify the optimalSolution clears every single arrow in order
        for (final arrowId in level.optimalSolution) {
          final arrow = board.getArrowById(arrowId);
          expect(arrow, isNotNull, reason: 'Arrow $arrowId should exist in level ${level.levelNumber}');
          expect(arrow!.isActive, isTrue, reason: 'Arrow $arrowId must be active before removal');
          expect(
            board.isPathClear(arrow),
            isTrue,
            reason: 'Arrow $arrowId path must be clear when its turn arrives in level ${level.levelNumber}',
          );
          board.setArrowActive(arrowId, false);
        }

        expect(
          board.isCleared,
          isTrue,
          reason: 'Level ${level.levelNumber} must be fully cleared after executing optimal solution',
        );
      }
    });
  });
}

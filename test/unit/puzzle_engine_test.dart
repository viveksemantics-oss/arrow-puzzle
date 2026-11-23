import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_escape/features/gameplay/engine/arrow_direction.dart';
import 'package:arrow_escape/features/gameplay/engine/arrow_model.dart';
import 'package:arrow_escape/features/gameplay/engine/move_result.dart';
import 'package:arrow_escape/features/gameplay/engine/puzzle_board.dart';
import 'package:arrow_escape/features/gameplay/engine/puzzle_engine.dart';

void main() {
  group('ArrowDirection Tests', () {
    test('Verifies delta x and y for cardinal directions', () {
      expect(ArrowDirection.up.dy, equals(-1));
      expect(ArrowDirection.up.dx, equals(0));

      expect(ArrowDirection.down.dy, equals(1));
      expect(ArrowDirection.down.dx, equals(0));

      expect(ArrowDirection.left.dy, equals(0));
      expect(ArrowDirection.left.dx, equals(-1));

      expect(ArrowDirection.right.dy, equals(0));
      expect(ArrowDirection.right.dx, equals(1));
    });

    test('Verifies opposite directions', () {
      expect(ArrowDirection.up.opposite, equals(ArrowDirection.down));
      expect(ArrowDirection.down.opposite, equals(ArrowDirection.up));
      expect(ArrowDirection.left.opposite, equals(ArrowDirection.right));
      expect(ArrowDirection.right.opposite, equals(ArrowDirection.left));
    });

    test('Parses from string correctly', () {
      expect(ArrowDirection.fromString('up'), equals(ArrowDirection.up));
      expect(ArrowDirection.fromString('DOWN'), equals(ArrowDirection.down));
      expect(ArrowDirection.fromString('left'), equals(ArrowDirection.left));
      expect(ArrowDirection.fromString('Right'), equals(ArrowDirection.right));
    });
  });

  group('PuzzleBoard & Raycasting Tests', () {
    test('Unblocked arrow points out of board', () {
      final arrow = const ArrowModel(
        id: 'a1',
        row: 0,
        col: 0,
        direction: ArrowDirection.up,
      );
      final board = PuzzleBoard.fromList(size: 4, arrowsList: [arrow]);

      expect(board.isPathClear(arrow), isTrue);
      expect(board.getFirstBlockingArrow(arrow), isNull);
    });

    test('Blocked arrow detects blocker in its trajectory', () {
      // a1 at (1, 1) pointing UP, blocked by a2 at (0, 1)
      final a1 = const ArrowModel(
        id: 'a1',
        row: 1,
        col: 1,
        direction: ArrowDirection.up,
      );
      final a2 = const ArrowModel(
        id: 'a2',
        row: 0,
        col: 1,
        direction: ArrowDirection.left,
      );
      final board = PuzzleBoard.fromList(size: 4, arrowsList: [a1, a2]);

      expect(board.isPathClear(a1), isFalse);
      expect(board.getFirstBlockingArrow(a1)?.id, equals('a2'));
      // a2 points LEFT towards col 0 which is empty, so a2 is clear
      expect(board.isPathClear(a2), isTrue);
    });

    test('Inactive arrow does not block path', () {
      final a1 = const ArrowModel(
        id: 'a1',
        row: 2,
        col: 0,
        direction: ArrowDirection.up,
      );
      final a2 = const ArrowModel(
        id: 'a2',
        row: 1,
        col: 0,
        direction: ArrowDirection.right,
        isActive: false, // Inactive
      );
      final board = PuzzleBoard.fromList(size: 4, arrowsList: [a1, a2]);

      expect(board.isPathClear(a1), isTrue);
    });
  });

  group('PuzzleEngine Gameplay Mechanics Tests', () {
    late PuzzleBoard board;
    late PuzzleEngine engine;

    setUp(() {
      // Board layout:
      // (0, 0) -> RIGHT (a1)
      // (0, 1) -> DOWN  (a2)
      // a1 points into (0, 1) which has a2, so a1 is blocked by a2
      // a2 points down into (1, 1) which is empty, so a2 is clear!
      final a1 = const ArrowModel(
        id: 'a1',
        row: 0,
        col: 0,
        direction: ArrowDirection.right,
      );
      final a2 = const ArrowModel(
        id: 'a2',
        row: 0,
        col: 1,
        direction: ArrowDirection.down,
      );
      board = PuzzleBoard.fromList(size: 4, arrowsList: [a1, a2]);
      engine = PuzzleEngine(board: board);
    });

    test('Tapping blocked arrow returns MoveStatus.blocked and shakes', () {
      final result = engine.tapArrow('a1');

      expect(result.status, equals(MoveStatus.blocked));
      expect(result.blockingArrow?.id, equals('a2'));
      expect(result.isSuccess, isFalse);
      expect(engine.remainingArrows, equals(2));
      expect(board.getArrowById('a1')?.isShaking, isTrue);
    });

    test('Tapping clear arrow exits successfully and decrements remaining', () {
      final result = engine.tapArrow('a2');

      expect(result.status, equals(MoveStatus.success));
      expect(result.isSuccess, isTrue);
      expect(engine.remainingArrows, equals(1));
      expect(board.getArrowById('a2')?.isActive, isFalse);

      // Now a1's path is unblocked!
      expect(board.isPathClear(board.getArrowById('a1')!), isTrue);

      // Tapping a1 now completes the puzzle
      final result2 = engine.tapArrow('a1');
      expect(result2.status, equals(MoveStatus.completed));
      expect(result2.isGameWon, isTrue);
      expect(engine.isWon, isTrue);
    });

    test('Undo restores last removed arrow correctly', () {
      engine.tapArrow('a2');
      expect(engine.remainingArrows, equals(1));
      expect(engine.canUndo, isTrue);

      final restored = engine.undo();
      expect(restored?.id, equals('a2'));
      expect(restored?.isActive, isTrue);
      expect(engine.remainingArrows, equals(2));
      expect(engine.moveCount, equals(0));
    });

    test('Restart resets board, move count, and undo stack', () {
      engine.tapArrow('a2');
      engine.tapArrow('a1');
      expect(engine.isWon, isTrue);

      engine.restart();
      expect(engine.isWon, isFalse);
      expect(engine.remainingArrows, equals(2));
      expect(engine.moveCount, equals(0));
      expect(engine.canUndo, isFalse);
      expect(board.getArrowById('a1')?.isActive, isTrue);
      expect(board.getArrowById('a2')?.isActive, isTrue);
    });

    test('Hint highlights unblocked arrow', () {
      final hint = engine.requestHint();
      expect(hint?.id, equals('a2'));
      expect(engine.currentHintArrowId, equals('a2'));
      expect(board.getArrowById('a2')?.isHighlighted, isTrue);

      // Tapping clears the hint
      engine.tapArrow('a2');
      expect(engine.currentHintArrowId, isNull);
    });
  });
}

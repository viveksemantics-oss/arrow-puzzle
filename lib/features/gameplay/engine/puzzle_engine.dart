import 'arrow_model.dart';
import 'move_result.dart';
import 'puzzle_board.dart';

/// The core puzzle engine that manages gameplay state, moves, undo, and rules.
class PuzzleEngine {
  final PuzzleBoard board;
  final List<String> _undoStack = [];
  int _moveCount = 0;
  String? _currentHintArrowId;

  PuzzleEngine({required this.board});

  int get moveCount => _moveCount;
  int get remainingArrows => board.activeArrowCount;
  bool get isWon => board.isCleared;
  bool get canUndo => _undoStack.isNotEmpty;
  String? get currentHintArrowId => _currentHintArrowId;

  /// Attempts to move an arrow identified by [arrowId].
  MoveResult tapArrow(String arrowId) {
    final arrow = board.getArrowById(arrowId);
    if (arrow == null || !arrow.isActive) {
      return MoveResult(
        status: MoveStatus.invalid,
        remainingArrows: remainingArrows,
      );
    }

    // Clear any active hint highlight upon user action
    clearHint();

    // Check if path is clear
    if (board.isPathClear(arrow)) {
      // Remove arrow from active board
      board.setArrowActive(arrowId, false);
      _undoStack.add(arrowId);
      _moveCount++;

      final won = board.isCleared;
      return MoveResult(
        status: won ? MoveStatus.completed : MoveStatus.success,
        movedArrow: arrow,
        remainingArrows: remainingArrows,
        isGameWon: won,
      );
    } else {
      // Blocked move: detect blocking arrow and ray
      final blocker = board.getFirstBlockingArrow(arrow);
      final ray = board.getBlockedRay(arrow);
      board.setArrowShaking(arrowId, true);

      return MoveResult(
        status: MoveStatus.blocked,
        movedArrow: arrow,
        blockingArrow: blocker,
        blockedRay: ray,
        remainingArrows: remainingArrows,
        isGameWon: false,
      );
    }
  }

  /// Taps an arrow at a specific grid row and col.
  MoveResult tapAt(int row, int col) {
    final arrow = board.getActiveArrowAt(row, col);
    if (arrow == null) {
      return MoveResult(
        status: MoveStatus.invalid,
        remainingArrows: remainingArrows,
      );
    }
    return tapArrow(arrow.id);
  }

  /// Undoes the last move, restoring the arrow.
  ArrowModel? undo() {
    if (!canUndo) return null;
    final lastArrowId = _undoStack.removeLast();
    board.setArrowActive(lastArrowId, true);
    if (_moveCount > 0) _moveCount--;
    clearHint();
    return board.getArrowById(lastArrowId);
  }

  /// Restores the board to its initial state.
  void restart() {
    _undoStack.clear();
    _moveCount = 0;
    clearHint();
    board.clearAllHighlights();
    board.clearAllShaking();
    for (final arrow in board.arrows.values) {
      board.setArrowActive(arrow.id, true);
    }
  }

  /// Requests a hint. Finds an available unblocked arrow and highlights it.
  ArrowModel? requestHint() {
    clearHint();
    final clearArrows = board.getClearArrows();
    if (clearArrows.isEmpty) return null;

    final hintArrow = clearArrows.first;
    _currentHintArrowId = hintArrow.id;
    board.setArrowHighlighted(hintArrow.id, true);
    return hintArrow;
  }

  /// Clears active hint highlights.
  void clearHint() {
    if (_currentHintArrowId != null) {
      board.setArrowHighlighted(_currentHintArrowId!, false);
      _currentHintArrowId = null;
    }
  }

  /// Clears shaking feedback on arrows.
  void clearShaking() {
    board.clearAllShaking();
  }
}

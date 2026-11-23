import '../engine/arrow_model.dart';
import '../engine/puzzle_board.dart';

/// Intelligent solver for the Arrow Escape puzzle.
class PuzzleSolver {
  /// Returns all currently available unblocked arrows.
  static List<ArrowModel> findAvailableArrows(PuzzleBoard board) {
    return board.getClearArrows();
  }

  /// Solves the puzzle by finding a complete sequence of arrow IDs to exit the board.
  ///
  /// Returns the sequence of arrow IDs that solves the board, or null if deadlocked/unsolvable.
  static List<String>? solve(PuzzleBoard board) {
    final clonedBoard = board.clone();
    final solutionSequence = <String>[];
    final totalArrows = clonedBoard.activeArrowCount;

    while (clonedBoard.activeArrowCount > 0) {
      final available = clonedBoard.getClearArrows();
      if (available.isEmpty) {
        // Deadlock detected: remaining arrows block each other cyclically
        return null;
      }

      // Pick an available arrow (heuristic: prioritize arrow that unblocks others)
      ArrowModel bestArrow = available.first;
      int maxUnblocked = -1;

      for (final candidate in available) {
        // Lookahead 1 step: simulate removing candidate
        clonedBoard.setArrowActive(candidate.id, false);
        final nextAvailableCount = clonedBoard.getClearArrows().length;
        clonedBoard.setArrowActive(candidate.id, true);

        if (nextAvailableCount > maxUnblocked) {
          maxUnblocked = nextAvailableCount;
          bestArrow = candidate;
        }
      }

      // Execute best move
      clonedBoard.setArrowActive(bestArrow.id, false);
      solutionSequence.add(bestArrow.id);
    }

    if (solutionSequence.length == totalArrows) {
      return solutionSequence;
    }
    return null;
  }

  /// Checks if the board has a valid, complete solution.
  static bool isSolvable(PuzzleBoard board) {
    final solution = solve(board);
    return solution != null && solution.length == board.activeArrowCount;
  }

  /// Calculates the dependency depth of a board (how many sequential waves of arrows must be removed).
  static int calculateDependencyDepth(PuzzleBoard board) {
    final clonedBoard = board.clone();
    int waves = 0;

    while (clonedBoard.activeArrowCount > 0) {
      final available = clonedBoard.getClearArrows();
      if (available.isEmpty) return -1; // Unsolvable

      for (final a in available) {
        clonedBoard.setArrowActive(a.id, false);
      }
      waves++;
    }

    return waves;
  }
}

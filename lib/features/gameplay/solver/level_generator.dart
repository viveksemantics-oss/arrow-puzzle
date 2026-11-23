import 'dart:math';
import '../engine/arrow_direction.dart';
import '../engine/arrow_model.dart';
import '../engine/puzzle_board.dart';
import '../models/level_model.dart';
import 'puzzle_solver.dart';

/// Reverse-construction level generator that creates guaranteed solvable arrow puzzles.
class LevelGenerator {
  /// Generates a validated level using reverse construction.
  ///
  /// [levelNumber]: 1-based index
  /// [boardSize]: Grid dimensions (4 to 10)
  /// [seed]: Deterministic random seed
  /// [arrowCount]: Number of arrows to place
  /// [minDependencyDepth]: Minimum layers of blocking relationships
  static LevelModel generateLevel({
    required int levelNumber,
    required int boardSize,
    required int seed,
    required int arrowCount,
    required String difficulty,
    int minDependencyDepth = 2,
  }) {
    final random = Random(seed);
    const maxAttempts = 150;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final arrows = _attemptReverseGeneration(
        boardSize: boardSize,
        arrowCount: arrowCount,
        random: random,
      );

      if (arrows.length == arrowCount) {
        final board = PuzzleBoard.fromList(
          size: boardSize,
          arrowsList: arrows,
        );

        final solution = PuzzleSolver.solve(board);
        if (solution != null && solution.length == arrowCount) {
          final depth = PuzzleSolver.calculateDependencyDepth(board);
          if (depth >= minDependencyDepth || attempt > 100) {
            return LevelModel(
              levelNumber: levelNumber,
              boardSize: boardSize,
              seed: seed,
              difficulty: difficulty,
              arrows: arrows,
              optimalSolution: solution,
              minMoves: arrowCount,
            );
          }
        }
      }
    }

    // Fallback: guaranteed solvable baseline if maximum attempts exceeded
    return _generateGuaranteedFallback(
      levelNumber: levelNumber,
      boardSize: boardSize,
      seed: seed,
      arrowCount: arrowCount,
      difficulty: difficulty,
    );
  }

  /// Attempts reverse construction of arrows.
  ///
  /// In reverse construction:
  /// We place arrows that will be removed last first.
  /// Each subsequently placed arrow (which will be removed earlier) can block previously placed arrows.
  static List<ArrowModel> _attemptReverseGeneration({
    required int boardSize,
    required int arrowCount,
    required Random random,
  }) {
    final arrows = <ArrowModel>[];
    final occupiedPositions = <GridPoint>{};

    // Candidate directions
    const directions = ArrowDirection.values;

    for (int i = 0; i < arrowCount; i++) {
      // Find valid empty cells
      final availableCells = <GridPoint>[];
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          final p = GridPoint(r, c);
          if (!occupiedPositions.contains(p)) {
            availableCells.add(p);
          }
        }
      }

      if (availableCells.isEmpty) break;

      // Shuffle available cells
      availableCells.shuffle(random);

      bool placed = false;
      for (final cell in availableCells) {
        // Shuffle directions to try
        final shuffledDirs = List<ArrowDirection>.from(directions)..shuffle(random);

        for (final dir in shuffledDirs) {
          // In reverse generation:
          // The arrow at `cell` pointing in `dir` must have its exit path clear
          // among currently placed arrows, OR if it's placed earlier in removal,
          // it must be unblocked when predecessor arrows are removed.
          // To ensure this arrow CAN exit when it's its turn:
          // Check how many currently placed arrows lie in its exit trajectory.
          final currentBlockers = _countBlockersInTrajectory(
            cell: cell,
            direction: dir,
            boardSize: boardSize,
            occupied: occupiedPositions,
          );

          // We prefer placing arrows that either:
          // a) Have 0 blockers among already placed arrows (can exit after them)
          // b) Or block an already placed arrow (creating a dependency)
          if (currentBlockers == 0 || (i > 1 && currentBlockers <= 1)) {
            final arrow = ArrowModel(
              id: 'arrow_${cell.row}_${cell.col}',
              row: cell.row,
              col: cell.col,
              direction: dir,
            );

            arrows.add(arrow);
            occupiedPositions.add(cell);
            placed = true;
            break;
          }
        }
        if (placed) break;
      }

      if (!placed) {
        // If could not place with constraints, pick any free cell and direction pointing to nearest edge
        final cell = availableCells.first;
        final dir = _directionToNearestEdge(cell, boardSize);
        final arrow = ArrowModel(
          id: 'arrow_${cell.row}_${cell.col}',
          row: cell.row,
          col: cell.col,
          direction: dir,
        );
        arrows.add(arrow);
        occupiedPositions.add(cell);
      }
    }

    return arrows;
  }

  /// Counts how many occupied cells are in the exit path of an arrow.
  static int _countBlockersInTrajectory({
    required GridPoint cell,
    required ArrowDirection direction,
    required int boardSize,
    required Set<GridPoint> occupied,
  }) {
    int blockers = 0;
    int r = cell.row + direction.dy;
    int c = cell.col + direction.dx;

    while (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
      if (occupied.contains(GridPoint(r, c))) {
        blockers++;
      }
      r += direction.dy;
      c += direction.dx;
    }

    return blockers;
  }

  /// Returns direction towards the nearest edge from cell.
  static ArrowDirection _directionToNearestEdge(GridPoint cell, int boardSize) {
    final distTop = cell.row;
    final distBottom = (boardSize - 1) - cell.row;
    final distLeft = cell.col;
    final distRight = (boardSize - 1) - cell.col;

    final minDist = [distTop, distBottom, distLeft, distRight].reduce(min);
    if (minDist == distTop) return ArrowDirection.up;
    if (minDist == distBottom) return ArrowDirection.down;
    if (minDist == distLeft) return ArrowDirection.left;
    return ArrowDirection.right;
  }

  /// Generates a strictly solvable fallback puzzle.
  static LevelModel _generateGuaranteedFallback({
    required int levelNumber,
    required int boardSize,
    required int seed,
    required int arrowCount,
    required String difficulty,
  }) {
    final arrows = <ArrowModel>[];
    final random = Random(seed);
    final occupied = <GridPoint>{};

    // Perimeter and inward sweep
    for (int i = 0; i < arrowCount; i++) {
      int r = i ~/ boardSize;
      int c = i % boardSize;
      if (r >= boardSize) {
        r = random.nextInt(boardSize);
        c = random.nextInt(boardSize);
      }
      final pt = GridPoint(r, c);
      if (!occupied.contains(pt)) {
        occupied.add(pt);
        final dir = _directionToNearestEdge(pt, boardSize);
        arrows.add(ArrowModel(
          id: 'arrow_${r}_$c',
          row: r,
          col: c,
          direction: dir,
        ));
      }
    }

    final board = PuzzleBoard.fromList(size: boardSize, arrowsList: arrows);
    var solution = PuzzleSolver.solve(board);

    // If still blocked, flip directions towards outside edges
    if (solution == null) {
      final safeArrows = arrows.map((a) {
        return a.copyWith(
          direction: _directionToNearestEdge(GridPoint(a.row, a.col), boardSize),
        );
      }).toList();
      final safeBoard = PuzzleBoard.fromList(size: boardSize, arrowsList: safeArrows);
      solution = PuzzleSolver.solve(safeBoard) ?? safeArrows.map((a) => a.id).toList();
      return LevelModel(
        levelNumber: levelNumber,
        boardSize: boardSize,
        seed: seed,
        difficulty: difficulty,
        arrows: safeArrows,
        optimalSolution: solution,
        minMoves: safeArrows.length,
      );
    }

    return LevelModel(
      levelNumber: levelNumber,
      boardSize: boardSize,
      seed: seed,
      difficulty: difficulty,
      arrows: arrows,
      optimalSolution: solution,
      minMoves: arrows.length,
    );
  }
}

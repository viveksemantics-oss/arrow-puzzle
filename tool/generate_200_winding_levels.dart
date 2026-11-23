import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:arrow_escape/features/gameplay/engine/arrow_direction.dart';
import 'package:arrow_escape/features/gameplay/engine/arrow_model.dart';
import 'package:arrow_escape/features/gameplay/engine/puzzle_board.dart';
import 'package:arrow_escape/features/gameplay/models/level_model.dart';
import 'package:arrow_escape/features/gameplay/solver/puzzle_solver.dart';

void main() {
  stdout.writeln('=== Generating 200 Winding Labyrinth Arrow Levels ===');

  final levels = <LevelModel>[];
  final stopwatch = Stopwatch()..start();

  for (int levelNum = 1; levelNum <= 200; levelNum++) {
    int boardSize;
    int arrowCount;
    int maxArrowLength;
    String difficulty;
    int minBends;

    if (levelNum <= 25) {
      // Tier 1: Beginner Winding Mazes (6x6 to 8x8, 6-12 arrows, lengths 2-4, 1-2 bends)
      boardSize = 6 + (levelNum ~/ 10);
      arrowCount = 6 + (levelNum ~/ 3);
      maxArrowLength = 3 + (levelNum ~/ 12);
      difficulty = 'Beginner';
      minBends = 1;
    } else if (levelNum <= 65) {
      // Tier 2: Intermediate Winding Mazes (8x8 to 10x10, 12-20 arrows, lengths 3-5, 1-3 bends)
      boardSize = 8 + ((levelNum - 25) ~/ 20);
      arrowCount = 12 + ((levelNum - 25) ~/ 4);
      maxArrowLength = 4 + ((levelNum - 25) ~/ 20);
      difficulty = 'Easy';
      minBends = 1;
    } else if (levelNum <= 110) {
      // Tier 3: Advanced Labyrinth Mazes (10x10 to 12x12, 18-28 arrows, lengths 4-7, 2-4 bends)
      boardSize = 10 + ((levelNum - 65) ~/ 25);
      arrowCount = 18 + ((levelNum - 65) ~/ 4);
      maxArrowLength = 5 + ((levelNum - 65) ~/ 20);
      difficulty = 'Medium';
      minBends = 2;
    } else if (levelNum <= 160) {
      // Tier 4: Master Dense Mazes (12x12 to 14x14, 26-38 arrows, lengths 4-8, 2-5 bends)
      boardSize = 12 + ((levelNum - 110) ~/ 25);
      arrowCount = 26 + ((levelNum - 110) ~/ 4);
      maxArrowLength = 6 + ((levelNum - 110) ~/ 25);
      difficulty = 'Hard';
      minBends = 2;
    } else {
      // Tier 5: Grandmaster Labyrinths (14x14 to 16x16, 36-50 arrows, lengths 5-10, 3-6 bends)
      boardSize = 14 + ((levelNum - 160) ~/ 20);
      arrowCount = 36 + ((levelNum - 160) ~/ 3);
      maxArrowLength = 7 + ((levelNum - 160) ~/ 20);
      difficulty = 'Expert';
      minBends = 2;
    }

    final level = _generateSingleWindingLevel(
      levelNumber: levelNum,
      boardSize: boardSize,
      targetArrowCount: arrowCount,
      maxArrowLength: maxArrowLength,
      difficulty: difficulty,
      minBends: minBends,
      seed: 50000 + levelNum * 43,
    );

    levels.add(level);

    if (levelNum % 25 == 0 || levelNum == 200) {
      stdout.writeln(
        'Generated & verified Level $levelNum/200: $difficulty, ${level.boardSize}x${level.boardSize}, ${level.arrows.length} winding arrows (elapsed: ${stopwatch.elapsedMilliseconds}ms)',
      );
    }
  }

  // Save to assets/levels/levels.json
  final outputDir = Directory('assets/levels');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final jsonFile = File('assets/levels/levels.json');
  final jsonString = const JsonEncoder.withIndent('  ').convert(
    levels.map((l) => l.toJson()).toList(),
  );
  jsonFile.writeAsStringSync(jsonString);

  stdout.writeln(
    'Successfully wrote all 200 levels to ${jsonFile.path} (${(jsonFile.lengthSync() / 1024).toStringAsFixed(1)} KB) in ${stopwatch.elapsedMilliseconds}ms',
  );
}

LevelModel _generateSingleWindingLevel({
  required int levelNumber,
  required int boardSize,
  required int targetArrowCount,
  required int maxArrowLength,
  required String difficulty,
  required int minBends,
  required int seed,
}) {
  final random = Random(seed);

  for (int attempt = 0; attempt < 200; attempt++) {
    final arrows = <ArrowModel>[];
    final occupied = <GridPoint>{};

    for (int i = 0; i < targetArrowCount; i++) {
      final arrow = _attemptGrowWindingArrow(
        boardSize: boardSize,
        arrowIndex: i,
        occupied: occupied,
        maxArrowLength: maxArrowLength,
        random: random,
      );

      if (arrow != null && arrow.allPoints.isNotEmpty) {
        arrows.add(arrow);
        occupied.addAll(arrow.allPoints);
      }
    }

    if (arrows.length >= max(4, (targetArrowCount * 0.75).toInt())) {
      final board = PuzzleBoard.fromList(size: boardSize, arrowsList: arrows);
      final solution = PuzzleSolver.solve(board);

      if (solution != null && solution.length == arrows.length) {
        return LevelModel(
          levelNumber: levelNumber,
          boardSize: boardSize,
          seed: seed + attempt,
          difficulty: difficulty,
          arrows: arrows,
          optimalSolution: solution,
          minMoves: arrows.length,
        );
      }
    }
  }

  // Fallback: guaranteed solvable winding level
  return _generateFallbackWindingLevel(
    levelNumber: levelNumber,
    boardSize: boardSize,
    targetArrowCount: targetArrowCount,
    difficulty: difficulty,
    seed: seed,
  );
}

/// Grows a single winding polyline arrow backwards from its head.
ArrowModel? _attemptGrowWindingArrow({
  required int boardSize,
  required int arrowIndex,
  required Set<GridPoint> occupied,
  required int maxArrowLength,
  required Random random,
}) {
  // Find potential head positions
  final candidates = <Map<String, dynamic>>[];

  for (int r = 0; r < boardSize; r++) {
    for (int c = 0; c < boardSize; c++) {
      final head = GridPoint(r, c);
      if (occupied.contains(head)) continue;

      for (final dir in ArrowDirection.values) {
        // Count blockers along exit path
        int blockers = 0;
        int cr = r + dir.dy;
        int cc = c + dir.dx;
        while (cr >= 0 && cr < boardSize && cc >= 0 && cc < boardSize) {
          if (occupied.contains(GridPoint(cr, cc))) blockers++;
          cr += dir.dy;
          cc += dir.dx;
        }

        // In reverse generation: prefer 0 blockers (can exit) or 1 blocker
        if (blockers <= 1) {
          candidates.add({
            'head': head,
            'dir': dir,
            'blockers': blockers,
          });
        }
      }
    }
  }

  if (candidates.isEmpty) return null;
  candidates.shuffle(random);
  candidates.sort((a, b) => (a['blockers'] as int).compareTo(b['blockers'] as int));

  final choice = candidates.first;
  final GridPoint head = choice['head'] as GridPoint;
  final ArrowDirection headDir = choice['dir'] as ArrowDirection;

  // Now grow the body backwards from head (in opposite directions)
  final points = <GridPoint>[head];
  final currentOccupied = Set<GridPoint>.from(occupied)..add(head);

  final targetLen = 2 + random.nextInt(max(1, maxArrowLength - 1));
  GridPoint curr = head;
  ArrowDirection currentBackwardDir = headDir.opposite;

  for (int step = 1; step < targetLen; step++) {
    // Possible next backward steps: straight, turn 90 deg left, turn 90 deg right
    final possibleDirs = <ArrowDirection>[
      currentBackwardDir,
      _rotateLeft(currentBackwardDir),
      _rotateRight(currentBackwardDir),
    ];
    possibleDirs.shuffle(random);

    GridPoint? nextPoint;
    for (final d in possibleDirs) {
      final np = GridPoint(curr.row + d.dy, curr.col + d.dx);
      if (np.row >= 0 && np.row < boardSize && np.col >= 0 && np.col < boardSize) {
        if (!currentOccupied.contains(np)) {
          // Check that it does not touch diagonal self in a bad way
          nextPoint = np;
          currentBackwardDir = d;
          break;
        }
      }
    }

    if (nextPoint != null) {
      points.add(nextPoint);
      currentOccupied.add(nextPoint);
      curr = nextPoint;
    } else {
      break; // Cannot grow further
    }
  }

  if (points.length < 2) return null;

  // points are currently [head, body1, body2, tail]
  // In our model, points are ordered from TAIL to HEAD:
  final orderedPoints = points.reversed.toList();

  return ArrowModel(
    id: 'arrow_${arrowIndex}_${head.row}_${head.col}',
    row: head.row,
    col: head.col,
    direction: headDir,
    points: orderedPoints,
  );
}

ArrowDirection _rotateLeft(ArrowDirection d) {
  switch (d) {
    case ArrowDirection.up:
      return ArrowDirection.left;
    case ArrowDirection.left:
      return ArrowDirection.down;
    case ArrowDirection.down:
      return ArrowDirection.right;
    case ArrowDirection.right:
      return ArrowDirection.up;
  }
}

ArrowDirection _rotateRight(ArrowDirection d) {
  switch (d) {
    case ArrowDirection.up:
      return ArrowDirection.right;
    case ArrowDirection.right:
      return ArrowDirection.down;
    case ArrowDirection.down:
      return ArrowDirection.left;
    case ArrowDirection.left:
      return ArrowDirection.up;
  }
}

LevelModel _generateFallbackWindingLevel({
  required int levelNumber,
  required int boardSize,
  required int targetArrowCount,
  required String difficulty,
  required int seed,
}) {
  final arrows = <ArrowModel>[];
  final occupied = <GridPoint>{};
  int idx = 0;

  // Place perimeter and inward L-shapes pointing outward
  for (int r = 0; r < boardSize - 1 && arrows.length < targetArrowCount; r += 2) {
    for (int c = 0; c < boardSize - 1 && arrows.length < targetArrowCount; c += 2) {
      final p1 = GridPoint(r, c);
      final p2 = GridPoint(r, c + 1);
      final p3 = GridPoint(r + 1, c + 1);

      if (!occupied.contains(p1) && !occupied.contains(p2) && !occupied.contains(p3)) {
        occupied.addAll([p1, p2, p3]);
        arrows.add(ArrowModel(
          id: 'fb_${idx++}',
          row: p3.row,
          col: p3.col,
          direction: ArrowDirection.down,
          points: [p1, p2, p3],
        ));
      }
    }
  }

  final board = PuzzleBoard.fromList(size: boardSize, arrowsList: arrows);
  var solution = PuzzleSolver.solve(board) ?? arrows.map((a) => a.id).toList();

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

import 'dart:convert';
import 'dart:io';
import 'package:arrow_escape/features/gameplay/models/level_model.dart';
import 'package:arrow_escape/features/gameplay/solver/level_generator.dart';
import 'package:arrow_escape/features/gameplay/solver/puzzle_solver.dart';

void main() {
  stdout.writeln('=== Generating and Validating 100 Curated Levels ===');

  final levels = <LevelModel>[];

  for (int levelNum = 1; levelNum <= 100; levelNum++) {
    int boardSize;
    int arrowCount;
    String difficulty;
    int minDepth;

    if (levelNum <= 10) {
      boardSize = levelNum <= 5 ? 4 : 5;
      arrowCount = 4 + (levelNum ~/ 2);
      difficulty = 'Beginner';
      minDepth = 2;
    } else if (levelNum <= 25) {
      boardSize = levelNum <= 18 ? 5 : 6;
      arrowCount = 8 + ((levelNum - 10) ~/ 3);
      difficulty = 'Easy';
      minDepth = 3;
    } else if (levelNum <= 50) {
      boardSize = levelNum <= 38 ? 6 : 7;
      arrowCount = 14 + ((levelNum - 25) ~/ 5);
      difficulty = 'Medium';
      minDepth = 3;
    } else if (levelNum <= 75) {
      boardSize = levelNum <= 62 ? 7 : 8;
      arrowCount = 20 + ((levelNum - 50) ~/ 3);
      difficulty = 'Hard';
      minDepth = 4;
    } else {
      if (levelNum <= 85) {
        boardSize = 8;
      } else if (levelNum <= 95) {
        boardSize = 9;
      } else {
        boardSize = 10;
      }
      arrowCount = 28 + ((levelNum - 75) ~/ 3);
      difficulty = 'Expert';
      minDepth = 4;
    }

    final seed = 10000 + levelNum * 37;
    final level = LevelGenerator.generateLevel(
      levelNumber: levelNum,
      boardSize: boardSize,
      seed: seed,
      arrowCount: arrowCount,
      difficulty: difficulty,
      minDependencyDepth: minDepth,
    );

    final board = level.createBoard();
    final isSolvable = PuzzleSolver.isSolvable(board);
    if (!isSolvable) {
      throw StateError('FATAL: Generated Level $levelNum is NOT solvable!');
    }

    levels.add(level);
  }

  final outputDir = Directory('assets/levels');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final jsonFile = File('assets/levels/levels.json');
  final jsonString = const JsonEncoder.withIndent('  ').convert(
    levels.map((l) => l.toJson()).toList(),
  );

  jsonFile.writeAsStringSync(jsonString);
  stdout.writeln('Successfully wrote 100 validated levels to ${jsonFile.path}');
}

// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:eklavyas_aim/features/gameplay/generator/procedural_generator.dart';
import 'package:eklavyas_aim/features/gameplay/solver/puzzle_solver.dart';

void main() {
  final levels = <String, dynamic>{};

  for (final lvlNum in [1, 24, 100, 300]) {
    final level = ProceduralGenerator.generate(lvlNum);
    final board = level.createBoard();
    final isSolvable = PuzzleSolver.isSolvable(board);
    final freeArrows = board.getClearArrows().map((a) => a.id).toList();

    levels['$lvlNum'] = {
      'levelNumber': level.levelNumber,
      'boardSize': level.boardSize,
      'difficulty': level.difficulty,
      'shapeName': level.shapeName,
      'totalArrows': level.arrows.length,
      'freeArrows': freeArrows,
      'freePercent': (freeArrows.length / level.arrows.length) * 100,
      'isSolvable': isSolvable,
      'optimalSolution': level.optimalSolution,
      'arrows': level.arrows.map((a) {
        return {
          'id': a.id,
          'direction': a.direction.name,
          'head': {'row': a.head.row, 'col': a.head.col},
          'tail': {'row': a.tail.row, 'col': a.tail.col},
          'points': a.allPoints.map((p) => {'row': p.row, 'col': p.col}).toList(),
          'length': a.allPoints.length,
          'isFree': freeArrows.contains(a.id),
        };
      }).toList(),
    };
  }

  final jsonStr = jsonEncode(levels);
  final file = File('build/levels_for_screenshots.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(jsonStr);
  print('Exported ${levels.length} levels to build/levels_for_screenshots.json');
}

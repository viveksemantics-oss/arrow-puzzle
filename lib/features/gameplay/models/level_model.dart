import '../engine/arrow_model.dart';
import '../engine/puzzle_board.dart';

/// Represents a configured level in Arrow Maze.
class LevelModel {
  final int levelNumber;
  final int boardSize;
  final int seed;
  final String difficulty;
  final String shapeName;
  final List<ArrowModel> arrows;
  final List<String> optimalSolution; // Sequence of arrow IDs to solve
  final int minMoves;

  const LevelModel({
    required this.levelNumber,
    required this.boardSize,
    required this.seed,
    required this.difficulty,
    this.shapeName = 'Maze',
    required this.arrows,
    required this.optimalSolution,
    required this.minMoves,
  });

  /// Instantiates a new PuzzleBoard for this level.
  PuzzleBoard createBoard() {
    return PuzzleBoard.fromList(
      size: boardSize,
      arrowsList: arrows.map((a) => a.copyWith(isActive: true)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'levelNumber': levelNumber,
        'boardSize': boardSize,
        'seed': seed,
        'difficulty': difficulty,
        'shapeName': shapeName,
        'arrows': arrows.map((a) => a.toJson()).toList(),
        'optimalSolution': optimalSolution,
        'minMoves': minMoves,
      };

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      levelNumber: json['levelNumber'] as int,
      boardSize: json['boardSize'] as int,
      seed: json['seed'] as int,
      difficulty: json['difficulty'] as String,
      shapeName: json['shapeName'] as String? ?? 'Maze',
      arrows: (json['arrows'] as List<dynamic>)
          .map((a) => ArrowModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      optimalSolution: (json['optimalSolution'] as List<dynamic>)
          .map((s) => s as String)
          .toList(),
      minMoves: json['minMoves'] as int,
    );
  }
}

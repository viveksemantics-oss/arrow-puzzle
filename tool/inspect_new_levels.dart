// ignore_for_file: avoid_print
import 'package:eklavyas_aim/features/gameplay/generator/procedural_generator.dart';
import 'package:eklavyas_aim/features/gameplay/solver/puzzle_solver.dart';

void main() {
  print('================ LEVEL GENERATOR METRICS ================');
  for (final lvlNum in [1, 24, 25, 100, 300]) {
    final sw = Stopwatch()..start();
    final level = ProceduralGenerator.generate(lvlNum);
    sw.stop();

    final board = level.createBoard();
    final isSolvable = PuzzleSolver.isSolvable(board);
    final freeArrows = board.getClearArrows();
    final freeRatio = freeArrows.length / level.arrows.length;

    final totalCells = level.arrows.map((a) => a.allPoints.length).reduce((a, b) => a + b);
    final avgLen = totalCells / level.arrows.length;

    final depths = <String, int>{};
    int maxDepth = 0;
    for (final id in level.optimalSolution) {
      final a = board.arrows[id];
      if (a == null) continue;
      int d = 0;
      final head = a.head;
      int r = head.row + a.direction.dy;
      int c = head.col + a.direction.dx;
      while (r >= 0 && r < board.size && c >= 0 && c < board.size) {
        final other = board.getActiveArrowAt(r, c);
        if (other != null && other.id != id) {
          final od = depths[other.id] ?? 0;
          if (od + 1 > d) d = od + 1;
        }
        r += a.direction.dy;
        c += a.direction.dx;
      }
      depths[id] = d;
      if (d > maxDepth) maxDepth = d;
    }

    print('Level $lvlNum:');
    print('  Tier: ${level.difficulty}');
    print('  Shape: ${level.shapeName}');
    print('  Grid Size: ${level.boardSize}x${level.boardSize}');
    print('  Arrow Count: ${level.arrows.length}');
    print('  Average Length: ${avgLen.toStringAsFixed(1)} cells');
    print('  Free at Start: ${freeArrows.length} (${(freeRatio * 100).toStringAsFixed(1)}%)');
    print('  Dependency Depth: $maxDepth');
    print('  Is Solvable: $isSolvable');
    print('  Generation Time: ${sw.elapsedMilliseconds} ms');
    print('---------------------------------------------------------');
  }
}

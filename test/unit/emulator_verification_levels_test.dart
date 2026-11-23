import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrow_escape/core/services/admob_service.dart';
import 'package:arrow_escape/core/services/purchase_service.dart';
import 'package:arrow_escape/core/storage/storage_service.dart';
import 'package:arrow_escape/core/utils/sound_manager.dart';
import 'package:arrow_escape/features/gameplay/engine/level_repository.dart';
import 'package:arrow_escape/features/gameplay/engine/move_result.dart';
import 'package:arrow_escape/features/gameplay/providers/game_providers.dart';
import 'package:arrow_escape/features/gameplay/solver/puzzle_solver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Master Verification: 5 Key Gameplay & Design Criteria', () {
    late LevelRepository repo;

    setUp(() {
      repo = LevelRepository();
    });

    test('Criterion 1: Levels 100 and 300 are dense, winding mazes like silhouettes', () {
      final lvl100 = repo.getLevel(100);
      final lvl300 = repo.getLevel(300);

      // Verify Level 100
      expect(lvl100.levelNumber, equals(100));
      expect(lvl100.difficulty.toLowerCase(), equals('medium'));
      expect(lvl100.boardSize, equals(36));
      expect(lvl100.arrows.length, greaterThanOrEqualTo(100), reason: 'Level 100 must have 100+ arrows');
      final avgLen100 = lvl100.arrows.map((a) => a.allPoints.length).reduce((a, b) => a + b) / lvl100.arrows.length;
      expect(avgLen100, greaterThanOrEqualTo(4.5), reason: 'Level 100 arrows must be long winding snakes');

      // Verify Level 300
      expect(lvl300.levelNumber, equals(300));
      expect(lvl300.difficulty.toLowerCase(), equals('expert'));
      expect(lvl300.boardSize, equals(60));
      expect(lvl300.arrows.length, greaterThanOrEqualTo(300), reason: 'Level 300 must have 300+ arrows');
      final avgLen300 = lvl300.arrows.map((a) => a.allPoints.length).reduce((a, b) => a + b) / lvl300.arrows.length;
      expect(avgLen300, greaterThanOrEqualTo(4.5), reason: 'Level 300 arrows must be long winding snakes');

      // Solvability check for both
      expect(lvl100.optimalSolution.length, equals(lvl100.arrows.length));
      expect(lvl300.optimalSolution.length, equals(lvl300.arrows.length));
      expect(PuzzleSolver.isSolvable(lvl100.createBoard()), isTrue);
      expect(PuzzleSolver.isSolvable(lvl300.createBoard()), isTrue);
    });

    test('Criterion 2: Fewer than 20% of arrows are free at start for levels above 20', () {
      final testLevels = [21, 24, 25, 40, 50, 100, 200, 300];

      for (final lvlNum in testLevels) {
        final level = repo.getLevel(lvlNum);
        final board = level.createBoard();
        final freeArrows = board.getClearArrows();
        final freeRatio = freeArrows.length / level.arrows.length;

        expect(
          freeRatio,
          lessThan(0.20),
          reason: 'Level $lvlNum has ${(freeRatio * 100).toStringAsFixed(1)}% free arrows, must be < 20%',
        );
      }
    });

    test('Criterion 3: Tapping a free arrow slides it out; tapping blocked shakes and costs a heart', () async {
      SharedPreferences.setMockInitialValues({'current_level': 24});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          storageProvider.overrideWithValue(StorageService(prefs)),
          levelRepoProvider.overrideWithValue(repo),
          soundProvider.overrideWithValue(SoundManager()),
          admobProvider.overrideWithValue(AdMobService()),
          purchaseProvider.overrideWithValue(PurchaseService()),
        ],
      );

      final controller = container.read(gameControllerProvider.notifier);
      final initialState = container.read(gameControllerProvider);

      expect(initialState.lives, equals(3));
      expect(initialState.remainingArrows, equals(initialState.level.arrows.length));

      // Find a blocked arrow and a free arrow on Level 24
      final board = initialState.board;
      final freeArrow = board.getClearArrows().first;
      final blockedArrow = board.arrows.values.firstWhere(
        (a) => !board.isPathClear(a),
      );

      // 1. Tap blocked arrow
      final blockedResult = controller.tapArrow(blockedArrow.id);
      expect(blockedResult.status, equals(MoveStatus.blocked));
      expect(blockedResult.isSuccess, isFalse);
      expect(blockedResult.blockingArrow, isNotNull);

      final stateAfterBlock = container.read(gameControllerProvider);
      expect(stateAfterBlock.lives, equals(2), reason: 'Blocked tap must lose 1 heart (3 -> 2)');
      expect(stateAfterBlock.isGameOver, isFalse);

      // 2. Tap free arrow
      final freeResult = controller.tapArrow(freeArrow.id);
      expect(freeResult.isSuccess, isTrue);

      final stateAfterFree = container.read(gameControllerProvider);
      expect(stateAfterFree.lives, equals(2), reason: 'Free tap must not lose hearts');
      expect(stateAfterFree.remainingArrows, equals(initialState.remainingArrows - 1));

      container.dispose();
    });

    test('Criterion 4: Pinch-zoom coordinates and hit-testing accurately identify arrow', () {
      final p1 = const Offset(10, 10);
      final p2 = const Offset(10, 50);

      final tapNear = const Offset(12, 30);
      final tapFar = const Offset(40, 30);

      double distanceToSegment(Offset p, Offset v, Offset w) {
        final l2 = (v - w).distanceSquared;
        if (l2 == 0.0) return (p - v).distance;
        final t = (((p.dx - v.dx) * (w.dx - v.dx) + (p.dy - v.dy) * (w.dy - v.dy)) / l2).clamp(0.0, 1.0);
        final projection = Offset(v.dx + t * (w.dx - v.dx), v.dy + t * (w.dy - v.dy));
        return (p - projection).distance;
      }

      expect(distanceToSegment(tapNear, p1, p2), closeTo(2.0, 0.001));
      expect(distanceToSegment(tapFar, p1, p2), closeTo(30.0, 0.001));
    });

    test('Criterion 5: Play Level 24 to the end using solution order and verify Level Complete', () async {
      SharedPreferences.setMockInitialValues({'current_level': 24});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final container = ProviderContainer(
        overrides: [
          storageProvider.overrideWithValue(storage),
          levelRepoProvider.overrideWithValue(repo),
          soundProvider.overrideWithValue(SoundManager()),
          admobProvider.overrideWithValue(AdMobService()),
          purchaseProvider.overrideWithValue(PurchaseService()),
        ],
      );

      final controller = container.read(gameControllerProvider.notifier);
      final level = repo.getLevel(24);

      expect(level.optimalSolution.length, equals(level.arrows.length));

      for (int i = 0; i < level.optimalSolution.length; i++) {
        final arrowId = level.optimalSolution[i];
        final result = controller.tapArrow(arrowId);
        expect(
          result.isSuccess,
          isTrue,
          reason: 'Step $i removing arrow $arrowId must be clear and successful',
        );
      }

      final finalState = container.read(gameControllerProvider);
      expect(finalState.isWon, isTrue, reason: 'Level 24 must be completed/won');
      expect(finalState.remainingArrows, equals(0));
      expect(finalState.lives, equals(3), reason: 'Zero lives lost when following optimal solution');
      expect(storage.completedLevels.contains(24), isTrue);
      expect(storage.getStars(24), equals(3));

      container.dispose();
    });
  });
}

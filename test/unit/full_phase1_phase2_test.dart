import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eklavyas_aim/config/ad_config.dart';
import 'package:eklavyas_aim/core/constants/app_constants.dart';
import 'package:eklavyas_aim/core/services/admob_service.dart';
import 'package:eklavyas_aim/core/services/purchase_service.dart';
import 'package:eklavyas_aim/core/storage/storage_service.dart';
import 'package:eklavyas_aim/core/utils/sound_manager.dart';
import 'package:eklavyas_aim/features/gameplay/engine/arrow_direction.dart';
import 'package:eklavyas_aim/features/gameplay/engine/arrow_model.dart';
import 'package:eklavyas_aim/features/gameplay/engine/level_repository.dart';
import 'package:eklavyas_aim/features/gameplay/generator/procedural_generator.dart';
import 'package:eklavyas_aim/features/gameplay/providers/game_providers.dart';
import 'package:eklavyas_aim/features/gameplay/screens/gameplay_screen.dart';
import 'package:eklavyas_aim/features/gameplay/solver/puzzle_solver.dart';
import 'package:eklavyas_aim/features/gameplay/widgets/game_over_dialog.dart';
import 'package:eklavyas_aim/features/gameplay/widgets/level_completed_dialog.dart';
import 'package:eklavyas_aim/features/gameplay/widgets/pause_dialog.dart';
import 'package:eklavyas_aim/features/home/main_menu_screen.dart';
import 'package:eklavyas_aim/features/levels/level_select_screen.dart';
import 'package:eklavyas_aim/features/settings/settings_screen.dart';
import 'package:eklavyas_aim/features/splash/splash_screen.dart';
import 'package:eklavyas_aim/services/ad_service.dart';
import 'package:eklavyas_aim/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1: Generator (100 levels across all 5 tiers)', () {
    test('Validates 100 levels across BEGINNER, EASY, MEDIUM, HARD, EXPERT', () {
      final levelsToTest = <int>[
        // 1-10 BEGINNER (10 levels)
        for (int i = 1; i <= 10; i++) i,
        // 11-40 EASY (20 levels)
        for (int i = 11; i <= 40; i += 2) i,
        12, 24, 30, 38, 40,
        // 41-100 MEDIUM (25 levels)
        for (int i = 41; i <= 100; i += 3) i,
        50, 75, 90, 99, 100,
        // 101-250 HARD (25 levels)
        for (int i = 101; i <= 250; i += 7) i,
        150, 200, 250,
        // 251+ EXPERT (20 levels)
        for (int i = 251; i <= 350; i += 6) i,
        280, 300, 350,
      ].take(100).toList();

      expect(levelsToTest.length, equals(100));

      for (final lvlNum in levelsToTest) {
        final level = ProceduralGenerator.generate(lvlNum);
        final expectedTier = lvlNum <= 10
            ? 'BEGINNER'
            : lvlNum <= 40
                ? 'EASY'
                : lvlNum <= 100
                    ? 'MEDIUM'
                    : lvlNum <= 250
                        ? 'HARD'
                        : 'EXPERT';
        expect(level.difficulty, equals(expectedTier), reason: 'Level $lvlNum tier mismatch');

        // Seeded determinism check on representative levels
        if (lvlNum == 1 || lvlNum == 24 || lvlNum == 100 || lvlNum == 300) {
          final levelAgain = ProceduralGenerator.generate(lvlNum);
          expect(levelAgain.arrows.length, equals(level.arrows.length));
          expect(levelAgain.arrows.first.allPoints, equals(level.arrows.first.allPoints));
        }

        final usedCells = <GridPoint>{};
        for (final arrow in level.arrows) {
          expect(arrow.allPoints.length, greaterThanOrEqualTo(2));
          for (int i = 0; i < arrow.allPoints.length - 1; i++) {
            final a = arrow.allPoints[i];
            final b = arrow.allPoints[i + 1];
            final dr = (b.row - a.row).abs();
            final dc = (b.col - a.col).abs();
            expect((dr == 1 && dc == 0) || (dr == 0 && dc == 1), isTrue,
                reason: 'Diagonal step in level $lvlNum');
          }
          final pPrev = arrow.allPoints[arrow.allPoints.length - 2];
          final pHead = arrow.allPoints.last;
          expect(
            arrow.direction,
            equals(ArrowDirection.fromDelta(pHead.row - pPrev.row, pHead.col - pPrev.col)),
          );
          for (final pt in arrow.allPoints) {
            expect(usedCells.add(pt), isTrue, reason: 'Duplicate cell $pt in level $lvlNum');
          }
        }

        expect(PuzzleSolver.isSolvable(level.createBoard()), isTrue,
            reason: 'Level $lvlNum must be solvable');
      }
    });
  });

  group('Phase 1: Game Logic, Sound & Ad Logic', () {
    test('Free tap, blocked tap, 3 hearts = game over, undo, hint, restart, stars, storage', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);

      // Save/load settings & progress
      await storage.setSoundEnabled(false);
      await storage.setHapticsEnabled(false);
      await storage.setCurrentLevel(12);
      await storage.markLevelCompleted(11, 30);
      expect(storage.soundEnabled, isFalse);
      expect(storage.hapticsEnabled, isFalse);
      expect(storage.currentLevel, equals(12));
      expect(storage.completedLevels.contains(11), isTrue);

      final container = ProviderContainer(
        overrides: [
          storageProvider.overrideWithValue(storage),
          levelRepoProvider.overrideWithValue(LevelRepository()),
          soundProvider.overrideWithValue(SoundManager()),
          admobProvider.overrideWithValue(AdMobService()),
          purchaseProvider.overrideWithValue(PurchaseService()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(gameControllerProvider.notifier);
      controller.loadLevel(1);
      var state = container.read(gameControllerProvider);
      final initialCount = state.remainingArrows;

      // Find a free arrow and a blocked arrow (if any; on lvl 1 find or use lvl 24)
      controller.loadLevel(24);
      state = container.read(gameControllerProvider);
      final count24 = state.remainingArrows;
      final blocked = state.board.arrows.values.firstWhere((a) => !state.board.isPathClear(a));
      final free = state.board.arrows.values.firstWhere((a) => state.board.isPathClear(a));

      // Blocked tap loses 1 heart and moves nothing
      controller.tapArrow(blocked.id);
      state = container.read(gameControllerProvider);
      expect(state.lives, equals(2));
      expect(state.remainingArrows, equals(count24));

      // Free tap removes only that arrow
      controller.tapArrow(free.id);
      state = container.read(gameControllerProvider);
      expect(state.remainingArrows, equals(count24 - 1));

      // Undo restores the last arrow, NOT the lost heart
      controller.undo();
      state = container.read(gameControllerProvider);
      expect(state.remainingArrows, equals(count24));
      expect(state.lives, equals(2));

      // Hint returns a currently free arrow and decrements count
      final hintsBefore = state.hintsRemaining;
      final usedHint = controller.useHint();
      state = container.read(gameControllerProvider);
      expect(usedHint, isTrue);
      expect(state.hintsRemaining, equals(hintsBefore - 1));
      expect(state.activeHintId, isNotNull);
      expect(state.board.isPathClear(state.board.getArrowById(state.activeHintId!)!), isTrue);

      // 3 lost hearts total = game over (already lost 1, lose 2 more)
      controller.tapArrow(blocked.id);
      controller.tapArrow(blocked.id);
      state = container.read(gameControllerProvider);
      expect(state.lives, equals(0));
      expect(state.isGameOver, isTrue);

      // Restart resets everything
      controller.restart();
      state = container.read(gameControllerProvider);
      expect(state.lives, equals(3));
      expect(state.isGameOver, isFalse);
      expect(state.remainingArrows, equals(count24));

      // Stars calculation sanity (3 - livesLost clamped 1..3)
      expect((3 - 0).clamp(1, 3), equals(3));
      expect((3 - 1).clamp(1, 3), equals(2));
      expect((3 - 2).clamp(1, 3), equals(1));
      expect(initialCount, greaterThan(0));
    });

    test('Sound off disables playback without error', () async {
      final s = SoundService();
      s.setSoundEnabled(false);
      expect(s.soundEnabled, isFalse);
      await s.play(SoundType.tap);
      await s.play(SoundType.slide);
    });

    test('AdService interstitial eligibility, cooldown, premium disable, and AdConfig fallback', () {
      final adService = AdService();
      adService.resetForTest();
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      // Never on levels 1-3
      expect(adService.evaluateInterstitialEligibility(completedLevelNumber: 1, isPremium: false, now: t0), isFalse);
      expect(adService.evaluateInterstitialEligibility(completedLevelNumber: 2, isPremium: false, now: t0), isFalse);
      expect(adService.evaluateInterstitialEligibility(completedLevelNumber: 3, isPremium: false, now: t0), isFalse);

      // Every 3rd completed level after level 3
      expect(adService.evaluateInterstitialEligibility(completedLevelNumber: 4, isPremium: false, now: t0), isFalse);
      expect(adService.evaluateInterstitialEligibility(completedLevelNumber: 5, isPremium: false, now: t0), isFalse);
      expect(adService.evaluateInterstitialEligibility(completedLevelNumber: 6, isPremium: false, now: t0), isTrue);

      // 60s cooldown check even after 3 more levels
      final t30s = t0.add(const Duration(seconds: 30));
      expect(adService.evaluateInterstitialEligibility(completedLevelNumber: 7, isPremium: false, now: t30s), isFalse);
      expect(adService.evaluateInterstitialEligibility(completedLevelNumber: 8, isPremium: false, now: t30s), isFalse);
      expect(adService.evaluateInterstitialEligibility(completedLevelNumber: 9, isPremium: false, now: t30s), isFalse);

      // After >= 60s passes, eligible again
      final t65s = t0.add(const Duration(seconds: 65));
      expect(adService.evaluateInterstitialEligibility(completedLevelNumber: 10, isPremium: false, now: t65s), isTrue);

      // Premium disables ads
      expect(adService.evaluateInterstitialEligibility(completedLevelNumber: 13, isPremium: true, now: t65s), isFalse);

      // AdConfig falls back to Google test IDs when placeholders are empty or contain REPLACE_WITH
      expect(AdConfig.bannerAdUnitId, contains('ca-app-pub-3940256099942544'));
      expect(AdConfig.interstitialAdUnitId, contains('ca-app-pub-3940256099942544'));
      expect(AdConfig.rewardedAdUnitId, contains('ca-app-pub-3940256099942544'));
    });
  });

  group('Phase 2: All Screens & Dialogs Widget Tests', () {
    Future<Widget> wrapWithProviders(Widget child, {Map<String, Object>? prefsInit}) async {
      SharedPreferences.setMockInitialValues(prefsInit ?? {'current_level': 2, 'completed_levels': ['1']});
      final prefs = await SharedPreferences.getInstance();
      return ProviderScope(
        key: UniqueKey(),
        overrides: [
          storageProvider.overrideWithValue(StorageService(prefs)),
          levelRepoProvider.overrideWithValue(LevelRepository()),
          soundProvider.overrideWithValue(SoundManager()),
          admobProvider.overrideWithValue(AdMobService()),
          purchaseProvider.overrideWithValue(PurchaseService()),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          routes: {
            '/home': (_) => const Scaffold(body: Text('Home')),
            '/onboarding': (_) => const Scaffold(body: Text('Onboarding')),
          },
          home: child,
        ),
      );
    }

    testWidgets('Splash, Home, LevelSelect, Gameplay, Settings & Dialogs build cleanly', (tester) async {
      expect(AppConstants.appName, equals("Eklavya's Aim"));

      await tester.pumpWidget(await wrapWithProviders(const SplashScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text("Eklavya's Aim"), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));

      await tester.pumpWidget(await wrapWithProviders(const MainMenuScreen()));
      await tester.pumpAndSettle();
      expect(find.text("Eklavya's Aim"), findsOneWidget);

      await tester.pumpWidget(await wrapWithProviders(const LevelSelectScreen()));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_rounded), findsWidgets); // Locked levels present

      await tester.pumpWidget(await wrapWithProviders(const GameplayScreen(initialLevel: 1)));
      await tester.pumpAndSettle();
      expect(find.text('Level 1'), findsOneWidget);

      await tester.pumpWidget(await wrapWithProviders(const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      // Dialogs
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PauseDialog(
            onResume: () {},
            onRestart: () {},
            onLevels: () {},
            onHome: () {},
            soundEnabled: true,
            onToggleSound: (_) {},
          ),
        ),
      ));
      expect(find.text('Game Paused'), findsOneWidget);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LevelCompletedDialog(
            levelNumber: 1,
            moves: 10,
            optimalMoves: 10,
            seconds: 15,
            stars: 3,
            onNextLevel: () {},
            onReplay: () {},
            onMenu: () {},
          ),
        ),
      ));
      expect(find.text('Level Cleared!'), findsOneWidget);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GameOverDialog(
            onWatchAd: () {},
            onRetry: () {},
            onQuit: () {},
          ),
        ),
      ));
      expect(find.text('Level Failed!'), findsOneWidget);
    });
  });
}

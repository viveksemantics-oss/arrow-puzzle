import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eklavyas_aim/core/services/admob_service.dart';
import 'package:eklavyas_aim/core/services/purchase_service.dart';
import 'package:eklavyas_aim/core/storage/storage_service.dart';
import 'package:eklavyas_aim/core/utils/sound_manager.dart';
import 'package:eklavyas_aim/features/gameplay/engine/level_repository.dart';
import 'package:eklavyas_aim/features/gameplay/generator/procedural_generator.dart';
import 'package:eklavyas_aim/features/gameplay/providers/game_providers.dart';
import 'package:eklavyas_aim/features/gameplay/screens/gameplay_screen.dart';
import 'package:eklavyas_aim/features/gameplay/widgets/game_over_dialog.dart';
import 'package:eklavyas_aim/features/gameplay/widgets/level_completed_dialog.dart';
import 'package:eklavyas_aim/features/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    const fontPath = r'F:\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf';
    final file = File(fontPath);
    if (file.existsSync()) {
      final fontData = file.readAsBytesSync();
      final fontLoader = FontLoader('MaterialIcons');
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
    }
    Directory('test_results').createSync(recursive: true);
  });

  Future<void> capturePng(GlobalKey repaintKey, WidgetTester tester, String filename) async {
    await tester.runAsync(() async {
      final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      File('test_results/$filename').writeAsBytesSync(byteData!.buffer.asUint8List());
    });
  }

  group('Phase 3: End-to-End Flows & Screenshots', () {
    for (final lvlNum in [1, 24, 100, 300]) {
      testWidgets('Level $lvlNum: full solve, before/after screenshots, Level Complete dialog', (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({'current_level': lvlNum});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        final repo = LevelRepository();
        final level = repo.getLevel(lvlNum);

        final container = ProviderContainer(
          overrides: [
            storageProvider.overrideWithValue(storage),
            levelRepoProvider.overrideWithValue(repo),
            soundProvider.overrideWithValue(SoundManager()),
            admobProvider.overrideWithValue(AdMobService()),
            purchaseProvider.overrideWithValue(PurchaseService()),
          ],
        );
        addTearDown(container.dispose);

        final repaintKey = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: RepaintBoundary(
                key: repaintKey,
                child: GameplayScreen(initialLevel: lvlNum),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await capturePng(repaintKey, tester, 'level_${lvlNum}_before.png');

        final controller = container.read(gameControllerProvider.notifier);
        for (final arrowId in level.optimalSolution) {
          final res = controller.tapArrow(arrowId);
          expect(res.isSuccess, isTrue);
        }
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(container.read(gameControllerProvider).remainingArrows, equals(0));
        expect(find.byType(LevelCompletedDialog), findsOneWidget);
        await capturePng(repaintKey, tester, 'level_${lvlNum}_after.png');
        if (lvlNum == 24) {
          await capturePng(repaintKey, tester, 'level_complete.png');
        }
      });
    }

    testWidgets('Blocked tap, Game Over, Retry, Hints, Pause/Resume & Settings screenshot', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({'current_level': 24, 'hints_count': 3});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
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

      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: RepaintBoundary(
              key: repaintKey,
              child: const GameplayScreen(initialLevel: 24),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = container.read(gameControllerProvider.notifier);
      final state = container.read(gameControllerProvider);
      final blocked = state.board.arrows.values.firstWhere((a) => !state.board.isPathClear(a));

      // Blocked tap loses 1 heart, arrow stays
      controller.tapArrow(blocked.id);
      await tester.pump(const Duration(milliseconds: 50));
      expect(container.read(gameControllerProvider).lives, equals(2));
      await capturePng(repaintKey, tester, 'blocked_tap.png');

      // Use 3 hints -> hints == 0 -> tapping hint shows watch ad dialog
      expect(controller.useHint(), isTrue);
      expect(controller.useHint(), isTrue);
      expect(controller.useHint(), isTrue);
      expect(container.read(gameControllerProvider).hintsRemaining, equals(0));
      expect(controller.useHint(), isFalse);

      // Pause stops timer, resume continues
      final secBeforePause = container.read(gameControllerProvider).elapsedSeconds;
      controller.pause();
      await tester.pump(const Duration(seconds: 2));
      expect(container.read(gameControllerProvider).elapsedSeconds, equals(secBeforePause));
      controller.resume();

      // Lose remaining 2 hearts -> Game Over
      controller.tapArrow(blocked.id);
      controller.tapArrow(blocked.id);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byType(GameOverDialog), findsOneWidget);
      await capturePng(repaintKey, tester, 'game_over.png');

      // Retry resets lives
      await tester.tap(find.text('Retry Level'));
      await tester.pumpAndSettle();
      expect(container.read(gameControllerProvider).lives, equals(3));

      // Settings screenshot
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: RepaintBoundary(
              key: repaintKey,
              child: const SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capturePng(repaintKey, tester, 'settings.png');
    });
  });

  group('Phase 4: Performance & Stability', () {
    test('Isolate level generation times for 100, 300, 500 and 50-level play-through', () async {
      for (final lvl in [100, 300, 500]) {
        final sw = Stopwatch()..start();
        final generated = await Isolate.run(() => ProceduralGenerator.generate(lvl));
        sw.stop();
        expect(generated.arrows.length, greaterThan(0));
        // ignore: avoid_print
        print('PERF_GEN Level $lvl: ${(sw.elapsedMilliseconds / 1000.0).toStringAsFixed(2)}s (${generated.arrows.length} arrows)');
      }

      // Play 50 levels in a row
      final repo = LevelRepository();
      final sw50 = Stopwatch()..start();
      for (int i = 1; i <= 50; i++) {
        final lvl = repo.getLevel(i);
        final board = lvl.createBoard();
        for (final id in lvl.optimalSolution) {
          final a = board.getArrowById(id)!;
          expect(board.isPathClear(a), isTrue);
          board.setArrowActive(id, false);
        }
        expect(board.isCleared, isTrue);
      }
      sw50.stop();
      // ignore: avoid_print
      print('PERF_50_LEVELS: ${sw50.elapsedMilliseconds}ms total');
    });

    testWidgets('Level 300 rapid 30-arrow slide-out frame timing benchmark', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({'current_level': 300});
      final prefs = await SharedPreferences.getInstance();
      final repo = LevelRepository();
      final level300 = repo.getLevel(300);

      final container = ProviderContainer(
        overrides: [
          storageProvider.overrideWithValue(StorageService(prefs)),
          levelRepoProvider.overrideWithValue(repo),
          soundProvider.overrideWithValue(SoundManager()),
          admobProvider.overrideWithValue(AdMobService()),
          purchaseProvider.overrideWithValue(PurchaseService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: GameplayScreen(initialLevel: 300),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = container.read(gameControllerProvider.notifier);
      final frameTimesMs = <double>[];

      // Tap 30 arrows in solution order rapidly, measuring per-frame pump cost
      for (int i = 0; i < 30 && i < level300.optimalSolution.length; i++) {
        final sw = Stopwatch()..start();
        controller.tapArrow(level300.optimalSolution[i]);
        await tester.pump(const Duration(milliseconds: 16));
        sw.stop();
        frameTimesMs.add(sw.elapsedMicroseconds / 1000.0);
      }

      final avgMs = frameTimesMs.reduce((a, b) => a + b) / frameTimesMs.length;
      final maxMs = frameTimesMs.reduce((a, b) => a > b ? a : b);
      final overBudget = frameTimesMs.where((ms) => ms > 20.0).length; // >20ms (<50fps)
      // ignore: avoid_print
      print('PERF_LVL300_FRAMES: avg=${avgMs.toStringAsFixed(2)}ms, max=${maxMs.toStringAsFixed(2)}ms, >20ms=$overBudget/30');
    });
  });
}

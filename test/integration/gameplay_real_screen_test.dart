import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arrow_escape/core/services/admob_service.dart';
import 'package:arrow_escape/core/services/purchase_service.dart';
import 'package:arrow_escape/core/storage/storage_service.dart';
import 'package:arrow_escape/core/utils/sound_manager.dart';
import 'package:arrow_escape/features/gameplay/engine/level_repository.dart';
import 'package:arrow_escape/features/gameplay/providers/game_providers.dart';
import 'package:arrow_escape/features/gameplay/screens/gameplay_screen.dart';
import 'package:arrow_escape/features/gameplay/widgets/level_completed_dialog.dart';

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
  });

  group('Real Flutter Engine Verification: Levels 1, 24, 100, 300', () {
    const artifactDir = r'C:\Users\vivek.kumar2\.gemini\antigravity\brain\ebc4063f-bdca-42be-ad80-6b8ad94b6aea';
    Directory('build/screenshots').createSync(recursive: true);
    Directory('$artifactDir/screenshots').createSync(recursive: true);

    for (final lvlNum in [1, 24, 100, 300]) {
      testWidgets('Level $lvlNum: Real Render, Gameplay Solve, Complete Dialog & Screenshots', (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({'current_level': lvlNum});
        final prefs = await SharedPreferences.getInstance();
        final storage = StorageService(prefs);
        final levelRepo = LevelRepository();
        final level = levelRepo.getLevel(lvlNum);

        final container = ProviderContainer(
          overrides: [
            storageProvider.overrideWithValue(storage),
            levelRepoProvider.overrideWithValue(levelRepo),
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
              theme: ThemeData(
                fontFamily: 'sans-serif',
                useMaterial3: true,
              ),
              home: RepaintBoundary(
                key: repaintKey,
                child: GameplayScreen(initialLevel: lvlNum),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. CAPTURE REAL BEFORE-PLAY SCREENSHOT
        await tester.runAsync(() async {
          final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.5);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          final bytes = byteData!.buffer.asUint8List();

          File('build/screenshots/level_${lvlNum}_before.png').writeAsBytesSync(bytes);
          File('$artifactDir/screenshots/level_${lvlNum}_before.png').writeAsBytesSync(bytes);
          File('$artifactDir/level_$lvlNum.png').writeAsBytesSync(bytes);
        });

        // 2. CAPTURE BLOCKED TAP (HEART LOST) EXAMPLE on Level 24
        if (lvlNum == 24) {
          final controller = container.read(gameControllerProvider.notifier);
          final stateBefore = container.read(gameControllerProvider);
          expect(stateBefore.lives, equals(3));

          // Find a blocked arrow
          final blockedArrow = stateBefore.board.arrows.values.firstWhere(
            (a) => !stateBefore.board.isPathClear(a),
          );

          controller.tapArrow(blockedArrow.id);
          await tester.pump(const Duration(milliseconds: 50));

          final stateAfterBlock = container.read(gameControllerProvider);
          expect(stateAfterBlock.lives, equals(2), reason: 'Blocked tap must lose 1 heart (3 -> 2)');

          await tester.runAsync(() async {
            final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1.5);
            final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
            final bytes = byteData!.buffer.asUint8List();

            File('build/screenshots/blocked_tap_heart_lost.png').writeAsBytesSync(bytes);
            File('$artifactDir/screenshots/blocked_tap_heart_lost.png').writeAsBytesSync(bytes);
            File('$artifactDir/blocked_tap_heart_lost.png').writeAsBytesSync(bytes);
          });

          // Reset for playing through
          controller.restart();
          await tester.pumpAndSettle();
        }

        // 3. PLAY THROUGH ENTIRE LEVEL USING OPTIMAL SOLUTION ORDER
        final controller = container.read(gameControllerProvider.notifier);
        expect(level.optimalSolution.length, equals(level.arrows.length));

        for (int i = 0; i < level.optimalSolution.length; i++) {
          final arrowId = level.optimalSolution[i];
          final res = controller.tapArrow(arrowId);
          expect(res.isSuccess, isTrue, reason: 'Move $i (arrow $arrowId) must succeed');
        }

        await tester.pump(const Duration(milliseconds: 100));

        final finalState = container.read(gameControllerProvider);
        expect(finalState.isWon, isTrue, reason: 'Level $lvlNum must be won');
        expect(finalState.remainingArrows, equals(0), reason: 'Remaining arrows must reach 0');

        // Let victory dialog trigger and animate into view
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(find.byType(LevelCompletedDialog), findsOneWidget);
        expect(find.text('Level Cleared!'), findsOneWidget);
        expect(find.text('Level $lvlNum Completed'), findsOneWidget);

        // 4. CAPTURE REAL AFTER-PLAY (LEVEL COMPLETE DIALOG) SCREENSHOT
        await tester.runAsync(() async {
          final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.5);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          final bytes = byteData!.buffer.asUint8List();

          File('build/screenshots/level_${lvlNum}_complete.png').writeAsBytesSync(bytes);
          File('$artifactDir/screenshots/level_${lvlNum}_complete.png').writeAsBytesSync(bytes);
          if (lvlNum == 24) {
            File('$artifactDir/level_24_complete.png').writeAsBytesSync(bytes);
          }
        });
      });
    }
  });
}

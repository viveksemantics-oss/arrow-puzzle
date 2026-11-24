import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eklavyas_aim/app/theme.dart';
import 'package:eklavyas_aim/core/services/admob_service.dart';
import 'package:eklavyas_aim/core/services/purchase_service.dart';
import 'package:eklavyas_aim/core/storage/storage_service.dart';
import 'package:eklavyas_aim/core/utils/sound_manager.dart';
import 'package:eklavyas_aim/features/daily_challenge/daily_challenge_screen.dart';
import 'package:eklavyas_aim/features/gameplay/engine/level_repository.dart';
import 'package:eklavyas_aim/features/gameplay/providers/game_providers.dart';
import 'package:eklavyas_aim/features/gameplay/screens/gameplay_screen.dart';
import 'package:eklavyas_aim/features/home/main_menu_screen.dart';
import 'package:eklavyas_aim/features/levels/level_select_screen.dart';
import 'package:eklavyas_aim/features/statistics/statistics_screen.dart';

void main() {
  late StorageService storage;
  late LevelRepository levelRepo;
  late SoundManager sound;
  late AdMobService admob;
  late PurchaseService purchase;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'current_level': 1,
      'unlocked_levels': ['1', '2', '3'],
      'completed_levels': ['1'],
      'total_arrows_removed': 15,
      'total_games_played': 5,
      'total_hints_used': 1,
      'daily_streak': 2,
    });
    final prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs);
    levelRepo = LevelRepository();
    await levelRepo.loadLevels();
    sound = SoundManager();
    admob = AdMobService();
    purchase = PurchaseService();
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        levelRepoProvider.overrideWithValue(levelRepo),
        soundProvider.overrideWithValue(sound),
        admobProvider.overrideWithValue(admob),
        purchaseProvider.overrideWithValue(purchase),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  testWidgets('MainMenuScreen renders title, level badge, and buttons', (tester) async {
    await tester.pumpWidget(buildTestableWidget(const MainMenuScreen()));
    await tester.pumpAndSettle();

    expect(find.text("Eklavya's Aim"), findsOneWidget);
    expect(find.text('Level Select'), findsOneWidget);
    expect(find.text('Daily Challenge'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.textContaining('1 Levels Completed'), findsOneWidget);
  });

  testWidgets('LevelSelectScreen displays difficulty tabs and level grid', (tester) async {
    await tester.pumpWidget(buildTestableWidget(const LevelSelectScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Select Level'), findsOneWidget);
    expect(find.textContaining('Beginner'), findsOneWidget);
    expect(find.textContaining('Easy'), findsOneWidget);
    expect(find.textContaining('Medium'), findsOneWidget);
    expect(find.textContaining('Hard'), findsOneWidget);
  });

  testWidgets('StatisticsScreen displays player metrics and level progression', (tester) async {
    await tester.pumpWidget(buildTestableWidget(const StatisticsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Level Progression'), findsOneWidget);
    expect(find.text('Arrows Cleared'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('2 days'), findsOneWidget);
  });

  testWidgets('DailyChallengeScreen renders streak and challenge button', (tester) async {
    await tester.pumpWidget(buildTestableWidget(const DailyChallengeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Daily Challenge'), findsOneWidget);
    expect(find.textContaining('Streak'), findsOneWidget);
    expect(find.textContaining('Challenge'), findsWidgets);
  });

  testWidgets('GameplayScreen renders board, progress bar, and action controls', (tester) async {
    await tester.pumpWidget(buildTestableWidget(const GameplayScreen(initialLevel: 1)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Level 1'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}

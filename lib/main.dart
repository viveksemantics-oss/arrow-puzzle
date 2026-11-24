import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/services/admob_service.dart';
import 'core/services/purchase_service.dart';
import 'core/storage/storage_service.dart';
import 'core/utils/sound_manager.dart';
import 'features/gameplay/engine/level_repository.dart';
import 'features/gameplay/providers/game_providers.dart';

void main() async {
  // Catch any early framework errors cleanly
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };

    // Lock to portrait orientation
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (_) {}

    // Initialize local storage safely
    final storageService = await StorageService.init();

    // Initialize sound manager
    final soundManager = SoundManager();
    try {
      await soundManager.init(
        sound: storageService.soundEnabled,
        music: storageService.musicEnabled,
        haptics: storageService.hapticsEnabled,
      );
    } catch (_) {}

    final admobService = AdMobService();
    final purchaseService = PurchaseService();
    final levelRepo = LevelRepository();

    // Preload levels
    try {
      await levelRepo.loadLevels();
    } catch (_) {}

    // Launch UI immediately
    runApp(
      ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(storageService),
          soundProvider.overrideWithValue(soundManager),
          admobProvider.overrideWithValue(admobService),
          purchaseProvider.overrideWithValue(purchaseService),
          levelRepoProvider.overrideWithValue(levelRepo),
        ],
        child: const EklavyasAimApp(),
      ),
    );

    // Initialize network/plugin services in background after UI is mounted
    Future.microtask(() async {
      try {
        await admobService.initialize();
      } catch (_) {}
      try {
        await purchaseService.initialize(storageService);
      } catch (_) {}
    });
  }, (error, stack) {
    // Top-level unhandled exception guard
    debugPrint('Top-level unhandled exception: $error');
  });
}

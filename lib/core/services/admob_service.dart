import 'package:flutter/foundation.dart';
import '../../services/ad_service.dart';
import '../storage/storage_service.dart';

/// Legacy bridge / facade delegating to the unified [AdService].
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  final AdService _adService = AdService();

  bool get isInitialized => _adService.isInitialized;

  Future<void> initialize() => _adService.initialize();

  void showInterstitialIfEligible(StorageService storage, {required Function onDismissed, int completedLevelNumber = 4}) {
    _adService.showInterstitialIfEligible(
      completedLevelNumber: completedLevelNumber,
      storage: storage,
      onDismissed: () => onDismissed(),
    );
  }

  void showRewardedForHints({
    required Function(int amount) onRewardEarned,
    required Function onClosed,
  }) {
    _adService.showRewardedForHints(
      onHintsGranted: onRewardEarned,
      onClosed: () => onClosed(),
    );
  }

  void showRewardedForExtraLife({
    required VoidCallback onLifeGranted,
    required VoidCallback onClosed,
  }) {
    _adService.showRewardedForExtraLife(
      onLifeGranted: onLifeGranted,
      onClosed: onClosed,
    );
  }
}

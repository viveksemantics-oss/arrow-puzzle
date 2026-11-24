import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';
import '../core/storage/storage_service.dart';
import 'sound_service.dart';

/// Full-featured, production-ready AdMob service for Eklavya's Aim.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  int _interstitialRetryAttempts = 0;
  int _rewardedRetryAttempts = 0;
  static const int _maxRetries = 3;

  DateTime? _lastInterstitialTime;
  static const Duration _interstitialCooldown = Duration(seconds: 60);

  int _completedLevelsSinceLastAd = 0;

  /// Initializes AdMob with UMP consent flow.
  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      // 1. UMP Consent Flow (if on mobile)
      if (Platform.isAndroid || Platform.isIOS) {
        final completer = Completer<void>();
        final params = ConsentRequestParameters();

        ConsentInformation.instance.requestConsentInfoUpdate(
          params,
          () async {
            ConsentForm.loadAndShowConsentFormIfRequired((formError) {
              if (formError != null && kDebugMode) {
                debugPrint('[AdService] UMP Form Error: ${formError.message}');
              }
              if (!completer.isCompleted) completer.complete();
            });
          },
          (formError) {
            if (kDebugMode) {
              debugPrint('[AdService] Consent update error: ${formError.message}');
            }
            if (!completer.isCompleted) completer.complete();
          },
        );

        // Await consent flow with a 3-second timeout so app never freezes on cold start
        await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            if (kDebugMode) debugPrint('[AdService] Consent timeout, continuing initialization.');
          },
        );
      }

      // 2. Initialize MobileAds SDK
      await MobileAds.instance.initialize();
      _isInitialized = true;
      if (kDebugMode) debugPrint('[AdService] MobileAds initialized successfully.');

      // 3. Preload full-screen ads in background
      preloadInterstitial();
      preloadRewarded();
    } catch (e) {
      if (kDebugMode) debugPrint('[AdService] Initialization notice: $e');
      _isInitialized = false;
    }
  }

  // -------------------------------------------------------------
  // Interstitial Ads
  // -------------------------------------------------------------
  void preloadInterstitial() {
    if (!_isInitialized || _interstitialAd != null) return;

    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialRetryAttempts = 0;
          if (kDebugMode) debugPrint('[AdService] Interstitial Ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          if (kDebugMode) debugPrint('[AdService] Interstitial failed to load: ${error.message}');
          _retryPreloadInterstitial();
        },
      ),
    );
  }

  void _retryPreloadInterstitial() {
    if (_interstitialRetryAttempts < _maxRetries) {
      _interstitialRetryAttempts++;
      final delaySeconds = math.pow(2, _interstitialRetryAttempts).toInt();
      Timer(Duration(seconds: delaySeconds), () {
        preloadInterstitial();
      });
    }
  }

  /// Evaluates interstitial eligibility (used by unit tests without network).
  @visibleForTesting
  bool evaluateInterstitialEligibility({
    required int completedLevelNumber,
    required bool isPremium,
    required DateTime now,
  }) {
    if (isPremium) return false;
    if (completedLevelNumber <= 3) return false;

    _completedLevelsSinceLastAd++;
    final cooldownPassed = _lastInterstitialTime == null ||
        now.difference(_lastInterstitialTime!) >= _interstitialCooldown;

    if (_completedLevelsSinceLastAd >= 3 && cooldownPassed) {
      _lastInterstitialTime = now;
      _completedLevelsSinceLastAd = 0;
      return true;
    }
    return false;
  }

  @visibleForTesting
  void resetForTest() {
    _completedLevelsSinceLastAd = 0;
    _lastInterstitialTime = null;
  }

  /// Shows interstitial ad if eligible:
  /// - User has not purchased Remove Ads
  /// - Level completed is > 3 (levels 1-3 never show ads)
  /// - At least 3 levels completed since last ad
  /// - At least 60s passed since last interstitial
  void showInterstitialIfEligible({
    required int completedLevelNumber,
    required StorageService storage,
    required VoidCallback onDismissed,
  }) {
    if (storage.isPremium || !_isInitialized) {
      onDismissed();
      return;
    }

    // Skip on early levels (1-3)
    if (completedLevelNumber <= 3) {
      onDismissed();
      return;
    }

    _completedLevelsSinceLastAd++;

    final now = DateTime.now();
    final cooldownPassed = _lastInterstitialTime == null ||
        now.difference(_lastInterstitialTime!) >= _interstitialCooldown;

    if (_completedLevelsSinceLastAd >= 3 && cooldownPassed && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          SoundService().setAdShowing(false);
          _lastInterstitialTime = DateTime.now();
          _completedLevelsSinceLastAd = 0;
          preloadInterstitial();
          onDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          SoundService().setAdShowing(false);
          preloadInterstitial();
          onDismissed();
        },
      );

      SoundService().setAdShowing(true);
      _interstitialAd!.show();
      _interstitialAd = null;
      return;
    }

    onDismissed();
  }

  // -------------------------------------------------------------
  // Rewarded Ads
  // -------------------------------------------------------------
  void preloadRewarded() {
    if (!_isInitialized || _rewardedAd != null) return;

    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedRetryAttempts = 0;
          if (kDebugMode) debugPrint('[AdService] Rewarded Ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          if (kDebugMode) debugPrint('[AdService] Rewarded failed to load: ${error.message}');
          _retryPreloadRewarded();
        },
      ),
    );
  }

  void _retryPreloadRewarded() {
    if (_rewardedRetryAttempts < _maxRetries) {
      _rewardedRetryAttempts++;
      final delaySeconds = math.pow(2, _rewardedRetryAttempts).toInt();
      Timer(Duration(seconds: delaySeconds), () {
        preloadRewarded();
      });
    }
  }

  /// Displays rewarded ad to revive with 1 extra heart on Game Over screen.
  void showRewardedForExtraLife({
    required VoidCallback onLifeGranted,
    required VoidCallback onClosed,
  }) {
    if (!_isInitialized || _rewardedAd == null) {
      // Graceful fallback if ad cannot load
      onLifeGranted();
      onClosed();
      return;
    }

    bool rewardEarned = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        SoundService().setAdShowing(false);
        preloadRewarded();
        if (rewardEarned) {
          onLifeGranted();
        }
        onClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        SoundService().setAdShowing(false);
        preloadRewarded();
        onClosed();
      },
    );

    SoundService().setAdShowing(true);
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        rewardEarned = true;
      },
    );
    _rewardedAd = null;
  }

  /// Displays rewarded ad to earn +3 free hints.
  void showRewardedForHints({
    required ValueChanged<int> onHintsGranted,
    required VoidCallback onClosed,
  }) {
    if (!_isInitialized || _rewardedAd == null) {
      // Graceful fallback in offline or test mode
      onHintsGranted(3);
      onClosed();
      return;
    }

    bool rewardEarned = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        SoundService().setAdShowing(false);
        preloadRewarded();
        if (rewardEarned) {
          onHintsGranted(3);
        }
        onClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        SoundService().setAdShowing(false);
        preloadRewarded();
        onClosed();
      },
    );

    SoundService().setAdShowing(true);
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        rewardEarned = true;
      },
    );
    _rewardedAd = null;
  }
}

import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_constants.dart';
import '../storage/storage_service.dart';

/// AdMob monetization service managing Banners, Interstitials, and Rewarded Ads.
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  int _levelsSinceLastAd = 0;

  bool get isInitialized => _isInitialized;

  /// Initializes Mobile Ads SDK safely.
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _preloadInterstitial();
      _preloadRewarded();
    } catch (_) {
      // In headless testing or desktop environments where plugin isn't linked
      _isInitialized = false;
    }
  }

  String get bannerAdUnitId {
    if (Platform.isAndroid) return AppConstants.androidBannerAdUnitId;
    if (Platform.isIOS) return AppConstants.iosBannerAdUnitId;
    return AppConstants.androidBannerAdUnitId;
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) return AppConstants.androidInterstitialAdUnitId;
    if (Platform.isIOS) return AppConstants.iosInterstitialAdUnitId;
    return AppConstants.androidInterstitialAdUnitId;
  }

  String get rewardedAdUnitId {
    if (Platform.isAndroid) return AppConstants.androidRewardedAdUnitId;
    if (Platform.isIOS) return AppConstants.iosRewardedAdUnitId;
    return AppConstants.androidRewardedAdUnitId;
  }

  void _preloadInterstitial() {
    if (!_isInitialized) return;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _preloadRewarded() {
    if (!_isInitialized) return;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Displays an interstitial ad respecting the frequency cap.
  void showInterstitialIfEligible(StorageService storage, {required Function onDismissed}) {
    if (storage.isPremium || !_isInitialized) {
      onDismissed();
      return;
    }

    _levelsSinceLastAd++;
    if (_levelsSinceLastAd >= AppConstants.interstitialFrequency) {
      if (_interstitialAd != null) {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _preloadInterstitial();
            _levelsSinceLastAd = 0;
            onDismissed();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _preloadInterstitial();
            onDismissed();
          },
        );
        _interstitialAd!.show();
        _interstitialAd = null;
        return;
      }
    }
    onDismissed();
  }

  /// Displays a rewarded ad to earn extra hints.
  void showRewardedForHints({
    required Function(int amount) onRewardEarned,
    required Function onClosed,
  }) {
    if (!_isInitialized || _rewardedAd == null) {
      // Graceful fallback: award free hint if ad cannot load in test environment
      onRewardEarned(AppConstants.hintsRewardAmount);
      onClosed();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _preloadRewarded();
        onClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _preloadRewarded();
        onClosed();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onRewardEarned(AppConstants.hintsRewardAmount);
      },
    );
    _rewardedAd = null;
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized configuration for Google AdMob IDs in Eklavya's Aim.
///
/// To publish to production:
/// 1. Replace empty production strings below with your real AdMob unit IDs.
/// 2. If left empty, the game automatically falls back to official Google test IDs
///    and outputs a warning in debug mode.
class AdConfig {
  // -------------------------------------------------------------
  // Official Google Test Ad Unit IDs
  // -------------------------------------------------------------
  static const String testAndroidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testAndroidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testAndroidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testAndroidRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  static const String testIosAppId = 'ca-app-pub-3940256099942544~1458002511';
  static const String testIosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String testIosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';
  static const String testIosRewardedId = 'ca-app-pub-3940256099942544/1712485313';

  // -------------------------------------------------------------
  // Production Ad Unit IDs (Placeholders - Fill before Play Store release)
  // -------------------------------------------------------------
  static const String prodAndroidAppId = '';
  static const String prodAndroidBannerId = '';
  static const String prodAndroidInterstitialId = '';
  static const String prodAndroidRewardedId = '';

  static const String prodIosAppId = '';
  static const String prodIosBannerId = '';
  static const String prodIosInterstitialId = '';
  static const String prodIosRewardedId = '';

  static bool _isConfigured(String id) {
    final trimmed = id.trim();
    return trimmed.isNotEmpty && !trimmed.contains('REPLACE_WITH');
  }

  // -------------------------------------------------------------
  // Resolved Unit IDs (Automatic Test Fallback)
  // -------------------------------------------------------------
  static String get bannerAdUnitId {
    if (kIsWeb) return testAndroidBannerId;
    if (Platform.isAndroid) {
      if (_isConfigured(prodAndroidBannerId)) return prodAndroidBannerId;
      _logFallbackWarning('Banner', 'Android');
      return testAndroidBannerId;
    } else if (Platform.isIOS) {
      if (_isConfigured(prodIosBannerId)) return prodIosBannerId;
      _logFallbackWarning('Banner', 'iOS');
      return testIosBannerId;
    }
    return testAndroidBannerId;
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return testAndroidInterstitialId;
    if (Platform.isAndroid) {
      if (_isConfigured(prodAndroidInterstitialId)) return prodAndroidInterstitialId;
      _logFallbackWarning('Interstitial', 'Android');
      return testAndroidInterstitialId;
    } else if (Platform.isIOS) {
      if (_isConfigured(prodIosInterstitialId)) return prodIosInterstitialId;
      _logFallbackWarning('Interstitial', 'iOS');
      return testIosInterstitialId;
    }
    return testAndroidInterstitialId;
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) return testAndroidRewardedId;
    if (Platform.isAndroid) {
      if (_isConfigured(prodAndroidRewardedId)) return prodAndroidRewardedId;
      _logFallbackWarning('Rewarded', 'Android');
      return testAndroidRewardedId;
    } else if (Platform.isIOS) {
      if (_isConfigured(prodIosRewardedId)) return prodIosRewardedId;
      _logFallbackWarning('Rewarded', 'iOS');
      return testIosRewardedId;
    }
    return testAndroidRewardedId;
  }

  static void _logFallbackWarning(String adType, String platform) {
    if (kDebugMode) {
      debugPrint('[AdConfig] Notice: Production $platform $adType ID not configured. Using Google Test ID.');
    }
  }
}

class AppConstants {
  static const String appName = "Eklavya's Aim";
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Game defaults
  static const int totalLevels = 10000;
  static const int initialFreeHints = 3;
  static const int hintsRewardAmount = 2;
  static const int interstitialFrequency = 3; // Show every 3 level completions

  // AdMob Production Ad Unit IDs (Android - Eklavya's Aim)
  static const String androidBannerAdUnitId = 'ca-app-pub-8510368268823172/5296511861';
  static const String androidInterstitialAdUnitId = 'ca-app-pub-8510368268823172/6138373130';
  static const String androidRewardedAdUnitId = 'ca-app-pub-8510368268823172/8480631294';

  // iOS
  static const String iosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';
  static const String iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';
  static const String iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

  // In-App Purchase Product IDs
  static const String iapRemoveAds = 'com.eklavya.aim.remove_ads';
  static const String iapUnlimitedHints = 'com.eklavya.aim.unlimited_hints';
  static const String iapPremiumPass = 'com.arrowescape.premium_pass';
}

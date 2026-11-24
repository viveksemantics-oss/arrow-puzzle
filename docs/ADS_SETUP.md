# Google AdMob Setup & Configuration Guide — Eklavya's Aim

This guide documents the centralized Google AdMob monetization architecture for **Eklavya's Aim** and provides step-by-step instructions for transitioning from Google test IDs to production ad units.

---

## 1. Centralized Ad Unit Configuration

All ad unit IDs, fallbacks, and platform mappings are managed in a single file:
👉 [`lib/config/ad_config.dart`](file:///f:/xampp-8-2/htdocs/ArrowEscape/lib/config/ad_config.dart)

### Production ID Placeholders
To deploy live ads to the Google Play Store and Apple App Store, open `lib/config/ad_config.dart` and populate the production strings:

```dart
// Android Production Ad Unit IDs
static const String prodAndroidAppId         = 'ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY';
static const String prodAndroidBannerId      = 'ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB';
static const String prodAndroidInterstitialId= 'ca-app-pub-XXXXXXXXXXXXXXXX/IIIIIIIIII';
static const String prodAndroidRewardedId    = 'ca-app-pub-XXXXXXXXXXXXXXXX/RRRRRRRRRR';

// iOS Production Ad Unit IDs
static const String prodIosAppId             = 'ca-app-pub-XXXXXXXXXXXXXXXX~ZZZZZZZZZZ';
static const String prodIosBannerId          = 'ca-app-pub-XXXXXXXXXXXXXXXX/bbbbbbbbbb';
static const String prodIosInterstitialId    = 'ca-app-pub-XXXXXXXXXXXXXXXX/iiiiiiiiii';
static const String prodIosRewardedId        = 'ca-app-pub-XXXXXXXXXXXXXXXX/rrrrrrrrrr';
```

> **Safe Fallback**: If any production ID is left empty or whitespace, the game **automatically falls back** to Google's official sample test unit IDs and logs a warning in debug mode without crashing or freezing.

---

## 2. Native Platform Metadata Configuration

### Android Setup
Open [`android/app/src/main/AndroidManifest.xml`](file:///f:/xampp-8-2/htdocs/ArrowEscape/android/app/src/main/AndroidManifest.xml):
1. **AdMob Application ID**:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-3940256099942544~3347511713"/> <!-- Replace with prodAndroidAppId -->
   ```
2. **Permissions**:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="com.google.android.gms.permission.AD_ID"/>
   ```

### iOS Setup
Open [`ios/Runner/Info.plist`](file:///f:/xampp-8-2/htdocs/ArrowEscape/ios/Runner/Info.plist):
1. **Application Identifier**:
   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-3940256099942544~1458002511</string> <!-- Replace with prodIosAppId -->
   ```
2. **SKAdNetwork Tracking Items**:
   Includes Google and partner network identifiers (`cstr6suwn9.skadnetwork`, etc.).
3. **App Tracking Transparency (ATT)**:
   ```xml
   <key>NSUserTrackingUsageDescription</key>
   <string>This identifier will be used to deliver personalized ads to you.</string>
   ```

---

## 3. Ad Placements & Behavior Rules

| Ad Type | Placement | Trigger Condition & Policy |
| :--- | :--- | :--- |
| **Adaptive Banner** | Bottom of `GameplayScreen`, `MainMenuScreen`, `LevelSelectScreen` | Placed below gameplay controls; never overlaps puzzle cells or interactive buttons. Automatically hides if user purchases "Remove Ads". |
| **Interstitial** | Between Level Transitions | Preloaded in background. Appears every 3 completed levels. **Never shown on levels 1–3**. Strict **60-second cooldown** between interstitials. |
| **Rewarded Ad (+1 Life)** | Game Over Modal Dialog | Offered when the player runs out of hearts (3 lives lost). Grants **+1 heart** only on verified `onUserEarnedReward`. |
| **Rewarded Ad (+3 Hints)** | Gameplay Hint Action | Offered when hint counter reaches 0. Grants **+3 hints** on completion. |

---

## 4. Testing & Verification

### Running with Test IDs
1. Run the app on an Android emulator or connected device:
   ```bash
   flutter run -d <device_id>
   ```
2. Banners display the Google "Test Ad" ribbon.
3. Completing levels 4, 7, 10 triggers test interstitials.
4. Tapping "Watch Ad for +1 Life" on Game Over displays the Google test video ad and grants 1 life upon reward callback.

### Error Handling & Offline Resilience
- Failed ad loads trigger exponential backoff retry (up to 3 attempts).
- If offline or ad network fails, gameplay continues smoothly without exceptions or freezes.

---

## 5. Pre-Submission Checklist

- [ ] Create AdMob account and link Android/iOS apps.
- [ ] Configure payment profile and app-ads.txt on developer website.
- [ ] Fill production IDs in `lib/config/ad_config.dart`.
- [ ] Update `APPLICATION_ID` in `AndroidManifest.xml` and `GADApplicationIdentifier` in `Info.plist`.
- [ ] Run `flutter analyze` (must report 0 issues).
- [ ] Run `flutter test` (must pass 100% of tests).

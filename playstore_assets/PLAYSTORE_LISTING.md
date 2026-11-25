# Google Play Store Listing & Upload Content — Eklavya's Aim

Use the fields below when creating and publishing **Eklavya's Aim** in **Google Play Console**.

---

## 1. App Details (Store Listing)
- **App name** (max 30 chars): `Eklavya's Aim`
- **Default language**: `English (United States) – en-US`
- **App or game**: `Game`
- **Category**: `Puzzle`
- **Free or paid**: `Free` (Contains ads, Optional In-App Purchases)
- **Tags**: `Puzzle`, `Logic`, `Maze`, `Offline`, `Casual`, `Brain Training`

### Short Description (max 80 chars — 74 chars used)
```
Untangle winding arrow mazes! Tap free arrows to clear the board & train logic.
```

### Full Description (max 4000 chars)
```
Sharpen your focus and test your spatial logic in Eklavya's Aim — a clean, minimalist arrow maze puzzle game!

Every board is a dense, interlocking labyrinth of snake-like arrows. Your goal is simple to learn and deeply satisfying to master: clear every arrow from the board without getting blocked.

HOW TO PLAY
• Look at where each arrow's head is pointing.
• Tap an arrow whose forward path to the edge of the board is completely clear — it will smoothly glide off the maze!
• Be careful! Tapping a blocked arrow shakes it and costs 1 heart. Lose all 3 hearts and the level fails.
• Clear all arrows to earn up to 3 stars and unlock the next challenge.

FEATURES
• Thousands of Solvable Levels: Progress from Beginner 10×10 grids up to massive 60×60 Expert silhouettes (Puppy, Trophy, Anchor, Butterfly, Heart, Star, Knight, and more).
• Smooth Controls: Pinch-to-zoom, pan freely around large mazes, and tap any part of an arrow from head to tail with instant precision.
• Helpful Tools: Use Undo to step back, Hints to reveal a guaranteed free move, or Eye Comfort Paper Theme for relaxed play.
• Daily Challenges & Stats: Track your win streak, completion times, and stars earned.
• Offline First: Play anytime, anywhere — no internet connection required for puzzles.

Download Eklavya's Aim today and see how far your focus can take you!
```

---

## 2. Contact & Privacy Policy
- **Developer Email**: `vivekvarol@gmail.com` *(or `support@eklavyasaim.com`)*
- **Privacy Policy Summary** *(host on your website/GitHub Pages and paste the URL in Play Console)*:
  - Eklavya's Aim stores game progress, settings, and statistics locally on the user's device (`SharedPreferences`) and does not collect personally identifiable information (PII).
  - The app uses **Google AdMob** (`ca-app-pub-8510368268823172~5543797564`) to display Banner, Interstitial, and optional Rewarded ads. Google AdMob may collect pseudonymous identifiers (such as Android Advertising ID) for ad delivery, analytics, and fraud prevention.

---

## 3. Data Safety Form Answers (Play Console)
- **Does your app collect or share any of the required user data types?** `Yes` (via Google Mobile Ads SDK)
  - **Device or other IDs** (Advertising ID): Collected & Shared with AdMob for *Advertising or marketing* and *Analytics*. Ephemeral / encrypted in transit.
  - **App activity / Diagnostics** (Ad interactions, crash logs via Play/AdMob SDK): Collected for *Analytics* and *App functionality*.
- **Personal info (Name, Email, Phone, Location, Photos)**: `No — Not collected`.

---

## 4. Content Rating & Target Audience
- **Target age group**: `13–15`, `16–17`, `18 and over` *(recommended if using standard AdMob ads without Families Policy child-directed tagging)*.
- **Violence / Mature Content / Gambling**: `None` (Expected Rating: **Everyone / PEGI 3**).

---

## 5. Graphics & Files Prepared in `playstore_assets/`
- **App Icon (512 × 512 px PNG)**: `playstore_assets/icon_512x512.png`
- **Feature Graphic (1024 × 500 px PNG)**: `playstore_assets/feature_graphic_1024x500.png`
- **Phone Screenshots (1080 × 2340 px PNG)**: `playstore_assets/screenshots/` (5 screenshots)
- **Signed App Bundle (`.aab`)**: `playstore_assets/EklavyasAim.aab` (also on Desktop)
- **Release APK (`.apk`)**: `playstore_assets/EklavyasAim.apk` (also on Desktop)

---

## 6. Release Notes (Version 1.0.0 — Build 1)
```
Initial release of Eklavya's Aim!
• Hundreds of deterministic, 100% solvable arrow maze levels across 5 difficulty tiers.
• Smooth snake slide-out animations, pinch-to-zoom, and synthesized sound effects.
• Eye Comfort Paper Theme, Daily Challenges, Hints, Undo, and Statistics.
```

---

## 7. Release Signing Keystore Info (Keep Safe!)
- **Keystore File**: `android/app/upload-keystore.jks`
- **Properties File**: `android/key.properties`
- **Key Alias**: `upload`
- **Store / Key Password**: `eklavya2026`
> Keep `upload-keystore.jks` backed up safely — Google Play requires the same upload key for future updates (or use Play App Signing).

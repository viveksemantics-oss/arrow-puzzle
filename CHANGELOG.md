# Changelog

All notable changes to the **Arrow Escape** mobile game project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] - 2026-11-24

### Initial Release & Implementation
- Project initialized with Flutter, Dart, Riverpod, and CustomPainter architecture.
- Designed and implemented the complete pure-Dart puzzle engine (`PuzzleEngine`, `PuzzleBoard`, `ArrowModel`).
- Developed the reverse-construction level generation engine and automated solver.
- Generated and verified 100 progressive levels across 7 board sizes (4x4 to 10x10).
- Created 12 screens: Splash, Onboarding, Main Menu, Level Select, Gameplay, Pause, Level Complete, Game Over, Settings, Daily Challenge, Statistics, and Privacy Policy.
- Added smooth vector arrow rendering with exit and shake animations.
- Implemented persistent storage using SharedPreferences for level progression, statistics, and settings.
- Integrated AdMob monetization and In-App Purchase store architecture.
- Added complete automated unit, solver, and widget test suites.
- Release configuration for Android (APK and AAB) and iOS.

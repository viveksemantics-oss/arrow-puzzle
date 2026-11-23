import 'package:flutter/material.dart';
import '../features/daily_challenge/daily_challenge_screen.dart';
import '../features/gameplay/screens/gameplay_screen.dart';
import '../features/home/main_menu_screen.dart';
import '../features/levels/level_select_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/privacy_policy_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/statistics/statistics_screen.dart';

/// Application routing map.
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String levels = '/levels';
  static const String gameplay = '/gameplay';
  static const String daily = '/daily';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String privacy = '/privacy';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        onboarding: (context) => const OnboardingScreen(),
        home: (context) => const MainMenuScreen(),
        levels: (context) => const LevelSelectScreen(),
        gameplay: (context) => const GameplayScreen(),
        daily: (context) => const DailyChallengeScreen(),
        statistics: (context) => const StatisticsScreen(),
        settings: (context) => const SettingsScreen(),
        privacy: (context) => const PrivacyPolicyScreen(),
      };
}

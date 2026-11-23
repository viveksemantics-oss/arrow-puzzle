import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local data storage service for player progression, statistics, and settings.
class StorageService {
  static const String _keyCurrentLevel = 'current_level';
  static const String _keyUnlockedLevels = 'unlocked_levels';
  static const String _keyCompletedLevels = 'completed_levels';
  static const String _keyBestTimes = 'best_completion_times';
  static const String _keyTotalGames = 'total_games_played';
  static const String _keyTotalCompleted = 'total_levels_completed';
  static const String _keyTotalArrowsRemoved = 'total_arrows_removed';
  static const String _keyHintsUsed = 'total_hints_used';
  static const String _keyUndoUsed = 'total_undo_used';
  static const String _keyHintsRemaining = 'hints_remaining';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyMusicEnabled = 'music_enabled';
  static const String _keyHapticsEnabled = 'haptics_enabled';
  static const String _keyDailyDates = 'daily_completed_dates';
  static const String _keyDailyStreak = 'daily_streak';
  static const String _keyIsPremium = 'is_premium';
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyLevelStars = 'level_stars';
  static const String _keyEyeComfortTheme = 'eye_comfort_theme';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Progression ---

  int get currentLevel => _prefs.getInt(_keyCurrentLevel) ?? 1;
  Future<void> setCurrentLevel(int level) => _prefs.setInt(_keyCurrentLevel, level);

  Set<int> get unlockedLevels {
    final list = _prefs.getStringList(_keyUnlockedLevels);
    if (list == null || list.isEmpty) {
      return {1}; // Level 1 unlocked by default
    }
    return list.map(int.parse).toSet();
  }

  Future<void> unlockLevel(int level) async {
    final current = unlockedLevels;
    current.add(level);
    await _prefs.setStringList(
      _keyUnlockedLevels,
      current.map((e) => e.toString()).toList(),
    );
  }

  Set<int> get completedLevels {
    final list = _prefs.getStringList(_keyCompletedLevels);
    if (list == null) return {};
    return list.map(int.parse).toSet();
  }

  Future<void> markLevelCompleted(int level, int completionSeconds) async {
    final comp = completedLevels;
    comp.add(level);
    await _prefs.setStringList(
      _keyCompletedLevels,
      comp.map((e) => e.toString()).toList(),
    );

    // Save best time
    final times = bestTimes;
    if (!times.containsKey(level) || completionSeconds < times[level]!) {
      times[level] = completionSeconds;
      await _prefs.setString(
        _keyBestTimes,
        jsonEncode(times.map((k, v) => MapEntry(k.toString(), v))),
      );
    }

    // Auto unlock next level
    await unlockLevel(level + 1);
    await incrementTotalCompleted();
  }

  Map<int, int> get bestTimes {
    final str = _prefs.getString(_keyBestTimes);
    if (str == null) return {};
    try {
      final decoded = jsonDecode(str) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (_) {
      return {};
    }
  }

  // --- Statistics ---

  int get totalGamesPlayed => _prefs.getInt(_keyTotalGames) ?? 0;
  Future<void> incrementTotalGames() =>
      _prefs.setInt(_keyTotalGames, totalGamesPlayed + 1);

  int get totalLevelsCompleted => _prefs.getInt(_keyTotalCompleted) ?? 0;
  Future<void> incrementTotalCompleted() =>
      _prefs.setInt(_keyTotalCompleted, totalLevelsCompleted + 1);

  int get totalArrowsRemoved => _prefs.getInt(_keyTotalArrowsRemoved) ?? 0;
  Future<void> addArrowsRemoved(int count) =>
      _prefs.setInt(_keyTotalArrowsRemoved, totalArrowsRemoved + count);

  int get totalHintsUsed => _prefs.getInt(_keyHintsUsed) ?? 0;
  Future<void> incrementHintsUsed() =>
      _prefs.setInt(_keyHintsUsed, totalHintsUsed + 1);

  int get totalUndoUsed => _prefs.getInt(_keyUndoUsed) ?? 0;
  Future<void> incrementUndoUsed() =>
      _prefs.setInt(_keyUndoUsed, totalUndoUsed + 1);

  // --- Hints Inventory ---

  int get hintsRemaining => _prefs.getInt(_keyHintsRemaining) ?? 3;
  Future<void> setHintsRemaining(int hints) =>
      _prefs.setInt(_keyHintsRemaining, hints);

  Future<bool> consumeHint() async {
    if (isPremium) return true; // Unlimited for premium
    final current = hintsRemaining;
    if (current > 0) {
      await setHintsRemaining(current - 1);
      await incrementHintsUsed();
      return true;
    }
    return false;
  }

  Future<void> addHints(int amount) async {
    await setHintsRemaining(hintsRemaining + amount);
  }

  // --- Daily Challenge ---

  Set<String> get dailyCompletedDates {
    final list = _prefs.getStringList(_keyDailyDates);
    return list?.toSet() ?? {};
  }

  bool isDailyCompleted(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return dailyCompletedDates.contains(key);
  }

  int get dailyStreak => _prefs.getInt(_keyDailyStreak) ?? 0;

  Future<void> markDailyCompleted(DateTime date) async {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final set = dailyCompletedDates;
    if (!set.contains(key)) {
      set.add(key);
      await _prefs.setStringList(_keyDailyDates, set.toList());
      await _prefs.setInt(_keyDailyStreak, dailyStreak + 1);
    }
  }

  // --- Stars & Theme ---

  Map<int, int> get allLevelStars {
    final str = _prefs.getString(_keyLevelStars);
    if (str == null) return {};
    try {
      final decoded = jsonDecode(str) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (_) {
      return {};
    }
  }

  int getStars(int level) => allLevelStars[level] ?? 0;

  Future<void> setStars(int level, int stars) async {
    final map = allLevelStars;
    if (!map.containsKey(level) || stars > map[level]!) {
      map[level] = stars;
      await _prefs.setString(
        _keyLevelStars,
        jsonEncode(map.map((k, v) => MapEntry(k.toString(), v))),
      );
    }
  }

  bool get isEyeComfortTheme => _prefs.getBool(_keyEyeComfortTheme) ?? false;
  Future<void> setEyeComfortTheme(bool enabled) =>
      _prefs.setBool(_keyEyeComfortTheme, enabled);

  // --- Settings ---

  bool get soundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  Future<void> setSoundEnabled(bool enabled) =>
      _prefs.setBool(_keySoundEnabled, enabled);

  bool get musicEnabled => _prefs.getBool(_keyMusicEnabled) ?? true;
  Future<void> setMusicEnabled(bool enabled) =>
      _prefs.setBool(_keyMusicEnabled, enabled);

  bool get hapticsEnabled => _prefs.getBool(_keyHapticsEnabled) ?? true;
  Future<void> setHapticsEnabled(bool enabled) =>
      _prefs.setBool(_keyHapticsEnabled, enabled);

  bool get isOnboardingDone => _prefs.getBool(_keyOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool done) =>
      _prefs.setBool(_keyOnboardingDone, done);

  // --- Monetization ---

  bool get isPremium => _prefs.getBool(_keyIsPremium) ?? false;
  Future<void> setPremium(bool premium) =>
      _prefs.setBool(_keyIsPremium, premium);

  /// Resets all player progress and statistics.
  Future<void> resetAllProgress() async {
    await _prefs.remove(_keyCurrentLevel);
    await _prefs.remove(_keyUnlockedLevels);
    await _prefs.remove(_keyCompletedLevels);
    await _prefs.remove(_keyBestTimes);
    await _prefs.remove(_keyTotalGames);
    await _prefs.remove(_keyTotalCompleted);
    await _prefs.remove(_keyTotalArrowsRemoved);
    await _prefs.remove(_keyHintsUsed);
    await _prefs.remove(_keyUndoUsed);
    await _prefs.remove(_keyHintsRemaining);
    await _prefs.remove(_keyDailyDates);
    await _prefs.remove(_keyDailyStreak);
  }
}

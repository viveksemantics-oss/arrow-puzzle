import 'dart:async';
import 'package:flutter/foundation.dart';
import '../generator/procedural_generator.dart';
import '../models/level_model.dart';

/// Repository responsible for on-demand procedural generation and caching of levels.
///
/// Supports 10,000+ procedurally generated levels with deterministic seeds.
class LevelRepository {
  static final LevelRepository _instance = LevelRepository._internal();
  factory LevelRepository() => _instance;
  LevelRepository._internal();

  final Map<int, LevelModel> _cache = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  int get totalLevels => 10000;

  /// Initializes and pre-warms the cache with initial levels.
  Future<void> loadLevels() async {
    if (_isLoaded) return;
    // Pre-cache early levels in background for instantaneous loading
    for (int i = 1; i <= 5; i++) {
      if (!_cache.containsKey(i)) {
        _cache[i] = ProceduralGenerator.generate(i);
      }
    }
    _isLoaded = true;
  }

  /// Gets a specific level synchronously from cache or generates it deterministically.
  LevelModel getLevel(int levelNumber) {
    final cached = _cache[levelNumber];
    if (cached != null) return cached;

    final generated = ProceduralGenerator.generate(levelNumber);
    _cache[levelNumber] = generated;
    return generated;
  }

  /// Loads a level asynchronously (using compute for larger boards if needed) to ensure UI responsiveness.
  Future<LevelModel> getLevelAsync(int levelNumber) async {
    final cached = _cache[levelNumber];
    if (cached != null) return cached;

    LevelModel generated;
    if (levelNumber > 100 && !kIsWeb) {
      generated = await compute(ProceduralGenerator.generate, levelNumber);
    } else {
      generated = ProceduralGenerator.generate(levelNumber);
    }

    _cache[levelNumber] = generated;
    return generated;
  }

  /// Generates a deterministic daily challenge puzzle for a given calendar date.
  LevelModel getDailyChallenge(DateTime date) {
    final dateSeed = date.year * 10000 + date.month * 100 + date.day;
    final cached = _cache[dateSeed];
    if (cached != null) return cached;

    final level = ProceduralGenerator.generate(dateSeed % 500 + 1);
    final dailyLevel = LevelModel(
      levelNumber: dateSeed,
      boardSize: level.boardSize,
      seed: dateSeed,
      difficulty: 'DAILY CHALLENGE',
      shapeName: level.shapeName,
      arrows: level.arrows,
      optimalSolution: level.optimalSolution,
      minMoves: level.minMoves,
    );

    _cache[dateSeed] = dailyLevel;
    return dailyLevel;
  }
}

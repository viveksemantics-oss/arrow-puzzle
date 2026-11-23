import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/admob_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/sound_manager.dart';
import '../engine/arrow_model.dart';
import '../engine/level_repository.dart';
import '../engine/move_result.dart';
import '../engine/puzzle_board.dart';
import '../engine/puzzle_engine.dart';
import '../models/level_model.dart';

// --- Core Singletons ---

final storageProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized in main()');
});

final soundProvider = Provider<SoundManager>((ref) {
  return SoundManager();
});

final admobProvider = Provider<AdMobService>((ref) {
  return AdMobService();
});

final purchaseProvider = Provider<PurchaseService>((ref) {
  return PurchaseService();
});

final levelRepoProvider = Provider<LevelRepository>((ref) {
  return LevelRepository();
});

// --- Gameplay State Model ---

class GameState {
  final LevelModel level;
  final PuzzleBoard board;
  final int moveCount;
  final int remainingArrows;
  final int elapsedSeconds;
  final int lives; // 3 hearts
  final int maxLives;
  final int hintsRemaining;
  final bool isWon;
  final bool isGameOver;
  final bool canUndo;
  final String? activeHintId;
  final MoveResult? lastMoveResult;
  final bool isDailyChallenge;
  final bool isEyeComfortTheme;

  const GameState({
    required this.level,
    required this.board,
    required this.moveCount,
    required this.remainingArrows,
    required this.elapsedSeconds,
    this.lives = 3,
    this.maxLives = 3,
    this.hintsRemaining = 3,
    required this.isWon,
    this.isGameOver = false,
    required this.canUndo,
    this.activeHintId,
    this.lastMoveResult,
    this.isDailyChallenge = false,
    this.isEyeComfortTheme = false,
  });

  GameState copyWith({
    LevelModel? level,
    PuzzleBoard? board,
    int? moveCount,
    int? remainingArrows,
    int? elapsedSeconds,
    int? lives,
    int? maxLives,
    int? hintsRemaining,
    bool? isWon,
    bool? isGameOver,
    bool? canUndo,
    String? activeHintId,
    MoveResult? lastMoveResult,
    bool? isDailyChallenge,
    bool? isEyeComfortTheme,
  }) {
    return GameState(
      level: level ?? this.level,
      board: board ?? this.board,
      moveCount: moveCount ?? this.moveCount,
      remainingArrows: remainingArrows ?? this.remainingArrows,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      lives: lives ?? this.lives,
      maxLives: maxLives ?? this.maxLives,
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      isWon: isWon ?? this.isWon,
      isGameOver: isGameOver ?? this.isGameOver,
      canUndo: canUndo ?? this.canUndo,
      activeHintId: activeHintId,
      lastMoveResult: lastMoveResult,
      isDailyChallenge: isDailyChallenge ?? this.isDailyChallenge,
      isEyeComfortTheme: isEyeComfortTheme ?? this.isEyeComfortTheme,
    );
  }
}

// --- Game Controller Notifier ---

class GameController extends Notifier<GameState> {
  late PuzzleEngine _engine;
  Timer? _timer;

  @override
  GameState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    final repo = ref.watch(levelRepoProvider);
    final storage = ref.watch(storageProvider);
    final initialLevel = repo.getLevel(storage.currentLevel);
    final board = initialLevel.createBoard();
    _engine = PuzzleEngine(board: board);

    _startTimer();

    return GameState(
      level: initialLevel,
      board: board,
      moveCount: 0,
      remainingArrows: board.activeArrowCount,
      elapsedSeconds: 0,
      lives: 3,
      maxLives: 3,
      hintsRemaining: storage.hintsRemaining,
      isWon: false,
      isGameOver: false,
      canUndo: false,
      isDailyChallenge: false,
      isEyeComfortTheme: storage.isEyeComfortTheme,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!state.isWon && !state.isGameOver) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  /// Taps an arrow on the board.
  /// If free: arrow exits, checks win.
  /// If blocked: loses 1 life, shakes, triggers sound and haptic, checks game over.
  MoveResult tapArrow(String arrowId) {
    if (state.isWon || state.isGameOver) {
      return MoveResult(
        status: MoveStatus.invalid,
        remainingArrows: state.remainingArrows,
      );
    }

    final sound = ref.read(soundProvider);
    final arrow = state.board.getArrowById(arrowId);
    if (arrow == null || !arrow.isActive) {
      return MoveResult(
        status: MoveStatus.invalid,
        remainingArrows: state.remainingArrows,
      );
    }

    if (state.board.isPathClear(arrow)) {
      // Clear path move
      final result = _engine.tapArrow(arrowId);
      sound.playExit();
      ref.read(storageProvider).addArrowsRemoved(1);

      if (result.isGameWon) {
        _timer?.cancel();
        sound.playWin();
        _recordWin();
      }

      state = state.copyWith(
        board: _engine.board,
        moveCount: _engine.moveCount,
        remainingArrows: _engine.remainingArrows,
        isWon: _engine.isWon,
        canUndo: _engine.canUndo,
        activeHintId: null,
        lastMoveResult: result,
      );
      return result;
    } else {
      // Blocked move: lose 1 life!
      final blocker = state.board.getFirstBlockingArrow(arrow);
      final ray = state.board.getBlockedRay(arrow);
      sound.playBlocked();

      final newLives = (state.lives - 1).clamp(0, state.maxLives);
      final gameOver = newLives <= 0;

      if (gameOver) {
        _timer?.cancel();
      }

      final result = MoveResult(
        status: MoveStatus.blocked,
        movedArrow: arrow,
        blockingArrow: blocker,
        blockedRay: ray,
        remainingArrows: state.remainingArrows,
        isGameWon: false,
      );

      state = state.copyWith(
        lives: newLives,
        isGameOver: gameOver,
        lastMoveResult: result,
      );

      return result;
    }
  }

  void _recordWin() {
    final storage = ref.read(storageProvider);
    // Calculate stars: 3 stars = 0 lives lost, 2 stars = 1 lost, 1 star = 2 lost
    final livesLost = state.maxLives - state.lives;
    final stars = (3 - livesLost).clamp(1, 3);

    if (state.isDailyChallenge) {
      storage.markDailyCompleted(DateTime.now());
    } else {
      storage.markLevelCompleted(state.level.levelNumber, state.elapsedSeconds);
      storage.setStars(state.level.levelNumber, stars);
    }
  }

  /// Undoes the last move (restores arrow, does NOT restore lost life).
  ArrowModel? undo() {
    if (!state.canUndo || state.isWon || state.isGameOver) return null;
    final arrow = _engine.undo();
    if (arrow != null) {
      ref.read(soundProvider).playTap();
      ref.read(storageProvider).incrementUndoUsed();
      state = state.copyWith(
        board: _engine.board,
        moveCount: _engine.moveCount,
        remainingArrows: _engine.remainingArrows,
        isWon: false,
        canUndo: _engine.canUndo,
        activeHintId: null,
      );
    }
    return arrow;
  }

  /// Restarts the current level (resets board, timer, and hearts).
  void restart() {
    _engine.restart();
    _startTimer();
    ref.read(soundProvider).playClick();
    state = state.copyWith(
      board: _engine.board,
      moveCount: 0,
      remainingArrows: _engine.remainingArrows,
      elapsedSeconds: 0,
      lives: state.maxLives,
      isWon: false,
      isGameOver: false,
      canUndo: false,
      activeHintId: null,
    );
  }

  /// Adds an extra life (e.g. from watching a rewarded ad).
  void addExtraLife() {
    state = state.copyWith(
      lives: (state.lives + 1).clamp(1, state.maxLives),
      isGameOver: false,
    );
    _startTimer();
  }

  /// Consumes 1 hint and highlights a free arrow from the solution.
  bool useHint() {
    if (state.isWon || state.isGameOver) return false;
    final storage = ref.read(storageProvider);

    if (state.hintsRemaining <= 0 && !storage.isPremium) {
      return false; // Prompt rewarded ad
    }

    // Find the next available unblocked arrow from optimal solution or board
    ArrowModel? candidate;
    for (final arrowId in state.level.optimalSolution) {
      final a = state.board.getArrowById(arrowId);
      if (a != null && a.isActive && state.board.isPathClear(a)) {
        candidate = a;
        break;
      }
    }

    if (candidate == null) {
      final clearArrows = state.board.getClearArrows();
      if (clearArrows.isNotEmpty) candidate = clearArrows.first;
    }

    if (candidate != null) {
      storage.consumeHint();
      ref.read(soundProvider).playTap();
      state = state.copyWith(
        activeHintId: candidate.id,
        hintsRemaining: storage.hintsRemaining,
      );
      return true;
    }

    return false;
  }

  /// Adds hints to player inventory.
  Future<void> addHints(int amount) async {
    final storage = ref.read(storageProvider);
    await storage.addHints(amount);
    state = state.copyWith(hintsRemaining: storage.hintsRemaining);
  }

  /// Toggles between Classic Light and Eye Comfort Paper themes.
  void toggleTheme() {
    final storage = ref.read(storageProvider);
    final newTheme = !state.isEyeComfortTheme;
    storage.setEyeComfortTheme(newTheme);
    state = state.copyWith(isEyeComfortTheme: newTheme);
  }

  /// Loads a new level.
  void loadLevel(int levelNumber) {
    final repo = ref.read(levelRepoProvider);
    final newLevel = repo.getLevel(levelNumber);
    _initLevel(newLevel, isDaily: false);
  }

  /// Loads the daily challenge.
  void loadDailyChallenge(DateTime date) {
    final repo = ref.read(levelRepoProvider);
    final dailyLevel = repo.getDailyChallenge(date);
    _initLevel(dailyLevel, isDaily: true);
  }

  void _initLevel(LevelModel level, {required bool isDaily}) {
    _timer?.cancel();
    final board = level.createBoard();
    _engine = PuzzleEngine(board: board);
    final storage = ref.read(storageProvider);

    state = GameState(
      level: level,
      board: board,
      moveCount: 0,
      remainingArrows: board.activeArrowCount,
      elapsedSeconds: 0,
      lives: 3,
      maxLives: 3,
      hintsRemaining: storage.hintsRemaining,
      isWon: false,
      isGameOver: false,
      canUndo: false,
      isDailyChallenge: isDaily,
      isEyeComfortTheme: storage.isEyeComfortTheme,
    );

    _startTimer();
    storage.incrementTotalGames();
  }
}

final gameControllerProvider =
    NotifierProvider.autoDispose<GameController, GameState>(() {
  return GameController();
});

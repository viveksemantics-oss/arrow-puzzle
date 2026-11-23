import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../widgets/arrow_board_widget.dart';
import '../widgets/game_controls.dart';
import '../widgets/game_header.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/level_completed_dialog.dart';
import '../widgets/pause_dialog.dart';

/// Full interactive Gameplay Screen for Arrow Maze.
///
/// Matches the exact UI layout from specifications:
/// - Top Bar: Circular Pause button, Level title + Tier badge pill, Stopwatch Timer pill
/// - Sub-row: Remaining arrows counter, Percent cleared, Thin progress bar
/// - Lives: 3 Hearts row (hearts turn grey when lost)
/// - Center: Board in rounded card with soft shadow and dot grid
/// - Bottom Bar: Undo, Hint (with badge count), Restart
class GameplayScreen extends ConsumerStatefulWidget {
  final int? initialLevel;
  final bool isDaily;

  const GameplayScreen({
    super.key,
    this.initialLevel,
    this.isDaily = false,
  });

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen> {
  final GlobalKey<ArrowBoardWidgetState> _boardKey = GlobalKey<ArrowBoardWidgetState>();
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(gameControllerProvider.notifier);
      if (widget.isDaily) {
        controller.loadDailyChallenge(DateTime.now());
      } else if (widget.initialLevel != null) {
        controller.loadLevel(widget.initialLevel!);
      }
    });
  }

  void _onArrowTapped(String arrowId) {
    final state = ref.read(gameControllerProvider);
    if (state.isWon || state.isGameOver) return;

    final arrow = state.board.getArrowById(arrowId);
    if (arrow == null || !arrow.isActive) return;

    final controller = ref.read(gameControllerProvider.notifier);

    if (state.board.isPathClear(arrow)) {
      // 1. Play visual snake slithering exit animation
      _boardKey.currentState?.animateArrowExit(arrow, () {
        // 2. Commit move to engine state after animation completes
        final result = controller.tapArrow(arrowId);
        if (result.isGameWon && !_dialogOpen) {
          _showVictoryDialog();
        }
      });
    } else {
      // 3. Blocked move: shake arrow, flash blocking arrow in red, lose 1 heart!
      final blocker = state.board.getFirstBlockingArrow(arrow);
      final ray = state.board.getBlockedRay(arrow);
      _boardKey.currentState?.animateArrowShake(arrow, blocker?.id, ray);

      controller.tapArrow(arrowId);
      final updatedState = ref.read(gameControllerProvider);

      if (updatedState.isGameOver && !_dialogOpen) {
        Future.delayed(const Duration(milliseconds: 380), () {
          if (mounted && !_dialogOpen) {
            _showGameOverDialog();
          }
        });
      }
    }
  }

  void _showVictoryDialog() {
    _dialogOpen = true;
    final state = ref.read(gameControllerProvider);
    final storage = ref.read(storageProvider);
    final admob = ref.read(admobProvider);
    final livesLost = state.maxLives - state.lives;
    final stars = (3 - livesLost).clamp(1, 3);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LevelCompletedDialog(
        levelNumber: state.level.levelNumber,
        moves: state.moveCount,
        optimalMoves: state.level.minMoves,
        seconds: state.elapsedSeconds,
        stars: stars,
        onNextLevel: () {
          Navigator.of(ctx).pop();
          _dialogOpen = false;
          admob.showInterstitialIfEligible(storage, onDismissed: () {
            ref.read(gameControllerProvider.notifier).loadLevel(state.level.levelNumber + 1);
            _boardKey.currentState?.resetAnimations();
          });
        },
        onReplay: () {
          Navigator.of(ctx).pop();
          _dialogOpen = false;
          ref.read(gameControllerProvider.notifier).restart();
          _boardKey.currentState?.resetAnimations();
        },
        onMenu: () {
          Navigator.of(ctx).pop();
          _dialogOpen = false;
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showGameOverDialog() {
    _dialogOpen = true;
    final admob = ref.read(admobProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameOverDialog(
        onWatchAd: () {
          Navigator.of(ctx).pop();
          _dialogOpen = false;
          admob.showRewardedForHints(
            onRewardEarned: (amount) {
              controller.addExtraLife();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('+1 Life Restored! Keep Playing!')),
              );
            },
            onClosed: () {},
          );
        },
        onRetry: () {
          Navigator.of(ctx).pop();
          _dialogOpen = false;
          controller.restart();
          _boardKey.currentState?.resetAnimations();
        },
        onQuit: () {
          Navigator.of(ctx).pop();
          _dialogOpen = false;
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showPauseDialog() {
    final storage = ref.read(storageProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PauseDialog(
        onResume: () => Navigator.of(ctx).pop(),
        onRestart: () {
          Navigator.of(ctx).pop();
          ref.read(gameControllerProvider.notifier).restart();
          _boardKey.currentState?.resetAnimations();
        },
        onLevels: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pushReplacementNamed('/levels');
        },
        onHome: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
        soundEnabled: storage.soundEnabled,
        onToggleSound: (enabled) {
          storage.setSoundEnabled(enabled);
          ref.read(soundProvider).soundEnabled = enabled;
          setState(() {});
        },
      ),
    );
  }

  void _onHintPressed() {
    final state = ref.read(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final admob = ref.read(admobProvider);

    final success = controller.useHint();
    if (!success && state.hintsRemaining <= 0) {
      // Offer rewarded video ad for hints
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Need Hints?'),
          content: const Text('Watch a short video to earn 3 free hints?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                admob.showRewardedForHints(
                  onRewardEarned: (amount) {
                    controller.addHints(3);
                    controller.useHint();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('+3 Hints Earned!')),
                    );
                  },
                  onClosed: () {},
                );
              },
              child: const Text('Watch Video'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final isEyeComfort = gameState.isEyeComfortTheme;

    final bgColor = isEyeComfort
        ? const Color(0xFFF6EEDF)
        : const Color(0xFFF7F8FA);

    final totalArrows = gameState.level.arrows.length;
    final remaining = gameState.remainingArrows;
    final progress = totalArrows > 0
        ? ((totalArrows - remaining) / totalArrows).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Bar Header
            GameHeader(
              levelNumber: gameState.level.levelNumber,
              difficulty: gameState.level.difficulty,
              remainingArrows: remaining,
              elapsedSeconds: gameState.elapsedSeconds,
              onPause: _showPauseDialog,
              isDaily: gameState.isDailyChallenge,
              onToggleTheme: () {
                ref.read(gameControllerProvider.notifier).toggleTheme();
              },
              isEyeComfortTheme: isEyeComfort,
            ),

            // 2. Remaining, Percent, and Thin Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining: $remaining',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isEyeComfort
                              ? const Color(0xFF795548)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isEyeComfort
                              ? const Color(0xFF3E2723)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isEyeComfort
                          ? const Color(0xFFE8DCCB)
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isEyeComfort
                            ? const Color(0xFF5D4037)
                            : const Color(0xFF1E293B),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Lives / Hearts Indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(gameState.maxLives, (index) {
                  final hasLife = index < gameState.lives;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 22,
                      color: hasLife
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFCBD5E1),
                    ),
                  );
                }),
              ),
            ),

            // 4. Puzzle Board (Primary Focus in Rounded Card)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: ArrowBoardWidget(
                  key: _boardKey,
                  board: gameState.board,
                  onArrowTapped: _onArrowTapped,
                  activeHintId: gameState.activeHintId,
                  isEyeComfortTheme: isEyeComfort,
                ),
              ),
            ),

            // 5. Bottom Controls (Undo, Hint with badge, Restart)
            GameControls(
              canUndo: gameState.canUndo,
              hintsRemaining: gameState.hintsRemaining,
              onUndo: () {
                ref.read(gameControllerProvider.notifier).undo();
                _boardKey.currentState?.resetAnimations();
              },
              onHint: _onHintPressed,
              onRestart: () {
                ref.read(gameControllerProvider.notifier).restart();
                _boardKey.currentState?.resetAnimations();
              },
            ),
          ],
        ),
      ),
    );
  }
}

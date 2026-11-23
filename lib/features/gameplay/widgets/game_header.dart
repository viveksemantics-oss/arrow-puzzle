import 'package:flutter/material.dart';

/// Top bar header displaying pause button, level title + tier pill, and stopwatch timer pill.
class GameHeader extends StatelessWidget {
  final int levelNumber;
  final String difficulty;
  final int remainingArrows;
  final int elapsedSeconds;
  final VoidCallback onPause;
  final VoidCallback? onToggleTheme;
  final bool isEyeComfortTheme;
  final bool isDaily;

  const GameHeader({
    super.key,
    required this.levelNumber,
    required this.difficulty,
    required this.remainingArrows,
    required this.elapsedSeconds,
    required this.onPause,
    this.onToggleTheme,
    this.isEyeComfortTheme = false,
    this.isDaily = false,
  });

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isEyeComfortTheme
        ? const Color(0xFF3E2723)
        : const Color(0xFF1E293B);

    final pillBg = isEyeComfortTheme
        ? const Color(0xFFEDE1CF)
        : const Color(0xFFEEF2F6);

    final pillText = isEyeComfortTheme
        ? const Color(0xFF6D4C41)
        : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Left: Pause Button & Theme Toggle
          IconButton(
            onPressed: onPause,
            icon: const Icon(Icons.pause_circle_outline_rounded, size: 28),
            color: textColor,
            tooltip: 'Pause',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          if (onToggleTheme != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onToggleTheme,
              icon: Icon(
                isEyeComfortTheme
                    ? Icons.palette_rounded
                    : Icons.palette_outlined,
                size: 20,
              ),
              color: pillText,
              tooltip: 'Switch Theme',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],

          const Spacer(),

          // Center: Level Title & Tier Badge Pill
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isDaily ? 'Daily Challenge' : 'Level $levelNumber',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  difficulty.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: pillText,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Right: Timer Pill with Stopwatch Icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: pillText,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(elapsedSeconds),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Pause Button & Theme Toggle
          Row(
            children: [
              IconButton(
                onPressed: onPause,
                icon: const Icon(Icons.pause_circle_outline_rounded, size: 30),
                color: textColor,
                tooltip: 'Pause',
              ),
              if (onToggleTheme != null)
                IconButton(
                  onPressed: onToggleTheme,
                  icon: Icon(
                    isEyeComfortTheme
                        ? Icons.palette_rounded
                        : Icons.palette_outlined,
                    size: 22,
                  ),
                  color: pillText,
                  tooltip: 'Switch Theme',
                ),
            ],
          ),

          // Center: Level Title & Tier Badge Pill (Exact match to screenshot)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isDaily ? 'Daily Challenge' : 'Level $levelNumber',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  difficulty.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: pillText,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),

          // Right: Timer Pill with Stopwatch Icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: pillText,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(elapsedSeconds),
                  style: TextStyle(
                    fontSize: 13,
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

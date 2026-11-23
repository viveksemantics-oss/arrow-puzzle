import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Victory dialog presented upon completing a puzzle level.
class LevelCompletedDialog extends StatelessWidget {
  final int levelNumber;
  final int moves;
  final int optimalMoves;
  final int seconds;
  final int stars; // 1 to 3
  final VoidCallback onNextLevel;
  final VoidCallback onReplay;
  final VoidCallback onMenu;

  const LevelCompletedDialog({
    super.key,
    required this.levelNumber,
    required this.moves,
    required this.optimalMoves,
    required this.seconds,
    this.stars = 3,
    required this.onNextLevel,
    required this.onReplay,
    required this.onMenu,
  });

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stars Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isEarned = index < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isEarned ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isEarned ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                    size: index == 1 ? 46 : 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            const Text(
              'Level Cleared!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Level $levelNumber Completed',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            // Statistics Grid
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Time', _formatTime(seconds), Icons.timer_outlined),
                  Container(width: 1, height: 32, color: AppColors.border),
                  _statItem('Moves', '$moves', Icons.touch_app_outlined),
                  Container(width: 1, height: 32, color: AppColors.border),
                  _statItem('Optimal', '$optimalMoves', Icons.auto_awesome_outlined),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNextLevel,
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                label: const Text('Next Level'),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReplay,
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Replay'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onMenu,
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: const Text('Menu'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Modal dialog presented when gameplay is paused.
class PauseDialog extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onLevels;
  final VoidCallback onHome;
  final bool soundEnabled;
  final Function(bool) onToggleSound;

  const PauseDialog({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onLevels,
    required this.onHome,
    required this.soundEnabled,
    required this.onToggleSound,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Game Paused',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            // Resume Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text('Resume'),
              ),
            ),
            const SizedBox(height: 12),
            // Restart Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
                label: const Text('Restart'),
              ),
            ),
            const SizedBox(height: 12),
            // Level Select
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLevels,
                icon: const Icon(Icons.grid_view_rounded, color: AppColors.textPrimary),
                label: const Text('Level Select'),
              ),
            ),
            const SizedBox(height: 12),
            // Main Menu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onHome,
                icon: const Icon(Icons.home_rounded, color: AppColors.textPrimary),
                label: const Text('Main Menu'),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            // Sound quick toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sound Effects',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Switch.adaptive(
                  value: soundEnabled,
                  activeColor: AppColors.buttonDark,
                  onChanged: onToggleSound,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

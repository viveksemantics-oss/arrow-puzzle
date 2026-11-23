import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Bottom action bar providing Undo, Hint, and Restart controls.
class GameControls extends StatelessWidget {
  final bool canUndo;
  final int hintsRemaining;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onRestart;

  const GameControls({
    super.key,
    required this.canUndo,
    required this.hintsRemaining,
    required this.onUndo,
    required this.onHint,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo Button
          _ControlButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            isEnabled: canUndo,
            onPressed: canUndo ? onUndo : null,
          ),
          // Hint Button
          _ControlButton(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Hint',
            badge: '$hintsRemaining',
            badgeColor: AppColors.hint,
            isEnabled: true,
            onPressed: onHint,
          ),
          // Restart Button
          _ControlButton(
            icon: Icons.refresh_rounded,
            label: 'Restart',
            isEnabled: true,
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.badge,
    this.badgeColor,
    required this.isEnabled,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                  if (badge != null)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor ?? AppColors.buttonDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../gameplay/providers/game_providers.dart';

/// Main Menu Screen displaying progress, play actions, and feature navigation.
class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageProvider);
    final sound = ref.watch(soundProvider);
    final currentLevel = storage.currentLevel;
    final completedCount = storage.completedLevels.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar with Sound and Settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      final updated = !sound.soundEnabled;
                      storage.setSoundEnabled(updated);
                      sound.soundEnabled = updated;
                      (context as Element).markNeedsBuild();
                    },
                    icon: Icon(
                      sound.soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Toggle Sound',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pushNamed('/settings'),
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: 'Settings',
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // App Logo & Title
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x20000000),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Arrow Maze',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completedCount Levels Completed',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(flex: 2),

              // Primary Continue / Play Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    sound.playClick();
                    ref.read(gameControllerProvider.notifier).loadLevel(currentLevel);
                    Navigator.of(context).pushNamed('/gameplay');
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  label: Text(
                    completedCount == 0 ? 'Play Level 1' : 'Continue (Level $currentLevel)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Level Select Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    sound.playClick();
                    Navigator.of(context).pushNamed('/levels');
                  },
                  icon: const Icon(Icons.grid_view_rounded, size: 20),
                  label: const Text('Level Select'),
                ),
              ),
              const SizedBox(height: 14),

              // Daily Challenge Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    sound.playClick();
                    Navigator.of(context).pushNamed('/daily');
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.hint),
                  label: const Text('Daily Challenge'),
                ),
              ),
              const SizedBox(height: 14),

              // Statistics Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    sound.playClick();
                    Navigator.of(context).pushNamed('/statistics');
                  },
                  icon: const Icon(Icons.bar_chart_rounded, size: 22),
                  label: const Text('Statistics'),
                ),
              ),

              const Spacer(flex: 2),

              // Footer Info
              const Text(
                'v1.0.0 • Pure Minimalist Puzzle',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

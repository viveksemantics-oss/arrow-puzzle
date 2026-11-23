import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../gameplay/providers/game_providers.dart';

/// Settings Screen providing audio controls, reset options, and policy links.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(storageProvider);
    final sound = ref.watch(soundProvider);
    final purchase = ref.watch(purchaseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Audio & Feedback Section
            _sectionHeader('AUDIO & HAPTICS'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: storage.soundEnabled,
                    activeColor: AppColors.buttonDark,
                    onChanged: (val) {
                      storage.setSoundEnabled(val);
                      sound.soundEnabled = val;
                      (context as Element).markNeedsBuild();
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
                  SwitchListTile.adaptive(
                    title: const Text('Haptic Feedback', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: storage.hapticsEnabled,
                    activeColor: AppColors.buttonDark,
                    onChanged: (val) {
                      storage.setHapticsEnabled(val);
                      sound.hapticsEnabled = val;
                      (context as Element).markNeedsBuild();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Appearance & Theme Section
            _sectionHeader('APPEARANCE & THEME'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile.adaptive(
                title: const Text('Eye Comfort Paper Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Warm cream paper background with espresso ink'),
                value: storage.isEyeComfortTheme,
                activeColor: const Color(0xFF6D4C41),
                onChanged: (val) {
                  storage.setEyeComfortTheme(val);
                  ref.read(gameControllerProvider.notifier).toggleTheme();
                  (context as Element).markNeedsBuild();
                },
              ),
            ),
            const SizedBox(height: 24),

            // Store & Upgrades Section
            _sectionHeader('PREMIUM UPGRADES'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.block_rounded, color: AppColors.textPrimary),
                    title: const Text('Remove Advertisements', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(storage.isPremium ? 'Already Purchased' : 'Ad-free gaming experience'),
                    trailing: storage.isPremium
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
                        : TextButton(
                            onPressed: () async {
                              final success = await purchase.buyProduct('com.arrowescape.remove_ads');
                              if (!success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Store billing pending platform configuration.')),
                                );
                              }
                            },
                            child: const Text('Unlock'),
                          ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.restore_rounded, color: AppColors.textPrimary),
                    title: const Text('Restore Purchases', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () async {
                      await purchase.restorePurchases();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Purchases restored.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Legal & Data Section
            _sectionHeader('ABOUT & PRIVACY'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textPrimary),
                    title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).pushNamed('/privacy'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.textPrimary),
                    title: const Text('About Arrow Maze', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('v1.0.0 (Build 1)'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    title: const Text('Reset All Progress', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Reset All Progress?'),
                          content: const Text('This will delete all completed levels, statistics, and records permanently.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                await storage.resetAllProgress();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Progress has been reset.')),
                                );
                                (context as Element).markNeedsBuild();
                              },
                              child: const Text('Reset', style: TextStyle(color: AppColors.error)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

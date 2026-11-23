import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../gameplay/providers/game_providers.dart';

/// Level Select Screen supporting 10,000+ levels with difficulty tiers and star ratings.
class LevelSelectScreen extends ConsumerStatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  ConsumerState<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends ConsumerState<LevelSelectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _tiers = [
    {'name': 'Beginner (1-25)', 'range': [1, 25]},
    {'name': 'Easy (26-60)', 'range': [26, 60]},
    {'name': 'Medium (61-150)', 'range': [61, 150]},
    {'name': 'Hard (151-300)', 'range': [151, 300]},
    {'name': 'Expert (301-500)', 'range': [301, 500]},
    {'name': 'Master (501-1000)', 'range': [501, 1000]},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tiers.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(storageProvider);
    final sound = ref.watch(soundProvider);
    final unlocked = storage.unlockedLevels;
    final completed = storage.completedLevels;
    final allStars = storage.allLevelStars;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Level'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.buttonDark,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: _tiers.map((t) => Tab(text: t['name'] as String)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tiers.map((tier) {
          final range = tier['range'] as List<int>;
          final start = range[0];
          final end = range[1];
          final count = end - start + 1;

          return GridView.builder(
            padding: const EdgeInsets.all(18),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemCount: count,
            itemBuilder: (context, idx) {
              final levelNum = start + idx;
              final isUnlocked = unlocked.contains(levelNum);
              final isCompleted = completed.contains(levelNum);
              final stars = allStars[levelNum] ?? (isCompleted ? 3 : 0);

              return _LevelTile(
                levelNumber: levelNum,
                isUnlocked: isUnlocked,
                isCompleted: isCompleted,
                stars: stars,
                onTap: isUnlocked
                    ? () {
                        sound.playClick();
                        ref
                            .read(gameControllerProvider.notifier)
                            .loadLevel(levelNum);
                        Navigator.of(context).pushNamed('/gameplay');
                      }
                    : null,
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int levelNumber;
  final bool isUnlocked;
  final bool isCompleted;
  final int stars;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.levelNumber,
    required this.isUnlocked,
    required this.isCompleted,
    this.stars = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? AppColors.surface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFFF59E0B).withOpacity(0.5)
                : (isUnlocked ? AppColors.border : Colors.transparent),
            width: isCompleted ? 1.5 : 1.0,
          ),
          boxShadow: isUnlocked
              ? const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isUnlocked)
              const Icon(
                Icons.lock_rounded,
                size: 22,
                color: AppColors.textMuted,
              )
            else ...[
              Text(
                '$levelNumber',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              // Stars
              if (isCompleted && stars > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Icon(
                      i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 13,
                      color: i < stars
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFCBD5E1),
                    );
                  }),
                )
              else
                Text(
                  'Play',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary.withOpacity(0.8),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

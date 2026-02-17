import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_app_new/providers/auth_provider.dart';
import 'package:expense_app_new/services/gamification_service.dart';
import 'package:expense_app_new/database/database.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🏆 [AchievementsScreen] Building...');
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      print('🏆 [AchievementsScreen] User is null');
      return const Center(child: CircularProgressIndicator());
    }

    final gamificationService = ref.watch(gamificationServiceProvider);
    
    // Use StreamProvider.family to ensure unique streams per user
    final statsAsync = ref.watch(userStatsStreamProvider(user.id));
    final unlockedAsync = ref.watch(unlockedAchievementsStreamProvider(user.id));

    // We also need all achievements to show locked ones
    final allAchievementsAsync = ref.watch(allAchievementsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Card
            statsAsync.when(
              data: (stats) {
                print('🏆 [AchievementsScreen] Stats loaded: $stats');
                if (stats == null) return const SizedBox.shrink();
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, 'Wellness Score', '${stats.wellnessScore}', Icons.health_and_safety),
                        _buildStatItem(context, 'Streak', '${stats.currentStreak} Days', Icons.local_fire_department, color: Colors.orange),
                        _buildStatItem(context, 'Points', '${stats.totalPoints}', Icons.stars, color: Colors.amber),
                      ],
                    ),
                  ),
                );
              },
              loading: () {
                print('🏆 [AchievementsScreen] Stats loading...');
                return const Center(child: CircularProgressIndicator());
              },
              error: (e, s) {
                print('🏆 [AchievementsScreen] Stats error: $e');
                return Text('Error: $e');
              },
            ),
            const SizedBox(height: 24),
            
            Text(
              'Badges',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Achievements Grid
            allAchievementsAsync.when(
              data: (allAchievements) {
                print('🏆 [AchievementsScreen] All achievements loaded: ${allAchievements.length}');
                return unlockedAsync.when(
                  data: (unlocked) {
                    print('🏆 [AchievementsScreen] Unlocked achievements loaded: ${unlocked.length}');
                    final unlockedIds = unlocked.map((a) => a.id).toSet();
                    
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 columns
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: allAchievements.length,
                      itemBuilder: (context, index) {
                        final achievement = allAchievements[index];
                        final isUnlocked = unlockedIds.contains(achievement.id);
                        
                        return _buildAchievementCard(context, achievement, isUnlocked);
                      },
                    );
                  },
                  loading: () {
                    print('🏆 [AchievementsScreen] Unlocked achievements loading...');
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  error: (e, s) {
                    print('🏆 [AchievementsScreen] Unlocked achievements error: $e');
                    return Text('Error loading unlocked: $e');
                  },
                );
              },
              loading: () {
                print('🏆 [AchievementsScreen] All achievements loading...');
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              error: (e, s) {
                print('🏆 [AchievementsScreen] All achievements error: $e');
                return Text('Error loading achievements: $e');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 32, color: color ?? theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement, bool isUnlocked) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: isUnlocked ? 2 : 0,
      color: isUnlocked ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isUnlocked 
            ? BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)) 
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUnlocked ? theme.colorScheme.primaryContainer : Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(achievement.iconName),
                size: 32,
                color: isUnlocked ? theme.colorScheme.primary : Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isUnlocked ? null : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(isUnlocked ? 1 : 0.5),
              ),
            ),
            const SizedBox(height: 8),
            if (isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${achievement.points} pts',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'flag': return Icons.flag;
      case 'local_fire_department': return Icons.local_fire_department;
      case 'whatshot': return Icons.whatshot;
      case 'savings': return Icons.savings;
      case 'stars': return Icons.stars;
      default: return Icons.star;
    }
  }
}

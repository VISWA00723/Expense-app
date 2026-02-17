import 'package:drift/drift.dart';
import 'package:expense_app_new/database/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_app_new/providers/database_provider.dart';

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService(ref.read(databaseProvider));
});

final userStatsStreamProvider = StreamProvider.autoDispose.family<UserStat?, int>((ref, userId) {
  return ref.watch(gamificationServiceProvider).watchUserStats(userId).distinct();
});

final unlockedAchievementsStreamProvider = StreamProvider.autoDispose.family<List<Achievement>, int>((ref, userId) {
  return ref.watch(gamificationServiceProvider).watchUnlockedAchievements(userId).distinct();
});

final allAchievementsFutureProvider = FutureProvider<List<Achievement>>((ref) async {
  return ref.watch(gamificationServiceProvider).getAllAchievements();
});

class GamificationService {
  final AppDatabase db;

  GamificationService(this.db);

  // Initialize achievements if they don't exist
  Future<void> initializeAchievements() async {
    print('🏆 [Gamification] Initializing achievements...');
    
    final achievements = [
      AchievementsCompanion(
        id: const Value('first_expense'),
        title: const Value('First Step'),
        description: const Value('Record your first expense'),
        iconName: const Value('flag'),
        points: const Value(10),
        conditionType: const Value('count'),
        conditionValue: const Value(1),
      ),
      AchievementsCompanion(
        id: const Value('streak_3'),
        title: const Value('Consistency is Key'),
        description: const Value('Log in for 3 days in a row'),
        iconName: const Value('local_fire_department'),
        points: const Value(50),
        conditionType: const Value('streak'),
        conditionValue: const Value(3),
      ),
      AchievementsCompanion(
        id: const Value('streak_7'),
        title: const Value('On Fire!'),
        description: const Value('Log in for 7 days in a row'),
        iconName: const Value('whatshot'),
        points: const Value(100),
        conditionType: const Value('streak'),
        conditionValue: const Value(7),
      ),
      AchievementsCompanion(
        id: const Value('streak_30'),
        title: const Value('Monthly Master'),
        description: const Value('Log in for 30 days in a row'),
        iconName: const Value('calendar_month'),
        points: const Value(500),
        conditionType: const Value('streak'),
        conditionValue: const Value(30),
      ),
      AchievementsCompanion(
        id: const Value('streak_90'),
        title: const Value('Quarterly King'),
        description: const Value('Log in for 90 days in a row'),
        iconName: const Value('workspace_premium'),
        points: const Value(1000),
        conditionType: const Value('streak'),
        conditionValue: const Value(90),
      ),
      AchievementsCompanion(
        id: const Value('streak_180'),
        title: const Value('Half-Year Hero'),
        description: const Value('Log in for 180 days in a row'),
        iconName: const Value('military_tech'),
        points: const Value(2000),
        conditionType: const Value('streak'),
        conditionValue: const Value(180),
      ),
      AchievementsCompanion(
        id: const Value('streak_365'),
        title: const Value('Yearly Legend'),
        description: const Value('Log in for 365 days in a row'),
        iconName: const Value('diamond'),
        points: const Value(5000),
        conditionType: const Value('streak'),
        conditionValue: const Value(365),
      ),
      AchievementsCompanion(
        id: const Value('budget_master'),
        title: const Value('Budget Master'),
        description: const Value('Stay under budget for a month'),
        iconName: const Value('savings'),
        points: const Value(200),
        conditionType: const Value('budget'),
        conditionValue: const Value(1),
      ),
    ];

    // Check if achievements already exist to avoid unnecessary writes
    final count = await db.select(db.achievements).get().then((l) => l.length);
    if (count >= achievements.length) {
      print('🏆 [Gamification] Achievements already initialized ($count)');
      return;
    }

    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.achievements, achievements);
    });
    print('🏆 [Gamification] Achievements initialized/updated successfully');
  }

  // Ensure gamification data is initialized for a user
  Future<void> ensureInitialized(int userId) async {
    print('🏆 [Gamification] Ensuring initialization for user $userId');
    // Run initialization in parallel if possible, but here we need achievements first
    await initializeAchievements();
    
    final stats = await (db.select(db.userStats)..where((t) => t.userId.equals(userId))).getSingleOrNull();
    if (stats == null) {
      print('🏆 [Gamification] Creating initial stats for user $userId');
      final today = DateTime.now().toIso8601String().split('T')[0];
      await db.into(db.userStats).insert(UserStatsCompanion(
        userId: Value(userId),
        currentStreak: const Value(1),
        longestStreak: const Value(1),
        lastLoginDate: Value(today),
        wellnessScore: const Value(50),
      ));
    } else {
      print('🏆 [Gamification] Stats already exist for user $userId');
    }
  }

  // Update user streak on login
  Future<void> updateStreak(int userId) async {
    print('🏆 [Gamification] Updating streak for user $userId');
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final stats = await (db.select(db.userStats)..where((t) => t.userId.equals(userId))).getSingleOrNull();
    
    if (stats == null) {
      // First time user or missing stats
      await ensureInitialized(userId);
      return;
    }

    if (stats.lastLoginDate == today) {
      // Already logged in today
      print('🏆 [Gamification] Already logged in today');
      return;
    }

    final lastLogin = DateTime.parse(stats.lastLoginDate);
    final now = DateTime.now();
    
    // Normalize to date only (midnight)
    final lastLoginDate = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
    final nowDate = DateTime(now.year, now.month, now.day);
    
    final difference = nowDate.difference(lastLoginDate).inDays;

    if (difference == 1) {
      // Consecutive day
      final newStreak = stats.currentStreak + 1;
      print('🏆 [Gamification] Streak increased to $newStreak');
      await db.update(db.userStats).replace(stats.copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > stats.longestStreak ? newStreak : stats.longestStreak,
        lastLoginDate: today,
      ));
      
      // Check streak achievements
      await _checkStreakAchievements(userId, newStreak);
    } else {
      // Streak broken
      print('🏆 [Gamification] Streak broken (was ${stats.currentStreak})');
      await db.update(db.userStats).replace(stats.copyWith(
        currentStreak: 1,
        lastLoginDate: today,
      ));
    }
  }

  // Calculate Financial Wellness Score (0-100)
  Future<int> calculateWellnessScore(int userId) async {
    print('🏆 [Gamification] Calculating wellness score for user $userId');
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    // Parallelize independent queries
    final results = await Future.wait([
      db.getUserById(userId),
      db.getTotalIncomeForMonth(userId, currentMonth),
      db.getTotalByMonth(userId, currentMonth),
      (db.select(db.userStats)..where((t) => t.userId.equals(userId))).getSingleOrNull(),
    ]);

    final user = results[0] as User?;
    final totalIncome = results[1] as double;
    final totalExpenses = results[2] as double;
    var stats = results[3] as UserStat?;

    if (user == null) return 50;
    
    double score = 50.0;

    // 1. Savings Rate (up to 40 points)
    if (totalIncome > 0) {
      final savingsRate = (totalIncome - totalExpenses) / totalIncome;
      if (savingsRate >= 0.20) score += 40; // Excellent
      else if (savingsRate >= 0.10) score += 30; // Good
      else if (savingsRate >= 0.05) score += 20; // Okay
      else if (savingsRate > 0) score += 10; // At least positive
      else score -= 10; // Overspending
    }

    // 2. Consistency (Streak) (up to 10 points)
    // If stats are missing, initialize them
    if (stats == null) {
      await ensureInitialized(userId);
      // Re-fetch stats
      stats = await (db.select(db.userStats)..where((t) => t.userId.equals(userId))).getSingleOrNull();
    }
    
    if (stats != null) {
      if (stats.currentStreak >= 7) score += 10;
      else if (stats.currentStreak >= 3) score += 5;
    }

    // 3. Budget Adherence (up to 20 points)
    // Simplified: if expenses < income, give points. 
    // Ideally check against defined budgets, but this is a good proxy for referenced budgets.
    if (totalExpenses < totalIncome) score += 20;

    // Cap score at 100 and min at 0
    final finalScore = score.clamp(0, 100).toInt();
    print('🏆 [Gamification] New wellness score: $finalScore');

    // Update stats
    if (stats != null) {
      await db.update(db.userStats).replace(stats.copyWith(wellnessScore: finalScore));
    }

    return finalScore;
  }

  // Check and unlock achievements
  Future<void> _checkStreakAchievements(int userId, int currentStreak) async {
    final streakAchievements = await (db.select(db.achievements)
      ..where((t) => t.conditionType.equals('streak') & t.conditionValue.isSmallerOrEqualValue(currentStreak)))
      .get();

    for (final achievement in streakAchievements) {
      await _unlockAchievement(userId, achievement);
    }
  }

  Future<void> checkExpenseAchievements(int userId) async {
    print('🏆 [Gamification] Checking expense achievements');
    // Check 'first_expense'
    final expenseCount = await db.getExpenseCount(userId);
    
    if (expenseCount >= 1) {
      final achievement = await (db.select(db.achievements)..where((t) => t.id.equals('first_expense'))).getSingleOrNull();
      if (achievement != null) {
        await _unlockAchievement(userId, achievement);
      }
    }
  }

  Future<void> _unlockAchievement(int userId, Achievement achievement) async {
    final existing = await (db.select(db.userAchievements)
      ..where((t) => t.userId.equals(userId) & t.achievementId.equals(achievement.id)))
      .getSingleOrNull();

    if (existing == null) {
      print('🏆 [Gamification] Unlocked achievement: ${achievement.title}');
      await db.into(db.userAchievements).insert(UserAchievementsCompanion(
        userId: Value(userId),
        achievementId: Value(achievement.id),
        unlockedAt: Value(DateTime.now().toIso8601String()),
      ));

      // Update total points
      final stats = await (db.select(db.userStats)..where((t) => t.userId.equals(userId))).getSingleOrNull();
      if (stats != null) {
        await db.update(db.userStats).replace(stats.copyWith(
          totalPoints: stats.totalPoints + achievement.points
        ));
      }
    }
  }

  Future<List<Achievement>> getAllAchievements() {
    print('🏆 [Gamification] Fetching all achievements');
    return db.select(db.achievements).get();
  }
  
  Stream<UserStat?> watchUserStats(int userId) {
    print('🏆 [Gamification] Watching user stats for $userId');
    return (db.select(db.userStats)..where((t) => t.userId.equals(userId))).watchSingleOrNull();
  }
  
  Stream<List<Achievement>> watchUnlockedAchievements(int userId) {
    print('🏆 [Gamification] Watching unlocked achievements for $userId');
    return (db.select(db.userAchievements)
      ..where((t) => t.userId.equals(userId)))
      .join([
        innerJoin(db.achievements, db.achievements.id.equalsExp(db.userAchievements.achievementId))
      ])
      .watch()
      .map((rows) => rows.map((row) => row.readTable(db.achievements)).toList());
  }
}

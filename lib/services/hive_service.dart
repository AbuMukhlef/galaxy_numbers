import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class HiveService {
  static const String usersBox       = 'users';
  static const String progressBox    = 'moon_progress';
  static const String performanceBox = 'performance';
  static const String badgesBox      = 'badges';
  static const String streaksBox     = 'streaks';

  static Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();
    await _openBoxes();
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MoonProgressAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(QuestionPerformanceAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(BadgeModelAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(StreakModelAdapter());
  }

  static Future<void> _openBoxes() async {
    await Future.wait([
      Hive.openBox<UserModel>(usersBox),
      Hive.openBox<MoonProgress>(progressBox),
      Hive.openBox<QuestionPerformance>(performanceBox),
      Hive.openBox<BadgeModel>(badgesBox),
      Hive.openBox<StreakModel>(streaksBox),
    ]);
  }

  static Future<void> clearUser(String userId) async {
    final progress    = Hive.box<MoonProgress>(progressBox);
    final performance = Hive.box<QuestionPerformance>(performanceBox);
    final badges      = Hive.box<BadgeModel>(badgesBox);
    final streaks     = Hive.box<StreakModel>(streaksBox);
    await progress.deleteAll(progress.keys.where((k)=>k.toString().startsWith('${userId}_')).toList());
    await performance.deleteAll(performance.keys.where((k)=>k.toString().startsWith('${userId}_')).toList());
    await badges.deleteAll(badges.keys.where((k)=>badges.get(k)?.userId==userId).toList());
    await streaks.delete(userId);
    await Hive.box<UserModel>(usersBox).delete(userId);
  }
}

import 'package:hive/hive.dart';
part 'streak_model.g.dart';

@HiveType(typeId: 4)
class StreakModel extends HiveObject {
  @HiveField(0) final String userId;
  @HiveField(1) int currentStreak;
  @HiveField(2) int bestStreak;
  @HiveField(3) DateTime? lastPlayDate;

  StreakModel({required this.userId, this.currentStreak=0, this.bestStreak=0, this.lastPlayDate});

  bool recordPlay() {
    final today=DateTime.now();
    if(lastPlayDate==null){ currentStreak=1; }
    else {
      final diff=today.difference(lastPlayDate!).inDays;
      if(diff==0) {
        return false;
      } else if(diff==1) currentStreak++;
      else currentStreak=1;
    }
    lastPlayDate=today;
    if(currentStreak>bestStreak) bestStreak=currentStreak;
    return currentStreak%3==0;
  }

  bool get isStreakBroken => lastPlayDate!=null && DateTime.now().difference(lastPlayDate!).inDays>1;

  Map<String, dynamic> toJson() => {'user_id':userId,'current_streak':currentStreak,
    'best_streak':bestStreak,'last_play_date':lastPlayDate?.toIso8601String()};

  factory StreakModel.fromJson(Map<String, dynamic> j) => StreakModel(
    userId:j['user_id'],currentStreak:j['current_streak'],bestStreak:j['best_streak'],
    lastPlayDate:j['last_play_date']!=null?DateTime.parse(j['last_play_date']):null);
}

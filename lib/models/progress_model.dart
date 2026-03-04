import 'package:hive/hive.dart';
part 'progress_model.g.dart';

@HiveType(typeId: 1)
class MoonProgress extends HiveObject {
  @HiveField(0) final String userId;
  @HiveField(1) final String moonKey;
  @HiveField(2) double energy;
  @HiveField(3) bool isUnlocked;
  @HiveField(4) bool isCompleted;
  @HiveField(5) int currentLayer;
  @HiveField(6) bool layer1Done;
  @HiveField(7) bool layer2Done;
  @HiveField(8) bool layer3Done;

  MoonProgress({required this.userId, required this.moonKey,
    this.energy=0.0, this.isUnlocked=false, this.isCompleted=false,
    this.currentLayer=1, this.layer1Done=false, this.layer2Done=false, this.layer3Done=false});

  void addEnergy(double a) { energy=(energy+a).clamp(0.0,100.0); if(energy>=100.0) isCompleted=true; }

  Map<String, dynamic> toJson() => {'user_id':userId,'moon_key':moonKey,'energy':energy,
    'is_unlocked':isUnlocked,'is_completed':isCompleted,'current_layer':currentLayer,
    'layer1_done':layer1Done,'layer2_done':layer2Done,'layer3_done':layer3Done};

  factory MoonProgress.fromJson(Map<String, dynamic> j) => MoonProgress(
    userId:j['user_id'],moonKey:j['moon_key'],energy:(j['energy'] as num).toDouble(),
    isUnlocked:j['is_unlocked'],isCompleted:j['is_completed'],currentLayer:j['current_layer'],
    layer1Done:j['layer1_done'],layer2Done:j['layer2_done'],layer3Done:j['layer3_done']);
}

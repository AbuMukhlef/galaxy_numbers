import 'package:hive/hive.dart';
part 'performance_model.g.dart';

@HiveType(typeId: 2)
class QuestionPerformance extends HiveObject {
  @HiveField(0) final String userId;
  @HiveField(1) final String questionKey;
  @HiveField(2) int attempts;
  @HiveField(3) int correct;
  @HiveField(4) int wrong;
  @HiveField(5) double avgTime;
  @HiveField(6) DateTime lastSeen;
  @HiveField(7) int reviewAfterN;

  QuestionPerformance({required this.userId, required this.questionKey,
    this.attempts=0, this.correct=0, this.wrong=0, this.avgTime=0.0,
    required this.lastSeen, this.reviewAfterN=0});

  double get weaknessScore => attempts==0?0:wrong/attempts;
  bool get isMastered => attempts>=3 && weaknessScore<0.15;
  bool get isWeak => weaknessScore>0.35;

  void recordAnswer({required bool isCorrect, required double timeTaken}) {
    attempts++;
    if(isCorrect) correct++; else wrong++;
    avgTime=((avgTime*(attempts-1))+timeTaken)/attempts;
    lastSeen=DateTime.now();
  }

  Map<String, dynamic> toJson() => {'user_id':userId,'question_key':questionKey,
    'attempts':attempts,'correct':correct,'wrong':wrong,'avg_time':avgTime,
    'last_seen':lastSeen.toIso8601String(),'review_after_n':reviewAfterN};

  factory QuestionPerformance.fromJson(Map<String, dynamic> j) => QuestionPerformance(
    userId:j['user_id'],questionKey:j['question_key'],attempts:j['attempts'],
    correct:j['correct'],wrong:j['wrong'],avgTime:(j['avg_time'] as num).toDouble(),
    lastSeen:DateTime.parse(j['last_seen']),reviewAfterN:j['review_after_n']??0);
}

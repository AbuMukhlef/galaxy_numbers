import 'package:hive/hive.dart';
part 'badge_model.g.dart';

@HiveType(typeId: 3)
class BadgeModel extends HiveObject {
  @HiveField(0) final String userId;
  @HiveField(1) final String badgeType;
  @HiveField(2) final DateTime earnedAt;
  @HiveField(3) final String userName;

  BadgeModel({required this.userId, required this.badgeType, required this.earnedAt, required this.userName});

  String get displayName {
    const m = {'expertTable2':'خبيرة جدول 2','expertTable3':'خبيرة جدول 3',
      'expertTable4':'خبيرة جدول 4','expertTable5':'خبيرة جدول 5','expertTable6':'خبيرة جدول 6',
      'expertTable7':'خبيرة جدول 7','expertTable8':'خبيرة جدول 8','expertTable9':'خبيرة جدول 9',
      'expertTable10':'خبيرة جدول 10','speedChampion':'بطلة السرعة','focusQueen':'ملكة التركيز',
      'streakLegend':'أسطورة السلسلة','divisionPro':'محترفة القسمة'};
    return m[badgeType]??badgeType;
  }

  Map<String, dynamic> toJson() => {'user_id':userId,'badge_type':badgeType,
    'earned_at':earnedAt.toIso8601String(),'user_name':userName};

  factory BadgeModel.fromJson(Map<String, dynamic> j) => BadgeModel(
    userId:j['user_id'],badgeType:j['badge_type'],
    earnedAt:DateTime.parse(j['earned_at']),userName:j['user_name']);
}

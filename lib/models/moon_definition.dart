import 'question_model.dart';

class MoonDefinition {
  final String key, nameAr, nameEn;
  final QuestionType type;
  final int tableNumber, layer1Count, layer2Count, layer3Duration;
  final String? prerequisite;

  const MoonDefinition({required this.key, required this.nameAr, required this.nameEn,
    required this.type, required this.tableNumber,
    this.layer1Count=10, this.layer2Count=20, this.layer3Duration=60, this.prerequisite});
}

const List<MoonDefinition> multiplicationMoons = [
  MoonDefinition(key:'mul_2', nameAr:'جدول 2', nameEn:'Table 2', type:QuestionType.multiplication, tableNumber:2),
  MoonDefinition(key:'mul_5', nameAr:'جدول 5', nameEn:'Table 5', type:QuestionType.multiplication, tableNumber:5,  prerequisite:'mul_2'),
  MoonDefinition(key:'mul_10',nameAr:'جدول 10',nameEn:'Table 10',type:QuestionType.multiplication, tableNumber:10, prerequisite:'mul_5'),
  MoonDefinition(key:'mul_3', nameAr:'جدول 3', nameEn:'Table 3', type:QuestionType.multiplication, tableNumber:3,  prerequisite:'mul_10'),
  MoonDefinition(key:'mul_4', nameAr:'جدول 4', nameEn:'Table 4', type:QuestionType.multiplication, tableNumber:4,  prerequisite:'mul_3'),
  MoonDefinition(key:'mul_6', nameAr:'جدول 6', nameEn:'Table 6', type:QuestionType.multiplication, tableNumber:6,  prerequisite:'mul_4'),
  MoonDefinition(key:'mul_7', nameAr:'جدول 7', nameEn:'Table 7', type:QuestionType.multiplication, tableNumber:7,  prerequisite:'mul_6'),
  MoonDefinition(key:'mul_8', nameAr:'جدول 8', nameEn:'Table 8', type:QuestionType.multiplication, tableNumber:8,  prerequisite:'mul_7'),
  MoonDefinition(key:'mul_9', nameAr:'جدول 9', nameEn:'Table 9', type:QuestionType.multiplication, tableNumber:9,  prerequisite:'mul_8'),
];

MoonDefinition? getMoonDefinition(String key) {
  try { return multiplicationMoons.firstWhere((m)=>m.key==key); } catch(_){ return null; }
}

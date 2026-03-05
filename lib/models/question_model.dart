enum QuestionType { multiplication, division, addition, subtraction }
enum QuestionSource { normal, weaknessList, spacedRepetition }

class QuestionModel {
  final int operandA, operandB;
  final QuestionType type;
  final QuestionSource source;
  const QuestionModel({required this.operandA, required this.operandB,
    required this.type, this.source=QuestionSource.normal});

  String get key { final op=switch(type){QuestionType.multiplication=>'x',QuestionType.division=>'÷',QuestionType.addition=>'+',QuestionType.subtraction=>'-'}; return '$operandA$op$operandB'; }
  int get answer => switch(type){QuestionType.multiplication=>operandA*operandB,QuestionType.division=>operandA~/operandB,QuestionType.addition=>operandA+operandB,QuestionType.subtraction=>operandA-operandB};
  String get displayAr { final op=switch(type){QuestionType.multiplication=>'×',QuestionType.division=>'÷',QuestionType.addition=>'+',QuestionType.subtraction=>'−'}; return '$operandA $op $operandB = ?'; }
  bool checkAnswer(String input) { final p=int.tryParse(input.trim()); return p!=null&&p==answer; }
}

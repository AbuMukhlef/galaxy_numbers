// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionPerformanceAdapter extends TypeAdapter<QuestionPerformance> {
  @override
  final int typeId = 2;

  @override
  QuestionPerformance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionPerformance(
      userId: fields[0] as String,
      questionKey: fields[1] as String,
      attempts: fields[2] as int,
      correct: fields[3] as int,
      wrong: fields[4] as int,
      avgTime: fields[5] as double,
      lastSeen: fields[6] as DateTime,
      reviewAfterN: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, QuestionPerformance obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.questionKey)
      ..writeByte(2)
      ..write(obj.attempts)
      ..writeByte(3)
      ..write(obj.correct)
      ..writeByte(4)
      ..write(obj.wrong)
      ..writeByte(5)
      ..write(obj.avgTime)
      ..writeByte(6)
      ..write(obj.lastSeen)
      ..writeByte(7)
      ..write(obj.reviewAfterN);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionPerformanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

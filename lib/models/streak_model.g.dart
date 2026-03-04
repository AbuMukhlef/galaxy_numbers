// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StreakModelAdapter extends TypeAdapter<StreakModel> {
  @override
  final int typeId = 4;

  @override
  StreakModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StreakModel(
      userId: fields[0] as String,
      currentStreak: fields[1] as int,
      bestStreak: fields[2] as int,
      lastPlayDate: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StreakModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.currentStreak)
      ..writeByte(2)
      ..write(obj.bestStreak)
      ..writeByte(3)
      ..write(obj.lastPlayDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

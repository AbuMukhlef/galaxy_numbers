// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MoonProgressAdapter extends TypeAdapter<MoonProgress> {
  @override
  final int typeId = 1;

  @override
  MoonProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoonProgress(
      userId: fields[0] as String,
      moonKey: fields[1] as String,
      energy: fields[2] as double,
      isUnlocked: fields[3] as bool,
      isCompleted: fields[4] as bool,
      currentLayer: fields[5] as int,
      layer1Done: fields[6] as bool,
      layer2Done: fields[7] as bool,
      layer3Done: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MoonProgress obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.moonKey)
      ..writeByte(2)
      ..write(obj.energy)
      ..writeByte(3)
      ..write(obj.isUnlocked)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(5)
      ..write(obj.currentLayer)
      ..writeByte(6)
      ..write(obj.layer1Done)
      ..writeByte(7)
      ..write(obj.layer2Done)
      ..writeByte(8)
      ..write(obj.layer3Done);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoonProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

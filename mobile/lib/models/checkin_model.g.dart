// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckinModelAdapter extends TypeAdapter<CheckinModel> {
  @override
  final int typeId = 0;

  @override
  CheckinModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckinModel(
      condition: fields[0] as String,
      date: fields[1] as DateTime,
      answers: (fields[2] as Map).cast<String, String>(),
      riskLevel: fields[3] as String,
      riskColor: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CheckinModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.condition)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.answers)
      ..writeByte(3)
      ..write(obj.riskLevel)
      ..writeByte(4)
      ..write(obj.riskColor);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckinModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'love_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoveProfileAdapter extends TypeAdapter<LoveProfile> {
  @override
  final int typeId = 0;

  @override
  LoveProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoveProfile(
      yourName: fields[0] as String,
      partnerName: fields[1] as String,
      relationshipDate: fields[2] as DateTime,
      yourPhoto: fields[3] as String,
      partnerPhoto: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LoveProfile obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.yourName)
      ..writeByte(1)
      ..write(obj.partnerName)
      ..writeByte(2)
      ..write(obj.relationshipDate)
      ..writeByte(3)
      ..write(obj.yourPhoto)
      ..writeByte(4)
      ..write(obj.partnerPhoto);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoveProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

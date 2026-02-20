// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PageModelAdapter extends TypeAdapter<PageModel> {
  @override
  final int typeId = 1;

  @override
  PageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PageModel(
      id: fields[0] as String,
      documentId: fields[1] as String,
      imagePath: fields[2] as String,
      ocrText: fields[3] as String?,
      orderIndex: fields[4] as int,
      originalImagePath: fields[5] as String?,
      cropCorners: (fields[6] as List?)?.cast<double>(),
      filterType: fields[7] == null ? 0 : fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PageModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.documentId)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.ocrText)
      ..writeByte(4)
      ..write(obj.orderIndex)
      ..writeByte(5)
      ..write(obj.originalImagePath)
      ..writeByte(6)
      ..write(obj.cropCorners)
      ..writeByte(7)
      ..write(obj.filterType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

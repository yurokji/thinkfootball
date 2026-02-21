import 'dart:convert';
import 'package:uuid/uuid.dart';

class PageModel {
  final String id;
  final String documentId;
  String imagePath;
  String? ocrText;
  int orderIndex;
  String? originalImagePath;
  List<double>? cropCorners; // [x1,y1, x2,y2, x3,y3, x4,y4] normalized 0.0-1.0
  int filterType; // 0=Original, 1=Magic, 2=B/W...

  PageModel({
    required this.id,
    required this.documentId,
    required this.imagePath,
    this.ocrText,
    required this.orderIndex,
    this.originalImagePath,
    this.cropCorners,
    this.filterType = 0,
  });

  factory PageModel.create({
    required String documentId,
    required String imagePath,
    required int orderIndex,
    String? originalImagePath,
    List<double>? cropCorners,
    int filterType = 0,
  }) {
    return PageModel(
      id: const Uuid().v4(),
      documentId: documentId,
      imagePath: imagePath,
      orderIndex: orderIndex,
      originalImagePath: originalImagePath,
      cropCorners: cropCorners,
      filterType: filterType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'image_path': imagePath,
      'ocr_text': ocrText,
      'order_index': orderIndex,
      'original_image_path': originalImagePath,
      'crop_corners': cropCorners != null ? jsonEncode(cropCorners) : null,
      'filter_type': filterType,
    };
  }

  factory PageModel.fromMap(Map<String, dynamic> map) {
    return PageModel(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      imagePath: map['image_path'] as String,
      ocrText: map['ocr_text'] as String?,
      orderIndex: map['order_index'] as int,
      originalImagePath: map['original_image_path'] as String?,
      cropCorners: map['crop_corners'] != null
          ? List<double>.from(jsonDecode(map['crop_corners'] as String))
          : null,
      filterType: map['filter_type'] as int? ?? 0,
    );
  }
}

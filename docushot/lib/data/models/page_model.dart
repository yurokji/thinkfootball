import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'page_model.g.dart';

@HiveType(typeId: 1)
class PageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String documentId;

  @HiveField(2)
  String imagePath;

  @HiveField(3)
  String? ocrText;

  @HiveField(4)
  int orderIndex;

  @HiveField(5)
  String? originalImagePath;

  @HiveField(6)
  List<double>? cropCorners; // Stores [x1,y1, x2,y2, x3,y3, x4,y4] normalized to 0.0-1.0

  @HiveField(7, defaultValue: 0)
  int filterType; // 0=Original, 1=Magic, 2=B/W... (Matches FilterType enum index)

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
}

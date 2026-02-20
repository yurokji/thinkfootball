import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'document_model.g.dart';

@HiveType(typeId: 0)
class DocumentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  String? thumbnailPath;

  @HiveField(5)
  List<String> pageIds;

  DocumentModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    required this.pageIds,
  });

  factory DocumentModel.create({required String title}) {
    final now = DateTime.now();
    return DocumentModel(
      id: const Uuid().v4(),
      title: title,
      createdAt: now,
      updatedAt: now,
      pageIds: [],
    );
  }
}

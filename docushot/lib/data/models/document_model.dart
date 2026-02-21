import 'dart:convert';
import 'package:uuid/uuid.dart';

class DocumentModel {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  String? thumbnailPath;
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'thumbnail_path': thumbnailPath,
      'page_ids': jsonEncode(pageIds),
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      thumbnailPath: map['thumbnail_path'] as String?,
      pageIds: List<String>.from(jsonDecode(map['page_ids'] as String)),
    );
  }
}

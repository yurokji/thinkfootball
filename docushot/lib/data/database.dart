import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'docushot.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE documents (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            thumbnail_path TEXT,
            page_ids TEXT NOT NULL DEFAULT '[]'
          )
        ''');

        await db.execute('''
          CREATE TABLE pages (
            id TEXT PRIMARY KEY,
            document_id TEXT NOT NULL,
            image_path TEXT NOT NULL,
            ocr_text TEXT,
            order_index INTEGER NOT NULL DEFAULT 0,
            original_image_path TEXT,
            crop_corners TEXT,
            filter_type INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_pages_document_id ON pages(document_id)',
        );
      },
    );
  }
}

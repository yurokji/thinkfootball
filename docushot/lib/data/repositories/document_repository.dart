import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:docushot/data/models/document_model.dart';
import 'package:docushot/data/models/page_model.dart';

class DocumentRepository {
  final Database _db;
  final _changeController = StreamController<void>.broadcast();

  DocumentRepository(this._db);

  /// Stream that fires whenever documents or pages change.
  Stream<void> get changes => _changeController.stream;

  void _notifyChange() {
    _changeController.add(null);
  }

  void dispose() {
    _changeController.close();
  }

  // --- Document Operations ---

  List<DocumentModel> getAllDocuments() {
    // sqflite doesn't have a sync query — use the async variant and cache.
    // This is called from the stream provider which handles async.
    throw UnsupportedError('Use getAllDocumentsAsync instead');
  }

  Future<List<DocumentModel>> getAllDocumentsAsync() async {
    final rows = await _db.query('documents', orderBy: 'updated_at DESC');
    return rows.map((r) => DocumentModel.fromMap(r)).toList();
  }

  Future<DocumentModel?> getDocumentAsync(String id) async {
    final rows = await _db.query('documents', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return DocumentModel.fromMap(rows.first);
  }

  Future<DocumentModel> createDocument(String title) async {
    final doc = DocumentModel.create(title: title);
    await _db.insert('documents', doc.toMap());
    _notifyChange();
    return doc;
  }

  Future<void> _saveDocument(DocumentModel doc) async {
    await _db.update('documents', doc.toMap(), where: 'id = ?', whereArgs: [doc.id]);
  }

  Future<void> deleteDocument(String id) async {
    final doc = await getDocumentAsync(id);
    if (doc != null) {
      for (var pageId in doc.pageIds) {
        final page = await getPageAsync(pageId);
        if (page != null) {
          _deletePageFiles(page);
        }
      }
      await _db.delete('pages', where: 'document_id = ?', whereArgs: [id]);
      await _db.delete('documents', where: 'id = ?', whereArgs: [id]);
      _notifyChange();
    }
  }

  // --- Page Operations ---

  Future<PageModel?> getPageAsync(String pageId) async {
    final rows = await _db.query('pages', where: 'id = ?', whereArgs: [pageId]);
    if (rows.isEmpty) return null;
    return PageModel.fromMap(rows.first);
  }

  Future<List<PageModel>> getPagesForDocumentAsync(String documentId) async {
    final doc = await getDocumentAsync(documentId);
    if (doc == null) return [];

    List<PageModel> orderedPages = [];
    for (var pageId in doc.pageIds) {
      final page = await getPageAsync(pageId);
      if (page != null) {
        orderedPages.add(page);
      }
    }
    return orderedPages;
  }

  Future<void> addPageToDocument(
    String documentId,
    String imagePath, {
    String? originalImagePath,
    List<double>? cropCorners,
    int filterType = 0,
  }) async {
    final doc = await getDocumentAsync(documentId);
    if (doc == null) return;

    final newIndex = doc.pageIds.length;
    final page = PageModel.create(
      documentId: documentId,
      imagePath: imagePath,
      orderIndex: newIndex,
      originalImagePath: originalImagePath,
      cropCorners: cropCorners,
      filterType: filterType,
    );

    await _db.insert('pages', page.toMap());

    doc.pageIds.add(page.id);
    if (doc.pageIds.length == 1) {
      doc.thumbnailPath = imagePath;
    }
    doc.updatedAt = DateTime.now();
    await _saveDocument(doc);
    _notifyChange();
  }

  Future<void> updatePageImage(
    String pageId,
    String newImagePath, {
    List<double>? cropCorners,
    int? filterType,
  }) async {
    final page = await getPageAsync(pageId);
    if (page == null) {
      debugPrint('Error updating page image: page $pageId not found');
      return;
    }

    if (page.originalImagePath == null) {
      page.originalImagePath = page.imagePath;
    }

    final oldPath = page.imagePath;
    if (oldPath != newImagePath && oldPath != page.originalImagePath) {
      _tryDeleteFile(oldPath);
    }

    page.imagePath = newImagePath;
    if (cropCorners != null) {
      page.cropCorners = cropCorners;
    }
    if (filterType != null) {
      page.filterType = filterType;
    }

    await _db.update('pages', page.toMap(), where: 'id = ?', whereArgs: [pageId]);
    _notifyChange();
  }

  Future<void> updatePageOcrText(String pageId, String text) async {
    await _db.update('pages', {'ocr_text': text}, where: 'id = ?', whereArgs: [pageId]);
    _notifyChange();
  }

  Future<void> deletePage(String documentId, String pageId) async {
    final doc = await getDocumentAsync(documentId);
    if (doc == null) return;

    doc.pageIds.remove(pageId);
    if (doc.pageIds.isEmpty) {
      doc.thumbnailPath = null;
    } else {
      final firstPage = await getPageAsync(doc.pageIds.first);
      if (firstPage != null) {
        doc.thumbnailPath = firstPage.imagePath;
      }
    }
    doc.updatedAt = DateTime.now();
    await _saveDocument(doc);

    final page = await getPageAsync(pageId);
    if (page != null) {
      _deletePageFiles(page);
    }
    await _db.delete('pages', where: 'id = ?', whereArgs: [pageId]);
    _notifyChange();
  }

  Future<void> reorderPages(String documentId, int oldIndex, int newIndex) async {
    final doc = await getDocumentAsync(documentId);
    if (doc == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = doc.pageIds.removeAt(oldIndex);
    doc.pageIds.insert(newIndex, item);

    doc.updatedAt = DateTime.now();
    await _saveDocument(doc);
    _notifyChange();
  }

  Future<void> renameDocument(String documentId, String newTitle) async {
    final doc = await getDocumentAsync(documentId);
    if (doc != null) {
      doc.title = newTitle;
      doc.updatedAt = DateTime.now();
      await _saveDocument(doc);
      _notifyChange();
    }
  }

  void _deletePageFiles(PageModel page) {
    _tryDeleteFile(page.imagePath);
    if (page.originalImagePath != null && page.originalImagePath != page.imagePath) {
      _tryDeleteFile(page.originalImagePath!);
    }
  }

  void _tryDeleteFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      debugPrint('Failed to delete file: $path - $e');
    }
  }
}

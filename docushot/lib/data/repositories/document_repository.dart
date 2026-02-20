import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:docushot/data/models/document_model.dart';
import 'package:docushot/data/models/page_model.dart';

class DocumentRepository {
  final Box<DocumentModel> _documentBox;
  final Box<PageModel> _pageBox;

  DocumentRepository(this._documentBox, this._pageBox);

  // --- Document Operations ---

  List<DocumentModel> getAllDocuments() {
    final docs = _documentBox.values.toList();
    // Sort by created date descending (newest first)
    docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return docs;
  }

  DocumentModel? getDocument(String id) {
    // Hive stores by key, but our ID is a field. 
    // Optimization: If we used ID as key, we could use _documentBox.get(id).
    // For now, linear search or assuming ID logic aligns later.
    try {
      return _documentBox.values.firstWhere((doc) => doc.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<DocumentModel> createDocument(String title) async {
    final doc = DocumentModel.create(title: title);
    await _documentBox.add(doc);
    return doc;
  }

  Future<void> deleteDocument(String id) async {
    final doc = getDocument(id);
    if (doc != null) {
      // Delete associated pages
      final pagesToDelete = _pageBox.values.where((p) => doc.pageIds.contains(p.id)).toList();
      for (var p in pagesToDelete) {
        await p.delete();
      }
      await doc.delete();
    }
  }

  // --- Page Operations ---

  List<PageModel> getPagesForDocument(String documentId) {
    final doc = getDocument(documentId);
    if (doc == null) return [];

    // Filter pages and sort by order defined in doc.pageIds
    // This is safer than trusting page.orderIndex alone if reordering happens
    final pagesMap = {for (var p in _pageBox.values) p.id: p};
    
    List<PageModel> orderedPages = [];
    for (var pageId in doc.pageIds) {
      if (pagesMap.containsKey(pageId)) {
        orderedPages.add(pagesMap[pageId]!);
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
    final doc = getDocument(documentId);
    if (doc == null) return;

    final newIndex = doc.pageIds.length;
    final page = PageModel.create(
      documentId: documentId,
      imagePath: imagePath,
      orderIndex: newIndex,
      originalImagePath: originalImagePath, // Save original
      cropCorners: cropCorners,
      filterType: filterType,
    );

    await _pageBox.add(page);
    
    // Update Document
    doc.pageIds.add(page.id);
    // Update thumbnail if it's the first page
    if (doc.pageIds.length == 1) {
      doc.thumbnailPath = imagePath;
    }
    doc.updatedAt = DateTime.now();
    await doc.save();
  }

  Future<void> updatePageImage(
    String pageId, 
    String newImagePath, {
    List<double>? cropCorners,
    int? filterType,
  }) async {
    try {
      final page = _pageBox.values.firstWhere((p) => p.id == pageId);
      
      // Ensure original is saved before first edit
      if (page.originalImagePath == null) {
        page.originalImagePath = page.imagePath; 
      }
      
      // Update displayed image
      page.imagePath = newImagePath;
      
      // Update metadata if provided
      if (cropCorners != null) {
        page.cropCorners = cropCorners;
      }
      if (filterType != null) {
        page.filterType = filterType;
      }

      await page.save();
    } catch (e) {
      debugPrint('Error updating page image: $e');
    }
  }

  Future<void> deletePage(String documentId, String pageId) async {
    final doc = getDocument(documentId);
    if (doc == null) return;

    // Remove from document's pageIds
    doc.pageIds.remove(pageId);
    // Update thumbnail if needed
    if (doc.pageIds.isEmpty) {
      doc.thumbnailPath = null;
    } else if (doc.thumbnailPath != null) {
      // If deleted page was the thumbnail, use first remaining page
      final firstPage = _pageBox.values.where((p) => p.id == doc.pageIds.first).firstOrNull;
      if (firstPage != null) {
        doc.thumbnailPath = firstPage.imagePath;
      }
    }
    doc.updatedAt = DateTime.now();
    await doc.save();

    // Delete the page record
    final page = _pageBox.values.where((p) => p.id == pageId).firstOrNull;
    if (page != null) {
      await page.delete();
    }
  }

  Future<void> reorderPages(String documentId, int oldIndex, int newIndex) async {
    final doc = getDocument(documentId);
    if (doc == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = doc.pageIds.removeAt(oldIndex);
    doc.pageIds.insert(newIndex, item);
    
    doc.updatedAt = DateTime.now();
    await doc.save();
  }
}

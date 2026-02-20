import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:async/async.dart';
import 'package:docushot/data/models/document_model.dart';
import 'package:docushot/data/models/page_model.dart';
import 'package:docushot/data/repositories/document_repository.dart';
import 'package:docushot/data/services/pdf_service.dart';
import 'package:docushot/data/services/export_service.dart';
import 'package:docushot/data/services/camera_service.dart'; 
import 'package:docushot/data/services/scanner_service.dart'; // NEW
import 'package:docushot/utils/test_image_generator.dart'; 
import 'dart:io'; // NEW
import 'package:image_picker/image_picker.dart';

// --- Dependencies ---

final documentBoxProvider = Provider<Box<DocumentModel>>((ref) {
  return Hive.box<DocumentModel>('documents');
});

final pageBoxProvider = Provider<Box<PageModel>>((ref) {
  return Hive.box<PageModel>('pages');
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final docBox = ref.watch(documentBoxProvider);
  final pageBox = ref.watch(pageBoxProvider);
  return DocumentRepository(docBox, pageBox);
});

// --- State Providers ---

// Stream of all documents (listens to Box events)
final documentListProvider = StreamProvider<List<DocumentModel>>((ref) async* {
  final repository = ref.watch(documentRepositoryProvider);
  final box = ref.watch(documentBoxProvider);

  // Initial yield
  yield repository.getAllDocuments();

  // Watch for changes
  await for (final _ in box.watch()) {
    yield repository.getAllDocuments();
  }
});

// Stream of pages for a specific document
final documentPagesProvider = StreamProvider.family<List<PageModel>, String>((ref, documentId) async* {
  final repository = ref.watch(documentRepositoryProvider);
  final docBox = ref.watch(documentBoxProvider);
  final pageBox = ref.watch(pageBoxProvider); // Need to watch page box too

  // Helper to fetch
  List<PageModel> fetch() => repository.getPagesForDocument(documentId);

  yield fetch();

  // Watch both boxes for changes
  // Merging streams simplistically or just listening to re-renders caused by repository actions
  // For simplicity: Watch generic box events.
  // Ideally, we should listen to specific object changes, but box.watch() is simple.
  
  // Create a combined stream or just listen to relevant events manually?
  // Let's rely on Ref.notifyListeners() from Controller or just watch boxes.
  
  await for (final _ in StreamGroup.merge([docBox.watch(), pageBox.watch()])) {
     yield fetch();
  }
});

// --- Services Providers ---

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
final exportServiceProvider = Provider<ExportService>((ref) => ExportService());
final cameraServiceProvider = Provider<CameraService>((ref) => CameraService());
final scannerServiceProvider = Provider<ScannerService>((ref) => ScannerService()); // NEW

// --- Controller ---

class DocumentController {
  final DocumentRepository _repository;
  final PdfService _pdfService;
  final ExportService _exportService;
  final CameraService _cameraService;

  DocumentController(
    this._repository, 
    this._pdfService, 
    this._exportService,
    this._cameraService,
  );

  // Updated to accept richer data from Custom Camera (Map: 'path', 'originalPath')
  Future<DocumentModel> createDocument({List<dynamic>? initialImages}) async {
    // Determine title
    final now = DateTime.now();
    final title = 'Scan ${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}';
    final doc = await _repository.createDocument(title);

    if (initialImages != null && initialImages.isNotEmpty) {
      await _processAndAddImages(doc.id, initialImages);
    }
    return doc;
  }

  Future<void> deleteDocument(String id) async {
    await _repository.deleteDocument(id);
  }

  // Helper to handle both List<String> (legacy/gallery) and List<Map> (camera)
  Future<void> _processAndAddImages(String documentId, List<dynamic> images) async {
    for (var item in images) {
      if (item is String) {
        await _repository.addPageToDocument(documentId, item, originalImagePath: item);
      } else if (item is Map) {
        final path = item['path'] as String;
        final originalPath = item['originalPath'] as String?;
        final corners = item['corners'] as List<double>?;
        // final filter = item['filter'] as int?; // Future use
        
        await _repository.addPageToDocument(
          documentId, 
          path, 
          originalImagePath: originalPath, 
          cropCorners: corners,
        );
      }
    }
  }
  
  // Expose as public for DetailScreen
  Future<void> addPagesToDocument(String documentId, List<dynamic> images) async {
    await _processAndAddImages(documentId, images);
  }

  Future<void> updatePageImage(String pageId, String newImagePath, {List<double>? cropCorners, int? filterType}) async {
    await _repository.updatePageImage(pageId, newImagePath, cropCorners: cropCorners, filterType: filterType);
  }

  Future<void> importImagesFromGallery(String documentId) async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isEmpty) return;

    // Gallery images are "original" by default
    final paths = images.map((e) => e.path).toList();
    await addPagesToDocument(documentId, paths);
  }

  Future<void> deletePage(String documentId, String pageId) async {
    await _repository.deletePage(documentId, pageId);
  }

  Future<void> reorderPages(String documentId, int oldIndex, int newIndex) async {
    await _repository.reorderPages(documentId, oldIndex, newIndex);
  }

  Future<void> exportPdf(String documentId, {List<String>? pageIds}) async {
    List<PageModel> pages = _repository.getPagesForDocument(documentId);
    final doc = _repository.getDocument(documentId);
    
    if (pages.isEmpty || doc == null) return;

    // Filter if specific pages selected
    if (pageIds != null && pageIds.isNotEmpty) {
      pages = pages.where((p) => p.id != null && pageIds.contains(p.id)).toList();
    }

    final imagePaths = pages.map((p) => p.imagePath).toList();
    final pdfPath = await _pdfService.generatePdf(imagePaths, doc.title);
    
    // Share immediately for now
    await _exportService.shareFile(pdfPath, doc.title);
  }

  Future<void> exportMultiplePdfs(List<String> documentIds) async {
    final List<String> paths = [];
    
    for (var id in documentIds) {
      final doc = _repository.getDocument(id);
      final pages = _repository.getPagesForDocument(id);
      
      if (doc != null && pages.isNotEmpty) {
        final imagePaths = pages.map((p) => p.imagePath).toList();
        final pdfPath = await _pdfService.generatePdf(imagePaths, doc.title);
        paths.add(pdfPath);
      }
    }

    if (paths.isNotEmpty) {
      await _exportService.shareMultipleFiles(paths, subject: 'Batch Export');
    }
  }

  Future<void> renameDocument(String documentId, String newTitle) async {
    final doc = _repository.getDocument(documentId);
    if (doc != null) {
      doc.title = newTitle;
      doc.updatedAt = DateTime.now();
      await doc.save();
    }
  }

  Future<void> mergeDocuments(List<String> documentIds) async {
    if (documentIds.length < 2) return;

    // Create new Merged Doc
    final now = DateTime.now();
    final newTitle = 'Merged ${now.hour}:${now.minute}';
    final newDoc = await _repository.createDocument(newTitle);

    for (var docId in documentIds) {
      final pages = _repository.getPagesForDocument(docId);
      for (var page in pages) {
        // We add pages to the new document (copying image paths)
        await _repository.addPageToDocument(newDoc.id, page.imagePath);
      }
    }
  }
}

final documentControllerProvider = Provider<DocumentController>((ref) {
  return DocumentController(
    ref.watch(documentRepositoryProvider),
    ref.watch(pdfServiceProvider),
    ref.watch(exportServiceProvider),
    ref.watch(cameraServiceProvider),
  );
});

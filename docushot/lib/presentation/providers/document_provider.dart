import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:docushot/data/models/document_model.dart';
import 'package:docushot/data/models/page_model.dart';
import 'package:docushot/data/repositories/document_repository.dart';
import 'package:docushot/data/services/pdf_service.dart';
import 'package:docushot/data/services/export_service.dart';
import 'package:docushot/data/services/scan_service.dart';
import 'package:docushot/data/services/ocr_service.dart';
import 'package:docushot/data/services/backup_service.dart';
import 'package:docushot/presentation/providers/settings_provider.dart';
import 'package:docushot/presentation/providers/premium_provider.dart';
import 'package:image_picker/image_picker.dart';

// --- Dependencies ---

final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('databaseProvider must be overridden at startup');
});

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DocumentRepository(db);
});

// --- State Providers ---

final documentListProvider = StreamProvider<List<DocumentModel>>((ref) async* {
  final repository = ref.watch(documentRepositoryProvider);

  yield await repository.getAllDocumentsAsync();

  await for (final _ in repository.changes) {
    yield await repository.getAllDocumentsAsync();
  }
});

final documentPagesProvider = StreamProvider.family<List<PageModel>, String>((ref, documentId) async* {
  final repository = ref.watch(documentRepositoryProvider);

  yield await repository.getPagesForDocumentAsync(documentId);

  await for (final _ in repository.changes) {
    yield await repository.getPagesForDocumentAsync(documentId);
  }
});

// --- Services Providers ---

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
final exportServiceProvider = Provider<ExportService>((ref) => ExportService());
final scanServiceProvider = Provider<ScanService>((ref) => ScanService());
final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(databaseProvider);
  return BackupService(db);
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  final settings = ref.watch(settingsProvider);
  final service = OcrService();
  service.setScript(OcrService.scriptFromName(settings.ocrLanguage));
  return service;
});

// --- Controller ---

class DocumentController {
  final DocumentRepository _repository;
  final PdfService _pdfService;
  final ExportService _exportService;
  final ScanService _scanService;
  final OcrService _ocrService;
  final PremiumNotifier _premium;

  DocumentController(
    this._repository,
    this._pdfService,
    this._exportService,
    this._scanService,
    this._ocrService,
    this._premium,
  );

  Future<DocumentModel> createDocument({List<dynamic>? initialImages}) async {
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

  Future<void> _processAndAddImages(String documentId, List<dynamic> images) async {
    for (var item in images) {
      if (item is String) {
        await _repository.addPageToDocument(documentId, item, originalImagePath: item);
      } else if (item is Map) {
        final path = item['path'] as String;
        final originalPath = item['originalPath'] as String?;
        final corners = item['corners'] as List<double>?;

        await _repository.addPageToDocument(
          documentId,
          path,
          originalImagePath: originalPath,
          cropCorners: corners,
        );
      }
    }
  }

  Future<void> addPagesToDocument(String documentId, List<dynamic> images) async {
    await _processAndAddImages(documentId, images);
  }

  Future<void> updatePageImage(String pageId, String newImagePath, {List<double>? cropCorners, int? filterType}) async {
    await _repository.updatePageImage(pageId, newImagePath, cropCorners: cropCorners, filterType: filterType);
  }

  /// Import images from gallery. Returns the number of images added.
  Future<int> importImagesFromGallery(String documentId) async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isEmpty) return 0;

    final paths = images.map((e) => e.path).toList();
    await addPagesToDocument(documentId, paths);
    return images.length;
  }

  Future<void> deletePage(String documentId, String pageId) async {
    await _repository.deletePage(documentId, pageId);
  }

  /// Run OCR on a page and save the recognized text.
  /// Throws [PremiumRequiredException] if daily OCR limit reached (free tier).
  Future<String> runOcr(String pageId) async {
    _premium.consumeOcr();
    final page = await _repository.getPageAsync(pageId);
    if (page == null) return '';
    final text = await _ocrService.recognizeText(page.imagePath);
    if (text.isNotEmpty) {
      await _repository.updatePageOcrText(pageId, text);
    }
    return text;
  }

  /// Run OCR on all pages of a document.
  /// Throws [PremiumRequiredException] if daily OCR limit reached (free tier).
  Future<void> runOcrForDocument(String documentId) async {
    final pages = await _repository.getPagesForDocumentAsync(documentId);
    for (var page in pages) {
      if (page.ocrText == null || page.ocrText!.isEmpty) {
        _premium.consumeOcr();
        final text = await _ocrService.recognizeText(page.imagePath);
        if (text.isNotEmpty) {
          await _repository.updatePageOcrText(page.id, text);
        }
      }
    }
  }

  Future<void> shareImages(List<String> imagePaths) async {
    await _exportService.shareMultipleFiles(imagePaths, subject: 'Shared Pages');
  }

  Future<void> reorderPages(String documentId, int oldIndex, int newIndex) async {
    await _repository.reorderPages(documentId, oldIndex, newIndex);
  }

  Future<void> exportPdf(String documentId, {List<String>? pageIds}) async {
    List<PageModel> pages = await _repository.getPagesForDocumentAsync(documentId);
    final doc = await _repository.getDocumentAsync(documentId);

    if (pages.isEmpty || doc == null) return;

    if (pageIds != null && pageIds.isNotEmpty) {
      pages = pages.where((p) => pageIds.contains(p.id)).toList();
    }

    final imagePaths = pages.map((p) => p.imagePath).toList();
    final pdfPath = await _pdfService.generatePdf(imagePaths, doc.title);

    await _exportService.shareFile(pdfPath, doc.title);
  }

  /// Throws [PremiumRequiredException] if not premium.
  Future<void> exportZip(String documentId) async {
    _premium.requirePremium('ZIP export');
    final pages = await _repository.getPagesForDocumentAsync(documentId);
    final doc = await _repository.getDocumentAsync(documentId);
    if (pages.isEmpty || doc == null) return;

    final imagePaths = pages.map((p) => p.imagePath).toList();
    await _exportService.shareAsZip(imagePaths, doc.title);
  }

  /// Throws [PremiumRequiredException] if not premium.
  Future<void> exportMultiplePdfs(List<String> documentIds) async {
    _premium.requirePremium('Batch export');
    final List<String> paths = [];

    for (var id in documentIds) {
      final doc = await _repository.getDocumentAsync(id);
      final pages = await _repository.getPagesForDocumentAsync(id);

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
    await _repository.renameDocument(documentId, newTitle);
  }

  /// Throws [PremiumRequiredException] if not premium.
  Future<void> mergeDocuments(List<String> documentIds) async {
    _premium.requirePremium('Merge');
    if (documentIds.length < 2) return;

    final now = DateTime.now();
    final newTitle = 'Merged ${now.hour}:${now.minute}';
    final newDoc = await _repository.createDocument(newTitle);

    for (var docId in documentIds) {
      final pages = await _repository.getPagesForDocumentAsync(docId);
      for (var page in pages) {
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
    ref.watch(scanServiceProvider),
    ref.watch(ocrServiceProvider),
    ref.read(premiumProvider.notifier),
  );
});

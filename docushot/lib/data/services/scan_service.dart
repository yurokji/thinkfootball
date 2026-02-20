import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

/// Unified scanning service wrapping Google ML Kit Document Scanner.
/// Replaces both CameraService and ScannerService.
class ScanService {
  /// Opens the native ML Kit Scanner UI.
  /// [pageLimit]: 0 = unlimited (batch), 1 = single page, N = max N pages.
  /// [isGalleryImport]: allow importing from gallery within the scanner.
  Future<List<String>> scanDocuments({
    int pageLimit = 0,
    bool isGalleryImport = false,
  }) async {
    try {
      final scanner = DocumentScanner(
        options: DocumentScannerOptions(
          mode: ScannerMode.full,
          pageLimit: pageLimit,
          isGalleryImport: isGalleryImport,
        ),
      );

      final result = await scanner.scanDocument();
      scanner.close();
      return result.images ?? [];
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') return [];
      debugPrint('Scanner failed: $e');
      return [];
    } catch (e) {
      debugPrint('Scanner error: $e');
      return [];
    }
  }
}

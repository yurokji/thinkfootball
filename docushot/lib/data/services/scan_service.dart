import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Unified scanning service wrapping Google ML Kit Document Scanner.
class ScanService {
  /// Opens the native ML Kit Scanner UI.
  /// [pageLimit]: max pages per session (must be >= 1). Default 100 for batch scanning.
  /// [isGalleryImport]: allow importing from gallery within the scanner.
  ///
  /// Throws on permission denial or scanner errors so the caller can display
  /// meaningful feedback to the user.
  Future<List<String>> scanDocuments({
    int pageLimit = 100,
    bool isGalleryImport = false,
  }) async {
    // Request camera permission at runtime (required on Android 6+)
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        throw Exception('Camera permission permanently denied. Please enable it in Settings.');
      }
      throw Exception('Camera permission denied');
    }

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
      debugPrint('Scanner PlatformException: $e');
      rethrow;
    }
  }
}

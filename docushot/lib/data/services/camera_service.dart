import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:flutter/services.dart';

class CameraService {
  Future<List<String>> scanDocument() async {
    try {
      final options = DocumentScannerOptions(
        mode: ScannerMode.full, // Filter, Crop, Edit handled by ML Kit
        pageLimit: 100,
      );

      final scanner = DocumentScanner(options: options);
      final result = await scanner.scanDocument();
      scanner.close();

      return result.images ?? [];
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        return [];
      } else {
        throw e;
      }
    }
  }
}

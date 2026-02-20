import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ExportService {
  Future<void> shareFile(String filePath, String title) async {
    await shareMultipleFiles([filePath], subject: title);
  }

  Future<void> shareMultipleFiles(List<String> filePaths, {String? subject}) async {
    try {
      final xfiles = filePaths.map((path) => XFile(path)).toList();
      await Share.shareXFiles(xfiles, subject: subject);
    } catch (e) {
      debugPrint('Sharing failed: $e');
    }
  }

  /// Create a zip file from image paths and share it.
  Future<void> shareAsZip(List<String> imagePaths, String documentTitle) async {
    try {
      final archive = Archive();
      for (var i = 0; i < imagePaths.length; i++) {
        final file = File(imagePaths[i]);
        if (!file.existsSync()) continue;
        final bytes = await file.readAsBytes();
        final ext = imagePaths[i].split('.').last;
        archive.addFile(ArchiveFile(
          'page_${i + 1}.$ext',
          bytes.length,
          bytes,
        ));
      }

      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) return;

      final dir = await getTemporaryDirectory();
      final safeName = documentTitle.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final ts = DateTime.now().millisecondsSinceEpoch;
      final zipPath = '${dir.path}/${safeName}_$ts.zip';
      await File(zipPath).writeAsBytes(zipData);

      await shareFile(zipPath, documentTitle);
    } catch (e) {
      debugPrint('Zip export failed: $e');
    }
  }

  Future<void> saveToGallery(String imagePath) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // await Gal.putImage(imagePath);
    } else {
      debugPrint('Save to gallery not supported on this platform');
    }
  }
}

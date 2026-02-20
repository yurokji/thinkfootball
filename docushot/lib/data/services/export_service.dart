import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
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

  Future<void> saveToGallery(String imagePath) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // await Gal.putImage(imagePath);
    } else {
      debugPrint('Save to gallery not supported on this platform');
    }
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:docushot/data/models/document_model.dart';
import 'package:docushot/data/models/page_model.dart';
import 'dart:convert';

/// Backup/restore service for document data and images.
class BackupService {
  final Box<DocumentModel> _docBox;
  final Box<PageModel> _pageBox;

  BackupService(this._docBox, this._pageBox);

  /// Create a backup zip containing all documents, pages metadata, and images.
  /// Returns the path to the created backup file.
  Future<String?> createBackup({void Function(double progress)? onProgress}) async {
    try {
      final archive = Archive();
      final docs = _docBox.values.toList();
      final pages = _pageBox.values.toList();
      final totalItems = docs.length + pages.length;
      int processed = 0;

      // 1. Serialize document metadata as JSON
      final docsJson = docs.map((d) => {
        'id': d.id,
        'title': d.title,
        'createdAt': d.createdAt.toIso8601String(),
        'updatedAt': d.updatedAt.toIso8601String(),
        'thumbnailPath': d.thumbnailPath,
        'pageIds': d.pageIds,
      }).toList();

      final docsBytes = utf8.encode(jsonEncode(docsJson));
      archive.addFile(ArchiveFile('metadata/documents.json', docsBytes.length, docsBytes));

      // 2. Serialize page metadata as JSON
      final pagesJson = pages.map((p) => {
        'id': p.id,
        'documentId': p.documentId,
        'imagePath': p.imagePath,
        'originalImagePath': p.originalImagePath,
        'ocrText': p.ocrText,
        'orderIndex': p.orderIndex,
        'cropCorners': p.cropCorners,
        'filterType': p.filterType,
      }).toList();

      final pagesBytes = utf8.encode(jsonEncode(pagesJson));
      archive.addFile(ArchiveFile('metadata/pages.json', pagesBytes.length, pagesBytes));

      // 3. Add image files
      final addedPaths = <String>{};
      for (var page in pages) {
        for (var path in [page.imagePath, page.originalImagePath]) {
          if (path != null && !addedPaths.contains(path)) {
            final file = File(path);
            if (file.existsSync()) {
              final bytes = await file.readAsBytes();
              final fileName = path.split('/').last;
              archive.addFile(ArchiveFile('images/$fileName', bytes.length, bytes));
              addedPaths.add(path);
            }
          }
        }
        processed++;
        onProgress?.call(processed / totalItems);
      }

      // 4. Encode and save
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${dir.path}/docushot_backup_$ts.zip';
      await File(backupPath).writeAsBytes(zipData);

      debugPrint('Backup created: $backupPath (${(zipData.length / 1024 / 1024).toStringAsFixed(1)} MB)');
      return backupPath;
    } catch (e) {
      debugPrint('Backup error: $e');
      return null;
    }
  }

  /// Restore from a backup zip file.
  /// Returns true on success.
  Future<bool> restoreBackup(String backupPath, {void Function(double progress)? onProgress}) async {
    try {
      final file = File(backupPath);
      if (!file.existsSync()) return false;

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // 1. Find and parse metadata
      final docsFile = archive.findFile('metadata/documents.json');
      final pagesFile = archive.findFile('metadata/pages.json');
      if (docsFile == null || pagesFile == null) return false;

      final docsJson = jsonDecode(utf8.decode(docsFile.content)) as List;
      final pagesJson = jsonDecode(utf8.decode(pagesFile.content)) as List;

      final totalItems = docsJson.length + pagesJson.length;
      int processed = 0;

      // 2. Restore images to app documents directory
      final dir = await getApplicationDocumentsDirectory();
      final imageFiles = archive.files.where((f) => f.name.startsWith('images/'));
      final pathMap = <String, String>{}; // old filename -> new path

      for (var imgFile in imageFiles) {
        final fileName = imgFile.name.split('/').last;
        final newPath = '${dir.path}/$fileName';
        await File(newPath).writeAsBytes(imgFile.content);
        pathMap[fileName] = newPath;
      }

      // 3. Restore documents
      for (var docData in docsJson) {
        final existing = _docBox.values.where((d) => d.id == docData['id']).firstOrNull;
        if (existing != null) continue; // Skip duplicates

        final doc = DocumentModel(
          id: docData['id'],
          title: docData['title'],
          createdAt: DateTime.parse(docData['createdAt']),
          updatedAt: DateTime.parse(docData['updatedAt']),
          thumbnailPath: _resolveImagePath(docData['thumbnailPath'], pathMap, dir.path),
          pageIds: List<String>.from(docData['pageIds'] ?? []),
        );
        await _docBox.add(doc);
        processed++;
        onProgress?.call(processed / totalItems);
      }

      // 4. Restore pages
      for (var pageData in pagesJson) {
        final existing = _pageBox.values.where((p) => p.id == pageData['id']).firstOrNull;
        if (existing != null) continue; // Skip duplicates

        final page = PageModel(
          id: pageData['id'],
          documentId: pageData['documentId'],
          imagePath: _resolveImagePath(pageData['imagePath'], pathMap, dir.path)!,
          originalImagePath: _resolveImagePath(pageData['originalImagePath'], pathMap, dir.path),
          ocrText: pageData['ocrText'],
          orderIndex: pageData['orderIndex'] ?? 0,
          cropCorners: pageData['cropCorners'] != null ? List<double>.from(pageData['cropCorners']) : null,
          filterType: pageData['filterType'] ?? 0,
        );
        await _pageBox.add(page);
        processed++;
        onProgress?.call(processed / totalItems);
      }

      debugPrint('Backup restored: ${docsJson.length} docs, ${pagesJson.length} pages');
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  String? _resolveImagePath(String? originalPath, Map<String, String> pathMap, String appDir) {
    if (originalPath == null) return null;
    final fileName = originalPath.split('/').last;
    return pathMap[fileName] ?? '$appDir/$fileName';
  }

  /// List available local backups.
  Future<List<FileSystemEntity>> listLocalBackups() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().where((f) => f.path.contains('docushot_backup_') && f.path.endsWith('.zip')).toList();
    files.sort((a, b) => b.path.compareTo(a.path)); // newest first
    return files;
  }
}

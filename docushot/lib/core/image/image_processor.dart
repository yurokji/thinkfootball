import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:docushot/core/models/scan_result.dart';

enum FilterType {
  original,
  magicPro, // Auto-contrast / sharpen
  grayscale, // B/W
  lighten, // Brightness boost
}

class ImageProcessor {
  
  // Apply filter to a file and return path to new file
  // Type: 0=Original, 1=Magic, 2=B/W, 3=Lighten
  static Future<String> applyFilter(String path, int type) async {
    if (type == 0) return path;

    final bytes = await File(path).readAsBytes();
    img.Image? original = img.decodeImage(bytes);

    if (original == null) return path;

    img.Image processed = original;

    switch (type) {
      case 1: // Magic Color
        // High contrast + Saturation to simulate scanner
        processed = img.adjustColor(processed, contrast: 1.3, saturation: 1.4, brightness: 1.1);
        // processed = img.emboss(processed); // Optional sharpening
        break;
      case 2: // B/W
        processed = img.grayscale(processed);
        processed = img.adjustColor(processed, contrast: 1.5, brightness: 1.1);
        break;
      case 3: // Lighten
         processed = img.adjustColor(processed, brightness: 1.3);
        break;
      default:
        break;
    }

    // Creates unique file for filter result (timestamp prevents overwrite conflicts)
    final ts = DateTime.now().millisecondsSinceEpoch;
    final String newPath = path.replaceAll('.jpg', '_filter${type}_$ts.jpg');
    final encoded = img.encodeJpg(processed, quality: 90);
    await File(newPath).writeAsBytes(encoded);
    
    return newPath;
  }

  /// Apply filter to all ScanResults in batch, updating each result's path.
  static Future<void> applyFilterToAll(List<ScanResult> results, int filterType) async {
    for (var result in results) {
      final newPath = await applyFilter(result.path, filterType);
      result.path = newPath;
      result.filterType = filterType;
    }
  }

  // Perspective Crop
  static Future<String> perspectiveCrop(String path, List<img.Point> corners) async {
    final bytes = await File(path).readAsBytes();
    img.Image? original = img.decodeImage(bytes);

    if (original == null || corners.length != 4) return path;

    // copyRectify(src, topLeft: ..., topRight: ..., bottomLeft: ..., bottomRight: ...)
    // corners order: TL, TR, BR, BL (based on standard UI flow)
    final warped = img.copyRectify(
      original,
      topLeft: corners[0],
      topRight: corners[1],
      bottomRight: corners[2], 
      bottomLeft: corners[3],
    );

    final String newPath = path.replaceAll('.jpg', '_crop.jpg');
    final encoded = img.encodeJpg(warped, quality: 90);
    await File(newPath).writeAsBytes(encoded);

    return newPath;
  }
}

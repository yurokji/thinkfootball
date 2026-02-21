import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

enum FilterType {
  original,
  magicPro, // Auto-contrast / sharpen
  grayscale, // B/W
  lighten, // Brightness boost
}

// --- Top-level functions for Isolate execution ---

String _applyFilterIsolate(Map<String, dynamic> params) {
  final bytes = params['bytes'] as List<int>;
  final type = params['type'] as int;
  final outputPath = params['outputPath'] as String;

  img.Image? original = img.decodeImage(Uint8List.fromList(bytes));
  if (original == null) return params['inputPath'] as String;

  img.Image processed = original;

  switch (type) {
    case 1: // Magic Color
      processed = img.adjustColor(processed, contrast: 1.3, saturation: 1.4, brightness: 1.1);
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

  final encoded = img.encodeJpg(processed, quality: 90);
  File(outputPath).writeAsBytesSync(encoded);
  return outputPath;
}

String _applyAdjustmentsIsolate(Map<String, dynamic> params) {
  final bytes = params['bytes'] as List<int>;
  final brightness = params['brightness'] as double;
  final contrast = params['contrast'] as double;
  final outputPath = params['outputPath'] as String;

  img.Image? original = img.decodeImage(Uint8List.fromList(bytes));
  if (original == null) return params['inputPath'] as String;

  img.Image processed = img.adjustColor(original, brightness: brightness, contrast: contrast);

  final encoded = img.encodeJpg(processed, quality: 90);
  File(outputPath).writeAsBytesSync(encoded);
  return outputPath;
}

String _perspectiveCropIsolate(Map<String, dynamic> params) {
  final bytes = params['bytes'] as List<int>;
  final cornerCoords = params['corners'] as List<double>; // [x1,y1, x2,y2, x3,y3, x4,y4]
  final outputPath = params['outputPath'] as String;

  img.Image? original = img.decodeImage(Uint8List.fromList(bytes));
  if (original == null || cornerCoords.length != 8) return params['inputPath'] as String;

  final corners = [
    img.Point(cornerCoords[0], cornerCoords[1]),
    img.Point(cornerCoords[2], cornerCoords[3]),
    img.Point(cornerCoords[4], cornerCoords[5]),
    img.Point(cornerCoords[6], cornerCoords[7]),
  ];

  final warped = img.copyRectify(
    original,
    topLeft: corners[0],
    topRight: corners[1],
    bottomRight: corners[2],
    bottomLeft: corners[3],
  );

  final encoded = img.encodeJpg(warped, quality: 90);
  File(outputPath).writeAsBytesSync(encoded);
  return outputPath;
}

// --- Public API ---

class ImageProcessor {

  // Apply filter to a file and return path to new file
  // Type: 0=Original, 1=Magic, 2=B/W, 3=Lighten
  static Future<String> applyFilter(String path, int type) async {
    if (type == 0) return path;

    final bytes = await File(path).readAsBytes();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final String outputPath = path.replaceAll('.jpg', '_filter${type}_$ts.jpg');

    return compute(_applyFilterIsolate, {
      'bytes': bytes,
      'type': type,
      'inputPath': path,
      'outputPath': outputPath,
    });
  }

  /// Apply custom brightness and contrast adjustments.
  static Future<String> applyAdjustments(String path, {double brightness = 1.0, double contrast = 1.0}) async {
    final bytes = await File(path).readAsBytes();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final String outputPath = path.replaceAll('.jpg', '_adj_$ts.jpg');

    return compute(_applyAdjustmentsIsolate, {
      'bytes': bytes,
      'brightness': brightness,
      'contrast': contrast,
      'inputPath': path,
      'outputPath': outputPath,
    });
  }


  // Perspective Crop
  static Future<String> perspectiveCrop(String path, List<img.Point> corners) async {
    if (corners.length != 4) return path;

    final bytes = await File(path).readAsBytes();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final String outputPath = path.replaceAll('.jpg', '_crop_$ts.jpg');

    // Flatten corners to List<double> for isolate serialization
    final cornerCoords = <double>[];
    for (var c in corners) {
      cornerCoords.add(c.x.toDouble());
      cornerCoords.add(c.y.toDouble());
    }

    return compute(_perspectiveCropIsolate, {
      'bytes': bytes,
      'corners': cornerCoords,
      'inputPath': path,
      'outputPath': outputPath,
    });
  }
}

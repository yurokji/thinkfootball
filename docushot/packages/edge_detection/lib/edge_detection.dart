import 'dart:async';

import 'dart:ui';
import 'package:flutter/services.dart';

class EdgeDetection {
  static const MethodChannel _channel = const MethodChannel('edge_detection');

  /// Call this method to scan the object edge in live camera.
  static Future<bool> detectEdge(String saveTo,
      {
        bool canUseGallery = true,
        String androidScanTitle = "Scanning",
        String androidCropTitle = "Crop",
        String androidCropBlackWhiteTitle = "Black White",
        String androidCropReset = "Reset",
      }) async {
    return await _channel.invokeMethod('edge_detect', {
      'save_to': saveTo,
      'can_use_gallery': canUseGallery,
      'scan_title': androidScanTitle,
      'crop_title': androidCropTitle,
      'crop_black_white_title': androidCropBlackWhiteTitle,
      'crop_reset_title': androidCropReset,
    });
  }

  /// Call this method to scan the object edge from a gallery image.
  static Future<bool> detectEdgeFromGallery(String saveTo,
      {
        String androidCropTitle = "Crop",
        String androidCropBlackWhiteTitle = "Black White",
        String androidCropReset = "Reset",
      }) async {
    return await _channel.invokeMethod('edge_detect_gallery', {
      'save_to': saveTo,
      'crop_title': androidCropTitle,
      'crop_black_white_title': androidCropBlackWhiteTitle,
      'crop_reset_title': androidCropReset,
      'from_gallery': true,
    });
  }

  /// Call this method to scan the object edge from a file path without UI.
  /// Returns a list of 4 Offsets (TopLeft, TopRight, BottomRight, BottomLeft) or null if not found.
  static Future<List<Offset>?> detectEdgesNoUI(String filePath) async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('detect_edges_file', {
        'save_to': filePath, // Reusing existing key convention just in case
      });

      if (result != null && result.length == 4) {
         List<Offset> corners = [];
         for (var point in result) {
            final Map<dynamic, dynamic> p = point;
            corners.add(Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble()));
         }
         return corners;
      }
    } catch (e) {
      print('EdgeDetection Error: $e');
    }
    return null;
  }
}

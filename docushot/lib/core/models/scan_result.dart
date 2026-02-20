/// Type-safe model for passing image data through the scan pipeline.
/// Replaces Map<String, dynamic> usage throughout camera/crop/enhance flow.
class ScanResult {
  /// Path to the currently displayed image (may be cropped/filtered)
  String path;

  /// Path to the original raw captured image (never modified)
  final String originalPath;

  /// Normalized crop corners [x1,y1, x2,y2, x3,y3, x4,y4] in 0.0-1.0 range
  List<double>? corners;

  /// Applied filter type: 0=Original, 1=Magic, 2=B/W, 3=Lighten
  int filterType;

  ScanResult({
    required this.path,
    required this.originalPath,
    this.corners,
    this.filterType = 0,
  });

  /// Convert to Map for backward compatibility with existing code
  Map<String, dynamic> toMap() => {
        'path': path,
        'originalPath': originalPath,
        'corners': corners,
        'filterType': filterType,
      };

  /// Create from Map for backward compatibility
  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      path: map['path'] as String,
      originalPath: (map['originalPath'] as String?) ?? map['path'] as String,
      corners: map['corners'] as List<double>?,
      filterType: (map['filterType'] as int?) ?? 0,
    );
  }
}

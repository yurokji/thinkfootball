/// Document type enumeration and configuration.
/// Each type influences crop aspect ratio, edge detection sensitivity,
/// and recommended filters.
enum DocumentType {
  document,
  book,
  idCard,
}

/// Configuration for each document type, controlling scan behavior.
class DocumentTypeConfig {
  /// Display label for UI
  final String label;

  /// Expected aspect ratio (width / height). Null = free-form.
  final double? aspectRatio;

  /// Minimum contour area threshold for edge detection (higher = stricter)
  final double edgeMinArea;

  /// Recommended default filter index: 0=Original, 1=Magic, 2=B/W, 3=Lighten
  final int defaultFilter;

  /// Crop margin padding (0.0 = tight, 0.05 = 5% padding)
  final double cropPadding;

  const DocumentTypeConfig({
    required this.label,
    this.aspectRatio,
    this.edgeMinArea = 10000,
    this.defaultFilter = 1,
    this.cropPadding = 0.02,
  });
}

/// Get config for a given document type
DocumentTypeConfig getDocTypeConfig(DocumentType type) {
  switch (type) {
    case DocumentType.document:
      return const DocumentTypeConfig(
        label: 'Document',
        aspectRatio: 0.707, // A4 ratio (210/297)
        edgeMinArea: 10000,
        defaultFilter: 1, // Magic Color
        cropPadding: 0.02,
      );
    case DocumentType.book:
      return const DocumentTypeConfig(
        label: 'Book',
        aspectRatio: null, // Free-form (books vary)
        edgeMinArea: 8000, // More lenient for book pages
        defaultFilter: 3, // Lighten (better for book pages)
        cropPadding: 0.03,
      );
    case DocumentType.idCard:
      return const DocumentTypeConfig(
        label: 'ID Card',
        aspectRatio: 1.586, // ISO/IEC 7810 ID-1 (85.6/54)
        edgeMinArea: 5000, // Small objects need lower threshold
        defaultFilter: 1, // Magic Color
        cropPadding: 0.01, // Tight crop
      );
  }
}

/// Convert int index to DocumentType
DocumentType docTypeFromIndex(int index) {
  switch (index) {
    case 1:
      return DocumentType.book;
    case 2:
      return DocumentType.idCard;
    default:
      return DocumentType.document;
  }
}

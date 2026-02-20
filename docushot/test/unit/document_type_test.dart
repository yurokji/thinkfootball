import 'package:flutter_test/flutter_test.dart';
import 'package:docushot/core/models/document_type.dart';

void main() {
  group('DocumentType', () {
    test('docTypeFromIndex returns correct type', () {
      expect(docTypeFromIndex(0), DocumentType.document);
      expect(docTypeFromIndex(1), DocumentType.book);
      expect(docTypeFromIndex(2), DocumentType.idCard);
      expect(docTypeFromIndex(99), DocumentType.document); // out of range
    });

    test('getDocTypeConfig returns correct config for document', () {
      final config = getDocTypeConfig(DocumentType.document);
      expect(config.aspectRatio, closeTo(0.707, 0.001));
      expect(config.defaultFilter, 1); // Magic Color
      expect(config.edgeMinArea, 0.2);
    });

    test('getDocTypeConfig returns correct config for book', () {
      final config = getDocTypeConfig(DocumentType.book);
      expect(config.aspectRatio, isNull); // free-form
      expect(config.defaultFilter, 3); // Lighten
      expect(config.edgeMinArea, 0.15);
    });

    test('getDocTypeConfig returns correct config for idCard', () {
      final config = getDocTypeConfig(DocumentType.idCard);
      expect(config.aspectRatio, closeTo(1.586, 0.001));
      expect(config.defaultFilter, 1); // Magic Color
      expect(config.cropPadding, 2.0);
    });
  });

  group('DocumentTypeConfig', () {
    test('has correct fields', () {
      const config = DocumentTypeConfig(
        aspectRatio: 1.5,
        edgeMinArea: 0.3,
        defaultFilter: 2,
        cropPadding: 5.0,
      );
      expect(config.aspectRatio, 1.5);
      expect(config.edgeMinArea, 0.3);
      expect(config.defaultFilter, 2);
      expect(config.cropPadding, 5.0);
    });
  });
}

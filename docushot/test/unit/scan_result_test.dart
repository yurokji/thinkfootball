import 'package:flutter_test/flutter_test.dart';
import 'package:docushot/core/models/scan_result.dart';

void main() {
  group('ScanResult', () {
    test('creates with required fields', () {
      final result = ScanResult(path: '/test/image.jpg', originalPath: '/test/original.jpg');
      expect(result.path, '/test/image.jpg');
      expect(result.originalPath, '/test/original.jpg');
      expect(result.corners, isNull);
      expect(result.filterType, 0);
    });

    test('toMap returns correct map', () {
      final result = ScanResult(
        path: '/test/image.jpg',
        originalPath: '/test/original.jpg',
        corners: [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8],
        filterType: 2,
      );

      final map = result.toMap();
      expect(map['path'], '/test/image.jpg');
      expect(map['originalPath'], '/test/original.jpg');
      expect(map['corners'], hasLength(8));
      expect(map['filterType'], 2);
    });

    test('fromMap creates correct instance', () {
      final map = {
        'path': '/test/image.jpg',
        'originalPath': '/test/original.jpg',
        'corners': [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8],
        'filterType': 1,
      };

      final result = ScanResult.fromMap(map);
      expect(result.path, '/test/image.jpg');
      expect(result.originalPath, '/test/original.jpg');
      expect(result.corners, hasLength(8));
      expect(result.filterType, 1);
    });

    test('fromMap handles null corners', () {
      final map = {
        'path': '/test/image.jpg',
        'originalPath': '/test/original.jpg',
      };

      final result = ScanResult.fromMap(map);
      expect(result.corners, isNull);
      expect(result.filterType, 0);
    });

    test('path is mutable', () {
      final result = ScanResult(path: '/old.jpg', originalPath: '/orig.jpg');
      result.path = '/new.jpg';
      expect(result.path, '/new.jpg');
    });
  });
}

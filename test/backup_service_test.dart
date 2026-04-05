import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:replay/core/database/database.dart';
import 'package:replay/core/services/backup_service.dart';

void main() {
  late BackupService backupService;

  setUp(() {
    backupService = BackupService();
  });

  group('exportToJson', () {
    test('produces valid JSON with correct structure', () {
      final toys = [
        Toy(
          id: 1, name: 'Buzz Lightyear', description: 'Space ranger',
          imagePath: '/img/1.jpg', thumbnailPath: null, category: 'Action Figures',
          aiLabels: '["action figure"]', createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 1, 15), condition: 'excellent',
          location: 'Bedroom', status: 'active', owner: 'Jake',
        ),
      ];

      final json = backupService.exportToJson(toys);
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['version'], 1);
      expect(decoded['exportedAt'], isNotNull);
      expect(decoded['toys'], isList);
      expect((decoded['toys'] as List).length, 1);

      final toy = (decoded['toys'] as List).first as Map<String, dynamic>;
      expect(toy['name'], 'Buzz Lightyear');
      expect(toy['category'], 'Action Figures');
      expect(toy['owner'], 'Jake');
      expect(toy.containsKey('imagePath'), false);
      expect(toy.containsKey('id'), false);
    });
  });

  group('parseImport', () {
    test('parses valid JSON and returns toy data', () {
      final json = jsonEncode({
        'version': 1,
        'exportedAt': '2026-04-03T12:00:00Z',
        'toys': [
          {
            'name': 'Teddy Bear',
            'category': 'Stuffed Animals',
            'condition': 'good',
            'status': 'active',
            'createdAt': '2026-01-14T00:00:00.000',
          },
        ],
      });

      final result = backupService.parseImport(json);

      expect(result.length, 1);
      expect(result.first['name'], 'Teddy Bear');
    });

    test('handles missing optional fields', () {
      final json = jsonEncode({
        'version': 1,
        'toys': [
          {'name': 'Simple Toy', 'createdAt': '2026-01-01T00:00:00.000'},
        ],
      });

      final result = backupService.parseImport(json);

      expect(result.length, 1);
      expect(result.first['name'], 'Simple Toy');
      expect(result.first['category'], 'Other');
    });

    test('throws on invalid version', () {
      final json = jsonEncode({'version': 999, 'toys': []});

      expect(() => backupService.parseImport(json), throwsException);
    });
  });

  group('filterDuplicates', () {
    test('identifies duplicates by name and createdAt', () {
      final existing = [
        Toy(
          id: 1, name: 'Buzz', description: null, imagePath: '',
          thumbnailPath: null, category: 'Other', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 15), updatedAt: DateTime(2026, 1, 15),
          condition: 'good', location: null, status: 'active', owner: null,
        ),
      ];

      final incoming = [
        {'name': 'Buzz', 'createdAt': '2026-01-15T00:00:00.000'},
        {'name': 'New Toy', 'createdAt': '2026-02-01T00:00:00.000'},
      ];

      final nonDuplicates = backupService.filterDuplicates(incoming, existing);

      expect(nonDuplicates.length, 1);
      expect(nonDuplicates.first['name'], 'New Toy');
    });
  });
}

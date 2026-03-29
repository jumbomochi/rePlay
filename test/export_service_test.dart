import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replay/core/database/database.dart';
import 'package:replay/core/services/export_service.dart';

void main() {
  late ExportService exportService;

  setUp(() {
    exportService = ExportService();
  });

  group('generateTextList', () {
    test('produces correct format with filter label and toy data', () {
      final toys = [
        Toy(
          id: 1, name: 'Buzz Lightyear', description: null, imagePath: '',
          thumbnailPath: null, category: 'Action Figures', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 15), updatedAt: DateTime(2026, 1, 15),
          condition: 'excellent', location: 'Bedroom', status: 'active',
        ),
        Toy(
          id: 2, name: 'Teddy Bear', description: null, imagePath: '',
          thumbnailPath: null, category: 'Stuffed Animals', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 14), updatedAt: DateTime(2026, 1, 14),
          condition: 'fair', location: 'Playroom', status: 'toDonate',
        ),
      ];

      final result = exportService.generateTextList(toys, 'All');

      expect(result, contains('rePlay Toy List'));
      expect(result, contains('All'));
      expect(result, contains('2 toys'));
      expect(result, contains('1. Buzz Lightyear'));
      expect(result, contains('Excellent'));
      expect(result, contains('Bedroom'));
      expect(result, contains('2. Teddy Bear'));
    });

    test('handles toys with null location', () {
      final toys = [
        Toy(
          id: 1, name: 'Puzzle', description: null, imagePath: '',
          thumbnailPath: null, category: 'Puzzles', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 15), updatedAt: DateTime(2026, 1, 15),
          condition: 'good', location: null, status: 'active',
        ),
      ];

      final result = exportService.generateTextList(toys, 'Active');

      expect(result, contains('1. Puzzle'));
      expect(result, contains('Good'));
      expect(result, isNot(contains('null')));
    });
  });

  group('generateCsvContent', () {
    test('produces valid CSV with headers and data', () {
      final toys = [
        Toy(
          id: 1, name: 'Buzz Lightyear', description: null, imagePath: '',
          thumbnailPath: null, category: 'Action Figures', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 15), updatedAt: DateTime(2026, 1, 15),
          condition: 'excellent', location: 'Bedroom', status: 'active',
        ),
      ];

      final result = exportService.generateCsvContent(toys);
      final lines = result.split('\n');

      expect(lines[0], 'Name,Category,Condition,Location,Status,Date Added');
      expect(lines[1], contains('Buzz Lightyear'));
      expect(lines[1], contains('Action Figures'));
      expect(lines[1], contains('Excellent'));
      expect(lines[1], contains('Bedroom'));
      expect(lines[1], contains('Active'));
      expect(lines[1], contains('2026-01-15'));
    });

    test('quotes values containing commas', () {
      final toys = [
        Toy(
          id: 1, name: 'LEGO Set, Large', description: null, imagePath: '',
          thumbnailPath: null, category: 'Building Blocks', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 15), updatedAt: DateTime(2026, 1, 15),
          condition: 'good', location: 'Shelf 1, Room 2', status: 'active',
        ),
      ];

      final result = exportService.generateCsvContent(toys);

      expect(result, contains('"LEGO Set, Large"'));
      expect(result, contains('"Shelf 1, Room 2"'));
    });

    test('handles null location in CSV', () {
      final toys = [
        Toy(
          id: 1, name: 'Ball', description: null, imagePath: '',
          thumbnailPath: null, category: 'Outdoor', aiLabels: '[]',
          createdAt: DateTime(2026, 3, 1), updatedAt: DateTime(2026, 3, 1),
          condition: 'fair', location: null, status: 'active',
        ),
      ];

      final result = exportService.generateCsvContent(toys);
      final lines = result.split('\n');

      expect(lines[1], isNot(contains('null')));
      expect(lines[1], contains('Ball,Outdoor,Fair,,Active'));
    });
  });

  group('writeCsvFile', () {
    test('writes CSV to temp file and returns path', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock path_provider to return the system temp directory.
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'getTemporaryDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      });

      final toys = [
        Toy(
          id: 1, name: 'Test Toy', description: null, imagePath: '',
          thumbnailPath: null, category: 'Other', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1),
          condition: 'good', location: null, status: 'active',
        ),
      ];

      final path = await exportService.writeCsvFile(toys);

      expect(path, endsWith('.csv'));
      final file = File(path);
      expect(await file.exists(), true);
      final content = await file.readAsString();
      expect(content, contains('Test Toy'));

      await file.delete();
    });
  });
}

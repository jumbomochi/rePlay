import 'package:flutter_test/flutter_test.dart';

import 'package:replay/core/services/vision_identification_service.dart';

void main() {
  group('ToyIdentification.fromJson', () {
    test('parses valid JSON correctly', () {
      final json = {
        'name': 'Buzz Lightyear',
        'category': 'Action Figures',
        'description': 'Space ranger action figure from Toy Story',
      };

      final result = ToyIdentification.fromJson(json);

      expect(result.name, 'Buzz Lightyear');
      expect(result.category, 'Action Figures');
      expect(result.description, 'Space ranger action figure from Toy Story');
    });

    test('handles missing fields with defaults', () {
      final json = <String, dynamic>{
        'name': 'Some Toy',
      };

      final result = ToyIdentification.fromJson(json);

      expect(result.name, 'Some Toy');
      expect(result.category, 'Other');
      expect(result.description, '');
    });

    test('unrecognized category defaults to Other', () {
      final json = {
        'name': 'Fidget Spinner',
        'category': 'Gadgets',
        'description': 'A spinning toy',
      };

      final result = ToyIdentification.fromJson(json);

      expect(result.category, 'Other');
    });

    test('tryParseResponse handles valid JSON string', () {
      const response = '{"name": "LEGO Set", "category": "Building Blocks", "description": "A building set"}';

      final result = ToyIdentification.tryParseResponse(response);

      expect(result.name, 'LEGO Set');
      expect(result.category, 'Building Blocks');
    });

    test('tryParseResponse handles JSON with markdown code block', () {
      const response = '```json\n{"name": "LEGO Set", "category": "Building Blocks", "description": "A building set"}\n```';

      final result = ToyIdentification.tryParseResponse(response);

      expect(result.name, 'LEGO Set');
      expect(result.category, 'Building Blocks');
    });

    test('tryParseResponse falls back to raw text on invalid JSON', () {
      const response = 'This is a Buzz Lightyear action figure';

      final result = ToyIdentification.tryParseResponse(response);

      expect(result.name, 'This is a Buzz Lightyear action figure');
      expect(result.category, 'Other');
      expect(result.description, '');
    });
  });
}

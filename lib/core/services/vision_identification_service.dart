import 'dart:convert';
import 'dart:io';

import '../constants/app_constants.dart';

class ToyIdentification {
  final String name;
  final String category;
  final String description;

  const ToyIdentification({
    required this.name,
    required this.category,
    required this.description,
  });

  factory ToyIdentification.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Unknown Toy';
    final rawCategory = json['category'] as String? ?? 'Other';
    final description = json['description'] as String? ?? '';

    final validCategories = AppConstants.categoryIcons.keys.toSet();
    final category = validCategories.contains(rawCategory) ? rawCategory : 'Other';

    return ToyIdentification(
      name: name,
      category: category,
      description: description,
    );
  }

  static ToyIdentification tryParseResponse(String response) {
    var jsonStr = response.trim();

    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr
          .replaceFirst(RegExp(r'^```json?\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '');
    }

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ToyIdentification.fromJson(json);
    } catch (_) {
      return ToyIdentification(
        name: response.trim(),
        category: 'Other',
        description: '',
      );
    }
  }
}

abstract class VisionIdentificationService {
  Future<ToyIdentification> identifyToy(File imageFile);
}

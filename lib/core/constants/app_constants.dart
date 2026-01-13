import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'rePlay';
  static const String appDescription = 'Toy Organizer for Families';

  // Default categories with their icons
  static const Map<String, IconData> categoryIcons = {
    'Action Figures': Icons.sports_martial_arts,
    'Dolls': Icons.face,
    'Building Blocks': Icons.view_in_ar,
    'Vehicles': Icons.directions_car,
    'Puzzles': Icons.extension,
    'Board Games': Icons.casino,
    'Stuffed Animals': Icons.pets,
    'Educational': Icons.school,
    'Outdoor': Icons.park,
    'Other': Icons.category,
  };

  static IconData getCategoryIcon(String categoryName) {
    return categoryIcons[categoryName] ?? Icons.category;
  }
}

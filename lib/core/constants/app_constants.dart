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

  // Toy condition values
  static const List<String> conditions = [
    'excellent',
    'good',
    'fair',
    'poor',
    'broken',
  ];

  static const Map<String, IconData> conditionIcons = {
    'excellent': Icons.star,
    'good': Icons.thumb_up,
    'fair': Icons.thumbs_up_down,
    'poor': Icons.thumb_down,
    'broken': Icons.build,
  };

  static const Map<String, String> conditionLabels = {
    'excellent': 'Excellent',
    'good': 'Good',
    'fair': 'Fair',
    'poor': 'Poor',
    'broken': 'Broken',
  };

  // Toy lifecycle status values
  static const List<String> statuses = [
    'active',
    'inStorage',
    'toDonate',
    'toSell',
    'toHandDown',
  ];

  static const Map<String, IconData> statusIcons = {
    'active': Icons.play_arrow,
    'inStorage': Icons.inventory_2,
    'toDonate': Icons.volunteer_activism,
    'toSell': Icons.attach_money,
    'toHandDown': Icons.card_giftcard,
  };

  static const Map<String, String> statusLabels = {
    'active': 'Active',
    'inStorage': 'In Storage',
    'toDonate': 'To Donate',
    'toSell': 'To Sell',
    'toHandDown': 'Hand Down',
  };

  static IconData getConditionIcon(String condition) {
    return conditionIcons[condition] ?? Icons.help_outline;
  }

  static IconData getStatusIcon(String status) {
    return statusIcons[status] ?? Icons.help_outline;
  }

  static String getConditionLabel(String condition) {
    return conditionLabels[condition] ?? condition;
  }

  static String getStatusLabel(String status) {
    return statusLabels[status] ?? status;
  }
}

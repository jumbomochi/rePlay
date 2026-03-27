import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database.dart';

class CategoryFilterChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final void Function(String? category) onCategorySelected;
  final List<Toy> toys;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
    this.toys = const [],
  });

  @override
  Widget build(BuildContext context) {
    final categoryCounts = <String, int>{};
    for (final toy in toys) {
      categoryCounts[toy.category] = (categoryCounts[toy.category] ?? 0) + 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: Text(toys.isEmpty ? 'All' : 'All (${toys.length})'),
            selected: selectedCategory == null,
            onSelected: (_) => onCategorySelected(null),
            avatar: const Icon(Icons.select_all, size: 18),
          ),
          const SizedBox(width: 8),
          ...categories.map((category) {
            final count = categoryCounts[category] ?? 0;
            final label = toys.isEmpty ? category : '$category ($count)';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: selectedCategory == category,
                onSelected: (_) => onCategorySelected(category),
                avatar: Icon(
                  AppConstants.getCategoryIcon(category),
                  size: 18,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

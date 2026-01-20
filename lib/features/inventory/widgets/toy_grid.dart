import 'package:flutter/material.dart';

import '../../../core/database/database.dart';
import 'toy_card.dart';

class ToyGrid extends StatelessWidget {
  final List<Toy> toys;
  final void Function(Toy toy)? onToyTap;
  final bool isLoading;
  final String searchQuery;

  const ToyGrid({
    super.key,
    required this.toys,
    this.onToyTap,
    this.isLoading = false,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (toys.isEmpty) {
      final hasSearchQuery = searchQuery.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearchQuery ? Icons.search_off : Icons.toys_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearchQuery ? 'No toys found for "$searchQuery"' : 'No toys yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearchQuery
                  ? 'Try a different search or clear filters'
                  : 'Tap the camera button to add your first toy!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: toys.length,
      itemBuilder: (context, index) {
        final toy = toys[index];
        return ToyCard(
          toy: toy,
          onTap: onToyTap != null ? () => onToyTap!(toy) : null,
        );
      },
    );
  }
}

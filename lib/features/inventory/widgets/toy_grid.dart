import 'package:flutter/material.dart';

import '../../../core/database/database.dart';
import 'toy_card.dart';

class ToyGrid extends StatelessWidget {
  final List<Toy> toys;
  final void Function(Toy toy)? onToyTap;
  final bool isLoading;

  const ToyGrid({
    super.key,
    required this.toys,
    this.onToyTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (toys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.toys_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No toys yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the camera button to add your first toy!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
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

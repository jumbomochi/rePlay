import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database.dart';

class NeedsAttentionCard extends StatelessWidget {
  final List<Toy> toys;
  final void Function(int toyId) onToyTap;

  const NeedsAttentionCard({
    super.key,
    required this.toys,
    required this.onToyTap,
  });

  @override
  Widget build(BuildContext context) {
    final attentionToys = toys
        .where((t) => t.condition == 'poor' || t.condition == 'broken')
        .toList();

    if (attentionToys.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Needs Attention',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...attentionToys.map((toy) {
              return InkWell(
                onTap: () => onToyTap(toy.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          toy.name,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppConstants.getConditionLabel(toy.condition),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

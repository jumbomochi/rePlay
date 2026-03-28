import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class StatusBreakdownCard extends StatelessWidget {
  final Map<String, int> statusCounts;

  const StatusBreakdownCard({super.key, required this.statusCounts});

  static const _statusColors = <String, Color>{
    'active': Color(0xFF6366F1),
    'inStorage': Color(0xFF8B5CF6),
    'toDonate': Color(0xFF10B981),
    'toSell': Color(0xFFF59E0B),
    'toHandDown': Color(0xFF14B8A6),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = statusCounts.values.fold(0, (sum, c) => sum + c);
    final nonZeroStatuses = AppConstants.statuses
        .where((s) => (statusCounts[s] ?? 0) > 0)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By Status', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (total > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: nonZeroStatuses.map((status) {
                    final count = statusCounts[status] ?? 0;
                    return Expanded(
                      flex: count,
                      child: Container(
                        height: 12,
                        color: _statusColors[status] ?? Colors.grey,
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: nonZeroStatuses.map((status) {
                final count = statusCounts[status] ?? 0;
                final color = _statusColors[status] ?? Colors.grey;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppConstants.getStatusLabel(status),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database.dart';

class StatusFilterTabs extends StatelessWidget {
  final String? selectedStatus;
  final void Function(String? status) onStatusSelected;
  final List<Toy> toys;

  const StatusFilterTabs({
    super.key,
    this.selectedStatus,
    required this.onStatusSelected,
    this.toys = const [],
  });

  @override
  Widget build(BuildContext context) {
    final statusCounts = <String, int>{};
    for (final toy in toys) {
      statusCounts[toy.status] = (statusCounts[toy.status] ?? 0) + 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab(
            context: context,
            label: 'All',
            count: toys.length,
            icon: Icons.select_all,
            isSelected: selectedStatus == null,
            onTap: () => onStatusSelected(null),
          ),
          const SizedBox(width: 8),
          ...AppConstants.statuses.map((status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildTab(
                context: context,
                label: AppConstants.getStatusLabel(status),
                count: statusCounts[status] ?? 0,
                icon: AppConstants.getStatusIcon(status),
                isSelected: selectedStatus == status,
                onTap: () => onStatusSelected(status),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required String label,
    required int count,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final displayLabel = toys.isEmpty ? label : '$label ($count)';

    return FilterChip(
      label: Text(displayLabel),
      avatar: Icon(icon, size: 18),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }
}

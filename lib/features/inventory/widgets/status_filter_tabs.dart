import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class StatusFilterTabs extends StatelessWidget {
  final String? selectedStatus;
  final void Function(String? status) onStatusSelected;

  const StatusFilterTabs({
    super.key,
    this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab(
            context: context,
            label: 'All',
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
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }
}

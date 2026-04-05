import 'package:flutter/material.dart';

import '../../../core/database/database.dart';

class OwnerFilterChips extends StatelessWidget {
  final String? selectedOwner;
  final void Function(String? owner) onOwnerSelected;
  final List<Toy> toys;

  const OwnerFilterChips({
    super.key,
    this.selectedOwner,
    required this.onOwnerSelected,
    this.toys = const [],
  });

  @override
  Widget build(BuildContext context) {
    final ownerCounts = <String, int>{};
    for (final toy in toys) {
      if (toy.owner != null && toy.owner!.isNotEmpty) {
        ownerCounts[toy.owner!] = (ownerCounts[toy.owner!] ?? 0) + 1;
      }
    }

    if (ownerCounts.isEmpty) return const SizedBox.shrink();

    final owners = ownerCounts.keys.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: Text('All (${toys.length})'),
            selected: selectedOwner == null,
            onSelected: (_) => onOwnerSelected(null),
            avatar: const Icon(Icons.people, size: 18),
          ),
          const SizedBox(width: 8),
          ...owners.map((owner) {
            final count = ownerCounts[owner] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('$owner ($count)'),
                selected: selectedOwner == owner,
                onSelected: (_) => onOwnerSelected(owner),
                avatar: const Icon(Icons.person, size: 18),
              ),
            );
          }),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inventory/providers/inventory_provider.dart';
import '../../inventory/screens/toy_detail_screen.dart';
import '../widgets/hero_count_card.dart';
import '../widgets/needs_attention_card.dart';
import '../widgets/recently_added_card.dart';
import '../widgets/status_breakdown_card.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryState = ref.watch(inventoryProvider);
    final toys = inventoryState.toys;

    final statusCounts = <String, int>{};
    for (final toy in toys) {
      statusCounts[toy.status] = (statusCounts[toy.status] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: inventoryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                HeroCountCard(totalCount: toys.length),
                const SizedBox(height: 12),
                StatusBreakdownCard(statusCounts: statusCounts),
                const SizedBox(height: 12),
                RecentlyAddedCard(
                  toys: toys,
                  onToyTap: (id) => _navigateToDetail(context, ref, id),
                ),
                const SizedBox(height: 12),
                NeedsAttentionCard(
                  toys: toys,
                  onToyTap: (id) => _navigateToDetail(context, ref, id),
                ),
              ],
            ),
    );
  }

  void _navigateToDetail(BuildContext context, WidgetRef ref, int toyId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ToyDetailScreen(toyId: toyId),
      ),
    );

    if (result == true) {
      ref.read(inventoryProvider.notifier).refresh();
    }
  }
}

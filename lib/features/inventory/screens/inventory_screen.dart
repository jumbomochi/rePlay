import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/providers/categories_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/status_filter_tabs.dart';
import '../widgets/toy_grid.dart';
import 'toy_detail_screen.dart';
import '../../capture/screens/capture_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);
    final categories = ref.watch(categoryNamesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('rePlay'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search toys...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(inventoryProvider.notifier).setSearchQuery('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {});
                  ref.read(inventoryProvider.notifier).setSearchQuery(value);
                },
              ),
            ),
            const SizedBox(height: 8),
            StatusFilterTabs(
              selectedStatus: inventoryState.selectedStatus,
              onStatusSelected: (status) {
                ref.read(inventoryProvider.notifier).setStatus(status);
              },
              toys: inventoryState.toys,
            ),
            const SizedBox(height: 8),
            CategoryFilterChips(
              categories: categories,
              selectedCategory: inventoryState.selectedCategory,
              onCategorySelected: (category) {
                ref.read(inventoryProvider.notifier).setCategory(category);
              },
              toys: inventoryState.toys,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownButton<SortOption>(
                    value: inventoryState.sortBy,
                    underline: const SizedBox.shrink(),
                    icon: const Icon(Icons.sort, size: 20),
                    style: Theme.of(context).textTheme.bodySmall,
                    items: SortOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(inventoryProvider.notifier).setSortOption(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ToyGrid(
                toys: inventoryState.filteredToys,
                isLoading: inventoryState.isLoading,
                searchQuery: inventoryState.searchQuery,
                onToyTap: (toy) => _navigateToDetail(toy.id),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCapture,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Add Toy'),
      ),
    );
  }

  void _navigateToCapture() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const CaptureScreen(),
      ),
    );

    if (result == true) {
      ref.read(inventoryProvider.notifier).refresh();
    }
  }

  void _navigateToDetail(int toyId) async {
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

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
  bool _isSearching = false;

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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search toys...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(inventoryProvider.notifier).setSearchQuery(value);
                },
              )
            : const Text('rePlay'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(inventoryProvider.notifier).setSearchQuery('');
                }
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(inventoryProvider.notifier).refresh(),
        child: Column(
          children: [
            const SizedBox(height: 8),
            StatusFilterTabs(
              selectedStatus: inventoryState.selectedStatus,
              onStatusSelected: (status) {
                ref.read(inventoryProvider.notifier).setStatus(status);
              },
            ),
            const SizedBox(height: 8),
            CategoryFilterChips(
              categories: categories,
              selectedCategory: inventoryState.selectedCategory,
              onCategorySelected: (category) {
                ref.read(inventoryProvider.notifier).setCategory(category);
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ToyGrid(
                toys: inventoryState.filteredToys,
                isLoading: inventoryState.isLoading,
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

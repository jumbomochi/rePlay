import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database.dart';
import '../../../core/services/services_provider.dart';
import '../../categories/providers/categories_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/location_autocomplete_field.dart';
import '../widgets/owner_filter_chips.dart';
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
    final isMultiSelect = inventoryState.isMultiSelectMode;

    return Scaffold(
      appBar: isMultiSelect
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(inventoryProvider.notifier).clearSelection();
                },
              ),
              title: Text('${inventoryState.selectedToyIds.length} selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  tooltip: 'Select All',
                  onPressed: () {
                    ref.read(inventoryProvider.notifier).selectAll();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Actions',
                  onPressed: () => _showBulkActionsSheet(context),
                ),
              ],
            )
          : AppBar(
              title: const Text('rePlay'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Export',
                  onPressed: () => _showExportSheet(context),
                ),
              ],
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
              toys: inventoryState.toys,
              onStatusSelected: (status) {
                ref.read(inventoryProvider.notifier).setStatus(status);
              },
            ),
            const SizedBox(height: 8),
            CategoryFilterChips(
              categories: categories,
              selectedCategory: inventoryState.selectedCategory,
              toys: inventoryState.toys,
              onCategorySelected: (category) {
                ref.read(inventoryProvider.notifier).setCategory(category);
              },
            ),
            const SizedBox(height: 8),
            OwnerFilterChips(
              selectedOwner: inventoryState.selectedOwner,
              toys: inventoryState.toys,
              onOwnerSelected: (owner) {
                ref.read(inventoryProvider.notifier).setOwner(owner);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(inventoryState.isListView ? Icons.grid_view : Icons.view_list),
                    tooltip: inventoryState.isListView ? 'Grid view' : 'List view',
                    onPressed: () {
                      ref.read(inventoryProvider.notifier).toggleViewMode();
                    },
                  ),
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
                isMultiSelectMode: isMultiSelect,
                selectedToyIds: inventoryState.selectedToyIds,
                isListView: inventoryState.isListView,
                onToyTap: isMultiSelect
                    ? (toy) => ref.read(inventoryProvider.notifier).toggleSelection(toy.id)
                    : (toy) => _navigateToDetail(toy.id),
                onToyLongPress: isMultiSelect
                    ? null
                    : (toy) => ref.read(inventoryProvider.notifier).enterMultiSelect(toy.id),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isMultiSelect
          ? null
          : FloatingActionButton.extended(
              onPressed: _navigateToCapture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Add Toy'),
            ),
    );
  }

  void _showExportSheet(BuildContext context) {
    final inventoryState = ref.read(inventoryProvider);
    final filteredToys = inventoryState.filteredToys;

    if (filteredToys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export')),
      );
      return;
    }

    final filterLabel = inventoryState.selectedStatus != null
        ? AppConstants.getStatusLabel(inventoryState.selectedStatus!)
        : 'All';

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text('Share as Text'),
                subtitle: const Text('For messaging apps'),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsText(filteredToys, filterLabel);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Export as CSV'),
                subtitle: const Text('For spreadsheet apps'),
                onTap: () {
                  Navigator.pop(context);
                  _shareAsCsv(filteredToys);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareAsText(List<Toy> toys, String filterLabel) async {
    final exportService = ref.read(exportServiceProvider);
    final text = exportService.generateTextList(toys, filterLabel);
    await Share.share(text, subject: 'rePlay Toy List');
  }

  Future<void> _shareAsCsv(List<Toy> toys) async {
    final exportService = ref.read(exportServiceProvider);
    final filePath = await exportService.writeCsvFile(toys);
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'rePlay Toy Export',
    );
  }

  void _showBulkActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Change Status'),
                onTap: () {
                  Navigator.pop(context);
                  _showStatusPicker(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Change Location'),
                onTap: () {
                  Navigator.pop(context);
                  _showLocationDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Change Status To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ...AppConstants.statuses.map((status) {
                return ListTile(
                  leading: Icon(AppConstants.getStatusIcon(status)),
                  title: Text(AppConstants.getStatusLabel(status)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(inventoryProvider.notifier).bulkUpdateStatus(status);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showLocationDialog(BuildContext context) {
    final locationController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Location'),
          content: LocationAutocompleteField(
            controller: locationController,
            onChanged: (_) {},
            decoration: const InputDecoration(
              hintText: 'Enter location...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final location = locationController.text.trim();
                if (location.isNotEmpty) {
                  Navigator.pop(context);
                  ref.read(inventoryProvider.notifier).bulkUpdateLocation(location);
                }
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
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

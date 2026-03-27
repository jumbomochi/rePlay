# High-Impact Inventory Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add search-by-description, sort options, filter count badges, and batch status/location updates to the inventory screen.

**Architecture:** All four features modify the same state layer (`InventoryState` / `InventoryNotifier`) and the inventory screen's widget tree. Changes are independent — each task produces a working commit. Batch operations introduce a multi-select interaction mode with an overlay UI on toy cards and a transformed AppBar.

**Tech Stack:** Flutter, Riverpod (StateNotifier), Drift (SQLite)

---

## File Map

| File | Changes |
|------|---------|
| `lib/features/inventory/providers/inventory_provider.dart` | Add `SortOption` enum, `sortBy` field, description search, multi-select state, bulk methods |
| `lib/features/inventory/screens/inventory_screen.dart` | Add sort dropdown, pass toys to filter widgets, multi-select AppBar, long-press handler, bulk action bottom sheet |
| `lib/features/inventory/widgets/status_filter_tabs.dart` | Accept `toys` list, compute and display counts |
| `lib/features/inventory/widgets/category_filter_chips.dart` | Accept `toys` list, compute and display counts |
| `lib/features/inventory/widgets/toy_card.dart` | Accept `isSelected` and `isMultiSelectMode`, render selection overlay |
| `lib/features/inventory/widgets/toy_grid.dart` | Pass selection state and callbacks to ToyCard |
| `test/widget_test.dart` | Add tests for each feature |

---

### Task 1: Search Includes Description

**Files:**
- Modify: `lib/features/inventory/providers/inventory_provider.dart:66-73`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/widget_test.dart` before the closing `}` of `main()`:

```dart
  testWidgets('Search matches toy description', (WidgetTester tester) async {
    final notifier = MockInventoryNotifier();
    // Manually set state with a toy whose description matches but name doesn't
    notifier.state = InventoryState(
      toys: [
        Toy(
          id: 1,
          name: 'LEGO Star Wars Set',
          description: 'Millennium Falcon building set',
          imagePath: '',
          thumbnailPath: null,
          category: 'Building Blocks',
          aiLabels: '["lego"]',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          condition: 'good',
          location: 'Playroom',
          status: 'active',
        ),
      ],
      searchQuery: 'millennium',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith((ref) => notifier),
          categoryNamesProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();

    // Toy should appear because "millennium" matches the description
    expect(find.text('LEGO Star Wars Set'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --name "Search matches toy description"`
Expected: FAIL — the toy is filtered out because description is not searched.

- [ ] **Step 3: Add description to search predicate**

In `lib/features/inventory/providers/inventory_provider.dart`, replace lines 66-73:

```dart
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((t) {
        return t.name.toLowerCase().contains(query) ||
            t.aiLabels.toLowerCase().contains(query) ||
            (t.location?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
```

with:

```dart
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((t) {
        return t.name.toLowerCase().contains(query) ||
            (t.description?.toLowerCase().contains(query) ?? false) ||
            t.aiLabels.toLowerCase().contains(query) ||
            (t.location?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart --name "Search matches toy description"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/inventory/providers/inventory_provider.dart test/widget_test.dart
git commit -m "feat: include description in search filter"
```

---

### Task 2: Sort Options

**Files:**
- Modify: `lib/features/inventory/providers/inventory_provider.dart`
- Modify: `lib/features/inventory/screens/inventory_screen.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/widget_test.dart`:

```dart
  testWidgets('Sort dropdown appears and defaults to Newest First', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith((ref) => MockInventoryNotifier()),
          categoryNamesProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();

    // Sort dropdown should be visible with default value
    expect(find.text('Newest First'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --name "Sort dropdown"`
Expected: FAIL — no sort dropdown exists yet.

- [ ] **Step 3: Add SortOption enum and state to provider**

In `lib/features/inventory/providers/inventory_provider.dart`, add the enum before the `InventoryState` class:

```dart
enum SortOption {
  newestFirst('Newest First'),
  oldestFirst('Oldest First'),
  nameAsc('Name A-Z'),
  nameDesc('Name Z-A'),
  category('Category');

  const SortOption(this.label);
  final String label;
}
```

Add `sortBy` to `InventoryState`:

In the constructor, add: `this.sortBy = SortOption.newestFirst,`

In the field declarations, add: `final SortOption sortBy;`

In `copyWith`, add parameter `SortOption? sortBy,` and in the body: `sortBy: sortBy ?? this.sortBy,`

At the end of the `filteredToys` getter, before `return result;`, add:

```dart
    switch (sortBy) {
      case SortOption.newestFirst:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.oldestFirst:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOption.nameAsc:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case SortOption.nameDesc:
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case SortOption.category:
        result.sort((a, b) => a.category.compareTo(b.category));
    }
```

In `InventoryNotifier`, add:

```dart
  void setSortOption(SortOption option) {
    state = state.copyWith(sortBy: option);
  }
```

In `clearFilters`, add `sortBy: SortOption.newestFirst`:

```dart
  void clearFilters() {
    state = state.copyWith(
      selectedCategory: null,
      searchQuery: '',
      selectedStatus: null,
      sortBy: SortOption.newestFirst,
    );
  }
```

- [ ] **Step 4: Add sort dropdown to inventory screen**

In `lib/features/inventory/screens/inventory_screen.dart`, add the sort dropdown between the `CategoryFilterChips` and the `Expanded` `ToyGrid`. Replace:

```dart
            const SizedBox(height: 8),
            Expanded(
              child: ToyGrid(
```

with:

```dart
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
```

Add `SortOption` to the imports from `inventory_provider.dart` (it's exported from the same file).

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/widget_test.dart --name "Sort dropdown"`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/inventory/providers/inventory_provider.dart lib/features/inventory/screens/inventory_screen.dart test/widget_test.dart
git commit -m "feat: add sort options to inventory screen"
```

---

### Task 3: Toy Count Badges

**Files:**
- Modify: `lib/features/inventory/widgets/status_filter_tabs.dart`
- Modify: `lib/features/inventory/widgets/category_filter_chips.dart`
- Modify: `lib/features/inventory/screens/inventory_screen.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/widget_test.dart`:

```dart
  testWidgets('Status filter tabs show toy counts', (WidgetTester tester) async {
    final notifier = MockInventoryNotifier();
    notifier.state = InventoryState(
      toys: [
        Toy(id: 1, name: 'Toy1', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
        Toy(id: 2, name: 'Toy2', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
        Toy(id: 3, name: 'Toy3', description: null, imagePath: '', thumbnailPath: null, category: 'Dolls', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'toDonate'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith((ref) => notifier),
          categoryNamesProvider.overrideWith((ref) => ['Other', 'Dolls']),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();

    // Status tabs should show counts
    expect(find.text('All (3)'), findsOneWidget);
    expect(find.text('Active (2)'), findsOneWidget);
    expect(find.text('To Donate (1)'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --name "Status filter tabs show toy counts"`
Expected: FAIL — tabs show labels without counts.

- [ ] **Step 3: Update StatusFilterTabs to accept toys and show counts**

Replace the full content of `lib/features/inventory/widgets/status_filter_tabs.dart`:

```dart
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
```

- [ ] **Step 4: Update CategoryFilterChips to accept toys and show counts**

Replace the full content of `lib/features/inventory/widgets/category_filter_chips.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database.dart';

class CategoryFilterChips extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final void Function(String? category) onCategorySelected;
  final List<Toy> toys;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
    this.toys = const [],
  });

  @override
  Widget build(BuildContext context) {
    final categoryCounts = <String, int>{};
    for (final toy in toys) {
      categoryCounts[toy.category] = (categoryCounts[toy.category] ?? 0) + 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: Text(toys.isEmpty ? 'All' : 'All (${toys.length})'),
            selected: selectedCategory == null,
            onSelected: (_) => onCategorySelected(null),
            avatar: const Icon(Icons.select_all, size: 18),
          ),
          const SizedBox(width: 8),
          ...categories.map((category) {
            final count = categoryCounts[category] ?? 0;
            final label = toys.isEmpty ? category : '$category ($count)';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: selectedCategory == category,
                onSelected: (_) => onCategorySelected(category),
                avatar: Icon(
                  AppConstants.getCategoryIcon(category),
                  size: 18,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Pass toys list to filter widgets in inventory screen**

In `lib/features/inventory/screens/inventory_screen.dart`, update `StatusFilterTabs` to pass `toys`:

```dart
            StatusFilterTabs(
              selectedStatus: inventoryState.selectedStatus,
              toys: inventoryState.toys,
              onStatusSelected: (status) {
                ref.read(inventoryProvider.notifier).setStatus(status);
              },
            ),
```

Update `CategoryFilterChips` to pass `toys`:

```dart
            CategoryFilterChips(
              categories: categories,
              selectedCategory: inventoryState.selectedCategory,
              toys: inventoryState.toys,
              onCategorySelected: (category) {
                ref.read(inventoryProvider.notifier).setCategory(category);
              },
            ),
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/widget_test.dart --name "Status filter tabs show toy counts"`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/features/inventory/widgets/status_filter_tabs.dart lib/features/inventory/widgets/category_filter_chips.dart lib/features/inventory/screens/inventory_screen.dart test/widget_test.dart
git commit -m "feat: add toy count badges to status and category filters"
```

---

### Task 4: Batch Status and Location Changes — State Layer

**Files:**
- Modify: `lib/features/inventory/providers/inventory_provider.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/widget_test.dart`:

```dart
  test('Batch update status changes all selected toys', () async {
    final db = _MockDatabase();
    final imageStorage = _MockImageStorage();
    final notifier = InventoryNotifier(db, imageStorage);

    // Set initial state with toys
    notifier.state = InventoryState(
      toys: [
        Toy(id: 1, name: 'Toy1', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
        Toy(id: 2, name: 'Toy2', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
        Toy(id: 3, name: 'Toy3', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
      ],
    );

    // Enter multi-select and select toys 1 and 3
    notifier.enterMultiSelect(1);
    expect(notifier.state.isMultiSelectMode, true);
    expect(notifier.state.selectedToyIds, {1});

    notifier.toggleSelection(3);
    expect(notifier.state.selectedToyIds, {1, 3});

    // Toggle off toy 1
    notifier.toggleSelection(1);
    expect(notifier.state.selectedToyIds, {3});

    // Clear selection exits multi-select
    notifier.clearSelection();
    expect(notifier.state.isMultiSelectMode, false);
    expect(notifier.state.selectedToyIds, isEmpty);
  });
```

Add `import 'package:flutter_test/flutter_test.dart';` is already there. Also add a bare `test` import if needed — `flutter_test` re-exports it.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --name "Batch update status"`
Expected: FAIL — `isMultiSelectMode`, `selectedToyIds`, `enterMultiSelect`, `toggleSelection`, `clearSelection` don't exist.

- [ ] **Step 3: Add multi-select state and methods to provider**

In `lib/features/inventory/providers/inventory_provider.dart`, add to `InventoryState`:

Fields:
```dart
  final bool isMultiSelectMode;
  final Set<int> selectedToyIds;
```

Constructor params:
```dart
    this.isMultiSelectMode = false,
    this.selectedToyIds = const {},
```

`copyWith` params and body:
```dart
    bool? isMultiSelectMode,
    Set<int>? selectedToyIds,
```
```dart
      isMultiSelectMode: isMultiSelectMode ?? this.isMultiSelectMode,
      selectedToyIds: selectedToyIds ?? this.selectedToyIds,
```

In `InventoryNotifier`, add these methods:

```dart
  void enterMultiSelect(int toyId) {
    state = state.copyWith(
      isMultiSelectMode: true,
      selectedToyIds: {toyId},
    );
  }

  void toggleSelection(int toyId) {
    final selected = Set<int>.from(state.selectedToyIds);
    if (selected.contains(toyId)) {
      selected.remove(toyId);
    } else {
      selected.add(toyId);
    }
    state = state.copyWith(selectedToyIds: selected);
  }

  void selectAll() {
    final allIds = state.filteredToys.map((t) => t.id).toSet();
    state = state.copyWith(selectedToyIds: allIds);
  }

  void clearSelection() {
    state = state.copyWith(
      isMultiSelectMode: false,
      selectedToyIds: {},
    );
  }

  Future<void> bulkUpdateStatus(String status) async {
    for (final id in state.selectedToyIds) {
      await updateToy(id: id, status: status);
    }
    clearSelection();
  }

  Future<void> bulkUpdateLocation(String location) async {
    for (final id in state.selectedToyIds) {
      await updateToy(id: id, location: location);
    }
    clearSelection();
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart --name "Batch update status"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/inventory/providers/inventory_provider.dart test/widget_test.dart
git commit -m "feat: add multi-select state and bulk update methods"
```

---

### Task 5: Batch Operations — ToyCard Selection Overlay

**Files:**
- Modify: `lib/features/inventory/widgets/toy_card.dart`
- Modify: `lib/features/inventory/widgets/toy_grid.dart`

- [ ] **Step 1: Add selection parameters to ToyCard**

In `lib/features/inventory/widgets/toy_card.dart`, add parameters to `ToyCard`:

```dart
class ToyCard extends StatelessWidget {
  final Toy toy;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isMultiSelectMode;

  const ToyCard({
    super.key,
    required this.toy,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isMultiSelectMode = false,
  });
```

Update the `InkWell` to include `onLongPress`:

```dart
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
```

Add a selection overlay as the last item in the `Stack` children, after the condition badge:

```dart
            // Selection overlay
            if (isMultiSelectMode)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : Colors.transparent,
                    border: isSelected
                        ? Border.all(color: theme.colorScheme.primary, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
```

- [ ] **Step 2: Update ToyGrid to pass selection state**

In `lib/features/inventory/widgets/toy_grid.dart`, add parameters:

```dart
class ToyGrid extends StatelessWidget {
  final List<Toy> toys;
  final void Function(Toy toy)? onToyTap;
  final void Function(Toy toy)? onToyLongPress;
  final bool isLoading;
  final String searchQuery;
  final bool isMultiSelectMode;
  final Set<int> selectedToyIds;

  const ToyGrid({
    super.key,
    required this.toys,
    this.onToyTap,
    this.onToyLongPress,
    this.isLoading = false,
    this.searchQuery = '',
    this.isMultiSelectMode = false,
    this.selectedToyIds = const {},
  });
```

Update the `ToyCard` in `itemBuilder`:

```dart
        return ToyCard(
          toy: toy,
          onTap: onToyTap != null ? () => onToyTap!(toy) : null,
          onLongPress: onToyLongPress != null ? () => onToyLongPress!(toy) : null,
          isSelected: selectedToyIds.contains(toy.id),
          isMultiSelectMode: isMultiSelectMode,
        );
```

- [ ] **Step 3: Run all tests to verify nothing broke**

Run: `flutter test test/widget_test.dart`
Expected: All existing tests PASS (new params have defaults).

- [ ] **Step 4: Commit**

```bash
git add lib/features/inventory/widgets/toy_card.dart lib/features/inventory/widgets/toy_grid.dart
git commit -m "feat: add selection overlay to toy card and grid"
```

---

### Task 6: Batch Operations — Inventory Screen Multi-Select UI

**Files:**
- Modify: `lib/features/inventory/screens/inventory_screen.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/widget_test.dart`:

```dart
  testWidgets('Long press enters multi-select mode', (WidgetTester tester) async {
    final notifier = MockInventoryNotifier();
    notifier.state = InventoryState(
      toys: [
        Toy(id: 1, name: 'TestToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith((ref) => notifier),
          categoryNamesProvider.overrideWith((ref) => ['Other']),
        ],
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();

    // Long press the toy card
    await tester.longPress(find.text('TestToy'));
    await tester.pump();

    // Should show multi-select AppBar with "1 selected"
    expect(find.text('1 selected'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --name "Long press enters multi-select"`
Expected: FAIL — no multi-select AppBar exists.

- [ ] **Step 3: Add multi-select UI to inventory screen**

Replace the full `build` method in `_InventoryScreenState` in `lib/features/inventory/screens/inventory_screen.dart`:

```dart
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
                isMultiSelectMode: isMultiSelect,
                selectedToyIds: inventoryState.selectedToyIds,
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
```

- [ ] **Step 4: Add the bulk actions bottom sheet method**

Add this method to `_InventoryScreenState`:

```dart
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
          content: TextField(
            controller: locationController,
            decoration: const InputDecoration(
              hintText: 'Enter location...',
            ),
            autofocus: true,
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
```

Add `AppConstants` to the imports:

```dart
import '../../../core/constants/app_constants.dart';
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/widget_test.dart --name "Long press enters multi-select"`
Expected: PASS

- [ ] **Step 6: Run all tests**

Run: `flutter test test/widget_test.dart`
Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/inventory/screens/inventory_screen.dart test/widget_test.dart
git commit -m "feat: add multi-select UI with bulk status and location actions"
```

---

### Task 7: Final Verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No analysis issues.

- [ ] **Step 3: Fix any issues found**

If there are analysis warnings or test failures, fix them and commit.

- [ ] **Step 4: Final commit if needed**

```bash
git add -A
git commit -m "fix: resolve analysis warnings"
```

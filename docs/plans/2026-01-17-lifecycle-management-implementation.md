# Lifecycle Management Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add condition, location, and status fields to toys with quick-access status filter tabs.

**Architecture:** Extend existing Drift database schema with three new columns, add status filtering to InventoryState, create a new StatusFilterTabs widget that sits above category chips.

**Tech Stack:** Flutter, Drift (SQLite), Riverpod

---

## Task 1: Add Lifecycle Enums to Constants

**Files:**
- Modify: `lib/core/constants/app_constants.dart`

**Step 1: Add enums and icon maps**

Add after the existing `categoryIcons` map:

```dart
  // Toy condition values
  static const List<String> conditions = [
    'excellent',
    'good',
    'fair',
    'poor',
    'broken',
  ];

  static const Map<String, IconData> conditionIcons = {
    'excellent': Icons.star,
    'good': Icons.thumb_up,
    'fair': Icons.thumbs_up_down,
    'poor': Icons.thumb_down,
    'broken': Icons.build,
  };

  static const Map<String, String> conditionLabels = {
    'excellent': 'Excellent',
    'good': 'Good',
    'fair': 'Fair',
    'poor': 'Poor',
    'broken': 'Broken',
  };

  // Toy lifecycle status values
  static const List<String> statuses = [
    'active',
    'inStorage',
    'toDonate',
    'toSell',
    'toHandDown',
  ];

  static const Map<String, IconData> statusIcons = {
    'active': Icons.play_arrow,
    'inStorage': Icons.inventory_2,
    'toDonate': Icons.volunteer_activism,
    'toSell': Icons.attach_money,
    'toHandDown': Icons.card_giftcard,
  };

  static const Map<String, String> statusLabels = {
    'active': 'Active',
    'inStorage': 'In Storage',
    'toDonate': 'To Donate',
    'toSell': 'To Sell',
    'toHandDown': 'Hand Down',
  };

  static IconData getConditionIcon(String condition) {
    return conditionIcons[condition] ?? Icons.help_outline;
  }

  static IconData getStatusIcon(String status) {
    return statusIcons[status] ?? Icons.help_outline;
  }

  static String getConditionLabel(String condition) {
    return conditionLabels[condition] ?? condition;
  }

  static String getStatusLabel(String status) {
    return statusLabels[status] ?? status;
  }
```

**Step 2: Verify no syntax errors**

Run: `flutter analyze lib/core/constants/app_constants.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/constants/app_constants.dart
git commit -m "feat: add lifecycle enums and icons to constants"
```

---

## Task 2: Add Columns to Toys Table

**Files:**
- Modify: `lib/core/database/tables/toys_table.dart`

**Step 1: Add new columns to Toys class**

Add after the `updatedAt` column:

```dart
  TextColumn get condition => text().withDefault(const Constant('good'))();
  TextColumn get location => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
```

**Step 2: Verify no syntax errors**

Run: `flutter analyze lib/core/database/tables/toys_table.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/database/tables/toys_table.dart
git commit -m "feat: add condition, location, status columns to toys table"
```

---

## Task 3: Update Database with Migration

**Files:**
- Modify: `lib/core/database/database.dart`

**Step 1: Increment schema version**

Change:
```dart
@override
int get schemaVersion => 1;
```

To:
```dart
@override
int get schemaVersion => 2;
```

**Step 2: Add migration logic**

Replace the `migration` getter with:

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedCategories();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(toys, toys.condition);
        await m.addColumn(toys, toys.location);
        await m.addColumn(toys, toys.status);
      }
    },
  );
}
```

**Step 3: Add query methods for status filtering**

Add after `searchToys` method:

```dart
// Get all distinct locations for autocomplete
Future<List<String>> getAllLocations() async {
  final result = await customSelect(
    'SELECT DISTINCT location FROM toys WHERE location IS NOT NULL ORDER BY location',
  ).get();
  return result.map((row) => row.read<String>('location')).toList();
}

// Get toys by status
Future<List<Toy>> getToysByStatus(String status) {
  return (select(toys)..where((t) => t.status.equals(status))).get();
}

// Count toys by status
Future<Map<String, int>> getStatusCounts() async {
  final allToys = await getAllToys();
  final counts = <String, int>{};
  for (final toy in allToys) {
    counts[toy.status] = (counts[toy.status] ?? 0) + 1;
  }
  return counts;
}
```

**Step 4: Verify no syntax errors**

Run: `flutter analyze lib/core/database/database.dart`
Expected: No issues found

**Step 5: Commit**

```bash
git add lib/core/database/database.dart
git commit -m "feat: add migration and lifecycle query methods to database"
```

---

## Task 4: Regenerate Database Code

**Files:**
- Regenerate: `lib/core/database/database.g.dart`

**Step 1: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Successful generation with no errors

**Step 2: Verify generated code compiles**

Run: `flutter analyze lib/core/database/`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/database/database.g.dart
git commit -m "chore: regenerate database code with new columns"
```

---

## Task 5: Update Inventory Provider with Status Filter

**Files:**
- Modify: `lib/features/inventory/providers/inventory_provider.dart`

**Step 1: Add selectedStatus to InventoryState**

Update `InventoryState` class - add field:

```dart
final String? selectedStatus;
```

Update constructor:

```dart
InventoryState({
  this.toys = const [],
  this.isLoading = false,
  this.error,
  this.selectedCategory,
  this.searchQuery = '',
  this.selectedStatus,
});
```

Update `copyWith`:

```dart
InventoryState copyWith({
  List<Toy>? toys,
  bool? isLoading,
  String? error,
  String? selectedCategory,
  String? searchQuery,
  String? selectedStatus,
}) {
  return InventoryState(
    toys: toys ?? this.toys,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    selectedCategory: selectedCategory ?? this.selectedCategory,
    searchQuery: searchQuery ?? this.searchQuery,
    selectedStatus: selectedStatus ?? this.selectedStatus,
  );
}
```

**Step 2: Update filteredToys getter**

Replace `filteredToys` getter with:

```dart
List<Toy> get filteredToys {
  var result = toys;

  if (selectedStatus != null && selectedStatus!.isNotEmpty) {
    result = result.where((t) => t.status == selectedStatus).toList();
  }

  if (selectedCategory != null && selectedCategory!.isNotEmpty) {
    result = result.where((t) => t.category == selectedCategory).toList();
  }

  if (searchQuery.isNotEmpty) {
    final query = searchQuery.toLowerCase();
    result = result.where((t) {
      return t.name.toLowerCase().contains(query) ||
          t.aiLabels.toLowerCase().contains(query) ||
          (t.location?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  return result;
}
```

**Step 3: Add setStatus method to InventoryNotifier**

Add after `setSearchQuery`:

```dart
void setStatus(String? status) {
  state = state.copyWith(selectedStatus: status);
}
```

**Step 4: Verify no syntax errors**

Run: `flutter analyze lib/features/inventory/providers/inventory_provider.dart`
Expected: No issues found

**Step 5: Commit**

```bash
git add lib/features/inventory/providers/inventory_provider.dart
git commit -m "feat: add status filter to inventory provider"
```

---

## Task 6: Create Status Filter Tabs Widget

**Files:**
- Create: `lib/features/inventory/widgets/status_filter_tabs.dart`

**Step 1: Create the widget file**

```dart
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
```

**Step 2: Verify no syntax errors**

Run: `flutter analyze lib/features/inventory/widgets/status_filter_tabs.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/inventory/widgets/status_filter_tabs.dart
git commit -m "feat: create status filter tabs widget"
```

---

## Task 7: Add Status Tabs to Inventory Screen

**Files:**
- Modify: `lib/features/inventory/screens/inventory_screen.dart`

**Step 1: Add import**

Add after existing imports:

```dart
import '../widgets/status_filter_tabs.dart';
```

**Step 2: Add StatusFilterTabs to body**

In the `body` Column children, add StatusFilterTabs before CategoryFilterChips:

Replace:
```dart
child: Column(
  children: [
    const SizedBox(height: 8),
    CategoryFilterChips(
```

With:
```dart
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
```

**Step 3: Verify no syntax errors**

Run: `flutter analyze lib/features/inventory/screens/inventory_screen.dart`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/features/inventory/screens/inventory_screen.dart
git commit -m "feat: add status filter tabs to inventory screen"
```

---

## Task 8: Add Badges to Toy Card

**Files:**
- Modify: `lib/features/inventory/widgets/toy_card.dart`

**Step 1: Add status badge to card**

Replace the `build` method's Card child with:

```dart
return Card(
  clipBehavior: Clip.antiAlias,
  child: InkWell(
    onTap: onTap,
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: _buildImage(),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toy.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          AppConstants.getCategoryIcon(toy.category),
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            toy.category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Status badge (only for non-active)
        if (toy.status != 'active')
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                AppConstants.getStatusIcon(toy.status),
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        // Condition badge (only for poor/broken)
        if (toy.condition == 'poor' || toy.condition == 'broken')
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: toy.condition == 'broken'
                    ? theme.colorScheme.error
                    : Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    ),
  ),
);
```

**Step 2: Verify no syntax errors**

Run: `flutter analyze lib/features/inventory/widgets/toy_card.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/inventory/widgets/toy_card.dart
git commit -m "feat: add status and condition badges to toy card"
```

---

## Task 9: Add Lifecycle Fields to Toy Detail Screen

**Files:**
- Modify: `lib/features/inventory/screens/toy_detail_screen.dart`

**Step 1: Read current file to understand structure**

Read the file first to see the current form layout.

**Step 2: Add lifecycle section state variables**

In the State class, add:

```dart
String _condition = 'good';
String? _location;
String _status = 'active';
final _locationController = TextEditingController();
bool _lifecycleExpanded = false;
```

**Step 3: Initialize from toy data**

In the method that loads toy data, add:

```dart
_condition = toy.condition;
_location = toy.location;
_status = toy.status;
_locationController.text = toy.location ?? '';
```

**Step 4: Add lifecycle section widget**

Create a new method:

```dart
Widget _buildLifecycleSection() {
  return ExpansionTile(
    title: const Text('Lifecycle'),
    leading: const Icon(Icons.history),
    initiallyExpanded: _lifecycleExpanded,
    onExpansionChanged: (expanded) {
      setState(() => _lifecycleExpanded = expanded);
    },
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Condition
            Text('Condition', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: AppConstants.conditions.map((c) {
                return ButtonSegment(
                  value: c,
                  label: Text(AppConstants.getConditionLabel(c)),
                  icon: Icon(AppConstants.getConditionIcon(c)),
                );
              }).toList(),
              selected: {_condition},
              onSelectionChanged: (selected) {
                setState(() => _condition = selected.first);
              },
            ),
            const SizedBox(height: 16),
            // Location
            Text('Location', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'e.g., Playroom shelf, Garage bin 2',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _location = value.isEmpty ? null : value,
            ),
            const SizedBox(height: 16),
            // Status
            Text('Status', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: AppConstants.statuses.map((s) {
                return ButtonSegment(
                  value: s,
                  label: Text(AppConstants.getStatusLabel(s)),
                  icon: Icon(AppConstants.getStatusIcon(s)),
                );
              }).toList(),
              selected: {_status},
              onSelectionChanged: (selected) {
                setState(() => _status = selected.first);
              },
              multiSelectionEnabled: false,
            ),
          ],
        ),
      ),
    ],
  );
}
```

**Step 5: Add import for AppConstants**

```dart
import '../../../core/constants/app_constants.dart';
```

**Step 6: Include lifecycle fields in save**

Update the save/update method to include the new fields.

**Step 7: Verify no syntax errors**

Run: `flutter analyze lib/features/inventory/screens/toy_detail_screen.dart`
Expected: No issues found

**Step 8: Commit**

```bash
git add lib/features/inventory/screens/toy_detail_screen.dart
git commit -m "feat: add lifecycle fields to toy detail screen"
```

---

## Task 10: Add Lifecycle Fields to Capture Screen

**Files:**
- Modify: `lib/features/capture/screens/capture_screen.dart`

**Step 1: Add lifecycle state variables**

```dart
String _condition = 'good';
String? _location;
String _status = 'active';
final _locationController = TextEditingController();
```

**Step 2: Add collapsed lifecycle section**

Add a similar `ExpansionTile` to the capture form (collapsed by default).

**Step 3: Include lifecycle fields when saving**

Update the save method to include condition, location, status.

**Step 4: Verify no syntax errors**

Run: `flutter analyze lib/features/capture/screens/capture_screen.dart`
Expected: No issues found

**Step 5: Commit**

```bash
git add lib/features/capture/screens/capture_screen.dart
git commit -m "feat: add lifecycle fields to capture screen"
```

---

## Task 11: Update Widget Tests

**Files:**
- Modify: `test/widget_test.dart`

**Step 1: Update mock to include new fields**

The MockInventoryNotifier should work with the updated state.

**Step 2: Add test for status filter tabs**

```dart
testWidgets('Status filter tabs are displayed', (WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryProvider.overrideWith(
          (ref) => MockInventoryNotifier(),
        ),
        categoryNamesProvider.overrideWith(
          (ref) => ['Action Figures'],
        ),
      ],
      child: const MaterialApp(
        home: InventoryScreen(),
      ),
    ),
  );

  await tester.pump();

  // Verify status filter tabs are present
  expect(find.text('All'), findsWidgets); // May appear in both status and category
  expect(find.text('Active'), findsOneWidget);
  expect(find.text('In Storage'), findsOneWidget);
  expect(find.text('To Donate'), findsOneWidget);
});
```

**Step 3: Run tests**

Run: `flutter test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add test/widget_test.dart
git commit -m "test: add status filter tabs test"
```

---

## Task 12: Final Verification

**Step 1: Run all tests**

Run: `flutter test`
Expected: All tests pass

**Step 2: Run the app**

Run: `flutter run -d macos`
Expected: App launches, status tabs visible, lifecycle fields work

**Step 3: Test functionality**

- Add a new toy with lifecycle fields
- Edit an existing toy's condition/status
- Filter by status
- Verify badges appear on cards

**Step 4: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: address any issues found during testing"
```

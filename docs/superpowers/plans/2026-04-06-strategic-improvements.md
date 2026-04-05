# Strategic Improvements (Tasks 9-12) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add child/owner assignment, location autocomplete, backup/restore, and change history to the rePlay toy organizer.

**Architecture:** Four independent features implemented sequentially. Task 9 (owner) and Task 12 (history) require DB schema changes (v4 and v5). Task 10 (location autocomplete) is a pure UI widget. Task 11 (backup) adds a Settings tab and JSON export/import. Each feature produces a working commit.

**Tech Stack:** Flutter, Drift (SQLite), Riverpod, file_picker, share_plus

---

## Feature Order

1. **Task 9: Child/Owner** — schema v4, owner field + filter + UI
2. **Task 10: Location Autocomplete** — reusable widget, no schema change
3. **Task 11: Backup & Restore** — Settings tab, JSON export/import
4. **Task 12: Change History** — schema v5, history table + auto-recording + timeline UI

---

### Task 9a: Owner Column and Schema v4

**Files:**
- Modify: `lib/core/database/tables/toys_table.dart`
- Modify: `lib/core/database/database.dart`
- Regenerate: `lib/core/database/database.g.dart`

- [ ] **Step 1: Add owner column to Toys table**

In `lib/core/database/tables/toys_table.dart`, add after the `status` line in the `Toys` class:

```dart
  TextColumn get owner => text().nullable()();
```

- [ ] **Step 2: Bump schema and add migration**

In `lib/core/database/database.dart`:

Change `schemaVersion` to `4`:
```dart
@override
int get schemaVersion => 4;
```

Add migration block after `if (from < 3)`:
```dart
        if (from < 4) {
          await m.addColumn(toys, toys.owner);
        }
```

Update `@DriftDatabase` annotation — it already has `ToyImages`, no change needed here.

- [ ] **Step 3: Regenerate database code**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Run tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/database/
git commit -m "feat: add owner column to toys table with schema v4 migration"
```

---

### Task 9b: Owner in Provider State

**Files:**
- Modify: `lib/features/inventory/providers/inventory_provider.dart`

- [ ] **Step 1: Add selectedOwner to InventoryState**

Add field:
```dart
  final String? selectedOwner;
```

Constructor param:
```dart
    this.selectedOwner,
```

copyWith param:
```dart
    String? selectedOwner,
```

copyWith body:
```dart
      selectedOwner: selectedOwner ?? this.selectedOwner,
```

- [ ] **Step 2: Add owner filter to filteredToys getter**

After the category filter block and before the search block, add:

```dart
    if (selectedOwner != null && selectedOwner!.isNotEmpty) {
      result = result.where((t) => t.owner == selectedOwner).toList();
    }
```

- [ ] **Step 3: Add owner to search predicate**

In the search block, add after the location line:
```dart
            (t.owner?.toLowerCase().contains(query) ?? false) ||
```

- [ ] **Step 4: Add setOwner method to InventoryNotifier**

```dart
  void setOwner(String? owner) {
    state = state.copyWith(selectedOwner: owner);
  }
```

Update `clearFilters`:
```dart
  void clearFilters() {
    state = state.copyWith(
      selectedCategory: null,
      searchQuery: '',
      selectedStatus: null,
      sortBy: SortOption.newestFirst,
      selectedOwner: null,
    );
  }
```

- [ ] **Step 5: Add owner param to updateToy and addToy**

In `addToy`, add `String? owner` parameter and pass it:
```dart
        owner: Value(owner),
```

In `updateToy`, add `String? owner` parameter and pass it:
```dart
        owner: Value(owner ?? existing.owner),
```

- [ ] **Step 6: Run tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/inventory/providers/inventory_provider.dart
git commit -m "feat: add owner filter and search to inventory provider"
```

---

### Task 9c: Owner Filter Chips Widget

**Files:**
- Create: `lib/features/inventory/widgets/owner_filter_chips.dart`

- [ ] **Step 1: Create OwnerFilterChips**

Create `lib/features/inventory/widgets/owner_filter_chips.dart`:

```dart
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/inventory/widgets/owner_filter_chips.dart
git commit -m "feat: add owner filter chips widget"
```

---

### Task 9d: Owner in Screens

**Files:**
- Modify: `lib/features/inventory/screens/inventory_screen.dart`
- Modify: `lib/features/inventory/widgets/toy_card.dart`
- Modify: `lib/features/capture/screens/capture_screen.dart`
- Modify: `lib/features/inventory/screens/toy_detail_screen.dart`

- [ ] **Step 1: Add owner filter to inventory screen**

In `lib/features/inventory/screens/inventory_screen.dart`, add import:
```dart
import '../widgets/owner_filter_chips.dart';
```

In the `build` method, after the `CategoryFilterChips` widget and before the sort `Padding`, add:

```dart
            const SizedBox(height: 8),
            OwnerFilterChips(
              selectedOwner: inventoryState.selectedOwner,
              toys: inventoryState.toys,
              onOwnerSelected: (owner) {
                ref.read(inventoryProvider.notifier).setOwner(owner);
              },
            ),
```

- [ ] **Step 2: Show owner on toy card**

In `lib/features/inventory/widgets/toy_card.dart`, in the `Column` inside the bottom `Expanded(flex: 2)` section, after the category `Row`, add:

```dart
                        if (toy.owner != null && toy.owner!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  toy.owner!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
```

- [ ] **Step 3: Add owner field to capture screen**

In `lib/features/capture/screens/capture_screen.dart`, add a state field:
```dart
  String? _owner;
  final _ownerController = TextEditingController();
```

Dispose the controller in `dispose()`:
```dart
    _ownerController.dispose();
```

In the `build` method, after `_buildCategoryDropdown(categories)` and its `SizedBox`, add:

```dart
                      TextFormField(
                        controller: _ownerController,
                        decoration: const InputDecoration(
                          labelText: 'Owner (optional)',
                          prefixIcon: Icon(Icons.person),
                          hintText: "e.g., Jake, Emma",
                        ),
                        onChanged: (value) {
                          _owner = value.isNotEmpty ? value : null;
                        },
                      ),
                      const SizedBox(height: 16),
```

In `_saveToy`, add `owner: _owner,` to the `addToy` call.

- [ ] **Step 4: Add owner to detail screen**

In `lib/features/inventory/screens/toy_detail_screen.dart`:

Add `_owner` state and `_ownerController`:
```dart
  String? _owner;
  final _ownerController = TextEditingController();
```

Dispose in `dispose()`:
```dart
    _ownerController.dispose();
```

In the `data:` callback, initialize owner fields when not editing:
```dart
          _owner = toy.owner;
          _ownerController.text = toy.owner ?? '';
```

In `_buildDetails`, after category and before description, add:
```dart
        if (toy.owner != null && toy.owner!.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                toy.owner!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
```

In `_buildEditForm`, after category dropdown, add:
```dart
        const SizedBox(height: 16),
        TextFormField(
          controller: _ownerController,
          decoration: const InputDecoration(
            labelText: 'Owner (optional)',
            prefixIcon: Icon(Icons.person),
          ),
          onChanged: (value) {
            setState(() {
              _owner = value.isNotEmpty ? value : null;
              _hasChanges = true;
            });
          },
        ),
```

In `_saveChanges`, add `owner: _owner,` to the `updateToy` call.

- [ ] **Step 5: Run all tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/inventory/screens/inventory_screen.dart lib/features/inventory/widgets/toy_card.dart lib/features/capture/screens/capture_screen.dart lib/features/inventory/screens/toy_detail_screen.dart
git commit -m "feat: add owner field to inventory, capture, and detail screens"
```

---

### Task 10: Location Autocomplete Widget

**Files:**
- Create: `lib/features/inventory/widgets/location_autocomplete_field.dart`
- Modify: `lib/features/capture/screens/capture_screen.dart`
- Modify: `lib/features/inventory/screens/toy_detail_screen.dart`
- Modify: `lib/features/inventory/screens/inventory_screen.dart`

- [ ] **Step 1: Create LocationAutocompleteField**

Create `lib/features/inventory/widgets/location_autocomplete_field.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/inventory_provider.dart';

class LocationAutocompleteField extends ConsumerWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final InputDecoration? decoration;

  const LocationAutocompleteField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.decoration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);

    return FutureBuilder<List<String>>(
      future: db.getAllLocations(),
      builder: (context, snapshot) {
        final locations = snapshot.data ?? [];

        return Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return const Iterable.empty();
            final query = textEditingValue.text.toLowerCase();
            return locations.where((loc) => loc.toLowerCase().contains(query));
          },
          onSelected: (value) {
            controller.text = value;
            onChanged(value);
          },
          fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
            // Sync the external controller with the autocomplete's internal controller
            if (fieldController.text != controller.text) {
              fieldController.text = controller.text;
            }
            return TextFormField(
              controller: fieldController,
              focusNode: focusNode,
              decoration: decoration ?? const InputDecoration(
                labelText: 'Location (optional)',
                prefixIcon: Icon(Icons.location_on),
                hintText: 'e.g., Playroom shelf, Garage bin 2',
              ),
              onChanged: (value) {
                controller.text = value;
                onChanged(value);
              },
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 2: Replace location fields in capture screen**

In `lib/features/capture/screens/capture_screen.dart`, add import:
```dart
import '../../../features/inventory/widgets/location_autocomplete_field.dart';
```

Replace the location `TextFormField` in the lifecycle section with:
```dart
                LocationAutocompleteField(
                  controller: _locationController,
                  onChanged: (value) {
                    _location = value.isNotEmpty ? value : null;
                  },
                ),
```

- [ ] **Step 3: Replace location field in detail screen**

In `lib/features/inventory/screens/toy_detail_screen.dart`, add import:
```dart
import '../widgets/location_autocomplete_field.dart';
```

Replace the location `TextFormField` in `_buildLifecycleSection` with:
```dart
              LocationAutocompleteField(
                controller: _locationController,
                onChanged: (value) {
                  setState(() {
                    _location = value.isNotEmpty ? value : null;
                    _hasChanges = true;
                  });
                },
              ),
```

- [ ] **Step 4: Replace location field in bulk dialog**

In `lib/features/inventory/screens/inventory_screen.dart`, add import:
```dart
import '../widgets/location_autocomplete_field.dart';
```

In `_showLocationDialog`, replace the `TextField` with:
```dart
            content: LocationAutocompleteField(
              controller: locationController,
              onChanged: (_) {},
              decoration: const InputDecoration(
                hintText: 'Enter location...',
              ),
            ),
```

- [ ] **Step 5: Run all tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/inventory/widgets/location_autocomplete_field.dart lib/features/capture/screens/capture_screen.dart lib/features/inventory/screens/toy_detail_screen.dart lib/features/inventory/screens/inventory_screen.dart
git commit -m "feat: add location autocomplete to all location fields"
```

---

### Task 11a: Backup Service with Tests

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/services/backup_service.dart`
- Create: `test/backup_service_test.dart`

- [ ] **Step 1: Add file_picker dependency**

In `pubspec.yaml`, add under `# Sharing`:
```yaml
  file_picker: ^8.1.6
```

Run: `flutter pub get`

- [ ] **Step 2: Write failing tests**

Create `test/backup_service_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:replay/core/database/database.dart';
import 'package:replay/core/services/backup_service.dart';

void main() {
  late BackupService backupService;

  setUp(() {
    backupService = BackupService();
  });

  group('exportToJson', () {
    test('produces valid JSON with correct structure', () {
      final toys = [
        Toy(
          id: 1, name: 'Buzz Lightyear', description: 'Space ranger',
          imagePath: '/img/1.jpg', thumbnailPath: null, category: 'Action Figures',
          aiLabels: '["action figure"]', createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 1, 15), condition: 'excellent',
          location: 'Bedroom', status: 'active', owner: 'Jake',
        ),
      ];

      final json = backupService.exportToJson(toys);
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['version'], 1);
      expect(decoded['exportedAt'], isNotNull);
      expect(decoded['toys'], isList);
      expect((decoded['toys'] as List).length, 1);

      final toy = (decoded['toys'] as List).first as Map<String, dynamic>;
      expect(toy['name'], 'Buzz Lightyear');
      expect(toy['category'], 'Action Figures');
      expect(toy['owner'], 'Jake');
      expect(toy.containsKey('imagePath'), false);
      expect(toy.containsKey('id'), false);
    });
  });

  group('parseImport', () {
    test('parses valid JSON and returns toy data', () {
      final json = jsonEncode({
        'version': 1,
        'exportedAt': '2026-04-03T12:00:00Z',
        'toys': [
          {
            'name': 'Teddy Bear',
            'category': 'Stuffed Animals',
            'condition': 'good',
            'status': 'active',
            'createdAt': '2026-01-14T00:00:00.000',
          },
        ],
      });

      final result = backupService.parseImport(json);

      expect(result.length, 1);
      expect(result.first['name'], 'Teddy Bear');
    });

    test('handles missing optional fields', () {
      final json = jsonEncode({
        'version': 1,
        'toys': [
          {'name': 'Simple Toy', 'createdAt': '2026-01-01T00:00:00.000'},
        ],
      });

      final result = backupService.parseImport(json);

      expect(result.length, 1);
      expect(result.first['name'], 'Simple Toy');
      expect(result.first['category'], 'Other');
    });

    test('throws on invalid version', () {
      final json = jsonEncode({'version': 999, 'toys': []});

      expect(() => backupService.parseImport(json), throwsException);
    });
  });

  group('findDuplicates', () {
    test('identifies duplicates by name and createdAt', () {
      final existing = [
        Toy(
          id: 1, name: 'Buzz', description: null, imagePath: '',
          thumbnailPath: null, category: 'Other', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 15), updatedAt: DateTime(2026, 1, 15),
          condition: 'good', location: null, status: 'active', owner: null,
        ),
      ];

      final incoming = [
        {'name': 'Buzz', 'createdAt': '2026-01-15T00:00:00.000'},
        {'name': 'New Toy', 'createdAt': '2026-02-01T00:00:00.000'},
      ];

      final nonDuplicates = backupService.filterDuplicates(incoming, existing);

      expect(nonDuplicates.length, 1);
      expect(nonDuplicates.first['name'], 'New Toy');
    });
  });
}
```

- [ ] **Step 3: Implement BackupService**

Create `lib/core/services/backup_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../database/database.dart';

class BackupService {
  String exportToJson(List<Toy> toys) {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'toys': toys.map((toy) => {
        'name': toy.name,
        'description': toy.description,
        'category': toy.category,
        'condition': toy.condition,
        'location': toy.location,
        'status': toy.status,
        'owner': toy.owner,
        'aiLabels': toy.aiLabels,
        'createdAt': toy.createdAt.toIso8601String(),
        'updatedAt': toy.updatedAt.toIso8601String(),
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<String> writeBackupFile(List<Toy> toys) async {
    final content = exportToJson(toys);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/replay_backup_$timestamp.json');
    await file.writeAsString(content);
    return file.path;
  }

  List<Map<String, dynamic>> parseImport(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final version = data['version'] as int?;

    if (version == null || version > 1) {
      throw Exception('Unsupported backup version: $version');
    }

    final toys = (data['toys'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return toys.map((toy) {
      return {
        'name': toy['name'] ?? 'Unknown',
        'description': toy['description'],
        'category': toy['category'] ?? 'Other',
        'condition': toy['condition'] ?? 'good',
        'location': toy['location'],
        'status': toy['status'] ?? 'active',
        'owner': toy['owner'],
        'aiLabels': toy['aiLabels'] ?? '[]',
        'createdAt': toy['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': toy['updatedAt'] ?? DateTime.now().toIso8601String(),
      };
    }).toList();
  }

  List<Map<String, dynamic>> filterDuplicates(
    List<Map<String, dynamic>> incoming,
    List<Toy> existing,
  ) {
    final existingKeys = existing
        .map((t) => '${t.name}|${t.createdAt.toIso8601String()}')
        .toSet();

    return incoming.where((toy) {
      final key = '${toy['name']}|${toy['createdAt']}';
      return !existingKeys.contains(key);
    }).toList();
  }
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/backup_service_test.dart`
Expected: All PASS.

- [ ] **Step 5: Add backupServiceProvider**

In `lib/core/services/services_provider.dart`, add import:
```dart
import 'backup_service.dart';
```

Add provider:
```dart
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});
```

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/services/backup_service.dart lib/core/services/services_provider.dart test/backup_service_test.dart
git commit -m "feat: add backup service with JSON export/import"
```

---

### Task 11b: Settings Screen and Nav Tab

**Files:**
- Create: `lib/features/settings/screens/settings_screen.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Create SettingsScreen**

Create `lib/features/settings/screens/settings_screen.dart`:

```dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/services_provider.dart';
import '../../inventory/providers/inventory_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Export Backup'),
            subtitle: const Text('Save toy inventory as JSON file'),
            onTap: () => _exportBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Backup'),
            subtitle: const Text('Restore toys from a JSON backup file'),
            onTap: () => _importBackup(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final inventoryState = ref.read(inventoryProvider);
    final backupService = ref.read(backupServiceProvider);

    if (inventoryState.toys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No toys to export')),
      );
      return;
    }

    final filePath = await backupService.writeBackupFile(inventoryState.toys);
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'rePlay Backup',
    );
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path;
    if (filePath == null) return;

    try {
      final content = await File(filePath).readAsString();
      final backupService = ref.read(backupServiceProvider);
      final db = ref.read(databaseProvider);

      final incoming = backupService.parseImport(content);
      final existingToys = await db.getAllToys();
      final newToys = backupService.filterDuplicates(incoming, existingToys);

      int imported = 0;
      for (final toyData in newToys) {
        await db.insertToy(ToysCompanion.insert(
          name: toyData['name'] as String,
          description: Value(toyData['description'] as String?),
          imagePath: '',
          category: Value(toyData['category'] as String),
          aiLabels: Value(toyData['aiLabels'] as String),
          condition: Value(toyData['condition'] as String),
          location: Value(toyData['location'] as String?),
          status: Value(toyData['status'] as String),
          owner: Value(toyData['owner'] as String?),
        ));
        imported++;
      }

      await ref.read(inventoryProvider.notifier).refresh();

      if (context.mounted) {
        final skipped = incoming.length - imported;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $imported toys ($skipped skipped as duplicates)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: ${e.toString()}')),
        );
      }
    }
  }
}
```

Note: Requires `import 'package:drift/drift.dart' show Value;` at the top.

- [ ] **Step 2: Add Settings tab to app.dart**

In `lib/app.dart`, add import:
```dart
import 'features/settings/screens/settings_screen.dart';
```

Add `SettingsScreen()` to the `_screens` list:
```dart
  static const _screens = <Widget>[
    InventoryScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];
```

Add the third destination to `NavigationBar`:
```dart
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
```

- [ ] **Step 3: Run all tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/screens/settings_screen.dart lib/app.dart
git commit -m "feat: add settings screen with backup and restore"
```

---

### Task 12a: ToyHistory Table and Schema v5

**Files:**
- Modify: `lib/core/database/tables/toys_table.dart`
- Modify: `lib/core/database/database.dart`
- Regenerate: `lib/core/database/database.g.dart`

- [ ] **Step 1: Add ToyHistory table**

In `lib/core/database/tables/toys_table.dart`, add after `ToyImages`:

```dart
class ToyHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get toyId => integer()();
  TextColumn get field => text()();
  TextColumn get oldValue => text()();
  TextColumn get newValue => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

- [ ] **Step 2: Register table, bump schema, add migration**

In `lib/core/database/database.dart`:

Update annotation:
```dart
@DriftDatabase(tables: [Toys, Categories, ToyImages, ToyHistory])
```

Bump schema:
```dart
@override
int get schemaVersion => 5;
```

Add migration:
```dart
        if (from < 5) {
          await m.createTable(toyHistory);
        }
```

- [ ] **Step 3: Add ToyHistory CRUD methods**

Add to `AppDatabase`:

```dart
  // ToyHistory operations
  Future<List<ToyHistoryData>> getHistoryForToy(int toyId) {
    return (select(toyHistory)
          ..where((t) => t.toyId.equals(toyId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<int> insertHistory(ToyHistoryCompanion entry) {
    return into(toyHistory).insert(entry);
  }

  Future<int> deleteHistoryForToy(int toyId) {
    return (delete(toyHistory)..where((t) => t.toyId.equals(toyId))).go();
  }
```

- [ ] **Step 4: Regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/database/
git commit -m "feat: add ToyHistory table with schema v5 migration"
```

---

### Task 12b: Auto-Record History in Provider

**Files:**
- Modify: `lib/features/inventory/providers/inventory_provider.dart`

- [ ] **Step 1: Add history recording to updateToy**

In `InventoryNotifier.updateToy()`, after fetching the existing toy (`final existing = await _db.getToyById(id);`) and before performing the update, add:

```dart
      // Record history for status and condition changes
      if (status != null && status != existing.status) {
        await _db.insertHistory(ToyHistoryCompanion.insert(
          toyId: id,
          field: 'status',
          oldValue: existing.status,
          newValue: status,
        ));
      }
      if (condition != null && condition != existing.condition) {
        await _db.insertHistory(ToyHistoryCompanion.insert(
          toyId: id,
          field: 'condition',
          oldValue: existing.condition,
          newValue: condition,
        ));
      }
```

- [ ] **Step 2: Add history cleanup to deleteToy**

In `deleteToy()`, before `await _db.deleteToy(id);`, add:

```dart
      await _db.deleteHistoryForToy(id);
```

- [ ] **Step 3: Add toyHistoryProvider**

At the bottom of the file:

```dart
// History for a toy
final toyHistoryProvider = FutureProvider.family<List<ToyHistoryData>, int>((ref, toyId) async {
  final db = ref.watch(databaseProvider);
  return db.getHistoryForToy(toyId);
});
```

- [ ] **Step 4: Run tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/inventory/providers/inventory_provider.dart
git commit -m "feat: auto-record status and condition history"
```

---

### Task 12c: History Timeline on Detail Screen

**Files:**
- Modify: `lib/features/inventory/screens/toy_detail_screen.dart`

- [ ] **Step 1: Add history section to view mode**

In `_buildDetails`, at the end of the Column children (after the "Added on" date), add:

```dart
        const SizedBox(height: 24),
        _buildHistorySection(),
```

- [ ] **Step 2: Implement _buildHistorySection**

Add this method to `_ToyDetailScreenState`:

```dart
  Widget _buildHistorySection() {
    final historyAsync = ref.watch(toyHistoryProvider(widget.toyId));

    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (history) {
        if (history.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'History',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...history.map((entry) {
              final date = '${entry.createdAt.month}/${entry.createdAt.day}';
              final fieldLabel = entry.field == 'status' ? 'Status' : 'Condition';
              final oldLabel = entry.field == 'status'
                  ? AppConstants.getStatusLabel(entry.oldValue)
                  : AppConstants.getConditionLabel(entry.oldValue);
              final newLabel = entry.field == 'status'
                  ? AppConstants.getStatusLabel(entry.newValue)
                  : AppConstants.getConditionLabel(entry.newValue);

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$fieldLabel: $oldLabel → $newLabel',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
```

- [ ] **Step 3: Run all tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: No new issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/inventory/screens/toy_detail_screen.dart
git commit -m "feat: add history timeline to toy detail screen"
```

---

### Task 13: Final Verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No new issues.

- [ ] **Step 3: Fix any issues and commit**

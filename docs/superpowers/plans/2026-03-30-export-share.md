# Export & Share Lists Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to export the current filtered toy list as plain text or CSV via the native share sheet.

**Architecture:** A standalone `ExportService` with pure logic for text/CSV generation, a share button in the inventory AppBar, and `share_plus` for native sharing. The service is easily unit-testable since it has no UI dependencies.

**Tech Stack:** Flutter, share_plus, path_provider

---

## File Map

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `share_plus` dependency |
| `lib/core/services/export_service.dart` | New: text and CSV generation |
| `lib/core/services/services_provider.dart` | Add `exportServiceProvider` |
| `lib/features/inventory/screens/inventory_screen.dart` | Add share button to normal-mode AppBar |
| `test/export_service_test.dart` | New: unit tests for export formatting |

---

### Task 1: Add share_plus Dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add share_plus to pubspec.yaml**

In `pubspec.yaml`, add under the `# Utilities` section after `uuid: ^4.2.2`:

```yaml
  share_plus: ^10.1.4
```

- [ ] **Step 2: Install dependencies**

Run: `flutter pub get`
Expected: Dependencies resolved successfully.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add share_plus dependency"
```

---

### Task 2: ExportService with Tests

**Files:**
- Create: `lib/core/services/export_service.dart`
- Create: `test/export_service_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/export_service_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:replay/core/database/database.dart';
import 'package:replay/core/services/export_service.dart';

void main() {
  late ExportService exportService;

  setUp(() {
    exportService = ExportService();
  });

  group('generateTextList', () {
    test('produces correct format with filter label and toy data', () {
      final toys = [
        Toy(
          id: 1, name: 'Buzz Lightyear', description: null, imagePath: '',
          thumbnailPath: null, category: 'Action Figures', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 15), updatedAt: DateTime(2026, 1, 15),
          condition: 'excellent', location: 'Bedroom', status: 'active',
        ),
        Toy(
          id: 2, name: 'Teddy Bear', description: null, imagePath: '',
          thumbnailPath: null, category: 'Stuffed Animals', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 14), updatedAt: DateTime(2026, 1, 14),
          condition: 'fair', location: 'Playroom', status: 'toDonate',
        ),
      ];

      final result = exportService.generateTextList(toys, 'All');

      expect(result, contains('rePlay Toy List'));
      expect(result, contains('All'));
      expect(result, contains('2 toys'));
      expect(result, contains('1. Buzz Lightyear'));
      expect(result, contains('Excellent'));
      expect(result, contains('Bedroom'));
      expect(result, contains('2. Teddy Bear'));
    });

    test('handles toys with null location', () {
      final toys = [
        Toy(
          id: 1, name: 'Puzzle', description: null, imagePath: '',
          thumbnailPath: null, category: 'Puzzles', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 15), updatedAt: DateTime(2026, 1, 15),
          condition: 'good', location: null, status: 'active',
        ),
      ];

      final result = exportService.generateTextList(toys, 'Active');

      expect(result, contains('1. Puzzle'));
      expect(result, contains('Good'));
      expect(result, isNot(contains('null')));
    });
  });

  group('generateCsvContent', () {
    test('produces valid CSV with headers and data', () {
      final toys = [
        Toy(
          id: 1, name: 'Buzz Lightyear', description: null, imagePath: '',
          thumbnailPath: null, category: 'Action Figures', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 15), updatedAt: DateTime(2026, 1, 15),
          condition: 'excellent', location: 'Bedroom', status: 'active',
        ),
      ];

      final result = exportService.generateCsvContent(toys);
      final lines = result.split('\n');

      expect(lines[0], 'Name,Category,Condition,Location,Status,Date Added');
      expect(lines[1], contains('Buzz Lightyear'));
      expect(lines[1], contains('Action Figures'));
      expect(lines[1], contains('Excellent'));
      expect(lines[1], contains('Bedroom'));
      expect(lines[1], contains('Active'));
      expect(lines[1], contains('2026-01-15'));
    });

    test('quotes values containing commas', () {
      final toys = [
        Toy(
          id: 1, name: 'LEGO Set, Large', description: null, imagePath: '',
          thumbnailPath: null, category: 'Building Blocks', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 15), updatedAt: DateTime(2026, 1, 15),
          condition: 'good', location: 'Shelf 1, Room 2', status: 'active',
        ),
      ];

      final result = exportService.generateCsvContent(toys);

      expect(result, contains('"LEGO Set, Large"'));
      expect(result, contains('"Shelf 1, Room 2"'));
    });

    test('handles null location in CSV', () {
      final toys = [
        Toy(
          id: 1, name: 'Ball', description: null, imagePath: '',
          thumbnailPath: null, category: 'Outdoor', aiLabels: '[]',
          createdAt: DateTime(2026, 3, 1), updatedAt: DateTime(2026, 3, 1),
          condition: 'fair', location: null, status: 'active',
        ),
      ];

      final result = exportService.generateCsvContent(toys);
      final lines = result.split('\n');

      // Location field should be empty, not "null"
      expect(lines[1], isNot(contains('null')));
      expect(lines[1], contains('Ball,Outdoor,Fair,,Active'));
    });
  });

  group('writeCsvFile', () {
    test('writes CSV to temp file and returns path', () async {
      final toys = [
        Toy(
          id: 1, name: 'Test Toy', description: null, imagePath: '',
          thumbnailPath: null, category: 'Other', aiLabels: '[]',
          createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1),
          condition: 'good', location: null, status: 'active',
        ),
      ];

      final path = await exportService.writeCsvFile(toys);

      expect(path, endsWith('.csv'));
      final file = File(path);
      expect(await file.exists(), true);
      final content = await file.readAsString();
      expect(content, contains('Test Toy'));

      // Cleanup
      await file.delete();
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/export_service_test.dart`
Expected: FAIL — `ExportService` doesn't exist.

- [ ] **Step 3: Implement ExportService**

Create `lib/core/services/export_service.dart`:

```dart
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../database/database.dart';

class ExportService {
  String generateTextList(List<Toy> toys, String filterLabel) {
    final buffer = StringBuffer();
    buffer.writeln('rePlay Toy List ($filterLabel — ${toys.length} toys)');
    buffer.writeln();

    for (var i = 0; i < toys.length; i++) {
      final toy = toys[i];
      final conditionLabel = AppConstants.getConditionLabel(toy.condition);
      final parts = <String>[
        '${i + 1}. ${toy.name}',
        conditionLabel,
      ];
      if (toy.location != null && toy.location!.isNotEmpty) {
        parts.add(toy.location!);
      }
      buffer.writeln(parts.join(' — '));
    }

    return buffer.toString().trimRight();
  }

  String generateCsvContent(List<Toy> toys) {
    final buffer = StringBuffer();
    buffer.writeln('Name,Category,Condition,Location,Status,Date Added');

    for (final toy in toys) {
      final name = _csvEscape(toy.name);
      final category = _csvEscape(toy.category);
      final condition = _csvEscape(AppConstants.getConditionLabel(toy.condition));
      final location = _csvEscape(toy.location ?? '');
      final status = _csvEscape(AppConstants.getStatusLabel(toy.status));
      final date = '${toy.createdAt.year}-${toy.createdAt.month.toString().padLeft(2, '0')}-${toy.createdAt.day.toString().padLeft(2, '0')}';
      buffer.writeln('$name,$category,$condition,$location,$status,$date');
    }

    return buffer.toString().trimRight();
  }

  Future<String> writeCsvFile(List<Toy> toys) async {
    final content = generateCsvContent(toys);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/replay_export_$timestamp.csv');
    await file.writeAsString(content);
    return file.path;
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/export_service_test.dart`
Expected: All PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/export_service.dart test/export_service_test.dart
git commit -m "feat: add export service with text and CSV generation"
```

---

### Task 3: Export Service Provider

**Files:**
- Modify: `lib/core/services/services_provider.dart`

- [ ] **Step 1: Read the current file**

Read `lib/core/services/services_provider.dart` to see existing providers.

- [ ] **Step 2: Add exportServiceProvider**

Add the import at the top:

```dart
import 'export_service.dart';
```

Add the provider:

```dart
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});
```

- [ ] **Step 3: Run tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/core/services/services_provider.dart
git commit -m "feat: add exportServiceProvider"
```

---

### Task 4: Share Button in Inventory Screen

**Files:**
- Modify: `lib/features/inventory/screens/inventory_screen.dart`

- [ ] **Step 1: Add imports**

Add at the top of `inventory_screen.dart`:

```dart
import 'package:share_plus/share_plus.dart';

import '../../../core/services/services_provider.dart';
```

- [ ] **Step 2: Add share button to the normal-mode AppBar**

In the `build` method, the normal-mode AppBar currently has no actions:

```dart
          : AppBar(
              title: const Text('rePlay'),
            ),
```

Replace with:

```dart
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
```

- [ ] **Step 3: Add _showExportSheet method**

Add this method to `_InventoryScreenState`:

```dart
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
```

Note: `Toy` type is already available via the `inventory_provider.dart` import which re-exports from `database.dart`. `AppConstants` is already imported.

- [ ] **Step 4: Run all tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 5: Run flutter analyze**

Run: `flutter analyze`
Expected: No new issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/inventory/screens/inventory_screen.dart
git commit -m "feat: add export/share button to inventory screen"
```

---

### Task 5: Final Verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No new analysis issues.

- [ ] **Step 3: Fix any issues found**

If there are issues, fix and commit.

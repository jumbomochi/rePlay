# Lower Priority Improvements (Tasks 13-17) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add list view toggle, custom categories, onboarding flow, barcode scanning, and desktop parity info to the rePlay app.

**Architecture:** Five independent features. No shared schema changes. Tasks 15 and 16 add new dependencies. Each produces a standalone commit.

**Tech Stack:** Flutter, Riverpod, Drift, shared_preferences, mobile_scanner

---

## File Map

| Task | Files |
|------|-------|
| 13 | `inventory_provider.dart`, `toy_grid.dart`, `toy_list_item.dart` (new), `inventory_screen.dart` |
| 14 | `database.dart`, `manage_categories_screen.dart` (new), `settings_screen.dart` |
| 15 | `pubspec.yaml`, `onboarding_screen.dart` (new), `main.dart` |
| 16 | `pubspec.yaml`, `barcode_lookup_service.dart` (new), `barcode_scanner_screen.dart` (new), `capture_screen.dart` |
| 17 | `capture_screen.dart` |

---

### Task 13: List View Toggle

**Files:**
- Modify: `lib/features/inventory/providers/inventory_provider.dart`
- Create: `lib/features/inventory/widgets/toy_list_item.dart`
- Modify: `lib/features/inventory/widgets/toy_grid.dart`
- Modify: `lib/features/inventory/screens/inventory_screen.dart`

- [ ] **Step 1: Add isListView to InventoryState**

In `lib/features/inventory/providers/inventory_provider.dart`, add to `InventoryState`:

Field: `final bool isListView;`
Constructor: `this.isListView = false,`
copyWith param: `bool? isListView,`
copyWith body: `isListView: isListView ?? this.isListView,`

Add method to `InventoryNotifier`:
```dart
  void toggleViewMode() {
    state = state.copyWith(isListView: !state.isListView);
  }
```

- [ ] **Step 2: Create ToyListItem widget**

Create `lib/features/inventory/widgets/toy_list_item.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database.dart';

class ToyListItem extends StatelessWidget {
  final Toy toy;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isMultiSelectMode;

  const ToyListItem({
    super.key,
    required this.toy,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isMultiSelectMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbPath = toy.thumbnailPath ?? toy.imagePath;

    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: FutureBuilder<bool>(
            future: File(thumbPath).exists(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Image.file(File(thumbPath), fit: BoxFit.cover);
              }
              return Container(
                color: Colors.grey[200],
                child: Icon(Icons.toys, size: 24, color: Colors.grey[400]),
              );
            },
          ),
        ),
      ),
      title: Text(toy.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          Icon(AppConstants.getCategoryIcon(toy.category), size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(toy.category, style: theme.textTheme.bodySmall),
          if (toy.owner != null && toy.owner!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Icon(Icons.person, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 2),
            Text(toy.owner!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
      trailing: isMultiSelectMode
          ? Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            )
          : Text(
              AppConstants.getConditionLabel(toy.condition),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      selected: isSelected && isMultiSelectMode,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
```

- [ ] **Step 3: Update ToyGrid to support list view**

In `lib/features/inventory/widgets/toy_grid.dart`, add import:
```dart
import 'toy_list_item.dart';
```

Add parameter:
```dart
  final bool isListView;
```

Constructor:
```dart
    this.isListView = false,
```

Replace the `GridView.builder` block (the `return GridView.builder(...)` at the end of `build`) with:

```dart
    if (isListView) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: toys.length,
        itemBuilder: (context, index) {
          final toy = toys[index];
          return ToyListItem(
            toy: toy,
            onTap: onToyTap != null ? () => onToyTap!(toy) : null,
            onLongPress: onToyLongPress != null ? () => onToyLongPress!(toy) : null,
            isSelected: selectedToyIds.contains(toy.id),
            isMultiSelectMode: isMultiSelectMode,
          );
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: toys.length,
      itemBuilder: (context, index) {
        final toy = toys[index];
        return ToyCard(
          toy: toy,
          onTap: onToyTap != null ? () => onToyTap!(toy) : null,
          onLongPress: onToyLongPress != null ? () => onToyLongPress!(toy) : null,
          isSelected: selectedToyIds.contains(toy.id),
          isMultiSelectMode: isMultiSelectMode,
        );
      },
    );
```

- [ ] **Step 4: Add toggle button and pass isListView to ToyGrid in inventory screen**

In `lib/features/inventory/screens/inventory_screen.dart`, find the sort dropdown `Padding` row. Add a toggle button before the `DropdownButton`:

```dart
                  IconButton(
                    icon: Icon(inventoryState.isListView ? Icons.grid_view : Icons.view_list),
                    tooltip: inventoryState.isListView ? 'Grid view' : 'List view',
                    onPressed: () {
                      ref.read(inventoryProvider.notifier).toggleViewMode();
                    },
                  ),
```

Pass `isListView` to `ToyGrid`:
```dart
                isListView: inventoryState.isListView,
```

- [ ] **Step 5: Run tests, commit**

Run: `flutter test`

```bash
git add lib/features/inventory/providers/inventory_provider.dart lib/features/inventory/widgets/toy_list_item.dart lib/features/inventory/widgets/toy_grid.dart lib/features/inventory/screens/inventory_screen.dart
git commit -m "feat: add list view toggle to inventory screen"
```

---

### Task 14: Custom Categories

**Files:**
- Modify: `lib/core/database/database.dart`
- Create: `lib/features/settings/screens/manage_categories_screen.dart`
- Modify: `lib/features/settings/screens/settings_screen.dart`

- [ ] **Step 1: Add category CRUD methods to database**

In `lib/core/database/database.dart`, add after existing category operations:

```dart
  Future<int> insertCategory(String name) {
    return into(categories).insert(CategoriesCompanion.insert(
      name: name,
      iconName: const Value('category'),
      sortOrder: Value(100),
    ));
  }

  Future<int> deleteCategoryById(int id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  Future<int> countToysByCategory(String categoryName) async {
    final count = countAll();
    final query = selectOnly(toys)
      ..addColumns([count])
      ..where(toys.category.equals(categoryName));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
```

- [ ] **Step 2: Create ManageCategoriesScreen**

Create `lib/features/settings/screens/manage_categories_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../categories/providers/categories_provider.dart';
import '../../inventory/providers/inventory_provider.dart';

class ManageCategoriesScreen extends ConsumerStatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  ConsumerState<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends ConsumerState<ManageCategoriesScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'New category name',
                      prefixIcon: Icon(Icons.add),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addCategory,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (categories) {
                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ListTile(
                      leading: Icon(AppConstants.getCategoryIcon(category.name)),
                      title: Text(category.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(category.id, category.name),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final db = ref.read(databaseProvider);
    await db.insertCategory(name);
    _nameController.clear();
    ref.invalidate(categoriesProvider);
  }

  void _confirmDelete(int id, String name) async {
    final db = ref.read(databaseProvider);
    final toyCount = await db.countToysByCategory(name);

    if (!mounted) return;

    final message = toyCount > 0
        ? '"$name" has $toyCount toys assigned. Delete anyway?'
        : 'Delete category "$name"?';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await db.deleteCategoryById(id);
              ref.invalidate(categoriesProvider);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Add Manage Categories to settings screen**

In `lib/features/settings/screens/settings_screen.dart`, add import:
```dart
import 'manage_categories_screen.dart';
```

In the `ListView` children, after the Import Backup `ListTile`, add:

```dart
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Customization', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manage Categories'),
            subtitle: const Text('Add or remove toy categories'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
              );
            },
          ),
```

- [ ] **Step 4: Run tests, commit**

Run: `flutter test`

```bash
git add lib/core/database/database.dart lib/features/settings/screens/manage_categories_screen.dart lib/features/settings/screens/settings_screen.dart
git commit -m "feat: add custom category management in settings"
```

---

### Task 15: Onboarding Flow

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/onboarding/screens/onboarding_screen.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add shared_preferences dependency**

In `pubspec.yaml`, add under `# Utilities` after `uuid`:
```yaml
  shared_preferences: ^2.3.4
```

Run: `flutter pub get`

- [ ] **Step 2: Create OnboardingScreen**

Create `lib/features/onboarding/screens/onboarding_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.toys,
      title: 'Welcome to rePlay',
      subtitle: 'Organize your family\'s toy collection',
    ),
    _OnboardingPage(
      icon: Icons.camera_alt,
      title: 'Capture',
      subtitle: 'Take a photo and let AI identify your toys',
    ),
    _OnboardingPage(
      icon: Icons.filter_list,
      title: 'Organize',
      subtitle: 'Track status, condition, and location.\nExport lists when it\'s time to donate or sell.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: const Text('Skip'),
                ),
              )
            else
              const SizedBox(height: 48),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page.icon,
                          size: 100,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            if (_currentPage == _pages.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: FilledButton(
                  onPressed: _completeOnboarding,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Get Started'),
                ),
              )
            else
              const SizedBox(height: 48),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
```

- [ ] **Step 3: Update main.dart to check onboarding**

Replace `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/onboarding/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env').catchError((_) {});
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    ProviderScope(
      child: onboardingComplete
          ? const RePlayApp()
          : _OnboardingWrapper(),
    ),
  );
}

class _OnboardingWrapper extends StatefulWidget {
  @override
  State<_OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<_OnboardingWrapper> {
  bool _showApp = false;

  @override
  Widget build(BuildContext context) {
    if (_showApp) return const RePlayApp();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen(
        onComplete: () => setState(() => _showApp = true),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests, commit**

Run: `flutter pub get && flutter test`

```bash
git add pubspec.yaml pubspec.lock lib/features/onboarding/screens/onboarding_screen.dart lib/main.dart
git commit -m "feat: add onboarding flow for first-time users"
```

---

### Task 16: Barcode/UPC Scanning

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/services/barcode_lookup_service.dart`
- Create: `lib/features/capture/screens/barcode_scanner_screen.dart`
- Modify: `lib/features/capture/screens/capture_screen.dart`

- [ ] **Step 1: Add mobile_scanner dependency**

In `pubspec.yaml`, add under `# Camera & Images` after `image`:
```yaml
  mobile_scanner: ^6.0.5
```

Run: `flutter pub get`

- [ ] **Step 2: Create BarcodeLookupService**

Create `lib/core/services/barcode_lookup_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';

class BarcodeLookupService {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  Future<String?> lookupBarcode(String barcode) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$_baseUrl/$barcode.json'));
      final response = await request.close().timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (data['status'] != 1) return null;

      final product = data['product'] as Map<String, dynamic>?;
      return product?['product_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 3: Create BarcodeScannerScreen**

Create `lib/features/capture/screens/barcode_scanner_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_hasScanned) return;
          final barcode = capture.barcodes.firstOrNull;
          if (barcode?.rawValue != null) {
            _hasScanned = true;
            Navigator.of(context).pop(barcode!.rawValue);
          }
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Add barcode option to capture screen**

In `lib/features/capture/screens/capture_screen.dart`, add imports:
```dart
import '../../../core/services/barcode_lookup_service.dart';
import 'barcode_scanner_screen.dart';
```

In `_showImageSourceDialog`, add a third `ListTile` after "Choose from Gallery" and before the closing `]`:

```dart
              if (Platform.isIOS || Platform.isAndroid)
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text('Scan Barcode'),
                  onTap: () {
                    Navigator.pop(context);
                    _scanBarcode();
                  },
                ),
```

Add the `_scanBarcode` method:

```dart
  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Looking up barcode $barcode...')),
    );

    final lookupService = BarcodeLookupService();
    final productName = await lookupService.lookupBarcode(barcode);

    if (!mounted) return;

    if (productName != null && productName.isNotEmpty) {
      setState(() {
        _nameController.text = productName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Found: $productName')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not found. Enter name manually.')),
      );
    }
  }
```

- [ ] **Step 5: Run tests, commit**

Run: `flutter pub get && flutter test`

```bash
git add pubspec.yaml pubspec.lock lib/core/services/barcode_lookup_service.dart lib/features/capture/screens/barcode_scanner_screen.dart lib/features/capture/screens/capture_screen.dart
git commit -m "feat: add barcode scanning and product lookup"
```

---

### Task 17: Desktop Parity Info Banner

**Files:**
- Modify: `lib/features/capture/screens/capture_screen.dart`

- [ ] **Step 1: Add desktop info banner state**

In `_CaptureScreenState`, add:
```dart
  bool _showDesktopBanner = !Platform.isIOS && !Platform.isAndroid;
```

- [ ] **Step 2: Add banner to build method**

In the `build` method, at the top of the `Column` children (inside the `Form`, before `_buildImageSection()`), add:

```dart
                    if (_showDesktopBanner) ...[
                      MaterialBanner(
                        content: const Text(
                          'Running on desktop — AI labels and barcode scanning require a mobile device. Use "Identify with AI" for toy recognition.',
                        ),
                        leading: const Icon(Icons.info_outline),
                        actions: [
                          TextButton(
                            onPressed: () => setState(() => _showDesktopBanner = false),
                            child: const Text('Dismiss'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
```

- [ ] **Step 3: Run tests, commit**

Run: `flutter test`

```bash
git add lib/features/capture/screens/capture_screen.dart
git commit -m "feat: add desktop parity info banner on capture screen"
```

---

### Task 18: Final Verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No new issues.

- [ ] **Step 3: Fix any issues and commit**

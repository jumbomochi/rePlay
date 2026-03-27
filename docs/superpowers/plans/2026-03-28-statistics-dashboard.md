# Statistics Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a statistics dashboard as a second tab in the app via bottom navigation, showing total count, status breakdown, recently added toys, and toys needing attention.

**Architecture:** Convert `RePlayApp` to use a `BottomNavigationBar` with two tabs (Inventory, Stats). The stats screen is a `ConsumerWidget` that derives all data from the existing `inventoryProvider` — no new database queries. Each stat section is an isolated widget in its own file.

**Tech Stack:** Flutter, Riverpod, Material Design 3

---

## File Map

| File | Change |
|------|--------|
| `lib/app.dart` | Replace `StatelessWidget` with `StatefulWidget`, add `BottomNavigationBar`, manage tab index |
| `lib/features/stats/screens/stats_screen.dart` | New: scrollable column assembling the 4 stat cards |
| `lib/features/stats/widgets/hero_count_card.dart` | New: large centered total toy count |
| `lib/features/stats/widgets/status_breakdown_card.dart` | New: stacked bar + legend |
| `lib/features/stats/widgets/recently_added_card.dart` | New: last 5 toys with relative time |
| `lib/features/stats/widgets/needs_attention_card.dart` | New: poor/broken toys list |
| `test/stats_screen_test.dart` | New: widget tests for stats screen |
| `test/widget_test.dart` | Update: existing tests that hardcode `InventoryScreen` as `home` still work since `InventoryScreen` is unchanged |

---

### Task 1: Bottom Navigation in app.dart

**Files:**
- Modify: `lib/app.dart`
- Create: `lib/features/stats/screens/stats_screen.dart` (placeholder)

- [ ] **Step 1: Create a placeholder StatsScreen**

Create `lib/features/stats/screens/stats_screen.dart`:

```dart
import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Stats coming soon'),
      ),
    );
  }
}
```

- [ ] **Step 2: Convert app.dart to use BottomNavigationBar**

Replace the full content of `lib/app.dart`:

```dart
import 'package:flutter/material.dart';

import 'features/inventory/screens/inventory_screen.dart';
import 'features/stats/screens/stats_screen.dart';
import 'shared/theme/app_theme.dart';

class RePlayApp extends StatefulWidget {
  const RePlayApp({super.key});

  @override
  State<RePlayApp> createState() => _RePlayAppState();
}

class _RePlayAppState extends State<RePlayApp> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    InventoryScreen(),
    StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rePlay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.toys_outlined),
              selectedIcon: Icon(Icons.toys),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
          ],
        ),
      ),
    );
  }
}
```

Note: Uses `IndexedStack` so both screens stay alive when switching tabs (preserves scroll position, search state, etc.). Uses Material 3 `NavigationBar` instead of the older `BottomNavigationBar`. The `Scaffold` wrapping with the bottom nav is at the app level, and each screen has its own `Scaffold` with its own AppBar.

- [ ] **Step 3: Run existing tests to verify nothing broke**

Run: `flutter test test/widget_test.dart`
Expected: All 9 tests PASS. The existing tests render `InventoryScreen` directly (not through `RePlayApp`), so they are unaffected.

- [ ] **Step 4: Run the app to verify bottom nav works**

Run: `flutter run -d macos` (or your target device)
Expected: Bottom nav shows two tabs. Inventory tab shows existing screen. Stats tab shows "Stats coming soon".

- [ ] **Step 5: Commit**

```bash
git add lib/app.dart lib/features/stats/screens/stats_screen.dart
git commit -m "feat: add bottom navigation with inventory and stats tabs"
```

---

### Task 2: Hero Count Card Widget

**Files:**
- Create: `lib/features/stats/widgets/hero_count_card.dart`
- Create: `test/stats_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/stats_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replay/features/stats/widgets/hero_count_card.dart';

void main() {
  testWidgets('HeroCountCard shows total toy count', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HeroCountCard(totalCount: 24)),
      ),
    );

    expect(find.text('24'), findsOneWidget);
    expect(find.text('total toys'), findsOneWidget);
  });

  testWidgets('HeroCountCard shows zero count', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HeroCountCard(totalCount: 0)),
      ),
    );

    expect(find.text('0'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/stats_screen_test.dart`
Expected: FAIL — `HeroCountCard` doesn't exist.

- [ ] **Step 3: Implement HeroCountCard**

Create `lib/features/stats/widgets/hero_count_card.dart`:

```dart
import 'package:flutter/material.dart';

class HeroCountCard extends StatelessWidget {
  final int totalCount;

  const HeroCountCard({super.key, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Text(
              '$totalCount',
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'total toys',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/stats_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/stats/widgets/hero_count_card.dart test/stats_screen_test.dart
git commit -m "feat: add hero count card widget"
```

---

### Task 3: Status Breakdown Card Widget

**Files:**
- Create: `lib/features/stats/widgets/status_breakdown_card.dart`
- Modify: `test/stats_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/stats_screen_test.dart`:

```dart
import 'package:replay/features/stats/widgets/status_breakdown_card.dart';
```

And add this test:

```dart
  testWidgets('StatusBreakdownCard shows counts per status', (WidgetTester tester) async {
    final statusCounts = {
      'active': 15,
      'inStorage': 5,
      'toDonate': 3,
      'toSell': 1,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StatusBreakdownCard(statusCounts: statusCounts)),
      ),
    );

    expect(find.text('By Status'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('In Storage'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('StatusBreakdownCard handles empty counts', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBreakdownCard(statusCounts: {})),
      ),
    );

    expect(find.text('By Status'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/stats_screen_test.dart --name "StatusBreakdownCard"`
Expected: FAIL

- [ ] **Step 3: Implement StatusBreakdownCard**

Create `lib/features/stats/widgets/status_breakdown_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class StatusBreakdownCard extends StatelessWidget {
  final Map<String, int> statusCounts;

  const StatusBreakdownCard({super.key, required this.statusCounts});

  static const _statusColors = <String, Color>{
    'active': Color(0xFF6366F1),
    'inStorage': Color(0xFF8B5CF6),
    'toDonate': Color(0xFF10B981),
    'toSell': Color(0xFFF59E0B),
    'toHandDown': Color(0xFF14B8A6),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = statusCounts.values.fold(0, (sum, c) => sum + c);
    final nonZeroStatuses = AppConstants.statuses
        .where((s) => (statusCounts[s] ?? 0) > 0)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By Status', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (total > 0)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: nonZeroStatuses.map((status) {
                    final count = statusCounts[status] ?? 0;
                    return Expanded(
                      flex: count,
                      child: Container(
                        height: 12,
                        color: _statusColors[status] ?? Colors.grey,
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: nonZeroStatuses.map((status) {
                final count = statusCounts[status] ?? 0;
                final color = _statusColors[status] ?? Colors.grey;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AppConstants.getStatusLabel(status),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/stats_screen_test.dart --name "StatusBreakdownCard"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/stats/widgets/status_breakdown_card.dart test/stats_screen_test.dart
git commit -m "feat: add status breakdown card widget"
```

---

### Task 4: Recently Added Card Widget

**Files:**
- Create: `lib/features/stats/widgets/recently_added_card.dart`
- Modify: `test/stats_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/stats_screen_test.dart`:

```dart
import 'package:replay/core/database/database.dart';
import 'package:replay/features/stats/widgets/recently_added_card.dart';
```

And add this test:

```dart
  testWidgets('RecentlyAddedCard shows toys in reverse chronological order', (WidgetTester tester) async {
    final now = DateTime.now();
    final toys = [
      Toy(id: 1, name: 'Oldest', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: now.subtract(const Duration(days: 10)), updatedAt: now, condition: 'good', location: null, status: 'active'),
      Toy(id: 2, name: 'Newest', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: now.subtract(const Duration(hours: 2)), updatedAt: now, condition: 'good', location: null, status: 'active'),
      Toy(id: 3, name: 'Middle', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: now.subtract(const Duration(days: 3)), updatedAt: now, condition: 'good', location: null, status: 'active'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RecentlyAddedCard(toys: toys, onToyTap: (_) {})),
      ),
    );

    expect(find.text('Recently Added'), findsOneWidget);
    expect(find.text('Newest'), findsOneWidget);
    expect(find.text('Middle'), findsOneWidget);
    expect(find.text('Oldest'), findsOneWidget);

    // Verify order: Newest should appear before Oldest
    final newestOffset = tester.getTopLeft(find.text('Newest'));
    final oldestOffset = tester.getTopLeft(find.text('Oldest'));
    expect(newestOffset.dy, lessThan(oldestOffset.dy));
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/stats_screen_test.dart --name "RecentlyAddedCard"`
Expected: FAIL

- [ ] **Step 3: Implement RecentlyAddedCard**

Create `lib/features/stats/widgets/recently_added_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/database/database.dart';

class RecentlyAddedCard extends StatelessWidget {
  final List<Toy> toys;
  final void Function(int toyId) onToyTap;

  const RecentlyAddedCard({
    super.key,
    required this.toys,
    required this.onToyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<Toy>.from(toys)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final recent = sorted.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recently Added', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              Text(
                'No toys added yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...recent.map((toy) {
                return InkWell(
                  onTap: () => onToyTap(toy.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            toy.name,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _timeAgo(toy.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 30}mo ago';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/stats_screen_test.dart --name "RecentlyAddedCard"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/stats/widgets/recently_added_card.dart test/stats_screen_test.dart
git commit -m "feat: add recently added card widget"
```

---

### Task 5: Needs Attention Card Widget

**Files:**
- Create: `lib/features/stats/widgets/needs_attention_card.dart`
- Modify: `test/stats_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/stats_screen_test.dart`:

```dart
import 'package:replay/features/stats/widgets/needs_attention_card.dart';
```

And add these tests:

```dart
  testWidgets('NeedsAttentionCard hidden when no poor/broken toys', (WidgetTester tester) async {
    final toys = [
      Toy(id: 1, name: 'GoodToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NeedsAttentionCard(toys: toys, onToyTap: (_) {})),
      ),
    );

    expect(find.text('Needs Attention'), findsNothing);
  });

  testWidgets('NeedsAttentionCard shows poor and broken toys', (WidgetTester tester) async {
    final toys = [
      Toy(id: 1, name: 'GoodToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'good', location: null, status: 'active'),
      Toy(id: 2, name: 'PoorToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'poor', location: null, status: 'active'),
      Toy(id: 3, name: 'BrokenToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: DateTime.now(), updatedAt: DateTime.now(), condition: 'broken', location: null, status: 'active'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NeedsAttentionCard(toys: toys, onToyTap: (_) {})),
      ),
    );

    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('PoorToy'), findsOneWidget);
    expect(find.text('BrokenToy'), findsOneWidget);
    expect(find.text('GoodToy'), findsNothing);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/stats_screen_test.dart --name "NeedsAttentionCard"`
Expected: FAIL

- [ ] **Step 3: Implement NeedsAttentionCard**

Create `lib/features/stats/widgets/needs_attention_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database.dart';

class NeedsAttentionCard extends StatelessWidget {
  final List<Toy> toys;
  final void Function(int toyId) onToyTap;

  const NeedsAttentionCard({
    super.key,
    required this.toys,
    required this.onToyTap,
  });

  @override
  Widget build(BuildContext context) {
    final attentionToys = toys
        .where((t) => t.condition == 'poor' || t.condition == 'broken')
        .toList();

    if (attentionToys.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Needs Attention',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...attentionToys.map((toy) {
              return InkWell(
                onTap: () => onToyTap(toy.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          toy.name,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppConstants.getConditionLabel(toy.condition),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/stats_screen_test.dart --name "NeedsAttentionCard"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/stats/widgets/needs_attention_card.dart test/stats_screen_test.dart
git commit -m "feat: add needs attention card widget"
```

---

### Task 6: Assemble StatsScreen

**Files:**
- Modify: `lib/features/stats/screens/stats_screen.dart`
- Modify: `test/stats_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/stats_screen_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:replay/core/services/image_storage_service.dart';
import 'package:replay/features/inventory/providers/inventory_provider.dart';
import 'package:replay/features/stats/screens/stats_screen.dart';
```

And add this test:

```dart
  testWidgets('StatsScreen shows all stat sections with toy data', (WidgetTester tester) async {
    final notifier = _MockInventoryNotifier();
    final now = DateTime.now();
    notifier.state = InventoryState(
      toys: [
        Toy(id: 1, name: 'ActiveToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: now.subtract(const Duration(days: 1)), updatedAt: now, condition: 'good', location: null, status: 'active'),
        Toy(id: 2, name: 'BrokenToy', description: null, imagePath: '', thumbnailPath: null, category: 'Dolls', aiLabels: '[]', createdAt: now.subtract(const Duration(days: 5)), updatedAt: now, condition: 'broken', location: null, status: 'active'),
        Toy(id: 3, name: 'StoredToy', description: null, imagePath: '', thumbnailPath: null, category: 'Other', aiLabels: '[]', createdAt: now.subtract(const Duration(days: 3)), updatedAt: now, condition: 'good', location: null, status: 'inStorage'),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pump();

    // Hero count
    expect(find.text('3'), findsOneWidget);
    expect(find.text('total toys'), findsOneWidget);

    // Status breakdown
    expect(find.text('By Status'), findsOneWidget);

    // Recently added
    expect(find.text('Recently Added'), findsOneWidget);
    expect(find.text('ActiveToy'), findsOneWidget);

    // Needs attention (BrokenToy has condition 'broken')
    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('BrokenToy'), findsWidgets); // appears in both recently added and needs attention
  });
```

Also add the mock class at the bottom of the file:

```dart
class _MockInventoryNotifier extends InventoryNotifier {
  _MockInventoryNotifier() : super(_MockDatabase(), _MockImageStorage());
}

class _MockDatabase implements AppDatabase {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockImageStorage implements ImageStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/stats_screen_test.dart --name "StatsScreen shows all"`
Expected: FAIL — StatsScreen is still the placeholder.

- [ ] **Step 3: Implement the full StatsScreen**

Replace the content of `lib/features/stats/screens/stats_screen.dart`:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/stats_screen_test.dart --name "StatsScreen shows all"`
Expected: PASS

- [ ] **Step 5: Run all tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/stats/screens/stats_screen.dart test/stats_screen_test.dart
git commit -m "feat: assemble stats screen with all card widgets"
```

---

### Task 7: Final Verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No new analysis issues.

- [ ] **Step 3: Fix any issues found**

If there are analysis warnings or test failures in the new code, fix them and commit.

- [ ] **Step 4: Final commit if needed**

```bash
git add -A
git commit -m "fix: resolve analysis warnings"
```

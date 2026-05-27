# Hero Transitions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wrap toy cover images in Flutter `Hero` widgets across inventory grid, list, stats "Recently added", and the detail screen, with a fade page-transition so only the cover image flies during navigation.

**Architecture:** A pure tag helper in `lib/core/widgets/` and a feature-level route builder in `lib/features/inventory/navigation/`. Every entry point uses the shared `toyImageHeroTag(id)` and pushes via `toyDetailRoute(id)`. The destination Hero declares a custom `flightShuttleBuilder` to interpolate `BorderRadius` cleanly.

**Tech Stack:** Flutter, Dart, existing `flutter_test` widget testing setup.

---

## File Map

| Task | File | Role |
|------|------|------|
| 1 | `lib/core/widgets/hero_tags.dart` (new) | Pure tag helper `toyImageHeroTag(int)` |
| 1 | `test/hero_tags_test.dart` (new) | Unit test for the tag helper |
| 2 | `test/widget_test.dart` (modify) | Hero presence test for grid card |
| 2 | `lib/features/inventory/widgets/toy_card.dart` (modify) | Wrap `_buildImage()` return in Hero |
| 3 | `test/widget_test.dart` (modify) | Hero presence test for list item |
| 3 | `lib/features/inventory/widgets/toy_list_item.dart` (modify) | Wrap leading thumbnail in Hero |
| 4 | `lib/features/inventory/screens/toy_detail_screen.dart` (modify) | Wrap cover image in Hero + custom shuttle |
| 5 | `lib/features/inventory/navigation/toy_detail_route.dart` (new) | `toyDetailRoute(int)` page route builder |
| 5 | `test/toy_detail_route_test.dart` (new) | Unit test for the route helper |
| 6 | `lib/features/inventory/screens/inventory_screen.dart` (modify) | Use `toyDetailRoute` in `_navigateToDetail` |
| 6 | `lib/features/stats/screens/stats_screen.dart` (modify) | Use `toyDetailRoute` in `_navigateToDetail` |
| 7 | — | `flutter test` + `flutter analyze` + manual run |

---

### Task 1: Hero Tag Helper

**Files:**
- Create: `lib/core/widgets/hero_tags.dart`
- Create: `test/hero_tags_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/hero_tags_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:replay/core/widgets/hero_tags.dart';

void main() {
  test('toyImageHeroTag returns stable tag for a given id', () {
    expect(toyImageHeroTag(1), 'toy-image-1');
    expect(toyImageHeroTag(42), 'toy-image-42');
  });

  test('toyImageHeroTag is unique per id', () {
    expect(toyImageHeroTag(1), isNot(equals(toyImageHeroTag(2))));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/hero_tags_test.dart`
Expected: FAIL with "Target of URI doesn't exist" (the file we're about to create).

- [ ] **Step 3: Create the helper**

Create `lib/core/widgets/hero_tags.dart`:

```dart
String toyImageHeroTag(int id) => 'toy-image-$id';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/hero_tags_test.dart`
Expected: PASS — both tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/hero_tags.dart test/hero_tags_test.dart
git commit -m "feat: add toyImageHeroTag helper for hero transitions"
```

---

### Task 2: Hero on Grid Card

**Files:**
- Modify: `test/widget_test.dart` (append new test)
- Modify: `lib/features/inventory/widgets/toy_card.dart`

- [ ] **Step 1: Write the failing widget test**

In `test/widget_test.dart`, add this import at the top:

```dart
import 'dart:io';

import 'package:replay/core/database/database.dart';
import 'package:replay/core/widgets/hero_tags.dart';
```

(If `dart:io` and `database.dart` are already imported, skip those.)

Append this test inside the existing `void main() { ... }`, before the closing `}` of `main`:

```dart
  testWidgets('Grid card wraps image in Hero with toyImageHeroTag', (WidgetTester tester) async {
    final tempDir = Directory.systemTemp.createTempSync('hero_grid_test');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final imageFile = File('${tempDir.path}/cover.png')..writeAsBytesSync([0]);

    final notifier = MockInventoryNotifier();
    notifier.state = InventoryState(
      toys: [
        Toy(
          id: 7,
          name: 'HeroToy',
          description: null,
          imagePath: imageFile.path,
          thumbnailPath: null,
          category: 'Other',
          aiLabels: '[]',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          condition: 'good',
          location: null,
          status: 'active',
        ),
      ],
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

    final heroFinder = find.byWidgetPredicate(
      (w) => w is Hero && w.tag == toyImageHeroTag(7),
    );
    expect(heroFinder, findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --plain-name "Grid card wraps image in Hero"`
Expected: FAIL — `Expected: exactly one matching candidate / Actual: _WidgetPredicateFinder:<zero widgets>`.

- [ ] **Step 3: Modify ToyCard to wrap the image in a Hero**

In `lib/features/inventory/widgets/toy_card.dart`, replace the existing `_buildImage()` method (lines 180–197) with:

```dart
  Widget _buildImage() {
    final imagePath = toy.thumbnailPath ?? toy.imagePath;
    if (imagePath.isEmpty) {
      return _buildPlaceholder();
    }
    final file = File(imagePath);
    if (!file.existsSync()) {
      return _buildPlaceholder();
    }
    return Hero(
      tag: toyImageHeroTag(toy.id),
      child: Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      ),
    );
  }
```

Add the import at the top of the file (after the existing `database.dart` import):

```dart
import '../../../core/widgets/hero_tags.dart';
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart --plain-name "Grid card wraps image in Hero"`
Expected: PASS.

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: All tests pass. Existing tests with `imagePath: ''` continue to take the placeholder path.

- [ ] **Step 6: Commit**

```bash
git add lib/features/inventory/widgets/toy_card.dart test/widget_test.dart
git commit -m "feat: wrap grid card image in Hero for shared-element transitions"
```

---

### Task 3: Hero on List Item

**Files:**
- Modify: `test/widget_test.dart` (append new test)
- Modify: `lib/features/inventory/widgets/toy_list_item.dart`

- [ ] **Step 1: Write the failing widget test**

Append inside `void main()` in `test/widget_test.dart`:

```dart
  testWidgets('List item wraps thumbnail in Hero with toyImageHeroTag', (WidgetTester tester) async {
    final tempDir = Directory.systemTemp.createTempSync('hero_list_test');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final imageFile = File('${tempDir.path}/cover.png')..writeAsBytesSync([0]);

    final notifier = MockInventoryNotifier();
    notifier.state = InventoryState(
      isListView: true,
      toys: [
        Toy(
          id: 9,
          name: 'ListToy',
          description: null,
          imagePath: imageFile.path,
          thumbnailPath: null,
          category: 'Other',
          aiLabels: '[]',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          condition: 'good',
          location: null,
          status: 'active',
        ),
      ],
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

    final heroFinder = find.byWidgetPredicate(
      (w) => w is Hero && w.tag == toyImageHeroTag(9),
    );
    expect(heroFinder, findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart --plain-name "List item wraps thumbnail in Hero"`
Expected: FAIL — no matching Hero found.

- [ ] **Step 3: Modify ToyListItem to wrap the thumbnail in a Hero**

In `lib/features/inventory/widgets/toy_list_item.dart`, add the import after the existing `database.dart` import:

```dart
import '../../../core/widgets/hero_tags.dart';
```

Replace the `leading:` block of the `ListTile` (currently the `SizedBox(width: 48, height: 48, child: ClipRRect(...))` containing a `FutureBuilder<bool>`) with:

```dart
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _buildLeading(),
        ),
      ),
```

And add a `_buildLeading()` method after `build()`, before the closing class brace:

```dart
  Widget _buildLeading() {
    final thumbPath = toy.thumbnailPath ?? toy.imagePath;
    if (thumbPath.isEmpty) {
      return _placeholder();
    }
    final file = File(thumbPath);
    if (!file.existsSync()) {
      return _placeholder();
    }
    return Hero(
      tag: toyImageHeroTag(toy.id),
      child: Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.toys, size: 24, color: Colors.grey[400]),
    );
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart --plain-name "List item wraps thumbnail in Hero"`
Expected: PASS.

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/inventory/widgets/toy_list_item.dart test/widget_test.dart
git commit -m "feat: wrap list item thumbnail in Hero for shared-element transitions"
```

---

### Task 4: Hero + Flight Shuttle on Detail Screen

**Files:**
- Modify: `lib/features/inventory/screens/toy_detail_screen.dart`

This task adds the destination Hero with a custom `flightShuttleBuilder` that interpolates `BorderRadius` from rounded (card source) to square (detail destination). The shuttle behavior is verified manually rather than via widget test — automating animation frame inspection is impractical.

- [ ] **Step 1: Add the Hero import**

In `lib/features/inventory/screens/toy_detail_screen.dart`, add after the existing `database.dart` import:

```dart
import '../../../core/widgets/hero_tags.dart';
```

- [ ] **Step 2: Wrap the main image in Hero with custom shuttle**

Replace the `_buildMainImage` method (currently around lines 162–197) with:

```dart
  Widget _buildMainImage(Toy toy, List<ToyImage> additionalImages) {
    String imagePath;
    if (_selectedPhotoIndex == 0) {
      imagePath = toy.imagePath;
    } else {
      final imgIndex = _selectedPhotoIndex - (toy.imagePath.isNotEmpty ? 1 : 0);
      if (imgIndex >= 0 && imgIndex < additionalImages.length) {
        imagePath = additionalImages[imgIndex].imagePath;
      } else {
        imagePath = toy.imagePath;
      }
    }

    final showHero = _selectedPhotoIndex == 0 &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();

    final image = AspectRatio(
      aspectRatio: 1,
      child: imagePath.isNotEmpty && File(imagePath).existsSync()
          ? Image.file(File(imagePath), fit: BoxFit.cover)
          : Container(
              color: Colors.grey[200],
              child: Icon(Icons.toys, size: 80, color: Colors.grey[400]),
            ),
    );

    if (!showHero) {
      return image;
    }

    return Hero(
      tag: toyImageHeroTag(toy.id),
      flightShuttleBuilder: (flightContext, animation, direction, fromContext, toContext) {
        final tween = BorderRadiusTween(
          begin: BorderRadius.circular(8),
          end: BorderRadius.zero,
        );
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final radius = direction == HeroFlightDirection.push
                ? tween.evaluate(animation)!
                : tween.evaluate(ReverseAnimation(animation))!;
            return ClipRRect(
              borderRadius: radius,
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.file(File(imagePath), fit: BoxFit.cover),
              ),
            );
          },
        );
      },
      child: image,
    );
  }
```

The shuttle pins the image to `BoxFit.cover` inside an `AspectRatio` so the image never squishes mid-flight. The `BorderRadiusTween` animates from `8px` (card) to `0` (detail) on push and reverses on pop.

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: All tests pass. Existing detail-screen behavior is unchanged for toys without images.

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/inventory/screens/toy_detail_screen.dart
git commit -m "feat: wrap detail screen cover image in Hero with custom flight shuttle"
```

---

### Task 5: Page Route Helper

**Files:**
- Create: `lib/features/inventory/navigation/toy_detail_route.dart`
- Create: `test/toy_detail_route_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/toy_detail_route_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:replay/features/inventory/navigation/toy_detail_route.dart';
import 'package:replay/features/inventory/screens/toy_detail_screen.dart';

void main() {
  test('toyDetailRoute returns a PageRouteBuilder with a fade transition', () {
    final route = toyDetailRoute(42);
    expect(route, isA<PageRouteBuilder<void>>());

    final builder = route as PageRouteBuilder<void>;
    expect(builder.transitionDuration, const Duration(milliseconds: 350));
    expect(builder.reverseTransitionDuration, const Duration(milliseconds: 300));
  });

  testWidgets('toyDetailRoute pageBuilder produces ToyDetailScreen with correct toyId', (tester) async {
    final route = toyDetailRoute(99) as PageRouteBuilder<void>;
    final page = route.pageBuilder(
      _DummyBuildContext(),
      const AlwaysStoppedAnimation(0),
      const AlwaysStoppedAnimation(0),
    );

    expect(page, isA<ToyDetailScreen>());
    expect((page as ToyDetailScreen).toyId, 99);
  });
}

class _DummyBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/toy_detail_route_test.dart`
Expected: FAIL with "Target of URI doesn't exist" for the route file.

- [ ] **Step 3: Create the route helper**

Create `lib/features/inventory/navigation/toy_detail_route.dart`:

```dart
import 'package:flutter/material.dart';

import '../screens/toy_detail_screen.dart';

Route<void> toyDetailRoute(int toyId) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => ToyDetailScreen(toyId: toyId),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/toy_detail_route_test.dart`
Expected: PASS — both tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/features/inventory/navigation/toy_detail_route.dart test/toy_detail_route_test.dart
git commit -m "feat: add toyDetailRoute helper with fade page transition"
```

---

### Task 6: Wire Navigation Sites to toyDetailRoute

**Files:**
- Modify: `lib/features/inventory/screens/inventory_screen.dart`
- Modify: `lib/features/stats/screens/stats_screen.dart`

The push currently returns `bool` (the detail screen returns `true` when changes were saved). `toyDetailRoute` returns `Route<void>`, so we need to change the typed push signature. The detail screen still calls `Navigator.pop(context, true)` but the result is no longer typed — we lose the typed refresh signal. To preserve refresh-on-return behavior, we'll refresh unconditionally on pop (cheap; the inventory provider just re-reads the DB).

- [ ] **Step 1: Update inventory_screen.dart**

In `lib/features/inventory/screens/inventory_screen.dart`, add the import after the existing `ToyDetailScreen` import:

```dart
import '../navigation/toy_detail_route.dart';
```

Replace the `_navigateToDetail` method (currently around lines 361–370) with:

```dart
  void _navigateToDetail(int toyId) async {
    await Navigator.of(context).push(toyDetailRoute(toyId));
    ref.read(inventoryProvider.notifier).refresh();
  }
```

The conditional `if (result == true)` is gone; we now always refresh. The provider's `refresh()` is a debounced/idempotent DB re-read, so calling it after every detail visit is harmless.

- [ ] **Step 2: Update stats_screen.dart**

In `lib/features/stats/screens/stats_screen.dart`, add the import after the existing `ToyDetailScreen` import:

```dart
import '../../inventory/navigation/toy_detail_route.dart';
```

Replace the `_navigateToDetail` method (currently around lines 51–61) with:

```dart
  void _navigateToDetail(BuildContext context, WidgetRef ref, int toyId) async {
    await Navigator.of(context).push(toyDetailRoute(toyId));
    ref.read(inventoryProvider.notifier).refresh();
  }
```

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 4: Run flutter analyze**

Run: `flutter analyze`
Expected: No issues. (The unused `ToyDetailScreen` import in `inventory_screen.dart` should be removed if analyze flags it — check both screens and delete any newly-unused imports.)

- [ ] **Step 5: If analyze flags unused imports, remove them and re-run**

If `flutter analyze` reports `unused_import` for `import '...toy_detail_screen.dart';` in either file, delete that line.

Then re-run: `flutter analyze` and `flutter test`.

- [ ] **Step 6: Commit**

```bash
git add lib/features/inventory/screens/inventory_screen.dart lib/features/stats/screens/stats_screen.dart
git commit -m "feat: route through toyDetailRoute for fade transition on detail navigation"
```

---

### Task 7: Final Verification

**Files:**
- None (verification only)

- [ ] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: All tests pass — the prior count plus 2 new helper tests (1 in `hero_tags_test.dart`, 2 in `toy_detail_route_test.dart`) and 2 new widget tests (`Grid card wraps image in Hero`, `List item wraps thumbnail in Hero`).

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Manual verification on macOS**

Run: `flutter run -d macos`

In the running app:
1. Seed mock data if the inventory is empty (existing dev hook).
2. Tap a grid card with a real photo — observe the image fly into the detail header while the rest of the page fades in.
3. Press back — observe the reverse animation.
4. Toggle the inventory to list view (icon in the toolbar). Tap a list item — confirm the small 48×48 thumbnail flies and expands.
5. Go to the Stats tab. Tap a "Recently added" card — confirm the same transition.
6. Open Flutter DevTools → Performance → enable "Slow animations" and repeat one transition. Confirm the `BorderRadius` interpolates smoothly (no jump from rounded to square at the start or end).
7. Tap a toy that has no photo (placeholder icon). Confirm navigation still works (fade only, no hero).

- [ ] **Step 4: Fix any issues found in manual verification and commit fixes if needed**

If any visual glitch shows up, diagnose, patch, and create a separate fix commit. Note common pitfalls:
- If the image squishes mid-flight: the `flightShuttleBuilder` `AspectRatio` may not be wrapping the image. Recheck Task 4 Step 2.
- If two heroes log a "tag collision" warning: an unrelated screen may also be using `'toy-image-$id'`. Search the codebase for any extra usage.
- If the back animation hitches: confirm `reverseTransitionDuration` is `300ms` in `toy_detail_route.dart`.

- [ ] **Step 5: Push**

```bash
git push
```

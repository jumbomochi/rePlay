# Hero Transitions Design

**Date:** 2026-05-27
**Status:** Approved
**Scope:** Motion polish — make tapping a toy in the inventory animate its image smoothly into the detail screen.

## Goal

When the user taps a toy card (grid or list view) or a "Recently added" card on the stats screen, the toy's cover image should fly from its source position into the detail screen's header. The rest of the destination scaffold cross-fades in around it. Reverse animation on back navigation.

## Non-Goals

- No animation between photos within the detail screen's multi-photo gallery (separate concern).
- No list/grid entry animations, no haptics, no filter chip animations (different polish axes; addressed later if desired).
- No new state, no DB changes, no new dependencies.

## Architecture

A single shared helper module owns the hero tag scheme and the page route. Every place that displays a toy's cover image as a tap-target wraps it in a `Hero` with the shared tag, and every navigation to `ToyDetailScreen` goes through the shared route helper.

### New modules

Two helpers, split by layer to keep `lib/core/` from importing feature code:

`lib/core/widgets/hero_tags.dart` — pure tag helper, no widget dependencies:

```dart
String toyImageHeroTag(int id) => 'toy-image-$id';
```

`lib/features/inventory/navigation/toy_detail_route.dart` — the route builder, imports the screen:

```dart
import 'package:flutter/material.dart';
import '../screens/toy_detail_screen.dart';

Route<void> toyDetailRoute(int toyId) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => ToyDetailScreen(toyId: toyId),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
```

The hero animates *over* this fade — only the cover image flies; everything else cross-fades.

### Files touched

| File | Change |
|------|--------|
| `lib/core/widgets/hero_tags.dart` | New: `toyImageHeroTag` helper |
| `lib/features/inventory/navigation/toy_detail_route.dart` | New: `toyDetailRoute` page route builder |
| `lib/features/inventory/widgets/toy_card.dart` | Wrap `_buildImage()` return in `Hero` (only when file exists) |
| `lib/features/inventory/widgets/toy_list_item.dart` | Wrap leading thumbnail in `Hero` (only when file exists) |
| `lib/features/inventory/screens/toy_detail_screen.dart` | Wrap cover image in `Hero` with custom `flightShuttleBuilder` |
| `lib/features/inventory/screens/inventory_screen.dart` | Use `toyDetailRoute` in `_navigateToDetail` |
| `lib/features/stats/screens/stats_screen.dart` | Use `toyDetailRoute` instead of `MaterialPageRoute` at line 54 |
| `test/widget_test.dart` | Add hero tag assertion test |

## Hero Tag Scheme

One tag per toy id, regardless of entry point: `toy-image-<id>`. The same tag on grid card and list item is safe because only one is mounted at a time (`InventoryState.isListView` toggles between them). The detail screen mounts after navigation, so source and destination live in different routes — Hero matches them across the push.

The multi-photo gallery strip on detail (`photo_gallery_strip.dart`) does **not** participate. Switching between photos within detail is a separate interaction and is out of scope.

## Flight Shuttle

Default Hero behavior re-parents the source widget into the flight overlay, which can squish the image if source and destination wrap it differently (rounded `ClipRRect` on card, square on detail). To avoid this, the destination Hero declares a custom `flightShuttleBuilder` that:

1. Holds `Image.file(path, fit: BoxFit.cover)` constant during flight.
2. Animates `BorderRadius` from `BorderRadius.circular(8)` (card source) to `BorderRadius.zero` (detail destination) via a `BorderRadiusTween` driven by the flight `animation`.
3. Wraps the image in `ClipRRect` using the interpolated radius.

The image stays visually stable; only the frame shape morphs.

## Page Route

`toyDetailRoute(int toyId)` is the only sanctioned way to navigate to the detail screen. It uses `PageRouteBuilder` (see code above) so the non-image scaffold (app bar, gallery strip, lifecycle fields, history) fades in while the hero carries the image.

The default `MaterialPageRoute` is replaced at all three call sites. The detail screen itself does not change its scaffold layout — only how it's reached.

## Edge Cases

- **Missing image file.** Cards currently check `File(path).exists()` async via `FutureBuilder<bool>`. We switch to `File(path).existsSync()` (cheap on local FS) and only wrap in `Hero` when the file exists. If the file is missing, render the placeholder icon as before — no Hero, plain navigation through the route helper. The detail screen does the same check on mount.
- **Empty `imagePath`.** Toys without any photo skip the Hero on both source and destination; navigation still works via the fade route.
- **Multi-select overlay.** The selection checkmark on `ToyCard` sits outside the image's `Hero` subtree, so it stays anchored on the grid during flight. No visual flash.
- **Tag collisions.** Hero requires unique tags within a route. Only one card or list item per toy is mounted at a time, and the destination is a distinct route, so the tag is always unique within its route.
- **Back-button mid-flight.** Default Hero handles reverse gracefully — Flutter cancels and reverses on pop during forward flight.
- **List-view source size.** The list thumbnail is 48×48 with `BorderRadius.circular(6)`; the flight from there to a full-width detail header is more dramatic than from a grid card, but the shuttle interpolation handles both ranges. Acceptable.

## Testing

- **Widget test (new):** In `test/widget_test.dart`, add a test that mounts the inventory with one toy that has a real image path, finds the `Hero` with `toyImageHeroTag(id)` on the card, taps it, pumps the animation, and asserts the same tag is present on the detail screen after navigation completes. Use `tester.pumpAndSettle()` to flush the page transition.
- **Existing tests:** All existing widget and unit tests should continue to pass unchanged. The grid/list view smoke tests already pump the inventory and won't notice the Hero wrappers.
- **Manual verification:** `flutter run -d macos` (or any device), tap a toy, observe the image fly. Repeat from list view and from stats "Recently added". Toggle slow-motion in Flutter DevTools to confirm shuttle behavior frame-by-frame.

## Out of Scope (Future Polish)

- Hero between detail-screen photos (swipe to next photo with shared-element animation).
- Page transition for stats sub-tabs.
- Animated status badge color changes on `ToyCard`.
- List-view entry stagger animations.

These belong in a separate motion pass if desired.

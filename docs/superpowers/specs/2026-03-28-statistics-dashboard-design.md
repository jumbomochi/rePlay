# Statistics Dashboard Design

## Overview

Add a statistics dashboard as a second tab in the app, accessible via a bottom navigation bar. The dashboard gives parents a quick overview of their toy collection with actionable insights.

## Navigation

Add a `BottomNavigationBar` to `app.dart` with two tabs:
- **Inventory** (index 0) — the existing `InventoryScreen`
- **Stats** (index 1) — the new `StatsScreen`

The app root widget becomes a `StatefulWidget` that manages the selected tab index and renders the appropriate screen. The `InventoryScreen` and `StatsScreen` are peers — no push/pop navigation between them.

## Stats Screen

A scrollable single-column layout with 4 Material card sections:

### 1. Hero Count Card
- Large centered number showing total toy count
- Subtitle: "total toys"
- Uses `inventoryState.toys.length`

### 2. Status Breakdown Card
- Heading: "By Status"
- Horizontal stacked bar: a `Row` of colored `Container` widgets with flex proportions matching each status count. Colors:
  - Active: primary (indigo)
  - In Storage: secondary variant
  - To Donate: green
  - To Sell: amber
  - Hand Down: teal
- Legend below the bar showing status label + count for each non-zero status
- Computed from `inventoryState.toys` by counting per `toy.status`

### 3. Recently Added Card
- Heading: "Recently Added"
- Last 5 toys sorted by `createdAt` descending
- Each row shows toy name and relative time (e.g., "2 days ago")
- Tapping a row navigates to `ToyDetailScreen`
- Uses `timeago` style formatting via `DateTime.difference` — no external package needed, simple helper function (e.g., "just now", "2 days ago", "3 weeks ago")

### 4. Needs Attention Card
- Heading: "Needs Attention" with red accent (red left border on card)
- Shows toys where `condition == 'poor'` or `condition == 'broken'`
- Each row shows toy name and condition label
- Tapping a row navigates to `ToyDetailScreen`
- Card is hidden entirely if no toys need attention

## Data Source

All stats are computed from `inventoryProvider` state — no new database queries or providers needed. The `StatsScreen` is a `ConsumerWidget` that watches `inventoryProvider` and derives all values from `inventoryState.toys`.

## No Charting Library

The status breakdown bar is built with a `Row` of `Expanded` widgets with flex values matching counts. No external charting dependency.

## File Map

| File | Change |
|------|--------|
| `lib/app.dart` | Add `BottomNavigationBar`, manage tab state, render Inventory or Stats |
| `lib/features/stats/screens/stats_screen.dart` | New file: the stats dashboard screen |
| `lib/features/stats/widgets/hero_count_card.dart` | New file: total count card |
| `lib/features/stats/widgets/status_breakdown_card.dart` | New file: status bar + legend card |
| `lib/features/stats/widgets/recently_added_card.dart` | New file: recent toys list card |
| `lib/features/stats/widgets/needs_attention_card.dart` | New file: poor/broken toys card |
| `test/stats_screen_test.dart` | New file: widget tests for stats screen |

## Testing

- Widget test: StatsScreen renders correct total count
- Widget test: Status breakdown shows correct counts per status
- Widget test: Recently added shows toys in reverse chronological order
- Widget test: Needs attention card hidden when no poor/broken toys
- Widget test: Needs attention card visible with poor/broken toys

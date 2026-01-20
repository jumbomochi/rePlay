# Search Improvements Design

## Overview

Improve the search functionality in the inventory screen by making it more visible and providing better feedback when no results are found.

## Changes

### 1. Always-Visible Search Bar

Replace the hidden search toggle with a persistent search bar below the app bar.

**Layout:**
```
┌─────────────────────────────┐
│  AppBar (title only)        │
├─────────────────────────────┤
│  🔍 Search toys...      [X] │
├─────────────────────────────┤
│  Status Filter Tabs         │
├─────────────────────────────┤
│  Category Filter Chips      │
├─────────────────────────────┤
│  Toy Grid                   │
└─────────────────────────────┘
```

**Details:**
- TextField with search icon prefix
- Clear button suffix (visible when text entered)
- Rounded container matching app theme
- Consistent padding with filter sections

**Files to modify:**
- `lib/features/inventory/screens/inventory_screen.dart`

### 2. Empty Search Results State

Show a helpful message when search returns no results.

**Visual:**
```
┌─────────────────────────────┐
│         🔍 (large)          │
│    No toys found for        │
│    "search term"            │
│    Try a different search   │
│    or clear filters         │
└─────────────────────────────┘
```

**Details:**
- Large search icon
- Message includes the search term
- Secondary text with suggestion
- Only shown when search is active and results empty

**Files to modify:**
- `lib/features/inventory/screens/inventory_screen.dart` or
- `lib/features/inventory/widgets/toy_grid.dart`

## Implementation Notes

- Remove search toggle logic from app bar
- Remove `_isSearching` state variable
- Search bar can use existing `_searchController` and `setSearchQuery()` method
- Empty state should distinguish between "no toys exist" and "no search results"

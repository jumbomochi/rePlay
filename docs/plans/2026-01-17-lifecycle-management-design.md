# Toy Lifecycle Management Feature Design

## Overview

Add lightweight lifecycle tracking to toys with three new fields: condition, location, and status. Users can filter toys by lifecycle status using quick-access tabs.

## Goals

- Track toy condition (excellent to broken)
- Track storage location (user-defined)
- Track lifecycle status (active, storage, donate, sell, hand down)
- Filter toys by status with one tap
- Keep the experience lightweight and informal

## Data Model

### New Fields on Toy

| Field | Type | Values | Default |
|-------|------|--------|---------|
| `condition` | enum | `excellent`, `good`, `fair`, `poor`, `broken` | `good` |
| `location` | string | User-defined free text | `null` |
| `status` | enum | `active`, `inStorage`, `toDonate`, `toSell`, `toHandDown` | `active` |

### Database Migration

- Add three columns to `toys` table
- Existing toys receive default values automatically
- Drift handles migration

## UI Changes

### Inventory Screen

**Status Filter Tabs:**
Add a row of status filter tabs above existing category chips:

```
[All] [Active] [In Storage] [To Donate] [To Sell] [Hand Down]
```

- Tapping a tab filters the grid to toys with that status
- Combines with category filter (e.g., "Active" + "Vehicles")
- Optional badge counts on each tab

**Search Enhancement:**
- Location field becomes searchable

**Toy Card Badges:**
- Status icon in corner for non-active toys (box, heart, dollar sign)
- Condition indicator only for `poor` or `broken` (yellow/red dot)

### Toy Detail Screen

**New Lifecycle Section** (below name/description/category):

**Condition selector:**
- Segmented button with icons
- Options: Excellent, Good, Fair, Poor, Broken

**Location field:**
- Text input with autocomplete from previously used locations
- Placeholder: "e.g., Playroom shelf, Garage bin 2"

**Status selector:**
- Segmented button with icons
- Options: Active, In Storage, To Donate, To Sell, Hand Down

Section is collapsible to keep form clean.

### Capture Screen

- Same lifecycle fields available but collapsed by default
- Defaults (Active + Good) handle common case

## Implementation

### Files to Modify

| File | Changes |
|------|---------|
| `lib/core/database/tables/toys_table.dart` | Add condition, location, status columns |
| `lib/core/database/database.dart` | Migration logic, new query methods |
| `lib/features/inventory/models/toy.dart` | Add fields to ToyModel |
| `lib/features/inventory/providers/inventory_provider.dart` | Add status filter state |
| `lib/features/inventory/screens/inventory_screen.dart` | Add status filter tabs |
| `lib/features/inventory/widgets/toy_card.dart` | Add status/condition badges |
| `lib/features/inventory/screens/toy_detail_screen.dart` | Add lifecycle fields section |
| `lib/features/capture/screens/capture_screen.dart` | Add optional lifecycle fields |
| `lib/core/constants/app_constants.dart` | Add condition/status enums and icons |

### New Files

- `lib/features/inventory/widgets/status_filter_tabs.dart` - Status tab bar widget

### Testing

- Update existing widget tests with new fields
- Add tests for status filtering logic
- Add tests for location autocomplete

## Design Decisions

**Condition as enum:** Consistent values enable filtering and future features.

**Location as free text:** Every household organizes differently; predefined options would be limiting.

**Status as enum:** Fixed workflow states make filtering reliable and UI predictable.

**Lightweight approach:** No automated workflows or reminders. Users manage lifecycle informally through filters and manual updates.

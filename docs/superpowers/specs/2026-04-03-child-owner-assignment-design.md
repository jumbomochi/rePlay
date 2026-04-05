# Child/Owner Assignment Design

## Overview

Add an optional `owner` field to toys so families can track which child owns each toy. Filterable and searchable on the inventory screen.

## Database

Add an `owner` text column (nullable) to the `toys` table. Schema bumps from 3 to 4. Migration adds the column with no default (existing toys have null owner).

## Provider Changes

`InventoryState` gains:
- `selectedOwner` (String?, default null) — active owner filter
- Owner added to `filteredToys` getter: if `selectedOwner` is set, filter to toys matching that owner
- Owner added to search predicate: `t.owner?.toLowerCase().contains(query) ?? false`

`InventoryNotifier` gains:
- `setOwner(String? owner)` — set the owner filter
- `clearFilters()` updated to also reset `selectedOwner`

## Inventory Screen

Add an owner filter chip row between the category chips and the sort dropdown. Uses the same pattern as `CategoryFilterChips`:
- Horizontal scrollable row
- "All" chip + one chip per distinct owner value from `inventoryState.toys`
- Shows counts like the other filter rows: "Jake (5)"
- Hidden when no toys have owners set

## Toy Card

Show owner name below the category row if the toy has an owner. Small text, muted color, with a person icon.

## Capture Screen

Add an "Owner" text field in the form, after the category dropdown and before the lifecycle section. Optional field with person icon prefix.

## Detail Screen

- View mode: show owner below category if set
- Edit mode: editable text field for owner

## File Map

| File | Change |
|------|--------|
| `lib/core/database/tables/toys_table.dart` | Add `owner` column |
| `lib/core/database/database.dart` | Bump schema to 4, add migration |
| `lib/core/database/database.g.dart` | Regenerated |
| `lib/features/inventory/providers/inventory_provider.dart` | Add `selectedOwner`, `setOwner()`, owner filter + search |
| `lib/features/inventory/widgets/owner_filter_chips.dart` | New: owner filter chip row |
| `lib/features/inventory/widgets/toy_card.dart` | Show owner name |
| `lib/features/inventory/screens/inventory_screen.dart` | Add owner filter chips row |
| `lib/features/capture/screens/capture_screen.dart` | Add owner text field |
| `lib/features/inventory/screens/toy_detail_screen.dart` | Show/edit owner |

## Testing

- Unit test: owner filter in `filteredToys` works correctly
- Unit test: owner included in search predicate
- Widget test: owner filter chips appear when toys have owners

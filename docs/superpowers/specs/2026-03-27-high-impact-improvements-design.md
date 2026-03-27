# High-Impact Low-Effort Improvements

Four independent improvements to the inventory screen: search expansion, sort options, count badges, and batch operations.

## 1. Search Includes Description

**Change:** Add description to the search predicate in the `filteredToys` getter in `inventory_provider.dart`.

**Current behavior:** Searches name, aiLabels, and location.

**New behavior:** Also searches description. A parent searching "millennium falcon" finds the toy named "LEGO Star Wars Set" because the description contains the term.

**Files:** `lib/features/inventory/providers/inventory_provider.dart`

## 2. Sort Options

**Change:** Add a sort dropdown to the inventory screen and sort logic to the provider.

**Enum:** `SortOption` with values:
- `newestFirst` (default — matches current implicit behavior)
- `oldestFirst`
- `nameAsc`
- `nameDesc`
- `category`

**State:** `InventoryState` gains a `sortBy` field (`SortOption`, defaults to `newestFirst`). `InventoryNotifier` gains a `setSortOption(SortOption)` method.

**Sorting:** Applied in the `filteredToys` getter after filtering, before returning. Uses `Comparable` comparisons on the relevant fields.

**UI:** A compact dropdown button placed between the category filter chips and the toy grid. Shows the current sort label (e.g., "Newest First"). No icon-only mode — the label is clear enough.

**Files:**
- `lib/features/inventory/providers/inventory_provider.dart` — enum, state field, setter, sort logic
- `lib/features/inventory/screens/inventory_screen.dart` — dropdown widget

## 3. Toy Count Badges

**Change:** Show counts on status filter tabs and category filter chips.

**Display format:** `"Active (5)"`, `"To Donate (3)"`, `"Vehicles (2)"`.

**Count source:** Counts are computed from the full toy list (not the already-filtered list). Each filter value counts toys matching that single dimension only, so users see the total per bucket regardless of other active filters.

**Implementation:** Pass the full `inventoryState.toys` list to `StatusFilterTabs` and `CategoryFilterChips`. Each widget computes counts internally by iterating the list.

**Files:**
- `lib/features/inventory/widgets/status_filter_tabs.dart` — accept toys list, compute and display counts
- `lib/features/inventory/widgets/category_filter_chips.dart` — accept toys list, compute and display counts
- `lib/features/inventory/screens/inventory_screen.dart` — pass toys list to both widgets

## 4. Batch Status and Location Changes

### Interaction Flow

1. **Enter multi-select:** Long-press any toy card
2. **Select/deselect:** Tap cards to toggle selection; selected cards show a checkmark overlay
3. **AppBar transforms:** Title becomes "N selected", actions become Close (X) and a menu button
4. **Actions menu:** Bottom sheet with two options:
   - "Change Status" — shows a status picker (same values as the status filter: active, inStorage, toDonate, toSell, toHandDown)
   - "Change Location" — shows a text field dialog to enter a location
5. **Apply:** Updates all selected toys, clears selection, exits multi-select mode
6. **Cancel:** Close (X) button clears selection and exits multi-select mode

### State Changes

`InventoryState` gains:
- `isMultiSelectMode` (`bool`, default `false`)
- `selectedToyIds` (`Set<int>`, default empty)

`InventoryNotifier` gains:
- `enterMultiSelect(int toyId)` — enables multi-select and selects the long-pressed toy
- `toggleSelection(int toyId)` — add/remove from selection
- `selectAll()` — select all currently filtered toys
- `clearSelection()` — clear selection and exit multi-select mode
- `bulkUpdateStatus(String status)` — update status for all selected toys, then refresh
- `bulkUpdateLocation(String location)` — update location for all selected toys, then refresh

### Bulk Update Implementation

Bulk methods iterate `selectedToyIds` and call the existing `_db.updateToy()` for each toy inside a `batch` call for efficiency. After completion, call `_loadToys()` and `clearSelection()`.

### UI Changes

**`inventory_screen.dart`:**
- AppBar conditionally renders multi-select mode (selected count, close button, actions menu)
- Long-press handler on toy grid items

**`toy_card.dart`:**
- Accepts `isSelected` and `isMultiSelectMode` parameters
- When in multi-select mode: tap triggers selection toggle instead of navigation
- Selected state: semi-transparent overlay with checkmark icon (top-left corner)

**`toy_grid.dart`:**
- Passes selection state and callbacks through to `ToyCard`

**Files:**
- `lib/features/inventory/providers/inventory_provider.dart`
- `lib/features/inventory/screens/inventory_screen.dart`
- `lib/features/inventory/widgets/toy_card.dart`
- `lib/features/inventory/widgets/toy_grid.dart`

## Testing

- Unit test: `filteredToys` returns results matching description text
- Unit test: `filteredToys` respects sort option
- Widget test: sort dropdown appears and changes sort order
- Widget test: count badges display correct numbers
- Widget test: long-press enters multi-select mode
- Widget test: bulk status update modifies all selected toys

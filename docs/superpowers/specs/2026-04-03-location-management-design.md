# Location Management Design

## Overview

Add autocomplete to all location text fields using existing location values from the database. Prevents inconsistent entries like "Playroom" vs "playroom" vs "Play Room".

## Approach

No new screen. A reusable `LocationAutocompleteField` widget wraps Flutter's `Autocomplete<String>` and fetches distinct locations from `AppDatabase.getAllLocations()` (already exists). As the user types, matching existing locations appear in a dropdown. The user can still enter a new location not in the list.

## LocationAutocompleteField Widget

Parameters:
- `controller` (TextEditingController) — the text controller for the field
- `onChanged` (void Function(String)) — callback when value changes
- `decoration` (InputDecoration?) — optional custom decoration

Behavior:
- On focus/type, queries distinct locations and filters by input
- Case-insensitive matching
- Shows dropdown of matching existing locations
- Selecting a dropdown item fills the field
- Free text entry still allowed (not restricted to existing values)

## Integration Points

Replace the plain `TextFormField` for location in:
1. **Capture screen** — the location field in the lifecycle section
2. **Detail screen** — the location field in the edit form
3. **Inventory screen** — the bulk "Change Location" dialog

## File Map

| File | Change |
|------|--------|
| `lib/features/inventory/widgets/location_autocomplete_field.dart` | New: reusable autocomplete widget |
| `lib/features/capture/screens/capture_screen.dart` | Replace location TextFormField |
| `lib/features/inventory/screens/toy_detail_screen.dart` | Replace location TextFormField |
| `lib/features/inventory/screens/inventory_screen.dart` | Replace bulk location dialog TextField |

## Testing

- Widget test: autocomplete shows suggestions matching typed text
- Widget test: free text entry still works for new locations

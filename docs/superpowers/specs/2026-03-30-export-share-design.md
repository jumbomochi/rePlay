# Export & Share Lists Design

## Overview

Allow users to export the current filtered toy list as plain text (for messaging) or CSV (for spreadsheets) via the native share sheet.

## Trigger

An export/share icon button in the inventory screen AppBar, visible in normal mode, hidden in multi-select mode. Tapping opens a bottom sheet with two options: "Share as Text" and "Export as CSV".

If the filtered list is empty, show a snackbar "Nothing to export" instead of the bottom sheet.

## Scope

Exports the current `filteredToys` list — whatever is showing after status/category/search/sort filters. The user sees exactly what they're exporting.

## Text Format

```
rePlay Toy List (To Donate - 3 toys)

1. Wooden Puzzle — Good — Playroom
2. Teddy Bear — Fair — Bedroom
3. Soccer Ball — Fair — Garage
```

- Header includes the active status filter label (or "All" if no status filter) and toy count
- Each line: index, name, condition label, location (omitted if null)
- Shared via `Share.share()` from `share_plus` — opens native share sheet

## CSV Format

```csv
Name,Category,Condition,Location,Status,Date Added
Wooden Puzzle,Puzzles,Good,Playroom,To Donate,2026-01-15
Teddy Bear,Stuffed Animals,Fair,Bedroom,To Donate,2026-01-14
```

- Standard CSV with headers
- Condition and status use human-readable labels (not raw enum values)
- Date formatted as YYYY-MM-DD
- Values containing commas are quoted
- Saved to a temp file, shared via `Share.shareXFiles()` from `share_plus`

## Export Service

A standalone `ExportService` class with pure logic methods:

- `String generateTextList(List<Toy> toys, String filterLabel)` — returns the formatted text string
- `Future<String> generateCsvFile(List<Toy> toys)` — writes CSV to a temp file, returns the file path

No state, no dependencies beyond `path_provider` (for temp directory). Easily unit testable.

## New Dependency

`share_plus` — Flutter plugin for native sharing on iOS, Android, macOS, Windows, Linux, web.

## File Map

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `share_plus` dependency |
| `lib/core/services/export_service.dart` | New: text and CSV generation |
| `lib/features/inventory/screens/inventory_screen.dart` | Add share button to AppBar, bottom sheet for format selection |
| `test/export_service_test.dart` | New: unit tests for export formatting |

## Testing

- Unit test: `generateTextList` produces correct format with filter label and toy data
- Unit test: `generateTextList` handles toys with null location
- Unit test: `generateCsvFile` produces valid CSV with headers and correct data
- Unit test: CSV properly quotes values containing commas

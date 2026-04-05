# Backup & Restore Design

## Overview

Allow users to export the full toy database as a JSON file and import it back, providing a simple backup/restore mechanism.

## Navigation

Add a third tab "Settings" to the bottom navigation bar. The settings screen contains backup and restore buttons.

## Export (Backup)

Serialize all toys to a JSON file with this structure:

```json
{
  "version": 1,
  "exportedAt": "2026-04-03T12:00:00Z",
  "toys": [
    {
      "name": "Buzz Lightyear",
      "description": "To infinity and beyond!",
      "category": "Action Figures",
      "condition": "excellent",
      "location": "Bedroom",
      "status": "active",
      "owner": null,
      "aiLabels": "[\"action figure\", \"space\"]",
      "createdAt": "2026-01-15T10:00:00Z",
      "updatedAt": "2026-01-15T10:00:00Z"
    }
  ]
}
```

Does NOT include image files or image paths (not portable across devices). Does NOT include toy_images records (additional photos). Focuses on the metadata that matters for inventory tracking.

Shared via `Share.shareXFiles()` from `share_plus` as a `.json` file.

## Import (Restore)

Pick a `.json` file via `file_picker` package. Validate the structure (check `version` field, validate `toys` array).

**Import strategy: additive only.** Imports toys that don't already exist. Duplicate detection: match by `name` + `createdAt` — if both match an existing toy, skip it. Does not delete or overwrite existing toys.

After import, shows a snackbar: "Imported X toys (Y skipped as duplicates)".

## New Dependency

`file_picker` — cross-platform file picker for selecting the backup JSON file.

## File Map

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `file_picker` dependency |
| `lib/core/services/backup_service.dart` | New: JSON export/import logic |
| `lib/core/services/services_provider.dart` | Add `backupServiceProvider` |
| `lib/features/settings/screens/settings_screen.dart` | New: settings screen with backup/restore |
| `lib/app.dart` | Add Settings as third bottom nav tab |
| `test/backup_service_test.dart` | New: unit tests for serialization/deserialization |

## Testing

- Unit test: export produces valid JSON with correct structure
- Unit test: import parses JSON and returns toy data
- Unit test: duplicate detection skips matching toys
- Unit test: import handles missing/extra fields gracefully

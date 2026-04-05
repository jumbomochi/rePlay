# Change History / Activity Log Design

## Overview

Automatically record status and condition changes for each toy in a history table. Display a timeline on the toy detail screen.

## Database

### New Table: `ToyHistory`

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| id | INT | No | Auto-increment | Primary key |
| toyId | INT | No | - | References toys.id |
| field | TEXT | No | - | "status" or "condition" |
| oldValue | TEXT | No | - | Previous value |
| newValue | TEXT | No | - | New value |
| createdAt | DATETIME | No | Now | When the change happened |

Schema bumps from 4 to 5 (after owner field adds v4). Migration creates the table.

Note: Schema version depends on task 9 (owner) being implemented first, bringing schema to v4. This task bumps to v5.

### Database Methods

- `getHistoryForToy(int toyId)` — returns `List<ToyHistoryData>` ordered by `createdAt` descending
- `insertHistory(ToyHistoryCompanion)` — insert a history record
- `deleteHistoryForToy(int toyId)` — cleanup when toy is deleted

## Automatic Recording

In `InventoryNotifier.updateToy()`, before performing the update:
1. Fetch the existing toy
2. Compare `status` and `condition` fields
3. If either changed, insert a history record with the old and new values

This is transparent to the caller — no extra code needed at call sites.

## Toy Deletion Cleanup

When a toy is deleted, `deleteHistoryForToy()` is called to clean up history records.

## Detail Screen

In view mode, add a "History" section below the existing details (AI labels, date added). Shows a chronological list (most recent first):

```
History
─────────────────
Apr 3 — Status: Active → In Storage
Mar 15 — Condition: Good → Poor
Jan 10 — Status: In Storage → Active
```

Each entry shows: date, field label, old value → new value. Uses human-readable labels from `AppConstants`.

Hidden when no history exists for the toy.

## File Map

| File | Change |
|------|--------|
| `lib/core/database/tables/toys_table.dart` | Add `ToyHistory` table |
| `lib/core/database/database.dart` | Register table, bump schema, add migration, add CRUD methods |
| `lib/core/database/database.g.dart` | Regenerated |
| `lib/features/inventory/providers/inventory_provider.dart` | Record history in `updateToy()`, add `toyHistoryProvider`, cleanup in `deleteToy()` |
| `lib/features/inventory/screens/toy_detail_screen.dart` | Add history timeline section |

## Testing

- Unit test: history record created when status changes
- Unit test: history record created when condition changes
- Unit test: no history record when status/condition unchanged
- Widget test: history section shows entries on detail screen

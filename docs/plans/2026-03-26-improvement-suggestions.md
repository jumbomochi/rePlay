# rePlay Improvement Suggestions

## High Impact, Low Effort

### 1. Sort Options on Inventory Screen
Add sort by name, date added, condition, or category. Currently toys are returned in insertion order with no way to reorder. A dropdown + `OrderingTerm` in the provider — minimal code.

### 2. Search Should Include Description
The filter in `inventory_provider.dart` searches name, aiLabels, and location but skips description. A parent searching "millennium falcon" won't find the LEGO set named "LEGO Star Wars Set".

### 3. Batch Status Changes
Moving multiple toys to "In Storage" one by one is painful. A long-press multi-select mode with bulk "Change Status" or "Change Location" actions would save real time and determine whether people actually maintain their inventory.

### 4. Toy Count Badges on Filters
The status filter tabs and category chips don't show counts. "To Donate (7)" is more useful than just "To Donate" — it answers "how many?" without tapping.

## High Impact, Medium Effort

### 5. Statistics Dashboard
A simple dashboard showing:
- Total toys, breakdown by status (pie/bar chart)
- Toys by category
- Condition distribution (how many need attention?)
- Recently added

Gives parents a reason to open the app even when not adding toys.

### 6. Multiple Photos Per Toy
Toys often need more than one angle — the box, accessories, damage for condition tracking. A `toy_images` table would enable a photo gallery on the detail screen.

### 7. Export & Share Lists
When it's time to donate or sell, parents need a list. Exporting "To Donate" toys as PDF or shareable text/image list closes the lifecycle loop.

### 8. Better Toy Identification with Vision LLM
ML Kit image labeling is generic — returns "toy", "figurine", "plastic" but can't identify a specific toy. Supplementing with a vision API (Claude, GPT-4o) for identification would improve the capture experience. Could be optional/on-demand to manage costs.

## Medium Impact, Strategic

### 9. Child/Owner Assignment
Families have multiple kids. A lightweight owner/child field per toy (plus filter) would help with hand-me-down tracking and answering "whose is this?"

### 10. Location Management Screen
Location is a free-text field, so "Playroom", "playroom", and "Play Room" become separate entries. A dedicated locations screen or autocomplete from existing values would keep data clean.

### 11. Backup & Restore
iCloud/Google Drive sync, or a simple JSON export/import, so users can rely on the app without fear of data loss.

### 12. Change History / Activity Log
When a toy's status changes, there's no record of when or why. A simple changelog per toy adds accountability and helps track lifecycle over time.

## Lower Priority

### 13. List View Toggle
Grid is nice for photos but a compact list is faster to scan for large collections.

### 14. Custom Categories
The 10 seeded categories can't be edited from the UI.

### 15. Onboarding Flow
First-time users see an empty grid with no guidance.

### 16. Barcode/UPC Scanning
Many commercial toys have barcodes; scanning could auto-populate name/details from a product database.

### 17. Desktop Parity
ML Kit doesn't work on macOS; the app runs but AI features silently return empty results with no user feedback.

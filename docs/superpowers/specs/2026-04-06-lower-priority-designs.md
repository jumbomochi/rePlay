# Lower Priority Improvements (Tasks 13-17) Design

## Task 13: List View Toggle

A toggle button next to the sort dropdown that switches between 2-column grid and compact list view. List view shows: small square thumbnail, name, category, owner, condition — one toy per row.

**State:** `isListView` bool added to `InventoryState`, default `false`. `setViewMode(bool)` method on notifier.

**UI:** Toggle icon button (grid/list icon) in the sort row. `ToyGrid` conditionally renders `GridView.builder` or `ListView.builder` based on `isListView`.

**Files:**
- `lib/features/inventory/providers/inventory_provider.dart` — add `isListView` state
- `lib/features/inventory/widgets/toy_grid.dart` — conditional grid/list layout
- `lib/features/inventory/widgets/toy_list_item.dart` — new: compact list row widget
- `lib/features/inventory/screens/inventory_screen.dart` — add toggle button

## Task 14: Custom Categories

CRUD for categories from the Settings screen. A "Manage Categories" list tile opens a screen with the existing categories list (deletable) and a text field to add new ones.

**Rules:**
- New categories get the default "category" icon
- Deleting a category that has toys assigned shows a confirmation warning
- The 10 seeded categories can be deleted if the user wants
- Category names must be unique

**Database methods needed:** `insertCategory(name)`, `deleteCategory(id)` — `getAllCategories()` already exists.

**Files:**
- `lib/core/database/database.dart` — add `insertCategory`, `deleteCategory` methods
- `lib/features/settings/screens/manage_categories_screen.dart` — new: category CRUD screen
- `lib/features/settings/screens/settings_screen.dart` — add "Manage Categories" list tile

## Task 15: Onboarding Flow

3-page onboarding shown on first launch only.

**Pages:**
1. "Welcome to rePlay" — app name, toy icon, tagline "Organize your family's toy collection"
2. "Capture" — camera icon, "Take a photo and let AI identify your toys"
3. "Organize" — filter icon, "Track status, condition, and location. Export lists when it's time to donate or sell."

**Navigation:** `PageView` with dot indicators. "Skip" text button on pages 1-2. "Get Started" button on page 3.

**First-launch detection:** `shared_preferences` package. Key `onboarding_complete` set to `true` after completion. Checked in `main.dart` before showing the app.

**New dependency:** `shared_preferences`

**Files:**
- `pubspec.yaml` — add `shared_preferences`
- `lib/features/onboarding/screens/onboarding_screen.dart` — new: 3-page PageView
- `lib/main.dart` — check onboarding flag, show onboarding or app

## Task 16: Barcode/UPC Scanning

Add barcode scanning as an option on the capture screen. Scans UPC/EAN codes and looks up product name via a free API.

**Flow:**
1. User taps "Take Photo" → bottom sheet now has 3 options: Camera, Gallery, Scan Barcode
2. Scan Barcode opens `MobileScanner` widget in a full-screen overlay
3. On scan, queries `https://world.openfoodfacts.org/api/v2/product/{barcode}.json` (free, no API key)
4. If product found, auto-fills toy name from product name
5. If not found, shows snackbar "Product not found" and returns to manual entry
6. After name is filled, user still needs to take a photo separately

**New dependency:** `mobile_scanner`

**Files:**
- `pubspec.yaml` — add `mobile_scanner`
- `lib/core/services/barcode_lookup_service.dart` — new: barcode API lookup
- `lib/features/capture/screens/barcode_scanner_screen.dart` — new: scanner overlay
- `lib/features/capture/screens/capture_screen.dart` — add barcode option to bottom sheet

## Task 17: Desktop Parity

Show an info banner on the capture screen when running on desktop (macOS/Windows/Linux) explaining that ML Kit and barcode scanning aren't available, but Claude AI identification works.

**Banner:** A `MaterialBanner` or subtle `Card` at the top of the capture screen body: "Running on desktop — AI labels and barcode scanning require a mobile device. Use 'Identify with AI' for toy recognition."

Only shown when `!Platform.isIOS && !Platform.isAndroid`. Dismissible (tap X to hide for the session).

**Files:**
- `lib/features/capture/screens/capture_screen.dart` — add platform check and info banner

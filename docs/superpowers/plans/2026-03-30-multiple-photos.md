# Multiple Photos Per Toy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow toys to have up to 10 additional photos stored in a new `toy_images` table, with a horizontal thumbnail gallery on the detail screen.

**Architecture:** Add a `ToyImages` Drift table, bump schema to v3 with migration, add CRUD methods, create a `toyImagesProvider`, and add a photo gallery strip to `ToyDetailScreen`. The existing cover photo on the `toys` table is unchanged. Image storage reuses `ImageStorageService`.

**Tech Stack:** Flutter, Drift (SQLite), Riverpod, image_picker

---

## File Map

| File | Change |
|------|--------|
| `lib/core/database/tables/toys_table.dart` | Add `ToyImages` table class |
| `lib/core/database/database.dart` | Register table, bump schema, add migration, add CRUD methods |
| `lib/core/database/database.g.dart` | Regenerated |
| `lib/features/inventory/providers/inventory_provider.dart` | Add `toyImagesProvider`, update `deleteToy` |
| `lib/features/inventory/widgets/photo_gallery_strip.dart` | New: horizontal thumbnail strip widget |
| `lib/features/inventory/screens/toy_detail_screen.dart` | Integrate gallery strip below cover image |

---

### Task 1: ToyImages Table and Migration

**Files:**
- Modify: `lib/core/database/tables/toys_table.dart`
- Modify: `lib/core/database/database.dart`
- Regenerate: `lib/core/database/database.g.dart`

- [ ] **Step 1: Add ToyImages table definition**

In `lib/core/database/tables/toys_table.dart`, add after the `Categories` class:

```dart
class ToyImages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get toyId => integer()();
  TextColumn get imagePath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

- [ ] **Step 2: Register table and bump schema in database.dart**

In `lib/core/database/database.dart`, change the `@DriftDatabase` annotation:

```dart
@DriftDatabase(tables: [Toys, Categories, ToyImages])
```

Change `schemaVersion`:

```dart
@override
int get schemaVersion => 3;
```

Add migration for version 3 in the `onUpgrade` callback, after the `if (from < 2)` block:

```dart
        if (from < 3) {
          await m.createTable(toyImages);
        }
```

- [ ] **Step 3: Add ToyImages CRUD methods to database.dart**

Add these methods to `AppDatabase`, after the category operations:

```dart
  // ToyImages operations
  Future<List<ToyImage>> getImagesForToy(int toyId) {
    return (select(toyImages)
          ..where((t) => t.toyId.equals(toyId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<int> insertToyImage(ToyImagesCompanion image) {
    return into(toyImages).insert(image);
  }

  Future<int> deleteToyImage(int id) {
    return (delete(toyImages)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteImagesForToy(int toyId) {
    return (delete(toyImages)..where((t) => t.toyId.equals(toyId))).go();
  }

  Future<int> countImagesForToy(int toyId) async {
    final count = countAll();
    final query = selectOnly(toyImages)
      ..addColumns([count])
      ..where(toyImages.toyId.equals(toyId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
```

- [ ] **Step 4: Regenerate database code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `database.g.dart` regenerated with `ToyImage`, `ToyImagesCompanion`, `$ToyImagesTable`.

- [ ] **Step 5: Run existing tests to verify nothing broke**

Run: `flutter test`
Expected: All 16 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/database/
git commit -m "feat: add ToyImages table with schema v3 migration"
```

---

### Task 2: ToyImages Provider and deleteToy Cleanup

**Files:**
- Modify: `lib/features/inventory/providers/inventory_provider.dart`

- [ ] **Step 1: Add toyImagesProvider**

In `lib/features/inventory/providers/inventory_provider.dart`, add at the bottom of the file:

```dart
// Additional images for a toy
final toyImagesProvider = FutureProvider.family<List<ToyImage>, int>((ref, toyId) async {
  final db = ref.watch(databaseProvider);
  return db.getImagesForToy(toyId);
});
```

This requires adding `ToyImage` to the available types — it's already exported from `database.dart` via the generated code.

- [ ] **Step 2: Update deleteToy to clean up additional images**

In `InventoryNotifier.deleteToy()`, add cleanup of additional images before deleting the toy. Replace the current `deleteToy` method:

```dart
  Future<bool> deleteToy(int id) async {
    try {
      final toy = await _db.getToyById(id);
      // Delete additional images
      final additionalImages = await _db.getImagesForToy(id);
      for (final img in additionalImages) {
        await _imageStorage.deleteImage(
          img.imagePath,
          thumbnailPath: img.thumbnailPath,
        );
      }
      await _db.deleteImagesForToy(id);
      // Delete cover image
      await _imageStorage.deleteImage(
        toy.imagePath,
        thumbnailPath: toy.thumbnailPath,
      );
      await _db.deleteToy(id);
      await _loadToys();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
```

- [ ] **Step 3: Run tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/inventory/providers/inventory_provider.dart
git commit -m "feat: add toyImagesProvider and cleanup on toy deletion"
```

---

### Task 3: Photo Gallery Strip Widget

**Files:**
- Create: `lib/features/inventory/widgets/photo_gallery_strip.dart`

- [ ] **Step 1: Create the gallery strip widget**

Create `lib/features/inventory/widgets/photo_gallery_strip.dart`:

```dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/database/database.dart';

class PhotoGalleryStrip extends StatelessWidget {
  final String? coverImagePath;
  final String? coverThumbnailPath;
  final List<ToyImage> additionalImages;
  final int selectedIndex;
  final void Function(int index) onThumbnailTap;
  final VoidCallback? onAddPhoto;
  final void Function(int imageId)? onDeletePhoto;
  final int maxPhotos;

  const PhotoGalleryStrip({
    super.key,
    this.coverImagePath,
    this.coverThumbnailPath,
    required this.additionalImages,
    this.selectedIndex = 0,
    required this.onThumbnailTap,
    this.onAddPhoto,
    this.onDeletePhoto,
    this.maxPhotos = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCover = coverImagePath != null && coverImagePath!.isNotEmpty;
    final totalPhotos = additionalImages.length + (hasCover ? 1 : 0);

    if (!hasCover && additionalImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: totalPhotos + (totalPhotos < maxPhotos && onAddPhoto != null ? 1 : 0),
        itemBuilder: (context, index) {
          // Add button at the end
          if (index == totalPhotos) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onAddPhoto,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 20, color: theme.colorScheme.outline),
                      const SizedBox(height: 2),
                      Text(
                        '$totalPhotos/$maxPhotos',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Cover photo thumbnail (index 0)
          if (hasCover && index == 0) {
            final thumbPath = coverThumbnailPath ?? coverImagePath!;
            return _buildThumbnail(
              context: context,
              imagePath: thumbPath,
              isSelected: selectedIndex == 0,
              onTap: () => onThumbnailTap(0),
              onLongPress: null, // Can't delete cover photo
            );
          }

          // Additional photo thumbnails
          final imageIndex = hasCover ? index - 1 : index;
          final image = additionalImages[imageIndex];
          final thumbPath = image.thumbnailPath ?? image.imagePath;
          return _buildThumbnail(
            context: context,
            imagePath: thumbPath,
            isSelected: selectedIndex == index,
            onTap: () => onThumbnailTap(index),
            onLongPress: onDeletePhoto != null
                ? () => onDeletePhoto!(image.id)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildThumbnail({
    required BuildContext context,
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: FutureBuilder<bool>(
              future: File(imagePath).exists(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  );
                }
                return Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.image, size: 24, color: Colors.grey[400]),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze to check for issues**

Run: `flutter analyze lib/features/inventory/widgets/photo_gallery_strip.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/inventory/widgets/photo_gallery_strip.dart
git commit -m "feat: add photo gallery strip widget"
```

---

### Task 4: Integrate Gallery into Detail Screen

**Files:**
- Modify: `lib/features/inventory/screens/toy_detail_screen.dart`

- [ ] **Step 1: Add gallery state and imports**

At the top of `toy_detail_screen.dart`, add imports:

```dart
import 'package:image_picker/image_picker.dart';

import '../../../core/services/services_provider.dart';
import '../widgets/photo_gallery_strip.dart';
```

In `_ToyDetailScreenState`, add state field:

```dart
  int _selectedPhotoIndex = 0;
```

- [ ] **Step 2: Update the build method to show gallery**

In the `data:` callback of `toyAsync.when()`, after the line `final aiLabels = _parseAiLabels(toy.aiLabels);`, add:

```dart
        final toyImagesAsync = ref.watch(toyImagesProvider(widget.toyId));
        final additionalImages = toyImagesAsync.valueOrNull ?? [];
```

In the `body: SingleChildScrollView` → `Column` → `children`, replace:

```dart
                _buildImage(toy.imagePath),
```

with:

```dart
                _buildMainImage(toy, additionalImages),
                if (toy.imagePath.isNotEmpty || additionalImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: PhotoGalleryStrip(
                      coverImagePath: toy.imagePath,
                      coverThumbnailPath: toy.thumbnailPath,
                      additionalImages: additionalImages,
                      selectedIndex: _selectedPhotoIndex,
                      onThumbnailTap: (index) {
                        setState(() => _selectedPhotoIndex = index);
                      },
                      onAddPhoto: () => _addPhoto(toy.id),
                      onDeletePhoto: (imageId) => _confirmDeletePhoto(imageId),
                    ),
                  ),
```

- [ ] **Step 3: Add _buildMainImage method**

Replace the existing `_buildImage` method with `_buildMainImage`:

```dart
  Widget _buildMainImage(Toy toy, List<ToyImage> additionalImages) {
    String imagePath;
    if (_selectedPhotoIndex == 0) {
      imagePath = toy.imagePath;
    } else {
      final imgIndex = _selectedPhotoIndex - (toy.imagePath.isNotEmpty ? 1 : 0);
      if (imgIndex >= 0 && imgIndex < additionalImages.length) {
        imagePath = additionalImages[imgIndex].imagePath;
      } else {
        imagePath = toy.imagePath;
      }
    }

    return AspectRatio(
      aspectRatio: 1,
      child: FutureBuilder<bool>(
        future: File(imagePath).exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return Image.file(
              File(imagePath),
              fit: BoxFit.cover,
            );
          }
          return Container(
            color: Colors.grey[200],
            child: Icon(
              Icons.toys,
              size: 80,
              color: Colors.grey[400],
            ),
          );
        },
      ),
    );
  }
```

- [ ] **Step 4: Add _addPhoto and _confirmDeletePhoto methods**

Add these methods to `_ToyDetailScreenState`:

```dart
  Future<void> _addPhoto(int toyId) async {
    final db = ref.read(databaseProvider);
    final imageCount = await db.countImagesForToy(toyId);
    if (imageCount >= 10) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 10 additional photos reached')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final imageStorage = ref.read(imageStorageServiceProvider);
    final saved = await imageStorage.saveImage(File(pickedFile.path));

    final currentCount = await db.countImagesForToy(toyId);
    await db.insertToyImage(ToyImagesCompanion.insert(
      toyId: toyId,
      imagePath: saved.imagePath,
      thumbnailPath: Value(saved.thumbnailPath),
      sortOrder: Value(currentCount),
    ));

    ref.invalidate(toyImagesProvider(toyId));
  }

  void _confirmDeletePhoto(int imageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Remove this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePhoto(imageId);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePhoto(int imageId) async {
    final db = ref.read(databaseProvider);
    final imageStorage = ref.read(imageStorageServiceProvider);

    // Get the image data before deleting
    final images = await db.getImagesForToy(widget.toyId);
    final image = images.firstWhere((i) => i.id == imageId);

    await imageStorage.deleteImage(
      image.imagePath,
      thumbnailPath: image.thumbnailPath,
    );
    await db.deleteToyImage(imageId);

    setState(() => _selectedPhotoIndex = 0);
    ref.invalidate(toyImagesProvider(widget.toyId));
  }
```

- [ ] **Step 5: Add necessary imports for Drift Value**

Make sure the imports at the top include:

```dart
import 'package:drift/drift.dart' show Value;
```

- [ ] **Step 6: Run all tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 7: Run flutter analyze**

Run: `flutter analyze`
Expected: No new issues.

- [ ] **Step 8: Commit**

```bash
git add lib/features/inventory/screens/toy_detail_screen.dart
git commit -m "feat: add photo gallery to toy detail screen"
```

---

### Task 5: Final Verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No new analysis issues.

- [ ] **Step 3: Fix any issues found**

If there are issues, fix and commit.

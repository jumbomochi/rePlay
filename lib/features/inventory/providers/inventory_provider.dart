import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../core/services/services_provider.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  // Seed mock data for development
  db.seedMockToys();
  ref.onDispose(() => db.close());
  return db;
});

enum SortOption {
  newestFirst('Newest First'),
  oldestFirst('Oldest First'),
  nameAsc('Name A-Z'),
  nameDesc('Name Z-A'),
  category('Category');

  const SortOption(this.label);
  final String label;
}

// Inventory state
class InventoryState {
  final List<Toy> toys;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;
  final String searchQuery;
  final String? selectedStatus;
  final SortOption sortBy;
  final bool isMultiSelectMode;
  final Set<int> selectedToyIds;

  InventoryState({
    this.toys = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
    this.searchQuery = '',
    this.selectedStatus,
    this.sortBy = SortOption.newestFirst,
    this.isMultiSelectMode = false,
    this.selectedToyIds = const {},
  });

  InventoryState copyWith({
    List<Toy>? toys,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? searchQuery,
    String? selectedStatus,
    SortOption? sortBy,
    bool? isMultiSelectMode,
    Set<int>? selectedToyIds,
  }) {
    return InventoryState(
      toys: toys ?? this.toys,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      sortBy: sortBy ?? this.sortBy,
      isMultiSelectMode: isMultiSelectMode ?? this.isMultiSelectMode,
      selectedToyIds: selectedToyIds ?? this.selectedToyIds,
    );
  }

  List<Toy> get filteredToys {
    var result = List<Toy>.from(toys);

    if (selectedStatus != null && selectedStatus!.isNotEmpty) {
      result = result.where((t) => t.status == selectedStatus).toList();
    }

    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      result = result.where((t) => t.category == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((t) {
        return t.name.toLowerCase().contains(query) ||
            (t.description?.toLowerCase().contains(query) ?? false) ||
            t.aiLabels.toLowerCase().contains(query) ||
            (t.location?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    switch (sortBy) {
      case SortOption.newestFirst:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.oldestFirst:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOption.nameAsc:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case SortOption.nameDesc:
        result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case SortOption.category:
        result.sort((a, b) => a.category.compareTo(b.category));
    }

    return result;
  }
}

// Inventory notifier
class InventoryNotifier extends StateNotifier<InventoryState> {
  final AppDatabase _db;
  final ImageStorageService _imageStorage;

  InventoryNotifier(this._db, this._imageStorage)
      : super(InventoryState()) {
    _loadToys();
  }

  Future<void> _loadToys() async {
    state = state.copyWith(isLoading: true);
    try {
      final toys = await _db.getAllToys();
      state = state.copyWith(toys: toys, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> refresh() async {
    await _loadToys();
  }

  Future<Toy?> addToy({
    required String name,
    String? description,
    required String imagePath,
    String? thumbnailPath,
    required String category,
    List<String> aiLabels = const [],
    String? condition,
    String? location,
    String? status,
  }) async {
    try {
      final id = await _db.insertToy(ToysCompanion.insert(
        name: name,
        description: Value(description),
        imagePath: imagePath,
        thumbnailPath: Value(thumbnailPath),
        category: Value(category),
        aiLabels: Value(jsonEncode(aiLabels)),
        condition: Value(condition ?? 'good'),
        location: Value(location),
        status: Value(status ?? 'active'),
      ));

      await _loadToys();
      return await _db.getToyById(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> updateToy({
    required int id,
    String? name,
    String? description,
    String? category,
    String? condition,
    String? location,
    String? status,
  }) async {
    try {
      final existing = await _db.getToyById(id);
      await _db.updateToy(ToysCompanion(
        id: Value(id),
        name: Value(name ?? existing.name),
        description: Value(description ?? existing.description),
        imagePath: Value(existing.imagePath),
        thumbnailPath: Value(existing.thumbnailPath),
        category: Value(category ?? existing.category),
        aiLabels: Value(existing.aiLabels),
        createdAt: Value(existing.createdAt),
        updatedAt: Value(DateTime.now()),
        condition: Value(condition ?? existing.condition),
        location: Value(location ?? existing.location),
        status: Value(status ?? existing.status),
      ));
      await _loadToys();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

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

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatus(String? status) {
    state = state.copyWith(selectedStatus: status);
  }

  void setSortOption(SortOption option) {
    state = state.copyWith(sortBy: option);
  }

  void clearFilters() {
    state = state.copyWith(
      selectedCategory: null,
      searchQuery: '',
      selectedStatus: null,
      sortBy: SortOption.newestFirst,
    );
  }

  void enterMultiSelect(int toyId) {
    state = state.copyWith(
      isMultiSelectMode: true,
      selectedToyIds: {toyId},
    );
  }

  void toggleSelection(int toyId) {
    final selected = Set<int>.from(state.selectedToyIds);
    if (selected.contains(toyId)) {
      selected.remove(toyId);
    } else {
      selected.add(toyId);
    }
    state = state.copyWith(selectedToyIds: selected);
  }

  void selectAll() {
    final allIds = state.filteredToys.map((t) => t.id).toSet();
    state = state.copyWith(selectedToyIds: allIds);
  }

  void clearSelection() {
    state = state.copyWith(
      isMultiSelectMode: false,
      selectedToyIds: {},
    );
  }

  Future<void> bulkUpdateStatus(String status) async {
    for (final id in state.selectedToyIds) {
      await updateToy(id: id, status: status);
    }
    clearSelection();
  }

  Future<void> bulkUpdateLocation(String location) async {
    for (final id in state.selectedToyIds) {
      await updateToy(id: id, location: location);
    }
    clearSelection();
  }
}

// Inventory provider
final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  return InventoryNotifier(
    ref.watch(databaseProvider),
    ref.watch(imageStorageServiceProvider),
  );
});

// Single toy provider for detail view
final toyByIdProvider = FutureProvider.family<Toy?, int>((ref, id) async {
  final db = ref.watch(databaseProvider);
  try {
    return await db.getToyById(id);
  } catch (e) {
    return null;
  }
});

// Additional images for a toy
final toyImagesProvider = FutureProvider.family<List<ToyImage>, int>((ref, toyId) async {
  final db = ref.watch(databaseProvider);
  return db.getImagesForToy(toyId);
});

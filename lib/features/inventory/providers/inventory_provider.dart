import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../core/services/services_provider.dart';

// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// Inventory state
class InventoryState {
  final List<Toy> toys;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;
  final String searchQuery;
  final String? selectedStatus;

  InventoryState({
    this.toys = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
    this.searchQuery = '',
    this.selectedStatus,
  });

  InventoryState copyWith({
    List<Toy>? toys,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? searchQuery,
    String? selectedStatus,
  }) {
    return InventoryState(
      toys: toys ?? this.toys,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
    );
  }

  List<Toy> get filteredToys {
    var result = toys;

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
            t.aiLabels.toLowerCase().contains(query) ||
            (t.location?.toLowerCase().contains(query) ?? false);
      }).toList();
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
  }) async {
    try {
      final id = await _db.insertToy(ToysCompanion.insert(
        name: name,
        description: Value(description),
        imagePath: imagePath,
        thumbnailPath: Value(thumbnailPath),
        category: Value(category),
        aiLabels: Value(jsonEncode(aiLabels)),
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

  void clearFilters() {
    state = state.copyWith(selectedCategory: null, searchQuery: '', selectedStatus: null);
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

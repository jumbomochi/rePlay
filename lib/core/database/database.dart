import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/toys_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Toys, Categories, ToyImages])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedCategories();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(toys, toys.condition);
          await m.addColumn(toys, toys.location);
          await m.addColumn(toys, toys.status);
        }
        if (from < 3) {
          await m.createTable(toyImages);
        }
      },
    );
  }

  Future<void> _seedCategories() async {
    final defaultCategories = [
      CategoriesCompanion.insert(name: 'Action Figures', iconName: const Value('sports_martial_arts'), sortOrder: const Value(1)),
      CategoriesCompanion.insert(name: 'Dolls', iconName: const Value('face'), sortOrder: const Value(2)),
      CategoriesCompanion.insert(name: 'Building Blocks', iconName: const Value('view_in_ar'), sortOrder: const Value(3)),
      CategoriesCompanion.insert(name: 'Vehicles', iconName: const Value('directions_car'), sortOrder: const Value(4)),
      CategoriesCompanion.insert(name: 'Puzzles', iconName: const Value('extension'), sortOrder: const Value(5)),
      CategoriesCompanion.insert(name: 'Board Games', iconName: const Value('casino'), sortOrder: const Value(6)),
      CategoriesCompanion.insert(name: 'Stuffed Animals', iconName: const Value('pets'), sortOrder: const Value(7)),
      CategoriesCompanion.insert(name: 'Educational', iconName: const Value('school'), sortOrder: const Value(8)),
      CategoriesCompanion.insert(name: 'Outdoor', iconName: const Value('park'), sortOrder: const Value(9)),
      CategoriesCompanion.insert(name: 'Other', iconName: const Value('category'), sortOrder: const Value(10)),
    ];

    await batch((batch) {
      batch.insertAll(categories, defaultCategories);
    });
  }

  // Toy CRUD operations
  Future<List<Toy>> getAllToys() => select(toys).get();

  Stream<List<Toy>> watchAllToys() => select(toys).watch();

  Future<Toy> getToyById(int id) =>
      (select(toys)..where((t) => t.id.equals(id))).getSingle();

  Future<int> insertToy(ToysCompanion toy) => into(toys).insert(toy);

  Future<bool> updateToy(ToysCompanion toy) => update(toys).replace(toy);

  Future<int> deleteToy(int id) =>
      (delete(toys)..where((t) => t.id.equals(id))).go();

  Stream<List<Toy>> watchToysByCategory(String category) {
    return (select(toys)..where((t) => t.category.equals(category))).watch();
  }

  Future<List<Toy>> searchToys(String query) {
    return (select(toys)
      ..where((t) =>
          t.name.lower().contains(query.toLowerCase()) |
          t.aiLabels.lower().contains(query.toLowerCase())))
      .get();
  }

  // Get all distinct locations for autocomplete
  Future<List<String>> getAllLocations() async {
    final result = await customSelect(
      'SELECT DISTINCT location FROM toys WHERE location IS NOT NULL ORDER BY location',
    ).get();
    return result.map((row) => row.read<String>('location')).toList();
  }

  // Get toys by status
  Future<List<Toy>> getToysByStatus(String status) {
    return (select(toys)..where((t) => t.status.equals(status))).get();
  }

  // Count toys by status
  Future<Map<String, int>> getStatusCounts() async {
    final result = await customSelect(
      'SELECT status, COUNT(*) as count FROM toys GROUP BY status',
    ).get();
    return {
      for (final row in result)
        row.read<String>('status'): row.read<int>('count')
    };
  }

  // Category operations
  Future<List<Category>> getAllCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();

  Stream<List<Category>> watchAllCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).watch();

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

  // Seed mock data for development
  Future<void> seedMockToys() async {
    final existingToys = await getAllToys();
    if (existingToys.isNotEmpty) return; // Don't seed if toys exist

    final mockToys = [
      ToysCompanion.insert(
        name: 'Buzz Lightyear',
        description: const Value('To infinity and beyond!'),
        imagePath: '',
        category: const Value('Action Figures'),
        aiLabels: const Value('["action figure", "space", "toy"]'),
        condition: const Value('excellent'),
        location: const Value('Bedroom'),
        status: const Value('active'),
      ),
      ToysCompanion.insert(
        name: 'LEGO Star Wars Set',
        description: const Value('Millennium Falcon building set'),
        imagePath: '',
        category: const Value('Building Blocks'),
        aiLabels: const Value('["lego", "building", "star wars"]'),
        condition: const Value('good'),
        location: const Value('Playroom'),
        status: const Value('active'),
      ),
      ToysCompanion.insert(
        name: 'Teddy Bear',
        description: const Value('Soft brown teddy bear'),
        imagePath: '',
        category: const Value('Stuffed Animals'),
        aiLabels: const Value('["stuffed animal", "bear", "plush"]'),
        condition: const Value('fair'),
        location: const Value('Bedroom'),
        status: const Value('active'),
      ),
      ToysCompanion.insert(
        name: 'Hot Wheels Car',
        description: const Value('Red race car'),
        imagePath: '',
        category: const Value('Vehicles'),
        aiLabels: const Value('["car", "vehicle", "race"]'),
        condition: const Value('good'),
        location: const Value('Toy Box'),
        status: const Value('inStorage'),
      ),
      ToysCompanion.insert(
        name: 'Barbie Doll',
        description: const Value('Fashion doll with accessories'),
        imagePath: '',
        category: const Value('Dolls'),
        aiLabels: const Value('["doll", "fashion", "barbie"]'),
        condition: const Value('excellent'),
        location: const Value('Playroom'),
        status: const Value('active'),
      ),
      ToysCompanion.insert(
        name: 'Wooden Puzzle',
        description: const Value('Animal shapes puzzle'),
        imagePath: '',
        category: const Value('Puzzles'),
        aiLabels: const Value('["puzzle", "wood", "animals"]'),
        condition: const Value('good'),
        status: const Value('toDonate'),
      ),
      ToysCompanion.insert(
        name: 'Soccer Ball',
        description: const Value('Size 4 soccer ball'),
        imagePath: '',
        category: const Value('Outdoor'),
        aiLabels: const Value('["ball", "soccer", "sports"]'),
        condition: const Value('fair'),
        location: const Value('Garage'),
        status: const Value('active'),
      ),
      ToysCompanion.insert(
        name: 'Monopoly',
        description: const Value('Classic board game'),
        imagePath: '',
        category: const Value('Board Games'),
        aiLabels: const Value('["board game", "monopoly"]'),
        condition: const Value('good'),
        location: const Value('Closet'),
        status: const Value('toSell'),
      ),
    ];

    await batch((batch) {
      batch.insertAll(toys, mockToys);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'replay.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

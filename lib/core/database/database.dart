import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/toys_table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Toys, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedCategories();
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

  // Category operations
  Future<List<Category>> getAllCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).get();

  Stream<List<Category>> watchAllCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).watch();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'replay.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

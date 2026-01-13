import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../inventory/providers/inventory_provider.dart';

// Categories stream provider
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllCategories();
});

// Category names only
final categoryNamesProvider = Provider<List<String>>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.when(
    data: (categories) => categories.map((c) => c.name).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database.dart';
import '../../../data/local/database_provider.dart';

// To access databaseProvider

class CategoriesRepository {
  final AppDatabase _db;

  CategoriesRepository(this._db);

  Future<List<Category>> getAllCategories() {
    return _db.select(_db.categories).get();
  }
}

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CategoriesRepository(db);
});

final categoriesListProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoriesRepositoryProvider);
  return repository.getAllCategories();
});

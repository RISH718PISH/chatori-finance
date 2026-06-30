import 'package:drift/drift.dart';

import '../../core/categories.dart';
import 'connection.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Transactions,
    Staff,
    SalaryRecords,
    AdvanceRecords,
    ScreenshotImports,
    Categories,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(String passphrase) : super(openEncryptedConnection(passphrase));

  /// For tests: inject any executor (e.g. an in-memory NativeDatabase).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCategories();
        },
      );

  Future<void> _seedCategories() async {
    await batch((b) {
      b.insertAll(
        categories,
        kSeedCategories
            .map(
              (c) => CategoriesCompanion.insert(
                id: c.id,
                name: c.name,
                kind: c.kind,
                icon: Value(c.icon),
                sortOrder: Value(c.sortOrder),
              ),
            )
            .toList(),
      );
    });
  }
}

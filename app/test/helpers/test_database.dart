import 'package:drift/native.dart';
import 'package:scatter_notes/core/database/app_database.dart';

/// Creates an isolated in-memory [AppDatabase] with FTS5 enabled for tests.
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

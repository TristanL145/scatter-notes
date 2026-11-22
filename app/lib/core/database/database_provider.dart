import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notes/data/notes_repository.dart';
import '../../features/organization/data/organization_repository.dart';
import 'app_database.dart';

/// Provides the singleton [AppDatabase] and closes it when the container
/// is disposed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provides [OrganizationRepository] backed by [appDatabaseProvider].
final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(ref.watch(appDatabaseProvider));
});

/// Provides [NotesRepository] backed by [appDatabaseProvider].
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(appDatabaseProvider));
});

/// Ensures default spaces (`School` and `Personal Projects`) exist on startup.
final bootstrapSpacesProvider = FutureProvider<void>((ref) async {
  await ref.watch(organizationRepositoryProvider).ensureDefaultSpaces();
});

/// Streams all active spaces ordered by sort order.
final spacesStreamProvider = StreamProvider<List<Space>>((ref) {
  return ref.watch(organizationRepositoryProvider).watchSpaces();
});

/// Streams active notes belonging to a specific [spaceId].
final notesBySpaceProvider = StreamProvider.family<List<Note>, String>((
  ref,
  spaceId,
) {
  return ref.watch(notesRepositoryProvider).watchNotes(spaceId: spaceId);
});

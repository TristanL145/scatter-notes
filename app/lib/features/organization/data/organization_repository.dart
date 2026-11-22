import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

/// Manages top-level organizational entities: [Space], [Collection]
/// (classes/projects), [Topic], and [Label].
class OrganizationRepository {
  OrganizationRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  /// Idempotently creates the default `School` and `Personal Projects` spaces
  /// when no active spaces exist yet.
  Future<void> ensureDefaultSpaces() async {
    final existing = await (_db.select(
      _db.spaces,
    )..where((t) => t.deletedAt.isNull())).get();
    if (existing.isNotEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    await _db.batch((batch) {
      batch.insertAll(_db.spaces, [
        SpacesCompanion.insert(
          id: _uuid.v4(),
          name: 'School',
          icon: const Value('school'),
          sortOrder: const Value(0),
          createdAt: now,
          updatedAt: now,
        ),
        SpacesCompanion.insert(
          id: _uuid.v4(),
          name: 'Personal Projects',
          icon: const Value('rocket_launch'),
          sortOrder: const Value(1),
          createdAt: now,
          updatedAt: now,
        ),
      ]);
    });
  }

  /// Watches all active (non-deleted) spaces ordered by [Spaces.sortOrder].
  Stream<List<Space>> watchSpaces() {
    return (_db.select(_db.spaces)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  /// Creates a new custom space and returns it.
  Future<Space> createSpace({
    required String name,
    String icon = 'folder',
    int sortOrder = 0,
  }) async {
    final now = DateTime.now().toUtc();
    final companion = SpacesCompanion.insert(
      id: _uuid.v4(),
      name: name.trim(),
      icon: Value(icon),
      sortOrder: Value(sortOrder),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.spaces).insert(companion);
    return (_db.select(
      _db.spaces,
    )..where((t) => t.id.equals(companion.id.value))).getSingle();
  }

  /// Soft-deletes a space by setting [Spaces.deletedAt].
  Future<void> softDeleteSpace(String spaceId) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.spaces)..where((t) => t.id.equals(spaceId))).write(
      SpacesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Watches collections (classes/projects) inside [spaceId].
  Stream<List<Collection>> watchCollections(
    String spaceId, {
    bool includeArchived = false,
  }) {
    return (_db.select(_db.collections)
          ..where((t) {
            final base = t.spaceId.equals(spaceId) & t.deletedAt.isNull();
            return includeArchived ? base : base & t.archived.equals(false);
          })
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  /// Creates a new class or project collection inside [spaceId].
  Future<Collection> createCollection({
    required String spaceId,
    required String name,
    String kind = 'class',
    String colorHex = '#4F46E5',
    int sortOrder = 0,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _db
        .into(_db.collections)
        .insert(
          CollectionsCompanion.insert(
            id: id,
            spaceId: spaceId,
            name: name.trim(),
            kind: Value(kind),
            colorHex: Value(colorHex),
            sortOrder: Value(sortOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (_db.select(
      _db.collections,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  /// Archives or unarchives a collection.
  Future<void> setCollectionArchived(
    String id, {
    required bool archived,
  }) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.collections)..where((t) => t.id.equals(id))).write(
      CollectionsCompanion(archived: Value(archived), updatedAt: Value(now)),
    );
  }

  /// Soft-deletes a collection.
  Future<void> softDeleteCollection(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.collections)..where((t) => t.id.equals(id))).write(
      CollectionsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Watches active topics inside [collectionId].
  Stream<List<Topic>> watchTopics(String collectionId) {
    return (_db.select(_db.topics)
          ..where(
            (t) => t.collectionId.equals(collectionId) & t.deletedAt.isNull(),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  /// Creates a topic inside [collectionId].
  Future<Topic> createTopic({
    required String collectionId,
    required String name,
    int sortOrder = 0,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _db
        .into(_db.topics)
        .insert(
          TopicsCompanion.insert(
            id: id,
            collectionId: collectionId,
            name: name.trim(),
            sortOrder: Value(sortOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (_db.select(_db.topics)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Soft-deletes a topic.
  Future<void> softDeleteTopic(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.topics)..where((t) => t.id.equals(id))).write(
      TopicsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Watches all active labels sorted alphabetically.
  Stream<List<Label>> watchLabels() {
    return (_db.select(_db.labels)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Creates a cross-cutting label.
  Future<Label> createLabel({
    required String name,
    String colorHex = '#0D9488',
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _db
        .into(_db.labels)
        .insert(
          LabelsCompanion.insert(
            id: id,
            name: name.trim(),
            colorHex: Value(colorHex),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (_db.select(_db.labels)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Soft-deletes a label.
  Future<void> softDeleteLabel(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.labels)..where((t) => t.id.equals(id))).write(
      LabelsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }
}

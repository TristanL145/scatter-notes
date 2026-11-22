import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../editor/domain/note_block_content.dart';

/// Persists notes, ordered structured blocks, label associations, internal
/// note links, and FTS5 search index updates.
class NotesRepository {
  NotesRepository(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  /// Creates a new note with optional initial [blocks] and [labelIds], and
  /// indexes it in `notes_fts`.
  Future<Note> createNote({
    required String spaceId,
    String? collectionId,
    String? topicId,
    String title = '',
    String? flowId,
    bool isPinned = false,
    List<NoteBlockInput> blocks = const [],
    List<String> labelIds = const [],
  }) async {
    final now = DateTime.now().toUtc();
    final noteId = _uuid.v4();
    final normalizedTitle = title.trim();

    await _db.transaction(() async {
      await _db
          .into(_db.notes)
          .insert(
            NotesCompanion.insert(
              id: noteId,
              spaceId: spaceId,
              collectionId: Value(collectionId),
              topicId: Value(topicId),
              title: Value(normalizedTitle),
              flowId: Value(flowId),
              isPinned: Value(isPinned),
              createdAt: now,
              updatedAt: now,
            ),
          );

      if (blocks.isNotEmpty) {
        await _insertBlocks(noteId: noteId, blocks: blocks, now: now);
      }

      if (labelIds.isNotEmpty) {
        final uniqueLabelIds = labelIds.toSet().toList();
        await _db.batch((batch) {
          batch.insertAll(
            _db.noteLabels,
            uniqueLabelIds
                .map(
                  (labelId) => NoteLabelsCompanion.insert(
                    noteId: noteId,
                    labelId: labelId,
                  ),
                )
                .toList(),
          );
        });
      }

      await _syncSearchIndexForNote(noteId);
    });

    return (_db.select(
      _db.notes,
    )..where((t) => t.id.equals(noteId))).getSingle();
  }

  /// Fetches a single active note by [noteId], or `null` if missing or deleted.
  Future<Note?> getNoteById(String noteId) {
    return (_db.select(_db.notes)
          ..where((t) => t.id.equals(noteId) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Fetches ordered content blocks for [noteId].
  Future<List<NoteBlock>> getNoteBlocks(String noteId) {
    return (_db.select(_db.noteBlocks)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
  }

  /// Watches ordered content blocks for [noteId].
  Stream<List<NoteBlock>> watchNoteBlocks(String noteId) {
    return (_db.select(_db.noteBlocks)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .watch();
  }

  /// Watches active notes filtered by optional organizational facets, sorted
  /// with pinned notes first and then most recently updated.
  Stream<List<Note>> watchNotes({
    String? spaceId,
    String? collectionId,
    String? topicId,
    String? labelId,
    bool inboxOnly = false,
  }) {
    if (labelId != null) {
      final query = _db.select(_db.notes).join([
        innerJoin(
          _db.noteLabels,
          _db.noteLabels.noteId.equalsExp(_db.notes.id),
        ),
      ]);
      query.where(
        _noteFilterExpr(
              spaceId: spaceId,
              collectionId: collectionId,
              topicId: topicId,
              inboxOnly: inboxOnly,
            ) &
            _db.noteLabels.labelId.equals(labelId),
      );
      query.orderBy([
        OrderingTerm.desc(_db.notes.isPinned),
        OrderingTerm.desc(_db.notes.updatedAt),
      ]);
      return query.watch().map(
        (rows) => rows.map((row) => row.readTable(_db.notes)).toList(),
      );
    }

    return (_db.select(_db.notes)
          ..where(
            (_) => _noteFilterExpr(
              spaceId: spaceId,
              collectionId: collectionId,
              topicId: topicId,
              inboxOnly: inboxOnly,
            ),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPinned),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  Expression<bool> _noteFilterExpr({
    String? spaceId,
    String? collectionId,
    String? topicId,
    bool inboxOnly = false,
  }) {
    Expression<bool> expr = _db.notes.deletedAt.isNull();
    if (spaceId != null) {
      expr = expr & _db.notes.spaceId.equals(spaceId);
    }
    if (inboxOnly) {
      expr = expr & _db.notes.collectionId.isNull();
    } else if (collectionId != null) {
      expr = expr & _db.notes.collectionId.equals(collectionId);
    }
    if (topicId != null) {
      expr = expr & _db.notes.topicId.equals(topicId);
    }
    return expr;
  }

  /// Updates note metadata such as title, space/collection/topic assignment,
  /// pin status, or active flow, and refreshes the search index.
  Future<void> updateNoteMetadata({
    required String noteId,
    String? title,
    String? collectionId,
    bool clearCollection = false,
    String? topicId,
    bool clearTopic = false,
    bool? isPinned,
    String? flowId,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await (_db.update(_db.notes)..where((t) => t.id.equals(noteId))).write(
        NotesCompanion(
          title: title != null ? Value(title.trim()) : const Value.absent(),
          collectionId: clearCollection
              ? const Value(null)
              : (collectionId != null
                    ? Value(collectionId)
                    : const Value.absent()),
          topicId: clearTopic
              ? const Value(null)
              : (topicId != null ? Value(topicId) : const Value.absent()),
          isPinned: isPinned != null ? Value(isPinned) : const Value.absent(),
          flowId: flowId != null ? Value(flowId) : const Value.absent(),
          updatedAt: Value(now),
        ),
      );
      await _syncSearchIndexForNote(noteId);
    });
  }

  /// Atomically replaces and reorders all blocks for [noteId] and refreshes
  /// `notes.updatedAt` and `notes_fts`.
  Future<void> replaceNoteBlocks({
    required String noteId,
    required List<NoteBlockInput> blocks,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await (_db.delete(
        _db.noteBlocks,
      )..where((t) => t.noteId.equals(noteId))).go();

      if (blocks.isNotEmpty) {
        await _insertBlocks(noteId: noteId, blocks: blocks, now: now);
      }

      await (_db.update(_db.notes)..where((t) => t.id.equals(noteId))).write(
        NotesCompanion(updatedAt: Value(now)),
      );

      await _syncSearchIndexForNote(noteId);
    });
  }

  Future<void> _insertBlocks({
    required String noteId,
    required List<NoteBlockInput> blocks,
    required DateTime now,
  }) async {
    await _db.batch((batch) {
      batch.insertAll(_db.noteBlocks, [
        for (var i = 0; i < blocks.length; i++)
          NoteBlocksCompanion.insert(
            id: blocks[i].id ?? _uuid.v4(),
            noteId: noteId,
            type: Value(blocks[i].type.storageKey),
            position: i,
            contentJson: Value(blocks[i].encodeContentJson()),
            updatedAt: now,
          ),
      ]);
    });
  }

  /// Replaces the set of labels attached to [noteId] and updates `notes_fts`.
  Future<void> setNoteLabels({
    required String noteId,
    required List<String> labelIds,
  }) async {
    final now = DateTime.now().toUtc();
    final uniqueIds = labelIds.toSet().toList();
    await _db.transaction(() async {
      await (_db.delete(
        _db.noteLabels,
      )..where((t) => t.noteId.equals(noteId))).go();

      if (uniqueIds.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.noteLabels,
            uniqueIds
                .map(
                  (labelId) => NoteLabelsCompanion.insert(
                    noteId: noteId,
                    labelId: labelId,
                  ),
                )
                .toList(),
          );
        });
      }

      await (_db.update(_db.notes)..where((t) => t.id.equals(noteId))).write(
        NotesCompanion(updatedAt: Value(now)),
      );

      await _syncSearchIndexForNote(noteId);
    });
  }

  /// Fetches all active labels attached to [noteId].
  Future<List<Label>> getLabelsForNote(String noteId) async {
    final query = _db.select(_db.labels).join([
      innerJoin(
        _db.noteLabels,
        _db.noteLabels.labelId.equalsExp(_db.labels.id),
      ),
    ]);
    query.where(
      _db.noteLabels.noteId.equals(noteId) & _db.labels.deletedAt.isNull(),
    );
    query.orderBy([OrderingTerm.asc(_db.labels.name)]);
    final rows = await query.get();
    return rows.map((row) => row.readTable(_db.labels)).toList();
  }

  /// Replaces outgoing internal note links from [sourceNoteId].
  Future<void> setOutgoingLinks({
    required String sourceNoteId,
    required List<String> targetNoteIds,
  }) async {
    final uniqueTargets = targetNoteIds
        .where((id) => id != sourceNoteId)
        .toSet()
        .toList();
    await _db.transaction(() async {
      await (_db.delete(
        _db.noteLinks,
      )..where((t) => t.sourceNoteId.equals(sourceNoteId))).go();

      if (uniqueTargets.isNotEmpty) {
        await _db.batch((batch) {
          batch.insertAll(
            _db.noteLinks,
            uniqueTargets
                .map(
                  (targetId) => NoteLinksCompanion.insert(
                    sourceNoteId: sourceNoteId,
                    targetNoteId: targetId,
                  ),
                )
                .toList(),
          );
        });
      }
    });
  }

  /// Returns active notes that contain an internal link pointing to
  /// [targetNoteId].
  Future<List<Note>> getBacklinks(String targetNoteId) async {
    final query = _db.select(_db.notes).join([
      innerJoin(
        _db.noteLinks,
        _db.noteLinks.sourceNoteId.equalsExp(_db.notes.id),
      ),
    ]);
    query.where(
      _db.noteLinks.targetNoteId.equals(targetNoteId) &
          _db.notes.deletedAt.isNull(),
    );
    query.orderBy([OrderingTerm.desc(_db.notes.updatedAt)]);
    final rows = await query.get();
    return rows.map((row) => row.readTable(_db.notes)).toList();
  }

  /// Soft-deletes a note and removes it from the FTS5 search index.
  Future<void> softDeleteNote(String noteId) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await (_db.update(_db.notes)..where((t) => t.id.equals(noteId))).write(
        NotesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      await _db.removeNoteSearchIndex(noteId);
    });
  }

  /// Searches notes using FTS5 full-text search combined with optional
  /// organizational filters, preserving BM25 relevance ranking.
  Future<List<Note>> searchNotes(
    String query, {
    String? spaceId,
    String? collectionId,
    String? topicId,
    String? labelId,
  }) async {
    final rankedIds = await _db.searchNoteIds(query);
    if (rankedIds.isEmpty) {
      return const [];
    }

    final List<Note> matching;
    if (labelId != null) {
      final joinQuery = _db.select(_db.notes).join([
        innerJoin(
          _db.noteLabels,
          _db.noteLabels.noteId.equalsExp(_db.notes.id),
        ),
      ]);
      joinQuery.where(
        _noteFilterExpr(
              spaceId: spaceId,
              collectionId: collectionId,
              topicId: topicId,
            ) &
            _db.notes.id.isIn(rankedIds) &
            _db.noteLabels.labelId.equals(labelId),
      );
      final rows = await joinQuery.get();
      matching = rows.map((row) => row.readTable(_db.notes)).toList();
    } else {
      matching =
          await (_db.select(_db.notes)..where(
                (t) =>
                    _noteFilterExpr(
                      spaceId: spaceId,
                      collectionId: collectionId,
                      topicId: topicId,
                    ) &
                    t.id.isIn(rankedIds),
              ))
              .get();
    }

    final byId = {for (final note in matching) note.id: note};
    return [
      for (final id in rankedIds)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }

  Future<void> _syncSearchIndexForNote(String noteId) async {
    final note = await getNoteById(noteId);
    if (note == null) {
      await _db.removeNoteSearchIndex(noteId);
      return;
    }

    final persistedBlocks = await getNoteBlocks(noteId);
    final blockInputs = persistedBlocks
        .map(
          (b) => NoteBlockInput.fromPersisted(
            id: b.id,
            typeKey: b.type,
            contentJson: b.contentJson,
          ),
        )
        .toList();
    final labels = await getLabelsForNote(noteId);

    await _db.upsertNoteSearchIndex(
      noteId: noteId,
      title: note.title,
      bodyText: extractPlainTextFromBlocks(blockInputs),
      labelsText: labels.map((l) => l.name).join(' '),
    );
  }
}

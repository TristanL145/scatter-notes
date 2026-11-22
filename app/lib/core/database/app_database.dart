import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// Local-first Drift SQLite database powering Scatter Notes, including FTS5
/// full-text search across note titles, block content, and labels.
@DriftDatabase(
  tables: [
    Spaces,
    Collections,
    Topics,
    Labels,
    Notes,
    NoteBlocks,
    NoteLabels,
    NoteLinks,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the default persistent local database for the application.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Opens the database with an explicit [QueryExecutor] (used by unit/widget
  /// tests with an in-memory SQLite instance).
  AppDatabase.forTesting(super.e);

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'scatter_notes');
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onCreate: (m) async {
      await m.createAll();
      await customStatement(
        'CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5('
        'note_id UNINDEXED, '
        'title, '
        'body_text, '
        'labels_text'
        ')',
      );
    },
  );

  /// Inserts or replaces the FTS5 search index entry for [noteId].
  Future<void> upsertNoteSearchIndex({
    required String noteId,
    required String title,
    required String bodyText,
    required String labelsText,
  }) async {
    await transaction(() async {
      await customStatement('DELETE FROM notes_fts WHERE note_id = ?', [
        noteId,
      ]);
      await customStatement(
        'INSERT INTO notes_fts (note_id, title, body_text, labels_text) '
        'VALUES (?, ?, ?, ?)',
        [noteId, title, bodyText, labelsText],
      );
    });
  }

  /// Removes [noteId] from the FTS5 search index (e.g., on soft-delete).
  Future<void> removeNoteSearchIndex(String noteId) async {
    await customStatement('DELETE FROM notes_fts WHERE note_id = ?', [noteId]);
  }

  /// Searches `notes_fts` safely and returns matching `note_id`s ordered by
  /// BM25 relevance.
  Future<List<String>> searchNoteIds(String rawQuery) async {
    final ftsQuery = buildSafeFtsQuery(rawQuery);
    if (ftsQuery.isEmpty) {
      return const [];
    }

    final rows = await customSelect(
      'SELECT note_id FROM notes_fts '
      'WHERE notes_fts MATCH ? '
      'ORDER BY bm25(notes_fts)',
      variables: [Variable.withString(ftsQuery)],
    ).get();

    return rows.map((row) => row.read<String>('note_id')).toList();
  }

  /// Escapes user search terms into safe FTS5 prefix queries so punctuation
  /// such as `C++` or `foo:bar` never triggers FTS5 syntax errors.
  static String buildSafeFtsQuery(String rawQuery) {
    final hasWordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);
    final tokens = rawQuery
        .trim()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty && hasWordChar.hasMatch(token))
        .map((token) => '"${token.replaceAll('"', '""')}"*')
        .toList();

    return tokens.join(' ');
  }
}

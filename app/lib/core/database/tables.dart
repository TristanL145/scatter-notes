import 'package:drift/drift.dart';

/// Top-level organizational spaces (e.g., School, Personal Projects).
class Spaces extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('folder'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Classes (in School) or Projects (in Personal Projects) inside a [Spaces] row.
class Collections extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId =>
      text().references(Spaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get kind => text().withDefault(const Constant('class'))();
  TextColumn get colorHex => text().withDefault(const Constant('#4F46E5'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Structured topics inside a [Collections] row.
class Topics extends Table {
  TextColumn get id => text()();
  TextColumn get collectionId =>
      text().references(Collections, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Cross-cutting labels/tags applicable to any note across spaces.
class Labels extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().unique()();
  TextColumn get colorHex => text().withDefault(const Constant('#0D9488'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Notes belonging to a space and optionally filed under a collection and topic.
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId =>
      text().references(Spaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get collectionId => text().nullable().references(
    Collections,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get topicId =>
      text().nullable().references(Topics, #id, onDelete: KeyAction.setNull)();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get flowId => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Ordered structured content blocks within a note.
class NoteBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get noteId =>
      text().references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text().withDefault(const Constant('paragraph'))();
  IntColumn get position => integer()();
  TextColumn get contentJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Many-to-many join table associating notes and labels.
class NoteLabels extends Table {
  TextColumn get noteId =>
      text().references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get labelId =>
      text().references(Labels, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {noteId, labelId};
}

/// Directed internal wiki-style links between notes for backlinks navigation.
class NoteLinks extends Table {
  @ReferenceName('outgoingLinks')
  TextColumn get sourceNoteId =>
      text().references(Notes, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('incomingLinks')
  TextColumn get targetNoteId =>
      text().references(Notes, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {sourceNoteId, targetNoteId};
}

import 'package:flutter_test/flutter_test.dart';
import 'package:scatter_notes/core/database/app_database.dart';
import 'package:scatter_notes/features/editor/domain/note_block_content.dart';
import 'package:scatter_notes/features/notes/data/notes_repository.dart';
import 'package:scatter_notes/features/organization/data/organization_repository.dart';

import 'helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late OrganizationRepository orgRepo;
  late NotesRepository notesRepo;

  setUp(() async {
    db = createTestDatabase();
    orgRepo = OrganizationRepository(db);
    notesRepo = NotesRepository(db);
    await orgRepo.ensureDefaultSpaces();
  });

  tearDown(() async {
    await db.close();
  });

  test('supports Inbox vs Class/Topic filtering and pinned ordering', () async {
    final spaces = await orgRepo.watchSpaces().first;
    final school = spaces.firstWhere((s) => s.name == 'School');
    final cs301 = await orgRepo.createCollection(
      spaceId: school.id,
      name: 'CS 301',
    );
    final topic = await orgRepo.createTopic(
      collectionId: cs301.id,
      name: 'Indexing',
    );

    final inboxNote = await notesRepo.createNote(
      spaceId: school.id,
      title: 'Quick Thought in Inbox',
    );
    final classNote = await notesRepo.createNote(
      spaceId: school.id,
      collectionId: cs301.id,
      topicId: topic.id,
      title: 'B-Tree Lecture',
    );
    final pinnedNote = await notesRepo.createNote(
      spaceId: school.id,
      collectionId: cs301.id,
      title: 'Course Syllabus',
      isPinned: true,
    );

    final inboxNotes = await notesRepo
        .watchNotes(spaceId: school.id, inboxOnly: true)
        .first;
    expect(inboxNotes.map((n) => n.id), [inboxNote.id]);

    final cs301Notes = await notesRepo
        .watchNotes(spaceId: school.id, collectionId: cs301.id)
        .first;
    expect(cs301Notes.first.id, pinnedNote.id);
    expect(
      cs301Notes.map((n) => n.id),
      containsAll([pinnedNote.id, classNote.id]),
    );

    final topicNotes = await notesRepo.watchNotes(topicId: topic.id).first;
    expect(topicNotes.map((n) => n.id), [classNote.id]);
  });

  test('persists and reorders structured blocks across block types', () async {
    final spaces = await orgRepo.watchSpaces().first;
    final projects = spaces.firstWhere((s) => s.name == 'Personal Projects');

    final note = await notesRepo.createNote(
      spaceId: projects.id,
      title: 'Architecture Notes',
      blocks: const [
        NoteBlockInput(
          type: BlockType.heading,
          content: {'level': 1, 'text': 'Goals'},
        ),
        NoteBlockInput(
          type: BlockType.paragraph,
          content: {'text': 'Keep storage fast and offline-first.'},
        ),
      ],
    );

    final initialBlocks = await notesRepo.getNoteBlocks(note.id);
    expect(initialBlocks.length, 2);
    expect(initialBlocks[0].type, 'heading');
    expect(initialBlocks[0].position, 0);
    expect(initialBlocks[1].position, 1);

    await notesRepo.replaceNoteBlocks(
      noteId: note.id,
      blocks: const [
        NoteBlockInput(
          type: BlockType.callout,
          content: {'variant': 'key_takeaway', 'text': 'SQLite FTS5 rocks'},
        ),
        NoteBlockInput(
          type: BlockType.checklist,
          content: {'text': 'Write repository tests', 'checked': true},
        ),
        NoteBlockInput(
          type: BlockType.code,
          content: {'language': 'dart', 'code': 'print("hello");'},
        ),
      ],
    );

    final updatedBlocks = await notesRepo.getNoteBlocks(note.id);
    expect(updatedBlocks.map((b) => b.type), ['callout', 'checklist', 'code']);
    expect(updatedBlocks.map((b) => b.position), [0, 1, 2]);
  });

  test(
    'supports label filtering and backlinks excluding soft-deleted notes',
    () async {
      final spaces = await orgRepo.watchSpaces().first;
      final school = spaces.first;
      final examLabel = await orgRepo.createLabel(name: 'exam-prep');

      final targetNote = await notesRepo.createNote(
        spaceId: school.id,
        title: 'ACID Properties',
      );
      final linkingNote = await notesRepo.createNote(
        spaceId: school.id,
        title: 'Transactions Summary',
        labelIds: [examLabel.id],
      );
      final deletedLinkingNote = await notesRepo.createNote(
        spaceId: school.id,
        title: 'Scratch Link',
      );

      await notesRepo.setOutgoingLinks(
        sourceNoteId: linkingNote.id,
        targetNoteIds: [targetNote.id],
      );
      await notesRepo.setOutgoingLinks(
        sourceNoteId: deletedLinkingNote.id,
        targetNoteIds: [targetNote.id],
      );
      await notesRepo.softDeleteNote(deletedLinkingNote.id);

      final labeled = await notesRepo.watchNotes(labelId: examLabel.id).first;
      expect(labeled.map((n) => n.id), [linkingNote.id]);

      final backlinks = await notesRepo.getBacklinks(targetNote.id);
      expect(backlinks.map((n) => n.id), [linkingNote.id]);
    },
  );

  test(
    'FTS5 searches title, blocks, labels, special chars, and removes on delete',
    () async {
      final spaces = await orgRepo.watchSpaces().first;
      final school = spaces.firstWhere((s) => s.name == 'School');
      final projects = spaces.firstWhere((s) => s.name == 'Personal Projects');

      final systemsLabel = await orgRepo.createLabel(name: 'systems-review');

      final cppNote = await notesRepo.createNote(
        spaceId: school.id,
        title: 'Pointers in C++',
        blocks: const [
          NoteBlockInput(
            type: BlockType.code,
            content: {'language': 'cpp', 'code': 'int* ptr = nullptr;'},
          ),
          NoteBlockInput(
            type: BlockType.paragraph,
            content: {'text': 'Remember smart pointers and RAII.'},
          ),
        ],
        labelIds: [systemsLabel.id],
      );

      final projectNote = await notesRepo.createNote(
        spaceId: projects.id,
        title: 'Scatter Notes Roadmap',
        blocks: const [
          NoteBlockInput(
            type: BlockType.paragraph,
            content: {'text': 'Implement logical flows and RAII-free Dart UI.'},
          ),
        ],
      );

      // Search by title / special characters like C++ without crashing FTS5.
      final cppResults = await notesRepo.searchNotes('C++');
      expect(cppResults.map((n) => n.id), [cppNote.id]);

      // Punctuation-only queries safely return empty rather than throwing.
      expect(await notesRepo.searchNotes('+++ ::: ""'), isEmpty);

      // Search by label text indexed into FTS5.
      final labelSearch = await notesRepo.searchNotes('systems-review');
      expect(labelSearch.map((n) => n.id), [cppNote.id]);

      // Search by block body text combined with space filter.
      final allRaii = await notesRepo.searchNotes('RAII');
      expect(
        allRaii.map((n) => n.id),
        containsAll([cppNote.id, projectNote.id]),
      );

      final projectOnlyRaii = await notesRepo.searchNotes(
        'RAII',
        spaceId: projects.id,
      );
      expect(projectOnlyRaii.map((n) => n.id), [projectNote.id]);

      // Combined label filter on search.
      final labeledRaii = await notesRepo.searchNotes(
        'RAII',
        labelId: systemsLabel.id,
      );
      expect(labeledRaii.map((n) => n.id), [cppNote.id]);

      // Soft delete removes note from FTS5 index.
      await notesRepo.softDeleteNote(cppNote.id);
      expect(await notesRepo.searchNotes('nullptr'), isEmpty);
    },
  );
}

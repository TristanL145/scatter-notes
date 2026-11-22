import 'package:flutter_test/flutter_test.dart';
import 'package:scatter_notes/core/database/app_database.dart';
import 'package:scatter_notes/features/organization/data/organization_repository.dart';

import 'helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late OrganizationRepository repo;

  setUp(() {
    db = createTestDatabase();
    repo = OrganizationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'ensureDefaultSpaces creates School and Personal Projects idempotently',
    () async {
      await repo.ensureDefaultSpaces();
      await repo.ensureDefaultSpaces();

      final spaces = await repo.watchSpaces().first;
      expect(spaces.map((s) => s.name), ['School', 'Personal Projects']);
    },
  );

  test('collections, topics, archiving, labels, and soft deletes', () async {
    await repo.ensureDefaultSpaces();
    final spaces = await repo.watchSpaces().first;
    final school = spaces.firstWhere((s) => s.name == 'School');

    final cs301 = await repo.createCollection(
      spaceId: school.id,
      name: 'CS 301 - Databases',
      kind: 'class',
    );
    final math210 = await repo.createCollection(
      spaceId: school.id,
      name: 'MATH 210',
      kind: 'class',
    );

    final bTrees = await repo.createTopic(
      collectionId: cs301.id,
      name: 'Week 3: B-Trees',
    );
    await repo.createTopic(
      collectionId: cs301.id,
      name: 'Midterm Prep',
      sortOrder: 1,
    );

    final collections = await repo.watchCollections(school.id).first;
    expect(collections.map((c) => c.name), ['CS 301 - Databases', 'MATH 210']);

    final topics = await repo.watchTopics(cs301.id).first;
    expect(topics.map((t) => t.name), ['Week 3: B-Trees', 'Midterm Prep']);

    // Archiving excludes collection unless includeArchived is true.
    await repo.setCollectionArchived(math210.id, archived: true);
    final activeOnly = await repo.watchCollections(school.id).first;
    expect(activeOnly.map((c) => c.id), [cs301.id]);

    final withArchived = await repo
        .watchCollections(school.id, includeArchived: true)
        .first;
    expect(withArchived.length, 2);

    // Labels CRUD + soft delete.
    final examLabel = await repo.createLabel(name: 'exam-prep');
    final todoLabel = await repo.createLabel(name: 'todo');
    expect((await repo.watchLabels().first).map((l) => l.name), [
      'exam-prep',
      'todo',
    ]);

    await repo.softDeleteTopic(bTrees.id);
    expect((await repo.watchTopics(cs301.id).first).map((t) => t.name), [
      'Midterm Prep',
    ]);

    await repo.softDeleteLabel(todoLabel.id);
    expect((await repo.watchLabels().first).map((l) => l.name), ['exam-prep']);

    await repo.softDeleteCollection(cs301.id);
    expect(
      await repo.watchCollections(school.id, includeArchived: true).first,
      [math210.copyWith(archived: true)],
    );

    expect(examLabel.name, 'exam-prep');
  });
}

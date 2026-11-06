import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/data/companion_memory_repository.dart';
import 'package:trackia/domain/companion_memory.dart';

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late Database db;
  late CompanionMemoryRepository repo;
  final t0 = DateTime.utc(2026, 1, 1);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('trackia-memory-repo-');
    db = await databaseFactoryFfi.openDatabase('${dir.path}/memory.sqlite');
    // Test-owned schema: does not depend on or alter the application's migration.
    await db.execute('''CREATE TABLE trackia_companion_memories (
      id TEXT PRIMARY KEY, profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
      content TEXT NOT NULL, source TEXT NOT NULL,
      source_message_id TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
      revision INTEGER NOT NULL, status TEXT NOT NULL)''');
    repo = CompanionMemoryRepository(db, profileId: 'profile-a');
  });

  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test(
    'scopes reads, revisions edits as user-authored, confirms, and soft deletes',
    () async {
      final created = await repo.create(
        companionId: 'companion-a',
        content: 'Prefiere correr',
        source: MemorySource.inferred,
        status: MemoryStatus.pendingConfirmation,
        sourceMessageId: 'message-a',
        at: t0,
        id: 'memory-a',
      );
      expect(created.revision, 1);
      expect((await repo.get('memory-a', companionId: 'other')), isNull);
      final edited = await repo.revise(
        'memory-a',
        companionId: 'companion-a',
        at: t0.add(const Duration(minutes: 1)),
        content: 'Prefiere caminar',
      );
      expect(edited!.content, 'Prefiere caminar');
      expect(edited.source, MemorySource.userEdited);
      expect(edited.revision, 2);
      final confirmed = await repo.confirm(
        'memory-a',
        companionId: 'companion-a',
        at: t0.add(const Duration(minutes: 2)),
      );
      expect(confirmed!.status, MemoryStatus.active);
      expect(confirmed.revision, 3);
      final deleted = await repo.delete(
        'memory-a',
        companionId: 'companion-a',
        at: t0.add(const Duration(minutes: 3)),
      );
      expect(deleted!.status, MemoryStatus.deleted);
      expect(await repo.list(companionId: 'companion-a'), isEmpty);
      expect(
        (await repo.list(
          companionId: 'companion-a',
          includeDeleted: true,
        )).single.id,
        'memory-a',
      );
      expect(
        await CompanionMemoryRepository(
          db,
          profileId: 'profile-b',
        ).list(companionId: 'companion-a'),
        isEmpty,
      );
    },
  );

  test(
    'selection is active-only, bounded, relevant and ambiguity-safe',
    () async {
      await repo.create(
        companionId: 'companion-a',
        content: 'Le gusta el yoga',
        source: MemorySource.explicit,
        at: t0,
        id: 'a',
      );
      await repo.create(
        companionId: 'companion-a',
        content: 'Otra nota',
        source: MemorySource.explicit,
        status: MemoryStatus.pendingConfirmation,
        at: t0,
        id: 'b',
      );
      final selected = await repo.select(
        companionId: 'companion-a',
        relevantMemoryIds: ['a'],
      );
      expect(selected.memories.map((m) => m.id), ['a']);
      expect(selected.contextText, '- Le gusta el yoga');
      final ambiguous = await repo.select(
        companionId: 'companion-a',
        referenceCandidateIds: ['a', 'b'],
      );
      expect(ambiguous.needsClarification, isTrue);
      expect(ambiguous.memories, isEmpty);
    },
  );
}

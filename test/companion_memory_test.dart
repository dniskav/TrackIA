import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trackia/application/companion_memory_service.dart';
import 'package:trackia/data/companion_memory_repository.dart';
import 'package:trackia/domain/companion_memory.dart';

void main() {
  final baseTime = DateTime.utc(2026, 11, 5);
  sqfliteFfiInit();

  CompanionMemory memory({
    String id = 'memory-1',
    String profileId = 'profile-a',
    String companionId = 'companion-a',
    String content = 'Prefiere respuestas breves.',
    MemorySource source = MemorySource.explicit,
    String? sourceMessageId = 'message-fixture-1',
    int revision = 1,
    MemoryStatus status = MemoryStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CompanionMemory(
    id: id,
    profileId: profileId,
    companionId: companionId,
    content: content,
    source: source,
    sourceMessageId: sourceMessageId,
    createdAt: createdAt ?? baseTime,
    updatedAt: updatedAt ?? baseTime,
    revision: revision,
    status: status,
  );

  test('memory validates required text and the 2000 character boundary', () {
    final boundary = memory(content: 'x' * 2000);
    expect(boundary.content, hasLength(2000));
    expect(
      () => memory(content: 'x' * 2001),
      throwsArgumentError,
    );
    expect(() => memory(content: '  '), throwsArgumentError);
    expect(() => memory(profileId: ' '), throwsArgumentError);
  });

  test('explicit source and source message are represented without chat scope', () {
    final explicit = memory();
    expect(explicit.source, MemorySource.explicit);
    expect(explicit.sourceMessageId, 'message-fixture-1');
    expect(explicit.profileId, 'profile-a');
    expect(explicit.companionId, 'companion-a');
    expect(explicit.toString(), isNot(contains('chatId')));
  });

  test('pending and inferred memories keep distinct origin and state', () {
    final inferred = memory(
      source: MemorySource.inferred,
      status: MemoryStatus.pendingConfirmation,
    );
    expect(inferred.source, MemorySource.inferred);
    expect(inferred.status, MemoryStatus.pendingConfirmation);
  });

  test('revision and edit preserve identity and original value; edits are user authored', () {
    final original = memory();
    final edited = original.revise(
      at: baseTime.add(const Duration(minutes: 1)),
      content: 'Prefiere instrucciones breves.',
    );

    expect(original.content, 'Prefiere respuestas breves.');
    expect(original.revision, 1);
    expect(edited.id, original.id);
    expect(edited.profileId, original.profileId);
    expect(edited.companionId, original.companionId);
    expect(edited.revision, 2);
    expect(edited.source, MemorySource.userEdited);
    expect(edited.sourceMessageId, original.sourceMessageId);
    expect(edited.updatedAt, baseTime.add(const Duration(minutes: 1)));
  });

  test('deletion is a new revision and deleted memories are not selected', () {
    final deleted = memory().revise(
      at: baseTime.add(const Duration(minutes: 2)),
      status: MemoryStatus.deleted,
    );
    expect(deleted.status, MemoryStatus.deleted);
    expect(deleted.revision, 2);
    final selection = MemoryContextSelection.select(
      candidates: [deleted],
      profileId: 'profile-a',
      companionId: 'companion-a',
    );
    expect(selection.memories, isEmpty);
    expect(selection.contextText, isEmpty);
  });

  test('archiving a source chat does not make its memory depend on chat storage', () {
    final storedMemory = memory();
    // The memory retains only an optional provenance ID; selection after the
    // source chat has been archived receives the memory independently.
    final afterArchive = MemoryContextSelection.select(
      candidates: [storedMemory],
      profileId: 'profile-a',
      companionId: 'companion-a',
    );
    expect(afterArchive.memories.single.id, storedMemory.id);
    expect(afterArchive.contextText, contains(storedMemory.content));
  });

  test('selection excludes other profile/companion scopes and pending states', () {
    final current = memory();
    final foreignProfile = memory(id: 'm2', profileId: 'profile-b');
    final foreignCompanion = memory(id: 'm3', companionId: 'companion-b');
    final awaitingApproval = memory(
      id: 'm4',
      status: MemoryStatus.pendingConfirmation,
    );
    final result = MemoryContextSelection.select(
      candidates: [current, foreignProfile, foreignCompanion, awaitingApproval],
      profileId: 'profile-a',
      companionId: 'companion-a',
    );
    expect(result.memories.map((item) => item.id), ['memory-1']);
    expect(result.needsClarification, isFalse);
  });

  test('context is bounded to 20 records and 12000 rendered characters', () {
    final many = List.generate(
      30,
      (index) => memory(
        id: 'memory-$index',
        content: 'x' * 2000,
        createdAt: baseTime,
        updatedAt: baseTime.add(Duration(seconds: index)),
      ),
    );
    final result = MemoryContextSelection.select(
      candidates: many,
      profileId: 'profile-a',
      companionId: 'companion-a',
    );
    expect(result.memories.length, lessThanOrEqualTo(20));
    expect(result.contextText.length, lessThanOrEqualTo(12000));
    expect(result.omittedCount, greaterThan(0));
    expect(result.memories.first.id, 'memory-29');
  });

  test('ambiguous reference requests clarification and returns no memory context', () {
    final result = MemoryContextSelection.select(
      candidates: [memory()],
      profileId: 'profile-a',
      companionId: 'companion-a',
      referenceCandidateIds: const ['memory-1', 'memory-2'],
    );
    expect(result.needsClarification, isTrue);
    expect(result.memories, isEmpty);
    expect(result.contextText, isEmpty);
  });

  group('persistence and selection against the real v7 table (SQLite FFI)', () {
    late Directory dir;
    late Database db;
    late CompanionMemoryRepository repo;
    const service = CompanionMemoryService();

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('trackia-memory-context-');
      db = await databaseFactoryFfi.openDatabase('${dir.path}/memory.sqlite');
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

    test('an accepted save proposal persists with scope, bounds and provenance',
        () async {
      final proposal = service.parseProposal(
        {'action': 'save', 'content': 'Entrena por la mañana.'},
        profileId: 'profile-a',
        companionId: 'companion-a',
        sourceMessageId: 'message-1',
        userExplicitlyRequestedSave: true,
      )!;
      final accepted = await service.acceptPersisted(
        proposal,
        repository: repo,
        at: baseTime,
        id: 'memory-1',
      );
      expect(accepted!.profileId, 'profile-a');
      expect(accepted.companionId, 'companion-a');
      expect(accepted.source, MemorySource.explicit);
      expect(accepted.sourceMessageId, 'message-1');
      expect(accepted.status, MemoryStatus.active);
      // Persisted rows survive closing and re-opening the same database file,
      // and stay isolated per profile and companion.
      await db.close();
      final reopened =
          await databaseFactoryFfi.openDatabase('${dir.path}/memory.sqlite');
      final fresh = CompanionMemoryRepository(reopened, profileId: 'profile-a');
      final loaded = await fresh.get('memory-1', companionId: 'companion-a');
      expect(loaded, isNotNull);
      expect(loaded!.content, 'Entrena por la mañana.');
      expect(loaded.source, MemorySource.explicit);
      expect(loaded.revision, 1);
      expect(
        await CompanionMemoryRepository(
          reopened,
          profileId: 'profile-b',
        ).list(companionId: 'companion-a'),
        isEmpty,
      );
      expect(await fresh.list(companionId: 'companion-b'), isEmpty);
      await reopened.close();
    });

    test('an inferred save keeps its provenance and the 2000-character bound',
        () async {
      final inferred = service.parseProposal(
        {'action': 'save', 'content': 'Prefiere series de 8 repeticiones.'},
        profileId: 'profile-a',
        companionId: 'companion-a',
        sourceMessageId: 'message-2',
        userExplicitlyRequestedSave: false,
      )!;
      final accepted = await service.acceptPersisted(
        inferred,
        repository: repo,
        at: baseTime,
        id: 'memory-inferred',
      );
      expect(accepted!.source, MemorySource.inferred);
      // The repository/domain layer is the last guard: even if a caller skips
      // parseProposal, more than 2000 characters can never persist.
      await expectLater(
        repo.create(
          companionId: 'companion-a',
          content: 'x' * 2001,
          source: MemorySource.explicit,
          at: baseTime,
        ),
        throwsArgumentError,
      );
    });

    test('ask persists on acceptance; ignore writes nothing', () async {
      final ask = service.parseProposal(
        {'action': 'ask', 'content': '¿Guardar que acabas de empezar yoga?'},
        profileId: 'profile-a',
        companionId: 'companion-a',
        sourceMessageId: 'message-4',
        userExplicitlyRequestedSave: false,
      )!;
      // Without user acceptance nothing is stored: the pure accept stays null.
      expect(
        service.accept(ask, id: 'memory-ask', at: baseTime),
        isNull,
      );
      expect(await repo.list(companionId: 'companion-a'), isEmpty);
      // The persisted route stores it only when it is called as the user's
      // acceptance.
      await service.acceptPersisted(
        ask,
        repository: repo,
        at: baseTime,
        id: 'memory-ask',
      );
      expect((await repo.list(companionId: 'companion-a')).length, 1);

      final ignore = service.parseProposal(
        {'action': 'ignore'},
        profileId: 'profile-a',
        companionId: 'companion-a',
        sourceMessageId: 'message-5',
        userExplicitlyRequestedSave: false,
      )!;
      expect(
        await service.acceptPersisted(
          ignore,
          repository: repo,
          at: baseTime,
          id: 'memory-ignored',
        ),
        isNull,
      );
      expect(
        await repo.get('memory-ignored', companionId: 'companion-a'),
        isNull,
      );
    });

    test('a scope mismatch is rejected instead of leaking across profiles',
        () => expectLater(
          service.acceptPersisted(
            service.parseProposal(
              {'action': 'save', 'content': 'Dato de otro perfil.'},
              profileId: 'profile-b',
              companionId: 'companion-a',
              sourceMessageId: 'message-6',
              userExplicitlyRequestedSave: true,
            )!,
            repository: repo,
            at: baseTime,
          ),
          throwsArgumentError,
        ));

    test('deleted memories stay excluded from the selection after reopening',
        () async {
      await repo.create(
        companionId: 'companion-a',
        content: 'Recuerdo vivo',
        source: MemorySource.explicit,
        at: baseTime,
        id: 'keep',
      );
      await repo.create(
        companionId: 'companion-a',
        content: 'Recuerdo a borrar',
        source: MemorySource.explicit,
        at: baseTime,
        id: 'gone',
      );
      await repo.delete('gone', companionId: 'companion-a', at: baseTime);
      await db.close();
      final reopened =
          await databaseFactoryFfi.openDatabase('${dir.path}/memory.sqlite');
      final fresh = CompanionMemoryRepository(reopened, profileId: 'profile-a');
      final selection = await fresh.select(companionId: 'companion-a');
      expect(selection.memories.map((m) => m.id), ['keep']);
      expect(
        (await fresh.list(
          companionId: 'companion-a',
          includeDeleted: true,
        )).map((m) => m.id),
        containsAll(['keep', 'gone']),
      );
      await reopened.close();
    });

    test('the 20-memory cap and the 12000-character bound apply on load',
        () async {
      for (var i = 0; i < 25; i++) {
        await repo.create(
          companionId: 'companion-a',
          content: 'Recuerdo corto $i',
          source: MemorySource.explicit,
          at: baseTime,
          id: 'bulk-$i',
        );
      }
      final selection = await repo.select(companionId: 'companion-a');
      expect(selection.memories, hasLength(20));
      expect(selection.omittedCount, 5);
      expect(selection.contextText.length, lessThanOrEqualTo(12000));
      expect(selection.needsClarification, isFalse);
      // Ambiguous references still refuse to pick a memory.
      final ambiguous = await repo.select(
        companionId: 'companion-a',
        referenceCandidateIds: ['bulk-0', 'bulk-1'],
      );
      expect(ambiguous.needsClarification, isTrue);
      expect(ambiguous.memories, isEmpty);
    });

    test('the 12000-character bound drops whole oversized memories', () async {
      for (var i = 0; i < 6; i++) {
        await repo.create(
          companionId: 'companion-a',
          content: 'x' * 2000,
          source: MemorySource.explicit,
          at: baseTime,
          id: 'big-$i',
        );
      }
      final selection = await repo.select(companionId: 'companion-a');
      // Same timestamps and equal lengths keep the id tie-break: only the
      // first five fit inside 12000 characters, so big-5 is omitted whole.
      expect(
        selection.memories.map((m) => m.id),
        ['big-0', 'big-1', 'big-2', 'big-3', 'big-4'],
      );
      expect(selection.omittedCount, 1);
      expect(selection.contextText.length, lessThanOrEqualTo(12000));
    });
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/memory_snapshot.dart';
import 'package:trackia/data/memory_google_drive.dart';
import 'package:trackia/domain/companion_memory.dart';

/// Contract coverage that does not need Google, OAuth, a network, or private
/// user data. Cloud-operation cases stay explicitly skipped until T030/T031
/// provide an adapter/operation API that these tests can exercise.
void main() {
  final createdAt = DateTime.utc(2026, 11, 5, 10);

  CompanionMemory fixture({
    String id = 'memory-1',
    String profileId = 'profile-fixture-a',
    String companionId = 'companion-fixture-a',
    String content = 'Prefiere respuestas breves.',
    MemoryStatus status = MemoryStatus.active,
  }) => CompanionMemory(
    id: id,
    profileId: profileId,
    companionId: companionId,
    content: content,
    source: MemorySource.userEdited,
    sourceMessageId: 'message-fixture-1',
    createdAt: createdAt,
    updatedAt: createdAt.add(const Duration(minutes: 1)),
    revision: 2,
    status: status,
  );

  test(
    'v1 snapshot is deterministic and restores the full synthetic record',
    () {
      final first = MemorySnapshot(
        profileId: 'profile-fixture-a',
        companionId: 'companion-fixture-a',
        memories: [fixture(id: 'z-memory'), fixture(id: 'a-memory')],
      );
      final second = MemorySnapshot(
        profileId: 'profile-fixture-a',
        companionId: 'companion-fixture-a',
        memories: [fixture(id: 'a-memory'), fixture(id: 'z-memory')],
      );

      expect(first.toJson(), second.toJson());
      final restored = MemorySnapshot.parse(
        first.toJson(),
        expectedProfileId: 'profile-fixture-a',
        expectedCompanionId: 'companion-fixture-a',
      );
      expect(restored.toMap()['version'], 1);
      expect(restored.memories.map((memory) => memory.id), [
        'a-memory',
        'z-memory',
      ]);
      expect(restored.memories.first.content, 'Prefiere respuestas breves.');
      expect(restored.memories.first.source, MemorySource.userEdited);
      expect(restored.memories.first.revision, 2);
      expect(restored.memories.first.sourceMessageId, 'message-fixture-1');
    },
  );

  test(
    'snapshot is profile and companion scoped, independent of Google account',
    () {
      final snapshot = MemorySnapshot(
        profileId: 'profile-fixture-a',
        companionId: 'companion-fixture-a',
        memories: [fixture()],
      );

      expect(
        () => MemorySnapshot.parse(
          snapshot.toJson(),
          expectedProfileId: 'profile-fixture-b',
          expectedCompanionId: 'companion-fixture-a',
        ),
        throwsFormatException,
      );
      expect(
        () => MemorySnapshot.parse(
          snapshot.toJson(),
          expectedProfileId: 'profile-fixture-a',
          expectedCompanionId: 'companion-fixture-b',
        ),
        throwsFormatException,
      );
      expect(snapshot.toJson(), isNot(contains('googleAccount')));
    },
  );

  test(
    'damaged or credential-bearing snapshot is rejected without partial import',
    () {
      final valid =
          MemorySnapshot(
            profileId: 'profile-fixture-a',
            companionId: 'companion-fixture-a',
            memories: [fixture()],
          ).toMap();
      final memory =
          (valid['memories']! as List).single as Map<String, Object?>;
      final corrupt = <String, Object?>{
        ...valid,
        'memories': [
          {...memory, 'status': 'not-a-status'},
        ],
      };
      final withCredential = <String, Object?>{
        ...valid,
        'accessToken': 'synthetic-token-must-not-be-imported',
      };

      for (final json in [
        '{broken',
        jsonEncode(corrupt),
        jsonEncode(withCredential),
      ]) {
        expect(
          () => MemorySnapshot.parse(
            json,
            expectedProfileId: 'profile-fixture-a',
            expectedCompanionId: 'companion-fixture-a',
          ),
          throwsFormatException,
        );
      }
    },
  );

  group('memory cloud service with synthetic transport', () {
    const account = 'account-a';
    const profile = 'profile-fixture-a';
    const companion = 'companion-fixture-a';
    final snapshot = MemorySnapshot(
      profileId: profile,
      companionId: companion,
      memories: [fixture()],
    );
    late _FakeTransport transport;
    late MemoryGoogleDriveService service;
    setUp(() {
      transport = _FakeTransport();
      service = MemoryGoogleDriveService(transport, clock: () => createdAt);
    });

    test(
      'save/load are scoped to account and IDs with a monotonic revision',
      () async {
        final saved = await service.save(
          accountId: account,
          snapshot: snapshot,
          knownRevision: null,
        );
        expect(saved.status, MemoryCloudStatus.success);
        expect(saved.revision, 1);
        final loaded = await service.load(
          accountId: account,
          profileId: profile,
          companionId: companion,
        );
        expect(loaded.snapshot!.toJson(), snapshot.toJson());
        expect(loaded.updatedAt, createdAt);
        expect(transport.writeExpectedRevision, isNull);
        expect(
          await service.load(
            accountId: 'other-account',
            profileId: profile,
            companionId: companion,
          ),
          isA<MemoryCloudResult>(),
        );
      },
    );

    test(
      'remote revision mismatch conflicts and never writes over newer copy',
      () async {
        await service.save(
          accountId: account,
          snapshot: snapshot,
          knownRevision: null,
        );
        final before = transport.payload;
        final result = await service.save(
          accountId: account,
          snapshot: snapshot,
          knownRevision: null,
        );
        expect(result.status, MemoryCloudStatus.conflict);
        expect(transport.payload, before);
      },
    );

    test(
      'conditional write race and uncertain result are never reported as success',
      () async {
        await service.save(
          accountId: account,
          snapshot: snapshot,
          knownRevision: null,
        );
        transport.nextWrite = MemoryCloudWriteResult.conflict;
        expect(
          (await service.save(
            accountId: account,
            snapshot: snapshot,
            knownRevision: 1,
          )).status,
          MemoryCloudStatus.conflict,
        );
        transport.nextWrite = MemoryCloudWriteResult.uncertain;
        expect(
          (await service.save(
            accountId: account,
            snapshot: snapshot,
            knownRevision: 1,
          )).status,
          MemoryCloudStatus.uncertain,
        );
      },
    );

    test('cancellation and permission denial are surfaced', () async {
      transport.readError = const MemoryCloudException(
        MemoryCloudStatus.cancelled,
      );
      expect(
        (await service.load(
          accountId: account,
          profileId: profile,
          companionId: companion,
        )).status,
        MemoryCloudStatus.cancelled,
      );
      transport.readError = const MemoryCloudException(
        MemoryCloudStatus.permissionDenied,
      );
      expect(
        (await service.load(
          accountId: account,
          profileId: profile,
          companionId: companion,
        )).status,
        MemoryCloudStatus.permissionDenied,
      );
    });

    test(
      'cloud deletion is a separate explicit operation and detects revision conflict',
      () async {
        await service.save(
          accountId: account,
          snapshot: snapshot,
          knownRevision: null,
        );
        expect(
          (await service.delete(
            accountId: account,
            profileId: profile,
            companionId: companion,
            knownRevision: 9,
          )).status,
          MemoryCloudStatus.conflict,
        );
        expect(transport.payload, isNotNull);
        expect(
          (await service.delete(
            accountId: account,
            profileId: profile,
            companionId: companion,
            knownRevision: 1,
          )).status,
          MemoryCloudStatus.success,
        );
        expect(transport.payload, isNull);
      },
    );

    test('damaged or cross-account remote payload is rejected', () async {
      await service.save(
        accountId: account,
        snapshot: snapshot,
        knownRevision: null,
      );
      transport.payload = '{broken';
      expect(
        (await service.load(
          accountId: account,
          profileId: profile,
          companionId: companion,
        )).status,
        MemoryCloudStatus.failed,
      );
    });
  });
}

class _FakeTransport implements MemoryCloudTransport {
  String? payload;
  int? writeExpectedRevision;
  MemoryCloudWriteResult nextWrite = MemoryCloudWriteResult.written;
  MemoryCloudDeleteResult nextDelete = MemoryCloudDeleteResult.deleted;
  MemoryCloudException? readError;
  String? _account;
  String? _key;

  @override
  Future<MemoryCloudDocument?> read({
    required String accountId,
    required String key,
  }) async {
    if (readError case final error?) throw error;
    if (payload == null || accountId != _account || key != _key) return null;
    return MemoryCloudDocument(
      accountId: _account!,
      key: _key!,
      payload: payload!,
    );
  }

  @override
  Future<MemoryCloudWriteResult> write({
    required String accountId,
    required String key,
    required String payload,
    required int? expectedRevision,
  }) async {
    writeExpectedRevision = expectedRevision;
    final result = nextWrite;
    nextWrite = MemoryCloudWriteResult.written;
    if (result == MemoryCloudWriteResult.written) {
      _account = accountId;
      _key = key;
      this.payload = payload;
    }
    return result;
  }

  @override
  Future<MemoryCloudDeleteResult> delete({
    required String accountId,
    required String key,
  }) async {
    final result = nextDelete;
    nextDelete = MemoryCloudDeleteResult.deleted;
    if (result == MemoryCloudDeleteResult.deleted &&
        accountId == _account &&
        key == _key) {
      payload = null;
    }
    return result;
  }
}

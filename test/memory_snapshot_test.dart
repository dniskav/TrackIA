import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/memory_snapshot.dart';
import 'package:trackia/domain/companion_memory.dart';

void main() {
  final date = DateTime.utc(2026, 11, 5, 10);
  CompanionMemory memory({
    String id = 'm1',
    String profile = 'p1',
    String companion = 'c1',
  }) => CompanionMemory(
    id: id,
    profileId: profile,
    companionId: companion,
    content: 'Prefiere respuestas claras.',
    source: MemorySource.userEdited,
    sourceMessageId: 'opaque-message-1',
    createdAt: date,
    updatedAt: date.add(const Duration(minutes: 1)),
    revision: 2,
    status: MemoryStatus.active,
  );

  test(
    'v1 serializa y restaura recuerdos con todos sus atributos de dominio',
    () {
      final snapshot = MemorySnapshot(
        profileId: 'p1',
        companionId: 'c1',
        memories: [memory(id: 'z'), memory(id: 'a')],
      );
      final json = snapshot.toJson();
      final restored = MemorySnapshot.parse(
        json,
        expectedProfileId: 'p1',
        expectedCompanionId: 'c1',
      );

      expect(restored.memories.map((item) => item.id), ['a', 'z']);
      expect(restored.memories.first.source, MemorySource.userEdited);
      expect(restored.memories.first.sourceMessageId, 'opaque-message-1');
      expect(restored.memories.first.revision, 2);
      expect(
        restored.memories.first.updatedAt,
        date.add(const Duration(minutes: 1)),
      );
      expect(json, isNot(contains('token')));
      expect(json, isNot(contains('credential')));
    },
  );

  test(
    'constructor rejects memories from mixed profile or companion scopes',
    () {
      expect(
        () => MemorySnapshot(
          profileId: 'p1',
          companionId: 'c1',
          memories: [memory(profile: 'p2')],
        ),
        throwsFormatException,
      );
      expect(
        () => MemorySnapshot(
          profileId: 'p1',
          companionId: 'c1',
          memories: [memory(companion: 'c2')],
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'parser rejects a different expected scope without returning records',
    () {
      final json =
          MemorySnapshot(
            profileId: 'p1',
            companionId: 'c1',
            memories: [memory()],
          ).toJson();
      expect(
        () => MemorySnapshot.parse(
          json,
          expectedProfileId: 'p2',
          expectedCompanionId: 'c1',
        ),
        throwsFormatException,
      );
      expect(
        () => MemorySnapshot.parse(
          json,
          expectedProfileId: 'p1',
          expectedCompanionId: 'c2',
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'parser rejects unsupported version, unknown keys and malformed JSON',
    () {
      final map =
          MemorySnapshot(
            profileId: 'p1',
            companionId: 'c1',
            memories: [memory()],
          ).toMap();
      final wrongVersion = {...map, 'version': 2};
      final extraKey = {...map, 'accessToken': 'should-not-be-imported'};
      for (final candidate in [wrongVersion, extraKey]) {
        expect(
          () => MemorySnapshot.parse(
            _encode(candidate),
            expectedProfileId: 'p1',
            expectedCompanionId: 'c1',
          ),
          throwsFormatException,
        );
      }
      expect(
        () => MemorySnapshot.parse(
          '{broken',
          expectedProfileId: 'p1',
          expectedCompanionId: 'c1',
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'parser rejects invalid enum values, missing fields and model invariant violations',
    () {
      final map =
          MemorySnapshot(
            profileId: 'p1',
            companionId: 'c1',
            memories: [memory()],
          ).toMap();
      final original =
          (map['memories']! as List).single as Map<String, Object?>;
      final invalidSource = {
        ...map,
        'memories': [
          {...original, 'source': 'system'},
        ],
      };
      final missingField = {
        ...map,
        'memories': [
          {...original}..remove('content'),
        ],
      };
      final invalidRevision = {
        ...map,
        'memories': [
          {...original, 'revision': 0},
        ],
      };
      for (final candidate in [invalidSource, missingField, invalidRevision]) {
        expect(
          () => MemorySnapshot.parse(
            _encode(candidate),
            expectedProfileId: 'p1',
            expectedCompanionId: 'c1',
          ),
          throwsFormatException,
        );
      }
    },
  );
}

String _encode(Map<String, Object?> map) => jsonEncode(map);

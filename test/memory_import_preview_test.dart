import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/memory_import_preview.dart';
import 'package:trackia/data/memory_snapshot.dart';
import 'package:trackia/domain/companion_memory.dart';

void main() {
  final t = DateTime.utc(2026, 1, 1);
  CompanionMemory mem(String id, String content,
          {String p = 'p1', String c = 'c1', int revision = 1,
          MemoryStatus status = MemoryStatus.active}) =>
      CompanionMemory(id: id, profileId: p, companionId: c, content: content,
          source: MemorySource.explicit, createdAt: t, updatedAt: t,
          revision: revision, status: status);
  MemorySnapshot snap(List<CompanionMemory> m, {String p = 'p1', String c = 'c1'}) =>
      MemorySnapshot(profileId: p, companionId: c, memories: m);

  test('separa nuevos, duplicados y conflictos sin aplicar nada', () {
    final local = [mem('a', 'Le gusta correr'), mem('b', 'Odia madrugar')];
    final preview = MemoryImportPreview.build(
      snapshot: snap([
        mem('a', 'Le gusta correr'),
        mem('b', 'Ahora madruga', revision: 2),
        mem('c', 'Vive en Lima'),
        mem('d', '  le gusta   CORRER '),
      ]),
      targetProfileId: 'p1',
      targetCompanionId: 'c1',
      existing: local,
    );
    expect(preview.toAdd.map((m) => m.id), ['c']);
    expect(preview.skipped.map((m) => m.id), ['a', 'd']);
    expect(preview.conflicts.single.local.content, 'Odia madrugar');
    expect(preview.conflicts.single.incoming.content, 'Ahora madruga');
    expect(preview.hasChanges, isTrue);
    expect(preview.hasConflicts, isTrue);
    expect(local.map((m) => m.id), ['a', 'b']);
  });

  test('rechaza un snapshot de otro ámbito', () {
    for (final other in [snap([], p: 'p2'), snap([], c: 'c2')]) {
      expect(
        () => MemoryImportPreview.build(
          snapshot: other, targetProfileId: 'p1',
          targetCompanionId: 'c1', existing: const []),
        throwsFormatException,
      );
    }
    expect(
      () => MemoryImportPreview.build(
        snapshot: snap([]), targetProfileId: 'p1', targetCompanionId: 'c1',
        existing: [mem('x', 'otro', c: 'c2')]),
      throwsArgumentError,
    );
  });

  test('vacío y repetidos dentro del snapshot', () {
    final empty = MemoryImportPreview.build(
      snapshot: snap([]), targetProfileId: 'p1',
      targetCompanionId: 'c1', existing: const []);
    expect(empty.hasChanges, isFalse);
    expect(empty.hasConflicts, isFalse);
    final dup = MemoryImportPreview.build(
      snapshot: snap([mem('a', 'Uno'), mem('b', 'uno')]),
      targetProfileId: 'p1', targetCompanionId: 'c1', existing: const []);
    expect(dup.toAdd.map((m) => m.id), ['a']);
    expect(dup.skipped.map((m) => m.id), ['b']);
  });
}

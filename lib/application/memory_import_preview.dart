import '../data/memory_snapshot.dart';
import '../domain/companion_memory.dart';

/// Conflicto: el mismo ID existe en local con contenido, estado o revisión
/// distintos del snapshot. Nunca se resuelve solo; decide el usuario.
class MemoryImportConflict {
  const MemoryImportConflict({required this.local, required this.incoming});
  final CompanionMemory local;
  final CompanionMemory incoming;
}

/// Vista previa pura de una importación de memoria: no escribe nada.
///
/// El ámbito destino es explícito. Un snapshot de otro perfil o acompañante se
/// rechaza con [FormatException] y no produce ninguna vista previa.
class MemoryImportPreview {
  MemoryImportPreview._({
    required this.profileId,
    required this.companionId,
    required List<CompanionMemory> toAdd,
    required List<CompanionMemory> skipped,
    required List<MemoryImportConflict> conflicts,
  }) : toAdd = List.unmodifiable(toAdd),
       skipped = List.unmodifiable(skipped),
       conflicts = List.unmodifiable(conflicts);

  final String profileId;
  final String companionId;

  /// Recuerdos nuevos que se añadirían si el usuario confirma.
  final List<CompanionMemory> toAdd;

  /// Duplicados exactos (mismo ID y datos, o mismo texto ya activo): se omiten.
  final List<CompanionMemory> skipped;

  /// Mismo ID con datos distintos; no se aplican sin decisión del usuario.
  final List<MemoryImportConflict> conflicts;

  bool get hasChanges => toAdd.isNotEmpty;
  bool get hasConflicts => conflicts.isNotEmpty;

  /// [existing] son los recuerdos locales del mismo ámbito destino.
  factory MemoryImportPreview.build({
    required MemorySnapshot snapshot,
    required String targetProfileId,
    required String targetCompanionId,
    required Iterable<CompanionMemory> existing,
  }) {
    if (snapshot.profileId != targetProfileId ||
        snapshot.companionId != targetCompanionId) {
      throw const FormatException(
        'El snapshot pertenece a otro perfil o acompañante.',
      );
    }
    final local = existing.toList();
    for (final memory in local) {
      if (memory.profileId != targetProfileId ||
          memory.companionId != targetCompanionId) {
        throw ArgumentError('Recuerdo local de otro ámbito.');
      }
    }
    final byId = {for (final m in local) m.id: m};
    final activeTexts = {
      for (final m in local)
        if (m.status == MemoryStatus.active) _norm(m.content),
    };
    final seen = <String>{};
    final add = <CompanionMemory>[];
    final skip = <CompanionMemory>[];
    final conflicts = <MemoryImportConflict>[];
    final incoming = [...snapshot.memories]
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final memory in incoming) {
      if (!seen.add(memory.id)) {
        skip.add(memory);
        continue;
      }
      final current = byId[memory.id];
      if (current != null) {
        if (_same(current, memory)) {
          skip.add(memory);
        } else {
          conflicts.add(MemoryImportConflict(local: current, incoming: memory));
        }
      } else if (memory.status == MemoryStatus.active &&
          !activeTexts.add(_norm(memory.content))) {
        skip.add(memory);
      } else {
        add.add(memory);
      }
    }
    return MemoryImportPreview._(
      profileId: targetProfileId,
      companionId: targetCompanionId,
      toAdd: add,
      skipped: skip,
      conflicts: conflicts,
    );
  }
}

bool _same(CompanionMemory a, CompanionMemory b) =>
    a.content == b.content && a.status == b.status && a.revision == b.revision;

String _norm(String text) => text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

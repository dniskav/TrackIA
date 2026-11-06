/// How a memory entered the companion's memory store.
enum MemorySource { explicit, inferred, userEdited }

/// Whether a memory may be shown to the assistant or needs user action.
enum MemoryStatus { active, pendingConfirmation, deleted }

/// One profile- and companion-scoped memory item.
///
/// This is a domain value only; persistence and any decision to save inferred
/// memories belong to higher layers. Content is always treated as user data,
/// never as a privileged instruction.
class CompanionMemory {
  CompanionMemory({
    required this.id,
    required this.profileId,
    required this.companionId,
    required this.content,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.sourceMessageId,
    this.revision = 1,
    this.status = MemoryStatus.active,
  }) {
    _requireText(id, 'id');
    _requireText(profileId, 'profileId');
    _requireText(companionId, 'companionId');
    _requireContent(content);
    if (sourceMessageId != null && sourceMessageId!.trim().isEmpty) {
      throw ArgumentError.value(sourceMessageId, 'sourceMessageId');
    }
    if (revision <= 0) throw ArgumentError.value(revision, 'revision');
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(updatedAt, 'updatedAt', 'Must not precede createdAt.');
    }
  }

  static const int maxContentLength = 2000;
  static const int maxContextMemories = 20;
  static const int maxContextCharacters = 12000;

  final String id;
  final String profileId;
  final String companionId;
  final String content;
  final MemorySource source;
  final String? sourceMessageId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;
  final MemoryStatus status;

  /// Creates an edited or status-updated revision while retaining identity,
  /// scope, creation time, and provenance. Edits become user-authored data.
  CompanionMemory revise({
    required DateTime at,
    String? content,
    MemoryStatus? status,
  }) {
    if (at.isBefore(updatedAt)) {
      throw ArgumentError.value(at, 'at', 'Must not precede updatedAt.');
    }
    final changedContent = content ?? this.content;
    final changed = changedContent != this.content || status != null;
    return CompanionMemory(
      id: id,
      profileId: profileId,
      companionId: companionId,
      content: changedContent,
      source: content != null && content != this.content
          ? MemorySource.userEdited
          : source,
      sourceMessageId: sourceMessageId,
      createdAt: createdAt,
      updatedAt: changed ? at : updatedAt,
      revision: changed ? revision + 1 : revision,
      status: status ?? this.status,
    );
  }
}

/// Bounded, deterministic context selection over candidates already deemed
/// relevant by the caller. This class does not perform semantic retrieval.
class MemoryContextSelection {
  MemoryContextSelection._({
    required this.memories,
    required this.contextText,
    required this.omittedCount,
    required this.needsClarification,
  });

  final List<CompanionMemory> memories;
  final String contextText;
  final int omittedCount;
  final bool needsClarification;

  static MemoryContextSelection select({
    required Iterable<CompanionMemory> candidates,
    required String profileId,
    required String companionId,
    Iterable<String>? relevantMemoryIds,
    Iterable<String>? referenceCandidateIds,
  }) {
    _requireText(profileId, 'profileId');
    _requireText(companionId, 'companionId');
    final referenceIds = referenceCandidateIds?.toSet() ?? const <String>{};
    if (referenceIds.length > 1) {
      return MemoryContextSelection._(
        memories: const [],
        contextText: '',
        omittedCount: 0,
        needsClarification: true,
      );
    }

    final relevant = relevantMemoryIds?.toSet();
    final eligible = candidates
        .where((memory) =>
            memory.profileId == profileId &&
            memory.companionId == companionId &&
            memory.status == MemoryStatus.active &&
            (relevant == null || relevant.contains(memory.id)))
        .toList()
      ..sort((a, b) {
        final dateOrder = b.updatedAt.compareTo(a.updatedAt);
        return dateOrder != 0 ? dateOrder : a.id.compareTo(b.id);
      });

    final selected = <CompanionMemory>[];
    var chars = 0;
    for (final memory in eligible) {
      if (selected.length == CompanionMemory.maxContextMemories) break;
      final addition = 2 + memory.content.length + (selected.isEmpty ? 0 : 1);
      if (chars + addition > CompanionMemory.maxContextCharacters) continue;
      selected.add(memory);
      chars += addition;
    }
    final context = selected
        .map((memory) => '- ${memory.content}')
        .join('\n');
    return MemoryContextSelection._(
      memories: List.unmodifiable(selected),
      contextText: context,
      omittedCount: eligible.length - selected.length,
      needsClarification: false,
    );
  }
}

void _requireContent(String value) {
  if (value.trim().isEmpty || value.length > CompanionMemory.maxContentLength) {
    throw ArgumentError.value(
      value,
      'content',
      'Must contain 1–${CompanionMemory.maxContentLength} characters.',
    );
  }
}

void _requireText(String value, String name) {
  if (value.trim().isEmpty) throw ArgumentError.value(value, name);
}

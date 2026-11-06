import '../data/companion_memory_repository.dart';
import '../domain/companion_memory.dart';

/// Disposition returned by the assistant for a possible memory.
enum MemoryProposalAction { save, ask, ignore }

/// A validated, inert proposal. Creating one never writes to storage.
class CompanionMemoryProposal {
  const CompanionMemoryProposal._({
    required this.action,
    required this.profileId,
    required this.companionId,
    required this.sourceMessageId,
    this.content,
    this.source,
  });

  final MemoryProposalAction action;
  final String profileId;
  final String companionId;
  final String sourceMessageId;
  final String? content;
  final MemorySource? source;
}

/// Pure validation and selection rules for assistant memory proposals.
/// Persistence and user-interface confirmation remain caller responsibilities.
class CompanionMemoryService {
  const CompanionMemoryService();

  /// Accept only the closed proposal shape. Scope always comes from the
  /// application, never from assistant-controlled JSON. Text is data, not code
  /// or an instruction to this service.
  CompanionMemoryProposal? parseProposal(
    Map<String, Object?> data, {
    required String profileId,
    required String companionId,
    required String sourceMessageId,
    required bool userExplicitlyRequestedSave,
  }) {
    if (_blank(profileId) || _blank(companionId) || _blank(sourceMessageId)) {
      return null;
    }
    if (data.keys.any((key) => !const {'action', 'content'}.contains(key))) {
      return null;
    }
    final rawAction = data['action'];
    final action = switch (rawAction) {
      'save' => MemoryProposalAction.save,
      'ask' => MemoryProposalAction.ask,
      'ignore' => MemoryProposalAction.ignore,
      _ => null,
    };
    if (action == null) return null;
    final rawContent = data['content'];
    if (rawContent != null && rawContent is! String) return null;
    final content = rawContent as String?;
    if (content != null &&
        (content.trim().isEmpty ||
            content.length > CompanionMemory.maxContentLength)) {
      return null;
    }
    if (action == MemoryProposalAction.save && content == null) return null;
    if (action == MemoryProposalAction.ignore) {
      // `ignore` never keeps data it was given: a contentful ignore is
      // malformed, an empty one is a plain refusal.
      if (content != null) return null;
      return CompanionMemoryProposal._(
        action: action,
        profileId: profileId.trim(),
        companionId: companionId.trim(),
        sourceMessageId: sourceMessageId.trim(),
      );
    }
    // Provenance is fixed by the app: an explicit user request for saving
    // makes it explicit; anything else the assistant inferred stays inferred.
    final source = userExplicitlyRequestedSave
        ? MemorySource.explicit
        : MemorySource.inferred;
    return CompanionMemoryProposal._(
      action: action,
      profileId: profileId.trim(),
      companionId: companionId.trim(),
      sourceMessageId: sourceMessageId.trim(),
      content: content,
      source: content != null ? source : null,
    );
  }
  /// User approval is the only route from an inert proposal to a memory.
  /// Rejection and non-save responses return null and have no side effects.
  CompanionMemory? accept(
    CompanionMemoryProposal proposal, {
    required String id,
    required DateTime at,
  }) {
    if (proposal.action != MemoryProposalAction.save) return null;
    return CompanionMemory(
      id: id,
      profileId: proposal.profileId,
      companionId: proposal.companionId,
      content: proposal.content!,
      source: proposal.source!,
      sourceMessageId: proposal.sourceMessageId,
      createdAt: at,
      updatedAt: at,
      status: MemoryStatus.active,
    );
  }

  CompanionMemory? reject(CompanionMemoryProposal proposal) => null;

  /// Persisted acceptance: the connection between an approved proposal and the
  /// real v7 table through [CompanionMemoryRepository]. Call it only after the
  /// user has approved the proposal; that approval is what the contract calls
  /// acceptance (`save` goes straight to the table on acceptance, `ask` is
  /// saved because this call IS that acceptance, `ignore` writes nothing).
  ///
  /// Scope always matches the repository profile: cross-scope persistence is
  /// rejected. Content bounds (1–2000 characters) come from [CompanionMemory],
  /// provenance (`explicit` when the user explicitly requested saving, else
  /// `inferred`) comes from the proposal, and the proposal's message id is
  /// stored as source when it exists.
  Future<CompanionMemory?> acceptPersisted(
    CompanionMemoryProposal proposal, {
    required CompanionMemoryRepository repository,
    required DateTime at,
    MemoryStatus status = MemoryStatus.active,
    String? id,
  }) async {
    if (proposal.action == MemoryProposalAction.ignore) return null;
    final content = proposal.content;
    if (content == null || content.trim().isEmpty) return null;
    if (repository.profileId != proposal.profileId) {
      throw ArgumentError(
        'La propuesta es del perfil ${proposal.profileId} pero el repositorio '
        'es del perfil ${repository.profileId}.',
      );
    }
    return repository.create(
      companionId: proposal.companionId,
      content: content,
      source: proposal.source!,
      sourceMessageId: proposal.sourceMessageId,
      status: status,
      at: at,
      id: id,
    );
  }

  /// Keeps context bounded and only selects caller-designated relevant IDs.
  MemoryContextSelection selectRelevant({
    required Iterable<CompanionMemory> candidates,
    required String profileId,
    required String companionId,
    required Iterable<String> relevantMemoryIds,
    Iterable<String>? referenceCandidateIds,
  }) => MemoryContextSelection.select(
    candidates: candidates,
    profileId: profileId,
    companionId: companionId,
    relevantMemoryIds: relevantMemoryIds,
    referenceCandidateIds: referenceCandidateIds,
  );
}

bool _blank(String value) => value.trim().isEmpty;

/// Delivery state for a persisted user message.
enum MessageDelivery { pending, sending, answered, failed, uncertain }

/// Stable identity and delivery metadata for one chat message.
///
/// Text lives in [MessageRevision] so edits can retain the original content.
class Message {
  Message({
    required this.id,
    required this.profileId,
    required this.companionId,
    required this.chatId,
    required this.createdAt,
    required this.currentRevisionId,
    this.delivery = MessageDelivery.pending,
    List<String> attachmentRefs = const [],
  }) : attachmentRefs = List.unmodifiable(attachmentRefs) {
    _requireText(id, 'id');
    _requireText(profileId, 'profileId');
    _requireText(companionId, 'companionId');
    _requireText(chatId, 'chatId');
    _requireText(currentRevisionId, 'currentRevisionId');
    if (this.attachmentRefs.any((ref) => ref.trim().isEmpty)) {
      throw ArgumentError.value(attachmentRefs, 'attachmentRefs');
    }
  }

  final String id;
  final String profileId;
  final String companionId;
  final String chatId;
  final DateTime createdAt;
  final String currentRevisionId;
  final MessageDelivery delivery;
  final List<String> attachmentRefs;
}

/// Immutable snapshot of a message's text at one point in its edit history.
class MessageRevision {
  MessageRevision({
    required this.id,
    required this.messageId,
    required this.revision,
    required this.text,
    required this.createdAt,
    this.supersedesId,
  }) {
    _requireText(id, 'id');
    _requireText(messageId, 'messageId');
    if (revision <= 0) throw ArgumentError.value(revision, 'revision');
    if (text.trim().isEmpty || text.length > maxTextLength) {
      throw ArgumentError.value(
        text,
        'text',
        'Must contain 1–8000 characters.',
      );
    }
    if (supersedesId != null && supersedesId!.trim().isEmpty) {
      throw ArgumentError.value(supersedesId, 'supersedesId');
    }
  }

  static const int maxTextLength = 8000;

  final String id;
  final String messageId;
  final int revision;
  final String text;
  final DateTime createdAt;
  final String? supersedesId;
}

void _requireText(String value, String name) {
  if (value.trim().isEmpty) throw ArgumentError.value(value, name);
}

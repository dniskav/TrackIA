import '../data/message_revision_repository.dart';
import '../domain/message_revision.dart';
import 'message_delivery_policy.dart';

/// Application boundary for durable delivery. Opening a scope only recovers
/// interrupted states; it deliberately has no transport and cannot auto-send.
class MessageDeliveryService {
  const MessageDeliveryService(this.repository);

  final MessageRevisionRepository repository;

  Future<int> openScope({String? chatId}) =>
      repository.recoverSending(chatId: chatId);

  Future<List<MessageDeliveryItem>> pending(String chatId) async {
    final items = await repository.queue(chatId);
    for (final item in items) {
      if (!MessageDeliveryPolicy.canRetry(item.message.delivery)) {
        throw StateError('La cola contiene un estado no reintentable.');
      }
    }
    return items;
  }

  Future<MessageDeliveryItem?> begin(
    String messageId, {
    required String expectedRevisionId,
  }) async {
    final current = await repository.load(messageId);
    if (current == null ||
        current.message.currentRevisionId != expectedRevisionId ||
        !MessageDeliveryPolicy.canRetry(current.message.delivery)) {
      return null;
    }
    MessageDeliveryPolicy.beginAttempt(current.message.delivery);
    return repository.beginAttempt(
      messageId,
      expectedRevisionId: expectedRevisionId,
    );
  }

  Future<MessageAnswerStatus> answer(
    String messageId, {
    required String expectedRevisionId,
  }) => repository.recordAnswer(
    messageId,
    expectedRevisionId: expectedRevisionId,
  );

  Future<MessageDelivery?> failure(
    String messageId, {
    required String expectedRevisionId,
    required bool acceptanceKnown,
  }) async {
    MessageDeliveryPolicy.recordFailure(acceptanceKnown: acceptanceKnown);
    return repository.recordFailure(
      messageId,
      expectedRevisionId: expectedRevisionId,
      acceptanceKnown: acceptanceKnown,
    );
  }
}

import '../domain/message_revision.dart';

/// Pure delivery rules for a message with stable identity.
///
/// This policy does not persist messages or make network calls. Callers must
/// commit every transition before starting the corresponding external work.
/// `failed` means the transport established that the request was not accepted;
/// an ambiguous timeout must be recorded as `uncertain` instead.
class MessageDeliveryPolicy {
  const MessageDeliveryPolicy._();

  /// Interrupted work is never assumed safe to repeat.
  static MessageDelivery recoverAfterRestart(MessageDelivery state) =>
      state == MessageDelivery.sending ? MessageDelivery.uncertain : state;

  /// Only work known not to have been accepted can be sent again.
  static bool canRetry(MessageDelivery state) =>
      state == MessageDelivery.pending || state == MessageDelivery.failed;

  /// Start one attempt. The caller must persist `sending` before dispatch.
  static MessageDelivery beginAttempt(MessageDelivery state) {
    if (!canRetry(state)) {
      throw StateError('Message is not safe to retry from $state.');
    }
    return MessageDelivery.sending;
  }

  /// Record a transport failure only when rejection/non-acceptance is known.
  /// If acceptance is ambiguous, retain `uncertain` until reconciliation.
  static MessageDelivery recordFailure({required bool acceptanceKnown}) =>
      acceptanceKnown ? MessageDelivery.failed : MessageDelivery.uncertain;

  /// A late response may settle an uncertain attempt without creating a new
  /// message. The message ID remains the identity used by the caller.
  static MessageDelivery recordAnswer(MessageDelivery state) {
    if (state != MessageDelivery.sending && state != MessageDelivery.uncertain) {
      throw StateError('Cannot attach a response from $state.');
    }
    return MessageDelivery.answered;
  }
}

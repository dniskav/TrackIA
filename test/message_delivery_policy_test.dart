import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/application/message_delivery_policy.dart';
import 'package:trackia/domain/message_revision.dart';

void main() {
  group('MessageDeliveryPolicy', () {
    test('restart changes only an interrupted send to uncertain', () {
      expect(
        MessageDeliveryPolicy.recoverAfterRestart(MessageDelivery.sending),
        MessageDelivery.uncertain,
      );
      for (final state in [
        MessageDelivery.pending,
        MessageDelivery.answered,
        MessageDelivery.failed,
        MessageDelivery.uncertain,
      ]) {
        expect(MessageDeliveryPolicy.recoverAfterRestart(state), state);
      }
    });

    test('retry is permitted only when request is known unaccepted', () {
      expect(MessageDeliveryPolicy.canRetry(MessageDelivery.pending), isTrue);
      expect(MessageDeliveryPolicy.canRetry(MessageDelivery.failed), isTrue);
      expect(MessageDeliveryPolicy.canRetry(MessageDelivery.sending), isFalse);
      expect(MessageDeliveryPolicy.canRetry(MessageDelivery.uncertain), isFalse);
      expect(MessageDeliveryPolicy.canRetry(MessageDelivery.answered), isFalse);
      expect(
        MessageDeliveryPolicy.beginAttempt(MessageDelivery.pending),
        MessageDelivery.sending,
      );
      expect(
        () => MessageDeliveryPolicy.beginAttempt(MessageDelivery.uncertain),
        throwsStateError,
      );
    });

    test('ambiguous transport failure is uncertain, not retryable', () {
      expect(
        MessageDeliveryPolicy.recordFailure(acceptanceKnown: true),
        MessageDelivery.failed,
      );
      expect(
        MessageDeliveryPolicy.recordFailure(acceptanceKnown: false),
        MessageDelivery.uncertain,
      );
      expect(
        MessageDeliveryPolicy.canRetry(
          MessageDeliveryPolicy.recordFailure(acceptanceKnown: false),
        ),
        isFalse,
      );
    });

    test('late answer settles same uncertain message without a new attempt', () {
      expect(
        MessageDeliveryPolicy.recordAnswer(MessageDelivery.uncertain),
        MessageDelivery.answered,
      );
      expect(
        () => MessageDeliveryPolicy.recordAnswer(MessageDelivery.pending),
        throwsStateError,
      );
    });
  });
}

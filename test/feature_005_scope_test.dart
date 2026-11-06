import 'package:flutter_test/flutter_test.dart';
import 'package:trackia/data/feature_scope.dart';
import 'package:trackia/domain/workout.dart';

void main() {
  const rawId = 'same-id';

  FeatureScope scope(String profile, String companion) =>
      FeatureScope(profileId: profile, companionId: companion);

  test('IDs are qualified by profile and companion', () {
    final profileACompanionA = FeatureScopedId(
      scope: scope('profile-a', 'companion-a'),
      id: rawId,
    );
    final profileBCompanionA = FeatureScopedId(
      scope: scope('profile-b', 'companion-a'),
      id: rawId,
    );
    final profileACompanionB = FeatureScopedId(
      scope: scope('profile-a', 'companion-b'),
      id: rawId,
    );

    expect({
      profileACompanionA,
      profileBCompanionA,
      profileACompanionB,
    }, hasLength(3));
    expect(
      FeatureScopedId(scope: scope('profile-a', 'companion-a'), id: rawId),
      profileACompanionA,
    );
  });

  test('a reference is accepted only in its exact profile and companion', () {
    final owner = scope('profile-a', 'companion-a');
    final target = FeatureScopedId(scope: owner, id: rawId);

    expect(
      () => FeatureScopeValidator.requireReference(
        ownerScope: owner,
        referenceId: rawId,
        referenced: target,
      ),
      returnsNormally,
    );
    for (final foreignScope in [
      scope('profile-b', 'companion-a'),
      scope('profile-a', 'companion-b'),
      scope('profile-b', 'companion-b'),
    ]) {
      expect(
        () => FeatureScopeValidator.requireReference(
          ownerScope: owner,
          referenceId: rawId,
          referenced: FeatureScopedId(scope: foreignScope, id: rawId),
        ),
        throwsA(isA<ValidationException>()),
      );
    }
  });

  test('a mismatched or malformed reference ID is rejected', () {
    final owner = scope('profile-a', 'companion-a');
    final target = FeatureScopedId(scope: owner, id: rawId);

    expect(
      () => FeatureScopeValidator.requireReference(
        ownerScope: owner,
        referenceId: 'other-id',
        referenced: target,
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => FeatureScopeValidator.requireReference(
        ownerScope: owner,
        referenceId: '../same-id',
        referenced: target,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('scope and scoped IDs reject malformed identifiers', () {
    expect(
      () => FeatureScope(profileId: 'profile-a', companionId: '../companion'),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => FeatureScopedId(scope: scope('profile-a', 'companion-a'), id: ''),
      throwsA(isA<ValidationException>()),
    );
  });
}

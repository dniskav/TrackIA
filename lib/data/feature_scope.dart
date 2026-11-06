import '../domain/space.dart';
import '../domain/workout.dart';

/// The owner of data introduced by feature 005.
///
/// IDs are only unique inside this scope. Persisted IDs must therefore be
/// queried and referenced together with both [profileId] and [companionId].
class FeatureScope {
  FeatureScope({required String profileId, required String companionId})
    : profileId = validTrackiaId(profileId),
      companionId = validTrackiaId(companionId);

  final String profileId;
  final String companionId;

  @override
  bool operator ==(Object other) =>
      other is FeatureScope &&
      other.profileId == profileId &&
      other.companionId == companionId;

  @override
  int get hashCode => Object.hash(profileId, companionId);
}

/// An entity identifier qualified by its profile and companion owner.
///
/// The same opaque ID can be used by different scopes without referring to
/// the same entity.
class FeatureScopedId {
  FeatureScopedId({required this.scope, required String id})
    : id = validTrackiaId(id);

  final FeatureScope scope;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is FeatureScopedId && other.scope == scope && other.id == id;

  @override
  int get hashCode => Object.hash(scope, id);
}

/// Shared checks for scoped records and their references.
class FeatureScopeValidator {
  const FeatureScopeValidator._();

  /// Rejects a row loaded or written under a scope other than the caller's.
  static void requireScope({
    required FeatureScope requested,
    required FeatureScope stored,
  }) {
    if (requested != stored) {
      throw const ValidationException(
        'El dato pertenece a otro perfil o acompañante.',
      );
    }
  }

  /// Checks both components of a foreign-key reference, not only its raw ID.
  static void requireReference({
    required FeatureScope ownerScope,
    required String referenceId,
    required FeatureScopedId referenced,
  }) {
    final checkedId = validTrackiaId(referenceId);
    requireScope(requested: ownerScope, stored: referenced.scope);
    if (checkedId != referenced.id) {
      throw const ValidationException('La referencia no coincide con el dato.');
    }
  }
}

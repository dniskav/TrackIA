import 'dart:convert';

import 'memory_snapshot.dart';

/// Transport boundary for a remote memory snapshot store. Implementations must
/// enforce [expectedRevision] atomically when writing and scope every operation
/// to the authenticated account and app-private storage area.
abstract interface class MemoryCloudTransport {
  Future<MemoryCloudDocument?> read({
    required String accountId,
    required String key,
  });
  Future<MemoryCloudWriteResult> write({
    required String accountId,
    required String key,
    required String payload,
    required int? expectedRevision,
  });
  Future<MemoryCloudDeleteResult> delete({
    required String accountId,
    required String key,
  });
}

class MemoryCloudDocument {
  const MemoryCloudDocument({
    required this.accountId,
    required this.key,
    required this.payload,
  });
  final String accountId;
  final String key;
  final String payload;
}

enum MemoryCloudWriteResult {
  written,
  conflict,
  uncertain,
  cancelled,
  permissionDenied,
  failed,
}

enum MemoryCloudDeleteResult {
  deleted,
  absent,
  uncertain,
  cancelled,
  permissionDenied,
  failed,
}

enum MemoryCloudStatus {
  success,
  conflict,
  uncertain,
  cancelled,
  permissionDenied,
  failed,
  notFound,
}

class MemoryCloudException implements Exception {
  const MemoryCloudException(this.status);
  final MemoryCloudStatus status;
}

class MemoryCloudResult {
  const MemoryCloudResult({
    required this.status,
    this.accountId,
    this.revision,
    this.updatedAt,
    this.snapshot,
  });
  final MemoryCloudStatus status;
  final String? accountId;
  final int? revision;
  final DateTime? updatedAt;
  final MemorySnapshot? snapshot;
  bool get succeeded => status == MemoryCloudStatus.success;
}

/// Orchestrates account- and scope-bound cloud copies through an injected
/// transport. It contains no OAuth flow and does not claim Google integration.
class MemoryGoogleDriveService {
  MemoryGoogleDriveService(this.transport, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final MemoryCloudTransport transport;
  final DateTime Function() _clock;

  Future<MemoryCloudResult> load({
    required String accountId,
    required String profileId,
    required String companionId,
  }) async {
    _validate(accountId, profileId, companionId);
    try {
      final doc = await transport.read(
        accountId: accountId,
        key: _key(profileId, companionId),
      );
      if (doc == null) {
        return MemoryCloudResult(
          status: MemoryCloudStatus.notFound,
          accountId: accountId,
        );
      }
      if (doc.accountId != accountId ||
          doc.key != _key(profileId, companionId)) {
        return _failed(accountId);
      }
      final envelope = jsonDecode(doc.payload);
      if (envelope is! Map<String, dynamic> ||
          envelope.keys.toSet().difference(const {
            'version',
            'accountId',
            'profileId',
            'companionId',
            'revision',
            'updatedAt',
            'snapshot',
          }).isNotEmpty ||
          envelope.keys.toSet().length != 7 ||
          envelope['version'] != 1 ||
          envelope['accountId'] != accountId ||
          envelope['profileId'] != profileId ||
          envelope['companionId'] != companionId ||
          envelope['revision'] is! int ||
          envelope['revision'] <= 0 ||
          envelope['updatedAt'] is! String ||
          envelope['snapshot'] is! String) {
        return _failed(accountId);
      }
      final updatedAt = DateTime.tryParse(envelope['updatedAt'] as String);
      if (updatedAt == null) return _failed(accountId);
      final snapshot = MemorySnapshot.parse(
        envelope['snapshot'] as String,
        expectedProfileId: profileId,
        expectedCompanionId: companionId,
      );
      if (snapshot.memories.any((memory) => memory.status.name != 'active')) {
        return _failed(accountId);
      }
      return MemoryCloudResult(
        status: MemoryCloudStatus.success,
        accountId: accountId,
        revision: envelope['revision'] as int,
        updatedAt: updatedAt,
        snapshot: snapshot,
      );
    } on FormatException {
      return _failed(accountId);
    } on MemoryCloudException catch (error) {
      return MemoryCloudResult(status: error.status, accountId: accountId);
    } catch (_) {
      return _failed(accountId);
    }
  }

  Future<MemoryCloudResult> save({
    required String accountId,
    required MemorySnapshot snapshot,
    required int? knownRevision,
  }) async {
    _validate(accountId, snapshot.profileId, snapshot.companionId);
    if (snapshot.memories.any((memory) => memory.status.name != 'active')) {
      throw ArgumentError('La copia remota solo admite recuerdos activos.');
    }
    if (knownRevision != null && knownRevision <= 0) {
      throw ArgumentError.value(knownRevision, 'knownRevision');
    }
    try {
      // Always inspect identity and latest revision before attempting a write.
      final current = await load(
        accountId: accountId,
        profileId: snapshot.profileId,
        companionId: snapshot.companionId,
      );
      if (current.status == MemoryCloudStatus.failed ||
          current.status == MemoryCloudStatus.permissionDenied ||
          current.status == MemoryCloudStatus.cancelled ||
          current.status == MemoryCloudStatus.uncertain) {
        return current;
      }
      final actualRevision =
          current.status == MemoryCloudStatus.notFound
              ? null
              : current.revision;
      if (actualRevision != knownRevision) {
        return MemoryCloudResult(
          status: MemoryCloudStatus.conflict,
          accountId: accountId,
          revision: actualRevision,
          updatedAt: current.updatedAt,
          snapshot: current.snapshot,
        );
      }
      final next = (actualRevision ?? 0) + 1;
      final now = _clock().toUtc();
      final envelope = jsonEncode({
        'version': 1,
        'accountId': accountId,
        'profileId': snapshot.profileId,
        'companionId': snapshot.companionId,
        'revision': next,
        'updatedAt': now.toIso8601String(),
        'snapshot': snapshot.toJson(),
      });
      final result = await transport.write(
        accountId: accountId,
        key: _key(snapshot.profileId, snapshot.companionId),
        payload: envelope,
        expectedRevision: actualRevision,
      );
      final status = switch (result) {
        MemoryCloudWriteResult.written => MemoryCloudStatus.success,
        MemoryCloudWriteResult.conflict => MemoryCloudStatus.conflict,
        MemoryCloudWriteResult.uncertain => MemoryCloudStatus.uncertain,
        MemoryCloudWriteResult.cancelled => MemoryCloudStatus.cancelled,
        MemoryCloudWriteResult.permissionDenied =>
          MemoryCloudStatus.permissionDenied,
        MemoryCloudWriteResult.failed => MemoryCloudStatus.failed,
      };
      return MemoryCloudResult(
        status: status,
        accountId: accountId,
        revision: status == MemoryCloudStatus.success ? next : actualRevision,
        updatedAt:
            status == MemoryCloudStatus.success ? now : current.updatedAt,
        snapshot:
            status == MemoryCloudStatus.success ? snapshot : current.snapshot,
      );
    } catch (_) {
      return _failed(accountId);
    }
  }

  Future<MemoryCloudResult> delete({
    required String accountId,
    required String profileId,
    required String companionId,
    required int knownRevision,
  }) async {
    _validate(accountId, profileId, companionId);
    if (knownRevision <= 0) {
      throw ArgumentError.value(knownRevision, 'knownRevision');
    }
    try {
      final current = await load(
        accountId: accountId,
        profileId: profileId,
        companionId: companionId,
      );
      if (current.status != MemoryCloudStatus.success) return current;
      if (current.revision != knownRevision) {
        return MemoryCloudResult(
          status: MemoryCloudStatus.conflict,
          accountId: accountId,
          revision: current.revision,
          updatedAt: current.updatedAt,
          snapshot: current.snapshot,
        );
      }
      final result = await transport.delete(
        accountId: accountId,
        key: _key(profileId, companionId),
      );
      final status = switch (result) {
        MemoryCloudDeleteResult.deleted ||
        MemoryCloudDeleteResult.absent => MemoryCloudStatus.success,
        MemoryCloudDeleteResult.uncertain => MemoryCloudStatus.uncertain,
        MemoryCloudDeleteResult.cancelled => MemoryCloudStatus.cancelled,
        MemoryCloudDeleteResult.permissionDenied =>
          MemoryCloudStatus.permissionDenied,
        MemoryCloudDeleteResult.failed => MemoryCloudStatus.failed,
      };
      return MemoryCloudResult(
        status: status,
        accountId: accountId,
        revision: status == MemoryCloudStatus.success ? null : knownRevision,
      );
    } catch (_) {
      return _failed(accountId);
    }
  }
}

String _key(String profileId, String companionId) =>
    'memory-v1:${base64Url.encode(utf8.encode('$profileId\u0000$companionId'))}';
void _validate(String accountId, String profileId, String companionId) {
  for (final entry
      in {
        'accountId': accountId,
        'profileId': profileId,
        'companionId': companionId,
      }.entries) {
    if (entry.value.trim().isEmpty) {
      throw ArgumentError.value(entry.value, entry.key);
    }
  }
}

MemoryCloudResult _failed(String accountId) =>
    MemoryCloudResult(status: MemoryCloudStatus.failed, accountId: accountId);

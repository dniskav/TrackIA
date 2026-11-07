import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/ai_client.dart';
import '../data/ai_model_catalog.dart';
import '../data/ai_settings_store.dart';
import '../domain/workout.dart';
import '../l10n/generated/app_localizations.dart';

enum AiAvailabilityStatus {
  checking,
  unconfigured,
  unverified,
  ready,
  unavailable,
}

/// Language-neutral reason behind the current [AiAvailability] state. The UI
/// turns it into text with [AiAvailability.text] / [AiAvailability.settingsText];
/// nothing in the application layer depends on Spanish wording.
enum AiNotice {
  checking,
  unconfigured,
  unverified,
  verified,
  catalogFailedWithReason,
  catalogFailed,
  validationError,
  unreachable,
  requestFailed,
}

/// Configuration is not evidence of a working model. A real reply verifies
/// credentials/model; catalog checks refresh connectivity without inference.
class AiAvailability extends ChangeNotifier {
  AiAvailability({
    AiModelCatalog? catalog,
    AiClient? client,
    this.store = const AiSettingsStore(),
  }) : catalog = catalog ?? AiModelCatalog(),
       client = client ?? AiClient();
  final AiModelCatalog catalog;
  final AiClient client;
  final AiSettingsStore store;
  AiAvailabilityStatus status = AiAvailabilityStatus.checking;
  AiNotice notice = AiNotice.checking;

  /// Model id for [AiNotice.verified]; validation reason for
  /// [AiNotice.validationError] and [AiNotice.catalogFailedWithReason]
  /// (already user-facing text produced by the domain layer).
  String detail = '';
  bool get ready => status == AiAvailabilityStatus.ready;
  int _request = 0;
  bool _disposed = false;

  void _set(
    int request,
    AiAvailabilityStatus next,
    AiNotice reason, [
    String info = '',
  ]) {
    if (_disposed || request != _request) return;
    status = next;
    notice = reason;
    detail = info;
    notifyListeners();
  }

  /// Full status sentence, as shown in the chat banner.
  String text(AppLocalizations l) => switch (notice) {
    AiNotice.checking => l.aiStatusChecking,
    AiNotice.unconfigured => l.aiStatusUnconfigured,
    AiNotice.unverified => l.aiStatusUnverified,
    AiNotice.verified => l.aiStatusVerified(detail),
    AiNotice.catalogFailedWithReason => l.aiStatusCatalogReason(detail),
    AiNotice.catalogFailed => l.aiStatusCatalogFailed,
    AiNotice.validationError => detail,
    AiNotice.unreachable => l.aiStatusUnreachable,
    AiNotice.requestFailed => l.aiStatusRequestFailed,
  };

  /// Short row subtitle for the settings screen.
  String settingsText(AppLocalizations l) => switch (status) {
    AiAvailabilityStatus.ready when notice == AiNotice.verified =>
      '${l.verified} · $detail',
    AiAvailabilityStatus.ready => text(l),
    AiAvailabilityStatus.unconfigured => l.notConnected,
    AiAvailabilityStatus.unverified => l.notVerified,
    AiAvailabilityStatus.unavailable => l.unavailable,
    AiAvailabilityStatus.checking => l.checking,
  };

  Future<void> check({
    bool verify = false,
    bool acceptRecentVerification = false,
  }) async {
    final request = ++_request;
    final wasReady = ready && !verify;
    if (!wasReady) {
      _set(request, AiAvailabilityStatus.checking, AiNotice.checking);
    }
    try {
      final config = await store.load();
      if (config == null) {
        _set(
          request,
          AiAvailabilityStatus.unconfigured,
          AiNotice.unconfigured,
        );
        return;
      }
      config.validate();
      if (verify) {
        await client.reply(
          config,
          const [AiMessage('user', 'Responde OK.')],
          system: 'Comprobación de conexión de TrackIA. Responde brevemente.',
          sessionId: 'gymia-connection-check',
        );
        if (_disposed || request != _request) return;
        await store.markVerified(config);
      } else {
        final recentlyVerified =
            acceptRecentVerification && await store.recentlyVerified(config);
        if (!recentlyVerified) {
          if (!await store.isVerified(config)) {
            _set(
              request,
              AiAvailabilityStatus.unverified,
              AiNotice.unverified,
            );
            return;
          }
          // A saved successful reply verifies this exact configuration. The
          // provider's model catalog can fail independently of inference and
          // must never interrupt a workout or disable an already working chat.
        }
      }
      if (_disposed || request != _request) return;
      if ((await store.load())?.toJson().toString() !=
          config.toJson().toString()) {
        await check();
        return;
      }
      _set(
        request,
        AiAvailabilityStatus.ready,
        AiNotice.verified,
        config.modelId,
      );
    } on ValidationException catch (e) {
      if (wasReady) {
        _set(
          request,
          AiAvailabilityStatus.ready,
          AiNotice.catalogFailedWithReason,
          e.message,
        );
      } else {
        _set(
          request,
          AiAvailabilityStatus.unavailable,
          AiNotice.validationError,
          e.message,
        );
      }
    } catch (_) {
      _set(
        request,
        wasReady
            ? AiAvailabilityStatus.ready
            : AiAvailabilityStatus.unavailable,
        wasReady ? AiNotice.catalogFailed : AiNotice.unreachable,
      );
    }
  }

  void failed() {
    _set(
      ++_request,
      ready ? AiAvailabilityStatus.ready : AiAvailabilityStatus.unavailable,
      AiNotice.requestFailed,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/ai_client.dart';
import '../data/ai_model_catalog.dart';
import '../data/ai_settings_store.dart';
import '../domain/workout.dart';

enum AiAvailabilityStatus {
  checking,
  unconfigured,
  unverified,
  ready,
  unavailable,
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
  String message = 'Comprobando IA…';
  bool get ready => status == AiAvailabilityStatus.ready;
  int _request = 0;
  bool _disposed = false;

  void _set(int request, AiAvailabilityStatus next, String text) {
    if (_disposed || request != _request) return;
    status = next;
    message = text;
    notifyListeners();
  }

  Future<void> check({
    bool verify = false,
    bool acceptRecentVerification = false,
  }) async {
    final request = ++_request;
    final wasReady = ready && !verify;
    if (!wasReady) {
      _set(request, AiAvailabilityStatus.checking, 'Comprobando IA…');
    }
    try {
      final config = await store.load();
      if (config == null) {
        _set(
          request,
          AiAvailabilityStatus.unconfigured,
          'Configura tu proveedor y modelo para usar el asistente. Puedes cargar tus datos antes.',
        );
        return;
      }
      config.validate();
      if (verify) {
        await client.reply(
          config,
          const [AiMessage('user', 'Responde OK.')],
          system: 'Comprobación de conexión de GymIA. Responde brevemente.',
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
              'Verifica la conexión del modelo para habilitar el asistente y las actividades.',
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
        'IA verificada · ${config.modelId}',
      );
    } on ValidationException catch (e) {
      if (wasReady) {
        _set(
          request,
          AiAvailabilityStatus.ready,
          'IA configurada · no se pudo actualizar el catálogo: ${e.message}',
        );
      } else {
        _set(request, AiAvailabilityStatus.unavailable, e.message);
      }
    } catch (_) {
      _set(
        request,
        wasReady
            ? AiAvailabilityStatus.ready
            : AiAvailabilityStatus.unavailable,
        wasReady
            ? 'IA configurada · no se pudo actualizar el catálogo. Puedes seguir enviando mensajes.'
            : 'No se pudo comprobar la conexión con la IA. Reintenta o revisa el proveedor. Tus datos se conservan.',
      );
    }
  }

  void failed() {
    _set(
      ++_request,
      ready ? AiAvailabilityStatus.ready : AiAvailabilityStatus.unavailable,
      'La última solicitud falló. Puedes reintentar con el mismo modelo; tus registros se conservan.',
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _request++;
    super.dispose();
  }
}

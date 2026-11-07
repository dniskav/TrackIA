part of '../assistant_chat.dart';

/// Registro de efectos: lo que la app ejecuta de verdad por una respuesta del
/// asistente queda anotado contra el mensaje y la revisión que lo originó.
/// Una propuesta sin confirmar nunca se anota; solo lo ya aplicado.
extension _ChatEffects on _AssistantChatScreenState {
  /// Mensaje del usuario al que responde lo que se está aplicando. Fuera del
  /// envío (p. ej. al pulsar una tarjeta) es la última respuesta enlazada.
  ({String messageId, String revisionId})? effectOrigin() {
    final active = activeEffectOrigin;
    if (active != null) return active;
    for (final message in messages.reversed) {
      final link = responseLinks[message];
      if (message.role == 'assistant' && link != null) return link;
    }
    return null;
  }

  /// Clave de idempotencia, o null sin cola durable ni mensaje de origen.
  String? effectKey(String kind, String discriminator) {
    final origin = effectOrigin();
    if (messageEffects == null || origin == null) return null;
    return MessageEffect.keyFor(origin.messageId, kind, discriminator);
  }

  /// True si ese efecto ya se aplicó para este mensaje: no hay que repetirlo.
  Future<bool> effectAlreadyApplied(String kind, String discriminator) async {
    final key = effectKey(kind, discriminator);
    if (key == null) return false;
    try {
      return await messageEffects!.isApplied(key);
    } catch (_) {
      return false;
    }
  }

  /// Anota un efecto ya ejecutado. Un fallo del registro no deshace nada.
  Future<void> recordEffect(
    String kind,
    String discriminator,
    String summary, {
    String? targetId,
  }) async {
    final key = effectKey(kind, discriminator);
    final origin = effectOrigin();
    if (key == null || origin == null) return;
    try {
      await messageEffects!.record(
        MessageEffect(
          id: const Uuid().v4(),
          profileId: profileId,
          companionId: companionId,
          messageId: origin.messageId,
          revisionId: origin.revisionId,
          kind: kind,
          targetId: targetId ?? key,
          operationKey: key,
          summary: summary,
          createdAt: widget.controller.now(),
        ),
      );
    } catch (_) {}
  }

  /// Texto para el modelo con lo ya aplicado por la respuesta a [messageId].
  Future<String> appliedEffectsSummary(String messageId) async =>
      await messageEffects?.appliedEffectsSummary(messageId) ?? '';
}

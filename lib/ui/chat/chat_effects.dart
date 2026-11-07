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
    EffectStatus status = EffectStatus.confirmed,
  }) async {
    final key = effectKey(kind, discriminator);
    final origin = effectOrigin();
    if (key == null || origin == null) return;
    try {
      final fresh = await messageEffects!.record(
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
          status: status,
        ),
      );
      // Ya había una fila con esa clave (propuesta, intento incierto o
      // fallido): pasa al nuevo estado en lugar de duplicarse.
      if (!fresh) {
        await messageEffects!.settle(key, status, summary: summary);
      }
    } catch (error) {
      // El registro de efectos no debe romper el chat, pero un fallo aquí
      // dejaría al asistente sin saber qué se aplicó: queda en el log.
      debugPrint('No se pudo registrar el efecto: ${error.runtimeType}');
    }
  }

  /// Anota que el asistente propuso algo que necesita la decisión del usuario.
  /// No cuenta como hecho hasta que [recordEffect] lo confirme.
  Future<void> proposeEffect(
    String kind,
    String discriminator,
    String summary, {
    String? targetId,
  }) => recordEffect(
    kind,
    discriminator,
    summary,
    targetId: targetId,
    status: EffectStatus.proposed,
  );

  /// Cierra una propuesta o un intento incierto: [EffectStatus.failed] si el
  /// usuario la rechazó o no se aplicó, [EffectStatus.uncertain] si no se sabe.
  Future<void> settleEffect(
    String kind,
    String discriminator,
    EffectStatus status,
  ) async {
    final key = effectKey(kind, discriminator);
    if (key == null) return;
    try {
      await messageEffects!.settle(key, status);
    } catch (error) {
      // El registro de efectos no debe romper el chat, pero un fallo aquí
      // dejaría al asistente sin saber qué se aplicó: queda en el log.
      debugPrint('No se pudo registrar el efecto: ${error.runtimeType}');
    }
  }

  /// Ejecuta una escritura local con el controlador y distingue «no se aplicó»
  /// de «no se sabe»: un error inesperado tras empezar a escribir, o después de
  /// escribir (al recargar), deja el resultado incierto.
  Future<({bool done, bool uncertain})> runTracked(
    Future<void> Function() write,
  ) async {
    var started = false;
    var rejected = false;
    final done = await widget.controller.run(() async {
      started = true;
      try {
        await write();
      } on ValidationException {
        rejected = true;
        rethrow;
      }
    });
    return (done: done, uncertain: !done && started && !rejected);
  }

  /// Texto para el modelo con lo ya aplicado por la respuesta a [messageId].
  Future<String> appliedEffectsSummary(String messageId) async =>
      await messageEffects?.appliedEffectsSummary(messageId) ?? '';

  /// Efectos ya confirmados de este mensaje que una nueva aplicación del mismo
  /// tipo y objetivo corregiría. Vacío sin registro durable.
  Future<List<MessageEffect>> correctableEffects(
    String kind,
    String targetId,
  ) async {
    final origin = effectOrigin();
    if (messageEffects == null || origin == null) return const [];
    try {
      return await messageEffects!.correctable(
        origin.messageId,
        kind,
        targetId: targetId,
      );
    } catch (_) {
      return const [];
    }
  }

  /// Anota la aplicación como corrección de [old]: conserva el efecto anterior
  /// como corregido con su antes/después. Si no se puede, lo anota como nuevo.
  Future<void> correctEffect(
    MessageEffect old,
    String kind,
    String discriminator,
    String summary, {
    required String targetId,
    required String before,
    required String after,
  }) async {
    final key = effectKey(kind, discriminator);
    final origin = effectOrigin();
    if (key == null || origin == null) return;
    try {
      final done = await messageEffects!.correct(
        old.id,
        MessageEffect(
          id: const Uuid().v4(),
          profileId: profileId,
          companionId: companionId,
          messageId: origin.messageId,
          revisionId: origin.revisionId,
          kind: kind,
          targetId: targetId,
          operationKey: key,
          summary: summary,
          createdAt: widget.controller.now(),
        ),
        before: before,
        after: after,
        at: widget.controller.now(),
      );
      if (!done) await recordEffect(kind, discriminator, summary, targetId: targetId);
    } catch (error) {
      // El registro de efectos no debe romper el chat, pero un fallo aquí
      // dejaría al asistente sin saber qué se aplicó: queda en el log.
      debugPrint('No se pudo registrar el efecto: ${error.runtimeType}');
    }
  }
}

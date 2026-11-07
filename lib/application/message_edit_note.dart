/// Nota de sistema que acompaña al envío de una versión editada de un mensaje,
/// para que el modelo sepa que el usuario cambió lo que escribió.
const _maxPreviousReply = 1500;

String buildEditNote({
  required ({int number, String text}) previous,
  required ({int number, String text}) current,
  String? previousReply,
  String effectsSummary = '',
}) {
  final reply = previousReply?.trim() ?? '';
  final shown = reply.length > _maxPreviousReply
      ? '${reply.substring(0, _maxPreviousReply)}… [respuesta truncada]'
      : reply;
  final effects = effectsSummary.trim();
  return [
    'NOTA DE EDICIÓN: el usuario ha editado un mensaje que ya habías visto. '
        'El último mensaje del usuario es la versión nueva y sustituye a la anterior.',
    'Versión ${previous.number} (anterior): «${previous.text}»',
    'Versión ${current.number} (nueva): «${current.text}»',
    if (shown.isNotEmpty)
      'Tu respuesta anterior a la versión ${previous.number}: «$shown»'
    else
      'No hay respuesta anterior tuya a la versión ${previous.number}.',
    if (effects.isNotEmpty)
      effects
    else
      'Efectos ya aplicados: ninguno registrado.',
    'Cómo actuar:\n'
        '1. Compara ambas versiones e identifica qué cambió. Tu respuesta debe '
        'EMPEZAR mencionando de forma explícita el cambio detectado, con las '
        'cifras o palabras concretas (por ejemplo: «Veo que cambiaste 60 kg '
        'por 70 kg»), y no responder como si el mensaje fuera nuevo.\n'
        '2. Si el cambio es ambiguo, o afecta a algo que ya se aplicó (efectos '
        'listados arriba), NO lo apliques directamente: describe en una o dos '
        'frases lo que cambió y pregunta al usuario qué prefiere, con opciones '
        'concretas (por ejemplo: «veo que cambiaste X por Y: ¿quieres que '
        'corrija el registro ya guardado o que lo deje y registre esto como '
        'nuevo?»).\n'
        '3. Si el cambio es claro y no choca con efectos ya aplicados, tras '
        'nombrar el cambio continúa con la nueva versión y resume brevemente '
        'qué hiciste con ella.\n'
        '4. Nunca repitas un efecto ya aplicado; si hay que corregirlo, '
        'propón la corrección.\n'
        '5. No cites esta nota ni sus etiquetas al usuario.',
  ].join('\n\n');
}

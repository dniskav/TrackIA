# Contratos de comportamiento

## Mensajes y efectos

La UI ofrece Editar a los mensajes propios y Reenviar a pendientes/fallidos/inciertos. Editar abre borrador con texto actual; cancelar no cambia nada. Confirmar crea revisión, sin borrar original. Si no hay efecto: enviar revisión y conservar respuestas anteriores. Si hay un efecto inequívoco y reversible: mostrar antes/después y confirmar; si hay varios, pedir elección. No ejecutar correcciones destructivas ni modificar Sheets por inferencia. Cada envío captura perfil/chat/versión y un ID de operación persistente; reconexión no cambia destino. La respuesta confirma solo operaciones con resultado real. Para solicitud con resultado incierto, consultar estado antes de reenviar efectos; si no hay forma de comprobar, mostrar incertidumbre y pedir decisión, sin duplicar automáticamente.

## Actividad

La IA propone cambios tipados de actividad identificada, revisión esperada y campos; la app valida y rechaza revisión obsoleta. Cambios de nombre, objetivo y descanso se aplican localmente y se informan tras guardar. Objetivo menor al progreso conserva ambos valores. Aviso en curso no se altera sin confirmación. Cambios ambiguos se preguntan; controles locales permanecen disponibles.

## Memoria

Propuesta estructurada contiene contenido, fuente y decisión `save|ask|ignore`; validar tamaño y ámbito. Petición explícita válida se guarda; `ask` solo se guarda con aceptación; `ignore` no se guarda. Relevancia es estimación, nunca promesa; mostrar y permitir corregir/borrar. La memoria no permite acciones ni sustituye instrucciones. La copia a Google requiere cuenta, alcance y confirmación; snapshot v1 sin secretos. Guardar compara revisión remota conocida, cargar previsualiza reemplazos/conflictos, borrar nube confirma cuenta y verifica respuesta; fallo incierto no declara éxito. Borrar local no borra nube ni viceversa. Respaldo restaurado jamás activa permisos ni acciones externas.

## Acuerdo de apoyo

La IA propone campos opcionales; el usuario acepta antes de crear o modificar. El motor local cuenta solo eventos confirmados, respeta pausa y no deduce conducta de reloj o dispositivo. Avisos indican configuración y resultado de permisos. No pedir acceso a otras apps en este incremento.

## Sheets e idiomas

Conexión → cuenta → selección de hoja → pestaña → previsualización → confirmar o cancelar; conservar destino anterior hasta confirmación. Las operaciones siguen las comprobaciones y permisos existentes. Idioma de interfaz `system|es|en|ar`; guardar preferencia, usar dirección RTL en árabe y no alterar texto de usuario. Prompts piden responder en idioma elegido sin imponer traducción al contenido original.

## Paquete de acompañante (US8)
Implementación: `lib/domain/companion_package.dart` (formato) y `lib/application/companion_package_import.dart` (vista previa); pruebas `test/companion_package_test.dart`, `test/companion_package_import_test.dart`, fixtures en `test/fixtures/companion_package_fixtures.dart`.

**Versión**: `format = "trackia-companion/1"`. Cualquier otro `trackia-companion/N` se rechaza como versión no soportada («actualiza TrackIA»); un valor que no sigue ese patrón se rechaza como «no es un paquete».

**Campos permitidos (lista cerrada; todos obligatorios salvo los marcados)**: `format`, `name`, `icon`, `color`, `description`, `instructions`, `mode`, `templates`, `reminders`, `checksum`.
- `name` (1–40, sin saltos de línea), `description` (0–80), `instructions` (0–4000; solo estilo), `icon` y `color` (ids de `Companion.iconIds` / `colorIds`), `mode` (`reminder`, `goals` o `game`).
- `templates`: hasta 5 plantillas de actividad. Cada una: `name` (1–80), `repeated`, `restSeconds`, `fields`, `instructions` (0–1500), `instant`; opcionales `activitySeconds`, `targetSets`, `targetCycles`, `segmentSingular`, `segmentPlural`. Los campos de la plantilla se validan con `ActivityDefinition` (hasta 12 campos, claves, tipos, opciones…).
- `reminders`: `{windowStart, lastCall, inactive}`, cada una con 0–5 textos de 1–140 caracteres (los textos de aviso del acompañante). Las tres vacías equivalen a «sin textos propios». No incluye horarios ni días: un paquete no activa avisos.

**Campos prohibidos**: cualquier otra clave, a cualquier nivel, se rechaza (`forbiddenField` para nombres como `apiKey`, `token`, `chats`, `messages`, `memory`, `sheetId`, `accountId`, `id`, `companionId`, `settings`, `permissions`…; `unknownField` para el resto). En concreto nunca viajan: claves de IA, chats, memoria, hoja de Google, cuentas, identificadores locales (id del acompañante, `companionId`, `activityKey`), origen, bloqueos del usuario (`userSet`), progreso (`completedCycles`), metas, logros, ajustes, permisos ni datos de uso. El exportador construye el paquete solo desde la lista permitida; no copia el objeto de origen.

**Límites de tamaño** (razonados con el máximo real del creador: nombre 40, descripción 80, instrucciones 4000): JSON expandido máx. 64 KiB; gzip máx. 32 KiB; texto base64url máx. 43 695 caracteres; caracteres de control (salvo salto de línea y tabulación en textos largos) rechazados. En el peor caso del creador (instrucciones 4000 + 5 plantillas con 1500 + 15 avisos de 140, hasta 4 bytes por carácter) el JSON ronda 55 KiB, por debajo del tope. La descompresión se corta en cuanto el resultado supera 64 KiB (nunca se expande sin límite) y se comprueba la longitud declarada en el pie del gzip. Un QR se ofrece solo si el texto mide ≤ 2000 caracteres (`CompanionPackage.fitsInQr`); si no, solo archivo.

**Codificación**: JSON canónico (claves ordenadas en todos los niveles, sin espacios, UTF-8, sin escapar Unicode) → gzip → base64url sin relleno (al decodificar se acepta con o sin relleno y con espacios alrededor). El archivo `.trackia` contiene ese mismo texto (el lector acepta también el gzip crudo).

**`checksum`**: sha256 en hexadecimal minúscula (64 caracteres) de la forma canónica del objeto sin `checksum` y con `format` incluido. Detecta daños y ediciones accidentales; no es una firma (quien edite el paquete puede recalcularlo), por eso la importación nunca confía en el contenido.

**Orden de validación al decodificar**: vacío → tamaño del texto → base64url → tamaño comprimido → gzip (con tope) → UTF-8 → JSON objeto → `format`/versión → claves (prohibidas, desconocidas, faltantes) → `checksum` → tipos y límites de cada campo.

**Errores** (`CompanionPackageException.problem`): `empty`, `tooLarge`, `badEncoding`, `badCompression`, `tooLargeExpanded`, `malformed`, `notAPackage`, `unsupportedVersion`, `checksumMismatch`, `forbiddenField`, `unknownField`, `missingField`, `invalidField`; el mensaje interno va en español y la UI lo localiza por `problem`.

**Al importar** (`CompanionPackageImport.preview`): no escribe nada ni recibe almacenes. Devuelve un borrador editable con: identidad nueva (`companionIdFor(name, idsOcupados)`), `external = true`, `origin = 'external'`, modo siempre `reminder` (el modo declarado queda en `declaredMode` y se avisa; la persona lo sube a mano), sin metas ni horarios de aviso, bloques ```` ```trackia-* ````/```` ```gymia-* ```` (con o sin espacio tras las comillas, cerrados o no, repetido hasta que no quede ninguno) retirados de las instrucciones y de las plantillas, y la lista de advertencias (`appBlocksRemoved`, `modeReset`, `extraTemplatesNotApplied`, `suspiciousInstructions`, `instructionsEmpty`). El borrador lleva la primera plantilla; las demás se listan en la vista previa. Las instrucciones son solo estilo y nunca autorizan acciones.

# Research: TrackIA — experiencia, actividades abiertas y juego opcional

Cada decisión fija una opción para que la implementación no tenga que elegir. Si una
suposición resulta falsa al implementar, se registra como bloqueo en `tasks.md`.

## D1 · Avisos que suenan con No molestar

**Decisión**: crear el canal `trackia_timer_alarm_v1` («Fin de descanso y tramo») con
`IMPORTANCE_HIGH`, vibración, sonido `RingtoneManager.TYPE_ALARM` y `AudioAttributes`
`USAGE_ALARM` + `CONTENT_TYPE_SONIFICATION`; publicar con `Notification.CATEGORY_ALARM`.
Usarlo para fin de descanso y fin de tramo cuando la preferencia nativa `alarmStyle` es
`true` (valor inicial). El resto sigue en `gymia_rest`. Exponer en el método `status` el
filtro actual (`NotificationManager.getCurrentInterruptionFilter()`) y si el canal de alarma
está bloqueado.

**Rationale**: en No molestar modo Prioridad, Android permite por defecto los sonidos de
alarma; los avisos de importancia alta normales se silencian. Los ajustes de un canal no se
pueden cambiar tras crearlo, por eso se crea un canal nuevo con otro ID.

**Alternativas descartadas**:
- `setBypassDnd(true)`: solo surte efecto si el usuario concede acceso a la política de
  No molestar o lo activa en el canal; no es fiable por sí solo. Se ofrece como acceso a los
  ajustes del canal, no como solución.
- `setFullScreenIntent` o `AlarmManager.setAlarmClock`: interrumpen demasiado para un descanso
  y exigen permisos adicionales en Android 14+.
- Cambiar `gymia_rest`: imposible sin borrar el canal, lo que pierde la configuración del usuario.

**Límite conocido**: en «Silencio total» Android bloquea también las alarmas. Los fabricantes
pueden añadir reglas propias: se valida en el teléfono del propietario (`[OWNER]`).

## D2 · Ritmo de la actividad

**Decisión**: el ritmo se deriva y no se guarda:

| Ritmo | Regla |
|---|---|
| Puntual | No es una `ActivityDefinition`: se guarda como observación (`observation_repository`, 003 T007) con `runId = null` |
| Libre | `repeated == false` y `activitySeconds == null` |
| Con duración | `repeated == false` y `activitySeconds != null` |
| Por tramos | `repeated == true` (con `targetSets`/`targetCycles`, `restSeconds`, `activitySeconds` opcionales) |

**Rationale**: evita estados contradictorios entre un campo `rhythm` y los tiempos.
`activities.workout_id` es `NOT NULL` y todo pasa por tramos, así que forzar lo puntual en ese
modelo exigiría crear entrenos y tramos ficticios, lo que viola la constitución IV.

**Alternativa descartada**: actividad terminada al instante con cero tramos (crea un entreno
artificial por cada vaso de agua).

## D3 · Campos con tipo y forma de contar

**Decisión**: ampliar cada mapa de campo de `ActivityDefinition.fields` con claves opcionales:
`type` (`number`, `text`, `boolean`, `choice`, `scale`), `aggregate` (ver tabla), `options`
(lista, solo `choice`), `min` y `max` (enteros, solo `scale`, por defecto 1 y 5). El valor
`scale` existe solo en este mapa; en `lib/domain/activity_definition.dart` equivale a
`FieldType.number` con límites. Un campo sin `type` es heredado y vale «solo notas».

| type | aggregate permitidos | por defecto |
|---|---|---|
| number | `sum`, `max`, `avg`, `none` | `sum` |
| scale | `avg`, `none` | `avg` |
| text | `distinct`, `none` | `none` |
| choice | `distinct`, `none` | `distinct` |
| boolean | `countTrue`, `none` | `countTrue` |

**Rationale**: compatibilidad total con las definiciones guardadas y con el validador de
`interpretActivityMessage`, que ya acepta número, booleano y texto.

**Alternativa descartada**: migrar a `TrackiaActivityDefinition` de 003 ahora; supone el motor
nuevo de 003 completo.

## D4 · Candados por campo

**Decisión**: clave opcional `userSet` en la definición: lista de nombres de propiedad
(`name`, `restSeconds`, `activitySeconds`, `targetSets`, `targetCycles`, `segmentSingular`,
`segmentPlural`, `instructions`) o `field:<key>` para un campo. Toda edición desde la UI añade
la propiedad; tocar el candado la quita. Una propuesta (`gymia-activity`, `gymia-timing` o
`trackia-*`) que cambia una propiedad de `userSet` se convierte en tarjeta Aplicar/Ignorar.

## D5 · Nombre del tramo

**Decisión**: claves opcionales `segmentSingular` y `segmentPlural` (1–24 caracteres). Si faltan,
se mantiene la regla actual (`gymbro` → serie/series; resto → tramo/tramos).

Plantillas rápidas del constructor (valores exactos; el usuario puede cambiarlos antes de guardar):

| Plantilla | Ritmo y tiempos | Tramo | Campos (`key` · etiqueta · tipo · forma de contar · unidad) |
|---|---|---|---|
| Fútbol | Por tramos · `targetSets` 2 · `activitySeconds` 1500 · `restSeconds` 300 | tiempo/tiempos | `goals` · Goles · number · sum · — ; `assists` · Asistencias · number · sum · — |
| Yoga | Con duración · `activitySeconds` 3600 | — | `intensity` · Intensidad · scale 1–5 · avg · — |
| Pomodoro | Por tramos · `targetCycles` 4 · `activitySeconds` 1500 · `restSeconds` 300 | pomodoro/pomodoros | `task` · Tarea · text · none · — |
| Series | Por tramos · `targetSets` 4 · `restSeconds` 90 | serie/series | `weight` · Peso · number · max · kg ; `reps` · Repeticiones · number · sum · — |
| Correr | Libre | — | `distance` · Distancia · number · sum · km |
| Leer | Libre | — | `pages` · Páginas · number · sum · páginas ; `book` · Libro · text · distinct · — (`countSingular` libro, `countPlural` libros) |

## D6 · Dónde guardar lo nuevo

**Decisión**: migración v6 aditiva con siete tablas (ver `data-model.md`). Icono y color del
acompañante se añaden al JSON de `Companion` (pocos bytes) y se mueven con el resto de
acompañantes si US9 decide moverlos (no en esta entrega).

## D7 · Evaluador determinista

**Decisión**: `lib/application/progress_engine.dart` con funciones puras:
`evaluate(rules, records, now, timeZone) → ProgressSnapshot`. Sin E/S, sin `DateTime.now()`
interno, sin IA. `progress_service.dart` lee registros, llama al motor y guarda desbloqueos en
una transacción. Se ejecuta al guardar un valor, al parar un tramo y al terminar una actividad.

**Rationale**: comprobable con pruebas de propiedad; constitución II.

## D8 · Recordatorios nativos sin abrir SQLite

**Decisión**: Flutter escribe en SharedPreferences (archivo `trackia_reminders`) una instantánea
JSON por perfil con, por recordatorio: `id`, `companionId`, `companionName`, `days` (máscara L–D),
`windowStartMin`, `windowEndMin`, `lastCallMin`, `tone`, `templates`, `minimumText`,
`lastDoneDate`, `weekId`, `weekCount`, `weekTarget`, `streak`, `paused`. El receptor nativo
programa dos alarmas inexactas diarias por recordatorio (`AlarmManager.setWindow`, ventana
de 10 min), y al dispararse comprueba `lastDoneDate == hoy` (no publica), rellena marcadores
y publica en `trackia_reminders_v1`. `BootReceiver` reprograma tras reiniciar. Flutter
actualiza la instantánea al guardar, terminar, cambiar ajustes y al abrir la app.

**Alternativas descartadas**: WorkManager con motor Dart (dependencia y consumo); textos de la IA
generados en el momento (requiere red y viola FR-029).

## D9 · Bloques de la IA

**Decisión**: cuatro bloques nuevos con prefijo `trackia-`, cada uno con esquema cerrado
(`contracts/assistant-blocks.md`). Un bloque con claves desconocidas, tipos incorrectos o valores
fuera de rango se rechaza completo y se muestra «La propuesta no es válida» sin efectos.
El prompt del sistema se amplía en `assistant_context.dart` con la descripción de los bloques
solo cuando la pantalla los admite (creación de acompañante, chat en modo Juego).

## D10 · Identidad visual

**Decisión**: colores muestreados del PNG del icono (`assets/branding/trackia-icon-master.png`):
teal `#027D92`, naranja `#FE6101`, rojo `#F52C1F`, carmín `#DC0148`. Contrastes calculados con la
fórmula WCAG y fijados en `contracts/visual-tokens.md`. Botón principal: Iniciar teal y Parar
carmín, ambos con texto blanco en negrita; el naranja queda para el anillo y el progreso, porque
el texto negro sobre naranja vivo cansa aunque pase el contraste (5,86) y el blanco no llega (3,03).
Logo y anillo con `CustomPainter` (sin `flutter_svg` ni imágenes nuevas).

## D11 · User-Agent

**Decisión**: `lib/data/app_info.dart` con `const trackiaAppName = 'TrackIA';` y
`const trackiaVersion = '<versión de pubspec sin +build>';` y `String get trackiaUserAgent`.
Una prueba lee `pubspec.yaml` y falla si la versión no coincide. Sin `package_info_plus`.

## D12 · Chats fuera de secure storage

**Decisión**: tablas `trackia_chats` (una fila por perfil y acompañante con el JSON actual del
chat sin adjuntos) y `trackia_chat_archives` (una fila por archivo). Los bytes de adjuntos van a
`<applicationSupportDirectory>/trackia_media/<sha256>` y el JSON guarda la referencia.
Migración en dos fases idempotentes: (1) copiar a SQLite y archivos, verificar conteo de mensajes
y hash de adjuntos, marcar `migrated_at`; (2) en el siguiente arranque, si la fila está verificada,
borrar la clave antigua. Mientras la fase 2 no ocurre, la lectura prefiere SQLite y cae a la clave
antigua si falta la fila.

**Alternativa descartada**: guardar adjuntos como BLOB en SQLite (crece la copia de seguridad y la BD).

## D13 · Bienvenida

**Decisión**: la casilla «No volver a mostrar» aparece marcada en la entrada automática; Omitir y
Empezar confirman `autoShow = !casilla` como hoy. Resultado: tras la primera vez no se repite salvo
que el usuario la desmarque. La entrada manual (Ajustes → Ayuda) no cambia. Se anota la enmienda en
`specs/003-trackia-platform/contracts/welcome.md`.

## D14 · Rachas, días libres y mínimo

**Decisión**: un día está «cumplido» si alcanza la meta diaria o el mínimo; sin meta, si tiene al
menos un registro. La racha cuenta días cumplidos consecutivos hacia atrás desde ayer (y hoy si ya
está cumplido). Dentro de cada semana ISO (lunes a domingo) se toleran `freeDaysPerWeek` días no
cumplidos (por defecto 1) que no suman ni rompen. El siguiente día no cumplido de esa semana
rompe la racha. Hoy no cumplido nunca rompe hasta que termina el día.

## D15 · Sugerencia de juego

**Decisión**: la detecta la app (sin IA): acompañante en modo Recordatorio con 5 días cumplidos
seguidos. Se muestra como tarjeta en el chat con texto fijo; como máximo una vez por acompañante
y motivo; «No volver a sugerir» se guarda en los ajustes del acompañante.

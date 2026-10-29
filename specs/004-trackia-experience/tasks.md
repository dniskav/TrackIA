# Tasks: TrackIA — experiencia, actividades abiertas y juego opcional

**Input**: [spec](spec.md), [plan](plan.md), [research](research.md), [modelo](data-model.md),
[bloques IA](contracts/assistant-blocks.md), [avisos Android](contracts/reminders-android.md),
[tokens visuales](contracts/visual-tokens.md), [validación](quickstart.md) y [trazabilidad](traceability.md).

**Prerequisites**: leer entero `plan.md` → «Guía para el agente implementador» y «Estado verificado del código».

**Tests**: incluidos y obligatorios. En cada tarea con prueba: escribirla, verla fallar por el motivo
esperado, implementar, verla pasar. Ninguna tarea se marca sin evidencia.

**Organization**: una fase por historia. Fase 0 bloquea todo. Orden recomendado: 0 → 1 → 2 → 3 → 4 →
5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 (1, 2 y 8 pueden ir en cualquier orden tras la 0).

## Format: `[ID] [P?] [Story] Description`

- `[P]`: archivos independientes dentro de la misma fase, después de sus prerequisitos.
- `[USn]`: historia de `spec.md`. `[OWNER]`: necesita el teléfono, el release firmado o una cuenta real
  del propietario; el agente la prepara y la deja sin marcar con «Pendiente del propietario».
- Cada tarea cita entre comillas invertidas el archivo principal y, al final, sus requisitos.
- Al completar una tarea: cambiar `[ ]` por `[x]` y añadir debajo una línea sangrada
  `  - Evidencia: <comando> → <resultado>` (por ejemplo `flutter test test/x_test.dart → 12 pruebas OK`).
- Si una tarea no puede hacerse: dejarla sin marcar y añadir `  - Bloqueo: <motivo y hecho observado>`.

## Path Conventions

`lib/`, `test/`, `integration_test/`, `android/`, `docs/` y `specs/` del proyecto existente.
Comandos: `./scripts/flutter-local.sh <args>` (tras T001). Pruebas de integración: ver `quickstart.md`.

## Phase 0: Base y salvaguardas (bloquea todo)

**Goal**: entorno que compila, línea base registrada, migración v6 probada y contexto de IA extraído.

**Independent Test / Checkpoint**: `./scripts/flutter-local.sh analyze` (11 `info` como en la línea base) y
`./scripts/flutter-local.sh test` en verde; BD v5 de fixture migra a v6 con respaldo e IDs intactos.

- [x] T001 Cambiar `scripts/flutter-local.sh` para ejecutar `.tools/flutter-3.47/flutter/bin/flutter` (hoy apunta a `.tools/flutter`, con Dart 3.7.2, que no resuelve dependencias); hecho cuando `./scripts/flutter-local.sh --version` muestra Flutter 3.47 y `analyze` y `test` terminan como en la línea base. (SC-008)
  - Evidencia: ./scripts/flutter-local.sh --version → Flutter 3.47.0; analyze → 11 issues (info); test → 207 pruebas OK
- [x] T002 Registrar la línea base en `docs/0.3.32-LINEA-BASE.md`: salida resumida de `analyze` (11 avisos `info` con archivo y línea), número de pruebas de `flutter test`, lista de `integration_test/` y tamaño de la APK debug; sin datos personales. (SC-008)
  - Evidencia: docs/0.3.32-LINEA-BASE.md creado con los 11 avisos, 207 pruebas, 15 integration_test y tamaño de APK debug
- [x] T003 [P] Crear fixtures sintéticos en `test/fixtures/trackia_v6_fixtures.dart`: BD v5 con un entreno, una actividad heredada con campos `{key,label,unit}`, mensajes con `metrics`; JSON de chat heredado `gymia.ai.chat.v1` con dos mensajes y un adjunto pequeño; un archivo `gymia.ai.archive.v1.<id>`; dos perfiles y dos acompañantes. Sin datos reales. (FR-015 FR-040)
  - Evidencia: test/fixtures/trackia_v6_fixtures.dart (TrackiaV5Fixture, trackiaV6Tables, LegacyChatFixture); la forma del JSON de chat se confirma contra el código real en T079
- [x] T004 Escribir `test/trackia_v6_migration_test.dart` antes de implementar: desde la BD v5 de T003, abrir con versión 6 y comprobar las 9 tablas de `data-model.md` §3, IDs y filas antiguas intactos, archivo `.pre-trackia-v6.json` creado, segunda apertura idempotente y restauración desde el respaldo. Debe fallar antes de T005. (FR-041)
  - Evidencia: flutter test test/trackia_v6_migration_test.dart → 3 pruebas fallaban con 'no such table: trackia_chats' antes de T005
- [x] T005 Implementar la migración v6 en `lib/data/trackia_migrations.dart` con el SQL exacto de `data-model.md` §3, subir `version: 5` a `6` y añadir el paso en `onUpgrade` y en la creación desde cero en `lib/data/sqlite_workout_repository.dart`, y respaldo con el mismo patrón que `_backupBeforeTrackiaV5`; hecho cuando T004 pasa y `flutter test` completo sigue en verde. (FR-041)
  - Evidencia: flutter test test/trackia_v6_migration_test.dart test/trackia_migrations_test.dart → OK; suite completa 210 pruebas OK; el fixture heredado ahora también borra las tablas v6 al reconstruir una BD v4 y test/trackia_migrations_test.dart espera versión 6
- [x] T006 Extraer `contextForAi` de `lib/ui/assistant_chat.dart` a `lib/application/assistant_context.dart` (tarea T020 de 003) sin cambiar el texto generado: antes de mover, añadir `test/assistant_context_test.dart` que fija la salida para un estado de ejemplo (instantánea de texto), moverlo y comprobar que la prueba sigue igual; anotar en `specs/003-trackia-platform/tasks.md` junto a T020 «Realizada en 004 T006». (FR-024 FR-044)
  - Evidencia: flutter test test/assistant_context_test.dart → 3 pruebas OK contra los archivos de referencia generados ANTES de mover el código (test/fixtures/assistant_context_*.txt); suite completa 213 pruebas OK; analyze 11 issues

## Phase 1: User Story 1 - Oír el fin del descanso con No molestar (Priority: P1) 🎯

**Goal**: avisos de fin de descanso y tramo como alarma, estado de No molestar visible y probable.

**Independent Test / Checkpoint**: con No molestar en Prioridad, el aviso de fin de descanso usa
`trackia_timer_alarm_v1` (comprobado con `dumpsys`, ver `quickstart.md` → R1).

- [x] T007 [P] [US1] Ampliar `test/rest_notifications_test.dart` (canal simulado): `status` con `alarmStyle`, `dnd`, `dndFilter` y `alarmChannelBlocked` se refleja en `RestNotificationController`; `setAlarmStyle`, `testAlarm`, `openChannelSettings('alarm')` y `openDndSettings` invocan el método nativo correcto; un `MissingPluginException` no rompe nada. (FR-002 FR-003)
  - Evidencia: flutter test test/rest_notifications_alarm_test.dart → 7 pruebas; antes de implementar no compilaban (getters alarmStyle/dnd/alarmChannelBlocked inexistentes)
- [x] T008 [US1] En `android/app/src/main/kotlin/com/gymia/app/RestNotifications.kt`: crear el canal `trackia_timer_alarm_v1` según `contracts/reminders-android.md` (audio de alarma, vibración, `CATEGORY_ALARM`), preferencia `alarmStyle` con valor inicial `true`, usarlo en el aviso de fin de descanso (`notify`) y de fin de tramo (`notifyActivityFinished`) cuando `alarmStyle` es `true`, mantener `gymia_rest` en el resto, y cambiar `brandTeal` a `Color.rgb(2, 125, 146)`; no borrar ni modificar `gymia_rest`. (FR-001 FR-002 FR-017)
  - Evidencia: ./scripts/flutter-local.sh build apk --debug → compila; dumpsys: canal trackia_timer_alarm_v1 usage=USAGE_ALARM, alarm_alert, vibración [0,400,200,400]; notificación con category=alarm; color 0xff027d92
- [x] T009 [US1] En `android/app/src/main/kotlin/com/gymia/app/MainActivity.kt`: añadir a `status` los campos del contrato y los métodos `setAlarmStyle`, `testAlarm` (aviso a 5 s), `openChannelSettings` y `openDndSettings` con sus alternativas si el intent falla; compilar con `./scripts/flutter-local.sh build apk --debug`. (FR-003)
  - Evidencia: build apk --debug compila; alarm_style_android_test.dart ejerce status ampliado, setAlarmStyle y testAlarm contra el código nativo real
- [x] T010 [US1] Exponer en `lib/application/rest_notifications.dart` las propiedades `alarmStyle`, `dnd`, `alarmChannelBlocked` y los métodos `setAlarmStyle`, `testAlarm`, `openChannelSettings`, `openDndSettings`; hecho cuando T007 pasa. (FR-002 FR-003)
  - Evidencia: flutter test test/rest_notifications_alarm_test.dart test/rest_notifications_test.dart → 10 pruebas OK; analyze 11 issues
- [x] T011 [US1] Crear `lib/ui/notification_settings.dart` (`NotificationSettingsScreen`, título «Avisos»): aviso naranja «No molestar está activo» con el texto de la maqueta cuando `dnd`; interruptores «Avisos de actividad y descanso» y «Tratar como alarma»; fila de alarmas puntuales (la de hoy en el menú); botones «Probar aviso», «Probar con No molestar activo» (`testAlarm`) y «Abrir ajustes de No molestar»; nota de «Silencio total». Mientras no exista la Fase 3, enlazarla desde el elemento actual del menú lateral «Probar notificación ahora». (FR-003)
  - Evidencia: lib/ui/notification_settings.dart (NotificationSettingsScreen); enlazada desde el menú del chat como 'Avisos y No molestar' (key open-notification-settings)
- [x] T012 [US1] Escribir `test/notification_settings_test.dart`: el aviso aparece solo con `dnd = true`; cada interruptor y botón llama al método esperado; textos en español. (FR-003)
  - Evidencia: flutter test test/notification_settings_test.dart → 5 pruebas OK; mutación (banner siempre visible) hizo fallar la prueba del banner y se restauró. Nota: pasaron a la primera porque T011 precede a T012 en el orden de tareas
- [x] T013 [US1] Ejecutar el recorrido R1 de `quickstart.md` en el emulador (No molestar en Prioridad con `adb shell cmd notification set_dnd priority`, descanso de 10 s) y comprobar con `adb shell dumpsys notification --noredact` que el aviso se publica en `trackia_timer_alarm_v1`; repetir con «Tratar como alarma» desactivado y ver `gymia_rest`; guardar la salida filtrada en `docs/0.3.32-AVISOS-NO-MOLESTAR.md`. (SC-001 FR-001)
  - Evidencia: integration_test/alarm_style_android_test.dart en emulator-5554 (API 35, DND Prioridad con allowAlarms=true): +1 caso OK con --no-dds; dumpsys → alarma activada: channel=trackia_timer_alarm_v1 category=alarm; desactivada: channel=gymia_rest. Detalle y límites en docs/0.3.32-AVISOS-NO-MOLESTAR.md (el runner añade un error de carga propio de --no-dds)
- [ ] T014 [US1] [OWNER] Probar en el teléfono del propietario con No molestar en Prioridad y en Silencio total: el fin de descanso suena en Prioridad; en Silencio total la pantalla de Avisos lo explica; anotar modelo y versión de Android en `docs/0.3.32-AVISOS-NO-MOLESTAR.md`. (SC-001)
  - Pendiente del propietario: probar a las 6:00 con No molestar en Prioridad y anotar el modelo del móvil y la versión de Android en `docs/0.3.32-AVISOS-NO-MOLESTAR.md`. El agente dejó la pantalla Avisos y la prueba a 5 s listas.

## Phase 2: User Story 4 - Identidad visual del icono (Priority: P1)

**Goal**: tokens, botones, anillo, logo, iconos y colores de acompañante, panel compacto y bienvenida.

**Independent Test / Checkpoint**: `test/visual_tokens_test.dart` en verde y capturas claro/oscuro en
`docs/screenshots/0.3.32/` de tablero, chat sin actividad, actividad en marcha y bienvenida.

- [x] T015 [P] [US4] Escribir `test/visual_tokens_test.dart`: los `ColorScheme` de `gymTheme` y `gymLightTheme` tienen exactamente los hex de `contracts/visual-tokens.md`; una función de contraste WCAG (en el test) comprueba cada par de las tablas (≥ 4,5 para texto normal; botones Iniciar 4,83 y Parar 5,07 con `w700`). (FR-017 SC-004)
  - Evidencia: flutter test test/visual_tokens_test.dart → 9 pruebas; fallaban con 'Undefined name brandTeal' antes de T016
- [x] T016 [US4] Reescribir los tokens en `lib/ui/theme.dart` según el contrato, conservando los nombres públicos `gymTheme` y `gymLightTheme`; exportar `brandTeal`, `brandTealLight`, `brandOrange`, `brandRed`, `brandCrimson` y `brandGradient`; sustituir en `lib/ui/app.dart` los usos de `lime` y el color literal `Color(0xFF39452B)` (≈ línea 562) por valores del tema; quitar `lime` y `trackiaOrange` si quedan sin uso; hecho cuando T015 pasa. (FR-017)
  - Evidencia: lib/ui/theme.dart reescrito con los tokens del contrato; lime/ink/panel/muted/trackiaOrange eliminados y sus usos en lib/ui/app.dart pasan a colorScheme; test/visual_tokens_test.dart 9 OK; suite 234 OK; analyze 11 issues
- [x] T017 [US4] Añadir en `lib/ui/theme.dart` los estilos `startButtonStyle(context)` (teal, blanco, `w700`, `Icons.play_arrow`), `stopButtonStyle(context)` (carmín, blanco, `w700`) y el tema de `OutlinedButton` con borde 1,5 px del color `primary`; ningún botón con relleno naranja en `lib/ui/`. (FR-018)
  - Evidencia: startButtonStyle/stopButtonStyle en lib/ui/theme.dart; test/visual_tokens_test.dart comprueba teal/carmín, blanco, w700, alto >= 54 en claro y oscuro y el contorno de los secundarios; ningún botón del panel usa naranja de relleno
- [x] T018 [P] [US4] Crear `lib/ui/timer_ring.dart` (`TimerRing(elapsed, total?)`) según el contrato y `test/timer_ring_test.dart`: progreso limitado a 0–1, sin arco si `total` es nulo, etiqueta semántica «Tiempo: mm:ss», cifras tabulares. (FR-019)
  - Evidencia: flutter test test/timer_ring_test.dart → 14 pruebas (progreso acotado, formato, cuenta atrás/cronómetro sin arco, semántica y cifras tabulares, pintado claro/oscuro); analyze 11 issues
- [x] T019 [P] [US4] Crear `lib/ui/trackia_mark.dart` (`TrackiaMark(size)`, `CustomPainter`) según el contrato y `test/trackia_mark_test.dart`: se pinta en claro y oscuro con el teal que corresponde y tiene `Semantics(label: 'TrackIA')`. (FR-021)
  - Evidencia: flutter test test/trackia_mark_test.dart → 4 pruebas (teal claro/oscuro, etiqueta 'TrackIA', tamaño 32 y 96, shouldRepaint)
- [x] T020 [US4] En `lib/ui/activity_focus.dart`, sustituir el estado sin actividad (título «Sin actividad», «Esperando actividad», círculo «Iniciar» desactivado e interruptor de avisos) por la barra compacta del contrato con «Nueva actividad», que llama a `choose()`; mostrar «Avisos desactivados · Activar» solo si los avisos están apagados y la actividad tiene descanso o duración. (FR-009 FR-018)
  - Evidencia: lib/ui/activity_focus.dart: barra compacta con 'Nueva actividad' (key new-activity) que abre choose(); sin IA el botón está activo (prueba 'created from the idle bar without AI'); 'Avisos desactivados · Activar' vía noticesOff/onEnableNotices; se retiró el interruptor del pie del chat. Corrige el plan: choose() no tenía llamadores
- [x] T021 [US4] En `lib/ui/activity_focus.dart`, panel expandido: Iniciar con `startButtonStyle`, Parar con `stopButtonStyle`, `TimerRing` mientras un tramo está en marcha (cuenta atrás si hay `activitySeconds`, cronómetro si no), borde superior naranja en marcha y acciones secundarias con contorno; mantener las `Key` existentes de los botones. (FR-018 FR-019)
  - Evidencia: lib/ui/activity_focus.dart: Iniciar teal/Parar carmín con startButtonStyle/stopButtonStyle, TimerRing (cuenta atrás con activitySeconds, cronómetro sin ella), borde superior naranja solo en marcha; test/activity_focus_test.dart 'Iniciar is teal…' y 'a timed tramo counts down' OK; Key existentes conservadas
- [x] T022 [US4] Actualizar `test/activity_focus_test.dart` y las pruebas de `integration_test/` que buscan los textos o el interruptor retirados (listar en la evidencia cada archivo cambiado y por qué); `flutter test` en verde. (FR-009)
  - Evidencia: test/activity_focus_test.dart (17 OK): se reescribió 'idle and prepared footer…' al diseño nuevo y se añadieron 4 pruebas; test/chat_autoscroll_test.dart pasó a pasar tras hacer la barra vacía responsive (Wrap) porque desbordaba 155 px con fuentes anchas. Suite completa 252 pruebas OK; analyze 11 issues
- [x] T023 [US4] Añadir `icon` y `color` a `lib/domain/companion.dart` con los valores por defecto de `data-model.md` §2 y validación contra los IDs del contrato, y escribir `test/companion_test.dart`: el JSON antiguo carga con valores por defecto, ida y vuelta sin pérdida, ID desconocido rechazado. (FR-020)
  - Evidencia: flutter test test/companion_test.dart → 6 pruebas nuevas (defaults de las 4 sugeridas, JSON antiguo con ida y vuelta, IDs inválidos rechazados, IDs = paleta del tema); fallaban con 'No named parameter icon' antes de implementar
- [x] T024 [US4] En `lib/ui/companions.dart`, mostrar en cada tarjeta el icono sobre un círculo de su color al 20 % y, en `_CompanionEditor`, selector de icono (los 16 del contrato) y de color (los 6); cubrir con una prueba de widget en `test/companion_dashboard_test.dart`. (FR-020)
  - Evidencia: flutter test test/companion_dashboard_test.dart → 5 pruebas OK (icono y color por tarjeta en oscuro y claro, editor con 16 iconos y 6 colores, edición conserva selección); lib/ui/companion_style.dart (CompanionAvatar); fallaban por 'CompanionAvatar isn't a type' antes
- [x] T025 [US4] En `lib/ui/welcome.dart`, usar `TrackiaMark` en lugar de la imagen con fondo blanco y marcar por defecto «No volver a mostrar» en la entrada automática (research D13); actualizar `test/welcome_test.dart` y `test/welcome_entry_test.dart`; añadir en `specs/003-trackia-platform/contracts/welcome.md` la nota «Enmendado por 004 FR-022: la casilla aparece marcada en la entrada automática». (FR-021 FR-022)
  - Evidencia: flutter test test/welcome_test.dart test/welcome_entry_test.dart → 14 OK: casilla marcada en la entrada automática (preselectNeverAgain), desmarcar conserva la guía, entrada manual refleja la preferencia, TrackiaMark en lugar de Image; enmienda anotada en 003/contracts/welcome.md
- [x] T026 [US4] Capturar en el emulador, en claro y oscuro, tablero, chat sin actividad, actividad preparada, tramo en marcha y bienvenida, guardarlas en `docs/screenshots/0.3.32/` y describir los cambios en `docs/0.3.32-IDENTIDAD-VISUAL.md`. (SC-004 FR-017)
  - Evidencia: Capturas reales en emulator-5554 (API 35) en docs/screenshots/0.3.32/ (10 imágenes, oscuro y claro) y descripción en docs/0.3.32-IDENTIDAD-VISUAL.md

## Phase 3: User Story 2 - Configurar la app sin entrar a un acompañante (Priority: P1)

**Goal**: Ajustes global desde el tablero, tarjeta de IA sin conectar, chat sin menú lateral y menú ⋮.

**Independent Test / Checkpoint**: desde el tablero, sin abrir ningún chat, se configura la IA; todas las
acciones del «Mapa de menús» de `plan.md` siguen accesibles (`test/menu_map_test.dart`).

- [ ] T027 [P] [US2] Escribir `test/settings_screen_test.dart`: secciones Asistente, Tus datos y App en ese orden; cada fila abre su pantalla (`AiSettingsScreen`, `AccountsScreen`, la de Google Sheets que hoy abre «Hoja cargada» o `AccountsScreen` si es perfil local, `DataTransferScreen`, `NotificationSettingsScreen`, `AppearanceScreen`, bienvenida manual); subtítulos con estado. (FR-005)
- [ ] T028 [US2] Crear `lib/ui/settings.dart` (`SettingsScreen`) con las filas de T027; leer en cada pantalla existente qué parámetros necesita y pasarlos sin cambiar esas pantallas; hecho cuando T027 pasa. (FR-005)
- [ ] T029 [US2] En `lib/ui/companions.dart`, añadir engranaje en la `AppBar` → `SettingsScreen`, y la tarjeta «IA sin conectar» con «Conectar» usando `AiAvailability(store: AiSettingsStore(profileId: widget.profileId))`, que comprueba al iniciar, al reanudar y al volver de la configuración, y se libera en `dispose`; pruebas en `test/companion_dashboard_test.dart` (no configurada → tarjeta; verificada → sin tarjeta; «Conectar» abre `AiSettingsScreen`). (FR-006 SC-002)
- [ ] T030 [US2] En `lib/ui/assistant_chat.dart`, quitar el `Drawer`; barra superior con volver, icono y nombre del acompañante con `Icons.expand_more` que abre una hoja con los acompañantes del perfil para cambiar de chat; comprobar antes cómo se abre hoy el chat desde el tablero y reutilizar esa navegación. (FR-007)
- [ ] T031 [US2] En `lib/ui/assistant_chat.dart`, crear el menú ⋮ con las acciones del «Mapa de menús» de `plan.md`, con las mismas condiciones de visibilidad y habilitación que hoy, y mover las `Key` de los antiguos elementos a los nuevos; quitar de la barra los iconos sueltos (archivar, archivados, Sheets, «Tus datos», proveedor). (FR-007 FR-008)
- [ ] T032 [US2] Buscar en `test/` e `integration_test/` las referencias al menú lateral y a los iconos retirados (`openDrawer`, `Drawer`, textos y `Key` del menú) y actualizarlas al nuevo destino; listar cada archivo en la evidencia de `test/ai_settings_chat_test.dart` y demás; `flutter test` en verde. (FR-008)
- [ ] T033 [US2] Escribir `test/menu_map_test.dart`: para cada fila del «Mapa de menús», abrir el destino nuevo (⋮ del chat, Ajustes o volver) y encontrar la acción; falla si falta alguna. (FR-008)
- [ ] T034 [US2] Documentar en `docs/0.3.32-AJUSTES.md` con capturas el nuevo recorrido y el mapa de menús aplicado. (SC-002)

## Phase 4: User Story 3 - Registrar cualquier actividad a mano (Priority: P1)

**Goal**: constructor con ritmos y campos con tipo, plantillas propias, registro puntual y contadores.

**Independent Test / Checkpoint**: recorrido R3 de `quickstart.md` sin IA: «Leer» libre con campos y
«Beber agua» puntual, con los datos presentes tras reiniciar.

- [ ] T035 [P] [US3] Escribir `test/activity_definition_fields_test.dart`: las definiciones antiguas cargan y se vuelven a serializar con el mismo JSON (byte a byte); validación de cada clave nueva de `data-model.md` §1 (tipos y `aggregate` compatibles según research D3, `options` solo en `choice`, `min`/`max` solo en `scale`, `segmentPlural` obligatorio con `segmentSingular`, `userSet` con valores permitidos, `activityKey` calculada); `proposal` acepta campos ampliados y `segment*` pero rechaza `userSet` y `activityKey`. (FR-011 FR-012 FR-015)
- [ ] T036 [US3] Implementar en `lib/domain/activity.dart` las claves de `data-model.md` §1 (`toJson` solo escribe las que tienen valor) y ampliar `ActivityDefinition.proposal`; hecho cuando T035 pasa. (FR-011 FR-012 FR-015)
- [ ] T037 [US3] En `lib/data/sqlite_activity_repository.dart`: validar los valores por tipo de campo en `interpretActivityMessage` y en el registro manual; guardar `activityKey` calculada al preparar; `renameActivity` no cambia `activityKey`; pruebas en `test/activity_repository_test.dart`. (FR-011 FR-015)
- [ ] T038 [US3] Implementar el registro puntual (tarea T007 de 003) con `lib/domain/observation.dart` y `lib/data/observation_repository.dart` sobre `trackia_observations`: crear (original y procedencia obligatorios), listar por acompañante y día, corregir creando una revisión con `supersedes_id`, consultar solo la última revisión; `test/observation_repository_test.dart` con ausente ≠ 0 y aislamiento por perfil; anotar en 003 junto a T007 «Realizada en 004 T038». (FR-014)
- [ ] T039 [US3] Crear `lib/data/activity_template_repository.dart` sobre `trackia_activity_templates` (guardar, listar por acompañante, archivar; `instant` para puntuales) con `test/activity_template_repository_test.dart`. (FR-010 FR-014)
- [ ] T040 [US3] Crear `lib/ui/activity_builder.dart` (`ActivityBuilder`): nombre; ritmo con cuatro opciones (Puntual, Libre, Con duración, Por tramos) que muestran solo sus campos según research D2; nombre del tramo; editor de campos (tipo, forma de contar filtrada por tipo, unidad, opciones, mínimo y máximo); plantillas rápidas Fútbol, Yoga, Pomodoro, Series, Correr y Leer con los valores de research D5; casilla «Guardar en tus actividades»; devuelve una `ActivityDefinition` o una plantilla puntual. (FR-010 FR-011 FR-012)
- [ ] T041 [US3] Escribir `test/activity_builder_test.dart`: cada ritmo produce la definición de research D2; no se ofrecen formas de contar incompatibles; la plantilla Pomodoro da `activitySeconds: 1500`, `restSeconds: 300`, `targetCycles: 4`, `segmentSingular: 'pomodoro'`; errores de validación en español. (FR-010 FR-011 FR-012)
- [ ] T042 [US3] En `lib/ui/activity_focus.dart` (`ActivityChooser`), sustituir «Nueva actividad» → `NewActivityDialog` por `ActivityBuilder` y listar primero «Tus actividades» (plantillas del acompañante); borrar `NewActivityDialog` cuando ninguna prueba lo use. (FR-009 FR-010)
- [ ] T043 [US3] En `lib/ui/activity_focus.dart`, usar `segmentSingular`/`segmentPlural` en el texto de estado del panel y mantener la regla actual (`gymbro` → series, resto → tramos) si faltan; prueba en `test/activity_focus_test.dart`. (FR-012)
- [ ] T044 [US3] Añadir en `lib/ui/activity_focus.dart` contadores +/− para los campos `number` con `aggregate: sum` durante el tramo y el descanso: los toques se acumulan en pantalla y, tras 3 s sin tocar o al pulsar Parar, se guarda **un** mensaje del usuario con el original («Páginas: +18») y `metrics` con esa cantidad (semántica de `data-model.md` §1, sin totales acumulados); añadir la frase de esa sección al contexto de `lib/application/assistant_context.dart`; pruebas en `test/activity_focus_test.dart` (sin IA: 18 toques → un mensaje con 18; dos ráfagas → dos mensajes cuya suma es el total). (FR-013)
- [ ] T045 [US3] Registro puntual en la interfaz: para plantillas `instant`, la barra compacta muestra «Registrar», que abre una hoja con los campos y guarda una observación con `observation_repository`; el chat muestra la línea «Registrado: …»; prueba en `test/instant_record_test.dart`. (FR-014)
- [ ] T046 [US3] Instrucciones opcionales: en `lib/domain/companion.dart` admitir `prompt` vacío (0–8000); en el editor de `lib/ui/companions.dart`, etiqueta «Instrucciones para la IA (opcional)» y ayuda «Se usan cuando conectes un proveedor.»; en `lib/application/assistant_context.dart`, texto neutro por defecto de `data-model.md` §2; pruebas en `test/companion_test.dart` y `test/assistant_context_test.dart`. (FR-016)
- [ ] T047 [US3] Escribir y ejecutar `integration_test/manual_activity_android_test.dart` (recorrido R3, sin IA): crear «Leer» libre con Páginas y Libro, iniciar, contar 18 páginas, parar, reiniciar la app y ver los datos; crear «Beber agua» puntual y registrar 1 vaso. (SC-003 FR-014)
- [ ] T048 [US3] Documentar en `docs/0.3.32-ACTIVIDADES-ABIERTAS.md` ritmos, tipos, compatibilidad con definiciones anteriores y límites. (FR-010 FR-015)

## Phase 5: User Story 5 - Editar a mano sin que la IA lo pise (Priority: P2)

**Goal**: candados por campo, propuestas Aplicar/Ignorar y eventos de edición visibles para la IA.

**Independent Test / Checkpoint**: `test/assistant_lock_proposals_test.dart` en verde con cliente simulado.

- [ ] T049 [P] [US5] Escribir `test/activity_locks_test.dart`: cada edición desde la interfaz (renombrar, descanso, tiempos, constructor) añade la propiedad a `userSet`; tocar el candado la quita; las ediciones de la IA no la añaden. (FR-023)
- [ ] T050 [US5] Añadir el parámetro `source` (`user` o `assistant`) a los métodos de edición de `lib/data/sqlite_activity_repository.dart` usados por la interfaz y por las propuestas (`renameActivity`, `setActivityTiming`, `replaceActivityPreparation` y los que el agente encuentre) y actualizar `userSet` en la misma transacción; hecho cuando T049 pasa. (FR-023)
- [ ] T051 [US5] En `lib/ui/assistant_chat.dart`, al aplicar `gymia-timing` o `gymia-activity` sobre la actividad abierta, separar propiedades fijadas y libres: las libres se aplican como hoy; las fijadas generan una tarjeta (`lib/ui/proposal_card.dart`) con «Aplicar» e «Ignorar»; escribir `test/assistant_lock_proposals_test.dart` con cliente simulado (descanso fijado en 120 s, propuesta de 150 s → sigue en 120 s y aparece la tarjeta; Aplicar → 150 s). (FR-023)
- [ ] T052 [US5] Eventos de edición: guardar en el chat una entrada con rol `event` («Cambiaste el descanso a 120 s»), mostrarla como línea neutra, **no** enviarla al proveedor como mensaje y resumir los eventos recientes en el contexto de `lib/application/assistant_context.dart`; comprobar antes cómo `AiMessage` convierte roles para la API; pruebas en `test/assistant_context_test.dart`. (FR-024)
- [ ] T053 [US5] Escribir en `test/activity_repository_test.dart` la prueba «un cambio de tiempos con un tramo en marcha no altera ese tramo y se aplica al siguiente» y corregir `setActivityTiming` solo si falla. (FR-025)
- [ ] T054 [US5] Mostrar el candado junto a cada propiedad fijada en el panel y en el constructor (`lib/ui/activity_builder.dart`), con `Semantics` «Fijado por ti. Toca para liberar»; prueba de widget. (FR-023)
- [ ] T055 [US5] Documentar en `docs/0.3.32-EDICION-MANUAL-IA.md` las reglas de candados y propuestas. (FR-023 FR-025)

## Phase 6: User Story 6 - Recordatorio o juego, por acompañante (Priority: P2)

**Goal**: modo por acompañante y recordatorios con ventana, última llamada, mínimo y pausa.

**Independent Test / Checkpoint**: recorrido R6 de `quickstart.md`: dos avisos en un día no cumplido y
ninguno en un día cumplido.

- [ ] T056 [P] [US6] Crear `lib/data/progress_repository.dart` con ajustes de acompañante (por defecto `mode = 'reminder'` para los acompañantes existentes) y recordatorios (validaciones de `data-model.md` §5, uno activo por acompañante), conectar el borrado en cascada desde `lib/data/companion_store.dart`, y `test/progress_repository_test.dart` (aislamiento por perfil, cascada sin tocar observaciones ni actividades, validaciones). (FR-026 FR-027)
- [ ] T057 [P] [US6] Crear `lib/domain/reminder.dart` con el modelo, `renderReminder` (selección de plantilla y marcadores exactamente como `contracts/reminders-android.md`) y la construcción de la instantánea, y `test/reminder_render_test.dart` con todos los casos de plantilla, marcadores sin valor y la plantilla de GymBro. (FR-027 FR-029)
- [ ] T058 [US6] Crear `lib/application/reminder_scheduler.dart`: calcula la instantánea (día cumplido = al menos una sesión hasta que exista la Fase 7, que lo sustituye por el motor), aplica la pausa de 7 días y llama a `com.gymia.app/reminders.sync`; `test/reminder_scheduler_test.dart` con canal y reloj simulados. (FR-028 FR-030)
- [ ] T059 [US6] Android: `ReminderReceiver.kt`, `BootReceiver.kt` y la función pura de texto en `android/app/src/main/kotlin/com/gymia/app/ReminderReceiver.kt`; canal `trackia_reminders_v1`; canal `com.gymia.app/reminders` en `MainActivity.kt`; permiso y receptores en `AndroidManifest.xml`; todo según `contracts/reminders-android.md`; nunca usar el canal de alarma. (FR-004 FR-028 FR-029 FR-030 FR-031)
- [ ] T060 [US6] Crear `lib/ui/companion_settings.dart` («Modo y avisos»): tarjetas Recordatorio/Juego; en Juego, interruptores de metas, rachas, logros y mensajes de ánimo y días libres por semana; recordatorio con días, inicio y fin, última llamada, tono y mínimo; vista previa del texto con `renderReminder`; acceso desde el ⋮ de cada tarjeta del tablero y desde el ⋮ del chat; `test/companion_settings_test.dart`. (FR-026 FR-027)
- [ ] T061 [US6] Llamar a `ReminderScheduler.sync` al abrir la app (`lib/ui/app.dart`), al guardar un valor, parar, terminar, guardar ajustes, borrar un acompañante y cambiar de perfil; prueba con un programador simulado que cuenta llamadas en `test/reminder_scheduler_test.dart`. (FR-028)
- [ ] T062 [US6] En `lib/ui/companions.dart`, mostrar «Recordatorios en pausa» con «Reanudar» en la tarjeta del acompañante pausado; prueba de widget. (FR-030)
- [ ] T063 [US6] Al tocar un recordatorio, abrir el chat de ese acompañante: leer los extras `profileId` y `companionId` en `MainActivity.kt` y enrutarlos en `lib/ui/app.dart` (perfil distinto → no cambiar de perfil, solo abrir el tablero). (FR-027)
- [ ] T064 [US6] Escribir y ejecutar `integration_test/reminders_android_test.dart` (recorrido R6): ventana a +1 min → aviso en `trackia_reminders_v1`; con `lastDoneDate = hoy` → ninguno; tras `adb reboot` simulado con la difusión de arranque (`adb shell am broadcast -a android.intent.action.BOOT_COMPLETED -p com.gymia.app.dev`) siguen programados. (SC-005 FR-031)
- [ ] T065 [US6] [OWNER] En el teléfono: recordatorio real durante dos días, reinicio del móvil y No molestar respetado; anotar resultado en `docs/0.3.32-RECORDATORIOS.md`. (FR-004 FR-031)
- [ ] T066 [US6] Documentar en `docs/0.3.32-RECORDATORIOS.md` modos, ventana, última llamada, mínimo, pausa y límites. (FR-026 FR-030)

## Phase 7: User Story 7 - Metas, rachas y logros (Priority: P2)

**Goal**: evaluador determinista, logros generados desde campos, resumen al terminar y pantalla Progreso.

**Independent Test / Checkpoint**: `test/progress_engine_test.dart` (incluida la prueba de propiedad) y
recorrido R7 de `quickstart.md`.

- [ ] T067 [P] [US7] Crear `lib/domain/progress.dart` (`Metric`, `GoalRule`, `AchievementRule`, `AchievementUnlock`, `ProgressSnapshot`) con validación de JSON según `data-model.md` §4 y `test/progress_rules_test.dart` (válidos, claves extra, valores fuera de rango). (FR-032 FR-036)
- [ ] T068 [US7] Escribir `test/progress_engine_test.dart` antes del motor: `sum`, `max`, `avg`, `distinct`, `countTrue`; ausentes y campos heredados ignorados; solo la última revisión; `per` día, semana y total con `local_day`; metas y mínimo; todos los casos de racha de research D14 (día libre, segundo fallo en la semana, cambio de semana, hoy sin cumplir); cambio de zona horaria; prueba de propiedad con 500 casos de semilla fija: nunca hay desbloqueo si el valor calculado no alcanza el umbral. (FR-032 FR-034 SC-006)
- [ ] T069 [US7] Implementar `lib/application/progress_engine.dart` como funciones puras (sin E/S, sin `DateTime.now()`, sin IA); hecho cuando T068 pasa. (FR-032 FR-034)
- [ ] T070 [US7] Implementar la generación de familias de logros de `data-model.md` §4 en `lib/application/progress_engine.dart` (títulos con separador de miles español, sin duplicados por `rule_hash`) con pruebas en `test/progress_engine_test.dart`. (FR-033)
- [ ] T071 [US7] Ampliar `lib/data/progress_repository.dart` con metas, logros y desbloqueos, y con el cargador de registros (actividades, tramos, `metrics` y observaciones del acompañante); pruebas en `test/progress_repository_test.dart`. (FR-032)
- [ ] T072 [US7] Crear `lib/application/progress_service.dart`: al guardar un valor, parar o terminar, cargar, evaluar y guardar desbloqueos nuevos en una transacción y devolver el delta (logros y récords nuevos); regenerar familias al guardar una definición en modo Juego con logros activos; sustituir en `ReminderScheduler` el «día cumplido» provisional por el del motor; `test/progress_service_test.dart`. (FR-032 FR-033 FR-035)
- [ ] T073 [US7] Añadir a `lib/ui/companion_settings.dart` la edición de la meta (métrica limitada a tiempo, sesiones y campos con tipo del acompañante; periodo; objetivo; mínimo); prueba en `test/companion_settings_test.dart`. (FR-026 FR-034)
- [ ] T074 [US7] Crear `lib/ui/activity_summary.dart` («Sesión terminada»): anillo completo, nombre y duración, récords y logros nuevos del delta; se muestra al Terminar en modo Juego; `test/activity_summary_test.dart` (con y sin novedades). (FR-035)
- [ ] T075 [US7] Crear `lib/ui/progress_screen.dart` («Progreso»): racha actual y mejor, calendario de 4 semanas, anillos de metas y cuadrícula de logros (bloqueados con progreso, desbloqueados con degradado); acceso desde un icono de trofeo en el tablero y desde el ⋮ del chat; `test/progress_screen_test.dart`. (FR-032)
- [ ] T076 [US7] En `lib/ui/companions.dart`, en modo Juego, mostrar en cada tarjeta el anillo de la meta semanal y la línea de racha; prueba de widget. (FR-026)
- [ ] T077 [US7] En `lib/application/assistant_context.dart`, incluir como datos el estado calculado (racha, meta de hoy, logros de hoy) y la instrucción fija «No afirmes que el usuario desbloqueó un logro…» del contrato; prueba en `test/assistant_context_test.dart`. (FR-032)
- [ ] T078 [US7] Ejecutar el recorrido R7 de `quickstart.md` con `integration_test/progress_android_test.dart` (reloj controlado, tres días de lectura, un día libre) y documentar en `docs/0.3.32-JUEGO.md`. (SC-006 FR-034)

## Phase 8: User Story 9 - Chats fuera de secure storage (Priority: P2)

**Goal**: chats, archivos y adjuntos en SQLite y archivos, con migración verificada en dos fases.

**Independent Test / Checkpoint**: `test/chat_store_migration_test.dart` y las pruebas existentes de
chats y aislamiento en verde.

- [ ] T079 [P] [US9] Escribir `test/chat_store_migration_test.dart` con los fixtures de T003: copia y verificación (mensajes, orden y hash de adjuntos), fallo simulado a mitad y reintento idempotente, fase 2 que borra solo claves verificadas, aislamiento entre perfiles y acompañantes. (FR-040 SC-007)
- [ ] T080 [US9] Crear `lib/data/chat_store.dart` sobre `trackia_chats` y `trackia_chat_archives`, con adjuntos en `<applicationSupportDirectory>/trackia_media/<sha256>` (research D12). (FR-040)
- [ ] T081 [US9] Implementar la migración de dos fases en `lib/data/chat_store.dart` (lectura preferente de SQLite con caída a la clave antigua) y lanzarla al cargar el chat; hecho cuando T079 pasa. (FR-040)
- [ ] T082 [US9] Cambiar `lib/data/chat_archive_store.dart`, la carga de `lib/ui/assistant_chat.dart` (`storage.read(key: chatKey)`) y el borrado de `lib/data/companion_store.dart` para usar `chat_store`; `test/chat_archive_store_test.dart`, `test/chat_archiving_test.dart` y `test/profile_isolation_test.dart` en verde sin debilitarlos. (FR-040)
- [ ] T083 [US9] Ejecutar `integration_test/trackia_large_media_test.dart` y `integration_test/profile_isolation_android_test.dart` en el emulador sobre una instalación con datos antiguos (instalar la versión anterior, crear chat con imagen, actualizar). (SC-007)
- [ ] T084 [US9] Documentar en `docs/0.3.32-CHATS.md` el nuevo almacenamiento, la migración y la recuperación. (FR-040)

## Phase 9: User Story 8 - Crear un acompañante con ayuda de la IA (Priority: P3)

**Goal**: creación a mano o asistida, propuestas `trackia-*` validadas y sugerencia puntual de juego.

**Independent Test / Checkpoint**: `test/companion_creator_test.dart` con cliente simulado (bloque válido
crea todo; inválido no crea nada).

- [ ] T085 [P] [US8] Crear `lib/domain/assistant_blocks.dart` con los analizadores de `trackia-companion`, `trackia-goal`, `trackia-achievement` y `trackia-reminder-copy`, y `test/assistant_blocks_test.dart` con los casos de la regla 7 del contrato para cada bloque. (FR-036 FR-038)
- [ ] T086 [US8] Crear `lib/ui/companion_creator.dart`: al pulsar «Crear acompañante», elegir «Con ayuda de la IA» (solo si la IA está verificada; si no, explicación y acceso a Ajustes) o «A mano» (editor ampliado con icono, color, modo y recordatorio). (FR-037)
- [ ] T087 [US8] Conversación de creación en `lib/ui/companion_creator.dart` con el guion del contrato, sin guardarla en ningún chat; ficha de vista previa con Crear, Editar y Descartar; Crear guarda en el orden del contrato y deshace si falla un paso; `test/companion_creator_test.dart` (válido → todo creado; inválido → nada; Editar → constructor relleno). (FR-037 FR-038)
- [ ] T088 [US8] Mostrar en la ficha el nivel elegido con su texto (Solo recordatorio, Metas y rachas, Juego completo) y mapear `mode` a los ajustes (`goals` = Juego sin logros); prueba en `test/companion_creator_test.dart`. (FR-037)
- [ ] T089 [US8] Sugerencia de juego de research D15 en `lib/ui/assistant_chat.dart` (5 días cumplidos en modo Recordatorio): tarjeta con Activar, Ahora no y No volver a sugerir, guardada en `dismissed_suggestions`; prueba en `test/game_suggestion_test.dart`. (FR-039)
- [ ] T090 [US8] En el chat en modo Juego, convertir `trackia-goal`, `trackia-achievement` y `trackia-reminder-copy` en tarjetas cuya acción guarda con los repositorios y nunca crea desbloqueos; prueba en `test/assistant_lock_proposals_test.dart` o un archivo nuevo `test/game_blocks_chat_test.dart`. (FR-036)
- [ ] T091 [US8] Documentar en `docs/0.3.32-CREACION-ASISTIDA.md` el flujo, los bloques y los límites. (FR-037)

## Phase 10: User Story 10 - Mantenimiento interno (Priority: P3)

**Goal**: User-Agent real, textos sin GymIA visibles, errores útiles, archivos divididos y R8 evaluado.

**Independent Test / Checkpoint**: `flutter test` en verde tras cada paso de división; `test/app_info_test.dart`.

- [ ] T092 [P] [US10] Crear `lib/data/app_info.dart` (research D11) y `test/app_info_test.dart`, que lee `pubspec.yaml` y falla si la versión no coincide; usar `trackiaUserAgent` en `lib/data/ai_client.dart:211` y `lib/data/ai_model_catalog.dart:53`. (FR-042)
- [ ] T093 [US10] Cambiar a «TrackIA» los textos **visibles** que dicen GymIA en `lib/` (por ejemplo el mensaje de sistema «Comprobación de conexión de GymIA» en `lib/application/ai_availability.dart` y los de `ChatGptFailure`), sin tocar claves, IDs de sesión, nombres de paquete ni bloques `gymia-*`; listar cada cambio en la evidencia. (FR-047)
- [ ] T094 [US10] En `lib/data/chatgpt_auth.dart`, registrar con `debugPrint` el tipo de error (sin tokens ni URLs con parámetros) en `connect` y dar a `ChatGptFailure('connection')` un mensaje propio en español; prueba en el test existente de ChatGPT o en `test/chatgpt_auth_test.dart`. (FR-043)
- [ ] T095 [US10] Auditar los `catch (_)` de `lib/` en una tabla en `docs/0.3.32-ERRORES.md` (archivo, línea, legítimo u oculta un fallo); cambiar solo los de `lib/data/` marcados «oculta un fallo», añadiendo `debugPrint` y, si hay usuario, un mensaje; pruebas en verde. (FR-043)
- [ ] T096 [US10] Dividir `lib/ui/assistant_chat.dart` en pasos pequeños (compositor, lista de mensajes, cabecera y menú, tarjetas) en archivos bajo `lib/ui/chat/`, sin cambiar textos, `Key` ni comportamiento; tras cada paso, `analyze` y `test` en verde y un commit `refactor:`; objetivo menos de 1500 líneas. (FR-044)
- [ ] T097 [US10] Dividir de la misma forma `lib/ui/app.dart` y `lib/ui/activity_focus.dart` (objetivo menos de 900 líneas cada uno). (FR-044)
- [ ] T098 [US10] Activar R8 en `android/app/build.gradle.kts` (`isMinifyEnabled = true`, `isShrinkResources = true` en `release`) con `android/app/proguard-rules.pro` (reglas para Flutter, plugins y `llama_cpp_dart`), sin tocar la configuración de firma; compilar `--debug` para comprobar que el resto no cambia. (FR-045)
- [ ] T099 [US10] [OWNER] Compilar el release firmado, instalarlo encima de la versión anterior, prueba de humo (abrir, chat, modelo local, avisos, Sheets) y comparar tamaño; si algo falla, revertir T098 y documentarlo en `docs/0.3.32-R8.md`. (FR-045)

## Phase 11: User Story 11 - IA por acompañante (Priority: P3, opcional)

**Goal**: configuración de IA por defecto con excepciones por acompañante.

**Independent Test / Checkpoint**: `test/ai_override_test.dart` con cliente simulado.

- [ ] T100 [P] [US11] Escribir `test/ai_override_test.dart`: sin excepción se usa la configuración por defecto; con excepción, la del acompañante; las claves siguen solo en secure storage. (FR-046)
- [ ] T101 [US11] Resolver la configuración efectiva en `lib/data/ai_settings_store.dart` usando `ai_override` (solo proveedor y modelo) de `trackia_companion_settings`; las credenciales siguen siendo del perfil. (FR-046)
- [ ] T102 [US11] Añadir «Por acompañante» en la pantalla de IA de `lib/ui/ai_settings.dart` (lista de acompañantes con «Por defecto» o el modelo elegido). (FR-046)
- [ ] T103 [US11] Documentar en `docs/0.3.32-IA-POR-ACOMPANANTE.md`. (FR-046)

## Phase 12: Cierre

**Goal**: regresión completa, trazabilidad y aceptación del propietario.

- [ ] T104 Ejecutar `analyze`, `test` y todas las pruebas de `integration_test/` listadas en `quickstart.md` y registrar resultados en `docs/TRACKIA-QA.md`. (SC-008)
- [ ] T105 Ejecutar `python3 scripts/validate-sdd-004.py` y corregir cualquier fallo de formato o trazabilidad en `specs/004-trackia-experience/tasks.md`. (SC-008)
- [ ] T106 Actualizar `specs/README.md` y `docs/TRACKIA-QA.md` con el estado real (entregado, pendiente y `[OWNER]`), sin marcar como entregado nada sin evidencia. (SC-008 FR-047)
- [ ] T107 [OWNER] Recorridos R1–R8 de `quickstart.md` en el teléfono del propietario y aceptación anotada en `docs/TRACKIA-QA.md`. (SC-001 SC-002 SC-003)

## Hallazgos fuera de alcance

(El agente añade aquí lo que descubra y no esté en ninguna tarea.)

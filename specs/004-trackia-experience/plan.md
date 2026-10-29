# Implementation Plan: TrackIA — experiencia, actividades abiertas y juego opcional

**Branch**: `004-trackia-experience` | **Date**: 2026-10-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/004-trackia-experience/spec.md`

## Summary

Once historias en cinco bloques: (1) arreglar avisos con No molestar; (2) ajustes globales y
navegación sin menú lateral en el chat; (3) actividades abiertas con constructor manual,
ritmos, campos con tipo y registro puntual; (4) identidad visual del icono; (5) recordatorios,
modo Juego, metas, rachas y logros deterministas, con la IA como autora opcional de
propuestas. Se suma la deuda de `REVISION.md` (chats fuera de secure storage, User-Agent,
errores, división de archivos, R8).

Principio rector, acordado con el propietario: **la IA ayuda a construir el juego y la app lo
administra**. La IA propone (bloques con esquema estricto); la app valida, guarda, mide,
desbloquea y avisa; el usuario acepta, edita o fija.

## Technical Context

**Language/Version**: Dart ≥ 3.10, Flutter 3.47 (usar `.tools/flutter-3.47/flutter/bin/flutter`;
`.tools/flutter` es demasiado antiguo y falla al resolver dependencias). Kotlin en `android/`.
**Primary Dependencies**: sqflite, flutter_secure_storage 9.2.4, path_provider, uuid, intl,
speech_to_text, flutter_markdown_plus, llama_cpp_dart (vendorizado en `packages/`).
No añadir dependencias nuevas salvo que una tarea lo indique explícitamente.
**Storage**: SQLite (BD versión 5 en `lib/data/sqlite_workout_repository.dart:299`, migraciones
en `lib/data/sqlite_activity_repository.dart` `_migrateV4` y `lib/data/trackia_migrations.dart`
`_createTrackiaV5`); `flutter_secure_storage` hoy guarda también chats y acompañantes (deuda US9).
Preferencias nativas en SharedPreferences de `RestNotifications`.
**Testing**: `flutter test` (40 archivos en `test/`, 207 pruebas en la línea base del 2026-10-29),
`integration_test/` (15 archivos; necesitan emulador o dispositivo).
**Target Platform**: Android (minSdk/targetSdk de Flutter). iOS solo debe seguir compilando.
**Project Type**: mobile-app (Flutter + puente nativo Android).
**Performance Goals**: sin temporizadores periódicos con la app en segundo plano; evaluación de
logros solo al guardar o terminar una actividad; arranque sin bloqueos por migraciones.
**Constraints**: local primero, sin red ni IA para US1–US7; migraciones aditivas con respaldo;
no tocar `.signing/`, `android/key.properties` ni claves; no cambiar `applicationId`.
**Scale/Scope**: un usuario, varios perfiles, decenas de acompañantes, miles de registros.

## Constitution Check

| Principio | Cómo lo cumple esta entrega | Estado |
|---|---|---|
| I. Actividades abiertas | Ritmos y campos genéricos; plantillas = atajos que rellenan la misma definición; logros generados desde campos | Cumple |
| II. Conversación y ejecución determinista | Evaluador de metas/logros/recordatorios en la app; IA solo propone; controles locales sin IA | Cumple |
| III. Espacios sin mezclas | Toda tabla nueva lleva `profile_id` y `companion_id`; pruebas de aislamiento | Cumple |
| IV. Datos originales y compatibilidad | Campos antiguos sin tipo = «solo notas»; migración v6 aditiva con respaldo; no se reinterpreta el pasado | Cumple |
| V. Personalización subordinada | Bloques `trackia-*` con esquema estricto; un prompt no concede permisos | Cumple |
| VI. Persistencia y efectos verificables | Migración de chats verificada antes de borrar claves; estados explícitos | Cumple |
| VII. Interfaz adaptable y accesible | Tokens con contraste comprobado; controles por fase; claro/oscuro | Cumple |
| VIII. Evidencia antes de afirmar | Cada tarea indica su prueba; las pruebas de dispositivo real quedan marcadas `[OWNER]` | Cumple |

Sin violaciones. La enmienda de la bienvenida (FR-022) cambia un contrato de 003, no un principio.

## Relación con 003

| 003 | Qué hace 004 |
|---|---|
| T007 (`observation_repository.dart`, `runId` opcional) | **Se implementa dentro de 004** (T038 de 004) para el ritmo Puntual. Marcar T007 en 003 con referencia a 004 al terminar |
| T020 (extraer `contextForAi` a `lib/application/assistant_context.dart`) | **Se implementa dentro de 004** (T006 de 004), en la Fase 0, porque varias historias amplían ese contexto |
| T012, T014, T028 (editor y controles manuales sobre el motor nuevo de 003) | 004 entrega un constructor sobre el **motor actual** (`ActivityDefinition` en `lib/domain/activity.dart`). 003 sigue pendiente para su motor de ejecuciones; no se duplica |
| T029 (sonido/vibración por fase) | 004 cubre solo el canal de alarma y la detección de No molestar (US1) |
| US9 / `contracts/welcome.md` | Enmienda FR-022: `autoShow` pasa a `false` tras la primera confirmación salvo elección contraria |
| `lib/domain/activity_definition.dart` (`FieldType`, sin uso en la app) | Se reutiliza el enum `FieldType` y se añade el tipo escala en 004 como número con mínimo y máximo (sin cambiar el enum) |

## Estado verificado del código (2026-10-29)

Hechos comprobados leyendo el código. El agente DEBE releer cada punto antes de cambiarlo.

1. **Avisos**: canal único `gymia_rest`, `IMPORTANCE_HIGH`, sin categoría ni audio de alarma,
   sin lectura de No molestar (`android/app/src/main/kotlin/com/gymia/app/RestNotifications.kt:24,114,153,190,345`).
   `notifyTest` crea el mismo canal con otro nombre visible (línea 345). Alarmas con
   `setExactAndAllowWhileIdle` (líneas 107 y 225). No hay receptor de `BOOT_COMPLETED`.
2. **Tablero**: `CompanionDashboard` (`lib/ui/companions.dart:5`), `AppBar` solo con título
   (línea 104). Recibe `profileId`. Los acompañantes se guardan en secure storage con la clave
   `trackia.companions.v1` por perfil (`lib/data/companion_store.dart:19`).
3. **Menú del chat**: menú lateral en `lib/ui/assistant_chat.dart` (≈1895–2075) y acciones de la
   barra (≈2098–2132). Ver «Mapa de menús».
4. **Creación manual**: ya existe. El botón ⇄ del panel llama a `choose()`
   (`lib/ui/activity_focus.dart:185`) → `ActivityChooser` → «Nueva actividad» →
   `NewActivityDialog` (línea ≈727) con Nombre, «Varias series o tramos», duración por tramo,
   descanso (segundos) y «Series previstas». No depende de la IA (el parámetro `aiReady` de
   `ActivityFocusControls` se declara pero no se usa). El problema es de visibilidad y vocabulario.
5. **Definición de actividad**: `ActivityDefinition` (`lib/domain/activity.dart:6`) con `name`,
   `repeated`, `restSeconds`, `activitySeconds`, `targetSets`, `targetCycles`, `completedCycles`,
   `fields` (mapas con exactamente `key`, `label`, `unit`; máx. 12), `instructions`, `origin`,
   `companionId`. Se guarda como JSON en `activities.definition`. El analizador de propuestas
   `ActivityDefinition.proposal` rechaza claves desconocidas en el bloque `gymia-activity`.
6. **Valores**: los valores van en `activity_messages.metrics` (JSON) y se validan en
   `interpretActivityMessage` (`lib/data/sqlite_activity_repository.dart:223–280`): números
   finitos, booleanos o texto ≤ 500; claves limitadas a los campos de la definición.
7. **Esquema**: `activities.workout_id` es `NOT NULL` (toda actividad pertenece a un entreno);
   `activity_intervals` con `running_slot` único; BD versión 5.
8. **Nombre del tramo**: hoy se decide por `companionId == 'gymbro'` → «series», si no «tramos»
   (`lib/ui/activity_focus.dart`, texto de estado del panel).
9. **Prompt del acompañante**: solo se usa en el mensaje de sistema
   (`lib/ui/assistant_chat.dart:1555`, `userInstructions`). `Companion` exige 1–8000 caracteres
   (`lib/domain/companion.dart`).
10. **Bienvenida**: `autoShow` inicial `true` (`lib/data/welcome_settings_store.dart:22`); contrato
    en `specs/003-trackia-platform/contracts/welcome.md:23–29`.
11. **Colores**: `lime` (#63D9E2), `ink`, `panel`, `muted`, `trackiaOrange` (#FF8A57) en
    `lib/ui/theme.dart`; fuera del tema solo se usan en `lib/ui/app.dart` (líneas ≈526, 570) y hay
    un color literal en `lib/ui/app.dart:562`. Teal de notificación `rgb(0,109,126)` en
    `RestNotifications.kt:40`.
12. **User-Agent**: `'GymIA/0.3.14'` en `lib/data/ai_client.dart:211` y `lib/data/ai_model_catalog.dart:53`.
    No existe `package_info_plus`.
13. **Chats**: claves `gymia.ai.chat.v1` (por perfil y acompañante, `lib/data/chat_archive_store.dart:19`)
    y `gymia.ai.archive.v1.<id>` (línea 25); también se leen y borran en `lib/data/companion_store.dart:60–79`.
14. **Release**: `buildTypes.release` usa `signingConfigs.findByName("personal")`
    (`android/app/build.gradle.kts:51`); sin R8. `debug` añade `.dev`.
15. **Línea base**: `flutter analyze` → 11 avisos `info` preexistentes (APIs obsoletas y una llave);
    `flutter test` → 207 pruebas en verde.

## Decisiones fijadas

Detalle y alternativas descartadas en [research.md](research.md). Resumen:

- **D1 Avisos**: canal nuevo `trackia_timer_alarm_v1` (alarma) + canal existente `gymia_rest`
  (normal) + canal nuevo `trackia_reminders_v1` (recordatorios, importancia por defecto).
  Preferencia nativa `alarmStyle` (por defecto `true`). Contrato: [contracts/reminders-android.md](contracts/reminders-android.md).
- **D2 Ritmo**: se deriva de la definición; no se guarda. Puntual = registro en
  `observation_repository` (003 T007), no una actividad con tramos.
- **D3 Campos**: claves opcionales nuevas en cada mapa de campo: `type`, `aggregate`, `options`,
  `min`, `max`. Ausencia de `type` = campo heredado «solo notas». Ver [data-model.md](data-model.md).
- **D4 Candados**: clave opcional `userSet` (lista de nombres de propiedad) en la definición.
- **D5 Nombre del tramo**: claves opcionales `segmentSingular` y `segmentPlural`.
- **D6 Ajustes de acompañante, recordatorios, metas y logros**: tablas SQLite nuevas en la
  migración v6 (aditiva). Icono y color se añaden al JSON de `Companion` (pequeño; secure storage
  hasta que US9 lo mueva).
- **D7 Evaluador**: servicio puro en `lib/application/progress_engine.dart`, sin E/S, probado con
  reloj inyectado. Lo invoca un orquestador al guardar o terminar.
- **D8 Recordatorios nativos**: Flutter escribe una instantánea JSON en SharedPreferences; el
  receptor nativo redacta el texto con plantillas y marcadores, sin abrir SQLite.
- **D9 Bloques IA**: `trackia-companion`, `trackia-goal`, `trackia-achievement`,
  `trackia-reminder-copy`. Ver [contracts/assistant-blocks.md](contracts/assistant-blocks.md).
- **D10 Visual**: tokens fijos en [contracts/visual-tokens.md](contracts/visual-tokens.md); logo y
  anillo con `CustomPainter`, sin imágenes nuevas ni dependencias.
- **D11 User-Agent**: constante en `lib/data/app_info.dart` + prueba que la compara con `pubspec.yaml`.
- **D12 Chats**: tablas `trackia_chats` y `trackia_chat_archives` en SQLite; adjuntos en archivos
  bajo el directorio de soporte de la app; migración en dos fases (copiar y verificar → borrar claves).

## Mapa de menús

Cada acción existente y su destino. Ninguna desaparece (FR-008).

| Hoy (ubicación) | Destino |
|---|---|
| Menú lateral → Acompañantes | Botón volver del chat (vuelve al tablero) |
| Menú lateral → Apariencia | Ajustes → App → Apariencia |
| Menú lateral → Ayuda y bienvenida | Ajustes → App → Ayuda y bienvenida |
| Menú lateral → interruptor de avisos | Ajustes → App → Avisos |
| Menú lateral → Probar notificación ahora | Ajustes → Avisos → Probar aviso |
| Menú lateral → Permitir avisos puntuales | Ajustes → Avisos (fila de alarmas exactas) |
| Menú lateral → Rutinas e historial | Chat → ⋮ → Rutinas e historial |
| Menú lateral → Cuenta y datos | Ajustes → Tus datos → Cuenta y datos |
| Menú lateral y barra → Enviar a Google Sheets | Chat → ⋮ → Enviar a Google Sheets |
| Menú lateral y barra → Archivar chat actual | Chat → ⋮ → Archivar chat |
| Menú lateral y barra → Chats archivados | Chat → ⋮ → Chats archivados |
| Menú lateral → Hoja cargada | Chat → ⋮ → Hoja cargada |
| Menú lateral y barra «Tus datos» → Exportar / importar | Ajustes → Tus datos → Exportar e importar |
| Menú lateral y barra → Configurar IA / Proveedor de IA | Ajustes → Asistente → Inteligencia artificial |
| Menú lateral → Finalizar día | Chat → ⋮ → Finalizar día |
| Menú lateral → Recuperar preparación (condicional) | Chat → ⋮ → Recuperar preparación (misma condición) |
| Panel → interruptor «Avisos de actividad y descanso» | Ajustes → Avisos; en el panel solo un aviso «Avisos desactivados · Activar» si hay descanso o duración |

## Project Structure

### Documentation (this feature)

```text
specs/004-trackia-experience/
├── spec.md
├── plan.md                 # este archivo
├── research.md             # decisiones y alternativas
├── data-model.md           # esquemas, migración v6, reglas
├── quickstart.md           # comandos y recorridos de validación
├── contracts/
│   ├── assistant-blocks.md # bloques trackia-* de la IA
│   ├── reminders-android.md# canales, MethodChannel, instantánea nativa
│   └── visual-tokens.md    # colores, contrastes, componentes
├── checklists/
│   └── requirements.md     # calidad de la especificación
└── tasks.md                # checklist de implementación y pruebas
```

### Source Code (repository root)

Archivos nuevos (N) y modificados (M) previstos. Rutas exactas; no crear otras sin documentarlo.

```text
lib/
├── application/
│   ├── assistant_context.dart        (N, 003 T020)
│   ├── progress_engine.dart          (N, evaluador puro)
│   ├── progress_service.dart         (N, orquesta engine + repositorios)
│   ├── reminder_scheduler.dart       (N, instantánea y programación)
│   └── rest_notifications.dart       (M, alarmStyle y estado de No molestar)
├── data/
│   ├── app_info.dart                 (N, nombre y versión)
│   ├── activity_template_repository.dart (N, plantillas propias y puntuales)
│   ├── chat_store.dart               (N, chats en SQLite + archivos)
│   ├── observation_repository.dart   (N, 003 T007)
│   ├── progress_repository.dart      (N, metas, logros, ajustes, recordatorios)
│   ├── trackia_migrations.dart       (M, v6)
│   ├── sqlite_workout_repository.dart(M, versión 6 y onUpgrade)
│   ├── ai_client.dart                (M, User-Agent)
│   ├── ai_model_catalog.dart         (M, User-Agent)
│   ├── chat_archive_store.dart       (M, delega en chat_store)
│   ├── companion_store.dart          (M, icono/color; borrado en cascada nuevo)
│   └── chatgpt_auth.dart             (M, registro de errores)
├── domain/
│   ├── activity.dart                 (M, campos tipados, userSet, segment*)
│   ├── companion.dart                (M, icono, color, prompt opcional)
│   ├── observation.dart              (N, registro puntual)
│   ├── progress.dart                 (N, Metric, GoalRule, AchievementRule, Unlock, Streak)
│   ├── reminder.dart                 (N)
│   └── assistant_blocks.dart         (N, parsers estrictos trackia-*)
└── ui/
    ├── theme.dart                    (M, tokens)
    ├── trackia_mark.dart             (N, logo CustomPainter)
    ├── timer_ring.dart               (N, anillo de tiempo)
    ├── settings.dart                 (N, Ajustes global)
    ├── notification_settings.dart    (N, Ajustes → Avisos)
    ├── companions.dart               (M, engranaje, tarjeta IA, icono/color, estado)
    ├── companion_settings.dart       (N, modo, juego, recordatorio)
    ├── companion_creator.dart        (N, a mano / con IA)
    ├── activity_builder.dart         (N, constructor de ritmo y campos)
    ├── activity_focus.dart           (M, barra compacta, botones, anillo, contadores)
    ├── progress_screen.dart          (N, progreso y logros)
    ├── activity_summary.dart         (N, resumen al terminar)
    ├── proposal_card.dart            (N, tarjetas Aplicar/Ignorar)
    ├── chat/                         (N, piezas extraídas de assistant_chat.dart en T096)
    ├── assistant_chat.dart           (M, sin menú lateral, ⋮, eventos, propuestas)
    ├── welcome.dart                  (M, logo y casilla)
    └── app.dart                      (M, colores)
android/app/
├── build.gradle.kts                  (M, R8 en release; T098)
└── proguard-rules.pro                (N, T098)
android/app/src/main/
├── AndroidManifest.xml               (M, receptor de arranque y de recordatorios)
└── kotlin/com/gymia/app/
    ├── RestNotifications.kt          (M, canal alarma, No molestar, teal)
    ├── ReminderReceiver.kt           (N)
    ├── BootReceiver.kt               (N)
    └── MainActivity.kt               (M, métodos nuevos del canal)
test/ … integration_test/ …           (N/M, ver tasks.md)
docs/0.3.32-…md …                     (N, notas por entrega)
```

**Structure Decision**: se mantiene la estructura actual `lib/{domain,data,application,ui}`.
El número de versión de cada entrega sube en `pubspec.yaml` (0.3.32+35 en adelante) solo cuando
el propietario lo pida; las tareas no cambian la versión.

## Orden y dependencias

```text
Fase 0  Base y salvaguardas (T001–T006) ─────────────────────────────┐
Fase 1  US1 Avisos con No molestar (T007–T014)        ← independiente │
Fase 2  US4 Identidad visual (T015–T026)              ← independiente │
Fase 3  US2 Ajustes globales y menús (T027–T034)      ← tras Fase 2   │
Fase 4  US3 Actividades abiertas (T035–T048)          ← tras Fase 0   │
Fase 5  US5 Edición manual vs IA (T049–T055)          ← tras Fase 4   │
Fase 6  US6 Recordatorio o juego (T056–T066)          ← tras Fase 4   │
Fase 7  US7 Metas, rachas y logros (T067–T078)        ← tras Fase 6   │
Fase 8  US9 Chats fuera de secure storage (T079–T084) ← tras Fase 0   │
Fase 9  US8 Creación asistida (T085–T091)             ← tras Fase 7   │
Fase 10 US10 Mantenimiento (T092–T099)                ← al final      │
Fase 11 US11 IA por acompañante (T100–T103, opcional) ← al final      │
Fase 12 Cierre (T104–T107) ──────────────────────────────────────────┘
```

Fases 1, 2 y 8 pueden hacerse en cualquier orden tras la Fase 0. La migración v6 (T004–T005)
agrupa todas las tablas nuevas para hacer una sola migración de esquema.

## Guía para el agente implementador

Estas reglas son obligatorias. Existen para que cualquier agente obtenga el mismo resultado.

1. **Antes de cada tarea**: leer la tarea completa, los FR que cita, el contrato que cita y los
   archivos que va a tocar. Si un hecho de «Estado verificado» ya no es cierto, parar y anotarlo
   en `tasks.md` bajo la tarea («Bloqueo: …») en lugar de improvisar.
2. **Pruebas primero** cuando la tarea las incluye: escribir la prueba, ejecutarla y ver que falla
   por el motivo esperado; luego implementar.
3. **Comandos** (desde la raíz del repo; `scripts/flutter-local.sh` fija `JAVA_HOME` y `ANDROID_HOME`
   y, tras T001, usa Flutter 3.47):
   - `./scripts/flutter-local.sh analyze`
   - `./scripts/flutter-local.sh test`
   - pruebas de integración: ver [quickstart.md](quickstart.md).
   - validación del SDD: `python3 scripts/validate-sdd-004.py`.
4. **Definición de hecho de una tarea**: código + pruebas de la tarea en verde + `flutter analyze`
   sin avisos nuevos respecto a la línea base (11 `info`) + `flutter test` completo en verde +
   casilla marcada en `tasks.md` con una línea de evidencia (comando y resultado).
5. **Definición de hecho de una fase**: todas sus tareas hechas, checkpoint de la fase comprobado,
   nota en `docs/0.3.32-<tema>.md` (formato de las notas existentes) y un commit con mensaje en
   español `feat:`/`fix:`/`refactor:`/`test:`/`docs:` que cite las tareas (por ejemplo `T007–T014`).
6. **Prohibido**: tocar `.signing/`, `android/key.properties`, `*.jks` o claves; cambiar
   `applicationId`, nombres de paquete, claves de almacenamiento existentes o IDs de protocolo
   (`gymia-activity`, `gymia-timing`, `gymia_rest`); borrar datos de usuario sin migración
   verificada; añadir dependencias no indicadas; desactivar o borrar pruebas existentes para que
   pasen; marcar una casilla sin evidencia; hacer push o crear PR sin que el propietario lo pida.
7. **Textos**: todo texto visible en español, con tildes correctas, sin «¡», sin «por favor»,
   botones de 1–3 palabras con verbo («Conectar», «Nueva actividad»).
8. **Tareas `[OWNER]`**: requieren el teléfono del propietario, el release firmado o una cuenta
   real. El agente prepara la prueba y las instrucciones en `quickstart.md`, y deja la casilla sin
   marcar con «Pendiente del propietario».
9. **Si una prueba existente falla por un cambio de texto o de menú previsto en este plan**,
   actualizarla en la misma tarea y explicarlo en la evidencia. Si falla por otro motivo, parar.
10. **No ampliar el alcance**: si se descubre trabajo útil fuera de las tareas, anotarlo al final de
    `tasks.md` en «Hallazgos fuera de alcance» y seguir.

## Riesgos

| Riesgo | Mitigación |
|---|---|
| Los fabricantes (Xiaomi/HyperOS) tratan No molestar distinto | Tarea `[OWNER]` T014 en el teléfono real; preferencia para desactivar el modo alarma |
| Reorganizar menús rompe pruebas de integración que buscan textos o claves | T032 busca y actualiza todas las referencias; T033 comprueba el mapa; mantener `Key` existentes |
| Migración de chats con adjuntos grandes | Copia por partes, verificación por hash, borrado solo tras verificar, reintento idempotente (T079–T083) |
| R8 rompe `llama_cpp_dart` o plugins | Reglas `proguard` explícitas y prueba de humo `[OWNER]`; revertir si falla (T098–T099) |
| La IA propone reglas absurdas | Esquema estricto y límites numéricos en `contracts/assistant-blocks.md` (T085) |
| Rachas incorrectas en cambios de zona horaria | Días calculados con la fecha local guardada; pruebas con zonas distintas (T068) |
| `scripts/flutter-local.sh` usa un Flutter que no compila el proyecto | T001 lo corrige antes de cualquier otra tarea |

## Complexity Tracking

| Añadido | Por qué hace falta | Alternativa más simple descartada |
|---|---|---|
| Migración v6 con 9 tablas | Metas, logros, recordatorios, ajustes y chats necesitan persistencia consultable y aislada por perfil | Guardarlo en secure storage: lo prohíbe `CLAUDE.md` para datos grandes y es lo que US9 corrige |
| Instantánea nativa para recordatorios | El receptor de alarmas no puede ejecutar Dart ni abrir SQLite de forma segura en frío | WorkManager con motor Dart en segundo plano: añade dependencia y consumo |
| Cuatro bloques `trackia-*` | Cada uno tiene un efecto distinto y debe validarse por separado | Un bloque genérico: más ambiguo y difícil de validar |

# Data Model: TrackIA — experiencia, actividades abiertas y juego opcional

Estado: diseño. Nada de este modelo está implementado. Todo cambio es **aditivo**: no se
renombran ni borran columnas, tablas o claves existentes, y se conservan los IDs.

## 1. Ampliación de `ActivityDefinition` (JSON en `activities.definition`)

Clase: `lib/domain/activity.dart`. Claves nuevas, todas opcionales. `toJson` solo las escribe
si tienen valor, para que las definiciones antiguas se serialicen igual que hoy.

| Clave | Tipo | Regla |
|---|---|---|
| `activityKey` | texto | Clave estable de la actividad. Si falta al cargar, se calcula: `name.trim()`, espacios múltiples → uno, minúsculas. `renameActivity` **no** la cambia |
| `segmentSingular` | texto 1–24 | Nombre del tramo («tiempo», «pomodoro») |
| `segmentPlural` | texto 1–24 | Obligatorio si existe `segmentSingular` |
| `userSet` | lista de texto | Propiedades fijadas a mano. Valores permitidos: `name`, `restSeconds`, `activitySeconds`, `targetSets`, `targetCycles`, `segmentSingular`, `segmentPlural`, `instructions`, `field:<key>`. Sin duplicados |

Ampliación de cada mapa de `fields` (hoy exactamente `key`, `label`, `unit`):

| Clave | Tipo | Regla |
|---|---|---|
| `type` | `number` · `scale` · `text` · `choice` · `boolean` | Opcional. Ausente = campo heredado («solo notas») |
| `aggregate` | `sum` · `max` · `avg` · `distinct` · `countTrue` · `none` | Solo con `type`. Compatibilidad en `research.md` D3; por defecto según tipo |
| `options` | lista de texto 1–40, máx. 20, sin duplicados | Obligatoria y solo para `choice` |
| `min`, `max` | enteros | Solo `scale`; `1 ≤ min < max ≤ 10`; por defecto 1 y 5 |
| `countSingular`, `countPlural` | texto 1–40 | Opcionales, para títulos de logros de `countTrue` y `distinct` («libro terminado» / «libros terminados») |

Validación (en el constructor, como hoy): las claves de cada campo deben ser un subconjunto de
`{key, label, unit, type, aggregate, options, min, max, countSingular, countPlural}` y contener
`key`, `label` y `unit`. El analizador `ActivityDefinition.proposal` (bloque `gymia-activity`)
acepta además `segmentSingular`, `segmentPlural` y los campos ampliados; **no** acepta
`userSet` ni `activityKey` (solo los pone la app).

Valores (`activity_messages.metrics`): sin cambios de formato. **Semántica fijada**: cada valor es la
cantidad informada en ese mensaje, no un total acumulado. Para `sum`, `distinct` y `countTrue` se
combinan todos los mensajes; para `max` y `avg`, cada mensaje es una observación individual. El
contexto de la IA (`assistant_context.dart`) lo indica con la frase: «En los campos que se suman,
anota solo la cantidad de este mensaje, nunca el total acumulado.» Un valor de un campo `scale` debe
ser entero entre `min` y `max`; de `choice`, una de `options`; de `boolean`, booleano. La
validación se añade en `interpretActivityMessage` y en el guardado manual. Un valor ausente no
existe en el mapa (no se guarda `0` ni `null`).

## 2. `Companion` (JSON en secure storage, clave `trackia.companions.v1`)

Clase: `lib/domain/companion.dart`. Claves nuevas opcionales:

| Clave | Regla | Por defecto |
|---|---|---|
| `icon` | uno de los IDs de `contracts/visual-tokens.md` → «Iconos de acompañante» | `gymbro` → `barbell`, `enfoque` → `hourglass`, `calma` → `leaf`, `diario` → `notebook`, otros → `sparkles` |
| `color` | uno de los IDs de color de acompañante del mismo contrato | `gymbro` → `orange`, `enfoque` → `teal`, `calma` → `green`, `diario` → `amber`, otros → `teal` |

`prompt` pasa a admitir cadena vacía (0–8000). Si está vacío, `assistant_context.dart` usa:
«Acompaña al usuario con un tono cercano y claro. Ayúdale a registrar lo que hace sin inventar datos.»

## 3. Migración v6 (`lib/data/trackia_migrations.dart`)

Subir la versión de la BD de 5 a 6 en `lib/data/sqlite_workout_repository.dart` (≈ línea 299) y
añadir el paso en `onUpgrade` y en la creación desde cero. Antes de migrar, crear respaldo con el
mismo mecanismo de `_backupBeforeTrackiaV5` (archivo `.pre-trackia-v6.json`). Todas las tablas
llevan `profile_id`; ninguna usa el nombre visible como identidad.

```sql
CREATE TABLE trackia_observations (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL, space_id TEXT NOT NULL, companion_id TEXT NOT NULL,
  run_id TEXT,                                  -- siempre NULL en 004 (registro puntual)
  template_id TEXT,                             -- plantilla que lo originó
  definition_snapshot TEXT NOT NULL,            -- JSON de la definición en ese momento
  original TEXT NOT NULL,                       -- texto o resumen de lo introducido
  values_json TEXT NOT NULL,                    -- mismas reglas que metrics
  provenance TEXT NOT NULL CHECK(provenance IN ('user','assistant','import')),
  revision INTEGER NOT NULL CHECK(revision > 0),
  supersedes_id TEXT REFERENCES trackia_observations(id),
  observed_at INTEGER NOT NULL, recorded_at INTEGER NOT NULL, local_day TEXT NOT NULL,
  FOREIGN KEY(profile_id, space_id) REFERENCES trackia_spaces(profile_id, id));
CREATE INDEX observation_companion_day ON trackia_observations(profile_id, companion_id, local_day);

CREATE TABLE trackia_activity_templates (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
  definition TEXT NOT NULL,                     -- JSON ActivityDefinition
  instant INTEGER NOT NULL CHECK(instant IN (0,1)),
  origin TEXT NOT NULL CHECK(origin IN ('user','assistant','template')),
  created_at INTEGER NOT NULL, archived_at INTEGER);

CREATE TABLE trackia_companion_settings (
  profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
  mode TEXT NOT NULL CHECK(mode IN ('reminder','game')) DEFAULT 'reminder',
  goals_enabled INTEGER NOT NULL DEFAULT 1, streaks_enabled INTEGER NOT NULL DEFAULT 1,
  achievements_enabled INTEGER NOT NULL DEFAULT 1, cheers_enabled INTEGER NOT NULL DEFAULT 1,
  free_days_per_week INTEGER NOT NULL DEFAULT 1 CHECK(free_days_per_week BETWEEN 0 AND 3),
  dismissed_suggestions TEXT NOT NULL DEFAULT '[]',
  ai_override TEXT,                             -- US11: {"provider":…, "modelId":…}; sin claves
  revision INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL,
  PRIMARY KEY(profile_id, companion_id));

CREATE TABLE trackia_reminders (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
  days INTEGER NOT NULL CHECK(days BETWEEN 1 AND 127),       -- bit 0 = lunes … bit 6 = domingo
  window_start_min INTEGER NOT NULL CHECK(window_start_min BETWEEN 0 AND 1439),
  window_end_min INTEGER NOT NULL CHECK(window_end_min BETWEEN 1 AND 1440),
  last_call_min INTEGER,                                      -- entre inicio y fin, o NULL
  tone TEXT NOT NULL CHECK(tone IN ('neutral','cheer')) DEFAULT 'neutral',
  minimum TEXT,                                               -- JSON {"metric":…, "value":n}
  enabled INTEGER NOT NULL DEFAULT 1, paused_at INTEGER,
  revision INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL,
  CHECK(window_start_min < window_end_min));

CREATE TABLE trackia_goals (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, activity_key TEXT,
  metric TEXT NOT NULL,                                       -- JSON Metric (sección 4)
  period TEXT NOT NULL CHECK(period IN ('day','week')),
  target REAL NOT NULL CHECK(target > 0), minimum REAL CHECK(minimum > 0),
  origin TEXT NOT NULL CHECK(origin IN ('user','assistant','template')),
  created_at INTEGER NOT NULL, archived_at INTEGER);

CREATE TABLE trackia_achievements (
  id TEXT PRIMARY KEY,
  profile_id TEXT NOT NULL, companion_id TEXT NOT NULL, activity_key TEXT,
  rule TEXT NOT NULL, rule_hash TEXT NOT NULL,                -- JSON AchievementRule y su sha256
  title TEXT NOT NULL, icon TEXT NOT NULL,
  origin TEXT NOT NULL CHECK(origin IN ('generated','user','assistant')),
  created_at INTEGER NOT NULL, archived_at INTEGER,
  UNIQUE(profile_id, companion_id, rule_hash));

CREATE TABLE trackia_achievement_unlocks (
  id TEXT PRIMARY KEY,
  achievement_id TEXT NOT NULL UNIQUE REFERENCES trackia_achievements(id) ON DELETE CASCADE,
  unlocked_at INTEGER NOT NULL, value REAL NOT NULL,
  source_activity_id TEXT, source_observation_id TEXT);

CREATE TABLE trackia_chats (
  profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
  payload TEXT NOT NULL,                                      -- JSON del chat, adjuntos por referencia
  legacy_key TEXT, verified_at INTEGER, updated_at INTEGER NOT NULL,
  PRIMARY KEY(profile_id, companion_id));

CREATE TABLE trackia_chat_archives (
  id TEXT PRIMARY KEY,                                        -- mismo id que gymia.ai.archive.v1.<id>
  profile_id TEXT NOT NULL, companion_id TEXT NOT NULL,
  payload TEXT NOT NULL, legacy_key TEXT, verified_at INTEGER, created_at INTEGER NOT NULL);
```

`local_day` es `YYYY-MM-DD` en la zona local del dispositivo en el momento de `observed_at`.
Para las actividades con tramos, el día es el de `activities.finished_at` (o el del primer tramo
si no ha terminado), calculado al leer; no se añade columna a `activities`.

**Copia de seguridad**: esta entrega no cambia el formato `gymia-backup` v3. Las tablas nuevas no
entran en `_backupTables`; se documenta como pendiente (003 T042 versiona la copia).

**Borrado de acompañante** (`CompanionStore.delete`): además de lo actual, borrar en una transacción
sus filas de `trackia_companion_settings`, `trackia_reminders`, `trackia_goals`,
`trackia_achievements` (y por cascada sus desbloqueos), `trackia_activity_templates`,
`trackia_chats` y `trackia_chat_archives`. **No** borrar `trackia_observations` ni actividades.

## 4. Reglas de progreso (`lib/domain/progress.dart`)

### Metric

```json
{"source": "time" | "sessions" | "field",
 "field": "<key>",                       // solo con source=field
 "aggregate": "sum" | "max" | "avg" | "distinct" | "countTrue",   // solo con source=field
 "per": "session" | "day" | "week" | "total"}
```

- `time`: suma de duraciones de tramos terminados (segundos).
- `sessions`: actividades terminadas + observaciones (cada una cuenta 1).
- `field`: valores del campo en `activity_messages.metrics` y `trackia_observations.values_json`
  de las actividades del ámbito (`companion_id` y, si existe, `activity_key`). Solo cuentan los
  campos con `type`; los heredados se ignoran.
- Revisiones: de una cadena `supersedes_id` solo cuenta la última revisión.

### GoalRule

`metric` con `per` igual al `period` de la meta; cumplida si `valor ≥ target`; «mínimo cumplido» si
`valor ≥ minimum`. Sin meta, un día cuenta como cumplido si tiene al menos una sesión.

### AchievementRule

```json
{"kind": "threshold", "metric": Metric, "threshold": n}
{"kind": "streak", "threshold": n}
```

Se desbloquea una sola vez cuando el valor calculado alcanza el umbral. No se retira al corregir datos.

### Familias generadas (FR-033)

| Origen | Logros (umbral → título) |
|---|---|
| Universal · sesiones | 1 → «Primera vez»; 10 → «10 sesiones»; 50 → «50 sesiones»; 100 → «100 sesiones» |
| Universal · tiempo (horas) | 1, 10, 50, 100 → «{n} h en {acompañante}» |
| Universal · racha | 3, 7, 30, 100 → «Racha de {n} días» |
| Campo `sum` | 10, 100, 500, 1000, 5000 → «{n} {label en minúscula}» (por ejemplo «1.000 páginas») |
| Campo `distinct` | 3, 10, 25 → «{n} {countPlural}» o «{label}: {n} distintos» |
| Campo `countTrue` | 1, 5, 25 → «{n} {countSingular/countPlural}» o «{label}: {n}» |
| Campo `max`, `avg` | Sin logros; se muestran como récord y promedio en Progreso |

Números con separador de miles español (`1.000`). Los títulos generados se pueden editar; editarlos no
cambia la regla. Crear la misma regla dos veces no duplica (`UNIQUE rule_hash`).

### Racha

Algoritmo en `research.md` D14. Entrada: días cumplidos por `local_day`, `free_days_per_week`, hoy.
Salida: `current`, `best`, `freeDaysUsedThisWeek`.

## 5. Recordatorios (`lib/domain/reminder.dart`)

Campos de `trackia_reminders`. Validaciones: `days ≠ 0`; `window_start_min < window_end_min`;
`last_call_min` nulo o estrictamente entre inicio y fin; como máximo un recordatorio activo por
acompañante en esta entrega. Pausa automática: si hay 7 días seguidos programados sin cumplir,
`paused_at = ahora`; registrar una sesión o pulsar «Reanudar» lo pone a `NULL`.

La instantánea nativa se describe en `contracts/reminders-android.md`.

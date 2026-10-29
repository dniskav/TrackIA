# Contrato: bloques de la IA `trackia-*`

Amplía [003/contracts/assistant-proposals.md](../../003-trackia-platform/contracts/assistant-proposals.md).
Los bloques `gymia-activity` y `gymia-timing` siguen igual, salvo la ampliación de campos
descrita en `data-model.md` §1 y la regla de candados de este contrato.

## Reglas comunes

1. Un bloque es un fragmento Markdown con lenguaje `trackia-<tipo>` y JSON dentro:
   ````
   ```trackia-goal
   {"metric": {"source": "field", "field": "pages", "aggregate": "sum", "per": "day"}, "period": "day", "target": 20, "minimum": 5}
   ```
   ````
2. Se acepta **un** bloque de cada tipo por respuesta. Dos o más del mismo tipo → se ignoran todos de ese tipo.
3. El JSON debe ser un objeto con exactamente las claves permitidas (obligatorias + opcionales).
   Cualquier clave desconocida, tipo incorrecto o valor fuera de rango rechaza el bloque completo.
4. Un bloque nunca se aplica solo: se muestra como tarjeta con acciones del usuario. Solo la acción
   del usuario persiste algo.
5. La app asigna `profileId`, `companionId`, `origin = 'assistant'` e IDs. El bloque no puede traerlos.
6. Al rechazar un bloque se conserva el texto de la respuesta y se añade bajo ella «La propuesta no es
   válida y no se aplicó.» Se registra el motivo con `debugPrint` (sin contenido del usuario).
7. Los parsers viven en `lib/domain/assistant_blocks.dart` y devuelven `null` si el bloque es inválido.
   Pruebas en `test/assistant_blocks_test.dart` (válido, cada clave obligatoria ausente, clave extra,
   límite inferior y superior, dos bloques, JSON roto).

## Candados (aplica también a `gymia-activity` y `gymia-timing`)

Si un bloque cambia una propiedad incluida en `userSet` de la actividad abierta, la app no la cambia:
muestra la tarjeta «Propuesta de la IA · {propiedad}: {actual} → {propuesto}» con **Aplicar** e
**Ignorar**. Aplicar actualiza el valor y lo mantiene en `userSet`. Las propiedades no fijadas siguen
el flujo actual. Si hay un tramo en marcha, ningún cambio de tiempos afecta a ese tramo (el cambio se
guarda para los siguientes).

## `trackia-companion`

Uso: solo en la pantalla «Crear acompañante → Con ayuda de la IA».

| Clave | Obligatoria | Tipo y límites |
|---|---|---|
| `name` | sí | texto 1–40 |
| `description` | no | texto 0–80 |
| `prompt` | no | texto 0–2000 |
| `icon` | no | ID de `visual-tokens.md` → iconos |
| `color` | no | ID de `visual-tokens.md` → colores de acompañante |
| `mode` | sí | `reminder` · `goals` · `game` (`goals` = modo Juego con logros desactivados) |
| `activity` | no | objeto con las claves de `gymia-activity` ampliadas + `instant` (booleano) |
| `goal` | no | objeto `trackia-goal` |
| `reminder` | no | objeto: `days` (lista de 1–7 de `mon`…`sun`), `start` y `end` (`HH:MM`), `lastCall` (`HH:MM`, opcional), `tone` (`neutral` · `cheer`) |

Tarjeta: ficha con nombre, qué anotas, meta, modo y aviso; acciones **Crear**, **Editar** (abre el
constructor relleno) y **Descartar**. Crear guarda en este orden y en una transacción lógica:
acompañante → ajustes → plantilla de actividad → meta → recordatorio → logros generados. Si un paso
falla, se deshacen los anteriores y se muestra el error.

## `trackia-goal`

| Clave | Obligatoria | Límites |
|---|---|---|
| `metric` | sí | Metric de `data-model.md` §4 con `per` = `period` |
| `period` | sí | `day` · `week` |
| `target` | sí | número > 0 y ≤ 100000 |
| `minimum` | no | número > 0 y < `target` |
| `activityKey` | no | debe existir en el acompañante |

Tarjeta: «Meta propuesta: {target} {unidad} al {día/semana}» con **Añadir** / **Ignorar**.

## `trackia-achievement`

| Clave | Obligatoria | Límites |
|---|---|---|
| `title` | sí | texto 1–60 |
| `rule` | sí | AchievementRule de `data-model.md` §4; `threshold` ≤ 1000000 |
| `icon` | no | ID de icono de logro de `visual-tokens.md` |
| `activityKey` | no | debe existir en el acompañante |

Tarjeta: «Logro propuesto: {title}» con la regla en texto legible («Tiempo ≥ 15 min por día, 5 días
por semana») y **Añadir** / **Ignorar**. Añadir crea la regla; nunca un desbloqueo.

## `trackia-reminder-copy`

Variantes de texto para recordatorios en el tono del acompañante.

| Clave | Obligatoria | Límites |
|---|---|---|
| `windowStart` | no | lista de 1–5 textos de 1–140 caracteres |
| `lastCall` | no | lista de 1–5 textos de 1–140 caracteres |
| `inactive` | no | lista de 1–5 textos de 1–140 caracteres |

Marcadores permitidos: `{dias}`, `{faltan}`, `{racha}`, `{minimo}`, `{meta}`, `{nombre}`. Cualquier
otra llave `{…}` rechaza el bloque. Tarjeta: muestra dos ejemplos ya rellenados con datos reales y
**Usar estos textos** / **Ignorar**.

## Contexto del sistema

`lib/application/assistant_context.dart` añade la descripción de cada bloque solo donde se admite:

| Pantalla | Bloques descritos |
|---|---|
| Chat de acompañante en modo Recordatorio | `gymia-activity`, `gymia-timing` (como hoy) |
| Chat de acompañante en modo Juego | lo anterior + `trackia-goal`, `trackia-achievement`, `trackia-reminder-copy` |
| Crear acompañante con IA | solo `trackia-companion` |

Instrucción fija añadida en todos los casos: «No afirmes que el usuario desbloqueó un logro o cumplió
una meta: la app lo calcula y te lo indica en el contexto.» El contexto incluye el estado calculado
(racha actual, meta de hoy y su progreso, logros desbloqueados hoy) como datos, no como instrucciones.

## Creación asistida: guion de la IA

Instrucción de sistema para la pantalla de creación (texto exacto a incluir):

«Ayuda a crear un acompañante de seguimiento. Haz como máximo tres preguntas breves, de una en una:
qué quiere seguir, con qué frecuencia y si quiere aviso. Después ofrece estos tres niveles con una
línea cada uno: Solo recordatorio; Metas y rachas (recomendado); Juego completo con logros. Cuando el
usuario elija, responde con un único bloque trackia-companion. No inventes datos del usuario.»

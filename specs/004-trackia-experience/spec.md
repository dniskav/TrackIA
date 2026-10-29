# Feature Specification: TrackIA — experiencia, actividades abiertas y juego opcional

**Feature Branch**: `004-trackia-experience` (directorio de especificación; no exige rama git propia)
**Created**: 2026-10-29
**Status**: Draft — diseño acordado con el propietario; nada de esta especificación está implementado
**Input**: Conversación de diseño del 2026-10-29 sobre look & feel, usabilidad, actividades
manuales para cualquier seguimiento, gamificación opcional, recordatorios, avisos con
No molestar, creación de acompañantes asistida por IA y hallazgos pendientes de `REVISION.md`.

**Relación con 003**: esta especificación amplía `specs/003-trackia-platform/` y reutiliza
sus tareas pendientes donde coinciden (ver `plan.md` → «Relación con 003»). La
constitución `.specify/memory/constitution.md` (v1.1.0) rige todo el trabajo.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Oír el fin del descanso con No molestar activo (Priority: P1)

Entreno a las 6:00 con el móvil en No molestar. Cuando termina un descanso o un tramo
con duración, el aviso debe sonar y vibrar igualmente, como una alarma de cocina. Los
recordatorios de hábitos, en cambio, no deben saltarse No molestar.

**Why this priority**: es el único fallo real que hoy afecta al uso diario del propietario.
Es pequeño y no depende de ninguna otra historia.

**Independent Test**: activar No molestar en modo Prioridad en un emulador o en el teléfono,
iniciar una actividad con 10 s de descanso, pulsar Parar y comprobar que el aviso de fin
de descanso suena y vibra. Comprobar en Ajustes → Avisos que la app indica que
No molestar está activo.

**Acceptance Scenarios**:

1. **Given** avisos activados y «Tratar como alarma» activado, **When** termina un descanso
   con No molestar en modo Prioridad (alarmas permitidas), **Then** el aviso suena y vibra.
2. **Given** «Tratar como alarma» desactivado, **When** termina un descanso con
   No molestar, **Then** el aviso se publica sin saltarse No molestar (comportamiento actual).
3. **Given** No molestar activo, **When** abro Ajustes → Avisos, **Then** veo un aviso que
   explica que ahora mismo los avisos normales no sonarían y un botón para abrir los
   ajustes del sistema.
4. **Given** No molestar en «Silencio total», **When** termina un descanso, **Then** la app
   no promete sonido: la pantalla de Avisos explica que Android bloquea también las alarmas.

---

### User Story 2 - Configurar la app sin entrar a un acompañante (Priority: P1)

Desde el tablero de acompañantes quiero llegar a los ajustes globales (IA, cuenta, datos,
avisos, apariencia, ayuda) sin abrir ningún chat. Si la IA no está conectada, el tablero
me lo dice y me lleva directo a configurarla.

**Why this priority**: hoy configurar el modelo exige entrar a un acompañante, lo que confunde
en el primer uso.

**Independent Test**: con un perfil sin IA configurada, abrir la app, ver en el tablero la
tarjeta «IA sin conectar», pulsar «Conectar», configurar un proveedor y volver al tablero
sin haber abierto ningún acompañante.

**Acceptance Scenarios**:

1. **Given** el tablero, **When** pulso el engranaje, **Then** se abre Ajustes con las secciones
   Asistente, Tus datos y App, cada fila con su estado actual.
2. **Given** IA no configurada o no verificada, **When** veo el tablero, **Then** aparece la
   tarjeta «IA sin conectar» con el botón «Conectar», que abre la configuración de IA.
3. **Given** IA verificada, **When** veo el tablero, **Then** la tarjeta no aparece.
4. **Given** estoy en el chat de un acompañante, **When** abro el menú ⋮, **Then** solo veo
   acciones de ese acompañante (archivar, chats archivados, hoja cargada, enviar a Sheets,
   finalizar día, recuperar preparación y rutinas e historial).

---

### User Story 3 - Registrar cualquier actividad a mano (Priority: P1)

Quiero seguir cualquier cosa (leer, estudiar, beber agua, un partido, yoga, un pomodoro)
sin IA y sin vocabulario de gimnasio. Elijo cómo ocurre (puntual, libre, con duración o por
tramos), qué anoto (campos con tipo) y, si quiero, cómo cuenta cada campo.

**Why this priority**: la constitución exige que los controles locales funcionen sin IA (II)
y que las actividades sean abiertas (I). Hoy existe un camino manual (botón ⇄ del panel →
«Nueva actividad»), pero está escondido y usa palabras de gimnasio.

**Independent Test**: sin IA configurada, desde un acompañante nuevo, crear «Leer» libre con
los campos Páginas (número, sumar) y Libro (texto, contar distintos), iniciar, parar,
anotar 18 páginas y ver el registro guardado tras reiniciar la app. Crear «Beber agua»
puntual y registrar un vaso sin iniciar ningún cronómetro.

**Acceptance Scenarios**:

1. **Given** un acompañante sin actividad, **When** miro el panel, **Then** veo una barra compacta
   con el botón «Nueva actividad» visible sin necesidad de IA.
2. **Given** el constructor, **When** elijo el ritmo, **Then** puedo elegir Puntual, Libre,
   Con duración o Por tramos, y solo se muestran los campos pertinentes a ese ritmo.
3. **Given** Por tramos, **When** guardo, **Then** puedo nombrar el tramo (por ejemplo «tiempo»,
   «pomodoro», «serie») y el panel usa ese nombre en lugar de «serie» o «tramo».
4. **Given** un campo, **When** lo añado, **Then** elijo su tipo (número, texto, sí o no,
   opción, escala) y cómo cuenta (sumar, mejor marca, promedio, contar distintos, contar síes
   o solo notas).
5. **Given** una actividad con campos numéricos, **When** está en marcha, **Then** puedo anotar
   valores con controles rápidos (+/−) además de escribir o dictar.
6. **Given** una actividad puntual, **When** registro un valor, **Then** se guarda con fecha,
   original y procedencia sin crear tramos ni cronómetro.
7. **Given** actividades creadas antes de esta entrega, **When** abro la app actualizada, **Then**
   conservan su comportamiento, IDs y datos; sus campos sin tipo se tratan como «solo notas».

---

### User Story 4 - Una identidad visual que sale del icono (Priority: P1)

La app debe verse como su icono: teal del reloj, flecha naranja a carmín. Los botones deben
leerse con facilidad y el color debe decir qué hace cada uno. Cada acompañante tiene su
icono y su color. El panel de actividad solo ocupa espacio cuando hace falta.

**Why this priority**: el propietario lo pidió explícitamente; además corrige problemas de
lectura (texto negro sobre naranja) y de jerarquía visual.

**Independent Test**: comparar capturas antes/después en claro y oscuro de tablero, chat sin
actividad, actividad en marcha, Ajustes y bienvenida; comprobar contraste con los valores
de `contracts/visual-tokens.md`.

**Acceptance Scenarios**:

1. **Given** una actividad preparada, **When** veo el panel, **Then** «Iniciar» es teal con texto
   blanco en negrita; en marcha, «Parar» es carmín con texto blanco en negrita; las acciones
   secundarias son botones con contorno.
2. **Given** un tramo con duración en marcha, **When** veo el panel, **Then** el tiempo se muestra
   dentro de un anillo con las cuatro marcas del reloj y un arco de progreso con el degradado
   naranja → rojo → carmín.
3. **Given** el tablero, **When** lo veo, **Then** cada acompañante muestra su icono y su color;
   los cuatro sugeridos tienen valores por defecto y los nuevos permiten elegirlos.
4. **Given** la bienvenida en modo oscuro, **When** se muestra el logo, **Then** no aparece un
   recuadro blanco: el logo se dibuja con colores del tema.
5. **Given** la primera apertura, **When** completo u omito la bienvenida sin tocar la casilla,
   **Then** no vuelve a mostrarse automáticamente; sigue disponible en Ajustes → Ayuda.
6. **Given** el chat de un acompañante, **When** lo veo, **Then** la barra superior muestra
   volver, icono y nombre del acompañante (que abre un selector para cambiar de acompañante)
   y el menú ⋮; no hay menú lateral dentro del chat.

---

### User Story 5 - Editar a mano sin que la IA lo pise (Priority: P2)

Si cambio algo de la actividad a mano (nombre, descanso, duración, tramos, campos), la IA lo
sabe y no lo sobrescribe: solo propone, y yo decido. Con una actividad en marcha, ninguna
propuesta cambia el tramo actual.

**Why this priority**: es la integración entre el control manual y la IA como centro.
Depende de US3.

**Independent Test**: con IA simulada, fijar a mano el descanso en 120 s, recibir una respuesta
con `gymia-timing` que propone 150 s y comprobar que el descanso sigue en 120 s y aparece una
tarjeta «Aplicar / Ignorar».

**Acceptance Scenarios**:

1. **Given** un campo editado a mano, **When** la IA propone otro valor para ese campo, **Then**
   la app muestra una propuesta Aplicar/Ignorar y no cambia el valor hasta que pulso Aplicar.
2. **Given** un campo no editado a mano, **When** la IA propone un cambio, **Then** se mantiene
   el flujo actual de propuestas.
3. **Given** una edición manual, **When** se guarda, **Then** el chat muestra una línea neutra
   («Cambiaste el descanso a 120 s») y el contexto enviado a la IA la incluye.
4. **Given** un tramo en marcha, **When** llega una propuesta de tiempos, **Then** el tramo actual
   no cambia; la propuesta se aplica, si la acepto, desde el siguiente tramo.
5. **Given** un campo fijado, **When** toco su candado, **Then** deja de estar fijado.

---

### User Story 6 - Recordatorio o juego, por acompañante (Priority: P2)

Cada acompañante puede ser un simple recordatorio o sentirse como un juego. Los recordatorios
tienen una ventana horaria con un aviso al empezar y una «última llamada» antes de que
termine, y no llegan si ya cumplí.

**Why this priority**: motiva sin obligar; base de US7.

**Independent Test**: configurar Lectura con ventana 21:00–23:00 y última llamada a las 22:30,
avanzar el reloj en una prueba controlada, comprobar los dos avisos; registrar lectura antes
de las 22:30 y comprobar que la última llamada no se publica.

**Acceptance Scenarios**:

1. **Given** un acompañante, **When** abro su configuración, **Then** elijo modo Recordatorio o
   Juego y, en Juego, activo o desactivo por separado metas, rachas, logros y mensajes de ánimo.
2. **Given** un recordatorio con días, ventana y tono, **When** llega el inicio de la ventana en
   un día elegido y aún no cumplí, **Then** recibo un aviso; **When** llega la última llamada y
   sigo sin cumplir, **Then** recibo un segundo aviso que menciona el mínimo del día.
3. **Given** ya cumplí hoy, **When** llega cualquier hora de aviso, **Then** no se publica nada.
4. **Given** tono Motivador, **When** llevo N días sin actividad, **Then** el texto usa N real
   (por ejemplo «Amigo, llevamos 3 días sin entrenar»), calculado sin IA ni red.
5. **Given** siete días seguidos sin cumplir con avisos, **When** se evalúa el octavo, **Then**
   los avisos de ese acompañante se pausan y el tablero muestra «Recordatorios en pausa».
6. **Given** No molestar activo, **When** toca un recordatorio de hábito, **Then** respeta
   No molestar (no usa el canal de alarma de US1).
7. **Given** el móvil se reinicia, **When** vuelve a encenderse, **Then** los recordatorios
   siguen programados.

---

### User Story 7 - Metas, rachas y logros para cualquier actividad (Priority: P2)

En modo Juego, la app genera metas, rachas, logros y récords a partir de los campos que yo
definí (por ejemplo páginas, libros, tiempo leyendo), sin que la actividad estuviera
prevista en el diseño. La app mide y desbloquea; la IA solo propone y comenta.

**Why this priority**: es la gamificación pedida, y depende de US3 (campos con tipo y forma de
contar) y US6 (modo).

**Independent Test**: con un acompañante «Leer» en modo Juego, registrar sesiones con páginas
en días consecutivos con reloj controlado y comprobar anillo de meta diaria, racha con día
libre, logro «100 páginas» y récord diario; al terminar, ver la pantalla de resumen.

**Acceptance Scenarios**:

1. **Given** un campo número con «sumar», **When** guardo la actividad, **Then** la app crea los
   logros escalonados de ese campo con su etiqueta y unidad (por ejemplo «100 páginas»,
   «1.000 páginas») y el récord por día.
2. **Given** cualquier actividad, **When** acumulo tiempo y días, **Then** existen sin configurar
   logros universales de tiempo total, sesiones y racha.
3. **Given** una meta diaria con mínimo del día, **When** cumplo solo el mínimo, **Then** la racha
   se mantiene pero la meta no se marca como cumplida.
4. **Given** una racha con un día libre por semana, **When** falto un día, **Then** la racha no se
   rompe; **When** falto un segundo día en la misma semana, **Then** se rompe.
5. **Given** termino una actividad, **When** se desbloquea algo, **Then** veo una pantalla de
   resumen con récords y logros nuevos; si no hay nada nuevo, el resumen solo muestra el registro.
6. **Given** una respuesta de la IA que dice que desbloqueé un logro, **When** la app no lo ha
   calculado, **Then** no se desbloquea nada.
7. **Given** corrijo un dato pasado, **When** se recalcula, **Then** rachas y totales cambian, y los
   logros ya desbloqueados se conservan con su fecha.

---

### User Story 8 - Crear un acompañante con ayuda de la IA (Priority: P3)

Si quiero, describo con una frase lo que busco («quiero leer cada día») y la IA me hace dos o
tres preguntas y me propone una ficha completa: nombre, instrucciones, actividad, campos,
meta, modo (con tres niveles de juego ya armados) y recordatorio. Nada se crea hasta que lo
confirmo. Si no hay IA, o no quiero, lo creo a mano.

**Why this priority**: es un atajo de valor alto, pero depende de US3, US6 y US7.

**Independent Test**: con IA simulada que devuelve un bloque `trackia-companion` válido,
revisar la ficha, editar el nombre, pulsar Crear y comprobar acompañante, actividad,
meta y recordatorio creados; con un bloque inválido, comprobar que no se crea nada.

**Acceptance Scenarios**:

1. **Given** Crear acompañante, **When** elijo «Con ayuda de la IA», **Then** se abre una
   conversación de creación; **When** elijo «A mano», **Then** se abre el constructor.
2. **Given** la IA propone, **When** veo la ficha, **Then** puedo Crear, Editar o descartar; solo
   «Crear» persiste algo.
3. **Given** la IA ofrece el juego, **When** veo la propuesta, **Then** hay tres niveles: Solo
   recordatorio, Metas y rachas (sugerido) y Juego completo.
4. **Given** un acompañante en modo Recordatorio con 5 días seguidos de actividad, **When** registro
   el quinto, **Then** veo una única sugerencia «¿Activo una racha?» con Activar, Ahora no y
   No volver a sugerir; nunca como notificación del sistema.
5. **Given** sin IA, **When** creo un acompañante, **Then** las instrucciones para la IA son
   opcionales y la pantalla explica que se usan al conectar un proveedor.

---

### User Story 9 - Chats largos sin lentitud ni riesgo (Priority: P2)

Los chats, archivos y adjuntos no deben guardarse en el almacenamiento cifrado de claves,
para que los chats largos con imágenes no vuelvan lenta la app ni fallen al guardar.

**Why this priority**: hallazgo 2 de `REVISION.md`; riesgo real de pérdida o lentitud.

**Independent Test**: con un perfil que tiene chat activo, archivos y adjuntos en las claves
antiguas, abrir la versión nueva y comprobar que todo se ve igual, que las claves antiguas
se borran solo tras verificar la copia y que las pruebas de aislamiento por perfil y
acompañante siguen pasando.

**Acceptance Scenarios**:

1. **Given** datos en `gymia.ai.chat.v1*` y `gymia.ai.archive.v1.*`, **When** se migra, **Then** el
   chat, los archivos y los adjuntos se conservan con el mismo contenido y orden.
2. **Given** la migración falla a mitad, **When** reabro la app, **Then** sigo viendo los datos
   desde las claves antiguas y la migración se reintenta.
3. **Given** dos perfiles y dos acompañantes, **When** se migra, **Then** no se mezclan chats.

---

### User Story 10 - Mantenimiento interno (Priority: P3)

La app se identifica con su nombre y versión reales ante los proveedores, los fallos de
conexión se registran con un mensaje útil, los archivos más grandes se dividen sin cambiar
el comportamiento y el APK de release se reduce si es seguro.

**Why this priority**: hallazgos 4, 5, 6 y 7 de `REVISION.md`; no cambian la experiencia visible.

**Independent Test**: `flutter analyze` y `flutter test` en verde tras cada paso; prueba que el
User-Agent coincide con la versión de `pubspec.yaml`; tamaño de APK antes y después.

**Acceptance Scenarios**:

1. **Given** cualquier petición al proveedor, **When** se envía, **Then** el User-Agent es
   `TrackIA/<versión de pubspec>`.
2. **Given** un fallo de red en el inicio de sesión ChatGPT, **When** ocurre, **Then** se registra
   en el log de depuración y el usuario ve un mensaje específico de conexión.
3. **Given** la división de archivos grandes, **When** termina cada paso, **Then** no cambia ningún
   texto, clave de prueba ni comportamiento, y todas las pruebas siguen pasando.

---

### User Story 11 - Un modelo de IA distinto por acompañante (Priority: P3, opcional)

Puedo dejar un modelo por defecto y elegir otro para un acompañante concreto (por ejemplo,
un modelo local para Enfoque).

**Why this priority**: deseable pero no bloquea nada; puede posponerse sin afectar al resto.

**Independent Test**: configurar un modelo por defecto y otro para Enfoque; comprobar con un
cliente simulado que cada chat usa su configuración.

**Acceptance Scenarios**:

1. **Given** un acompañante sin excepción, **When** envío un mensaje, **Then** usa el modelo por defecto.
2. **Given** Enfoque con excepción, **When** envío un mensaje en Enfoque, **Then** usa su modelo.

---

### Edge Cases

- Una actividad preparada antes de la actualización con campos `{key,label,unit}` sin tipo: se
  conserva tal cual; sus valores no participan en sumas ni logros salvo que el usuario les
  asigne tipo y forma de contar (no se reinterpreta el pasado: constitución IV).
- Valor ausente frente a cero: un campo numérico sin valor no suma cero ni rompe un promedio.
- Cambio de zona horaria o de hora del sistema: los días se calculan en la zona local del
  momento del registro guardado; las rachas no se duplican al cambiar de zona.
- Renombrar una actividad: metas y logros enlazados por `activityKey` siguen la actividad por su
  clave original (ver `data-model.md`).
- Dos recordatorios del mismo acompañante a la misma hora: se publica uno solo.
- Recordatorio con permiso de notificaciones revocado: Ajustes → Avisos lo indica; no hay reintentos.
- Sin red ni IA: todo US1–US7 funciona; US8 muestra solo «A mano».
- Respuesta tardía de la IA tras pulsar Iniciar: no modifica el tramo iniciado (ya exigido por 003).
- Bloque de la IA con claves desconocidas o valores fuera de rango: se rechaza completo, sin efectos.
- Borrar un acompañante: se borran sus metas, logros, recordatorios y ajustes locales; no se
  borran registros de actividad ni hojas de Google (comportamiento actual de borrado).

## Requirements *(mandatory)*

### Functional Requirements

**Avisos (US1)**

- **FR-001**: Los avisos de fin de descanso y fin de tramo DEBEN poder publicarse en un canal de
  tipo alarma (categoría alarma y audio de alarma) que Android permite en No molestar modo Prioridad.
- **FR-002**: El usuario DEBE poder desactivar «Tratar como alarma»; entonces los avisos usan el
  canal normal actual.
- **FR-003**: La app DEBE detectar si No molestar está activo y mostrarlo en Ajustes → Avisos,
  con un acceso a los ajustes de notificaciones del sistema y una prueba de aviso.
- **FR-004**: Los recordatorios de hábitos (US6) NO DEBEN usar el canal de alarma.

**Ajustes y navegación (US2, US4)**

- **FR-005**: El tablero DEBE ofrecer acceso a una pantalla de Ajustes global con: Inteligencia
  artificial, Cuenta y datos, Google Sheets, Exportar e importar, Avisos, Apariencia y Ayuda.
- **FR-006**: El tablero DEBE mostrar una tarjeta «IA sin conectar» mientras la IA no esté
  verificada, con acceso directo a su configuración.
- **FR-007**: El chat de un acompañante NO DEBE tener menú lateral; DEBE tener volver, selector de
  acompañante en el título y un menú ⋮ con las acciones propias del acompañante.
- **FR-008**: Ninguna acción existente DEBE perderse al reorganizar menús; cada una DEBE tener un
  destino documentado en `plan.md` → «Mapa de menús».

**Actividades abiertas (US3)**

- **FR-009**: El panel sin actividad DEBE ser una barra compacta con «Nueva actividad», disponible sin IA.
- **FR-010**: El constructor DEBE ofrecer los ritmos Puntual, Libre, Con duración y Por tramos.
- **FR-011**: Los campos DEBEN tener tipo (número, texto, sí o no, opción, escala) y forma de contar
  (sumar, mejor marca, promedio, contar distintos, contar síes, solo notas) compatibles entre sí.
- **FR-012**: Las actividades por tramos DEBEN poder definir el nombre del tramo en singular y plural.
- **FR-013**: Los campos numéricos DEBEN poder anotarse con controles rápidos durante la actividad.
- **FR-014**: Los registros puntuales DEBEN guardarse con fecha, original y procedencia sin tramos.
- **FR-015**: Las definiciones anteriores DEBEN cargarse sin cambios; un campo sin tipo es «solo notas».
- **FR-016**: Las instrucciones para la IA de un acompañante DEBEN ser opcionales; si faltan se usa
  un texto neutro por defecto.

**Identidad visual (US4)**

- **FR-017**: Los temas claro y oscuro DEBEN usar los tokens de `contracts/visual-tokens.md`.
- **FR-018**: «Iniciar» DEBE ser teal con texto blanco en negrita; «Parar», carmín con texto blanco
  en negrita; las acciones secundarias, con contorno. El naranja NO DEBE usarse como relleno de botón.
- **FR-019**: El tiempo de una actividad en marcha DEBE mostrarse en un anillo con marcas y arco de
  progreso con el degradado de la marca.
- **FR-020**: Cada acompañante DEBE tener icono y color; los sugeridos con valores por defecto.
- **FR-021**: El logo DEBE dibujarse con colores del tema, sin recuadro blanco en oscuro.
- **FR-022**: La bienvenida DEBE mostrarse automáticamente solo hasta la primera vez que se completa
  u omite, salvo que el usuario desmarque «No volver a mostrar» (enmienda a `003/contracts/welcome.md`).

**IA y edición manual (US5)**

- **FR-023**: Cada campo editado a mano DEBE quedar fijado; las propuestas de la IA sobre un campo
  fijado DEBEN mostrarse como propuesta Aplicar/Ignorar y no aplicarse solas.
- **FR-024**: Las ediciones manuales DEBEN registrarse como eventos visibles en el chat e incluirse en
  el contexto de la IA.
- **FR-025**: Ninguna propuesta DEBE modificar un tramo ya iniciado.

**Recordatorio o juego (US6)**

- **FR-026**: Cada acompañante DEBE tener modo Recordatorio o Juego, y en Juego interruptores
  independientes para metas, rachas, logros y mensajes de ánimo.
- **FR-027**: Un recordatorio DEBE definir días, ventana (inicio y fin), última llamada, tono y mínimo del día.
- **FR-028**: No DEBE publicarse ningún recordatorio de un acompañante que ya cumplió ese día.
- **FR-029**: Los textos de recordatorio DEBEN calcularse en el dispositivo con datos reales, sin IA ni red.
- **FR-030**: Como máximo DEBEN publicarse dos recordatorios por acompañante y día; tras siete días
  seguidos sin cumplir, los recordatorios de ese acompañante DEBEN pausarse.
- **FR-031**: Los recordatorios DEBEN sobrevivir a un reinicio del dispositivo.

**Metas, rachas y logros (US7)**

- **FR-032**: Metas, rachas, logros y récords DEBEN calcularse de forma determinista desde los datos
  guardados; la IA NO DEBE poder desbloquear nada.
- **FR-033**: Cada forma de contar de un campo DEBE generar su familia de logros con la etiqueta y la
  unidad del campo; existen además logros universales de tiempo, sesiones y racha.
- **FR-034**: Una racha DEBE admitir un número configurable de días libres por semana (por defecto 1).
- **FR-035**: Al terminar una actividad DEBE mostrarse un resumen con récords y logros nuevos.
- **FR-036**: Las reglas propuestas por la IA DEBEN validarse contra un esquema estricto antes de
  ofrecerse; una regla inválida se descarta completa.

**Creación asistida (US8)**

- **FR-037**: La creación de acompañante DEBE ofrecer «Con ayuda de la IA» (solo con IA verificada) y «A mano».
- **FR-038**: Una propuesta de acompañante NO DEBE persistir nada hasta que el usuario pulse Crear.
- **FR-039**: La sugerencia de activar el juego DEBE mostrarse como máximo una vez por acompañante y
  motivo, dentro del chat, y respetar «No volver a sugerir».

**Datos y mantenimiento (US9, US10, US11)**

- **FR-040**: Chats, archivos y adjuntos DEBEN guardarse fuera de `flutter_secure_storage`, con
  migración verificada antes de borrar las claves antiguas.
- **FR-041**: Toda migración de SQLite DEBE ser aditiva, conservar IDs y hacer respaldo previo.
- **FR-042**: El User-Agent DEBE derivarse de una única constante de nombre y versión que coincida con `pubspec.yaml`.
- **FR-043**: Los fallos de conexión del inicio de sesión ChatGPT DEBEN registrarse y mostrar un mensaje específico.
- **FR-044**: La división de archivos grandes NO DEBE cambiar comportamiento, textos ni claves de prueba.
- **FR-045**: La minificación del release solo se activa si el APK firmado arranca y supera la prueba de humo.
- **FR-046** (opcional): Un acompañante PUEDE usar una configuración de IA distinta de la por defecto.
- **FR-047**: Todos los textos visibles nuevos DEBEN estar en español.

### Key Entities *(include if feature involves data)*

- **Definición de actividad (existente, ampliada)**: nombre, ritmo derivado, tiempos, nombre del tramo,
  campos con tipo y forma de contar, y lista de campos fijados por el usuario.
- **Registro puntual**: observación sin ejecución con valores, original, fecha y procedencia (003 T007).
- **Ajustes de acompañante**: icono, color, modo, interruptores de juego, días libres de racha.
- **Recordatorio**: días, ventana, última llamada, tono, mínimo del día, estado de pausa.
- **Regla de meta / logro**: métrica (fuente + agregación + periodo), umbral, ámbito y origen.
- **Logro desbloqueado**: regla, fecha, valor y actividad que lo causó.
- **Resumen para avisos**: instantánea pequeña que la parte nativa lee para redactar recordatorios.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Con No molestar en modo Prioridad, el 100 % de los avisos de fin de descanso con
  «Tratar como alarma» suenan en las pruebas Android.
- **SC-002**: Un usuario nuevo llega a configurar la IA desde el tablero en dos toques o menos.
- **SC-003**: Sin IA, crear una actividad propia y registrar un valor lleva menos de 60 segundos.
- **SC-004**: Todos los pares texto/fondo de botones y textos cumplen contraste ≥ 4,5 (texto
  normal) o ≥ 3 (texto grande en negrita de 18,66 px o más), según `contracts/visual-tokens.md`.
- **SC-005**: 0 recordatorios publicados en días ya cumplidos en las pruebas de recordatorios.
- **SC-006**: Ningún logro se desbloquea sin que su regla se cumpla con datos guardados (pruebas de
  propiedad sobre el evaluador).
- **SC-007**: La migración de chats conserva el 100 % de mensajes, archivos y adjuntos en los
  fixtures, incluido el caso de fallo a mitad.
- **SC-008**: `flutter analyze` sin errores ni avisos nuevos y `flutter test` en verde al cerrar cada fase.

## Assumptions

- La plataforma objetivo es Android; iOS se mantiene compilable pero no se valida en esta entrega.
- No se renombran `applicationId`, paquete, claves de almacenamiento ni IDs de protocolo
  (`gymia-activity`, `gymia-timing`, `gymia_rest`); los bloques nuevos usan prefijo `trackia-`.
- La gamificación no tiene valor fijo por defecto: se elige al crear el acompañante (sugerido
  «Metas y rachas»); los cuatro acompañantes existentes empiezan en modo Recordatorio.
- Los recordatorios usan alarmas inexactas dentro de la ventana; no requieren alarmas exactas.
- Las pruebas de dispositivo real (Xiaomi del propietario, No molestar del fabricante, release
  firmado) las ejecuta el propietario; el agente las deja preparadas y documentadas.
- Las notas de entrega siguen el formato de `docs/` (por ejemplo `docs/0.3.32-*.md`).

# Especificación: conversación fiable y acompañamiento adaptable

**Fecha**: 2026-11-05 · **Estado**: propuesta, no implementada · **Rama actual**: `feat/004-trackia-experience`.
**Entrada**: reporte del propietario y decisiones del 5 de noviembre; [notas](../../docs/PROPUESTAS-USO-REAL.md).

## Escenarios y pruebas

### US1 — Corregir y recuperar mensajes (P1)
Una persona corrige su mensaje o reenvía lo que quedó sin respuesta. Prueba independiente: registrar una serie, corregirla y simular pérdida de conexión y reinicio.
1. Dado «10r 10k f» con registro asociado, al editarlo a «10r 60k f», se conserva la revisión original y se propone o aplica una corrección identificada, sin añadir otra serie; si no se identifica con certeza, se pide confirmación.
2. Dado un fallo de red después de enviar, el mensaje conserva estado pendiente y ofrece reenviar; tras reiniciar sigue disponible. Si hay varios pendientes, se incluyen en orden y se indica el resultado sin duplicar mensajes ni efectos.
3. Una respuesta que solo dice haber anotado algo no acredita escritura: la interfaz informa únicamente de efectos confirmados.

### US2 — Modificar una actividad en marcha (P1)
La persona cambia el objetivo, nombre o descanso mediante chat o controles. Prueba: pasar de tres a cuatro series antes de la cuarta, y verificar contador, persistencia y descanso.
1. El cambio validado se refleja en la actividad vigente sin reescribir series anteriores; 4/4 sustituye a 4/3 al completar la cuarta.
2. Si el objetivo es menor que lo realizado, se conserva el progreso y se indica explícitamente; nombre y descanso afectan al futuro sin alterar resultados previos ni un aviso ya programado salvo confirmación explícita.
3. Una propuesta inválida o ambigua no modifica la actividad y explica cómo resolverla; funciona el control local sin modelo.

### US3 — Conectar y elegir hoja (P2)
Desde un mismo recorrido se autoriza Google, se selecciona archivo y pestaña y se decide cargar datos. Prueba: conexión nueva y conexión existente con transporte controlado. Cancelar conserva configuración previa; sin permisos o red se informa y permite reintentar. El destino es por perfil y acompañante.

### US4 — Memoria por acompañante (P2)
Cada acompañante recuerda instrucciones explícitas y hechos pertinentes entre chats archivados. Prueba: enseñar el significado de «igual», archivar y verificar contexto posterior y aislamiento.
1. Una petición inequívoca de recordar se guarda; el modelo puede sugerir recuerdos futuros, guardar los claramente pertinentes y preguntar cuando tenga dudas. Se muestra lo guardado y se permite revisar, editar y borrar.
2. «Igual» no inventa datos: se identifica la referencia y se pregunta si hay más de una interpretación razonable.
3. Copia voluntaria en Google: guardar, cargar y borrar por separado local y nube; mostrar cuenta, fecha, alcance, conflictos y errores. No se suben credenciales. Cambiar de cuenta o acompañante nunca mezcla memorias. Sin conexión los recuerdos locales siguen disponibles.

### US5 — Personalidad y apoyo adaptable (P2)
La persona describe libremente tono, objetivo y forma de apoyo; la IA ayuda a redactarlos y hay sugerencias opcionales. Prueba: crear dos acompañantes con tonos distintos y un acuerdo general para modificar una conducta o actividad.
1. El acuerdo contiene objetivo en texto libre, medida opcional, límite o duración opcional, avisos opcionales y acciones decididas por la persona. Se puede cambiar, pausar y finalizar sin penalización.
2. El seguimiento manual funciona sin red; los avisos dependen de los permisos disponibles. No se afirma observar ni bloquear otras aplicaciones.
3. El tono elegido no cambia permisos ni convierte respuestas en hechos; para temas sensibles evita juicio y no promete tratamiento.

### US6 — Experiencia y lenguas (P2)
Mostrar logo en inicio, frases de espera amables y traducciones completas de interfaz en español, inglés y árabe. Prueba independiente: cambiar idioma, reiniciar, activar árabe y recorrer inicio, chat, configuración, recordatorios y Sheets con interfaz RTL y texto mixto. La selección del sistema y una elección manual son persistentes; los datos escritos por el usuario no se traducen automáticamente. La arquitectura permite añadir idiomas.

### US7 — Plan de iOS (P3)
La entrega solicita un plan ejecutable de iOS, no implica publicación ni que iOS esté funcionando. Inventariar dependencias nativas, autorización, avisos, almacenamiento, archivos, IA local y pruebas; detallar preparación de Xcode, firma, simulador, iPhone, TestFlight y App Store como alternativas, dependencias y puertas de aceptación. La distribución elegida queda por decidir.

### US8 — Compartir un acompañante por QR o archivo (P3)
Una persona puede compartir la «receta» de un acompañante —nombre, icono, color, descripción, instrucciones de estilo, modo, plantillas de actividad y avisos por defecto— como código QR cuando cabe y como archivo `.trackia` siempre, y otra persona puede importarla en su teléfono. Nunca viajan claves de IA, chats, memoria, hoja de Google, cuentas ni datos de uso. La importación es contenido externo y no confiable: se muestra completa y editable antes de aplicarse, crea un acompañante nuevo sin permisos ni conexiones, y trata las instrucciones como estilo, nunca como autorización. Prueba independiente: exportar un acompañante, importarlo en otro perfil limpio, comprobar que solo coinciden los campos permitidos y que un paquete con instrucciones maliciosas, versión desconocida o tamaño excesivo no aplica nada.

### Casos límite
Red perdida tras respuesta o efecto externo; respuesta tardía tras cambio de acompañante; mensajes y adjuntos grandes; historial archivado; migración desde v6; edición de un mensaje con varios efectos; datos ambiguos; cuenta Google cambiada; conflicto o copia dañada; recordatorio ya programado; accesibilidad, modo oscuro, texto bidireccional y ampliación de fuente. No se usará información personal del teléfono en fixtures.

## Requisitos funcionales

- **FR-001** Cada mensaje del usuario admite edición y conserva original, revisiones, identidad y estado de procesamiento; la edición afecta explícitamente a la versión correcta.
- **FR-002** Se reenvían mensajes sin respuesta con su contexto y adjuntos, en orden, con persistencia tras reinicio e idempotencia de efectos identificables.
- **FR-003** Una corrección relacionada con un registro crea revisión verificable, no una segunda serie; ante ambigüedad se solicita confirmación.
- **FR-004** Los efectos en curso, confirmados, fallidos e inciertos se distinguen y el asistente no los afirma como hechos sin confirmación de la aplicación.
- **FR-005** Se modifican objetivo, nombre y descanso de actividad activa con validación y sin pérdida de registros; el progreso histórico no se reinterpreta.
- **FR-006** El flujo Google permite conectar, escoger hoja y pestaña y cargar o cancelar en una secuencia; respeta ámbitos y permisos.
- **FR-007** La memoria pertenece a perfil y acompañante, sobrevive al archivo y no mezcla datos. Es visible, editable y borrable.
- **FR-008** Las solicitudes explícitas de recuerdo se guardan; relevancia clara se puede guardar automáticamente y los casos dudosos se consultan. Los recuerdos recuperados se distinguen de instrucciones de sistema.
- **FR-009** La copia Google de memoria es opcional, explícita y por cuenta/ámbito; guardar, cargar, borrar localmente y borrar nube son operaciones diferenciadas con resultado y conflictos visibles.
- **FR-010** La personalidad libre y la ayuda de IA son configurables por acompañante sin cambiar permisos ni autorizar acciones.
- **FR-011** El apoyo a hábitos representa objetivos libres, seguimiento manual, límites, avisos y acuerdos editables, sin restringirlo a una actividad o conducta concreta.
- **FR-012** El logo aparece en inicio y las frases de espera son variadas, veraces y localizadas.
- **FR-013** La interfaz soporta español, inglés, árabe y extensiones; respeta RTL, accesibilidad, plurales, fechas y contenido mixto.
- **FR-014** Existe plan iOS trazable que distingue investigación, compilación, dispositivo y distribución; ninguna capacidad se declara validada sin evidencia.
- **FR-015** Se mantienen datos existentes, aislamiento y recuperación en migración; pruebas relevantes cubren errores y transportes simulados, con validación real identificada por separado.
- **FR-016** Un acompañante se exporta como paquete versionado (`trackia-companion/1`) con solo su configuración (nombre, icono, color, descripción, instrucciones de estilo, modo, plantillas y avisos por defecto); nunca incluye claves, chats, memoria, hoja, cuentas ni datos de uso.
- **FR-017** El paquete se comparte como QR cuando cabe y como archivo `.trackia` siempre, con contenido equivalente; si no cabe en un QR, la persona lo sabe y dispone del archivo.
- **FR-018** La importación no aplica nada sin una vista previa completa y editable, avisa de que el contenido es externo, crea un acompañante nuevo con identidad propia, sin permisos ni conexiones, y rechaza versiones desconocidas, daños de integridad y excesos de tamaño.
- **FR-019** Las instrucciones importadas se tratan como estilo: no pueden autorizar acciones ni permisos, y se retiran los bloques de la aplicación (`trackia-*`/`gymia-*`) que contengan.

### Entidades
Mensaje y revisiones; efecto asociado; actividad y revisión de objetivo; recuerdo con origen y estado; copia de memoria y cuenta; personalidad; acuerdo de apoyo y eventos; preferencia de idioma; paquete de acompañante.

## Criterios medibles

- **SC-001** En 100 % de los escenarios de corrección y reintento de la matriz, no aparece una serie adicional y se conserva el original.
- **SC-002** En 100 % de cambios de objetivo probados, el contador coincide con el objetivo vigente y se conservan resultados previos.
- **SC-003** En 100 % de pruebas de aislamiento entre dos perfiles y dos acompañantes, no se recupera memoria ajena.
- **SC-004** Los tres idiomas permiten completar los cinco recorridos de US6 sin texto de interfaz sin traducir ni controles inaccesibles; árabe se presenta RTL.
- **SC-005** Los flujos de nube y Sheets distinguen éxito, cancelación, desconexión y conflicto; ningún resultado simulado se presenta como validación real.
- **SC-006** Existe un plan iOS con tareas, dependencias y evidencia requerida por cada capacidad; el destino de distribución se decide antes de publicar.
- **SC-007** En 100 % de las pruebas de ida y vuelta el acompañante importado coincide en los campos permitidos y ningún campo prohibido aparece en el paquete; en 100 % de los paquetes maliciosos de la matriz (instrucciones hostiles, bloques `trackia-*`, versión desconocida, tamaño excesivo, integridad rota) no se aplica nada sin confirmación ni se ejecuta ninguna acción.

## Supuestos y límites

La edición conserva revisiones; la confirmación se exige cuando la relación con efectos sea ambigua. Google es la primera opción de copia, su viabilidad y permisos deben comprobarse antes de elegir el mecanismo; un fallo externo no permite declarar completo FR-009. No se contempla vigilar ni bloquear otras aplicaciones. La implementación de iOS no está incluida en este incremento: sí un plan ejecutable. Los datos sensibles no se extraen al repositorio. Pruebas con servicios reales y firma requieren entorno/cuentas adecuadas y evidencia separada.

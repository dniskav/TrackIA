# Traceability: TrackIA 004

Generada a partir de `spec.md` y `tasks.md`. Si cambian las tareas, regenerarla y
ejecutar `python3 scripts/validate-sdd-004.py`. Una fila no implica que el requisito esté entregado:
el estado real es el de las casillas de `tasks.md` con su evidencia.

| Requisito | Resumen | Tareas |
|---|---|---|
| FR-001 | Los avisos de fin de descanso y fin de tramo DEBEN poder publicarse en un canal de | T008 T013 |
| FR-002 | El usuario DEBE poder desactivar «Tratar como alarma»; entonces los avisos usan el | T007 T008 T010 |
| FR-003 | La app DEBE detectar si No molestar está activo y mostrarlo en Ajustes → Avisos, | T007 T009 T010 T011 T012 |
| FR-004 | Los recordatorios de hábitos (US6) NO DEBEN usar el canal de alarma. | T059 T065 |
| FR-005 | El tablero DEBE ofrecer acceso a una pantalla de Ajustes global con: Inteligencia | T027 T028 |
| FR-006 | El tablero DEBE mostrar una tarjeta «IA sin conectar» mientras la IA no esté | T029 |
| FR-007 | El chat de un acompañante NO DEBE tener menú lateral; DEBE tener volver, selector de | T030 T031 |
| FR-008 | Ninguna acción existente DEBE perderse al reorganizar menús; cada una DEBE tener un | T031 T032 T033 |
| FR-009 | El panel sin actividad DEBE ser una barra compacta con «Nueva actividad», disponible sin IA. | T020 T022 T042 |
| FR-010 | El constructor DEBE ofrecer los ritmos Puntual, Libre, Con duración y Por tramos. | T039 T040 T041 T042 T048 |
| FR-011 | Los campos DEBEN tener tipo (número, texto, sí o no, opción, escala) y forma de contar | T035 T036 T037 T040 T041 |
| FR-012 | Las actividades por tramos DEBEN poder definir el nombre del tramo en singular y plural. | T035 T036 T040 T041 T043 |
| FR-013 | Los campos numéricos DEBEN poder anotarse con controles rápidos durante la actividad. | T044 |
| FR-014 | Los registros puntuales DEBEN guardarse con fecha, original y procedencia sin tramos. | T038 T039 T045 T047 |
| FR-015 | Las definiciones anteriores DEBEN cargarse sin cambios; un campo sin tipo es «solo notas». | T003 T035 T036 T037 T048 |
| FR-016 | Las instrucciones para la IA de un acompañante DEBEN ser opcionales; si faltan se usa | T046 |
| FR-017 | Los temas claro y oscuro DEBEN usar los tokens de `contracts/visual-tokens.md`. | T008 T015 T016 T026 |
| FR-018 | «Iniciar» DEBE ser teal con texto blanco en negrita; «Parar», carmín con texto blanco | T017 T020 T021 |
| FR-019 | El tiempo de una actividad en marcha DEBE mostrarse en un anillo con marcas y arco de | T018 T021 |
| FR-020 | Cada acompañante DEBE tener icono y color; los sugeridos con valores por defecto. | T023 T024 |
| FR-021 | El logo DEBE dibujarse con colores del tema, sin recuadro blanco en oscuro. | T019 T025 |
| FR-022 | La bienvenida DEBE mostrarse automáticamente solo hasta la primera vez que se completa | T025 |
| FR-023 | Cada campo editado a mano DEBE quedar fijado; las propuestas de la IA sobre un campo | T049 T050 T051 T054 T055 |
| FR-024 | Las ediciones manuales DEBEN registrarse como eventos visibles en el chat e incluirse en | T006 T052 |
| FR-025 | Ninguna propuesta DEBE modificar un tramo ya iniciado. | T053 T055 |
| FR-026 | Cada acompañante DEBE tener modo Recordatorio o Juego, y en Juego interruptores | T056 T060 T066 T073 T076 |
| FR-027 | Un recordatorio DEBE definir días, ventana (inicio y fin), última llamada, tono y mínimo del día. | T056 T057 T060 T063 |
| FR-028 | No DEBE publicarse ningún recordatorio de un acompañante que ya cumplió ese día. | T058 T059 T061 |
| FR-029 | Los textos de recordatorio DEBEN calcularse en el dispositivo con datos reales, sin IA ni red. | T057 T059 |
| FR-030 | Como máximo DEBEN publicarse dos recordatorios por acompañante y día; tras siete días | T058 T059 T062 T066 |
| FR-031 | Los recordatorios DEBEN sobrevivir a un reinicio del dispositivo. | T059 T064 T065 |
| FR-032 | Metas, rachas, logros y récords DEBEN calcularse de forma determinista desde los datos | T067 T068 T069 T071 T072 T075 T077 |
| FR-033 | Cada forma de contar de un campo DEBE generar su familia de logros con la etiqueta y la | T070 T072 |
| FR-034 | Una racha DEBE admitir un número configurable de días libres por semana (por defecto 1). | T068 T069 T073 T078 |
| FR-035 | Al terminar una actividad DEBE mostrarse un resumen con récords y logros nuevos. | T072 T074 |
| FR-036 | Las reglas propuestas por la IA DEBEN validarse contra un esquema estricto antes de | T067 T085 T090 |
| FR-037 | La creación de acompañante DEBE ofrecer «Con ayuda de la IA» (solo con IA verificada) y «A mano». | T086 T087 T088 T091 |
| FR-038 | Una propuesta de acompañante NO DEBE persistir nada hasta que el usuario pulse Crear. | T085 T087 |
| FR-039 | La sugerencia de activar el juego DEBE mostrarse como máximo una vez por acompañante y | T089 |
| FR-040 | Chats, archivos y adjuntos DEBEN guardarse fuera de `flutter_secure_storage`, con | T003 T079 T080 T081 T082 T084 |
| FR-041 | Toda migración de SQLite DEBE ser aditiva, conservar IDs y hacer respaldo previo. | T004 T005 |
| FR-042 | El User-Agent DEBE derivarse de una única constante de nombre y versión que coincida con `pubspec.yaml`. | T092 |
| FR-043 | Los fallos de conexión del inicio de sesión ChatGPT DEBEN registrarse y mostrar un mensaje específico. | T094 T095 |
| FR-044 | La división de archivos grandes NO DEBE cambiar comportamiento, textos ni claves de prueba. | T006 T096 T097 |
| FR-045 | La minificación del release solo se activa si el APK firmado arranca y supera la prueba de humo. | T098 T099 |
| FR-046 | Un acompañante PUEDE usar una configuración de IA distinta de la por defecto. | T100 T101 T102 T103 |
| FR-047 | Todos los textos visibles nuevos DEBEN estar en español. | T093 T106 |
| SC-001 | Con No molestar en modo Prioridad, el 100 % de los avisos de fin de descanso con | T013 T014 T107 |
| SC-002 | Un usuario nuevo llega a configurar la IA desde el tablero en dos toques o menos. | T029 T034 T107 |
| SC-003 | Sin IA, crear una actividad propia y registrar un valor lleva menos de 60 segundos. | T047 T107 |
| SC-004 | Todos los pares texto/fondo de botones y textos cumplen contraste ≥ 4,5 (texto | T015 T026 |
| SC-005 | 0 recordatorios publicados en días ya cumplidos en las pruebas de recordatorios. | T064 |
| SC-006 | Ningún logro se desbloquea sin que su regla se cumpla con datos guardados (pruebas de | T068 T078 |
| SC-007 | La migración de chats conserva el 100 % de mensajes, archivos y adjuntos en los | T079 T083 |
| SC-008 | `flutter analyze` sin errores ni avisos nuevos y `flutter test` en verde al cerrar cada fase. | T001 T002 T104 T105 T106 |

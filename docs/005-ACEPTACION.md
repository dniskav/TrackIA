# Recorridos de aceptación: spec 005 (T053)

**Fecha**: 2026-11-07 · **Rama**: `feat/004-trackia-experience` · **Estado**: preparado, **nada ejecutado en el teléfono**.
**Fuentes**: `specs/005-conversacion-memoria/quickstart.md`, `spec.md` (US1–US7), `docs/005-MATRIZ.md`, `docs/005-QA.md`.

## Reglas de uso

- Los pasos los ejecuta una persona en el teléfono. Este documento no instala, no publica y no abre ningún dispositivo.
- Usar **solo datos sintéticos**: nombres inventados, hojas de Google desechables creadas para la prueba, nada del teléfono personal.
- No ejecutar nada marcado **G** sin permiso explícito de la persona propietaria, y solo con cuenta, hoja o modelo de prueba.
- Anotar en cada paso la evidencia: captura (nombre del archivo) o nota breve con fecha. Una casilla vacía significa «no ejecutado».

## Leyenda de evidencia

| Tipo | Significado | Cómo se marca |
|---|---|---|
| **E** Emulador / automática | Ya cubierto por pruebas del repositorio. No requiere teléfono. | Cita del test; no hace falta captura |
| **T** Teléfono real | Lo ejecuta la persona en su Android de prueba, sin servicios externos | Casilla `[ ]` + captura o nota |
| **G** Google real / IA real / iOS | **Sin ejecutar.** Requiere cuenta, modelo o dispositivo que no se han usado | `sin ejecutar` hasta que el propietario lo autorice |

## Lo que NO existe todavía (no esperar estos resultados)

| Función | Estado según la matriz | Efecto en los recorridos |
|---|---|---|
| Adaptador real de Google Drive (`appDataFolder`, OAuth) | T030 abierta; acciones de nube deshabilitadas | Copia de memoria en nube: no verificable |
| Chat que pasa recuerdos al modelo (`acceptPersisted`) | T026 abierta | Tras archivar, el modelo **no** recibe la memoria: no es fallo de la prueba |
| Avisos asociados a cada acuerdo de apoyo | T038 abierta | Un acuerdo no programa avisos propios |
| Prueba de permisos de acuerdos (`integration_test/support_agreement_android_test.dart`) | T039 abierta; el archivo no existe | Permisos concedidos/denegados solo a mano (T) |
| Fechas por idioma, fuente grande, lector de pantalla, RTL en todo el árbol | T042–T045 parciales | Verificación manual; resultado se anota, no se da por aprobado |
| Revisión humana del árabe | Sin validar | Tipo G (persona revisora) |
| Edición de cualquier mensaje | Decisión de producto: solo el **último** mensaje del usuario | Los mensajes anteriores no ofrecen Editar |
| Escaneo con cámara física y linterna | No probado; la cámara virtual del emulador muestra negro | Solo tipo C (persona, dispositivo real) |
| Abrir un `.trackia` desde otra app | El manifiesto de Android no lo asocia (T059 abierta) | Importar desde «Importar acompañante» |
| Compartir/importar en iOS | Sin validar; el texto de `NSCameraUsageDescription` habla de fotos | Fuera de este recorrido |

## Preparación previa (antes de cualquier instalación)

| # | Paso | Resultado esperado | Evidencia |
|---|---|---|---|
| P1 | Anotar la versión instalada que muestra la app (widget de versión). | Número anotado, p. ej. `0.3.x+yy` | `[ ]` |
| P2 | Guardar el APK instalado actual fuera del repositorio. En `releases/` solo hay `trackia-0.3.31.apk`, que puede no coincidir con la versión instalada: confirmar antes. | APK con número conocido y ubicación anotada | `[ ]` |
| P3 | Crear una copia de datos desde la pantalla de copia (clave `dataCreateBackup`, «Crear y compartir copia») y guardarla fuera del repositorio. | Archivo de copia creado | `[ ]` |
| P4 | Anotar conteos antes de migrar: actividades, chats, mensajes, acompañantes. | Lista con números | `[ ]` |

## Recorrido de migración a v8 (T)

Base: el código crea `<base>.pre-trackia-v8.sqlite` **solo si la base estaba en versión 7**. Si estaba en versión 6 o anterior, crea `<base>.pre-trackia-v7.sqlite` y no la copia v8. Con media de chat, la copia incluye además una carpeta `.pre-trackia-vN.media`.

| # | Paso | Resultado esperado | Evidencia |
|---|---|---|---|
| M1 | Confirmar P1–P4 completos. | Todo anotado | `[ ]` |
| M2 | Instalar la nueva versión **solo con permiso** (sobre la actual, sin desinstalar). | Instalación correcta, misma firma | `[ ]` |
| M3 | Abrir la app. | Arranca sin pantalla de error y muestra el inicio | `[ ]` |
| M4 | Comprobar la copia previa: si la base era v7, debe existir `.pre-trackia-v8.sqlite` (y su carpeta `.media` si había adjuntos). Si era v6, debe existir `.pre-trackia-v7.sqlite`. Requiere acceso al almacenamiento privado: solo con herramienta autorizada. | Archivo presente y no vacío | `[ ]` |
| M5 | Comparar con P4: mismas actividades, mismos chats y mensajes, mismos acompañantes. | Conteos iguales | `[ ]` |
| M6 | Abrir un chat antiguo y responder en modo normal (la IA real no se valida aquí). | Chat legible; adjuntos visibles | `[ ]` |
| M7 | Editar el último mensaje (ver US1) y comprobar que no se pierde el original. | Revisión visible | `[ ]` |

**Vuelta atrás (no probada: confirmar con el propietario antes de instalar).**
- Android no instala una versión más antigua encima de una más nueva: hay que desinstalar, y eso **borra los datos** si no hay copia.
- Un APK anterior probablemente no abre una base en v8. Por eso la vía fiable es: desinstalar, instalar el APK de P2, y restaurar la copia de P3 con «Restaurar copia» **si esa copia es compatible con la versión anterior** (no comprobado).
- Alternativa: restaurar `.pre-trackia-v8.sqlite` en el lugar de la base. Requiere herramienta autorizada y solo en depuración.
- Registrar aquí qué vía se usó y su resultado: `[ ]`

## US1 — Corregir y recuperar mensajes (P1)

**Objetivo**: corregir el último mensaje sin crear una serie nueva, y recuperar un mensaje sin respuesta.
**Datos sintéticos**: actividad «Prueba press banca» con objetivo 10 series; primer mensaje «10r 10k f» (registrado).
**Emulador/automática (E)**: `test/message_edit_widget_test.dart`, `test/message_revision_repository_test.dart`, `test/message_effect_test.dart` (3→5), `test/message_delivery_test.dart`, `test/message_queue_widget_test.dart`. El caso 10×10 → 10×60 del quickstart **no** está automatizado.

| # | Paso | Resultado esperado | Tipo | Evidencia |
|---|---|---|---|---|
| 1.1 | Registrar «10r 10k f» y esperar confirmación. | Una serie registrada | T | `[ ]` |
| 1.2 | Editar ese mensaje (acción Editar, es el último) a «10r 60k f» y enviar. | Se propone o aplica corrección identificada; **no** aparece una serie adicional | T | `[ ]` |
| 1.3 | Revisar el historial de la actividad. | Original consultable; revisión visible | T | `[ ]` |
| 1.4 | Repetir 1.2 y pulsar cancelar. | Nada cambia | T | `[ ]` |
| 1.5 | Activar modo avión, enviar un mensaje, esperar. | Mensaje con estado pendiente y opción de reenviar | T | `[ ]` |
| 1.6 | Reiniciar la app con el mensaje pendiente. | Sigue pendiente; reenviar no duplica | T | `[ ]` |
| 1.7 | Pedir a la IA que confirme un registro sin que la app lo haya guardado. | La interfaz no afirma el efecto como confirmado | G (IA real) | `sin ejecutar` |
| 1.8 | Editar con varios efectos o con respuesta ambigua. | Pide confirmación y no aplica a ciegas | G (IA real) | `sin ejecutar` |

## US2 — Modificar una actividad en marcha (P1)

**Objetivo**: cambiar objetivo, nombre y descanso sin perder registros.
**Datos sintéticos**: «Prueba remo» con objetivo 3 series y descanso 60 s.
**E**: `test/activity_live_edit_test.dart` (9), `test/activity_focus_test.dart`.

| # | Paso | Resultado esperado | Tipo | Evidencia |
|---|---|---|---|---|
| 2.1 | Registrar 3 series. | Contador 3/3 o 3/objetivo, según vista | T | `[ ]` |
| 2.2 | Cambiar el objetivo a 4 series (control local, sin IA). | Contador pasa a 3/4 | T | `[ ]` |
| 2.3 | Registrar la cuarta serie. | Contador 4/4; series anteriores intactas | T | `[ ]` |
| 2.4 | Cambiar el nombre a «Remo prueba 2». | Nombre nuevo; registros previos iguales | T | `[ ]` |
| 2.5 | Cambiar el descanso durante un descanso en curso. | Afecta al futuro, no al descanso en curso | T | `[ ]` |
| 2.6 | Poner objetivo 2 con 4 series hechas. | Progreso conservado y aviso explícito | T | `[ ]` |
| 2.7 | Observar si aparece el error visual del contador (T016). | Anotar si aparece; no está reproducido | T | `[ ]` |
| 2.8 | Pedir cambio de objetivo por chat con una cifra ambigua. | No modifica; explica cómo resolverlo | G (IA real) | `sin ejecutar` |

Nota: nombre y descanso no usan control de versión (T017); si dos cambios se hacen desde dos sitios a la vez, anotar el resultado.

## US3 — Conectar y elegir hoja (P2)

**Objetivo**: conectar Google, elegir archivo y pestaña, cargar o cancelar.
**Datos sintéticos**: hoja desechable «TrackIA prueba» creada solo para esto, en cuenta de prueba.
**E**: `test/sheets_onboarding_test.dart`, `test/google_sheets_import_test.dart`, `test/sheet_sync_ui_test.dart`, `integration_test/sheets_onboarding_test.dart` (transporte simulado).

| # | Paso | Resultado esperado | Tipo | Evidencia |
|---|---|---|---|---|
| 3.1 | Activar el modo avión y abrir el flujo de Sheets. | Informa de que no hay red y permite reintentar | T | `[ ]` |
| 3.2 | Cancelar a mitad del flujo, si la pantalla lo permite sin conectar. | Configuración previa intacta | T | `[ ]` |
| 3.3 | Conectar una cuenta de prueba (OAuth real). | Pantalla de consentimiento real; se muestran permisos | G (Google real) | `sin ejecutar` |
| 3.4 | Elegir hoja y pestaña desechables y cargar datos. | Datos cargados en la pestaña elegida | G (Google real) | `sin ejecutar` |
| 3.5 | Cambiar de cuenta. | Destino por perfil y acompañante; nada mezclado | G (Google real) | `sin ejecutar` |

## US4 — Memoria por acompañante (P2)

**Objetivo**: que el acompañante recuerde instrucciones explícitas, y poder revisarlas.
**Datos sintéticos**: acompañante «Coach prueba A» y otro «Coach prueba B». Instrucción de prueba: «Recuerda: cuando diga “igual”, repite el peso de la última serie.»
**E**: `test/companion_memory_test.dart`, `test/companion_memory_repository_test.dart`, `test/companion_memory_ui_test.dart` (13), `test/memory_proposal_test.dart`, `test/assistant_context_test.dart`.

| # | Paso | Resultado esperado | Tipo | Evidencia |
|---|---|---|---|---|
| 4.1 | Pedir al acompañante A que recuerde la instrucción. | Recuerdo guardado (se muestra lo guardado) | T (guardado local) | `[ ]` |
| 4.2 | Abrir ajustes del acompañante → «Memoria del acompañante». | Lista solo de A; se ve el recuerdo | T | `[ ]` |
| 4.3 | Editar el texto del recuerdo y guardar. | Texto nuevo visible | T | `[ ]` |
| 4.4 | Borrar el recuerdo. | Desaparece de la lista | T | `[ ]` |
| 4.5 | Repetir 4.1, archivar el chat y abrir uno nuevo. | Recuerdo sigue en la lista. **El modelo no lo recibe aún (T026): no es fallo de la prueba** | T (lista) | `[ ]` |
| 4.6 | Comprobar que B no ve memorias de A. | Lista vacía o solo de B | T | `[ ]` |
| 4.7 | Pedir a A que use «igual» en un mensaje. | Usa el recuerdo o pregunta si hay varias lecturas | G (IA real; y T026 abierta) | `sin ejecutar` |
| 4.8 | Pulsar la copia en la nube de la memoria. | Acciones deshabilitadas. **Drive real no está** (T030) | T (ver deshabilitado) | `[ ]` |
| 4.9 | Copia en Google Drive (guardar, cargar, borrar nube). | Resultados y conflictos visibles | G (Google real) | `sin ejecutar` |

## US5 — Personalidad y apoyo adaptable (P2)

**Objetivo**: crear dos acompañantes con tonos distintos y un acuerdo de apoyo que se pueda cambiar, pausar y terminar.
**Datos sintéticos**: acuerdo «Caminar 20 min antes de cenar» (objetivo libre, sin medida ni límite); no usar datos de salud reales.
**E**: `test/support_agreement_test.dart`, `test/support_agreement_service_test.dart`, `test/support_agreement_repository_test.dart`, `test/support_agreement_ui_test.dart`, `test/personality_custom_test.dart`, `test/companion_settings_test.dart`.

| # | Paso | Resultado esperado | Tipo | Evidencia |
|---|---|---|---|---|
| 5.1 | Crear dos acompañantes con tonos distintos (descripción libre). | Dos perfiles; permisos iguales | T | `[ ]` |
| 5.2 | En el chat, abrir «Acuerdos de apoyo» desde la cabecera. | Pantalla de acuerdos; lista vacía con texto guía | T | `[ ]` |
| 5.3 | «Nuevo acuerdo» con objetivo libre. | Acuerdo activo | T | `[ ]` |
| 5.4 | Pausar, cambiar el texto, reanudar, terminar. | Cada cambio se refleja; registros previos intactos | T | `[ ]` |
| 5.5 | Repetir 5.3–5.4 sin red. | Funciona sin conexión | T | `[ ]` |
| 5.6 | Acuerdo con aviso activado: esperar la hora. | **No hay aviso propio por acuerdo (T038).** Anotar lo que ocurra | T | `[ ]` |
| 5.7 | Denegar y conceder permisos de avisos y probar. | Sin permisos: informa. **Prueba automática no existe (T039)** | T | `[ ]` |
| 5.8 | Dar a un acompañante tono muy duro y pedir un consejo. | Tono cambia; permisos y acciones no | G (IA real) | `sin ejecutar` |

## US6 — Idiomas es / en / ar (P2)

**Objetivo**: cambiar idioma, reiniciar, árabe en RTL, fechas y texto mixto.
**Datos sintéticos**: una actividad con nombre en español, otra con nombre en árabe o mixto.
**E**: `test/localization_test.dart` (9), `test/localization_t042_test.dart`, `test/locale_settings_test.dart`, `test/sheets_localization_t044_test.dart`.

| # | Paso | Resultado esperado | Tipo | Evidencia |
|---|---|---|---|---|
| 6.1 | Ajustes → idioma: pasar a inglés. | Textos en inglés en inicio, chat, ajustes | T | `[ ]` |
| 6.2 | Reiniciar la app. | Sigue en inglés | T | `[ ]` |
| 6.3 | Pasar a árabe. | Diseño RTL (elementos espejados) | T | `[ ]` |
| 6.4 | En árabe, revisar inicio, chat, configuración, recordatorios y Sheets. | Sin textos en español sin traducir; controles visibles | T | `[ ]` |
| 6.5 | Revisar fechas en cada idioma (historial, recordatorios). | Formato de fecha del idioma | T (pendiente T045) | `[ ]` |
| 6.6 | Nombre de actividad en árabe dentro de una pantalla en español. | Texto mixto legible; el dato del usuario no se traduce | T | `[ ]` |
| 6.7 | Fuente grande y lector de pantalla del sistema. | Anotar lo que no se entiende (sin prueba automática) | T (pendiente T045) | `[ ]` |
| 6.8 | Revisión humana del texto árabe. | Persona revisora anota correcciones | G (revisión humana) | `sin ejecutar` |

## US7 — Plan de iOS (P3)

**Objetivo**: leer el plan, sin implicar que iOS funcione.
**E**: no aplica. El plan es documental (`docs/005-IOS-PLAN.md`, §§1–5).

| # | Paso | Resultado esperado | Tipo | Evidencia |
|---|---|---|---|---|
| 7.1 | Leer §1 (inventario) y §2 (Xcode, firma, simulador, iPhone). | Cada capacidad con su evidencia requerida | T (lectura) | `[ ]` |
| 7.2 | Compilar, abrir en simulador o iPhone, y probar TestFlight/App Store. | Sin ejecutar: requiere Mac, Xcode, cuenta y permiso | G (iOS) | `sin ejecutar` |

## Recordatorios: frases por idioma (T)

**Objetivo**: los textos de recordatorio y espera salen en el idioma elegido.
**E**: `integration_test/reminders_android_test.dart` (existe; revisar su contenido antes de citarlo como prueba de frases). Sin prueba específica de frases por idioma identificada (FR-012 parcial).

| # | Paso | Resultado esperado | Tipo | Evidencia |
|---|---|---|---|---|
| R1 | En español, crear recordatorio y esperar la frase de espera del chat. | Frase en español | T | `[ ]` |
| R2 | Cambiar a inglés y repetir. | Frase en inglés | T | `[ ]` |
| R3 | Cambiar a árabe y repetir. | Frase en árabe, RTL | T | `[ ]` |
| R4 | Dejar que el aviso se dispare (Android). | Aviso llega con el texto del idioma | T | `[ ]` |
| R5 | Revisión de veracidad de las frases. | Persona revisora anota | G (revisión humana) | `sin ejecutar` |

## US8 — Compartir, importar y escanear (T)

**Objetivo**: compartir un acompañante como QR o archivo, importarlo en otro perfil y escanearlo, sin datos prohibidos y sin aplicar nada sin confirmación.
**Detalle**: `docs/005-COMPARTIR.md`. Las columnas **E**, **T** y **C** son evidencias separadas: **E** emulador (automática o manual en el emulador), **T** teléfono Android real, **C** cámara física leyendo un QR real. La última columna marca si el paso **requiere a la persona**. Usar solo acompañantes sintéticos.

| # | Paso | Resultado esperado | E | T | C | Requiere a la persona |
|---|---|---|---|---|---|---|
| 8.1 | Ajustes de un acompañante propio → «Compartir acompañante» → leer el aviso. | Se listan qué viaja y qué no; ninguna clave, chat ni memoria. E: `test/companion_share_test.dart`. | `[ ]` | `[ ]` | — | Sí (T) |
| 8.2 | Compartir el archivo `.trackia` con la hoja del sistema (p. ej. guardar en archivos). | El archivo se entrega siempre. E: `test/companion_share_test.dart`, `integration_test/companion_package_android_test.dart`. | `[ ]` | `[ ]` | — | Sí (T) |
| 8.3 | Acompañante corto: aparece QR. Con instrucciones que dejen el texto por encima de 2000 caracteres: solo archivo y aviso. | QR solo si cabe. E: `test/companion_share_test.dart`. | `[ ]` | `[ ]` | — | Sí (T) |
| 8.4 | Escanear el QR mostrado en la pantalla de otro teléfono. | Se abre la vista previa con el contenido del paquete. E: `integration_test/companion_qr_decode_android_test.dart` (QR generado en el emulador; pasó el 2026-11-07, `docs/005-QA.md`). | `[ ]` | `[ ]` | `[ ]` | Sí (T y C) |
| 8.5 | Pulsar «Escanear acompañante» con el permiso de cámara denegado. | Aparece «No hay permiso para usar la cámara…» y el botón «Importar desde archivo o texto». E: `test/companion_scan_test.dart` (lector simulado). | `[ ]` | `[ ]` | — | Sí (T) |
| 8.6 | Importar el `.trackia` en un perfil limpio: revisar la vista previa, editar el nombre y guardar; repetir y cancelar. | Aviso de contenido externo, modo «solo recordatorio», identidad nueva, origen importado. Cancelar no crea nada. E: `integration_test/companion_package_android_test.dart`. | `[ ]` | `[ ]` | — | Sí (T) |
| 8.7 | Abrir un paquete con el `checksum` alterado, o con versión futura (`trackia-companion/2`). | Rechazado con mensaje; no hay vista previa ni acompañante. E: `integration_test/companion_package_android_test.dart` (tres paquetes hostiles) y `test/companion_package_test.dart`. | `[ ]` | `[ ]` | — | Sí (T) |
| 8.8 | Paquete con un bloque `trackia-activity` en las instrucciones. | El bloque se retira y el aviso dice cuántos. E: `test/companion_package_import_test.dart`. | `[ ]` | `[ ]` | — | Sí (T) |
| 8.9 | Con un acompañante importado, pedir al asistente que edite una hoja de prueba. | Diálogo con hoja, pestaña y cada celda; «Cancelar» no escribe. E: `test/imported_companion_confirmation_test.dart`. Hoja real: requiere cuenta de prueba (G). | `[ ]` | `[ ]` | — | Sí (T); G solo con autorización |
| 8.10 | Con un acompañante importado, provocar una propuesta automática de actividad. | Diálogo con nombre, descanso y duración; «Cancelar» no crea la actividad. Requiere IA real (G). E: `test/imported_companion_confirmation_test.dart` (sin IA). | `[ ]` | sin ejecutar (G) | — | Sí (G) |
| 8.11 | «Confiar en este acompañante» → confirmar. | Pasa a propio; sus acciones ya no piden diálogo. E: `test/imported_companion_confirmation_test.dart`. | `[ ]` | `[ ]` | — | Sí (T) |
| 8.12 | Leer con la cámara real el QR de un acompañante, con luz normal y con poca luz; probar la linterna. | El QR se lee con la cámara real y la linterna enciende y apaga. El emulador no lo prueba. | — | — | `[ ]` | Sí (C) |
| 8.13 | Pantallas de compartir e importar en árabe. | RTL correcto, sin textos en español ni claves sin traducir. Una persona revisora anota la calidad del texto. | — | `[ ]` | — | Sí (T y revisión humana) |

## Orden sugerido y cierre

1. P1–P4, luego M1–M7 (migración) con permiso.
2. US1, US2 y recordatorios (solo T).
2b. US8 (8.1–8.13), después de US1–US7 y con la misma preparación de emulador y teléfono.
3. US4 y US5 en modo local (T).
4. US6 con cambio de idioma.
5. G (Google, IA, iOS, revisión humana) solo con autorización explícita.

Al terminar, la persona completa el resumen en `docs/005-QA.md`, separando E, T y G. Sin resultados de G, la validación real queda como pendiente, no como aprobada.

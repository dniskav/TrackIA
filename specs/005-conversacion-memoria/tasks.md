# Tareas: conversación fiable y acompañamiento adaptable

**Fuentes**: [spec](spec.md), [plan](plan.md), [modelo](data-model.md), [contratos](contracts/contratos.md), [validación](quickstart.md). Leer la guía del plan antes de actuar. Las tareas son trabajo futuro; marcar solo con evidencia concreta debajo. No usar datos personales como fixtures. Si una integración real no está disponible, registrar bloqueo y continuar lo independiente; no marcar completa una tarea pendiente de validación real. `[P]` indica archivos independientes después de sus dependencias, no obliga a delegar.

## Fase 1 — Preparación

- [x] T001 Registrar en `docs/005-QA.md` rama real, estado Git sin modificar borrados previos, versión de Flutter, salida de `./scripts/flutter-local.sh analyze` y resultado de `./scripts/flutter-local.sh test`; distinguir fallos anteriores.
  - Evidencia: `docs/005-QA.md`; analyze 11 avisos informativos, test 690 aprobadas.
- [x] T002 Inventariar en `docs/005-QA.md` formatos reales de chat, adjuntos, respaldo y migraciones v6, símbolos de repositorio y callbacks actuales; no copiar conversaciones personales.
  - Evidencia: inventario de formatos y límites en `docs/005-QA.md`.

## Fase 2 — Base de identidad y migración

- [x] T003 Crear `test/feature_005_migration_test.dart` con fixture v6 sintético: copia previa, IDs y adjuntos intactos, migración repetida y restauración; comprobar que falla antes de migrar.
  - Evidencia: la prueba 'v6 snapshot restores all tables and attachment, then upgrade is repeatable' pasó completa el 2026-11-06 (esquema 7, todas las tablas y el adjunto intactos, restauración independiente con `pre-trackia-v7.media`, upgrade repetible con una sola copia); test del mismo fichero para copia fallida añade el 'falla antes de migrar'.
- [x] T004 Añadir migración aditiva y copia recuperable en `lib/data/trackia_migrations.dart` y `lib/data/sqlite_workout_repository.dart` para entidades del modelo; ejecutar T003 y pruebas de respaldo existentes.
  - Evidencia 2026-11-06: `_createTrackiaV7` (mensajes/revisiones/efectos/memoria, aditiva), `createTrackiaV7Backup` publicada fuera de la transacción de upgrade con limpieza de residuos; 6 pruebas de `feature_005_migration_test.dart` + `trackia_migrations_test`, `trackia_v6_migration_test`, `chat_store_migration_test` aprobadas; fixtures v4/v5 actualizados para simular heredados reales. Pendiente de validación real: Android antiguo e interrupción de proceso (`kill -9`); detalles y decisión en `docs/005-QA.md` §"T004".
- [x] T005 Añadir en `test/feature_005_scope_test.dart` pruebas de aislamiento entre dos perfiles y dos acompañantes para IDs y referencias; implementar validación común en `lib/data/feature_scope.dart` y comprobar rechazo de referencias cruzadas.
  - Evidencia: `./scripts/flutter-local.sh test test/feature_005_scope_test.dart` → 4 pruebas aprobadas; analyze focalizado limpio. El uso en repositorios corresponde a tareas posteriores.

## Fase 3 — US1: corregir y recuperar chat (P1)

**Prueba independiente**: quickstart 1–2. Depende de T003–T005.

- [ ] T006 [US1] Crear `test/message_revision_test.dart` para mensaje hasta 8000 caracteres, IDs estables, revisiones crecientes, original y adjunto conservados, cancelación y migración de chat legado.
  - Estado 2026-11-07: parcial: `test/message_revision_test.dart` (5 aprobadas) cubre 8000 caracteres, IDs estables, revisiones crecientes, original y adjunto conservados y migración de chat legado; falta una prueba explícita de cancelación de edición.
- [x] T007 [US1] Implementar modelos de mensaje y revisión en `lib/domain/message_revision.dart` conforme a `data-model.md`, sin eliminar compatibilidad de `AiMessage` existente; ejecutar T006.
  - Evidencia: `./scripts/flutter-local.sh test test/message_revision_test.dart --no-pub` → 5 pruebas aprobadas; falta persistencia y conexión al chat.
- [x] T008 [US1] Implementar persistencia transaccional de versiones y asociaciones en `lib/data/message_revision_repository.dart`; probar reinicio y aislamiento con `test/message_revision_test.dart`.
  - Evidencia 2026-11-07: `flutter test --no-pub test/message_revision_repository_test.dart` -> 3 aprobadas (revisiones ordenadas e inmutables y referencias de adjunto tras reabrir, escrituras obsoletas/inválidas/de otro ámbito sin revisión extra, rollback ante ID duplicado); `message_delivery_test.dart` reabre sobre el esquema real v7 migrado por `SqliteWorkoutRepository.open`.
- [x] T009 [US1] Crear `test/message_delivery_test.dart` con fallo previo/posterior a respuesta, múltiples pendientes, adjunto, reinicio, respuesta tardía y cambio de acompañante; exigir orden y ausencia de duplicación.
  - Evidencia 2026-11-07: `flutter test --no-pub test/message_delivery_test.dart` -> 5 aprobadas (cola estable tras reinicio con origen y medio, respuesta y respuesta tardía idempotentes, rechazo confirmado reintenta y `sending` interrumpido no se reenvía, edición no resuelta por respuesta antigua, efecto confirmado no se repite); esquema real v7. `message_delivery_policy_test.dart` -> 3 aprobadas.
- [x] T010 [US1] Implementar estados `pending|sending|answered|failed|uncertain` y reintento persistente en `lib/application/message_delivery.dart`; tras interrupción tratar `sending` como incierto y no repetir efectos sin reconciliación; ejecutar T009.
  - Evidencia 2026-11-07: `flutter test --no-pub test/message_delivery_test.dart` -> 5 aprobadas y `test/message_delivery_policy_test.dart` -> 3 aprobadas; `MessageDelivery` define `pending|sending|answered|failed|uncertain` (`lib/domain/message_revision.dart`), `MessageDeliveryService.openScope` recupera `sending` como incierto sin enviar. Integración al chat: ver T011.
- [ ] T011 [US1] Integrar cola y contexto ordenado en `lib/ui/chat/chat_send.dart`; no truncar mensajes pendientes y asegurar envío al chat de origen; ejecutar T009 y tests existentes del chat.
  - Estado 2026-11-07: parcial: el chat ya usa `MessageDeliveryService` vía `lib/ui/chat/chat_delivery.dart`, pero no hay prueba que acredite cola ordenada de pendientes, no truncado y envío al chat de origen en `chat_send.dart`.
- [x] T012 [US1] Crear `test/message_edit_widget_test.dart` y ofrecer Editar, historial y Reenviar accesibles en `lib/ui/assistant_chat.dart` y `lib/ui/chat/`; comprobar cancelación y estados tras reinicio.
  - Estado 2026-11-07: parcial: existen `lib/ui/chat/message_actions.dart` y `test/message_actions_tap_test.dart`; falta `test/message_edit_widget_test.dart` (cancelación, historial y estados tras reinicio).
- [ ] T013 [US1] Implementar relación mensaje→efecto y corrección transaccional por ID en `lib/data/message_effect_repository.dart`; ante varias relaciones mostrar selección y antes/después; no editar Sheets automáticamente; probar `test/message_effect_test.dart` con 10×10→10×60 y sin duplicados.
  - Estado 2026-11-07: parcial: `lib/data/message_effect_repository.dart` registra efectos por mensaje/revisión (`record` idempotente, `effectsFor`, `effectsForRevision`, `markReverted`, `appliedEffectsSummary`) y el chat los anota (`lib/ui/chat/chat_effects.dart`). Falta la corrección transaccional con antes/después y selección entre varias relaciones (10×10→10×60).
  - Evidencia 2026-11-07: `flutter test --no-pub test/message_effect_test.dart` -> 5 aprobadas (idempotencia y orden, por revisión y ámbito, resumen y marca de corregido, reenvío/edición sin repetir, reinicio con base en archivo); `flutter analyze` sin incidencias y suite completa 829 aprobadas.
- [ ] T014 [US1] En `lib/application/assistant_context.dart` y `lib/ui/chat/chat_archive.dart` distinguir propuesta de efecto confirmado y evitar afirmaciones de escritura no acreditadas; probar respuesta verbal sin efecto y operación incierta en `test/message_effect_test.dart`.
  - Estado 2026-11-07: parcial: solo se anota lo ya aplicado (una propuesta sin confirmar no cuenta) y el reenvío añade al contexto del modelo `appliedEffectsSummary`; `chat_archive.dart` no repite objetivo/tiempos/edición ya aplicados. Falta la distinción en `assistant_context.dart` y la prueba de respuesta verbal sin efecto y operación incierta (el resumen sí separa «incierto», cubierto solo por el repositorio).

## Fase 4 — US2: modificar actividad activa (P1)

**Prueba independiente**: quickstart 3. Depende de T004–T005.

- [x] T015 [US2] Crear `test/activity_live_edit_test.dart` para objetivo 3→4, 4/4, objetivo menor al progreso, nombre, descanso con aviso activo, revisión obsoleta y reinicio; reproducir el 4/3 con fixture sintético.
  - Evidencia 2026-11-07: `flutter test --no-pub test/activity_live_edit_test.dart` -> 9 aprobadas (4/3 sintético, nombre, descanso con aviso activo, aviso obsoleto, reinicio, objetivo 3->4 con historial, objetivo menor al progreso con escrituras inválidas/obsoletas rechazadas, propuesta tipada).
- [x] T016 [US2] Identificar y documentar causa reproducible del contador/error en `docs/005-QA.md`; si no se reproduce, registrar evidencia y aplicar corrección basada en invariantes sin inventar diagnóstico.
  - Evidencia: `test/activity_live_edit_test.dart` reproduce 4/3; diagnóstico en `docs/005-QA.md`. El error visual informado aún no se ha reproducido.
- [ ] T017 [US2] Implementar actualización transaccional por ID y revisión en `lib/data/sqlite_activity_repository.dart`; objetivo positivo o nulo, descanso no negativo, historial inmutable; ejecutar T015.
  - Estado 2026-11-07: parcial: `setActivityTarget` existe y funciona (T015), pero no está verificada la revisión monotónica; la comparación detecta cambios de definición y no el caso ABA.
- [ ] T018 [US2] Validar propuesta tipada y versión esperada en `lib/domain/assistant_blocks.dart` y `lib/application/assistant_context.dart`; rechazar ambiguas y obsoletas con explicación; probar en `test/activity_live_edit_test.dart`.
  - Estado 2026-11-07: parcial: propuesta tipada de objetivo validada (test T015), falta versión esperada monotónica.
- [ ] T019 [US2] Conectar edición local y propuestas en `lib/ui/activity_focus.dart` y `lib/ui/chat/`; mostrar objetivo vigente, conservar controles sin IA y pedir confirmación antes de alterar alarma activa; ejecutar T015.
  - Estado 2026-11-07: parcial: edición local del objetivo en `activity_focus.dart`; falta confirmación de alarma activa por propuestas del chat acreditada con prueba.

## Fase 5 — US3: conexión y selección Sheets (P2)

**Prueba independiente**: quickstart 4. No depende de US1/US2.

- [x] T020 [US3] Crear `test/sheets_onboarding_test.dart` con cuenta nueva/existente, lista parcial, pestaña, cancelación, pérdida de permisos y ámbito de acompañante.
  - Evidencia: `test/sheets_onboarding_test.dart`, `test/google_sheets_import_test.dart` y `test/sheet_sync_ui_test.dart`; 18 pruebas de interfaz y servicio aprobadas con transporte controlado.
- [x] T021 [US3] Integrar conexión y selector existente en un recorrido de `lib/ui/google_sheets_import.dart` y `lib/ui/chat/chat_sheet.dart`, manteniendo configuración previa hasta confirmar; ejecutar T020.
  - Estado 2026-11-07: validado solo con transporte simulado; OAuth real pendiente.
  - Evidencia: `lib/ui/sheet_sync.dart` permite revisar y cargar la pestaña tras conectar; prueba widget cubre cancelación y confirmación, y `ai_settings_chat_test.dart` verifica recarga del contexto del chat. OAuth real pendiente.
- [x] T022 [US3] Añadir `integration_test/sheets_onboarding_test.dart` con transporte controlado y registrar validación real pendiente en `docs/005-QA.md`; no usar hoja personal.
  - Estado 2026-11-07: validado solo con transporte sintético; Google real pendiente.
  - Evidencia: `./scripts/flutter-local.sh test integration_test/sheets_onboarding_test.dart -d emulator-5556` → 1 prueba aprobada con transporte sintético; Google real pendiente, registrado en `docs/005-QA.md`.

## Fase 6 — US4: memoria y copia (P2)

**Prueba independiente**: quickstart 5. Depende de T004–T005.

- [x] T023 [US4] Crear `test/companion_memory_test.dart` para ámbitos, archivo, petición explícita, revisión, borrado, tamaño máximo 2000, máximo 20 recuerdos/12000 caracteres de contexto y referencia ambigua.
  - Evidencia 2026-11-06: el fichero cubre los 2000 caracteres, origen explícito/usuario, revisiones, borrado, aislamiento de ámbitos, 20/12000 y referencia ambigua, y ahora un grupo nuevo con SQLite real (`databaseFactoryFfi`) que comprueba persistencia tras cerrar/reabrir la BD, aislamiento por perfil/acompañante, borrado excluido de la selección tras reabrir, límites 20/12000 y ambigüedad por repositorio. `./scripts/flutter-local.sh test --no-pub test/companion_memory_test.dart test/companion_memory_repository_test.dart test/memory_proposal_test.dart test/assistant_context_test.dart` → 48 aprobadas. Suite completa del momento → 819 aprobadas.
- [x] T024 [US4] Implementar `lib/domain/companion_memory.dart` y `lib/data/companion_memory_repository.dart` con campos y estados de `data-model.md`; ejecutar T023.
  - Evidencia 2026-11-06: dominio y repositorio verificados contra la tabla real v7 `trackia_companion_memories` (`_createTrackiaV7`) con las pruebas de T023 y `companion_memory_repository_test.dart`; formato de fila (source/status/revision/timestamps) coincide con la migración. Faltan UI de revisión/edición y conexión de chat (T027) y copia Google (T029–T031).
- [x] T025 [US4] Crear `test/memory_proposal_test.dart` para `save|ask|ignore`, instrucciones explícitas, contenido no confiable y aceptación/rechazo; ninguna respuesta libre ejecuta efectos.
  - Evidencia: `test/memory_proposal_test.dart` → 6 pruebas aprobadas; el servicio aún no está conectado al chat ni guarda datos.
- [x] T026 [US4] Implementar propuestas estructuradas y selección acotada en `lib/application/companion_memory_service.dart`; incorporar recuerdos como datos delimitados en `lib/application/assistant_context.dart`; ejecutar T025.
  - Estado 2026-11-07: conexión pendiente: `acceptPersisted` y el bloque de contexto funcionan en aislado, pero ningún flujo de `lib/ui/` usa `CompanionMemoryService`/`CompanionMemoryRepository` ni pasa recuerdos al contexto; por eso la casilla [x] cubre solo servicio y contexto, no el chat.
  - Evidencia 2026-11-06: `CompanionMemoryService.acceptPersisted` conecta la propuesta aprobada con `CompanionMemoryRepository` (tabla v7): ámbito fijo por perfil (mismatch → ArgumentError), límite 2000, fuente explícita/inferida según petición del usuario, `source_message_id` conservado, `ignore` sin filas y `ask` se guarda solo en la aceptación (además `parseProposal` ahora retiene el contenido de `ask` para que sea persistible y mantiene `ignore` sin datos). Pruebas: `memory_proposal_test.dart` y `companion_memory_test.dart` con SQLite real. En `assistant_context.dart` los recuerdos entran como bloque delimitado (`assistantMemoryDataStart`/`End`, claves `cuenta-recuerdos`) etiquetado como dato del usuario de solo lectura, contenido no confiable, sin instrucciones ejecutables, con límites reaplicados (20/12000, borrados fuera) y aviso de referencia ambigua «pregunta al usuario»; sin recuerdos el prompt queda byte a byte igual (golden fixtures intactas). Pruebas nuevas en `assistant_context_test.dart` (6) con SQLite real del pipeline repo→contexto. Las 6 pruebas de `memory_proposal_test.dart` (T025) siguen en verde. Pendiente: llamada real desde `lib/ui/chat/` (agente US1-chat, archivos no poseídos aquí); por ahora ningún flujo del chat invoca `acceptPersisted` ni alimenta las memorias al contexto.
- [ ] T027 [US4] Crear pantalla de consulta, edición, confirmación y borrado en `lib/ui/companion_memory.dart` y enlazar desde `lib/ui/companion_settings.dart`; probar `test/companion_memory_ui_test.dart` y persistencia al archivar.
- [x] T028 [US4] Crear `test/memory_cloud_test.dart` con snapshots v1, cuenta/ámbito, conflicto, copia dañada, cancelación, permisos, respuesta incierta y borrados local/nube separados.
  - Evidencia 2026-11-07: `flutter test --no-pub test/memory_cloud_test.dart` -> 9 aprobadas con transporte simulado (snapshot v1 determinista, ámbito perfil/acompañante e independiente de cuenta Google, copia dañada o con credenciales rechazada, conflicto de revisión, cancelación y permiso denegado, escritura condicional con resultado incierto, borrado en nube como operación separada). Sin Google real.
- [ ] T029 [US4] Implementar serialización sin secretos en `lib/data/memory_snapshot.dart` y vista previa de importación por ámbito explícito; ejecutar T028.
  - Estado 2026-11-07: parcial: `lib/data/memory_snapshot.dart` serializa sin secretos y rechaza ámbito distinto (`memory_snapshot_test.dart` -> 5 aprobadas); falta vista previa de importación.
- [ ] T030 [US4] Implementar adaptador `lib/data/memory_google_drive.dart` usando appDataFolder y alcance mínimo `drive.appdata`, autorización explícita y comprobación de identidad; gestionar respuestas inciertas y conflictos sin sobreescritura automática; ejecutar T028 con transporte simulado.
  - Estado 2026-11-07: pendiente: `lib/data/memory_google_drive.dart` es solo un servicio sobre transporte abstracto; no hay adaptador real con `appDataFolder`/`drive.appdata` ni autorización.
- [ ] T031 [US4] Conectar guardar/cargar/borrar nube y borrar local como operaciones distintas en `lib/ui/companion_memory.dart`, mostrando cuenta, fecha, conflicto y fallo; ejecutar T028 y `test/companion_memory_ui_test.dart`.
- [ ] T032 [US4] Documentar en `docs/005-MEMORIA.md` permisos adicionales, privacidad sin prometer cifrado de extremo a extremo, límites del proveedor y procedimiento de validación Google real con cuenta y datos desechables; ejecutar cuando haya autorización y registrar resultado o bloqueo.

## Fase 7 — US5: personalidad y apoyo general (P2)

**Prueba independiente**: quickstart 6. Depende de T004–T005; memoria opcional.

- [x] T033 [US5] Crear `test/personality_custom_test.dart`: texto libre hasta 4000 caracteres por acompañante, sugerencias editables, aislamiento y sin cambios de permisos.
  - Evidencia: pruebas de personalidad y ajustes aprobadas con persistencia de perfil y límite de 4000 caracteres.
- [x] T034 [US5] Añadir personalidad personalizada y ayuda opcional de IA en `lib/ui/companion_settings.dart` y `lib/ui/companion_creator.dart`; persistir en configuración por ámbito y ejecutar T033.
  - Estado 2026-11-07: validado con cliente simulado; proveedor de IA real no validado.
  - Evidencia: ajustes permiten editar y pedir una propuesta al proveedor del perfil; `test/companion_settings_test.dart` → 16 pruebas aprobadas, incluidos aceptar, cancelar y fallo con cliente simulado. IA real no validada.
- [x] T035 [US5] Crear `test/support_agreement_test.dart` con objetivos libres, sin número obligatorio, medida finita no negativa, creación confirmada, pausa, modificación, finalización y eventos históricos inmutables.
  - Evidencia 2026-11-07: `flutter test --no-pub test/support_agreement_test.dart` -> 5 aprobadas y `test/support_agreement_service_test.dart` -> 4 aprobadas (objetivo libre sin unidad ni medida, medida finita no negativa, creación solo tras consentimiento, pausa/reanudación/finalización con revisiones, modificación con instantánea previa, eventos manuales inmutables y con ámbito).
- [ ] T036 [US5] Implementar modelo y repositorio en `lib/domain/support_agreement.dart` y `lib/data/support_agreement_repository.dart` con estados y límites de `data-model.md`; ejecutar T035.
  - Estado 2026-11-07: parcial: modelo `lib/domain/support_agreement.dart` hecho; falta `lib/data/support_agreement_repository.dart` y esquema en la migración.
- [x] T037 [US5] Implementar propuestas validadas en `lib/application/support_agreement_service.dart`: la IA propone, usuario confirma, motor local cuenta solo eventos confirmados; ejecutar T035 sin red.
  - Estado 2026-11-07: sin conexión real: servicio puro sin UI ni persistencia; la casilla [x] cubre solo la lógica.
  - Evidencia: `support_agreement_service_test.dart` y `support_agreement_test.dart` → 9 pruebas aprobadas; servicio puro aún no conectado a interfaz ni persistencia.
- [ ] T038 [US5] Añadir creación, seguimiento, pausa y modificación en `lib/ui/support_agreement.dart`, accesible desde chat; integrar avisos existentes sin vigilar otras apps; probar `test/support_agreement_ui_test.dart` con varios objetivos distintos.
- [ ] T039 [US5] Probar permisos concedidos/denegados y reinicio en `integration_test/support_agreement_android_test.dart`; registrar límites y manejo de temas sensibles en `docs/005-QA.md`.

## Fase 8 — US6: idiomas y acabado (P2)

**Prueba independiente**: quickstart 7. Depende de textos finales de US1–US5.

- [x] T040 [US6] Inventariar cadenas visibles Dart y nativas, errores, notificaciones, plurales y formatos en `docs/005-LOCALIZACION.md`; incluir pantallas y pendientes concretos.
  - Evidencia: inventario de pantallas, rutas, avisos y pendientes en `docs/005-LOCALIZACION.md`.
- [x] T041 [US6] Configurar generación de localizaciones y preferencia `system|es|en|ar` en `l10n.yaml`, `pubspec.yaml` y `lib/application/locale_settings.dart`; crear ARB de los tres idiomas y probar persistencia en `test/locale_settings_test.dart`.
  - Evidencia: `./scripts/flutter-local.sh test test/locale_settings_test.dart` → 2 pruebas aprobadas; analyze focalizado limpio. Traducciones y selector de usuario quedan para las tareas siguientes.
- [ ] T042 [US6] Sustituir cadenas de inicio, bienvenida y acompañantes por claves en `lib/ui/companions.dart`, `lib/ui/welcome.dart` y `lib/ui/companion_settings.dart`; traducir es/en/ar y probar RTL.
  - Estado 2026-11-07: parcial: ver `test/localization_t042_test.dart`; falta cubrir todas las pantallas y RTL del alcance.
- [ ] T043 [US6] Localizar chat, actividad, acuerdos y memoria en `lib/ui/assistant_chat.dart`, `lib/ui/chat/`, `lib/ui/activity_focus.dart`, `lib/ui/support_agreement.dart` y `lib/ui/companion_memory.dart`; aislar direccionalidad de texto de usuario.
  - Estado 2026-11-07: parcial: chat y actividad con cadenas parciales; acuerdos y memoria no existen aún (T027, T038).
- [ ] T044 [US6] Localizar Sheets, IA, transferencia, errores y avisos en `lib/ui/google_sheets_import.dart`, `lib/ui/ai_settings.dart`, `lib/ui/data_transfer.dart`, `lib/application/` y recursos nativos `android/app/src/main/res/`; no traducir datos del usuario.
  - Estado 2026-11-07: parcial: Sheets localizado en parte (`test/sheets_localization_t044_test.dart`); faltan IA, transferencia, errores y recursos nativos.
- [ ] T045 [US6] Completar inventario T040 y agregar prueba de claves faltantes y recorridos es/en/ar en `test/localization_test.dart`; cubrir plurales, fechas, fuente grande, lector de pantalla, RTL y reinicio.
- [x] T046 [US6] Añadir logo existente en `lib/ui/companions.dart` con alternativa semántica y frases de espera localizadas y variadas en `lib/ui/chat/`; probar presentación en `test/locale_settings_test.dart`.
  - Evidencia: logo con descripción accesible y cuatro frases es/en/ar; `companion_dashboard_test.dart`, `locale_settings_test.dart` y `ai_settings_chat_test.dart` → 25 pruebas aprobadas.
- [x] T047 [US6] Solicitar respuestas del modelo en el idioma elegido en `lib/application/assistant_context.dart` sin traducir ni alterar originales; probar contexto en `test/assistant_context_test.dart`.
  - Evidencia: `assistant_context_test.dart` y `locale_settings_test.dart` aprobadas; las referencias doradas se actualizaron para la instrucción de idioma.

## Fase 9 — US7: plan iOS (P3)

**Prueba independiente**: quickstart 8. Independiente de implementación Android.

- [x] T048 [P] [US7] Inventariar plugins, canales y condicionales de plataforma en `docs/005-IOS-PLAN.md`, con rutas y estado no verificado por capacidad.
  - Evidencia: `docs/005-IOS-PLAN.md` §1 inventaría rutas, plugins y canales; inspección estática, iOS sin validar.
- [x] T049 [US7] Documentar en `docs/005-IOS-PLAN.md` pasos y comandos para Xcode, firma, compilación/simulador, OAuth Google, avisos, archivos, almacenamiento e IA local; para cada uno indicar dependencia, adaptación y prueba en dispositivo.
  - Evidencia: `docs/005-IOS-PLAN.md` incluye preparación, matriz por capacidad y pruebas; Xcode completo no está disponible en este equipo.
- [x] T050 [US7] Añadir a `docs/005-IOS-PLAN.md` criterios de aceptación, plan de regresión, alternativas TestFlight/App Store, cuenta y firma requeridas, y decisión de distribución aún pendiente; no declarar funcional sin evidencia.
  - Evidencia: `docs/005-IOS-PLAN.md` incluye criterios y alternativas de distribución sin afirmar compilación o publicación.

## Fase 10 — Cierre

- [ ] T051 Ejecutar `./scripts/flutter-local.sh analyze`, `./scripts/flutter-local.sh test` y pruebas de integración nuevas por archivo; registrar resultados y fallos en `docs/005-QA.md`, sin ocultar bloqueos externos.
- [ ] T052 Verificar matriz FR-001–FR-015 y SC-001–SC-006 contra tareas y evidencia en `docs/005-QA.md`; corregir huecos y actualizar `specs/README.md` y `README.md` con estado real.
- [ ] T053 Preparar recorridos de aceptación con datos sintéticos y evidencia diferenciada de Google real, teléfono y iOS en `docs/005-QA.md`; solicitar disponibilidad solo cuando sea necesaria, sin publicar ni instalar automáticamente.

## Dependencias y estrategia

T001–T005 → US1 y US2; US3 puede ejecutarse tras T001–T002; US4/US5 tras T005; US6 después de los textos finales; US7 tras T001 y en paralelo con historias de producto. T051–T053 cierran todas las historias. MVP: US1 completo; siguiente incremento US2. Las tareas independientes T020 y T048 pueden prepararse en paralelo con US1 si no se comparten archivos; no hay obligación de usar agentes. Ejecutar las pruebas de cada fase antes de pasar a la siguiente y actualizar la evidencia.

## Resumen de estado (2026-11-07)

Casillas [x] tras contrastar con el código y ejecutar sus pruebas puntuales; ver evidencia en cada tarea.

- Hechas (30): T001–T005, T007–T010, T015, T016, T020–T026, T028, T033–T035, T037, T040, T041, T046–T050. Con reservas: T021, T022 y T034 solo con transporte/cliente simulado; T026 sin conexión al chat; T037 solo lógica sin UI ni persistencia.
- Parciales (casilla vacía): T006 (falta cancelación), T011, T013, T017, T018, T019, T029 (falta vista previa de importación), T036 (falta repositorio), T042, T043, T044.
- Pendientes: T014, T027, T030 (sin adaptador Drive real), T031, T032, T038, T039, T045, T051, T052, T053.
- Validación real aún no hecha: Google OAuth/Drive, IA real, Android antiguo e interrupción de proceso (T004), iOS.

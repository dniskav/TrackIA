# Inventario de localización (US6)

Estado: inventario inicial para T040, antes de introducir claves de localización. La interfaz está escrita principalmente en español. El inventario cubre cadenas renderizadas por Flutter, mensajes de error que llegan a la interfaz, texto de notificaciones Android y formatos dependientes de idioma/región. Hay contenido de dominio que debe seguir siendo literal (nombres y mensajes escritos por la persona, nombres de ejercicios/acompañantes/hojas, texto de Sheets y contenido generado por IA).

## Pantallas y superficies visibles

| Superficie | Rutas principales | Contenido que debe localizarse |
| --- | --- | --- |
| Inicio, tablero, entrenamiento activo, historial y diálogos de sesión/serie | `lib/ui/gym_home.dart`, `lib/ui/session_control.dart`, `lib/ui/activity_dialogs.dart`, `lib/ui/activity_summary.dart`, `lib/ui/instant_record.dart`, `lib/ui/gym_widgets.dart` | Navegación Hoy/Rutinas/Historial; estados vacíos, títulos y estadísticas; crear/editar/finalizar; ejercicio/serie/repetición/peso/descanso; confirmaciones y acciones; tooltips; validaciones. |
| Rutinas, actividad enfocada y temporizador | `lib/ui/routines.dart`, `lib/ui/activity_focus.dart`, `lib/ui/focus_idle_bar.dart`, `lib/ui/rest_timer_panel.dart`, `lib/ui/timer_ring.dart` | Preparar/iniciar/pausar/reanudar/cerrar; estados de actividad y etiquetas accesibles del temporizador; plurales de series, ejercicios, minutos y segundos. |
| Chat y mensajes | `lib/ui/assistant_chat.dart`, `lib/ui/chat/` (`chat_header.dart`, `chat_sheet.dart`, `chat_game.dart`, `chat_send.dart`, `chat_attachments.dart`, `chat_archive.dart`), `lib/ui/chat_message.dart`, `lib/ui/archived_chats.dart` | Cabecera, menús, entrada/adjuntos, dictado y estado de escucha, espera, error/reintento, actividad propuesta, archivos y resumen de continuidad. El texto del usuario, del modelo y los títulos de conversación son datos, no recursos traducibles. |
| Acompañantes, bienvenida y personalización | `lib/ui/companions.dart`, `lib/ui/companion_creator.dart`, `lib/ui/companion_settings.dart`, `lib/ui/companion_style.dart`, `lib/ui/welcome.dart` | Crear/editar/eliminar, perfiles vacíos, pasos de bienvenida, modos y avisos, días libres, reglas, metas, estilos neutral/motivador, opciones y validaciones. Los nombres/descripciones que se crean son datos del usuario. |
| Sheets, IA y cuentas | `lib/ui/google_sheets_import.dart`, `lib/ui/sheet_sync.dart`, `lib/ui/ai_settings.dart`, `lib/ui/ai_per_companion.dart`, `lib/ui/accounts.dart`, `lib/ui/settings.dart` | Permisos y conexión, selección de hoja/pestaña, importación y revisión, diagnósticos, configuración/proveedor/modelo de IA, estados de carga y desconexión. No traducir nombres de pestañas, correos, modelos ni contenido de celdas. |
| Copias, apariencia, avisos y progreso | `lib/ui/data_transfer.dart`, `lib/ui/appearance.dart`, `lib/ui/notification_settings.dart`, `lib/ui/progress_screen.dart`, `lib/ui/goal_ring.dart`, `lib/ui/proposal_card.dart`, `lib/ui/game_proposal_cards.dart` | Exportar/restaurar/importar, confirmaciones, tema y tamaño de texto, permisos de notificación, logros, progreso, propuestas y unidades. |
| Elementos reutilizables y marca | `lib/ui/trackia_mark.dart`, `lib/ui/rule_text.dart`, `lib/ui/gym_widgets.dart`, `lib/ui/goal_ring.dart` | Etiquetas semánticas, estados y componentes comunes; comprobar que tooltips y nombres accesibles también estén cubiertos. El nombre de producto TrackIA se conserva. |

La lista de pantallas prioritarias para la sustitución prevista está concretada en T042–T044 de `specs/005-conversacion-memoria/tasks.md`: bienvenida y acompañantes; chat, actividad, acuerdos y memoria; Sheets, IA, transferencia, errores y avisos. Los archivos de arriba amplían el recorrido real a inicio, ajustes, actividad y progreso para que no queden superficies antiguas fuera del barrido.

## Errores, avisos y estados asíncronos

Las cadenas de error no están centralizadas: varias pantallas muestran directamente `error`, excepciones interpoladas o resultados de servicios. Deben convertirse en mensajes localizables y seguros (sin exponer trazas/tokens):

| Caso | Origen/puntos de presentación |
| --- | --- |
| IA no disponible, proveedor/modelo sin configurar, conexión fallida, espera/cancelación y errores de respuesta | `lib/application/ai_availability.dart`, `lib/application/assistant_context.dart`, `lib/data/ai_client.dart`, `lib/data/local_model_preflight.dart`, `lib/data/local_model_runtime.dart`, `lib/ui/assistant_chat.dart`, `lib/ui/ai_settings.dart` |
| Fallo de carga/guardado/borrado/validación de acompañante y perfil | `lib/ui/companions.dart`, `lib/ui/companion_creator.dart`, `lib/ui/companion_settings.dart`, `lib/ui/accounts.dart`, `lib/data/profile_store.dart` |
| Errores de autorización, lectura, escritura, importación/interpretación y sincronización de Sheets | `lib/data/chatgpt_auth.dart`, `lib/data/sheet_sync_service.dart`, `lib/data/sheet_plan_service.dart`, `lib/application/sheet_automation.dart`, `lib/ui/google_sheets_import.dart`, `lib/ui/sheet_sync.dart`, `lib/ui/data_transfer.dart`; además `android/app/src/main/kotlin/com/gymia/app/GoogleSheetsBridge.kt` y `SheetsWriter.kt` exponen errores por MethodChannel. |
| Fallo al crear/restaurar/exportar copia, JSON inválido, archivo incompatible o importación parcial | `lib/ui/data_transfer.dart`, `lib/domain/transfer.dart`, `lib/domain/transfer_repository.dart` |
| Error de almacenamiento/actividad, estados vacíos y carga | `lib/ui/gym_home.dart`, `lib/ui/activity_focus.dart`, `lib/ui/progress_screen.dart`, repositorios bajo `lib/data/` |
| Permisos denegados, avisos desactivados/bloqueados y programación fallida | `lib/application/rest_notifications.dart`, `lib/application/reminder_scheduler.dart`, `lib/ui/notification_settings.dart`, `lib/ui/companion_settings.dart` |

Revisar en cada flujo tanto `SnackBar`/diálogos como texto inline, botón de reintento, `tooltip`, `Semantics` y etiquetas de accesibilidad. En especial `Text(error)`, `Text('$e')`, `availability.message`, `connectionMessage`, `testStatus` y resultados de diagnóstico pueden ser contenido dinámico que hoy combina textos traducibles con detalles técnicos.

## Notificaciones y recursos nativos

- Notificaciones Android de descanso/actividad y acciones (iniciar, cerrar, detener, prueba y fallo de acción): `android/app/src/main/kotlin/com/gymia/app/RestNotifications.kt`. El canal se crea con el nombre literal «Descanso de entrenamiento» y los títulos/cuerpos de notificación también están en español; el mensaje de fallo de acción debe incluirse en las traducciones nativas.
- Recordatorios programados y canal: `android/app/src/main/kotlin/com/gymia/app/ReminderReceiver.kt`, con persistencia/reprogramación tras reinicio en `BootReceiver.kt`. Hay selección de frases, variables de mínimo/meta/nombre y pluralización; separar plantillas traducibles de los datos inyectados.
- Integración de permisos y acciones: `android/app/src/main/kotlin/com/gymia/app/MainActivity.kt`, `android/app/src/main/AndroidManifest.xml`; texto/errores de Sheets nativo en `GoogleSheetsBridge.kt` y `SheetsWriter.kt`.
- El directorio actual `android/app/src/main/res/values/` solo contiene colores/estilos y no hay recursos `values/strings.xml` ni variantes `values-en`, `values-ar`; deben crearse para cualquier nombre de canal, descripción y texto lanzado por Android. Los nombres de canal ya creados pueden quedar guardados por Android, así que revisar migración/identificador si se cambia el canal.
- iOS no tiene todavía una implementación equivalente de notificaciones ni catálogo de strings (`ios/Runner/Info.plist`, `ios/Runner/AppDelegate.swift`); el plan de plataforma está en `docs/005-IOS-PLAN.md`. T040 cubre lo nativo existente en Android y deja iOS como pendiente de alcance posterior.
- `android/app/src/main/res/drawable*/launch_background.xml`, `values/styles.xml`, `values-night/styles.xml` son recursos visuales/tema; revisar solo si se añaden textos nativos. El manifiesto contiene etiquetas/metadata de plataforma que no necesariamente se muestran al usuario.

## Plurales, fechas, números y unidades

- Hay contadores interpolados con singular/plural manual y sufijos literales: sesiones, ejercicios, series, errores, registros, semanas, días, minutos y segundos. Puntos detectados: `lib/ui/data_transfer.dart`, `lib/ui/gym_home.dart`, `lib/ui/companion_settings.dart`, `lib/ui/progress_screen.dart`, `lib/application/progress_engine.dart`, `lib/application/reminder_scheduler.dart`, `lib/ui/timer_ring.dart`. No depender de ternarios `n == 1`, sufijos `s` o gramática española; definir recursos plurales con argumentos y categorías de ICU para es/en/ar (incluido árabe cero/uno/dos/few/many/other).
- Fechas/horas se formatean con patrones y en algunos casos locale español fijo: `lib/ui/gym_home.dart` (por ejemplo `d MMM yyyy`, `d 'de' MMMM`, `d/M/yyyy HH:mm:ss`), `lib/ui/data_transfer.dart` (`d/M/yyyy HH:mm` y timestamp de nombre de archivo), `lib/ui/sheet_sync.dart` (`dd/MM/yyyy HH:mm`), además de resúmenes de chat/progreso. Usar locale efectivo y formato accesible; distinguir formato de visualización de formato estable de exportación/nombre de archivo.
- Números decimales de peso/volumen, porcentajes, valores de estadísticas y unidades: `lib/ui/gym_widgets.dart`, `lib/ui/instant_record.dart`, `lib/ui/activity_summary.dart`, `lib/ui/progress_screen.dart`, `lib/ui/goal_ring.dart`; validar separador decimal por locale sin cambiar valores guardados ni fórmulas.
- Duración de cuenta atrás y descanso: `lib/ui/timer_ring.dart`, `lib/ui/rule_text.dart`, `lib/application/rest_notifications.dart`, `android/app/src/main/kotlin/com/gymia/app/RestNotifications.kt`. Definir orden, abreviaturas, plural y texto para lector de pantalla en cada idioma.
- Persisten palabras de día/mes y abreviaturas locales construidas a mano; sustituir por `intl`/`MaterialLocalizations` según el caso. Mantener identificadores técnicos, claves de almacenamiento y formatos de intercambio como ISO/JSON invariantes.

## Idiomas, dirección y accesibilidad

El objetivo establecido es `system|es|en|ar` y catálogos es/en/ar (T041). No hay todavía `l10n.yaml`, ARB ni preferencia de idioma. Inglés requiere revisión de expansión de texto. Árabe requiere RTL a nivel de aplicación y verificación de iconos/controles direccionales, navegación, alineación y campos mixtos. Texto libre (chat, nombres, correos, títulos de Sheets) conserva su dirección según contenido; no aplicar RTL forzado dentro de esos datos. Mantener labels semánticas, anuncios de temporizador y acciones de botones además del texto visual. Probar tamaño de fuente grande y lector de pantalla, además de persistencia/reinicio.

## Pendientes concretos

1. **T041**: añadir configuración de generación, catálogos es/en/ar y preferencia `system|es|en|ar`; fijar política de locale, formato y dirección.
2. **T042**: migrar inicio/bienvenida/acompañantes, incluidos errores, tooltips y etiquetas semánticas.
3. **T043**: migrar chat, actividad, acuerdos y memoria; conservar dirección natural del texto escrito por usuario/modelo.
4. **T044**: migrar Sheets, IA, transferencia, mensajes de error y avisos; añadir recursos nativos Android y traducir notificaciones/canales. No traducir contenido de usuario.
5. **T045**: completar este inventario durante el barrido de claves; prueba de claves faltantes y recorridos es/en/ar con plurales, fechas, tamaño grande, lector de pantalla, RTL y reinicio.
6. **T046**: localizar frases variadas de espera y proporcionar alternativa semántica al logo existente.
7. **T047**: pedir al modelo responder en idioma elegido sin traducir originales; validar contexto.
8. Repasar superficies no enumeradas por las tareas de migración inicial (rutinas, ajustes generales, historial/archivos, apariencia, notificaciones, progreso y widgets reutilizables) y todos los errores dinámicos. Mantener sin traducir nombres/valores de datos, texto del usuario, contenido de modelo, títulos/celdas de Sheets, correos, nombres de proveedor/modelo e identificadores.

Este documento es un mapa de trabajo, no un catálogo final de claves. T045 debe actualizarlo con las rutas y claves reales después de T041–T044.

## Recursos nativos Android (hecho)

- Textos nativos en `android/app/src/main/res/values/strings.xml` (español, valor por defecto, idéntico al literal anterior), `values-en/` y `values-ar/`. Kotlin usa `getString(R.string.x)` y `%1$s`/`%1$d` para parámetros; no hay `plurals` (etiquetas invariables).
- Cubre: canales (nombre y descripción), títulos/cuerpos y acciones (Iniciar/Cerrar/Parar) de `RestNotifications.kt`, nombres por defecto («Actividad», «Entrenamiento»), errores de `MainActivity.kt` y `GoogleSheetsBridge.kt`, y la etiqueta del intent-filter «Importar en TrackIA» del manifiesto. El nombre de la app (`TrackIA`) no se traduce.
- **Idioma: el del SISTEMA** (resolución de recursos de Android), no el ajuste interno de idioma de la app. Si el usuario fuerza otro idioma en la app, las notificaciones y errores nativos siguen el del sistema.
- IDs de canal sin cambios (`gymia_rest`, `trackia_timer_alarm_v1`, `trackia_reminders_v1`). Cada `createNotificationChannel` con un ID existente actualiza nombre y descripción, así que se refrescan al volver a crearse el canal (en cada aviso o al abrir sus ajustes).
- `gymia_rest` conserva dos nombres heredados: «Actividad y descanso» (`channel_rest_name`) y «Descanso de entrenamiento» (`channel_rest_test_name`, solo en la notificación de prueba). Convendría unificarlos.
- Pendiente: las frases de recordatorio (`templates` del snapshot JSON) y `companionName` las genera Dart (`lib/domain/reminder.dart`); localizarlas allí. `SheetsWriter.kt` (errores `GOOGLE_SYNC`) no tiene `Context` y su test JVM fija el flujo; sigue en español. No existe módulo Wear.

# TrackIA iOS: inventario y plan de validación

Estado: plan de trabajo basado en inspección estática del repositorio el 2026-11-05. No acredita que la app compile, arranque, complete OAuth o funcione en iPhone. El equipo local tiene `xcodebuild`, pero al consultarlo informó que el directorio activo es Command Line Tools y que hace falta Xcode; `flutter` no está disponible en el `PATH`. Por tanto no se pudo validar con Xcode, simulador ni dispositivo. No se usaron cuentas, credenciales ni datos personales.

## 1. Evidencia e inventario (T048)

| Área | Evidencia en repositorio | Estado y trabajo iOS |
|---|---|---|
| Esqueleto Xcode | `ios/Runner.xcodeproj`, `ios/Runner.xcworkspace`, `ios/Runner/AppDelegate.swift`, esquema `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | Existe proyecto Flutter estándar y `AppDelegate` registra `GeneratedPluginRegistrant`. Abrir y compilar requiere Xcode completo; sin validar. |
| Configuración de app | `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Info.plist` | Bundle ID actual `com.gymia.app`; deployment target configurado en 12.0; Swift 5. No hay `DEVELOPMENT_TEAM` fijado. Revisar mínimo soportado por cada plugin y el deployment target que requiera la versión efectiva de Xcode/plugins. |
| Plugins nativos iOS registrados | `ios/Runner/GeneratedPluginRegistrant.m` | Registrados: `file_picker`, `flutter_secure_storage`, `image_picker_ios`, `integration_test` (solo pruebas), `path_provider_foundation`, `share_plus`, `speech_to_text` y `sqflite_darwin`. Es archivo generado: regenerar con Flutter/Pods, no editar a mano. |
| Dependencias Dart | `pubspec.yaml` | Paquetes principales: `sqflite`, `path`, `uuid`, `intl`, `file_picker`, `image_picker`, `share_plus`, `path_provider`, `csv`, `excel`, `archive`, `flutter_secure_storage`, `speech_to_text`, `flutter_markdown_plus`, `crypto`, `jose` y `llama_cpp_dart` local. La presencia en pubspec o registrant no demuestra funcionamiento en iOS. |
| SQLite y archivos locales | `lib/data/sqlite_workout_repository.dart`, `lib/data/chat_store.dart`, `lib/data/progress_repository.dart`, `lib/ui/data_transfer.dart` | La persistencia usa `sqflite` y rutas de archivo; sus plugins Darwin están registrados. Importación/exportación emplea además `file_picker`, `path_provider`, CSV/Excel/ZIP. Confirmar ciclo de vida, acceso a documentos seleccionados, compartir/exportar y restauración de backup en dispositivo. |
| Puentes Flutter/Android | Canales Dart en `lib/data/profile_store.dart`, `lib/data/chatgpt_auth.dart`, `lib/data/local_model_preflight.dart`, `lib/application/reminder_scheduler.dart`, `lib/application/rest_notifications.dart`, `lib/ui/app.dart`, `lib/ui/data_transfer.dart`; implementación bajo `android/app/src/main/kotlin/com/gymia/app/MainActivity.kt` y `GoogleSheetsBridge.kt` | No se encontró implementación equivalente en `ios/Runner`. Los canales son `com.gymia.app/google-sheets`, `com.gymia.app/chatgpt`, `com.trackia/local-model`, `com.gymia.app/reminders`, `com.gymia.app/rest-notifications` y `com.gymia.app/import`. Las llamadas que los alcancen pueden devolver `MissingPluginException`; se deben adaptar con código iOS o comportamiento alternativo explícito. |
| Condicionales de plataforma | `lib/application/reminder_scheduler.dart`; `lib/ui/chat/chat_sheet.dart`; `lib/ui/data_transfer.dart`; `lib/ui/chat/chat_attachments.dart`; `lib/ui/assistant_chat.dart` | Scheduler limita soporte a Android (`Platform.isAndroid`); Sheets y varias operaciones/adjuntos también restringen su ruta Android. Revisar cada guardia para ofrecer una alternativa iOS o desactivar controles con mensaje entendible. |
| Google Sheets/OAuth Google | `android/app/src/main/kotlin/com/gymia/app/GoogleSheetsBridge.kt`, `android/app/build.gradle.kts`, `lib/data/profile_store.dart`, `lib/ui/google_sheets_import.dart`, `docs/0.3.8-GOOGLE-AUTH.md` | La autenticación nativa y llamadas de Sheets se implementan con Google Play Services en Android. No hay cliente iOS, URL scheme OAuth de Google ni configuración GoogleService-Info en `ios/`. La documentación del flujo Android no es evidencia iOS. Diseñar y registrar cliente OAuth para iOS, redirect URI y scopes antes de habilitarlo. |
| Inicio de sesión ChatGPT | `lib/data/chatgpt_auth.dart`; canal Android en `MainActivity.kt`; URL de uso en `lib/data/chatgpt_auth.dart` | OAuth en Dart coordina apertura y retorno a través del canal `com.gymia.app/chatgpt`; `MainActivity` abre navegador y reanuda el flujo. `Info.plist` no declara URL types ni callback scheme. Debe implementarse apertura de navegador/Universal Link o URL scheme y retorno seguro en iOS; comprobar state/PKCE, cancelación, reanudación y almacenamiento seguro en el dispositivo. |
| Notificaciones y avisos | `lib/application/reminder_scheduler.dart`, `lib/application/rest_notifications.dart`, `MainActivity.kt`, `android/app/src/main/kotlin/com/gymia/app/ReminderReceiver.kt`, `RestNotifications.kt`; `ios/Runner/Info.plist` | Recordatorios, acciones y avisos en reposo tienen implementación Kotlin mediante canales Android. No hay equivalente iOS ni configuración de capacidades de notificaciones en Xcode. No asumir ejecución exacta en segundo plano: diseñar con UserNotifications y límites de iOS, pedir permiso en contexto y probar entrega/acciones en dispositivo. |
| Voz, cámara y fotos | `ios/Runner/Info.plist`; `pubspec.yaml` | Ya existen descripciones de privacidad para cámara, fotos, reconocimiento de voz y micrófono; `image_picker_ios` y `speech_to_text` aparecen registrados. Validar prompts, denegación, ajustes del sistema y flujo de reintento. |
| IA remota y local | `lib/data/ai_client.dart`, `lib/data/ai_model_catalog.dart`, `lib/data/local_model_runtime.dart`, `lib/data/local_model_preflight.dart`, `packages/llama_cpp_dart/pubspec.yaml`, `docs/LOCAL-AI.md` | La IA remota se apoya en HTTP/Dart; probar TLS, streaming y reanudación. `llama_cpp_dart` declara plugin FFI iOS/Darwin y el runtime usa FFI; es indicio de soporte declarado, no prueba de compilación/compatibilidad ABI, consumo de memoria, rendimiento, carga GGUF ni licencias de modelos. Preflight de memoria usa canal Android, así que necesita equivalente iOS o fallback seguro. |

### Comprobaciones realizadas y límites

- `xcodebuild -version` → error: Xcode no está seleccionado/instalado como developer directory; el activo es `/Library/Developer/CommandLineTools`.
- `xcodebuild -list -project ios/Runner.xcodeproj` no llegó a ejecutarse porque la comprobación anterior terminó con error.
- `flutter` no se encontró en `PATH`. Este estado describe esta sesión/entorno, no necesariamente otras máquinas de desarrollo.
- No se ejecutó build, test, simulador, instalación, OAuth ni distribución. No se inspeccionaron ni se requieren valores secretos para este plan.

## 2. Preparación y comandos (T049)

### Requisitos de equipo y proyecto

1. Mac compatible con la versión de Xcode que soporte la versión de Flutter y los SDK mínimos acordados; instalar Xcode completo, abrirlo una vez y aceptar licencia/componentes. Instalar Flutter compatible con `pubspec.yaml` (`flutter >=3.44.0`, Dart `>=3.10.0`) y CocoaPods conforme a la guía de Flutter/plugin lock efectivo.
2. Confirmar versiones y capacidad antes de tocar configuración:

```sh
xcode-select -p
xcodebuild -version
flutter --version
flutter doctor -v
flutter devices
```

3. En una rama de trabajo, instalar dependencias y regenerar integración iOS:

```sh
flutter pub get
cd ios
pod install
cd ..
open ios/Runner.xcworkspace
```

Usar el workspace, no abrir solamente el `.xcodeproj`, cuando CocoaPods haya generado `Pods`. No versionar archivos generados o secretos de CocoaPods sin revisar las convenciones del proyecto.

### Firma, simulador y compilación

- En Xcode, seleccionar target `Runner`, equipo de desarrollo y bundle ID final (ahora `com.gymia.app`). Habilitar firma automática solo para el equipo autorizado; confirmar perfiles/certificados y capacidades de notificaciones necesarias. Evitar guardar claves privadas o perfiles de distribución en el repositorio.
- Ejecutar en simulador y compilar sin firma para aislar problemas de código; simulador no valida OAuth de proveedor, notificaciones reales, rendimiento de IA ni permisos físicos:

```sh
flutter devices
flutter run -d <ID_SIMULADOR>
flutter build ios --simulator
```

- Revisar destinos/esquema y hacer build Xcode si es necesario:

```sh
xcodebuild -list -workspace ios/Runner.xcworkspace
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -destination 'platform=iOS Simulator,name=<SIMULADOR>,OS=<VERSION>' build
```

- Compilar para un dispositivo físico requiere firma y perfil:

```sh
flutter build ios --release
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner \
  -destination 'generic/platform=iOS' -configuration Release archive \
  -archivePath build/ios/Runner.xcarchive
```

El `archive` es solo compilación; aún se debe validar el archivo, exportar con opciones de distribución apropiadas y subirlo conscientemente a App Store Connect. Ninguno de estos comandos se ha ejecutado en este trabajo.

### Matriz de adaptación y prueba por flujo

| Flujo / dependencia | Adaptación pendiente | Prueba en simulador | Prueba requerida en iPhone |
|---|---|---|---|
| Base local (`sqflite`, secure storage, paths) | Confirmar inicialización, ubicación privada, migraciones y errores; asegurar datos aislados por perfil y no exponerlos en logs/backup inesperado. | Crear datos sintéticos, cerrar/reabrir app, migrar base y exportar/importar archivo de prueba. | Repetir tras reinstalación/actualización y bloqueo/desbloqueo; verificar persistencia y que credenciales/tokens no aparecen en archivos exportados. |
| Archivos, imágenes y compartir (`file_picker`, `image_picker`, `share_plus`) | Sustituir picker nativo Android de hojas por document picker de iOS y revisar URL/security-scoped resources; utilizar APIs de plugin en iOS. Mantener acciones Android ocultas donde no existan. | Seleccionar archivo sintético desde Files, cancelar, elegir foto y compartir exportación. | Importar CSV/XLSX sintéticos desde Files/iCloud local, probar archivos grandes, selección/cancelación, foto, compartir y reapertura desde Files. |
| OAuth Google y Sheets | Integrar OAuth iOS de Google con bundle ID, client ID iOS, redirect scheme asociado y consentimiento/scopes mínimos; trasladar llamadas Sheets a API HTTPS/Dart o plugin con soporte comprobado. Manejar revoke, expiración y cancelación. | Solo comprobar UI/configuración no productiva; usar mocks para flujos sin cuenta real. | Con cuenta de prueba autorizada: consentimiento, listar/leer, escritura de prueba reversible, revocar/reconectar, cancelar y errores de red. No usar datos personales ni hojas reales en QA. |
| OAuth ChatGPT | Añadir callback iOS seguro, asociar URL scheme/universal link, restaurar app y conservar validaciones PKCE/state; mover “abrir navegador” a API nativa iOS/Flutter soportada. | Mock de callback válido, inválido, cancelado y state incorrecto. | Proveedor real con cuenta de prueba autorizada; ciclo abrir app externa/volver, completar/cancelar, reanudar tras background, refresh/revoke y errores. No registrar tokens ni URLs con códigos. |
| Recordatorios y avisos | Implementar backend iOS `UNUserNotificationCenter`, categorías/acciones equivalentes y scheduling limitado por iOS. Solicitar autorización contextual; considerar que iOS decide presentación/entrega y no garantiza alarmas exactas ni tareas en segundo plano. | Permitir/denegar y comprobar programación, cancelación, cambio de zona/hora y acciones mientras app está activa. | Probar permiso inicial/denegado, banners/sonido según ajustes, acción desde notificación con app terminada/background, reprogramación, reinicio y Focus; registrar límites observados por versión iOS. |
| IA remota | Confirmar transporte HTTPS, streaming/cancelación y tratamiento de errores; no cambiar automáticamente proveedor/modelo. | Mock local de respuesta, corte de red, timeout y stream cancelado. | Probar endpoint de staging y credencial de QA aprobada, sin datos reales; validar consumo, TLS, background/foreground y no persistir secretos en logs. |
| IA local (GGUF/llama.cpp) | Verificar FFI iOS, arquitecturas/slices, deployment target, enlace y carga. Proporcionar métrica de memoria equivalente sin canal Android y rechazar modelos que excedan capacidad disponible. Revisar licencias y origen de modelos antes de distribuirlos. | Importar pequeño modelo sintético/permitido, generar corto, cancelar, liberar y comprobar respuesta ante archivo inválido; el simulador no sustituye rendimiento físico. | Probar en el iPhone mínimo y uno representativo con modelo autorizado: importación local, carga, generación, cancelación, memoria térmica, cierre/reapertura y errores por falta de memoria. Sin modelo personal. |
| Voz, cámara y galería | Mantener los textos de `Info.plist` y revisar permisos/privacidad solicitados por uso real; documentar fallback de escritura manual. | Probar prompts permitidos y denegados y fallback sin hardware de audio/cámara del simulador. | Dictado, interrupciones, rechazo de permiso, cámara/galería, orientación y volver desde Ajustes. |

## 3. Criterios de aceptación (T050)

La versión iOS solo podrá declararse funcional cuando exista evidencia fechada y repetible para todos estos puntos:

1. `flutter pub get`, resolución de Pods, análisis y compilación Release en Xcode compatible terminan correctamente; archivo firmado para un destino iOS acordado y sin errores de runtime relevantes al inicio.
2. Recorridos principales funcionan en dispositivo: crear/editar datos sintéticos, persistencia después de reiniciar, exportar/importar backup sintético, restaurar navegación/estado y manejo claro de errores.
3. Cada canal Dart usado está implementado en iOS o desactivado con explicación y fallback probado. Ninguna acción esencial muestra éxito ficticio ante `MissingPluginException`.
4. Google OAuth/Sheets y OAuth ChatGPT se marcan por separado: OAuth real de cada proveedor completado en un iPhone con cliente/redirect correctos, y cancelación, revocación y errores probados. Mocks no cuentan como OAuth real.
5. Permisos de voz, cámara, fotos y notificaciones tienen descripciones, solicitud contextual, denegación y fallback probados. Acciones/entrega de avisos comprobadas en dispositivo dentro de las garantías reales de iOS.
6. IA remota pasa respuesta, streaming/cancelación y errores con endpoint/credencial QA; IA local se marca funcional únicamente después de carga y generación física con modelos permitidos, revisión de arquitectura, memoria y licencia.
7. No se registran tokens, credenciales, datos personales ni contenidos sensibles; la evidencia usa perfiles, entrenamiento, hojas, archivos y mensajes sintéticos. La prueba de integración Google real se identifica como tal y se ejecuta únicamente con cuenta de QA autorizada.
8. Guardar versión de Xcode/Flutter/iOS, dispositivo, commit, comandos, resultados y defectos abiertos. Un build exitoso por sí solo no satisface aceptación funcional.

### Regresión mínima antes de candidato

- Arranque limpio, actualización desde versión previa, migración SQLite, persistencia entre reinicios y separación de perfiles.
- Crear/editar actividad y progreso, completar/restablecer tramo, editar observaciones, chat/memoria, archivos adjuntos e historial/archivado.
- Exportación/importación sintética CSV/XLSX/backup con cancelación, archivo inválido, tamaño grande, espacio insuficiente y recuperación sin pérdida silenciosa.
- Ajustes de proveedor IA, token/clave inválidos, red desconectada, timeout, stream cancelado, y modelo local no compatible/falta de memoria.
- OAuth de cada proveedor: inicio, cancelación, callback inválido, revocación, reconexión y regreso desde navegador externo.
- Permisos permitidos/denegados/revocados de notificaciones, micrófono, voz, cámara y fotos; apertura de cada acción de notificación desde app cerrada.
- VoiceOver/tamaño de texto, modo claro/oscuro, orientación soportada, teclado, safe areas, background/foreground y al menos el iPhone mínimo acordado.
- Sanidad de privacidad: revisar logs, archivo exportado, almacenamiento local y tráfico de QA para confirmar que no contienen secretos/datos reales.

## 4. Firma y opciones de distribución

| Canal | Requisitos prácticos | Uso previsto y verificación |
|---|---|---|
| Ejecución en simulador | Xcode y runtimes de simulador. No requiere publicación; algunas capacidades/servicios reales no están disponibles. | Desarrollo UI y automatización. No certifica cámara física, push/alertas reales, OAuth externo ni rendimiento IA. |
| Instalación de desarrollo en dispositivo | Mac/Xcode, Apple ID/equipo de desarrollo, dispositivo registrado cuando corresponda y firma de desarrollo. Capacidades/perfiles para el bundle ID y entitlements usados. | Smoke test interno; documentar equipo, dispositivo y perfil. No compartir certificados privados. |
| TestFlight | Membresía vigente del Apple Developer Program (cuenta del titular/organización), App Store Connect con rol habilitado, bundle ID, certificado/perfil o firma automática, archivo firmado y metadatos/export compliance requeridos. | Recomendado para beta interna/externa controlada: subir build, completar procesamiento y revisión beta cuando aplique, invitar testers autorizados y conservar feedback. No instalar ni publicar automáticamente. |
| App Store | Apple Developer Program, titular legal y fiscal cuando aplique, acceso App Store Connect, registro/metadata de app, privacidad, clasificación, screenshots y build firmado; pasar revisión de Apple y configurar disponibilidad/precio conscientemente. | Distribución pública una vez aprobadas privacidad, políticas, propiedad/licencias de modelos y servicios externos. Requiere decisión expresa de negocio y revisión final antes de enviar/publicar. |

La pertenencia a un Apple Developer Team, su titularidad, roles y disponibilidad de certificados **no se han comprobado**. No incluir identificadores de equipo, certificados, contraseñas ni datos de cuenta en este documento. La firma puede requerir capacidad de cuenta de pago para TestFlight/App Store; confirmar condiciones vigentes directamente en el portal de Apple antes de planificar fechas/costes.

## 5. Decisiones pendientes y límite de alcance

- Decidir si iOS debe cubrir todas las capacidades Android o lanzar una primera versión con Sheets, avisos y/o IA local deshabilitados. El código actual no ofrece equivalencia demostrada.
- Acordar mínimo de iOS/dispositivos y recursos del modelo local; target actual 12.0 no demuestra compatibilidad con dependencias actuales.
- Elegir la arquitectura de OAuth Google y de ChatGPT para iOS, redirect/callback, clientes OAuth registrados y pruebas con cuentas de QA. No copiar configuración Android como si fuera válida para iOS.
- Elegir implementación de notificaciones y nivel de puntualidad/acciones prometidas, dentro de límites de iOS.
- Decidir canal de distribución: instalación interna, TestFlight o App Store, y confirmar cuenta/equipo Apple y responsables de firma. **Decisión pendiente; este plan no autoriza publicar ni subir builds.**
- Determinar política de backup para datos de entrenamiento y credenciales, tratamiento de datos de IA, disclosure de privacidad y licencias de modelos antes de distribución.

Hasta que se completen pruebas en iPhone y las decisiones anteriores, iOS debe considerarse **preparación/plataforma parcialmente presente, funcionamiento no verificado**. No hay afirmación de que la app compile o sea publicable.

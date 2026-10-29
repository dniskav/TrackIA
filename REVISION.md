# Revisión de código · TrackIA (2026-10-29)

Revisión hecha leyendo el código (sin ejecutar `flutter analyze` ni tests: el entorno
de la revisión no tenía Flutter). Estado: `pubspec.yaml` 0.3.31+34, rama `main`,
2 commits, 36 archivos modificados sin commitear (+2241 / −611), sin remoto git configurado
(el README apunta a github.com/dniskav/gymia).

Primer paso sugerido: `flutter analyze && flutter test` para tener una línea base,
y hacer commit de lo pendiente antes de tocar nada.

## Lo que está bien (no tocar sin motivo)
- Login ChatGPT (`lib/data/chatgpt_auth.dart`): PKCE, state, nonce, validación del JWT,
  callback solo en loopback. `MainActivity.kt` limita las URLs del navegador a una lista blanca.
- Secretos: claves y tokens en `flutter_secure_storage`; `.jks` y `android/key.properties`
  ignorados y ausentes del historial git. El release falla si falta la firma.
- SQLite (`lib/data/trackia_migrations.dart`, `sqlite_*_repository.dart`): migraciones solo
  aditivas con backup previo, transacciones, `foreign_keys = ON`, sin SQL interpolado con datos del usuario.
- Alarmas de descanso (`RestNotifications.kt`): respetan `canScheduleExactAlarms()` con fallback.
- 40 tests unitarios + 16 de integración, ninguno con `skip`.
- Los `TextEditingController` revisados se liberan correctamente (ej. `routines.dart`).

## Hallazgos, por prioridad

### 1. Trabajo sin commitear y sin remoto
36 archivos modificados solo existen en disco. Hacer commit y configurar un remoto.

### 2. Chats y adjuntos en `flutter_secure_storage`
`lib/data/chat_archive_store.dart` (y `companion_store.dart`) guardan el chat activo y cada
archivo, con imágenes/PDF en base64 y tope de 20 MB por documento, en secure storage.
En Android es un archivo de preferencias cifrado que se lee y reescribe entero: riesgo de
lentitud, memoria y fallos con chats largos. Propuesta: dejar en secure storage solo
claves/tokens y mover chats y adjuntos a SQLite o a archivos, con migración de lo existente
(claves `gymia.ai.chat.v1*` y `gymia.ai.archive.v1.*`). Cubrir con tests (`chat_archive_store_test.dart`,
`chat_archiving_test.dart`, `profile_isolation_test.dart`).

### 3. Nombres mezclados GymIA / TrackIA
UI, README y logo son TrackIA, pero el paquete es `com.gymia.app`, `pubspec.yaml` se llama `gymia`
con descripción «Bitácora de entrenamiento local…», y hay textos de error que dicen GymIA
(p. ej. `ChatGptFailure.message`). Los canales de plataforma también mezclan `com.gymia.app/*`
y `com.trackia/local-model`. Decidir el nombre definitivo ANTES de publicar: cambiar el
`applicationId` después rompe las actualizaciones. Al menos, unificar textos visibles.

### 4. User-Agent con versión fija
`lib/data/ai_client.dart` (~línea 211) y `lib/data/ai_model_catalog.dart` (~línea 53) envían
`GymIA/0.3.14`. Sacar nombre y versión de una sola constante o de `package_info_plus`.

### 5. Errores tragados
70 `catch (_)` en `lib/`. Muchos son legítimos (cerrar sockets), pero revisar los que ocultan
fallos reales. En `ChatGptAuth.connect` cualquier excepción se convierte en
`ChatGptFailure('connection')`, que no tiene mensaje propio y cae al genérico; añadir
registro con `debugPrint` y/o un mensaje específico.

### 6. Archivos muy grandes
`lib/ui/assistant_chat.dart` (2554 líneas), `lib/ui/app.dart` (1457),
`lib/data/sqlite_workout_repository.dart` (1038), `lib/ui/activity_focus.dart` (959).
Dividir poco a poco en widgets y servicios, siempre con los tests en verde entre pasos.

### 7. Release sin minificar
`android/app/build.gradle.kts` no activa R8 ni `shrinkResources` (APK ~47–65 MB).
Probar con cuidado por el código nativo y `llama_cpp_dart`.

## Limpieza de disco
La carpeta pesa más de 30 GB: `.tools` 23 GB, `.dart_tool` 5.6 GB, `releases` 1.9 GB
(~60 APK), `build` 1.5 GB. Todo está ignorado por git; borrar APK antiguos de `releases/`
y `flutter clean` cuando convenga.

## Orden de trabajo propuesto
1. `flutter analyze` + `flutter test` (línea base) y commit de lo pendiente.
2. Mover chats/adjuntos fuera de secure storage (hallazgo 2).
3. Decidir nombre definitivo del paquete (3).
4. Unificar User-Agent/versión y mejorar manejo de errores (4, 5).
5. Dividir archivos grandes (6) y probar minificación (7).

## Estado de los hallazgos (actualizado 2026-10-29)

Las casillas se marcan al completar el trabajo; la evidencia está en `specs/004-trackia-experience/tasks.md`.

- [x] Línea base: `flutter analyze` (11 avisos `info`) y `flutter test` (207 pruebas) medidos y commit de lo pendiente (`docs/0.3.32-LINEA-BASE.md`).
- [ ] 1. Configurar un remoto git (los commits siguen solo en local).
- [ ] 2. Chats y adjuntos fuera de `flutter_secure_storage` (SDD 004, tareas T079–T084; la migración v6 ya crea las tablas).
- [ ] 3. Nombres GymIA/TrackIA: textos visibles en T093; `applicationId`, paquete y claves se conservan a propósito.
- [ ] 4. User-Agent con versión fija (T092).
- [ ] 5. Errores tragados (T094–T095).
- [ ] 6. Archivos muy grandes (T096–T097); `contextForAi` ya salió de `assistant_chat.dart` (T006).
- [ ] 7. Release sin minificar (T098–T099).
- [x] Batería: temporizadores del panel y del descanso solo corren con cuenta atrás y la app visible; sondeo de 60 s pausado en segundo plano (commit `0256b22`). Falta medir en un móvil.

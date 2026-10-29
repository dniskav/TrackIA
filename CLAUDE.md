# TrackIA (carpeta gymIAapp)

App Flutter (Android; iOS preparado) para registrar actividades con un asistente de IA.
El nombre visible es TrackIA; el paquete y muchos identificadores internos siguen siendo
`gymia` / `com.gymia.app`. Versión actual en `pubspec.yaml`.

## Antes de dar algo por terminado
- Ejecutar `flutter analyze` y `flutter test`. Los tests de `integration_test/` necesitan emulador o dispositivo.
- Las herramientas locales (Flutter, SDK de Android, JDK) están en `.tools/`.

## Reglas
- No tocar ni mostrar `.signing/`, `android/key.properties` ni claves; no mover secretos a git.
- Claves y tokens van en `flutter_secure_storage`. No poner datos grandes ahí (chats, adjuntos).
- Las migraciones de SQLite deben ser aditivas y conservar IDs; hacer backup antes de migrar.
- No cambiar `applicationId` sin consultarlo.
- Textos de la app en español.

## Contexto
- Revisión de código pendiente de aplicar: ver `REVISION.md` (hallazgos y orden de trabajo).
- Especificaciones en `specs/` y notas por versión en `docs/`.

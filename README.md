# GymIA · Sprint 1

Bitácora de entrenamiento offline, construida con Flutter para compartir interfaz,
reglas y persistencia entre Android e iOS. Esta entrega distribuye Android.

## Funciones
- Iniciar una sesión con nombre y fecha (máximo una activa).
- Añadir ejercicios personalizados.
- Registrar peso en kg y repeticiones; editar o eliminar series.
- Aceptar coma o punto decimal y 0 kg para ejercicios sin carga externa.
- Guardar cada operación confirmada en SQLite y recuperar la sesión al volver.
- Finalizar y consultar sesiones en el historial.
- Descartar una sesión con confirmación.

Cada serie se guarda al pulsar **Guardar**. Los campos aún sin confirmar no son
registros. Las sesiones finalizadas son de consulta en esta primera versión.
No requiere cuenta ni conexión. La APK release no solicita permiso de Internet.

## Instalar
La APK de esta entrega se encuentra en `releases/gymia-0.1.0.apk` una vez compilada.
Compatible con Android 6.0 (API 23) o posterior.

1. Copiar la APK al teléfono (por USB, Drive u otro medio elegido).
2. Abrirla y permitir la instalación desde esa aplicación si Android lo solicita.
3. Instalar y abrir **GymIA**.

Para actualizar, instalar la siguiente APK encima, sin desinstalar. Hay que mantener
el paquete `com.gymia.app` y la misma clave de firma.
**En este sprint no hay copia externa:** desinstalar, borrar almacenamiento o perder
el móvil implica perder sus registros. Exportación/restauración está prevista en E3.

## Desarrollo
Base comprobada: Flutter 3.29.3 / Dart 3.7.2, JDK 17, SDK Android 35, Gradle 8.9.
Las dependencias quedan fijadas mediante `pubspec.lock`.

```sh
flutter pub get
flutter analyze
flutter test
flutter test integration_test/workout_flow_test.dart -d <id-del-emulador>
flutter run
```

En este Mac hay herramientas locales bajo `.tools/` (ignoradas por Git).
`scripts/flutter-local.sh` configura las rutas necesarias sin depender del Java
incompatible que incluye la instalación antigua de Android Studio.

```sh
./scripts/flutter-local.sh analyze
./scripts/flutter-local.sh test
./scripts/flutter-local.sh build apk --release
```

### Firma de Android
Se ha generado una clave personal para mantener actualizaciones instalables.
Se conserva en `.signing/gymia-personal.jks`; `android/key.properties`
contiene su configuración. Ambos son privados, están ignorados y deben conservarse
en una copia segura al trasladar o limpiar el entorno. No regenerarlos para actualizar.

En otro entorno configurar `android/key.properties` con:

```properties
storeFile=/ruta/absoluta/a/la/clave.jks
storePassword=TU_PASSWORD
keyAlias=gymia
keyPassword=TU_PASSWORD
```

Una compilación release sin esta configuración falla expresamente. No se sustituye
la clave personal por la clave de depuración. Las pruebas de integración usan una
base separada `gymia-integration.sqlite`.

## Estructura
- `lib/domain`: modelos, validación y contrato de repositorio; sin Flutter/plugins.
- `lib/data`: SQLite, transacciones, claves foráneas y esquema versionado.
- `lib/application`: controlador de estado y manejo de operaciones/errores.
- `lib/ui`: pantallas y formularios compartidos Android/iOS.
- `android`, `ios`: configuración propia de cada plataforma.
- `test`: validación, persistencia real en SQLite y formulario.
- `integration_test`: recorrido de usuario sobre SQLite del dispositivo.

## iPhone
El proyecto iOS está preparado y usa el mismo código Dart y el plugin SQLite para
Apple. **No está compilado ni validado para iOS en esta entrega.** Este Mac solo
dispone de Command Line Tools; faltan Xcode completo, configuración de firma y
pruebas en simulador/iPhone. La futura transferencia del histórico entre teléfonos
se resolverá con exportación/restauración o sincronización, no cambiando la interfaz.

## Entorno local
Se ha instalado Rosetta 2 para ejecutar las herramientas de compilación de Flutter
que usan binarios Intel en este Mac Apple Silicon. La app Android y su código
compartido no dependen de Rosetta. El script local utiliza un JDK 17 separado.

Backlog y criterios: [docs/SPRINT-1.md](docs/SPRINT-1.md).
Prueba de aceptación: [docs/ACEPTACION-SPRINT-1.md](docs/ACEPTACION-SPRINT-1.md).

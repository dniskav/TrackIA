# Quickstart: validar TrackIA 004

Estado: guía de validación. Las casillas se marcan en `tasks.md`, no aquí.

## Entorno

```sh
./scripts/flutter-local.sh --version        # debe decir Flutter 3.47 (tras T001)
./scripts/flutter-local.sh analyze          # línea base: 11 avisos info, ningún error
./scripts/flutter-local.sh test             # línea base: 207 pruebas en verde
python3 scripts/validate-sdd-004.py         # formato y trazabilidad del SDD
```

Herramientas locales en `.tools/` (Flutter 3.47, SDK de Android, JDK 17). `scripts/flutter-local.sh`
fija `JAVA_HOME` y `ANDROID_HOME`. No usar `.tools/flutter` directamente (Dart 3.7.2, no compila).

## Emulador y pruebas de integración

```sh
ADB=.tools/android-sdk/platform-tools/adb
.tools/android-sdk/emulator/emulator -list-avds          # trackia_qa, gymia_sprint1, trackia_wear_qa
.tools/android-sdk/emulator/emulator -avd trackia_qa &   # o usar uno ya encendido
$ADB wait-for-device && $ADB shell getprop sys.boot_completed   # debe imprimir 1
./scripts/flutter-local.sh test integration_test/<archivo>.dart -d emulator-5554
```

La compilación debug instala `com.gymia.app.dev`. La compilación release necesita la firma del
propietario y no la ejecuta el agente.

Pruebas de integración que deben pasar al cerrar (T104): todas las existentes de `integration_test/`
más `manual_activity_android_test.dart`, `reminders_android_test.dart` y `progress_android_test.dart`.

## Recorridos

### R1 · Aviso de descanso con No molestar (US1)

1. `$ADB shell cmd notification set_dnd priority`
2. En la app: Ajustes → Avisos → ver «No molestar está activo»; activar avisos y «Tratar como alarma».
3. Preparar una actividad por tramos con 10 s de descanso, Iniciar, Parar y esperar 10 s.
4. `$ADB shell dumpsys notification --noredact | grep -B2 -A8 "trackia_timer_alarm_v1"` → hay una
   notificación reciente del paquete `com.gymia.app.dev` en ese canal.
5. Desactivar «Tratar como alarma», repetir → el aviso aparece en `gymia_rest`.
6. `$ADB shell cmd notification set_dnd off`

### R2 · Configurar la IA desde el tablero (US2)

1. Perfil sin IA configurada. Abrir la app → tablero con la tarjeta «IA sin conectar».
2. «Conectar» → pantalla de IA → configurar un proveedor de prueba → volver.
3. Sin IA verificada la tarjeta sigue; con IA verificada desaparece. Engranaje → Ajustes con las
   tres secciones. Ningún chat se ha abierto.

### R3 · Actividades a mano sin IA (US3)

1. Sin IA. Abrir un acompañante → barra compacta → «Nueva actividad».
2. «Leer»: Libre; campos Páginas (número, sumar, unidad «páginas») y Libro (texto, contar distintos).
3. Iniciar → contador Páginas hasta 18 → Parar → cerrar la app del todo y abrirla → registro presente.
4. «Beber agua»: Puntual, campo Vasos (número, sumar) → guardar → «Registrar» → 1 → línea
   «Registrado: 1 vaso» en el chat, sin cronómetro.

### R4 · Identidad visual (US4)

Capturas claro y oscuro (`$ADB exec-out screencap -p > archivo.png`) de: tablero, chat sin actividad,
actividad preparada (Iniciar teal), tramo en marcha (Parar carmín y anillo), bienvenida (logo sin
recuadro blanco). Comprobar que la bienvenida no reaparece tras omitirla una vez.

### R5 · Edición manual frente a IA (US5)

Con cliente simulado (pruebas `test/assistant_lock_proposals_test.dart`) o IA real: fijar descanso en
120 s a mano; pedir a la IA «ponme 150 s de descanso» → tarjeta Aplicar/Ignorar, el descanso sigue en
120 s; línea «Cambiaste el descanso a 120 s» en el chat.

### R6 · Recordatorios (US6)

1. Acompañante «Lectura» → «Modo y avisos» → recordatorio hoy, ventana desde dentro de 1 min hasta
   dentro de 10 min, última llamada a +3 min, tono Motivador.
2. Esperar → llega el aviso de inicio en `trackia_reminders_v1`
   (`dumpsys notification --noredact | grep trackia_reminders_v1`).
3. Registrar lectura antes de la última llamada → no llega la última llamada.
4. Reprogramación tras arranque:
   `$ADB shell am broadcast -a android.intent.action.BOOT_COMPLETED -p com.gymia.app.dev`
   y comprobar con `$ADB shell dumpsys alarm | grep com.gymia.app.dev` que hay alarmas.
5. Con `set_dnd priority`, el recordatorio no suena (respeta No molestar).

### R7 · Metas, rachas y logros (US7)

Con `integration_test/progress_android_test.dart` (reloj controlado): «Leer» en modo Juego, meta
20 páginas al día con mínimo 5, un día libre por semana. Día 1: 25 páginas (meta cumplida, logro
«Primera vez», «10 páginas» si existe el umbral). Día 2: 5 páginas (mínimo: racha sí, meta no).
Día 3: nada (día libre, racha no se rompe). Día 4: 100 páginas acumuladas → «100 páginas». Al terminar
cada sesión, pantalla «Sesión terminada» con lo nuevo.

### R8 · Crear acompañante con IA (US8)

Con IA verificada: «Crear acompañante» → «Con ayuda de la IA» → «Quiero leer cada día» → responder
las preguntas → elegir «Metas y rachas» → ficha → «Crear». Comprobar acompañante, plantilla, meta y
recordatorio creados. Sin IA: solo «A mano» disponible.

## Evidencia

Cada recorrido ejecutado deja en la nota `docs/0.3.32-*.md` de su fase: fecha, dispositivo o emulador
(nombre de AVD y versión de Android), comandos, resultado y capturas si aplica.

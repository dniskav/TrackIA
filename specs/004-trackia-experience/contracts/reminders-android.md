# Contrato: avisos y recordatorios en Android

## Canales

| ID | Nombre visible | Importancia | Audio | Uso |
|---|---|---|---|---|
| `gymia_rest` (existente, no cambiar) | Actividad y descanso | HIGH | por defecto | Actividad lista, actividad en curso, fin de descanso/tramo si `alarmStyle = false`, prueba normal |
| `trackia_timer_alarm_v1` (nuevo) | Fin de descanso y tramo | HIGH | `TYPE_ALARM`, `USAGE_ALARM`, `CONTENT_TYPE_SONIFICATION`, vibración | Fin de descanso y fin de tramo si `alarmStyle = true` |
| `trackia_reminders_v1` (nuevo) | Recordatorios | DEFAULT | por defecto | Recordatorios de hábitos (respeta No molestar) |

Notificaciones del canal de alarma: `setCategory(Notification.CATEGORY_ALARM)`, mismas acciones que
hoy (Iniciar/Cerrar o Parar/Cerrar), `setColor(brandTeal)`. Crear los canales nuevos de forma
idempotente al primer uso, como `gymia_rest`.

## MethodChannel `com.gymia.app/rest-notifications` (existente)

Métodos actuales sin cambios: `status`, `enable`, `test`, `exactSettings`, `pendingAction`.

Ampliaciones:

| Método | Argumentos | Resultado |
|---|---|---|
| `status` | — | Añade: `alarmStyle` (bool), `dnd` (bool: filtro ≠ `INTERRUPTION_FILTER_ALL`), `dndFilter` (int), `alarmChannelBlocked` (bool) |
| `setAlarmStyle` | `{enabled: bool}` | `true` |
| `testAlarm` | — | Programa a 5 s un aviso de fin de descanso de prueba en el canal que corresponda a `alarmStyle`; `true` si se programó |
| `openChannelSettings` | `{channel: 'alarm' \| 'reminders' \| 'rest'}` | Abre `Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS`; si falla, `ACTION_APP_NOTIFICATION_SETTINGS` |
| `openDndSettings` | — | Abre `"android.settings.ZEN_MODE_SETTINGS"`; si falla, `Settings.ACTION_SETTINGS` |

`RestNotificationController` (`lib/application/rest_notifications.dart`) expone `alarmStyle`, `dnd` y
los métodos anteriores; `initialize()` ya se llama al reanudar, así que el estado de No molestar se
refresca al volver a la app.

## MethodChannel `com.gymia.app/reminders` (nuevo)

| Método | Argumentos | Resultado |
|---|---|---|
| `sync` | `{snapshot: String}` (JSON de abajo) | Guarda la instantánea en SharedPreferences `trackia_reminders` y reprograma todas las alarmas; `true` |
| `clear` | `{profileId: String}` | Borra la instantánea del perfil y cancela sus alarmas |
| `status` | — | `{permitted: bool, scheduled: int}` |

## Instantánea (JSON, versión 1)

```json
{"version": 1, "profileId": "local", "generatedAt": 1767000000000,
 "reminders": [{
   "id": "uuid", "companionId": "lectura", "companionName": "Lectura",
   "days": 127, "windowStartMin": 1260, "windowEndMin": 1380, "lastCallMin": 1350,
   "tone": "cheer", "paused": false,
   "lastDoneDate": "2026-10-28",
   "lastActivityDate": "2026-10-28",
   "streak": 6, "goalText": "20 páginas", "minimumText": "5 páginas",
   "weekId": "2026-W44", "weekCount": 3, "weekTarget": 5,
   "templates": {"windowStart": ["…"], "lastCall": ["…"], "inactive": ["…"]}
 }]}
```

Flutter la regenera en `ReminderScheduler.sync()` (`lib/application/reminder_scheduler.dart`) al:
abrir la app, guardar un valor, parar un tramo, terminar una actividad, cambiar ajustes de un
acompañante, borrar un acompañante y cambiar de perfil. Solo incluye recordatorios activos.

## Programación y disparo

- Por cada recordatorio no pausado y día marcado: alarma inexacta `setWindow(RTC_WAKEUP, inicio, 10 min)`
  y otra para `lastCallMin` si existe. Solo se programa el próximo disparo de cada tipo; al dispararse,
  se programa el siguiente. `PendingIntent` con `requestCode` estable derivado de `id` y tipo.
- `ReminderReceiver.onReceive`: lee la instantánea; si `paused`, si el día no está marcado o si
  `lastDoneDate == hoy` (fecha local), no publica. Si no, elige plantilla y publica en
  `trackia_reminders_v1`, título = `companionName`, toque → abre la app con extras `profileId` y
  `companionId` (la app abre ese chat). Nunca más de 2 publicaciones por recordatorio y día
  (contador `postedCount:<id>:<fecha>` en SharedPreferences).
- `BootReceiver` (`android:exported="true"`, filtros `BOOT_COMPLETED`, `TIME_SET`,
  `TIMEZONE_CHANGED`; ignora cualquier otra acción): reprograma desde la instantánea.
- Manifest: permiso `RECEIVE_BOOT_COMPLETED`; `ReminderReceiver` con `exported="false"`.
- No usa alarmas exactas ni requiere `SCHEDULE_EXACT_ALARM`.

## Plantillas por defecto (español)

Elección: si `lastActivityDate` es anterior a ayer → plantillas `inactive` en el aviso de inicio;
si no → `windowStart`. En la última llamada → `lastCall`. Se usa la primera plantilla de la lista
cuyos marcadores tengan valor; si ninguna, la última de la lista (que no lleva marcadores).

| Clave | Neutro | Motivador |
|---|---|---|
| `windowStart` | «Es buen momento para tu actividad. Meta de hoy: {meta}.» · «Es buen momento para tu actividad.» | «{nombre} te espera: hoy toca {meta}.» · «{nombre} te espera hoy.» |
| `lastCall` | «Aún estás a tiempo hoy. Con {minimo} basta.» · «Te faltan {faltan} esta semana.» · «Aún estás a tiempo hoy.» | «Última llamada: con {minimo} mantienes tu racha de {racha} días.» · «No pierdas la racha: te faltan {faltan} esta semana.» · «Última llamada para hoy.» |
| `inactive` | «Llevas {dias} días sin registrar.» · «Hace unos días que no registras.» | «Llevamos {dias} días sin vernos. ¿Algo corto hoy?» · «¿Algo corto hoy?» |

Plantilla específica de GymBro (`companionId == 'gymbro'`, tono motivador, `inactive`):
«Amigo, llevamos {dias} días sin entrenar. Vamos a movernos un poco.»

Marcadores: `{dias}` = días desde `lastActivityDate` (≥ 2); `{faltan}` = `weekTarget − weekCount`
si `weekId` es la semana actual y es > 0 (si la semana cambió, `weekTarget`); `{racha}` = `streak` si
> 0; `{minimo}` = `minimumText`; `{meta}` = `goalText`; `{nombre}` = `companionName`. Las plantillas de
`trackia-reminder-copy` sustituyen a las por defecto del acompañante.

## Pruebas

- Unitarias (Dart): construcción de la instantánea y selección de plantillas replicada en Dart
  (`lib/domain/reminder.dart`, función `renderReminder`) con los mismos casos que Kotlin.
- Kotlin: la lógica de selección y relleno vive en una función pura `ReminderText.render(…)`; se
  prueba con un test JVM local si el módulo ya admite `testImplementation` (comprobar
  `android/app/build.gradle.kts`); si no, se cubre con la prueba de integración.
- Integración (`integration_test/reminders_android_test.dart`): instantánea con ventana a +1 min,
  esperar el aviso; repetir con `lastDoneDate = hoy` y comprobar que no llega.

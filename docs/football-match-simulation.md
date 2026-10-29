# Simulación: partido de fútbol 7 con TrackIA

Acompañante personalizado: **Cancha**. Su personalidad registra partidos, minutos y jugadas confirmadas, conserva observaciones físicas y no inventa estadísticas. El caso usa un partido de dos tiempos de 25 minutos, con 5 minutos de descanso.

| Momento | Acción del usuario | Estado comprobado |
| --- | --- | --- |
| Preparación | «Quiero registrar un partido de fútbol 7: dos tiempos de 25 minutos y 5 de descanso. Juego de delantero.» | Actividad asociada a Cancha, duración por tramo de 1500 s, descanso de 300 s y objetivo de dos tramos. |
| Primer tiempo | Iniciar; «Marqué 1 gol y di 1 asistencia.» | Tramo 1 en marcha; mensaje vinculado al tramo con `goals=1` y `assists=1`. |
| Descanso | Parar al minuto 25 | Primer tramo de 25 minutos; descanso previsto de 5 minutos. |
| Segundo tiempo | Iniciar; «Hice 2 tiros a puerta y acabé cansado.» | Segundo tramo en marcha; `shots_on_target=2` y observación original conservada. |
| Cierre | Parar al minuto 25 y Terminar | Dos tramos de 25 minutos persistidos y actividad cerrada. |

La prueba automatizada `integration_test/football_match_simulation_test.dart` recorrió la interfaz y SQLite en un emulador Android. Usó respuestas controladas del proveedor de IA y adelantó el reloj de prueba para simular los 55 minutos; no esperó el tiempo real ni consultó un modelo externo o Google Sheets. Los avisos Android de fin de tramo y descanso se verificaron por separado en `integration_test/pomodoro_notifications_test.dart` con intervalos cortos.

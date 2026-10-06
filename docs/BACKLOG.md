# Backlog de producto

Orden inicial; se revisará después de probar cada APK.

| Entrega | Resultado usable | Estado |
| --- | --- | --- |
| Sprint 1 · Registro | Sesión manual, series, correcciones, persistencia e historial | Aceptado por el usuario en su teléfono |
| Sprint 2 · Rutinas | Iniciar desde rutina, consultar valores anteriores y descansos | Pendiente |
| Sprint 3 · Histórico | Importar Sheets con vista previa/deduplicación y exportar/restaurar | Pendiente |
| Sprint 4 · Progreso | Gráficas y sugerencias calculadas con reglas explicables | Pendiente |
| Sprint 5 · IA | Proveedor configurable, análisis contextual y cambios revisables | Pendiente |
| Sprint 6 · Uso diario | Mejoras según entrenamientos reales y versión estable | Pendiente |

## Decisiones pendientes (no bloquean Sprint 1)
- Estructura real de Google Sheets y bitácora.
- Mantener Sheets actualizado o usarlo solo como fuente histórica.
- Proveedor/API de IA concreto: OpenCode Zen, Go u otro.
- Activación de iOS: Xcode, firma y dispositivo para validación.

## Cambio de arquitectura aceptado durante Sprint 1
El usuario pide facilitar una futura versión iPhone. Se sustituye la propuesta
Android nativa inicial por Flutter compartido. Android sigue siendo la primera
plataforma entregada; no se añade iOS al criterio de aceptación de este sprint.

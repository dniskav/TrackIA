# Plan: conversación fiable y acompañamiento adaptable

**Fecha**: 2026-11-05 · **Especificación**: [spec.md](spec.md) · **Rama real**: `feat/004-trackia-experience` (el nombre que devuelve setup-plan deriva del directorio; no se creó ni cambió rama).

## Resumen

Implementar incrementos Android utilizables en orden de riesgo: recuperación/corrección, edición de actividad, Sheets, memoria y copia, personalidad y acuerdos generales, idiomas y acabado. Entregar un plan iOS, no una promesa de compilación. La especificación 003 conserva su alcance no implementado; reutilizar el motor existente sin afirmar que 003 está completo. El propietario autorizó leer el tramo visible del chat para diagnosticar; no guardar datos reales en tests ni documentos.

## Contexto técnico y evidencias

Flutter/Dart, SQLite v6 en `lib/data/sqlite_workout_repository.dart`, `trackia_migrations.dart`, chat `lib/ui/chat/chat_send.dart`, `assistant_chat.dart`, contexto `lib/application/assistant_context.dart`; flujo Sheets `lib/ui/google_sheets_import.dart` y `lib/ui/chat/chat_sheet.dart`; ajustes `lib/ui/companion_settings.dart`; `flutter_localizations` e `intl` ya figuran en `pubspec.yaml`. `send()` guarda antes de enviar, conserva `pending` y tiene `retry` interno, pero limita historial y no demuestra recuperación durable completa ni idempotencia. No extrapolar desde una lectura parcial del teléfono. Verificar nombres de símbolos antes de cada cambio.

## Constitución

Sin excepciones: acciones deterministas, perfil y acompañante aislados, originales/revisiones, copia previa y restauración de migraciones, consentimiento para efectos remotos, estado incierto explícito, accesibilidad y evidencia separada real/simulada. Al final de cada fase ejecutar pruebas afectadas; al cierre analyze y suite. No tocar firma, datos personales ni eliminaciones preexistentes del árbol. Las tareas de este SDD son implementación futura, no autorización para publicar o modificar el móvil personal.

## Diseño y orden

1. Contratos y pruebas sintéticas de migración/alcance; preservar los formatos de chat y adjuntos actuales.
2. Entrega P1: IDs persistentes, versiones, cola y acciones vinculadas; las respuestas tardías deben quedar en su chat de origen. Una operación externa incierta se reconcilia, no se repite a ciegas. Los cambios de actividad pasan por validación de la app.
3. Flujo Sheets: reutilizar el selector y autorizaciones existentes; no guardar destino a medias.
4. Memoria: repositorio local y recuperación acotada por ámbito; la selección por IA produce propuestas estructuradas validadas, con tres decisiones explícitas: guardar, preguntar, ignorar. Proteger el prompt de instrucciones contenidas en recuerdos. Copia Google optativa según contrato, sin prometer viabilidad antes de probar permisos; el bloqueo externo se registra y no se marca completa.
5. Personalidad y acuerdos: preferencias libres y controles deterministas, sin hardcodear hábitos. Integrar avisos existentes. No implementar vigilancia ni bloqueo de otras apps.
6. Localización: ARB, generador Flutter, traducción completa y RTL, incluidos textos de error y nativos; preservar texto original de datos. Logo desde asset existente.
7. Plan iOS basado en inventario real, con comandos y puertas. No publicar ni instalar en el teléfono del usuario sin instrucciones posteriores.

## Guía de ejecución para modelos pequeños

Leer `spec.md`, este plan, `data-model.md`, `contracts/contratos.md`, `quickstart.md` y solo la fase actual de `tasks.md`. Ejecutar tareas secuencialmente; abrir los archivos citados y seguir patrones reales, sin asumir firmas. Cada tarea especifica resultado y prueba. Marcar `[x]` solo tras evidencia bajo la tarea; si algo falla, registrar comando, resultado y bloqueo, continuar con tareas independientes y no simular éxito. No eliminar ni sobrescribir cambios previos. Mantener cada paso compilable; conservar las pruebas existentes. Ante decisiones externas no resueltas documentar límites y pedir al usuario solo si impiden trabajo posterior. `tasks.md` y contratos prevalecen sobre ejemplos de producto, nunca sobre la constitución o instrucciones del usuario.

## Verificación de diseño

La copia usa autorización explícita y conflictos visibles; edición conserva originales; el modelo no ejecuta acciones directamente; personalidad no modifica permisos; acuerdos no requieren red. iOS queda planificado, no declarado funcional. Riesgos principales: impacto de cambiar formatos persistidos, efectos inciertos, permisos Google y cobertura de traducción; cada uno tiene puerta específica en tareas y quickstart.

# Especificaciones del producto

Base entregada: **GymIA 0.3.22+25**. Objetivo acordado: **TrackIA**, un asistente para
actividades y registros personales diversos. La bienvenida US9 y la base de
compatibilidad SQLite v5 tienen código y QA local; la APK 0.3.25 se compartió
por Fairdrop y conserva el nombre visible GymIA.

El SDD vigente de la evolución está en [003-trackia-platform/spec.md](003-trackia-platform/spec.md).

La mejora de experiencia acordada el 2026-10-29 (identidad visual, ajustes globales, actividades
abiertas, recordatorios, juego opcional, avisos con No molestar y deuda de `REVISION.md`) está en
[004-trackia-experience/spec.md](004-trackia-experience/spec.md), con [plan](004-trackia-experience/plan.md),
[tareas](004-trackia-experience/tasks.md) y [validación](004-trackia-experience/quickstart.md).
Amplía 003 y absorbe sus tareas T007 y T020. Estado (2026-10-30): fases 0 a 12 implementadas con tests
(665 pruebas de Dart y pruebas de integración en emulador y en un teléfono real); 103 de 107 tareas hechas.
Pendientes: T064 y T065 (reinicio real del móvil), T099 (release firmado con R8) y T107 (aceptación del
propietario), todas `[OWNER]`. El detalle y la
evidencia están en [tasks.md](004-trackia-experience/tasks.md) y en [docs/TRACKIA-QA.md](../docs/TRACKIA-QA.md). Validar con `python3 scripts/validate-sdd-004.py`.

- [Visión actual](00-product/vision.md) y [hoja de ruta](00-product/development-plan.md).
- [Constitución](../.specify/memory/constitution.md).
- [Investigación](003-trackia-platform/research.md), [plan](003-trackia-platform/plan.md)
  y [modelo](003-trackia-platform/data-model.md).
- [Contratos](003-trackia-platform/contracts/assistant-proposals.md),
  [bienvenida](003-trackia-platform/contracts/welcome.md),
  [tareas](003-trackia-platform/tasks.md) y [trazabilidad](003-trackia-platform/traceability.md).
- [Validación y recorridos](003-trackia-platform/quickstart.md).

Los documentos anteriores son antecedentes de sus versiones. Se conservan las visiones
originales en [histórico](00-product/history/vision.md); las notas de entrega de docs/
son evidencia de runtime. Un requisito futuro o una prueba planificada no equivale a
una capacidad entregada. Las integraciones y casos de gimnasio se conservan.

La estructura y las skills oficiales se inicializaron con [Spec Kit 1.2.2](../.specify/UPSTREAM.md).

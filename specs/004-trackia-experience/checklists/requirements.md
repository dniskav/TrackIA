# Specification Quality Checklist: TrackIA — experiencia, actividades abiertas y juego opcional

**Purpose**: validar que la especificación está completa antes de implementar.
**Created**: 2026-10-29
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] CHK001 Las historias describen valor para el usuario y no detalles de implementación.
- [x] CHK002 Cada historia tiene prioridad, prueba independiente y escenarios Given/When/Then.
- [x] CHK003 Los textos visibles propuestos están en español.
- [x] CHK004 Las decisiones técnicas están en `plan.md`, `research.md` y contratos, no en la especificación.

## Requirement Completeness

- [x] CHK005 No quedan marcadores de aclaración pendiente: las tres dudas (relación con 003, formato
  y valor por defecto del juego) se resolvieron con el propietario el 2026-10-29.
- [x] CHK006 Cada requisito funcional es comprobable y tiene al menos una tarea (ver `traceability.md`).
- [x] CHK007 Los criterios de éxito son medibles.
- [x] CHK008 Los casos límite cubren datos heredados, ausente frente a cero, zonas horarias, borrado,
  sin red y bloques inválidos.
- [x] CHK009 Los supuestos y lo que queda fuera (iOS, release firmado, teléfono real) están explícitos.

## Constitution Alignment

- [x] CHK010 La app calcula y desbloquea; la IA solo propone (principio II).
- [x] CHK011 Toda tabla nueva lleva perfil y acompañante; hay pruebas de aislamiento (principio III).
- [x] CHK012 Migración v6 aditiva con respaldo; las definiciones antiguas no se reinterpretan (principio IV).
- [x] CHK013 Los bloques de la IA tienen esquema cerrado y no conceden permisos (principio V).
- [x] CHK014 Las tareas que requieren dispositivo real o firma están marcadas `[OWNER]` (principio VIII).

## Readiness

- [x] CHK015 `plan.md` lista hechos verificados del código con archivo y línea.
- [x] CHK016 `tasks.md` tiene pruebas antes de cada implementación y evidencia obligatoria.
- [x] CHK017 `python3 scripts/validate-sdd-004.py` pasa (ejecutado el 2026-10-29).

# Memoria de acompañante y copia en Google Drive (005)

**Estado general: parcial.** Base de datos, dominio, propuestas y copia en nube simulada están implementados. No hay adaptador real de Google Drive, ni pantalla de memoria, ni validación con cuenta Google. Fecha de revisión: 2026-11-07. Relacionado: `specs/005-conversacion-memoria/tasks.md` (T024–T032) y `specs/005-conversacion-memoria/spec.md` (US4, FR-007 a FR-009).

## 1. Estado por pieza

| Pieza | Estado | Código |
|---|---|---|
| Modelo de recuerdo (revisiones, estados, límites) | Implementado | `lib/domain/companion_memory.dart` |
| Tabla `trackia_companion_memories` (v7, aditiva) | Implementado | `lib/data/trackia_migrations.dart` |
| Repositorio local (crear, leer, listar, revisar, borrado lógico) | Implementado | `lib/data/companion_memory_repository.dart` |
| Propuestas `save`/`ask`/`ignore` y aceptación persistida | Implementado como servicio; **no conectado al chat** | `lib/application/companion_memory_service.dart` |
| Bloque de memoria en el contexto del asistente | Implementado; **ningún flujo de chat lo invoca aún** | `lib/application/assistant_context.dart` |
| Snapshot v1 sin credenciales | Parcial: falta vista previa de importación (T029) | `lib/data/memory_snapshot.dart` |
| Servicio de copia en nube sobre transporte abstracto | Parcial: lógica hecha, solo con transporte simulado | `lib/data/memory_google_drive.dart` |
| Adaptador real de Drive (`appDataFolder`, OAuth, identidad) | **Pendiente** (T030) | no existe |
| Pantalla de memoria (ver, editar, borrar, copia) | **Pendiente** (T027, T031) | `lib/ui/companion_memory.dart` no existe |
| Validación con cuenta Google real | **Pendiente** (sin autorización) | — |

## 2. Permisos adicionales

- Alcance previsto: `drive.appdata` (carpeta oculta de la propia app). Es el alcance mínimo para este fin; no se piden permisos sobre el Drive completo.
- **Pendiente**: no hay código que pida el alcance, ni flujo OAuth, ni comprobación de identidad. `grep` de `appdata` en `lib/` no devuelve nada. El servicio recibe `accountId` como parámetro; de dónde sale ese valor aún no está definido.
- Ninguna credencial entra en el snapshot. Si aparece un token en el JSON importado, el parser lo rechaza (claves desconocidas).
- Cuando exista autenticación, los tokens irán en `flutter_secure_storage` (regla de `CLAUDE.md`), nunca en SQLite ni en el snapshot.

## 3. Qué se guarda

**En local** (`trackia_companion_memories`): `id`, `profile_id`, `companion_id`, `content` (hasta 2000 caracteres), `source` (`explicit|inferred|user_edited`), `source_message_id` (referencia, no el texto del mensaje), `created_at`, `updated_at`, `revision`, `status` (`active|pending_confirmation|deleted`).

**En la nube** (`memory-v1:<clave>`): un sobre JSON con exactamente siete claves: `version` (1), `accountId`, `profileId`, `companionId`, `revision`, `updatedAt` y `snapshot`. El `snapshot` es el JSON del snapshot v1: `version`, `profileId`, `companionId` y la lista `memories` con `id`, `content`, `source`, `sourceMessageId`, `createdAt`, `updatedAt`, `revision` y `status`.

- Solo se suben recuerdos `active`. `save` lanza error si recibe otros, y `load` rechaza un snapshot que los contenga.
- No se incluyen chats, adjuntos, tokens ni claves. El `content` de cada recuerdo sí es dato personal: va en claro (ver §4).

> Diferencia con `data-model.md`: el modelo habla de `formatVersion` y de una revisión a nivel de snapshot. El código usa `version` y guarda la `revision` en el sobre remoto.

## 4. Privacidad

- **No hay cifrado de extremo a extremo.** El contenido se envía en texto JSON al transporte y queda almacenado en el Drive de la cuenta del usuario, con los controles de Google. No se cifra en el cliente y no debe describirse como cifrado de extremo a extremo.
- La copia es voluntaria. El código no tiene ninguna llamada automática a `save`.
- Los tests usan datos sintéticos (`profile-fixture-a`, «Prefiere respuestas breves»). No se usan datos del teléfono ni cuentas reales.

## 5. Límites

| Límite | Valor | Fuente |
|---|---|---|
| Caracteres por recuerdo | 2000 | `CompanionMemory.maxContentLength` |
| Recuerdos en el contexto del asistente | 20 | `maxContextMemories` |
| Caracteres de contexto | 12000 (no se corta un recuerdo a la mitad) | `maxContextCharacters` |
| Tamaño máximo del sobre remoto | no definido en el código | — |
| Cuotas, tamaño y comportamiento de `appDataFolder` (p. ej. al desinstalar) | **no verificado**; comprobar en la documentación oficial de Google antes de la validación real | — |

## 6. Operaciones separadas

| Operación | Método | Qué hace | Estado |
|---|---|---|---|
| Guardar en la nube | `MemoryGoogleDriveService.save(accountId, snapshot, knownRevision)` | Lee la revisión remota; si coincide con `knownRevision` escribe `revision + 1` con escritura condicional. Si no coincide, devuelve conflicto sin escribir. | Implementado (simulado) |
| Cargar de la nube | `MemoryGoogleDriveService.load(accountId, profileId, companionId)` | Devuelve el snapshot validado. **No escribe en la base local.** | Implementado (simulado); aplicar al local, pendiente |
| Borrar en la nube | `MemoryGoogleDriveService.delete(..., knownRevision)` | Comprueba la revisión y elimina el documento remoto. | Implementado (simulado) |
| Borrar en local | `CompanionMemoryRepository.delete(id, companionId, at)` | Marca `status = deleted` con una revisión nueva. **La fila no se elimina físicamente.** | Implementado; sin pantalla |

Son métodos distintos. Borrar en local no toca la nube, y borrar en la nube no toca la base local.

## 7. Casos límite

| Situación | Comportamiento en código | Prueba (`test/memory_cloud_test.dart`) |
|---|---|---|
| Conflicto de revisión | `save` devuelve `conflict` con la copia remota; no sobrescribe | «remote revision mismatch conflicts…» |
| Carrera en escritura condicional | El transporte responde `conflict` y no se declara éxito | «conditional write race and uncertain result…» |
| Resultado incierto | `uncertain` en `save` y `delete`; no hay reintento automático ni reconciliación | misma prueba |
| Copia dañada (JSON roto, versión distinta, claves extra, credencial, recuerdo no activo) | `failed`; el parser es todo o nada, no importa nada parcial | «damaged or credential-bearing snapshot…»; «damaged or cross-account remote payload…» |
| Cancelación | El transporte informa `cancelled` y el servicio lo propaga. El servicio no tiene token de cancelación propio. | «cancellation and permission denial…» |
| Permiso denegado | `permissionDenied` propagado. No hay flujo de solicitud de permiso. | misma prueba |
| Cuenta cruzada | La clave depende de perfil y acompañante, no de la cuenta; la cuenta va en la ruta y en el sobre. `load` devuelve `failed` si `accountId` del documento o del sobre no coincide. | «save/load are scoped to account…» (el fake devuelve «no encontrado» para otra cuenta); la comparación del sobre no tiene prueba directa |
| Cambio de cuenta o de acompañante | Claves distintas por ámbito; no hay mezcla de memorias | «snapshot is profile and companion scoped…» |
| Error inesperado | `catch` general → `failed` | — |

## 8. Qué NO hace todavía

- **Adaptador real de Google Drive**: el servicio habla con una interfaz `MemoryCloudTransport`. No hay OAuth, `appDataFolder` ni identidad real (T030).
- **Pantalla de memoria**: no hay forma de ver, editar, confirmar o borrar recuerdos desde la app (T027), ni botones de guardar, cargar o borrar en nube (T031).
- **Chat**: ningún flujo llama a `acceptPersisted` ni pasa recuerdos al contexto del chat (nota de T026).
- **Importación**: falta la vista previa de importación entre perfiles o acompañantes (T029).
- **Reconciliación**: no hay reintentos ni comprobación automática tras un resultado incierto.
- **Borrado físico local**: solo borrado lógico.

## 9. Validación con Google real (no ejecutada)

**Resultado: bloqueado.** Faltan la autorización del propietario, una cuenta desechable y el adaptador (T030). Procedimiento propuesto para cuando existan:

1. Confirmar autorización por escrito y usar una cuenta Google desechable con datos sintéticos.
2. Guardar las credenciales OAuth fuera de git. No usar `.signing/` ni `android/key.properties`.
3. Implementar el adaptador (T030) y ejecutar `test/memory_cloud_test.dart` con el transporte simulado antes de nada.
4. Conceder `drive.appdata` y comprobar que la pantalla muestra la cuenta correcta.
5. Guardar un snapshot sintético (revisión 1); repetir con una `knownRevision` antigua y comprobar el conflicto.
6. Cargar desde una instalación limpia y comparar los datos.
7. Cancelar el consentimiento y comprobar que la configuración anterior no cambia.
8. Denegar el permiso y comprobar el mensaje de error.
9. Cortar la red durante una escritura y comprobar que aparece «incierto», no «éxito».
10. Borrar en la nube y en local por separado, y comprobar cada resultado.
11. Registrar fecha, versión y resultado en `docs/005-QA.md`, sin datos de la cuenta.

## 10. Cómo probar hoy

```bash
cd "/Users/daniel/Desktop/TrackIA app"
export PATH="$PWD/.tools/flutter-3.47/flutter/bin:$PATH"
export JAVA_HOME="$PWD/.tools/jdk-17.0.20.1+1/Contents/Home"
./scripts/flutter-local.sh test --no-pub test/memory_cloud_test.dart test/memory_snapshot_test.dart \
  test/memory_proposal_test.dart test/companion_memory_test.dart test/companion_memory_repository_test.dart
```

Resultado de este documento (2026-11-07): los cinco archivos pasan, 39 pruebas en total. Esto valida la lógica con SQLite real y transporte simulado. **No valida Google Drive, OAuth ni la interfaz.**

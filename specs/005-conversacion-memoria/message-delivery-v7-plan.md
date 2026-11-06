# Reenvío fiable de mensajes: trabajo pendiente de almacenamiento v7

## Estado comprobado

El esquema abierto actualmente usa SQLite `version: 6`. La tabla `trackia_chats`
guarda el chat activo como un único `payload` JSON y `ChatStore.saveActive`
reemplaza ese payload en una transacción. No hay una identidad de mensaje con
estado de entrega que se pueda actualizar de forma condicional, ni operaciones
de efecto ligadas a una revisión. Por ello el payload JSON por sí solo no puede
garantizar simultáneamente cola ordenada, transición durable antes del envío,
recuperación tras cierre y reconciliación sin reejecutar efectos.

## Política lista para integrar

`lib/application/message_delivery_policy.dart` define reglas puras y no afirma
persistencia:

- `pending` y `failed` solo son reintentables si `failed` significa rechazo
  confirmado antes de aceptación.
- Antes del trabajo externo, el llamador debe persistir `sending`.
- Si el proceso reinicia en `sending`, se recupera como `uncertain`; nunca se
  reenvía automáticamente.
- Un timeout o fallo de red ambiguo queda `uncertain`. Una respuesta tardía
  puede cerrar ese mismo mensaje como `answered`.
- Solo se adjuntan respuestas al ID original. Los efectos exigen operación
  idempotente o reconciliación independiente antes de repetir.

## Requisito de v7 para completar T009/T010

1. Añadir migración aditiva y transaccional desde v6; no inferir entrega para
   mensajes históricos. Mantener legible el payload de chat y hacer copia y
   recuperación verificadas según las convenciones existentes.
2. Almacenar mensajes por `id`, `profile_id`, `companion_id`, `chat_id`,
   `created_at`, revisión vigente y entrega; revisar claves foráneas/índices
   para que una consulta de reenvío quede acotada al perfil, acompañante y chat
   de origen. Adjuntos deben referenciar el almacenamiento existente.
3. Guardar revisiones inmutables con unicidad `(message_id, revision)` y
   `supersedes_id`; actualizar la revisión vigente mediante transacción y
   revisión esperada para evitar carreras con respuestas tardías.
4. Ofrecer en repositorio una transición condicional (`pending|failed` a
   `sending`) y recuperar `sending` a `uncertain` al abrir el ámbito. No enviar
   hasta confirmar el commit. Cola estable por fecha y desempate por ID.
5. Añadir relación de efecto con `operation_id` único. Resultado incierto no
   vuelve a ejecutar la operación; debe reconciliar el destino o requerir
   decisión explícita.
6. Definir un puente de lectura/escritura que mantenga un único origen de
   verdad durante compatibilidad del payload legacy. No mantener dos colas
   editables en paralelo.

## Pruebas de aceptación tras v7

Usar SQLite sintético real y cerrar/reabrir la base entre cada punto; no usar
un fake que pretenda probar durabilidad:

- Dos pendientes conservan orden, IDs, chat/acompañante de origen y adjuntos.
- Una respuesta se agrega una vez al mismo mensaje; una tardía posterior al
  timeout no crea un mensaje duplicado.
- Fallo conocido antes de aceptación permite reintento; caída después del
  commit `sending` restaura `uncertain` y no despacha de nuevo.
- La transacción de edición conserva revisión previa; las respuestas de una
  revisión vieja no sustituyen el estado de una revisión nueva.
- Un efecto confirmado no se repite; un efecto incierto debe reconciliarse.
- Aislamiento por perfil/acompañante y migración v6 con payload legacy,
  adjuntos y recuperación tras fallos inyectados.

La prueba actual `test/message_delivery_policy_test.dart` cubre únicamente la
política determinista. No cubre red, UI, repositorio, reinicio real ni efectos;
la integración y los criterios de arriba siguen pendientes de v7.

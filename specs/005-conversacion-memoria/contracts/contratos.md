# Contratos de comportamiento

## Mensajes y efectos

La UI ofrece Editar a los mensajes propios y Reenviar a pendientes/fallidos/inciertos. Editar abre borrador con texto actual; cancelar no cambia nada. Confirmar crea revisión, sin borrar original. Si no hay efecto: enviar revisión y conservar respuestas anteriores. Si hay un efecto inequívoco y reversible: mostrar antes/después y confirmar; si hay varios, pedir elección. No ejecutar correcciones destructivas ni modificar Sheets por inferencia. Cada envío captura perfil/chat/versión y un ID de operación persistente; reconexión no cambia destino. La respuesta confirma solo operaciones con resultado real. Para solicitud con resultado incierto, consultar estado antes de reenviar efectos; si no hay forma de comprobar, mostrar incertidumbre y pedir decisión, sin duplicar automáticamente.

## Actividad

La IA propone cambios tipados de actividad identificada, revisión esperada y campos; la app valida y rechaza revisión obsoleta. Cambios de nombre, objetivo y descanso se aplican localmente y se informan tras guardar. Objetivo menor al progreso conserva ambos valores. Aviso en curso no se altera sin confirmación. Cambios ambiguos se preguntan; controles locales permanecen disponibles.

## Memoria

Propuesta estructurada contiene contenido, fuente y decisión `save|ask|ignore`; validar tamaño y ámbito. Petición explícita válida se guarda; `ask` solo se guarda con aceptación; `ignore` no se guarda. Relevancia es estimación, nunca promesa; mostrar y permitir corregir/borrar. La memoria no permite acciones ni sustituye instrucciones. La copia a Google requiere cuenta, alcance y confirmación; snapshot v1 sin secretos. Guardar compara revisión remota conocida, cargar previsualiza reemplazos/conflictos, borrar nube confirma cuenta y verifica respuesta; fallo incierto no declara éxito. Borrar local no borra nube ni viceversa. Respaldo restaurado jamás activa permisos ni acciones externas.

## Acuerdo de apoyo

La IA propone campos opcionales; el usuario acepta antes de crear o modificar. El motor local cuenta solo eventos confirmados, respeta pausa y no deduce conducta de reloj o dispositivo. Avisos indican configuración y resultado de permisos. No pedir acceso a otras apps en este incremento.

## Sheets e idiomas

Conexión → cuenta → selección de hoja → pestaña → previsualización → confirmar o cancelar; conservar destino anterior hasta confirmación. Las operaciones siguen las comprobaciones y permisos existentes. Idioma de interfaz `system|es|en|ar`; guardar preferencia, usar dirección RTL en árabe y no alterar texto de usuario. Prompts piden responder en idioma elegido sin imponer traducción al contenido original.

# Uso real: mejoras propuestas

Notas de producto del 5 de noviembre de 2026. Son propuestas y observaciones del usuario, no funcionalidades implementadas ni pruebas de aceptación cerradas.

## Observaciones y prioridades

- El usuario confirma que recibe recordatorios al dejar la actividad y que le gustan sus mensajes. Esto no sustituye la prueba de dos días ni la de No molestar.
- Permitir corregir un mensaje y reenviarlo: conservar trazabilidad del original y asociar la corrección a los registros afectados; evitar duplicados y pedir confirmación si el efecto no es inequívoco. Ejemplo: «10r 10k f» era «10r 60k f».
- Conservar mensajes pendientes ante fallo del modelo, identificar cuáles no han recibido respuesta y ofrecer reenvío; recuperar el contexto sin exigir que el usuario pida releerlo. Evitar duplicar efectos al reintentar.
- Investigar el error al cambiar de tres a cuatro series: apareció un error y el contador mostró 4 de 3. Revisar también modificaciones de nombres y descansos de actividades ya creadas. El texto exacto del error aún no consta.
- Unificar la conexión Google y la elección de hoja y pestaña en un mismo recorrido, con opción de cargar datos.
- Añadir el logo a la pantalla principal y sustituir «Esperando modelo» por frases variadas y apropiadas al acompañante, sin atribuir operaciones no verificadas.

## Memoria y personalidad

Memoria independiente por perfil y acompañante, persistente tras archivar el chat. Guardar las instrucciones explícitas de recordar y evaluar hechos relevantes para sesiones posteriores; ante dudas, preguntar. El usuario puede consultar, editar y borrar recuerdos. Ejemplo: «igual» significa repetir las series y repeticiones anteriores, pero la app debe pedir aclaración si la referencia no es inequívoca.

Diseñar copia voluntaria en Google, aprovechando la conexión disponible cuando sea viable, con guardar, cargar y borrar localmente y en la nube como acciones claras e independientes. Investigar permisos, cifrado, conflictos, restauración y separación entre cuentas antes de elegir implementación. No afirmar que la copia existente ya soporta esta memoria.

El usuario puede describir libremente la personalidad y el tono de cada acompañante y pedir ayuda a la IA para definirlos. Los estilos sugeridos son puntos de partida, no una lista cerrada. Mantener separado el estilo de las reglas y límites de las acciones.

## Apoyo para hábitos y límites elegidos

Propuesta general, no limitada a dejar de fumar: el usuario describe qué desea cambiar, cuándo y qué tipo de apoyo quiere. El acompañante propone un acuerdo editable con señales, objetivo, avisos y respuesta ante desvíos; el usuario decide. Evitar culpa y permitir pausar o cambiar el acuerdo.

Ejemplo de ajedrez: antes de jugar, acordar cinco partidas de tres minutos; registrar manualmente cada partida y avisar al llegar a cinco, con opciones para cerrar, aplazar o modificar el límite. Una alerta temporal opcional ayuda si las partidas se alargan. La primera versión no presupone acceso al historial de la plataforma de ajedrez ni capacidad de bloquearla. Registrar desvíos solo si el usuario quiere y usar el contexto para ajustar el acuerdo en sesiones siguientes.

Para dejar de fumar u otros hábitos sensibles, permitir objetivos y seguimiento definidos por la persona, respuestas sin juicios y recursos de apoyo apropiados; no presentar el acompañante como sustituto de atención profesional.

## Idiomas e iOS

Preparar internacionalización extensible y ofrecer español, inglés y árabe; comprobar dirección RTL, disposición, contenido mixto, fechas y plurales, además de textos generados por IA y notificaciones. No basta con traducir cadenas.

Plan iOS: inventariar canales nativos y plugins; instalar Xcode y configurar firma; compilar y ejecutar en simulador; adaptar autenticación Google, avisos, archivos, IA local y demás funciones dependientes de Android; verificar persistencia y accesibilidad; probar en iPhone y preparar distribución. TestFlight o App Store aún no se han decidido. La base Flutter existente no equivale a una versión iOS validada.

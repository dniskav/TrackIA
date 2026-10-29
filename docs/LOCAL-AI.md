# Modelos locales de IA

TrackIA integra `llama.cpp` mediante el paquete Flutter `llama_cpp_dart` para
ejecutar modelos GGUF en Android ARM64. La inferencia se realiza en el móvil;
no envía el prompt a una API. Solo se mantiene un modelo cargado a la vez y se
conserva en memoria entre turnos para evitar cargarlo de nuevo en cada mensaje.

En **Ajustes → Proveedor de IA → Modelo local**, importa el archivo `.gguf` del
modelo. Los modelos visuales necesitan además el proyector `mmproj` compatible.
TrackIA copia los archivos al almacenamiento privado de la app y muestra una
estimación orientativa de RAM antes de cargar. La memoria disponible cambia con
las demás apps abiertas, así que la estimación puede advertir de una carga que
el teléfono sí consiga completar o que Android termine interrumpiendo.

MiniCPM‑V 4.7 1B es la primera configuración de prueba prevista. El repositorio
oficial publica variantes GGUF Q4 y un proyector visual: [modelo oficial en
Hugging Face](https://huggingface.co/openbmb/MiniCPM-V-4.7-1B-gguf). Descarga una
pareja de archivos compatible y selecciónalos desde TrackIA. La configuración
CPU móvil usa una ventana de contexto deliberadamente pequeña; el modelo puede
responder más despacio o con menos capacidad que los proveedores en la nube.

La integración requiere Flutter 3.44 o posterior y Android ARM64. El paquete
vendorizado está en `packages/llama_cpp_dart`; su lector de AAR se adapta al
`archive` 3.x ya requerido por el importador Excel del proyecto.

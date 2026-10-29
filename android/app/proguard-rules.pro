# Reglas de R8 para TrackIA (release). Flutter añade las suyas; aquí solo lo propio.

# Puentes nativos propios (MethodChannel) y receptores declarados en el manifiesto.
-keep class com.gymia.app.** { *; }

# llama_cpp_dart llama al código nativo por FFI de Dart: no hay clases Java que conservar.
# Plugins con reflexión (flutter_secure_storage usa Tink/Keystore) traen sus propias reglas de consumidor.

# Flutter menciona Play Core (componentes diferidos) aunque la app no lo usa.
-dontwarn com.google.android.play.core.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

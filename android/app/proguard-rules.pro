# --- REGLAS DE FLUTTER ---
# Estas reglas las provee el equipo de Flutter.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep public class * extends io.flutter.plugin.common.PluginRegistry { *; }
-keep public class * extends io.flutter.plugin.common.MethodChannel.MethodCallHandler { *; }

# --- REGLAS PARA ARREGLAR TU CRASH ---
# ¡Estas son las reglas clave que faltaban!
# Le dicen a R8 que no borre las clases de Google Play Core.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# --- REGLAS PARA 'flutter_secure_storage' ---
# Esta regla es la que arregla el MissingPluginException
-keep class androidx.security.crypto.** { *; }

# --- REGLAS PARA PLUGINS COMUNES (por si acaso) ---
# (http, video_player, etc.)
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**
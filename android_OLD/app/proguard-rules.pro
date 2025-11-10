# Reglas para Flutter (evita que R8 rompa el motor de Flutter)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**

# Regla para flutter_secure_storage (la que arregló el MissingPluginException)
-keep class androidx.security.crypto.** { *; }

# --- ¡NUEVAS REGLAS! ---
# Reglas para Google Play Core (las que faltaban y causan el error de R8)
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**
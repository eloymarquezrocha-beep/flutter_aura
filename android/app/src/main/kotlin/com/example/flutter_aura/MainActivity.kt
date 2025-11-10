package com.example.flutter_aura

// --- Imports añadidos ---
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    
    // --- ¡FUNCIÓN AÑADIDA! ---
    // Esto fuerza a Flutter a registrar manualmente TODOS los plugins
    // (incluyendo flutter_secure_storage)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // NO llames a super.configureFlutterEngine()
        // El registro manual reemplaza al automático.
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
    // -------------------------
}
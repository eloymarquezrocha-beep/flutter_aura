import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'storage_service.dart';
import 'message_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login.dart'; // Asegúrate que el nombre del archivo login sea correcto

// --- (AÑADIDO) Imports para la API y JSON ---
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- (AÑADIDO) La IP de tu servidor ---
const String API_BASE = "https://dragonpardo.com";
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> chatSessions = [];
  final _storage = const FlutterSecureStorage();

  // --- (AÑADIDO) Variables para guardar los datos del perfil ---
  Map<String, dynamic>? _userData;
  bool _isLoadingProfile = true;
  String _profileError = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // --- (NUEVO) Función que carga todo al iniciar ---
  void _loadAllData() {
    // Carga ambas cosas en paralelo
    _loadSessions();
    _loadProfile();
  }

  void _loadSessions() {
    // (Esta es la lógica de tu amigo, está perfecta)
    final allMessages = StorageService.getMessages();
    final Map<String, List<MessageModel>> sessionsMap = {};
    for (var msg in allMessages) {
      sessionsMap.putIfAbsent(msg.sessionId, () => []);
      sessionsMap[msg.sessionId]!.add(msg);
    }
    final sessionsList = sessionsMap.entries.map((e) {
      e.value.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return {
        "id": e.key,
        "messages": e.value,
        "lastDate": e.value.last.timestamp,
      };
    }).toList();
    sessionsList.sort(
        (a, b) => (b["lastDate"] as DateTime).compareTo(a["lastDate"] as DateTime));
    setState(() {
      chatSessions = sessionsList;
    });
  }

  // --- (NUEVO) Llama al endpoint /profile ---
  Future<void> _loadProfile() async {
    setState(() { _isLoadingProfile = true; _profileError = ''; });
    try {
      final token = await _storage.read(key: "aura_token");
      if (token == null) {
        throw Exception("No se encontró token.");
      }

      final res = await http.get(
        Uri.parse("$API_BASE/profile"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _userData = data;
        });
      } else {
        throw Exception("Error al cargar el perfil: ${res.statusCode}");
      }
    } catch (e) {
      setState(() { _profileError = e.toString(); });
    } finally {
      setState(() { _isLoadingProfile = false; });
    }
  }

  // --- (Lógica de Chat y Logout - sin cambios) ---
  void _openChat(String sessionId, List<MessageModel> messages) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          sessionId: sessionId,
          initialMessages: messages,
        ),
      ),
    );
    _loadSessions();
  }

  void _createNewChat() async {
    final newSessionId = StorageService.createNewSession();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          sessionId: newSessionId,
          initialMessages: const [],
        ),
      ),
    );
    _loadSessions();
  }

  void _deleteChat(String sessionId) async {
    await StorageService.deleteMessagesBySession(sessionId);
    _loadSessions();
  }

  void _handleLogout() async {
    await _storage.delete(key: "aura_token");
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Perfil",
          style: TextStyle(color: Colors.white, fontFamily: "MonosRegular"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // --- (MODIFICADO) Sección de Perfil Dinámica ---
            _isLoadingProfile
                ? const Center(child: CircularProgressIndicator())
                : _profileError.isNotEmpty
                    ? Text(_profileError, style: const TextStyle(color: Colors.red))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _userData?['nombre'] ?? 'Nombre no encontrado',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: "MonosRegular",
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _userData?['carrera'] ?? 'Carrera no registrada',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontFamily: "MonosRegular",
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _userData?['cuatrimestre'] ?? 'Cuatrimestre no registrado',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                fontFamily: "MonosRegular",
                              ),
                            ),
                          ),
                        ],
                      ),
            // --- Fin de la Modificación ---

            const SizedBox(height: 50),

            // ===== HISTORIAL (Sin cambios) =====
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      "Historial",
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: "MonosRegular",
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: chatSessions.isEmpty
                          ? const Center(
                              child: Text(
                                "No hay conversaciones aún",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontFamily: "MonosRegular",
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              itemCount: chatSessions.length,
                              itemBuilder: (context, index) {
                                final session = chatSessions[index];
                                final messages =
                                    session["messages"] as List<MessageModel>;
                                final lastDate =
                                    session["lastDate"] as DateTime;

                                final firstUserMessage = messages.firstWhere(
                                  (m) => m.sender == 'user',
                                  orElse: () => MessageModel(
                                    id: "",
                                    text: "Conversación vacía",
                                    sender: "user",
                                    timestamp: DateTime.now(),
                                    sessionId: session["id"] as String, 
                                  ),
                                ).text;

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: ListTile(
                                      onTap: () => _openChat(
                                          session["id"] as String, messages),
                                      title: Text(
                                        firstUserMessage,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: "MonosRegular",
                                        ),
                                      ),
                                      subtitle: Text(
                                        "${lastDate.day.toString().padLeft(2, '0')}/${lastDate.month.toString().padLeft(2, '0')} "
                                        "${lastDate.hour.toString().padLeft(2, '0')}:${lastDate.minute.toString().padLeft(2, '0')}",
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontFamily: "MonosItalic",
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent),
                                        onPressed: () =>
                                            _deleteChat(session["id"] as String),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),

            // ===== BOTÓN NUEVO CHAT (Sin cambios) =====
            ElevatedButton(
              onPressed: _createNewChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 14),
              ),
              child: const Text(
                "Nuevo chat",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: "MonosRegular",
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ===== BOTÓN CERRAR SESIÓN (Sin cambios) =====
            ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 14),
              ),
              child: const Text(
                "Cerrar sesión",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: "MonosRegular",
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
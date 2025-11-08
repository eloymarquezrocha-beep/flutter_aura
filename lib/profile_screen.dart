import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'storage_service.dart';
import 'message_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> chatSessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    final allMessages = StorageService.getMessages();

    final Map<String, List<MessageModel>> sessionsMap = {};
    for (var msg in allMessages) {
      sessionsMap.putIfAbsent(msg.sessionId ?? "default", () => []);
      sessionsMap[msg.sessionId ?? "default"]!.add(msg);
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
    _loadSessions(); // recarga al volver
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
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Raul Mariano",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: "MonosRegular",
                ),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Licenciatura en Creatividad Tecnológica",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: "MonosRegular",
                ),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Cuatrimestre 5",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontFamily: "MonosRegular",
                ),
              ),
            ),
            const SizedBox(height: 50),

            // ===== HISTORIAL =====
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
                                  sessionId: session["id"] as String, // ✅ Se agrega el campo requerido
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

            // ===== BOTÓN NUEVO CHAT =====
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

            // ===== BOTÓN CERRAR SESIÓN =====
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
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

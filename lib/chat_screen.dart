import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dash_chat_3/dash_chat_3.dart';
import 'package:uuid/uuid.dart';
import 'message_model.dart';
import 'storage_service.dart';
import 'openai_service.dart';
import 'wave.dart';
import 'calendario.dart';
import 'profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final List<MessageModel>? initialMessages;
  final String sessionId;

  const ChatScreen({
    super.key,
    this.initialMessages,
    required this.sessionId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final List<ChatMessage> messages = [];
  final ChatUser user = ChatUser(id: 'user', firstName: 'Tú');
  final ChatUser bot = ChatUser(id: 'bot', firstName: 'Aura');
  final uuid = const Uuid();
  final OpenAIService openAIService = OpenAIService();

  bool _isTyping = false;
  String _typingText = "";

  double _waveSpeed = 1.0;
  double _waveAmplitude = 10;
  int _ringCount = 4;
  Color _waveColor = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialMessages != null && widget.initialMessages!.isNotEmpty) {
      messages.addAll(widget.initialMessages!.map(
        (m) => ChatMessage(
          text: m.text,
          user: m.sender == 'user' ? user : bot,
          createdAt: m.timestamp,
        ),
      ));
    } else {
      _loadMessagesFromStorage();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _loadMessagesFromStorage() {
    final stored = StorageService.getMessages();
    final filtered =
        stored.where((m) => m.sessionId == widget.sessionId).toList();
    setState(() {
      messages.addAll(filtered.map(
        (m) => ChatMessage(
          text: m.text,
          user: m.sender == 'user' ? user : bot,
          createdAt: m.timestamp,
        ),
      ));
    });
  }

  void _updateWave(bool typing) {
    setState(() {
      _isTyping = typing;
      if (typing) {
        _waveSpeed = 2.8;
        _waveAmplitude = 17;
        _ringCount = 6;
        _waveColor = const Color(0xFF3FA7FF);
      } else {
        _waveSpeed = 1.0;
        _waveAmplitude = 10;
        _ringCount = 4;
        _waveColor = Colors.white;
      }
    });
  }

  Future<void> _handleSend(ChatMessage msg) async {
    if (msg.text.trim().isEmpty) return;

    setState(() {
      messages.add(msg);
      _typingText = "";
    });

    _updateWave(true);

    await StorageService.saveMessage(
      MessageModel(
        id: uuid.v4(),
        text: msg.text,
        sender: msg.user.id,
        timestamp: msg.createdAt ?? DateTime.now(),
        sessionId: widget.sessionId,
      ),
    );

    try {
      final reply = await openAIService.sendMessage(msg.text);
      for (int i = 0; i < reply.length; i++) {
        await Future.delayed(const Duration(milliseconds: 25));
        setState(() {
          _typingText = reply.substring(0, i + 1);
        });
      }

      final botMsg = ChatMessage(
        text: _typingText,
        user: bot,
        createdAt: DateTime.now(),
      );

      await StorageService.saveMessage(
        MessageModel(
          id: uuid.v4(),
          text: botMsg.text,
          sender: bot.id,
          timestamp: botMsg.createdAt,
          sessionId: widget.sessionId,
        ),
      );

      setState(() => messages.add(botMsg));
    } catch (e) {
      setState(() => _typingText = "⚠️ Error al comunicarse con la IA");
    }

    _updateWave(false);
  }

  InputOptions _buildInputOptions() {
    return InputOptions(
      inputDecoration: InputDecoration(
        hintText:
            _isTyping ? "Aura está escribiendo..." : "Escribe un mensaje...",
        hintStyle: TextStyle(
          color: _isTyping ? Colors.white38 : Colors.white70, fontFamily: String.fromEnvironment('MonosRegular' )
        ),
        filled: true,
        fillColor: _isTyping ? Colors.black26 : Colors.white12,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      inputTextStyle: const TextStyle(color: Colors.white, fontFamily: 'MonosRegular'),
      alwaysShowSend: true,
      sendButtonBuilder: (send) {
        return IconButton(
          icon: Icon(
            Icons.send_rounded,
            color: _isTyping ? Colors.white30 : Colors.white,
          ),
          onPressed: _isTyping ? null : send,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final reversedMessages = List<ChatMessage>.from(messages.reversed);
    if (_isTyping) {
      reversedMessages.insert(
        0,
        ChatMessage(
          text: _typingText,
          user: bot,
          createdAt: DateTime.now(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:  Color.fromARGB(255, 19, 19, 19),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(0, 255, 0, 0),
        elevation: 0,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color.fromARGB(255, 255, 0, 0)),
            onPressed: () async {
              await StorageService.deleteMessagesBySession(widget.sessionId);
              setState(() => messages.clear());
            },
          ),
          IconButton(
            icon: Image.asset('assets/Perfil.png', width: 26),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          /// 🌊 Wave al fondo total
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Align(
                alignment: Alignment.topCenter,
                child: WaveCircle(
                size: screenWidth * 0.9,
  speed: _waveSpeed,
  amplitude: _waveAmplitude,
  rings: _ringCount,
  color: _waveColor, // cambia dinámicamente entre blanco y azul
                ),
              ),
            ),
          ),

          /// 💬 Mensajes + input
          Column(
            children: [
              Expanded(
                child: Container(
                  margin: 
                  const EdgeInsets.symmetric(horizontal: 10,),
                  child: DashChat3(
                    currentUser: user,
                    messages: reversedMessages,
                    onSend: _handleSend,
                    inputOptions: _buildInputOptions(),
                    messageOptions: MessageOptions(
                      textColor: Colors.white,
                      borderRadius: 16,
                      showOtherUsersAvatar: false,
                      messagePadding: const EdgeInsets.all(12),
                      messageDecorationBuilder:
                          (ChatMessage msg, ChatMessage? prev, ChatMessage? next) {
                        final isUser = msg.user.id == user.id;
                        return BoxDecoration(
                          color: (isUser
                                  ? const Color.fromARGB(255, 65, 65, 65)
                                  : const Color.fromARGB(255, 110, 110, 110)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.2,
                          ),
                        );
                      },

                      messageRowBuilder: (ChatMessage msg, _, __, ___, ____) {
                        final isUser = msg.user.id == user.id;
                        final maxBubbleWidth = MediaQuery.of(context).size.width * 0.72;

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.only(
                              left: isUser ? 40.0 : 5.0,
                              right: isUser ? 5.0 : 40.0,
                              top: 10.0,
                              bottom: 10.0,
                            ),
                            constraints: BoxConstraints(
                              maxWidth: maxBubbleWidth,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 15,
                                  sigmaY: 15,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? const Color.fromARGB(180, 65, 65, 65)
                                        : const Color.fromARGB(180, 110, 110, 110),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    msg.text,
                                    style: const TextStyle(color: Colors.white,fontFamily: 'MonosRegular'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }, 
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      bottomNavigationBar: Container(
        color: Color.fromARGB(0, 13, 13, 13),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navButtonSelected("assets/House.png"),
            _navButtonInactive("assets/Calendar.png", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomCalendarScreen(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _navButtonSelected(String asset) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(0, 13, 13, 13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(asset, width: 32, color: Colors.white),
    );
  }

  Widget _navButtonInactive(String asset, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(0, 13, 13, 13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(asset, width: 30, color: Colors.grey.shade600),
      ),
    );
  }
}

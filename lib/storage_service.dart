import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'message_model.dart';

class StorageService {
  static const String boxName = 'chat_messages';
  static final Uuid _uuid = Uuid();

  // ✅ Inicializa Hive y abre la caja
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MessageModelAdapter());
    }
    await Hive.openBox<MessageModel>(boxName);
  }

  // ✅ Guardar mensaje en la base de datos
  static Future<void> saveMessage(MessageModel message) async {
    final box = Hive.box<MessageModel>(boxName);
    await box.add(message);
  }

  // ✅ Obtener todos los mensajes
  static List<MessageModel> getMessages() {
    final box = Hive.box<MessageModel>(boxName);
    return box.values.toList();
  }

  // ✅ Obtener mensajes de una sesión específica
  static List<MessageModel> getMessagesBySession(String sessionId) {
    final box = Hive.box<MessageModel>(boxName);
    return box.values.where((m) => m.sessionId == sessionId).toList();
  }

  // ✅ Eliminar todos los mensajes
  static Future<void> clearMessages() async {
    final box = Hive.box<MessageModel>(boxName);
    await box.clear();
  }

  // ✅ Eliminar mensajes de una sesión específica
  static Future<void> deleteMessagesBySession(String sessionId) async {
    final box = Hive.box<MessageModel>(boxName);
    final messagesToDelete =
        box.values.where((msg) => msg.sessionId == sessionId).toList();

    for (var msg in messagesToDelete) {
      await msg.delete();
    }
  }

  // ✅ Obtener todas las sesiones únicas
  static List<String> getAllSessions() {
    final box = Hive.box<MessageModel>(boxName);
    final all = box.values.map((m) => m.sessionId).whereType<String>().toSet();
    return all.toList();
  }

  // ✅ Crear un nuevo ID de sesión único
  static String createNewSession() {
    return _uuid.v4();
  }
}

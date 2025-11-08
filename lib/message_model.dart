import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 0)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final String sender; // 'user' o 'bot'

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String sessionId; // 🔥 NUEVO: ID único por conversación

  MessageModel({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    required this.sessionId,
  });
}

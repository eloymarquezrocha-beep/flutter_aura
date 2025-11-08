import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'message_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MessageModel> stored = [];

  @override
  void initState() {
    super.initState();
    stored = StorageService.getMessages().reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: ListView.builder(
        itemCount: stored.length,
        itemBuilder: (context, index) {
          final m = stored[index];
          return ListTile(
            leading: Icon(m.sender == 'user' ? Icons.person : Icons.smart_toy),
            title: Text(
              m.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              m.timestamp.toLocal().toString(),
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}

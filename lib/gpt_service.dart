import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GptService {
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  static Future<String> sendMessage(String message) async {
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini", // puedes usar "gpt-4-turbo" o "gpt-3.5-turbo"
        "messages": [
          {"role": "user", "content": message}
        ],
        "max_tokens": 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reply = data['choices'][0]['message']['content'];
      return reply.trim();
    } else {
      print('Error: ${response.body}');
      throw Exception('Error ${response.statusCode}');
    }
  }
}

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  late final OpenAI _openAI;

  OpenAIService() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("⚠️ API key no encontrada en .env");
    }

    _openAI = OpenAI.instance.build(
      token: apiKey,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 30)),
      enableLog: true,
    );
  }

  Future<String> sendMessage(String prompt) async {
    try {
      final request = ChatCompleteText(
        messages: [
          Map.of({
            "role": "user",
            "content": prompt,
          }),
        ],
        maxToken: 200,
        model: Gpt4oMiniChatModel(), // ✅ modelo correcto (GPT-4o-mini)
      );

      final response = await _openAI.onChatCompletion(request: request);

      if (response == null ||
          response.choices.isEmpty ||
          response.choices.first.message == null) {
        return "⚠️ Sin respuesta del modelo.";
      }

      return response.choices.first.message!.content.trim();
    } catch (e) {
      return "⚠️ Error al comunicarse con OpenAI: $e";
    }
  }
}

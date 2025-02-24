import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:study_planner/pages/gemini_ai.dart';

class GeminiApiService {
  final String apiKey;
  late GenerativeModel model;

  GeminiApiService(this.apiKey) {
    model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
    );
  }

  Future<String> sendMessage(String userInput) async {
    try {
      final chat = model.startChat(history: []);
      final content = Content.text(userInput);
      final response = await chat.sendMessage(content);
      return response.text ?? "No response from Gemini AI.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
}
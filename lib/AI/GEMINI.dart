import 'package:flutter/material.dart';
import 'google_generativeai.dart';
import 'GEMINI_API_KEY.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Gemini extends StatelessWidget {
  const Gemini({Key? key}) : super(key: key);

  void main() async {
    await FlutterDotenv.load();  // Load environment variables

    final apiKey = FlutterDotenv.get('API_KEY');  // Correctly retrieve the API key
    if (apiKey == null) {
      print("Error: API key not found.");
      return;
    }

    final ai = GoogleGenerativeAI(apiKey: apiKey);

    // Example usage
    final response = await ai.generate(prompt: "Tell me a joke", apiKey: null);
    if (response != null && response.candidates.isNotEmpty) {
      print(response.candidates[0].text);
    } else {
      print("Could not generate a response.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gemini AI Example'),
      ),
      body: Center(
        child: Text('Gemini AI is working!'),
      ),
    );
  }
}

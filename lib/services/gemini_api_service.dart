import 'dart:convert';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';
import 'package:study_planner/config/api_keys.dart';

class GeminiApiService {
  final String apiKey = ApiKeys.geminiApiKey;
  late final GenerativeModel _model;

  GeminiApiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // ✅ Single multimodal model
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      ),
    );
  }

  /// ✅ Unified method to handle Text and Image together.
  Future<String> sendMessageWithOptionalImage(String userInput, {File? imageFile}) async {
    try {
      final List<Part> parts = [];

      // ✅ If image is provided, add it
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

        parts.add(DataPart(mimeType, bytes)); // Correct usage for multimodal
      }

      // ✅ Add the user question as text part
      parts.add(TextPart(userInput));

      // ✅ Now create the content with "user" role
      final content = Content('user', parts);

      // ✅ Send the message and return AI response
      final response = await _model.generateContent([content]);
      final textResponse = response.text?.trim() ?? 'No response from AI.';
      print('✅ AI Response: $textResponse');
      return textResponse;
    } catch (e) {
      print('❌ Error sending message: $e');
      return "Error processing your request.";
    }
  }

  /// ✅ Process PDF file and generate flashcards
  Future<List<Map<String, String>>> processPDF(File file) async {
    try {
      final extractedText = await _extractTextFromPDF(file);

      if (extractedText.isEmpty) {
        return [
          {"question": "Error", "answer": "PDF is empty or couldn't extract text."}
        ];
      }

      final aiResponse = await sendMessageWithOptionalImage(
        "Generate multiple flashcards covering all key concepts from this text. "
        "Each flashcard should be formatted as:\n"
        "Flashcard 1\nFront: [Question]\nBack: [Answer]\n\n"
        "Here is the extracted text:\n\n$extractedText",
      );

      final flashcards = _extractFlashcards(aiResponse);
      return flashcards.isNotEmpty
          ? flashcards
          : [
              {"question": "Error", "answer": "No flashcards were generated. Try a different PDF."}
            ];
    } catch (e) {
      return [
        {"question": "Error", "answer": "Failed to process PDF: $e"}
      ];
    }
  }

  /// ✅ Extract flashcards from AI response
  List<Map<String, String>> _extractFlashcards(String responseText) {
    final List<Map<String, String>> flashcards = [];
    final lines = responseText.split('\n').map((line) => line.trim().replaceAll('*', '')).toList();

    String? question;
    String? answer;

    for (var line in lines) {
      if (line.startsWith('Flashcard')) {
        if (question != null && answer != null) flashcards.add({"question": question, "answer": answer});
        question = null;
        answer = null;
      } else if (line.startsWith('Front:')) {
        question = line.replaceFirst('Front:', '').trim();
      } else if (line.startsWith('Back:')) {
        answer = line.replaceFirst('Back:', '').trim();
      }
    }

    if (question != null && answer != null) flashcards.add({"question": question, "answer": answer});
    return flashcards;
  }

  /// ✅ Extract and clean text from PDF
  Future<String> _extractTextFromPDF(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final buffer = StringBuffer();

    for (int i = 0; i < document.pages.count; i++) {
      final text = PdfTextExtractor(document).extractText(startPageIndex: i);
      buffer.writeln(text.trim());
    }

    document.dispose();
    return buffer.toString().replaceAll('*', '').replaceAll(RegExp(r'\n\s*\n'), '\n').trim();
  }
}

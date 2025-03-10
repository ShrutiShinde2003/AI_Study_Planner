import 'dart:convert';
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:study_planner/config/api_keys.dart';

class GeminiApiService {
  final String apiKey = ApiKeys.geminiApiKey;
  late final GenerativeModel _model;

  GeminiApiService() {
    _model = GenerativeModel(
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

  /// ✅ Normal text message handler
  Future<String> sendMessageWithOptionalImage(String userInput, {File? imageFile}) async {
    try {
      final chat = _model.startChat(history: []);

      List<Content> parts = [];

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

        parts.add(Content.multi([
          DataPart(mimeType, bytes),
          TextPart(userInput),
        ]));
      } else {
        parts.add(Content.text(userInput));
      }

      final response = await chat.sendMessage(parts.first);
      return response.text?.trim() ?? "No response from AI.";
    } catch (e) {
      return "❌ Error processing request: ${e.toString()}";
    }
  }

  /// ✅ Handle PDF as text and send to AI with user's command
  Future<String> sendMessageWithOptionalPdf(String userInput, {required File pdfFile}) async {
    try {
      final extractedText = await _extractTextFromPDF(pdfFile);

      if (extractedText.isEmpty) {
        return "❌ Failed to extract text from PDF.";
      }

      final chat = _model.startChat(history: []);
      final combinedPrompt = "$userInput\n\nPDF Content:\n$extractedText";
      final response = await chat.sendMessage(Content.text(combinedPrompt));

      return response.text?.trim() ?? "No response from AI.";
    } catch (e) {
      return "❌ Error processing PDF: ${e.toString()}";
    }
  }

  /// 🔹 Extract and process flashcards from AI based on PDF content
  Future<List<Map<String, String>>> processPDF(File file) async {
    try {
      final extractedText = await _extractTextFromPDF(file);

      if (extractedText.isEmpty) {
        return [
          {"question": "Error", "answer": "PDF is empty or text could not be extracted."}
        ];
      }

      final responseText = await sendMessageWithOptionalPdf(
        "Generate flashcards from this content. Format each as 'Front: Question' and 'Back: Answer'.",
        pdfFile: file,
      );

      final flashcards = _extractFlashcards(responseText);
      return flashcards.isNotEmpty
          ? flashcards
          : [
              {"question": "Error", "answer": "No flashcards were generated."}
            ];
    } catch (e) {
      return [
        {"question": "Error", "answer": "Failed to process PDF: $e"}
      ];
    }
  }

  /// 🔹 Extract flashcards from AI response text
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

  /// 🔹 Extract text from PDF for AI use
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

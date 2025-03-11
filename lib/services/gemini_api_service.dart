import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:study_planner/config/api_keys.dart';
import 'package:study_planner/models/flashcard_model.dart'; // ✅ Import Flashcard model

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

  /// ✅ Send message with optional image to Gemini AI
  Future<String> sendMessageWithOptionalImage(String userInput, {File? imageFile}) async {
    final chat = _model.startChat();

    List<Part> parts = [TextPart(userInput)];
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      parts.add(DataPart(mimeType, bytes)); // Correct Part type
    }

    final response = await chat.sendMessage(Content('user', parts));
    return response.text ?? "No response from AI.";
  }

  /// ✅ Send message with optional PDF content to Gemini AI
  Future<String> sendMessageWithOptionalPdf(String userInput, {required File pdfFile}) async {
    final extractedText = await _extractTextFromPDF(pdfFile);
    final chat = _model.startChat();

    final response = await chat.sendMessage(
      Content('user', [
        TextPart("$userInput\n\nHere is the extracted text:\n$extractedText")
      ]),
    );

    return response.text ?? "No response from AI.";
  }

  /// ✅ Extract and clean text from PDF file
  Future<String> _extractTextFromPDF(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final buffer = StringBuffer();

    for (int i = 0; i < document.pages.count; i++) {
      final text = PdfTextExtractor(document).extractText(startPageIndex: i);
      buffer.writeln(text.trim());
    }

    document.dispose(); // Release memory

    return buffer.toString().replaceAll('*', '').replaceAll(RegExp(r'\n\s*\n'), '\n').trim();
  }

  /// ✅ Process PDF and generate multiple flashcards using AI
  Future<List<Flashcard>> processPDF(File file) async {
    final extractedText = await _extractTextFromPDF(file);

    if (extractedText.isEmpty) {
      return [
        Flashcard(question: "Error", answer: "PDF is empty or could not extract text.")
      ];
    }

    final chat = _model.startChat();

    // Strong prompt for multi-flashcard generation
    final prompt = '''
Generate as many flashcards as possible from this text. 
Each flashcard must be formatted exactly like this:

Flashcard 1
Front: [Question]
Back: [Answer]

Flashcard 2
Front: [Question]
Back: [Answer]

Here is the text:
$extractedText
''';

    final response = await chat.sendMessage(Content('user', [TextPart(prompt)]));

    // Proper parsing
    final flashcards = extractFlashcards(response.text ?? '');

    return flashcards.isNotEmpty
        ? flashcards
        : [
            Flashcard(
              question: "Error",
              answer: "No flashcards were generated. Please try a different file.",
            )
          ];
  }

  /// ✅ Parse multiple flashcards from AI response
  List<Flashcard> extractFlashcards(String responseText) {
    final List<Flashcard> flashcards = [];

    // Split on "Flashcard" keyword
    final rawFlashcards = responseText.split(RegExp(r'Flashcard\s*\d*', caseSensitive: false));

    for (var raw in rawFlashcards) {
      if (raw.trim().isEmpty) continue;

      String? question;
      String? answer;

      // Match question and answer
      final frontMatch = RegExp(r'Front:\s*(.*)', caseSensitive: false).firstMatch(raw);
      final backMatch = RegExp(r'Back:\s*(.*)', caseSensitive: false).firstMatch(raw);

      if (frontMatch != null) question = frontMatch.group(1)?.trim();
      if (backMatch != null) answer = backMatch.group(1)?.trim();

      // Only add valid flashcards
      if (question != null && answer != null && question.isNotEmpty && answer.isNotEmpty) {
        flashcards.add(Flashcard(question: question, answer: answer));
      }
    }

    return flashcards;
  }
}

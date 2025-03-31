import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:study_planner/config/api_keys.dart';
import 'package:study_planner/models/flashcard_model.dart';

class GeminiApiService {
  final String apiKey = ApiKeys.geminiApiKey;
  late final GenerativeModel _model;

  GeminiApiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
        responseMimeType: 'text/plain',
      ),
    );
  }

  /// Text message & Optional Image for Q&A or Flashcard if asked
  Future<String> sendMessageWithOptionalImage(String userInput, {File? imageFile}) async {
    final chat = _model.startChat();
    List<Part> parts = [TextPart(userInput)];

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      parts.add(DataPart(mimeType, bytes));
    }

    final response = await chat.sendMessage(Content('user', parts));
    return response.text ?? "No response from AI.";
  }

  /// Message & PDF Text for Summary/QA/Flashcard
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

  /// Extract Text from PDF
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

  /// Process PDF for Flashcards (When explicitly asked)
  Future<List<Flashcard>> processPDF(File file) async {
    final extractedText = await _extractTextFromPDF(file);

    if (extractedText.isEmpty) {
      return [
        Flashcard(question: "Error", answer: "PDF is empty or could not extract text.")
      ];
    }

    final chat = _model.startChat();
    final prompt = "Generate multiple flashcards covering all key concepts from this text. "
        "Each flashcard should be formatted as follows:\n"
        "Flashcard 1\nFront: [Question]\nBack: [Answer]\n\n"
        "Here is the extracted text:\n$extractedText";

    final response = await chat.sendMessage(Content('user', [TextPart(prompt)]));
    final flashcards = extractFlashcards(response.text ?? "");

    return flashcards.isNotEmpty
        ? flashcards
        : [
            Flashcard(
              question: "Error",
              answer: "No flashcards were generated. Try different content.",
            )
          ];
  }

  /// Extract Flashcards for Image or PDF (Based on AI response)
  List<Flashcard> extractFlashcards(String responseText) {
    final List<Flashcard> flashcards = [];
    final lines = responseText.split('\n').map((line) => line.trim().replaceAll('*', '')).toList();

    String? question;
    String? answer;

    for (var line in lines) {
      if (line.toLowerCase().startsWith('flashcard')) {
        if (question != null && answer != null) {
          flashcards.add(Flashcard(question: question, answer: answer));
        }
        question = null;
        answer = null;
      } else if (line.toLowerCase().startsWith('front:')) {
        question = line.replaceFirst(RegExp(r'front:', caseSensitive: false), '').trim();
      } else if (line.toLowerCase().startsWith('back:')) {
        answer = line.replaceFirst(RegExp(r'back:', caseSensitive: false), '').trim();
      }
    }

    // Add the last flashcard if present
    if (question != null && answer != null) {
      flashcards.add(Flashcard(question: question, answer: answer));
    }

    return flashcards;
  }

  /// General Purpose Analyzer: Check if Flashcard Generation Command
  bool isFlashcardCommand(String command) {
    final lowerCommand = command.toLowerCase();
    return lowerCommand.contains("flashcard") || lowerCommand.contains("generate flashcards");
  }

  /// General Purpose Analyzer: Check if Summary Command
  bool isSummaryCommand(String command) {
    final lowerCommand = command.toLowerCase();
    return lowerCommand.contains("summarize") || lowerCommand.contains("summary");
  }
}
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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

  Future<String> processPDF(File file) async {
    try {
      // Read the PDF file
      List<int> bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text from all pages
      StringBuffer extractedText = StringBuffer();
      for (int i = 0; i < document.pages.count; i++) {
        String pageText =
            PdfTextExtractor(document).extractText(startPageIndex: i);
        extractedText.writeln(pageText.trim());
      }

      document.dispose(); // Free memory

      // Clean extracted text (remove unnecessary asterisks, extra spaces, and blank lines)
      String cleanText = extractedText
          .toString()
          .replaceAll('*', '') // Remove asterisks from extracted text
          .replaceAll(RegExp(r'\n\s*\n'), '\n') // Remove extra blank lines
          .trim();

      // Send cleaned text to Gemini AI for summarization
      String summary = await sendMessage(
          "Summarize this text into important points as flashcards:\n$cleanText");

      // Post-process the AI-generated response to remove asterisks
      String cleanedSummary = summary
          .replaceAll('*', '') // Remove asterisks from AI response
          .replaceAll(RegExp(r'\n\s*\n'), '\n') // Remove excessive blank lines
          .trim(); // Trim leading and trailing spaces

      return cleanedSummary;
    } catch (e) {
      return "Error processing PDF: $e";
    }
  }
}
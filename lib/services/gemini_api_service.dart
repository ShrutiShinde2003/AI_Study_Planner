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

  /// 🔹 Sends a message to Gemini AI and returns the response.
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

  /// 🔹 Processes a PDF file and generates flashcards.
  Future<List<Map<String, String>>> processPDF(File file) async {
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

      // Clean extracted text (remove asterisks, extra spaces, and blank lines)
      String cleanText = extractedText
          .toString()
          .replaceAll('*', '') // Remove asterisks
          .replaceAll(RegExp(r'\n\s*\n'), '\n') // Remove excessive blank lines
          .trim();

      if (cleanText.isEmpty) {
        return [
          {
            "question": "Error",
            "answer": "PDF is empty or text could not be extracted."
          }
        ];
      }

      print(
          "Extracted PDF Text: ${cleanText.substring(0, 500)}..."); // Debugging

      // 🔹 Send extracted text to Gemini AI for flashcard generation
      String responseText = await sendMessage(
        "Generate multiple flashcards covering all key concepts from this text. "
        "Each flashcard should be formatted as follows:\n"
        "Flashcard 1\nFront: [Question]\nBack: [Answer]\n\n"
        "Flashcard 2\nFront: [Question]\nBack: [Answer]\n\n"
        "Here is the extracted text:\n\n$cleanText",
      );

      print("AI Response: ${responseText.substring(0, 500)}..."); // Debugging

      // 🔹 Extract flashcards from AI response
      List<Map<String, String>> flashcards = extractFlashcards(responseText);

      if (flashcards.isEmpty) {
        return [
          {
            "question": "Error",
            "answer": "No flashcards were generated. Try a different PDF."
          }
        ];
      }

      return flashcards;
    } catch (e) {
      return [
        {"question": "Error", "answer": "Failed to process PDF: $e"}
      ];
    }
  }

  /// 🔹 Extracts flashcards from AI response
  List<Map<String, String>> extractFlashcards(String text) {
    List<Map<String, String>> flashcards = [];
    List<String> lines = text.split('\n');

    String? question;
    String? answer;

    for (String line in lines) {
      line = line.replaceAll('*', '').trim(); // Remove unwanted asterisks
      if (line.isEmpty) continue;

      if (line.startsWith("Flashcard")) {
        if (question != null && answer != null) {
          flashcards.add({"question": question, "answer": answer});
        }
        question = null;
        answer = null;
      } else if (line.startsWith("Front:")) {
        question = line.replaceFirst("Front:", "").trim();
      } else if (line.startsWith("Back:")) {
        answer = line.replaceFirst("Back:", "").trim();
      }
    }

    // Add the last flashcard if valid
    if (question != null && answer != null) {
      flashcards.add({"question": question, "answer": answer});
    }

    return flashcards;
  }
}
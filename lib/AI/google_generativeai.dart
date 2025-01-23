import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleGenerativeAI {
  final String apiKey;

  GoogleGenerativeAI({required this.apiKey});

  Future<GenerativeAIResponse?> generate({required String prompt, int maxTokens = 150, required apiKey}) async {
    final url = 'https://generativeai.googleapis.com/v1alpha2/completions:generate';
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'prompt': prompt,
      'maxTokens': maxTokens,
      'temperature': 0.7,
    });

    final response = await http.post(Uri.parse(url), headers: headers, body: body);

    if (response.statusCode == 200) {
      return GenerativeAIResponse.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }
}

class GenerativeAIResponse {
  final List<Candidate> candidates;

  GenerativeAIResponse({required this.candidates});

  factory GenerativeAIResponse.fromJson(Map<String, dynamic> json) {
    return GenerativeAIResponse(
      candidates: (json['candidates'] as List)
          .map((candidate) => Candidate.fromJson(candidate))
          .toList(),
    );
  }
}

class Candidate {
  final String text;

  Candidate({required this.text});

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      text: json['text'],
    );
  }
}

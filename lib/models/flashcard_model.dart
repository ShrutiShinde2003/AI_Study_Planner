class Flashcard {
  final String question;
  final String answer;

  Flashcard({required this.question, required this.answer});

  /// Factory method to create Flashcard from Map (Firebase or other sources)
  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
    );
  }

  /// Convert Flashcard to Map (optional for storage)
  Map<String, String> toMap() {
    return {
      'question': question,
      'answer': answer,
    };
  }
}

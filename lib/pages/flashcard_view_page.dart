import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../pages/interactive_flashcard.dart';

class FlashcardViewPage extends StatelessWidget {
  final List<Flashcard> flashcards;

  const FlashcardViewPage({Key? key, required this.flashcards}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flashcards")),
      body: flashcards.isEmpty
          ? const Center(child: Text("No flashcards generated."))
          : PageView.builder(
              itemCount: flashcards.length,
              controller: PageController(viewportFraction: 0.85),
              itemBuilder: (context, index) {
                return InteractiveFlashcard(
                  flashcard: flashcards[index],
                  onKnown: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as Known!'))),
                  onReview: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked for Review!'))),
                );
              },
            ),
    );
  }
}

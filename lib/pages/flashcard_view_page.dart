import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';
import '../pages/interactive_flashcard.dart'; // ✅ Importing from widgets folder

class FlashcardViewPage extends StatelessWidget {
  final List<Flashcard> flashcards;

  const FlashcardViewPage({Key? key, required this.flashcards}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flashcards")),
      body: flashcards.isEmpty
          ? const Center(child: Text("No flashcards generated."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: flashcards.length,
              itemBuilder: (context, index) {
                return InteractiveFlashcard(
                  flashcard: flashcards[index], // ✅ Flip card only, no swipe/move
                );
              },
            ),
    );
  }
}

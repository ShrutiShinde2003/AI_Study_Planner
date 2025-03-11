import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';

class InteractiveFlashcard extends StatefulWidget {
  final Flashcard flashcard;
  final VoidCallback? onKnown; // Optional callback
  final VoidCallback? onReview; // Optional callback

  const InteractiveFlashcard({
    Key? key,
    required this.flashcard,
    this.onKnown,
    this.onReview,
  }) : super(key: key);

  @override
  State<InteractiveFlashcard> createState() => _InteractiveFlashcardState();
}

class _InteractiveFlashcardState extends State<InteractiveFlashcard> {
  bool _showAnswer = false;

  void _flipCard() {
    setState(() => _showAnswer = !_showAnswer);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.horizontal,
        onDismissed: (direction) {
          if (direction == DismissDirection.startToEnd) {
            widget.onKnown?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Marked as known!")),
            );
          } else {
            widget.onReview?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("🔄 Marked as need to review!")),
            );
          }
        },
        background: _buildSwipeBackground(Colors.green, Icons.check, Alignment.centerLeft),
        secondaryBackground: _buildSwipeBackground(Colors.red, Icons.refresh, Alignment.centerRight),
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            height: 250,
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: _showAnswer
                  ? Text(widget.flashcard.answer, key: const ValueKey('answer'), style: _answerStyle, textAlign: TextAlign.center)
                  : Text(widget.flashcard.question, key: const ValueKey('question'), style: _questionStyle, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(Color color, IconData icon, Alignment alignment) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.all(20),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }

  final _questionStyle = const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black);
  final _answerStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black87);
}

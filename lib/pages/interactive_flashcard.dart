import 'package:flutter/material.dart';
import '../models/flashcard_model.dart';

class InteractiveFlashcard extends StatefulWidget {
  final Flashcard flashcard;
  final VoidCallback? onKnown; // Optional callback when marked as known
  final VoidCallback? onReview; // Optional callback when marked for review

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
        direction: DismissDirection.horizontal, // Swipe left-right
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
        background: _buildSwipeBackground(
          color: Colors.green,
          icon: Icons.check,
          alignment: Alignment.centerLeft,
        ),
        secondaryBackground: _buildSwipeBackground(
          color: Colors.red,
          icon: Icons.refresh,
          alignment: Alignment.centerRight,
        ),
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
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: _buildFlashcardContent(),
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Helper for question/answer content
  Widget _buildFlashcardContent() {
    return _showAnswer
        ? Text(
            widget.flashcard.answer,
            key: const ValueKey('answer'),
            style: _answerStyle,
            textAlign: TextAlign.center,
          )
        : Text(
            widget.flashcard.question,
            key: const ValueKey('question'),
            style: _questionStyle,
            textAlign: TextAlign.center,
          );
  }

  /// ✅ Helper for swipe background
  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.all(20),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }

  /// ✅ Flashcard styling
  final _questionStyle = const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  final _answerStyle = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );
}

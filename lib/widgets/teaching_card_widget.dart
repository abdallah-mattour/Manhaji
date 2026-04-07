import 'package:flutter/material.dart';
import '../models/learning_step.dart';

class TeachingCardWidget extends StatelessWidget {
  final TeachingCardData data;
  final bool isIntro;
  final VoidCallback onNext;

  const TeachingCardWidget({
    super.key,
    required this.data,
    this.isIntro = false,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji header
          Text(data.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: isIntro ? 26 : 22,
              fontWeight: FontWeight.bold,
              color: data.accentColor,
            ),
          ),
          const SizedBox(height: 16),
          // Content card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: data.accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: data.accentColor.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Text(
              data.content,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                height: 1.8,
                color: Color(0xFF2D3436),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Next button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: data.accentColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isIntro ? 'يلا نبدأ! 🚀' : 'التالي ←',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'quiz.dart';

enum LearningStepType { teachingIntro, teachingCard, question }

class TeachingCardData {
  final String title;
  final String content;
  final String emoji;
  final Color accentColor;
  final String? imageUrl;

  const TeachingCardData({
    required this.title,
    required this.content,
    required this.emoji,
    required this.accentColor,
    this.imageUrl,
  });
}

class LearningStep {
  final LearningStepType type;
  final TeachingCardData? teachingData;
  final Question? question;
  final int stepIndex;

  const LearningStep({
    required this.type,
    this.teachingData,
    this.question,
    required this.stepIndex,
  });

  bool get isTeaching =>
      type == LearningStepType.teachingIntro ||
      type == LearningStepType.teachingCard;

  bool get isQuestion => type == LearningStepType.question;
}

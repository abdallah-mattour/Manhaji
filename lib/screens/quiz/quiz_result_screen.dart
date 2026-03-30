import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/quiz_provider.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Consumer<QuizProvider>(
          builder: (context, provider, _) {
            final result = provider.attemptResult;
            if (result == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Result emoji & message
                    _buildResultHeader(result.scorePercent),
                    const SizedBox(height: 24),
                    // Score circle
                    _buildScoreCircle(result.scorePercent),
                    const SizedBox(height: 24),
                    // Stats row
                    _buildStatsRow(result.correctAnswers, result.totalQuestions,
                        result.pointsEarned),
                    const SizedBox(height: 24),
                    // Answer review
                    if (result.answers.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'مراجعة الإجابات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...result.answers.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final answer = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: answer.isCorrect
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: answer.isCorrect
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    answer.isCorrect
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: answer.isCorrect
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'السؤال ${idx + 1}',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                answer.questionText,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const Divider(height: 16),
                              if (answer.studentAnswer != null)
                                Text(
                                  'إجابتك: ${answer.studentAnswer}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    color: answer.isCorrect
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              if (!answer.isCorrect)
                                Text(
                                  'الإجابة الصحيحة: ${answer.correctAnswer}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 24),
                    // Back button
                    ElevatedButton.icon(
                      onPressed: () {
                        // Pop back to lesson screen, then pop again to subject
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        'العودة للدرس',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultHeader(double score) {
    String emoji;
    String message;

    if (score >= 80) {
      emoji = '🏆';
      message = 'ممتاز! أنت نجم!';
    } else if (score >= 50) {
      emoji = '👏';
      message = 'أحسنت! عمل جيد!';
    } else {
      emoji = '💪';
      message = 'لا بأس، حاول مرة أخرى!';
    }

    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCircle(double score) {
    final color = score >= 80
        ? AppTheme.primaryGreen
        : score >= 50
            ? AppTheme.primaryOrange
            : AppTheme.primaryRed;

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${score.toInt()}%',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'النتيجة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int correct, int total, int points) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStat('✅', '$correct/$total', 'إجابات صحيحة'),
        _buildStat('⭐', '$points', 'نقطة'),
        _buildStat(
            '📊',
            total > 0 ? '${(correct * 100 / total).toInt()}%' : '0%',
            'نسبة النجاح'),
      ],
    );
  }

  Widget _buildStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }
}

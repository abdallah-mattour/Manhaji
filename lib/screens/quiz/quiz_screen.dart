import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';
import '../../providers/quiz_provider.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final int lessonId;

  const QuizScreen({super.key, required this.lessonId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  String? _selectedAnswer;
  final _shortAnswerController = TextEditingController();
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().startQuiz(widget.lessonId);
    });
  }

  @override
  void dispose() {
    _shortAnswerController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Consumer<QuizProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.currentQuiz == null) {
              return _buildLoading();
            }
            if (provider.errorMessage != null && provider.currentQuiz == null) {
              return _buildError(provider.errorMessage!);
            }
            if (provider.currentQuiz == null) return const SizedBox();

            return SafeArea(
              child: Column(
                children: [
                  _buildTopBar(provider),
                  _buildProgressBar(provider),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildQuestionCard(provider),
                          const SizedBox(height: 20),
                          _buildAnswerArea(provider),
                          if (provider.lastAnswerResult != null) ...[
                            const SizedBox(height: 16),
                            _buildFeedback(provider),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButtons(provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryOrange),
          const SizedBox(height: 16),
          Text(
            'جاري تحضير الاختبار...',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              color: AppTheme.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Cairo', color: AppTheme.textGray)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('العودة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(QuizProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _showExitDialog(),
            icon: const Icon(Icons.close, color: AppTheme.textGray),
          ),
          Expanded(
            child: Text(
              provider.currentQuiz!.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),
          // Points badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '${provider.totalPointsEarned}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(QuizProvider provider) {
    final total = provider.currentQuiz!.totalQuestions;
    final current = provider.currentQuestionIndex + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السؤال $current من $total',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppTheme.textGray,
                ),
              ),
              Text(
                '${provider.totalCorrect} صحيح',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: current / total,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryOrange),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizProvider provider) {
    final question = provider.currentQuestion!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Question type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getTypeColor(question.type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getTypeLabel(question.type),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getTypeColor(question.type),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question.questionText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerArea(QuizProvider provider) {
    final question = provider.currentQuestion!;
    final isAnswered = provider.hasAnsweredCurrent;

    if (question.isMCQ) {
      return _buildMCQOptions(question, isAnswered, provider);
    } else if (question.isTrueFalse) {
      return _buildTrueFalseOptions(isAnswered, provider);
    } else {
      return _buildShortAnswer(isAnswered, provider);
    }
  }

  Widget _buildMCQOptions(Question question, bool isAnswered, QuizProvider provider) {
    final options = question.options ?? [];
    final result = provider.answeredQuestions[question.id];

    return Column(
      children: options.map((option) {
        final isSelected = _selectedAnswer == option;
        Color bgColor = Colors.white;
        Color borderColor = const Color(0xFFE0E0E0);
        IconData? icon;

        if (isAnswered && result != null) {
          if (option == result.correctAnswer) {
            bgColor = Colors.green.shade50;
            borderColor = Colors.green;
            icon = Icons.check_circle;
          } else if (isSelected && !result.isCorrect) {
            bgColor = Colors.red.shade50;
            borderColor = Colors.red;
            icon = Icons.cancel;
          }
        } else if (isSelected) {
          bgColor = AppTheme.primaryBlue.withValues(alpha: 0.08);
          borderColor = AppTheme.primaryBlue;
        }

        return GestureDetector(
          onTap: isAnswered
              ? null
              : () => setState(() => _selectedAnswer = option),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(icon,
                      color: icon == Icons.check_circle ? Colors.green : Colors.red),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrueFalseOptions(bool isAnswered, QuizProvider provider) {
    final question = provider.currentQuestion!;
    final result = provider.answeredQuestions[question.id];

    return Row(
      children: [
        Expanded(
          child: _buildTFButton('صح', Icons.check_circle_outline,
              Colors.green, isAnswered, result),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTFButton('خطأ', Icons.cancel_outlined,
              Colors.red, isAnswered, result),
        ),
      ],
    );
  }

  Widget _buildTFButton(String value, IconData icon, Color color,
      bool isAnswered, SubmitAnswerResult? result) {
    final isSelected = _selectedAnswer == value;
    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE0E0E0);

    if (isAnswered && result != null) {
      if (value == result.correctAnswer) {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
      } else if (isSelected && !result.isCorrect) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      bgColor = color.withValues(alpha: 0.1);
      borderColor = color;
    }

    return GestureDetector(
      onTap: isAnswered
          ? null
          : () => setState(() => _selectedAnswer = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? color : AppTheme.textLight),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortAnswer(bool isAnswered, QuizProvider provider) {
    return Column(
      children: [
        TextFormField(
          controller: _shortAnswerController,
          enabled: !isAnswered,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 18),
          decoration: InputDecoration(
            hintText: 'اكتب إجابتك هنا...',
            filled: true,
            fillColor: isAnswered ? Colors.grey.shade100 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onChanged: (value) => setState(() => _selectedAnswer = value),
        ),
      ],
    );
  }

  Widget _buildFeedback(QuizProvider provider) {
    final result = provider.lastAnswerResult!;

    return ScaleTransition(
      scale: _feedbackAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: result.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: result.isCorrect ? Colors.green : Colors.red,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              result.isCorrect ? '🎉' : '💡',
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.isCorrect ? 'أحسنت!' : 'حاول مرة أخرى!',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: result.isCorrect
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  if (result.feedback != null)
                    Text(
                      result.feedback!,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: result.isCorrect
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                    ),
                  if (result.isCorrect)
                    Text(
                      '+${result.pointsEarned} نقطة ⭐',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(QuizProvider provider) {
    final isAnswered = provider.hasAnsweredCurrent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: !isAnswered
          ? ElevatedButton(
              onPressed: _selectedAnswer != null && !provider.isLoading
                  ? () => _submitAnswer(provider)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'تأكيد الإجابة',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 18),
                    ),
            )
          : ElevatedButton(
              onPressed: provider.isLoading ? null : () => _next(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    provider.isLastQuestion ? AppTheme.primaryGreen : AppTheme.primaryBlue,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      provider.isLastQuestion ? 'إنهاء الاختبار 🎯' : 'السؤال التالي ←',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 18),
                    ),
            ),
    );
  }

  Future<void> _submitAnswer(QuizProvider provider) async {
    final answer = _selectedAnswer;
    if (answer == null) return;

    await provider.submitAnswer(answer);
    _feedbackController.forward(from: 0);
  }

  Future<void> _next(QuizProvider provider) async {
    if (provider.isLastQuestion) {
      await provider.completeQuiz();
      if (mounted && provider.attemptResult != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const QuizResultScreen(),
          ),
        );
      }
    } else {
      provider.nextQuestion();
      setState(() {
        _selectedAnswer = null;
        _shortAnswerController.clear();
      });
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('الخروج من الاختبار',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          content: const Text('هل تريد الخروج؟ سيتم فقدان تقدمك.',
              style: TextStyle(fontFamily: 'Cairo')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('متابعة',
                  style: TextStyle(fontFamily: 'Cairo', color: AppTheme.primaryGreen)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
              child: const Text('الخروج',
                  style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'MCQ':
        return AppTheme.primaryBlue;
      case 'TRUE_FALSE':
        return AppTheme.primaryPurple;
      case 'SHORT_ANSWER':
        return AppTheme.primaryOrange;
      default:
        return AppTheme.primaryGreen;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'MCQ':
        return 'اختيار من متعدد';
      case 'TRUE_FALSE':
        return 'صح أو خطأ';
      case 'SHORT_ANSWER':
        return 'إجابة قصيرة';
      default:
        return '';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';

/// MCQ question widget — kid-friendly polished version.
///
/// Each option renders as a tactile pill-card with:
///   - A circular lettered bubble (أ/ب/ج/د for Arabic, A/B/C/D for English)
///     so very young readers can pair "the one with ب" with the audio prompt.
///   - 64dp minimum height (well above Material's 48dp recommendation —
///     Grade 1-2 fingers need wider targets).
///   - Staggered fade-in animation on mount so the choices feel alive
///     rather than appearing as a static wall of text.
///   - Tactile press: scale + light haptic.
///   - Smooth color transition between idle / selected / correct / wrong.
///
/// The widget is RTL-aware via `Directionality.of(context)` so the bubble
/// stays on the leading side for both Arabic and English.
class McqWidget extends StatelessWidget {
  final Question question;
  final String? selectedAnswer;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;

  const McqWidget({
    super.key,
    required this.question,
    required this.selectedAnswer,
    required this.isAnswered,
    required this.isCorrect,
    this.correctAnswer,
    required this.onSelect,
  });

  static const _arabicLetters = ['أ', 'ب', 'ج', 'د', 'هـ'];
  static const _englishLetters = ['A', 'B', 'C', 'D', 'E'];

  bool _isArabic(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl;

  String _bubbleLabel(int index, BuildContext context) {
    final list = _isArabic(context) ? _arabicLetters : _englishLetters;
    return index < list.length ? list[index] : '${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final options = question.options ?? const <String>[];

    return Column(
      children: [
        for (int i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.space3),
            child: _McqOption(
              option: options[i],
              bubbleLabel: _bubbleLabel(i, context),
              isSelected: selectedAnswer == options[i],
              isAnswered: isAnswered,
              isCorrect: isCorrect,
              correctAnswer: correctAnswer,
              onSelect: onSelect,
              // Stagger the entrance: each option 60ms after the previous.
              entranceDelay: Duration(milliseconds: 60 * i),
            ),
          ),
      ],
    );
  }
}

class _McqOption extends StatefulWidget {
  final String option;
  final String bubbleLabel;
  final bool isSelected;
  final bool isAnswered;
  final bool isCorrect;
  final String? correctAnswer;
  final ValueChanged<String> onSelect;
  final Duration entranceDelay;

  const _McqOption({
    required this.option,
    required this.bubbleLabel,
    required this.isSelected,
    required this.isAnswered,
    required this.isCorrect,
    required this.correctAnswer,
    required this.onSelect,
    required this.entranceDelay,
  });

  @override
  State<_McqOption> createState() => _McqOptionState();
}

class _McqOptionState extends State<_McqOption>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _entrance;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: AppTheme.motionBase,
    );
    _opacity = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: AppTheme.motionCurve));

    Future.delayed(widget.entranceDelay, () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  _OptionVisual _resolveVisual() {
    if (widget.isAnswered) {
      if (widget.option == widget.correctAnswer) {
        return _OptionVisual(
          bg: AppTheme.successContainer,
          border: AppTheme.success,
          bubbleFill: AppTheme.success,
          bubbleText: Colors.white,
          icon: Icons.check_rounded,
          iconColor: AppTheme.success,
        );
      } else if (widget.isSelected && !widget.isCorrect) {
        return _OptionVisual(
          bg: AppTheme.errorContainer,
          border: AppTheme.error,
          bubbleFill: AppTheme.error,
          bubbleText: Colors.white,
          icon: Icons.close_rounded,
          iconColor: AppTheme.error,
        );
      }
      // Other unselected options after answering — dim them slightly so the
      // correct answer is what the eye lands on.
      return _OptionVisual(
        bg: AppTheme.surfaceMuted,
        border: AppTheme.surfaceSubtle,
        bubbleFill: AppTheme.surfaceSubtle,
        bubbleText: AppTheme.textLight,
        icon: null,
        iconColor: AppTheme.textLight,
      );
    }
    if (widget.isSelected) {
      return _OptionVisual(
        bg: AppTheme.infoContainer,
        border: AppTheme.info,
        bubbleFill: AppTheme.info,
        bubbleText: Colors.white,
        icon: null,
        iconColor: AppTheme.info,
      );
    }
    return _OptionVisual(
      bg: AppTheme.surface,
      border: AppTheme.surfaceSubtle,
      bubbleFill: AppTheme.surfaceMuted,
      bubbleText: AppTheme.textGray,
      icon: null,
      iconColor: AppTheme.textGray,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visual = _resolveVisual();

    final tile = GestureDetector(
      onTapDown:
          widget.isAnswered ? null : (_) => setState(() => _pressed = true),
      onTapCancel:
          widget.isAnswered ? null : () => setState(() => _pressed = false),
      onTapUp:
          widget.isAnswered ? null : (_) => setState(() => _pressed = false),
      onTap: widget.isAnswered
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onSelect(widget.option);
            },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppTheme.motionInstant,
        curve: AppTheme.motionCurve,
        child: AnimatedContainer(
          duration: AppTheme.motionFast,
          curve: AppTheme.motionCurve,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space3,
          ),
          decoration: BoxDecoration(
            color: visual.bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(color: visual.border, width: 2),
            boxShadow: widget.isSelected || widget.isAnswered
                ? AppTheme.elevationLow
                : null,
          ),
          child: Row(
            children: [
              // The lettered bubble — always on the leading edge regardless
              // of Directionality (Row respects textDirection automatically).
              AnimatedContainer(
                duration: AppTheme.motionFast,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: visual.bubbleFill,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.bubbleLabel,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: visual.bubbleText,
                  ),
                ),
              ),
              const AppGap.h4(),
              Expanded(
                child: Text(
                  widget.option,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: widget.isSelected || widget.isAnswered
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
              ),
              // Animated check/cross icon when answered.
              AnimatedSwitcher(
                duration: AppTheme.motionBase,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: anim,
                    curve: AppTheme.motionSpring,
                  ),
                  child: child,
                ),
                child: visual.icon != null
                    ? Icon(visual.icon,
                        key: ValueKey(visual.icon),
                        color: visual.iconColor,
                        size: 26)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: tile),
    );
  }
}

/// Lookup struct for visual state (color combos + icon) so the build
/// method stays declarative.
class _OptionVisual {
  final Color bg;
  final Color border;
  final Color bubbleFill;
  final Color bubbleText;
  final IconData? icon;
  final Color iconColor;

  const _OptionVisual({
    required this.bg,
    required this.border,
    required this.bubbleFill,
    required this.bubbleText,
    required this.icon,
    required this.iconColor,
  });
}

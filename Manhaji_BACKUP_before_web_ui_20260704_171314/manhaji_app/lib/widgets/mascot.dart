import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The 6 poses available for Hakeem the owl, Manhaji's mascot.
///
/// Use one consistently across a screen rather than mixing poses —
/// the mascot reads as a single character, not a stock illustration set.
enum MascotMood {
  /// Default friendly stare. Use on Home / Subject screens.
  idle,

  /// Big smile, blush, wave wing. Use after a correct answer or
  /// at the top of a "completed lesson" toast.
  happy,

  /// Head tilted, wing on chin, thought bubbles. Use during loading
  /// states or when the student requests a hint.
  thinking,

  /// Wings up, sparkles, open mouth. Use on the result screen and
  /// lesson-completion confetti moment.
  celebrating,

  /// Drooped wings, tear, downturned mouth. Use on empty/error states
  /// — "no lessons yet" or "couldn't load your progress".
  sad,

  /// Eyes closed, Z's floating up. Use on splash + skeleton loading.
  sleeping,
}

/// Manhaji's mascot — a friendly blue owl named Hakeem (حكيم — "wise one").
///
/// Renders the matching SVG from `assets/mascots/owl_<mood>.svg` at the
/// requested size. The SVG aspect ratio is 1:1 so `size` controls both
/// dimensions.
///
/// Example:
/// ```dart
/// const Mascot(mood: MascotMood.celebrating, size: 200)
/// ```
class Mascot extends StatelessWidget {
  final MascotMood mood;
  final double size;

  /// Optional semantic label for screen readers. Defaults to a friendly
  /// Arabic description based on mood.
  final String? semanticLabel;

  const Mascot({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 160,
    this.semanticLabel,
  });

  String get _assetPath {
    switch (mood) {
      case MascotMood.idle:
        return 'assets/mascots/owl_idle.svg';
      case MascotMood.happy:
        return 'assets/mascots/owl_happy.svg';
      case MascotMood.thinking:
        return 'assets/mascots/owl_thinking.svg';
      case MascotMood.celebrating:
        return 'assets/mascots/owl_celebrating.svg';
      case MascotMood.sad:
        return 'assets/mascots/owl_sad.svg';
      case MascotMood.sleeping:
        return 'assets/mascots/owl_sleeping.svg';
    }
  }

  String get _defaultLabel {
    switch (mood) {
      case MascotMood.idle:
        return 'البومة حكيم';
      case MascotMood.happy:
        return 'البومة حكيم سعيدة';
      case MascotMood.thinking:
        return 'البومة حكيم تفكر';
      case MascotMood.celebrating:
        return 'البومة حكيم تحتفل';
      case MascotMood.sad:
        return 'البومة حكيم حزينة';
      case MascotMood.sleeping:
        return 'البومة حكيم نائمة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetPath,
      width: size,
      height: size,
      semanticsLabel: semanticLabel ?? _defaultLabel,
    );
  }
}

/// Mascot with a gentle idle animation: a subtle vertical bob (like the
/// character is breathing). Use on splash/home/empty-state hero slots
/// where the mascot should feel alive. Defaults to a 2.6-second cycle so
/// it doesn't distract from page content.
class AnimatedMascot extends StatefulWidget {
  final MascotMood mood;
  final double size;
  final Duration period;
  final String? semanticLabel;

  const AnimatedMascot({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 160,
    this.period = const Duration(milliseconds: 2600),
    this.semanticLabel,
  });

  @override
  State<AnimatedMascot> createState() => _AnimatedMascotState();
}

class _AnimatedMascotState extends State<AnimatedMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.period)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        // Smooth sine-like easing.
        final t = Curves.easeInOut.transform(_ctrl.value);
        // Bob ±4px vertically, very subtle.
        final dy = (t - 0.5) * 8;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Mascot(
        mood: widget.mood,
        size: widget.size,
        semanticLabel: widget.semanticLabel,
      ),
    );
  }
}

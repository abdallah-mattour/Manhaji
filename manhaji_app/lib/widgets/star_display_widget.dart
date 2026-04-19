import 'package:flutter/material.dart';
import '../app/theme.dart';

class StarDisplayWidget extends StatefulWidget {
  final int totalStars;

  const StarDisplayWidget({super.key, required this.totalStars});

  @override
  State<StarDisplayWidget> createState() => _StarDisplayWidgetState();
}

class _StarDisplayWidgetState extends State<StarDisplayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  int _prevStars = 0;

  @override
  void initState() {
    super.initState();
    _prevStars = widget.totalStars;
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.bounceOut,
    ));
  }

  @override
  void didUpdateWidget(covariant StarDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.totalStars > _prevStars) {
      _bounceController.forward(from: 0);
      _prevStars = widget.totalStars;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: Container(
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
              '${widget.totalStars}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

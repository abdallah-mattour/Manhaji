import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';
import '../../utils/text_direction.dart';

/// DRAG_DROP — the student sorts word tokens into named target groups.
///
/// Data comes from `question.pairs`:
///   { "targets": ["Pets", "Wild"], "tokens": ["Lion", "Cat", "Dog", ...] }
///
/// Two ways to place a token (both matter for small fingers / emulators):
///   • drag a chip from the bank onto a group box, or
///   • tap a chip (it highlights) then tap the group box.
/// Tapping a placed chip returns it to the bank.
///
/// [onChanged] receives the full "target=token,target=token" mapping once
/// EVERY token is placed, and null while the sort is incomplete — so the
/// normal "تحقق" button only lights up when the child has finished. Scoring
/// is the same order-independent pair-set compare as IMAGE_MATCH.
class DragDropWidget extends StatefulWidget {
  final Question question;
  final bool isAnswered;
  final ValueChanged<String?> onChanged;

  /// Full English experience (2026-07-03): English-subject lessons show the
  /// instruction chrome in English.
  final bool english;

  const DragDropWidget({
    super.key,
    required this.question,
    required this.isAnswered,
    required this.onChanged,
    this.english = false,
  });

  @override
  State<DragDropWidget> createState() => _DragDropWidgetState();
}

class _DragDropWidgetState extends State<DragDropWidget> {
  /// target label → tokens dropped into it (insertion order preserved).
  late final Map<String, List<String>> _drops;
  late final List<String> _bank;

  /// Tap-to-place: the bank chip currently selected, if any.
  String? _selectedToken;

  static const _targetPalette = [
    AppTheme.primaryBlue,
    AppTheme.primaryGreen,
    AppTheme.primaryPurple,
    AppTheme.primaryOrange,
  ];

  @override
  void initState() {
    super.initState();
    final pairs = widget.question.pairs;
    final targets = (pairs?['targets'] is List)
        ? (pairs!['targets'] as List).map((e) => e.toString()).toList()
        : const <String>[];
    final tokens = (pairs?['tokens'] is List)
        ? (pairs!['tokens'] as List).map((e) => e.toString()).toList()
        : const <String>[];
    _drops = {for (final t in targets) t: <String>[]};
    _bank = List.of(tokens);
  }

  void _place(String token, String target) {
    if (widget.isAnswered) return;
    HapticFeedback.selectionClick();
    setState(() {
      _bank.remove(token);
      // A token may be re-dragged between groups — remove any prior placement.
      for (final list in _drops.values) {
        list.remove(token);
      }
      _drops[target]!.add(token);
      _selectedToken = null;
    });
    _emit();
  }

  void _returnToBank(String token, String fromTarget) {
    if (widget.isAnswered) return;
    HapticFeedback.selectionClick();
    setState(() {
      _drops[fromTarget]!.remove(token);
      _bank.add(token);
    });
    _emit();
  }

  void _emit() {
    if (_bank.isNotEmpty) {
      widget.onChanged(null); // incomplete — keep the check button disabled
      return;
    }
    final parts = <String>[];
    _drops.forEach((target, tokens) {
      for (final t in tokens) {
        parts.add('$target=$t');
      }
    });
    widget.onChanged(parts.join(','));
  }

  @override
  Widget build(BuildContext context) {
    final targets = _drops.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.english
              ? 'Drag each word to the correct group'
              : 'اسحب كل كلمة إلى مجموعتها الصحيحة',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textGray,
          ),
        ),
        const SizedBox(height: 16),

        // Target group boxes.
        for (var i = 0; i < targets.length; i++)
          _buildTarget(targets[i], _targetPalette[i % _targetPalette.length]),

        const SizedBox(height: 8),

        // Token bank.
        if (_bank.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final token in _bank)
                Draggable<String>(
                  data: token,
                  maxSimultaneousDrags: widget.isAnswered ? 0 : 1,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _TokenChip(
                      text: token,
                      color: AppTheme.primaryTerracotta,
                      selected: true,
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: _TokenChip(text: token),
                  ),
                  child: GestureDetector(
                    onTap: widget.isAnswered
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedToken =
                                _selectedToken == token ? null : token);
                          },
                    child: _TokenChip(
                      text: token,
                      selected: _selectedToken == token,
                      color: _selectedToken == token
                          ? AppTheme.primaryTerracotta
                          : null,
                    ),
                  ),
                ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.english
                  ? 'Great! Tap "Check answer" now 👇'
                  : 'رائع! اضغط "تحقق" الآن 👇',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTarget(String target, Color color) {
    final placed = _drops[target] ?? const [];

    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => !widget.isAnswered,
      onAcceptWithDetails: (details) => _place(details.data, target),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        return GestureDetector(
          // Tap-to-place path: a selected bank chip lands here.
          onTap: (_selectedToken != null && !widget.isAnswered)
              ? () => _place(_selectedToken!, target)
              : null,
          child: AnimatedContainer(
            duration: AppTheme.motionFast,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hovering || (_selectedToken != null && !widget.isAnswered)
                  ? color.withValues(alpha: 0.10)
                  : AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(
                color: hovering ? color : color.withValues(alpha: 0.45),
                width: 2.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  target,
                  textAlign: TextAlign.center,
                  textDirection: directionOf(target),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                if (placed.isEmpty)
                  Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: color.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      widget.english ? 'Drop here' : 'ضع هنا',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final token in placed)
                        GestureDetector(
                          onTap: widget.isAnswered
                              ? null
                              : () => _returnToBank(token, target),
                          child: _TokenChip(text: token, color: color),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TokenChip extends StatelessWidget {
  final String text;
  final Color? color;
  final bool selected;

  const _TokenChip({required this.text, this.color, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final border = color ?? AppTheme.surfaceMuted;
    return AnimatedScale(
      duration: AppTheme.motionInstant,
      scale: selected ? 1.08 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color == null
              ? AppTheme.cardWhite
              : color!.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: border, width: 2),
          boxShadow: [
            BoxShadow(
              color: border.withValues(alpha: 0.55),
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          text,
          textDirection: directionOf(text),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color ?? AppTheme.textDark,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';
import '../../utils/text_direction.dart';
import 'option_image.dart';

/// IMAGE_MATCH — two columns of cards. Tap a left card then a right card to
/// pair them (color-coded so the link is obvious). Each completed pairing feeds
/// the parent the running "left=right,left=right" mapping via [onChanged]; the
/// student submits with the normal "تحقق" button. Scoring is order-independent
/// on the backend.
///
/// Data comes from `question.pairs`:
///   { "left":  [ {"id":"a","text":"تفاحة","image":"assets/openmoji/apple.png"} … ],
///     "right": [ {"id":"1","text":"apple"} … ] }
/// Image-ready with fallback: a card shows text when it has no image.
class ImageMatchWidget extends StatefulWidget {
  final Question question;
  final bool isAnswered;
  final ValueChanged<String> onChanged;

  /// Full English experience (2026-07-03).
  final bool english;

  const ImageMatchWidget({
    super.key,
    required this.question,
    required this.isAnswered,
    required this.onChanged,
    this.english = false,
  });

  @override
  State<ImageMatchWidget> createState() => _ImageMatchWidgetState();
}

class _ImageMatchWidgetState extends State<ImageMatchWidget> {
  /// leftId → rightId
  final Map<String, String> _matches = {};
  String? _pendingLeft;

  static const _palette = [
    AppTheme.primaryGreen,
    AppTheme.primaryBlue,
    AppTheme.primaryOrange,
    AppTheme.primaryPurple,
    AppTheme.primaryRed,
    AppTheme.primaryYellow,
  ];

  List<Map<String, dynamic>> get _left =>
      _column('left');
  List<Map<String, dynamic>> get _right =>
      _column('right');

  List<Map<String, dynamic>> _column(String key) {
    final raw = widget.question.pairs?[key];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const [];
  }

  void _tapLeft(String id) {
    if (widget.isAnswered) return;
    if (_matches.containsKey(id)) {
      // tap a matched left to unlink it
      setState(() => _matches.remove(id));
      _emit();
      return;
    }
    setState(() => _pendingLeft = (_pendingLeft == id) ? null : id);
  }

  void _tapRight(String rightId) {
    if (widget.isAnswered) return;
    if (_matches.containsValue(rightId)) return; // already used
    final left = _pendingLeft;
    if (left == null) return;
    setState(() {
      _matches[left] = rightId;
      _pendingLeft = null;
    });
    _emit();
  }

  void _emit() {
    final mapping =
        _matches.entries.map((e) => '${e.key}=${e.value}').join(',');
    widget.onChanged(mapping);
  }

  int? _colorIndexForLeft(String leftId) {
    final keys = _matches.keys.toList();
    final idx = keys.indexOf(leftId);
    return idx >= 0 ? idx : null;
  }

  int? _colorIndexForRight(String rightId) {
    String? leftId;
    _matches.forEach((k, v) {
      if (v == rightId) leftId = k;
    });
    return leftId == null ? null : _colorIndexForLeft(leftId!);
  }

  @override
  Widget build(BuildContext context) {
    final left = _left;
    final right = _right;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.english
              ? 'Match each picture to its pair'
              : 'صِل كل صورة بما يناسبها',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textGray,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final item in left)
                    _MatchCard(
                      item: item,
                      isPending: _pendingLeft == item['id'],
                      isMatched: _matches.containsKey('${item['id']}'),
                      color: () {
                        final idx = _colorIndexForLeft('${item['id']}');
                        return idx == null ? null : _palette[idx % _palette.length];
                      }(),
                      onTap: () => _tapLeft('${item['id']}'),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  for (final item in right)
                    _MatchCard(
                      item: item,
                      isPending: false,
                      isMatched: _matches.containsValue('${item['id']}'),
                      color: () {
                        final idx = _colorIndexForRight('${item['id']}');
                        return idx == null ? null : _palette[idx % _palette.length];
                      }(),
                      onTap: () => _tapRight('${item['id']}'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isPending;
  final bool isMatched;
  final Color? color;
  final VoidCallback onTap;

  const _MatchCard({
    required this.item,
    required this.isPending,
    required this.isMatched,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = item['image']?.toString();
    final text = item['text']?.toString() ?? '';
    final hasImage = image != null && image.trim().isNotEmpty;

    final highlight = color ??
        (isPending ? AppTheme.primaryBlue : AppTheme.surfaceMuted);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: AppTheme.motionInstant,
        scale: isPending ? 1.05 : 1.0,
        child: AnimatedContainer(
          duration: AppTheme.motionFast,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isMatched
                ? highlight.withValues(alpha: 0.12)
                : (isPending
                    ? AppTheme.infoContainer
                    : AppTheme.cardWhite),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(color: highlight, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasImage) ...[
                OptionImage(path: image, size: 64),
                if (text.isNotEmpty) const SizedBox(height: 6),
              ],
              if (text.isNotEmpty)
                Text(
                  text,
                  textAlign: TextAlign.center,
                  textDirection: directionOf(text),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isMatched ? highlight : AppTheme.textDark,
                  ),
                ),
              if (isMatched) ...[
                const SizedBox(height: 4),
                Icon(Icons.link_rounded, color: highlight, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

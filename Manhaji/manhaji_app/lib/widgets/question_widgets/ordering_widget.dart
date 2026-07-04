import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';
import '../../utils/text_direction.dart';

/// ORDERING — the student arranges items into the correct sequence.
///
/// Rebuilt 2026-07-04 WITHOUT ReorderableListView. The drag-based list
/// reparents render objects through an overlay while dragging, which is
/// fragile inside the quiz screen's animated question transitions and
/// produced `child._parent == this` render assertions on device. This
/// implementation uses plain Columns only — nothing is ever reparented:
///   • big ▲ / ▼ arrow buttons move a row one step (primary, unmissable
///     for young kids),
///   • tapping a row selects it (highlight), tapping another row moves the
///     selected row to that position (same pattern as the match widget).
class OrderingWidget extends StatefulWidget {
  final Question question;
  final bool isAnswered;
  final bool isCorrect;
  final ValueChanged<String> onOrderChanged;

  /// Full English experience (2026-07-03).
  final bool english;

  const OrderingWidget({
    super.key,
    required this.question,
    required this.isAnswered,
    required this.isCorrect,
    required this.onOrderChanged,
    this.english = false,
  });

  @override
  State<OrderingWidget> createState() => _OrderingWidgetState();
}

class _OrderingWidgetState extends State<OrderingWidget> {
  late List<String> _items;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.question.options ?? []);
  }

  @override
  void didUpdateWidget(covariant OrderingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _items = List.from(widget.question.options ?? []);
      _selected = null;
    }
  }

  void _emit() => widget.onOrderChanged(_items.join('، '));

  void _moveBy(int index, int delta) {
    final to = index + delta;
    if (to < 0 || to >= _items.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      final item = _items.removeAt(index);
      _items.insert(to, item);
      _selected = null;
    });
    _emit();
  }

  void _tapRow(int index) {
    if (widget.isAnswered) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected == null) {
        _selected = index;
      } else if (_selected == index) {
        _selected = null;
      } else {
        final item = _items.removeAt(_selected!);
        _items.insert(index, item);
        _selected = null;
        _emit();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swap_vert, color: AppTheme.primaryPurple),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.english
                      ? 'Use the arrows to put the items in order'
                      : 'استخدم الأسهم لترتيب العناصر',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppTheme.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!widget.isAnswered)
          Column(
            children: [
              for (var i = 0; i < _items.length; i++) _buildRow(i),
            ],
          )
        else
          Column(
            children: _items.asMap().entries.map((entry) {
              final resultColor = widget.isCorrect
                  ? AppTheme.primaryGreen
                  : AppTheme.primaryRed;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: resultColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: resultColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        textDirection: directionOf(entry.value),
                        style:
                            const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                      ),
                    ),
                    Icon(
                      widget.isCorrect ? Icons.check_circle : Icons.cancel,
                      color: resultColor,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildRow(int index) {
    final isSelected = _selected == index;
    final atTop = index == 0;
    final atBottom = index == _items.length - 1;

    return GestureDetector(
      onTap: () => _tapRow(index),
      child: AnimatedContainer(
        duration: AppTheme.motionFast,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.infoContainer : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : AppTheme.primaryPurple.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
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
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _items[index],
                // English ordering tokens (words/sentence fragments) flow
                // LTR; Arabic tokens stay RTL.
                textDirection: directionOf(_items[index]),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            // Chunky move buttons — 40px targets, greyed at the edges.
            IconButton(
              onPressed: atTop || widget.isAnswered
                  ? null
                  : () => _moveBy(index, -1),
              icon: const Icon(Icons.arrow_upward_rounded),
              color: AppTheme.primaryPurple,
              disabledColor: AppTheme.textLight.withValues(alpha: 0.4),
              iconSize: 24,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: atBottom || widget.isAnswered
                  ? null
                  : () => _moveBy(index, 1),
              icon: const Icon(Icons.arrow_downward_rounded),
              color: AppTheme.primaryPurple,
              disabledColor: AppTheme.textLight.withValues(alpha: 0.4),
              iconSize: 24,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

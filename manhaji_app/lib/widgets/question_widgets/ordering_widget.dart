import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../models/quiz.dart';

class OrderingWidget extends StatefulWidget {
  final Question question;
  final bool isAnswered;
  final bool isCorrect;
  final ValueChanged<String> onOrderChanged;

  const OrderingWidget({
    super.key,
    required this.question,
    required this.isAnswered,
    required this.isCorrect,
    required this.onOrderChanged,
  });

  @override
  State<OrderingWidget> createState() => _OrderingWidgetState();
}

class _OrderingWidgetState extends State<OrderingWidget> {
  late List<String> _items;

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
    }
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
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_vert, color: AppTheme.primaryPurple),
              SizedBox(width: 8),
              Text(
                'اسحب العناصر لترتيبها',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppTheme.primaryPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (!widget.isAnswered)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.selectionClick();
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _items.removeAt(oldIndex);
                _items.insert(newIndex, item);
                widget.onOrderChanged(_items.join('، '));
              });
            },
            itemBuilder: (context, index) {
              return Container(
                key: ValueKey('$index-${_items[index]}'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.3)),
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
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    const Icon(Icons.drag_handle, color: AppTheme.textLight),
                  ],
                ),
              );
            },
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
}

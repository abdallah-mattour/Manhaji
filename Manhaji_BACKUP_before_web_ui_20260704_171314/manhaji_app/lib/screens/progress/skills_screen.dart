import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/skill_mastery.dart';
import '../../services/quiz_service.dart';
import '../../utils/error_handler.dart';
import '../../widgets/vibrant_background.dart';

/// "مهاراتي / My Skills" — visualizes the Bayesian Knowledge Tracing model:
/// per-sub-skill mastery for one subject. Rendered as labelled horizontal
/// bars (clearer than a radar for young children + Arabic labels, and never
/// degenerate with <3 axes).
///
/// This is the visible proof that the knowledge-tracing engine works: as the
/// child answers questions, these bars move.
class SkillsScreen extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final Color subjectColor;

  const SkillsScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.subjectColor = AppTheme.primaryGreen,
  });

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  SkillMastery? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context
          .read<QuizApiService>()
          .getSkillMastery(widget.subjectId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = extractError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مهاراتي',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900)),
          backgroundColor: widget.subjectColor,
          foregroundColor: Colors.white,
        ),
        body: VibrantBackground(
          child: SafeArea(
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: widget.subjectColor),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('حاول مرة أخرى',
                    style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
        ),
      );
    }

    final skills = _data?.skills ?? [];
    if (skills.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'لا توجد مهارات لعرضها بعد. ابدأ بحلّ بعض الأسئلة!',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.subjectName,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'كلّما تدرّبت أكثر، ارتفعت مهاراتك!',
          style: TextStyle(
              fontFamily: 'Cairo', fontSize: 14, color: AppTheme.textGray),
        ),
        const SizedBox(height: 20),
        ...skills.map(_buildSkillBar),
      ],
    );
  }

  Widget _buildSkillBar(SkillScore skill) {
    final pct = skill.percent;
    final barColor = _masteryColor(skill.pMastery);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  skill.arabicLabel,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              if (skill.mastered)
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: 6),
                  child: Text('🏆', style: TextStyle(fontSize: 16)),
                ),
              Text(
                '$pct٪',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: skill.pMastery.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 14,
                backgroundColor: AppTheme.surfaceMuted,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ),
          if (skill.observationCount == 0) ...[
            const SizedBox(height: 4),
            const Text(
              'لم تتدرّب على هذه المهارة بعد',
              style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 12, color: AppTheme.textLight),
            ),
          ],
        ],
      ),
    );
  }

  /// Red → orange → blue → green as mastery climbs (mirrors the
  /// pronunciation score-card colour scale the kids already see).
  Color _masteryColor(double p) {
    if (p >= 0.90) return AppTheme.primaryGreen;
    if (p >= 0.70) return AppTheme.primaryBlue;
    if (p >= 0.45) return AppTheme.primaryOrange;
    return AppTheme.primaryRed;
  }
}

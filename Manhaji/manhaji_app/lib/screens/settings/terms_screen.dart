import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/vibrant_background.dart';
import 'legal_section.dart';

/// In-app Arabic terms of use, parent-readable. Covers guardian acceptance,
/// account responsibility, acceptable use, and an AI-feedback disclaimer.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('شروط الاستخدام'),
          backgroundColor: AppTheme.backgroundLight,
          foregroundColor: AppTheme.textDark,
          elevation: 0,
        ),
        body: VibrantBackground(
          backgroundColor: AppTheme.backgroundLight,
          pattern: BackgroundPattern.none,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: const [
                LegalIntro(
                  text:
                      'باستخدامك تطبيق «منهجي» فإنك توافق على الشروط التالية. '
                      'صُمّم التطبيق لمساعدة طلاب المرحلة الابتدائية على التعلّم '
                      'بطريقة ممتعة وآمنة.',
                ),
                LegalSection(
                  emoji: '👨‍👩‍👧',
                  title: 'موافقة وليّ الأمر',
                  body:
                      'التطبيق مخصّص للأطفال، ويُستخدم بإشراف وليّ الأمر '
                      'وموافقته. بإنشاء الحساب يُقرّ وليّ الأمر بموافقته على هذه '
                      'الشروط وعلى سياسة الخصوصية.',
                ),
                LegalSection(
                  emoji: '🔑',
                  title: 'مسؤولية الحساب',
                  body:
                      'أنت مسؤول عن الحفاظ على سرّية كلمة المرور وعن النشاط الذي '
                      'يتم عبر حسابك. يُرجى إبلاغ إدارة المدرسة عند أي استخدام '
                      'غير مصرّح به.',
                ),
                LegalSection(
                  emoji: '✅',
                  title: 'الاستخدام المقبول',
                  body:
                      'يُستخدم التطبيق للأغراض التعليمية فقط. يُمنع إساءة '
                      'استخدامه أو محاولة الإضرار بالخدمة أو الوصول إلى بيانات '
                      'مستخدمين آخرين.',
                ),
                LegalSection(
                  emoji: '🤖',
                  title: 'حول التقييم الذكي',
                  body:
                      'يستعين التطبيق بالذكاء الاصطناعي لتقييم النطق وإنشاء '
                      'تقارير ونصائح تعليمية. هذه النتائج مساعِدة وتقريبية وقد لا '
                      'تكون دقيقة دائماً، ولا تُغني عن متابعة المعلّم وولي الأمر.',
                ),
                LegalSection(
                  emoji: '🔄',
                  title: 'تعديل الشروط',
                  body:
                      'قد نُحدّث هذه الشروط لتحسين الخدمة. استمرارك في استخدام '
                      'التطبيق بعد التحديث يعني موافقتك على النسخة المُحدّثة.',
                ),
                SizedBox(height: 8),
                LegalFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

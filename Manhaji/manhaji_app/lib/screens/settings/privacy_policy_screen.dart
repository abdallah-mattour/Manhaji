import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/vibrant_background.dart';
import 'legal_section.dart';

/// In-app Arabic privacy policy, written for a parent/guardian to read. Content
/// is kept honest to the app's *verified* behaviour: voice recordings are sent
/// to Google Gemini for scoring and are NOT stored; passwords are hashed; tokens
/// live in device secure storage; no ads, no third-party analytics, no sale of
/// data. Reachable from About and, pre-auth, from the register consent links.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // Placeholder support contact — replace with the real school/admin address
  // before the graduation showcase.
  static const String _contactEmail = 'privacy@manhaji.app';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سياسة الخصوصية'),
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
                      'خصوصية أطفالنا أولوية. تشرح هذه السياسة، بلغة واضحة لوليّ '
                      'الأمر، البياناتِ التي يجمعها تطبيق «منهجي» وكيف نستخدمها '
                      'ونحميها.',
                ),
                LegalSection(
                  emoji: '📋',
                  title: 'المعلومات التي نجمعها',
                  body:
                      'عند إنشاء الحساب نجمع: اسم الطالب، والبريد الإلكتروني أو '
                      'رقم الهاتف، والصف الدراسي. أثناء الاستخدام نسجّل تقدّم '
                      'الطالب في الدروس والاختبارات (النقاط، النجوم، الإجابات) '
                      'لعرض التقدّم وتخصيص التعلّم.',
                ),
                LegalSection(
                  emoji: '🎤',
                  title: 'التسجيلات الصوتية',
                  body:
                      'في تمارين النطق يُرسَل التسجيل الصوتي إلى خدمة الذكاء '
                      'الاصطناعي من Google لتقييم النطق فقط، ثم يُحذف مباشرةً. '
                      'نحن لا نخزّن تسجيلات صوت الأطفال على خوادمنا.',
                ),
                LegalSection(
                  emoji: '🔒',
                  title: 'كيف نحمي البيانات',
                  body:
                      'تُحفظ كلمات المرور مشفّرة (hashed) ولا يمكن لأحد قراءتها. '
                      'تُخزَّن رموز الدخول في المخزن الآمن للجهاز '
                      '(Android Keystore / iOS Keychain). ويتم الاتصال بالخادم '
                      'عبر اتصال آمن.',
                ),
                LegalSection(
                  emoji: '🚫',
                  title: 'ما لا نفعله',
                  body:
                      'لا نعرض إعلانات، ولا نستخدم أدوات تتبّع أو تحليلات من '
                      'أطراف ثالثة، ولا نبيع بيانات الطلاب أو نشاركها لأغراض '
                      'تجارية. تُستخدم البيانات داخل التطبيق التعليمي فقط.',
                ),
                LegalSection(
                  emoji: '🤝',
                  title: 'مشاركة البيانات',
                  body:
                      'قد يطّلع المعلّم وولي الأمر المرتبطان بالطالب على تقدّمه '
                      'التعليمي لدعم تعلّمه. ولإتاحة تقييم النطق والتقارير الذكية '
                      'نستعين بخدمات Google للذكاء الاصطناعي وفق سياسات '
                      'خصوصيتها.',
                ),
                LegalSection(
                  emoji: '👨‍👩‍👧',
                  title: 'موافقة وليّ الأمر وحقوقه',
                  body:
                      'يُنشأ حساب الطالب بموافقة وليّ الأمر. ولوليّ الأمر الحق في '
                      'طلب مراجعة بيانات الطالب أو تصحيحها أو حذفها عبر التواصل '
                      'مع إدارة المدرسة أو مشرف التطبيق.',
                ),
                LegalSection(
                  emoji: '✉️',
                  title: 'تواصل معنا',
                  body:
                      'لأي سؤال حول الخصوصية، تواصل مع مشرف التطبيق أو إدارة '
                      'المدرسة على البريد: $_contactEmail',
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

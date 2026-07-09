import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhaji_app/app/theme.dart';
import 'package:manhaji_app/widgets/staff_metric_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: SizedBox(width: 320, child: child)),
        ),
      ),
    );
  }

  testWidgets('StaffMetricCard renders metric content', (tester) async {
    await tester.pumpWidget(
      wrap(
        const StaffMetricCard(
          title: 'إجمالي الطلاب',
          value: '10',
          subtitle: 'افتح قائمة الطلاب',
          icon: Icons.people_alt_rounded,
          color: AppTheme.primaryBlue,
        ),
      ),
    );

    expect(find.text('إجمالي الطلاب'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('افتح قائمة الطلاب'), findsOneWidget);
    expect(find.byIcon(Icons.people_alt_rounded), findsOneWidget);
  });

  testWidgets('StaffMetricCard handles tap when enabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        StaffMetricCard(
          title: 'النشطون هذا الأسبوع',
          value: '8',
          icon: Icons.trending_up_rounded,
          color: AppTheme.primaryGreen,
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('النشطون هذا الأسبوع'));
    await tester.pump();

    expect(taps, 1);
  });
}

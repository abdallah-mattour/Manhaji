import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

/// Lets the user point the app at a different backend origin (e.g. the laptop's
/// IP on a new network) WITHOUT rebuilding. The value is persisted in
/// SharedPreferences and applied to the live Dio client immediately, so the
/// very next request uses it. Reached from the gear on the login screen.
Future<void> showServerSettingsDialog(BuildContext context) async {
  final storage = context.read<LocalStorageService>();
  final api = context.read<ApiService>();
  final controller = TextEditingController(text: ApiConfig.currentOrigin);

  await showDialog<void>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text(
          'عنوان الخادم',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اكتب عنوان جهاز الخادم. غيّره عند تغيّر الشبكة (البيت / الجامعة / '
              'نقطة الاتصال) — بدون إعادة بناء التطبيق.',
              style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 13, color: AppTheme.textGray),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              textDirection: TextDirection.ltr,
              autocorrect: false,
              keyboardType: TextInputType.url,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.104:8080',
                hintStyle: TextStyle(fontFamily: 'monospace'),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اكتب IP الجهاز فقط ويُكمَل الباقي تلقائياً (مثال: 192.168.1.104).',
              style: TextStyle(
                  fontFamily: 'Cairo', fontSize: 11, color: AppTheme.textLight),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء',
                style: TextStyle(fontFamily: 'Cairo', color: AppTheme.textGray)),
          ),
          TextButton(
            onPressed: () async {
              final origin = ApiConfig.normalizeOrigin(controller.text);
              ApiConfig.runtimeOrigin = origin;
              await storage.setServerBaseUrl(origin);
              api.updateBaseUrl(ApiConfig.baseUrl);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      origin == null
                          ? 'تمت إعادة العنوان إلى الوضع الافتراضي'
                          : 'تم ضبط الخادم على: $origin',
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            child: const Text('حفظ',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryGreen)),
          ),
        ],
      ),
    ),
  );
}

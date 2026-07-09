import 'package:flutter/material.dart';

/// Thin top-of-screen strip that appears ONLY in screenshot preview mode.
/// Never rendered in normal builds — screens that host it only do so inside
/// an `if (kScreenshotMode)` guard in routes.dart.
class PreviewBanner extends StatelessWidget {
  const PreviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 5),
      color: const Color(0xFF1CB0F6),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
          SizedBox(width: 6),
          Text(
            'وضع المعاينة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

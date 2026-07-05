/// Helpers for displaying numbers in Arabic-Indic form (٠١٢٣٤٥٦٧٨٩) inside
/// an otherwise-Arabic UI.
///
/// Grade 1 students are learning Arabic numerals as a primary skill. Mixing
/// Western digits (0123) into Arabic prompts is jarring and breaks the
/// pedagogical context. Use these helpers on any numeric value that appears
/// inside an Arabic-language Text widget.
///
/// Audit-3 fix (2026-05-15): introduced after the Flutter UI scan flagged
/// score / star displays as mixing scripts.
library;

const _arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Convert ASCII digits (0-9) inside a string to Arabic-Indic digits.
/// Non-digit characters pass through unchanged.
///
/// Example: `toArabicDigits('89 / 100')` → `'٨٩ / ١٠٠'`.
String toArabicDigits(String input) {
  final buf = StringBuffer();
  for (final code in input.codeUnits) {
    if (code >= 0x30 && code <= 0x39) {
      buf.write(_arabicIndic[code - 0x30]);
    } else {
      buf.writeCharCode(code);
    }
  }
  return buf.toString();
}

/// Convenience wrapper for an integer.
String arabicInt(int value) => toArabicDigits(value.toString());

import 'package:flutter/widgets.dart';

/// Picks a [TextDirection] for a piece of content based on its first strong
/// directional character (the Unicode bidi P2/P3 rule).
///
/// ### Why this exists
///
/// The whole app runs under an ambient `Directionality.rtl` (it's Arabic-first).
/// A `Text` widget with no explicit `textDirection` inherits that RTL, which is
/// correct for Arabic but WRONG for English: the paragraph lays out
/// right-to-left, so trailing punctuation jumps to the left edge —
/// "What's your name?" renders as "?What's your name". Setting the direction
/// per-string from its own content fixes this without flipping the surrounding
/// RTL layout (chips, icons, alignment all stay RTL).
///
/// First-strong (rather than "contains any Arabic") is deliberate: a mixed
/// string like "Translate: تفاحة" should flow in the direction of how it
/// *starts*, matching how a reader scans it.
TextDirection directionOf(String? text, {TextDirection fallback = TextDirection.rtl}) {
  if (text == null || text.isEmpty) return fallback;
  for (final rune in text.runes) {
    if (_isStrongRtl(rune)) return TextDirection.rtl;
    if (_isStrongLtr(rune)) return TextDirection.ltr;
    // Neutral (digits, punctuation, whitespace, symbols) → keep scanning.
  }
  return fallback;
}

/// Arabic, Hebrew, and their supplements/presentation forms.
bool _isStrongRtl(int c) {
  return (c >= 0x0590 && c <= 0x05FF) || // Hebrew
      (c >= 0x0600 && c <= 0x06FF) ||    // Arabic
      (c >= 0x0750 && c <= 0x077F) ||    // Arabic Supplement
      (c >= 0x08A0 && c <= 0x08FF) ||    // Arabic Extended-A
      (c >= 0xFB1D && c <= 0xFDFF) ||    // Hebrew + Arabic Presentation Forms-A
      (c >= 0xFE70 && c <= 0xFEFF);      // Arabic Presentation Forms-B
}

/// Basic + extended Latin letters (covers all English question/answer text).
bool _isStrongLtr(int c) {
  return (c >= 0x0041 && c <= 0x005A) || // A-Z
      (c >= 0x0061 && c <= 0x007A) ||    // a-z
      (c >= 0x00C0 && c <= 0x024F);      // Latin-1 supplement + extended
}

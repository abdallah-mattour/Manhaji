package com.springboot.manhaji.service.ai;

import java.util.List;

/**
 * Structured output from {@link WhisperService#transcribeWithPhonemes}.
 *
 * <p>Feature B (2026-04-29 audit response): the legacy {@code transcribe()}
 * method returned just a flat string. For pronunciation coaching to be
 * pedagogically useful — especially for Grade 1 Arabic where letters like
 * ع، خ، غ، ر have specific failure modes — we ask Gemini to additionally
 * identify which phonemes the child got wrong and emit a short child-friendly
 * coaching sentence.
 *
 * <p>All fields are nullable / may be empty. Callers should defensively handle
 * the case where Gemini returns plain text instead of JSON (the {@code transcribed}
 * field is then the full response and the other two are empty/null) — see
 * {@link WhisperService#transcribeWithPhonemes} for fallback details.
 *
 * @param transcribed   what the audio sounded like (the child's actual utterance,
 *                       may differ from the expected word). Never null.
 * @param phonemeErrors a list of phonemes / letters the child mispronounced.
 *                       Example: {@code ["ر", "ع"]} when the child said "لمان" instead
 *                       of "رمان". Empty list when nothing's wrong or AI couldn't tell.
 * @param guidance      one short Arabic sentence the UI can show as a hint, e.g.
 *                       "ركّز على صوت الراء من الحلق". May be null/blank.
 */
public record PhonemeAnalysis(
        String transcribed,
        List<String> phonemeErrors,
        String guidance
) {
    public static PhonemeAnalysis empty() {
        return new PhonemeAnalysis("", List.of(), null);
    }

    public static PhonemeAnalysis transcribedOnly(String text) {
        return new PhonemeAnalysis(text == null ? "" : text, List.of(), null);
    }
}

"""
One-shot backfill of Grade 1 Arabic letter lessons in ar1_p1.json:

1. Rewrite the templated FILL_BLANK ("أكمل: ___ هو الحرف الذي نتعلمه في هذا الدرس")
   into a lesson-specific stem ("أكمل: في كلمة (X) يأتي حرف ___ في البداية").
   Resolves the cross-lesson R10 violations of this template.

2. Add an ORDERING (difficulty 3, sub-skill `application`) word-formation question
   to each letter lesson. Resolves R9 (no diff-3 question per lesson) for these
   lessons.

3. Add explicit `subSkill` tags to all questions, derived from type (and Arabic-
   subject default mapping per spec §6).

Idempotent: if the lesson already has a non-template FILL_BLANK or an ORDERING,
that lesson is skipped — re-runs are safe.

Usage:
    python Manhaji/scripts/curriculum/_backfill_ar1_p1.py

Resolves the curriculum dir relative to its own location. Modifies
backend/src/main/resources/curriculum/ar1_p1.json in place.
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
# Scripts live in Manhaji/scripts/curriculum/; JSON lives in
# Manhaji/backend/src/main/resources/curriculum/.
CURRICULUM = (HERE.parent.parent
              / "backend" / "src" / "main" / "resources" / "curriculum")
TARGET = CURRICULUM / "ar1_p1.json"

# Per-letter mapping: lesson title -> (display word, letter-list-in-order,
# fill-blank-answer-with-ال). The word is one used in the lesson's existing
# `content` field, so it stays consistent with the rest of the lesson.
# The letter-list is the word's letters in correct order (used both for the
# ORDERING correctAnswer and to derive a shuffled options list).
LETTER_LESSONS = {
    # حرف الراء already shipped in the manual gold-standard pass; skipping.
    "حرف الدال":  ("دار",   ["د", "ا", "ر"],         "الدال"),
    "حرف الباء":  ("بيت",   ["ب", "ي", "ت"],         "الباء"),
    "حرف الميم":  ("موز",   ["م", "و", "ز"],         "الميم"),
    "حرف النون":  ("نمر",   ["ن", "م", "ر"],         "النون"),
    "حرف السين":  ("سمكة",  ["س", "م", "ك", "ة"],   "السين"),
    "حرف الزاي":  ("زيت",   ["ز", "ي", "ت"],         "الزاي"),
    "حرف الحاء":  ("حصان",  ["ح", "ص", "ا", "ن"],   "الحاء"),
    "حرف اللام":  ("لون",   ["ل", "و", "ن"],         "اللام"),
    "حرف التاء":  ("تاج",   ["ت", "ا", "ج"],         "التاء"),
    "حرف الجيم":  ("جمل",   ["ج", "م", "ل"],         "الجيم"),
    "حرف الفاء":  ("فيل",   ["ف", "ي", "ل"],         "الفاء"),
    "حرف العين":  ("علم",   ["ع", "ل", "م"],         "العين"),
    "حرف الشين":  ("شمس",   ["ش", "م", "س"],         "الشين"),
    "حرف الصاد":  ("صقر",   ["ص", "ق", "ر"],         "الصاد"),
    "حرف القاف":  ("قمر",   ["ق", "م", "ر"],         "القاف"),
    "حرف الثاء":  ("ثلج",   ["ث", "ل", "ج"],         "الثاء"),
    "حرف الخاء":  ("خبز",   ["خ", "ب", "ز"],         "الخاء"),
}

# Default sub-skill mapping for the Arabic subject (per spec §6). MCQ/T-F default
# to recognition; Religion would use comprehension instead, but this script only
# touches Arabic, so recognition is correct.
DEFAULT_SUB_SKILL = {
    "MCQ":            "recognition",
    "TRUE_FALSE":     "comprehension",
    "SHORT_ANSWER":   "production",
    "FILL_BLANK":     "production",
    "ORDERING":       "application",
    "PRONUNCIATION":  "pronunciation",
    "TRACING":        "handwriting",
}

OLD_FILL_TEXT = "أكمل: ___ هو الحرف الذي نتعلمه في هذا الدرس"


def _shuffled(letters):
    """Return a stable, deterministic 'shuffle' that always differs from input.

    For each letter list of length N, rotate by `floor(N/2)`. Pure functional —
    re-running the script produces the same JSON every time, which makes the
    git diff easy to review. Real shuffling is not needed because the widget
    presents the options to the student in a different render order anyway.
    """
    n = len(letters)
    if n < 2:
        return list(letters)
    k = n // 2
    return list(letters[k:]) + list(letters[:k])


def _ordering_question(word, letters):
    return {
        "type": "ORDERING",
        "questionText": f"رتّب الحروف لتكوين كلمة ({word})",
        # Arabic comma + space to match the existing convention in ma1_p1.json;
        # the audit's R5 regex `[،,]\s*` accepts both with or without space.
        "correctAnswer": "، ".join(letters),
        "options": _shuffled(letters),
        "difficultyLevel": 3,
        "subSkill": "application",
    }


def _ensure_sub_skill(question):
    """Add a `subSkill` field if missing, derived from `type`."""
    if "subSkill" not in question or not question.get("subSkill"):
        t = question.get("type")
        if t in DEFAULT_SUB_SKILL:
            question["subSkill"] = DEFAULT_SUB_SKILL[t]


def _rewrite_fill_blank(question, word, fill_answer):
    """Mutate a templated FILL_BLANK into a lesson-specific one."""
    question["questionText"] = f"أكمل: في كلمة ({word}) يأتي حرف ___ في البداية"
    question["correctAnswer"] = fill_answer


def _process_lesson(lesson, report):
    title = lesson.get("title", "")
    if title not in LETTER_LESSONS:
        return  # Not a letter lesson we're backfilling (review, thematic, etc.)
    word, letters, fill_answer = LETTER_LESSONS[title]

    questions = lesson.get("questions", [])
    has_ordering = any(q.get("type") == "ORDERING" for q in questions)
    rewrote_fill = False

    for q in questions:
        _ensure_sub_skill(q)
        if (q.get("type") == "FILL_BLANK"
                and q.get("questionText") == OLD_FILL_TEXT):
            _rewrite_fill_blank(q, word, fill_answer)
            rewrote_fill = True

    if not has_ordering:
        # Insert before any TRACING block to keep ordering consistent across
        # lessons (handwriting items always last). Find the first TRACING
        # index; if there is none, append.
        first_tracing = next(
            (i for i, q in enumerate(questions) if q.get("type") == "TRACING"),
            len(questions),
        )
        questions.insert(first_tracing, _ordering_question(word, letters))

    report.append({
        "title": title,
        "fill_rewritten": rewrote_fill,
        "ordering_added": not has_ordering,
        "total_questions": len(questions),
    })


def main():
    if not TARGET.exists():
        print(f"ERROR: {TARGET} not found", file=sys.stderr)
        sys.exit(1)

    with TARGET.open("r", encoding="utf-8") as f:
        data = json.load(f)

    report = []
    for lesson in data.get("lessons", []):
        _process_lesson(lesson, report)

    # Also walk every lesson and ensure subSkill on every question, even non-
    # letter lessons (review, thematic), so the per-question shape is uniform.
    for lesson in data.get("lessons", []):
        for q in lesson.get("questions", []):
            _ensure_sub_skill(q)

    with TARGET.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")  # match the existing trailing newline

    # Print a tidy report.
    print(f"Processed {len(report)} letter lessons in {TARGET.name}:")
    for r in report:
        print(f"  - {r['title']:20s}  fill={r['fill_rewritten']}  "
              f"ordering={r['ordering_added']}  total={r['total_questions']}")


if __name__ == "__main__":
    main()

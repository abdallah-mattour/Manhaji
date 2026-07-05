"""
Same backfill as _backfill_ar1_p1.py but for ar1_p2.json (the second-half
Arabic letter lessons + thematic lessons).

For thematic lessons (نساعد الكبير, وطني أجمل, الماء), we DO add a sub-skill
to every existing question but skip the ORDERING/FILL_BLANK rewrites — those
are letter-lesson-specific.
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
CURRICULUM = (HERE.parent.parent.parent
              / "backend" / "src" / "main" / "resources" / "curriculum")
TARGET = CURRICULUM / "ar1_p2.json"

# Per-letter mapping: lesson title -> (display word, letter list, fill-blank answer).
LETTER_LESSONS = {
    "حرف الذال":             ("ذرة",   ["ذ", "ر", "ة"],         "الذال"),
    "حرف الغين":             ("غزال",  ["غ", "ز", "ا", "ل"],   "الغين"),
    "حرف الطاء":             ("طبل",   ["ط", "ب", "ل"],         "الطاء"),
    "حرف الكاف":             ("كتاب",  ["ك", "ت", "ا", "ب"],   "الكاف"),
    "حرف الضاد":             ("ضفدع",  ["ض", "ف", "د", "ع"],   "الضاد"),
    "حرف الهاء":             ("هاتف",  ["ه", "ا", "ت", "ف"],   "الهاء"),
    "حرف الواو":             ("ولد",   ["و", "ل", "د"],         "الواو"),
    "حرف الهمزة (الألف)":    ("أسد",   ["أ", "س", "د"],         "الهمزة"),
    "حرف الظاء":             ("ظرف",   ["ظ", "ر", "ف"],         "الظاء"),
    "حرف الياء":             ("يوم",   ["ي", "و", "م"],         "الياء"),
}

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
    n = len(letters)
    if n < 2:
        return list(letters)
    k = n // 2
    return list(letters[k:]) + list(letters[:k])


def _ordering_question(word, letters):
    return {
        "type": "ORDERING",
        "questionText": f"رتّب الحروف لتكوين كلمة ({word})",
        "correctAnswer": "، ".join(letters),
        "options": _shuffled(letters),
        "difficultyLevel": 3,
        "subSkill": "application",
    }


def _ensure_sub_skill(question):
    if "subSkill" not in question or not question.get("subSkill"):
        t = question.get("type")
        if t in DEFAULT_SUB_SKILL:
            question["subSkill"] = DEFAULT_SUB_SKILL[t]


def _rewrite_fill_blank(question, word, fill_answer):
    question["questionText"] = f"أكمل: في كلمة ({word}) يأتي حرف ___ في البداية"
    question["correctAnswer"] = fill_answer


def _process_lesson(lesson):
    title = lesson.get("title", "")
    questions = lesson.get("questions", [])
    # Always add subSkill tags everywhere (idempotent).
    for q in questions:
        _ensure_sub_skill(q)

    if title not in LETTER_LESSONS:
        return  # Thematic / review — only sub-skill backfill above applies.

    word, letters, fill_answer = LETTER_LESSONS[title]
    has_ordering = any(q.get("type") == "ORDERING" for q in questions)
    for q in questions:
        if (q.get("type") == "FILL_BLANK"
                and q.get("questionText") == OLD_FILL_TEXT):
            _rewrite_fill_blank(q, word, fill_answer)
    if not has_ordering:
        first_tracing = next(
            (i for i, q in enumerate(questions) if q.get("type") == "TRACING"),
            len(questions),
        )
        questions.insert(first_tracing, _ordering_question(word, letters))


def main():
    if not TARGET.exists():
        print(f"ERROR: {TARGET} not found", file=sys.stderr)
        sys.exit(1)

    with TARGET.open("r", encoding="utf-8") as f:
        data = json.load(f)

    for lesson in data.get("lessons", []):
        _process_lesson(lesson)

    with TARGET.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    total = sum(len(l.get("questions", [])) for l in data.get("lessons", []))
    print(f"OK: {len(data.get('lessons', []))} lessons, {total} total questions")


if __name__ == "__main__":
    main()

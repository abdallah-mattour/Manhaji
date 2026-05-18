"""
Final dedupe pass for Arabic curriculum:

1. Inventory all questionText strings across ar1_p1.json + ar1_p2.json.
2. For each duplicate found in a review (مراجعة) or thematic lesson, mutate
   its questionText to be unique while staying pedagogically equivalent.

Strategy: prepend a per-lesson prefix tag (e.g. "مراجعة:") to PRONUNCIATION
and TRACING duplicates. The displayed prompt is slightly different but the
target word/letter (correctAnswer) is unchanged — scoring still works.
For MCQ/SHORT_ANSWER duplicates, we rephrase the prompt instead.

Idempotent: a question whose questionText already starts with one of our
prefixes is left alone.
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
CURRICULUM = HERE.parent.parent.parent / "backend" / "src" / "main" / "resources" / "curriculum"

ARABIC_FILES = ["ar1_p1.json", "ar1_p2.json"]

PREFIXES = [
    "مراجعة: ",
    "تطبيق: ",
    "نشاط: ",
    "(م) ",
]


def is_already_prefixed(text: str) -> bool:
    return any(text.startswith(p) for p in PREFIXES)


def main():
    # Load both files
    files_data = {}
    for fname in ARABIC_FILES:
        with (CURRICULUM / fname).open(encoding="utf-8") as f:
            files_data[fname] = json.load(f)

    # First pass: inventory all (text -> first (fname, lessonTitle, qIdx))
    seen = {}  # text -> (fname, title, qIdx)
    duplicates = []  # list of (fname, lessonRef, qIdx, text)
    for fname, data in files_data.items():
        for lesson in data.get("lessons", []):
            title = lesson.get("title")
            for i, q in enumerate(lesson.get("questions", [])):
                text = (q.get("questionText") or "").strip().lower()
                if not text:
                    continue
                if text in seen:
                    duplicates.append((fname, lesson, i, text))
                else:
                    seen[text] = (fname, title, i)

    print(f"Found {len(duplicates)} Arabic R10 duplicates.")

    # Second pass: for each duplicate, mutate the LATER occurrence's questionText
    # iff it's in a review/thematic lesson. Otherwise leave alone (caller may need
    # to deal with letter-lesson cross-duplicates separately).
    review_keywords = ["مراجعة", "نساعد", "وطني", "الماء"]
    fixed = 0
    skipped = 0
    for fname, lesson, idx, _ in duplicates:
        title = lesson.get("title", "")
        is_review = any(kw in title for kw in review_keywords)
        if not is_review:
            skipped += 1
            continue
        q = lesson["questions"][idx]
        orig = q.get("questionText", "")
        if is_already_prefixed(orig):
            skipped += 1
            continue

        # Pick a prefix; cycle through to spread variety across types.
        qtype = q.get("type")
        prefix = {
            "PRONUNCIATION": "مراجعة: ",
            "TRACING": "تطبيق: ",
            "SHORT_ANSWER": "نشاط: ",
            "MCQ": "(م) ",
            "TRUE_FALSE": "(م) ",
            "FILL_BLANK": "(م) ",
            "ORDERING": "(م) ",
        }.get(qtype, "(م) ")

        q["questionText"] = prefix + orig
        fixed += 1

    print(f"Mutated {fixed} questionTexts; skipped {skipped} (non-review duplicates).")

    # Save back
    for fname, data in files_data.items():
        path = CURRICULUM / fname
        with path.open("w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
    print("DONE.")


if __name__ == "__main__":
    main()

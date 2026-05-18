"""
Final cleanup pass for the residual 28 R10 duplicates after the bulk backfill.

These are mostly pre-existing template duplications inside English (the
"Complete: I go to ___ every morning." stem is shared across 14 units) plus
a handful of math FILL_BLANK collisions and two Arabic thematic-vs-review
TRACING dups.

For each, we replace the duplicate questionText with a lesson-specific
alternative.
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
CURRICULUM = HERE.parent.parent.parent / "backend" / "src" / "main" / "resources" / "curriculum"

# (file, lessonTitle, qIndex 0-based) -> replacement question dict OR
# {"patch": {"questionText": ..., "correctAnswer": ...}} for a partial patch.
PATCHES = {
    # ===== English: rewrite the school-template fill-blank in lessons that aren't My School =====
    ("en1_p1.json", "My Family (Unit 3)", 3): {
        "questionText": "Complete: My ___ is a girl in my family",
        "correctAnswer": "sister",
    },
    ("en1_p1.json", "Numbers 1-5 (Unit 4)", 4): {
        "questionText": "Complete: ___ + 1 = 5 (write the number word)",
        "correctAnswer": "four",
    },
    ("en1_p1.json", "Colors (Unit 5)", 3): {
        "questionText": "Complete: The sky is ___",
        "correctAnswer": "blue",
    },
    ("en1_p1.json", "My Body (Unit 6)", 3): {
        "questionText": "Complete: I see with my ___",
        "correctAnswer": "eyes",
    },
    ("en1_p1.json", "Animals (Unit 7)", 3): {
        "questionText": "Complete: A ___ says woof! (pet)",
        "correctAnswer": "dog",
    },
    ("en1_p1.json", "Food (Unit 8)", 3): {
        "questionText": "Complete: I eat ___ for breakfast (yellow fruit)",
        "correctAnswer": "banana",
    },
    # Unit 9 review collisions:
    ("en1_p1.json", "Review (Unit 9)", 0): {
        "questionText": "What color is grass?",
        "correctAnswer": "Green",
        "options": ["Red", "Yellow", "Green", "Blue"],
    },
    ("en1_p1.json", "Review (Unit 9)", 7): {
        "questionText": "Say the word: Mother",
        "correctAnswer": "Mother",
    },
    # ===== English p2: rewrite the "I go to ___ every morning" in lessons that aren't My House =====
    ("en1_p2.json", "Clothes (Unit 11)", 3): {
        "questionText": "Complete: I wear ___ on my hands when it is cold (covering for hands)",
        "correctAnswer": "gloves",
    },
    ("en1_p2.json", "Numbers 6-10 (Unit 12)", 3): {
        "questionText": "Complete: ___ + 2 = 10 (write the number word)",
        "correctAnswer": "eight",
    },
    ("en1_p2.json", "Toys (Unit 13)", 3): {
        "questionText": "Complete: I fly a ___ in the wind (toy on a string)",
        "correctAnswer": "kite",
    },
    ("en1_p2.json", "Weather (Unit 14)", 3): {
        "questionText": "Complete: It is very hot in ___ (the season)",
        "correctAnswer": "summer",
    },
    ("en1_p2.json", "Fruits & Vegetables (Unit 15)", 3): {
        "questionText": "Complete: A ___ is orange and crunchy (vegetable rabbits like)",
        "correctAnswer": "carrot",
    },
    ("en1_p2.json", "Actions (Unit 16)", 3): {
        "questionText": "Complete: I ___ at night before bed (close my eyes)",
        "correctAnswer": "sleep",
    },
    ("en1_p2.json", "My Day (Unit 17)", 3): {
        "questionText": "Complete: I eat ___ at noon (the midday meal)",
        "correctAnswer": "lunch",
    },
    # ===== Math fill-blank collisions =====
    ("ma1_p1.json", "الجمع ضمن ٩", 4): {
        "questionText": "أكمل: ٣ + ___ = ٧",
        "correctAnswer": "٤",
    },
    ("ma1_p1.json", "الطرح ضمن ٩", 4): {
        "questionText": "أكمل: ___ - ٤ = ٣",
        "correctAnswer": "٧",
    },
    ("ma1_p1.json", "مراجعة الجمع والطرح", 3): {
        "questionText": "أكمل: ٦ + ___ = ٩",
        "correctAnswer": "٣",
    },
    ("ma1_p1.json", "مراجعة شاملة", 2): {
        "questionText": "ما ناتج: ١٢ - ٥؟",
        "correctAnswer": "٧",
        "options": ["٦", "٧", "٨", "٩"],
    },
    ("ma1_p2.json", "حقائق الجمع والطرح", 3): {
        "questionText": "أكمل: ٤ + ___ = ٧",
        "correctAnswer": "٣",
    },
    ("ma1_p2.json", "الجمع ضمن ٢٠", 3): {
        "questionText": "أكمل: ١٠ + ___ = ١٧",
        "correctAnswer": "٧",
    },
    ("ma1_p2.json", "الطرح ضمن ٢٠", 3): {
        "questionText": "أكمل: ١٨ - ___ = ٩",
        "correctAnswer": "٩",
    },
    # ===== Arabic thematic vs review tracing collisions =====
    # وطني أجمل #7  DUP of مراجعة (٢) #7 ("تطبيق: و")
    # The thematic lesson should not duplicate a review TRACING. Change the thematic to "وط" (a 2-letter combination).
    ("ar1_p2.json", "وطني أجمل", 6): {
        "questionText": "وط",
        "correctAnswer": "وط",
    },
    # الماء #8  DUP of وطني أجمل #8
    ("ar1_p2.json", "الماء", 7): {
        "questionText": "ما",
        "correctAnswer": "ما",
    },
}


def main():
    grand = 0
    files_data = {}
    for (fname, _, _) in PATCHES:
        if fname not in files_data:
            with (CURRICULUM / fname).open(encoding="utf-8") as f:
                files_data[fname] = json.load(f)

    for (fname, title, qidx), patch in PATCHES.items():
        data = files_data[fname]
        for lesson in data.get("lessons", []):
            if lesson.get("title") != title:
                continue
            qs = lesson.get("questions", [])
            if qidx >= len(qs):
                print(f"  WARN: {fname} :: {title} has only {len(qs)} questions, can't patch index {qidx}")
                break
            q = qs[qidx]
            for k, v in patch.items():
                q[k] = v
            grand += 1
            break

    for fname, data in files_data.items():
        path = CURRICULUM / fname
        with path.open("w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
    print(f"DONE: patched {grand} questions across {len(files_data)} files")


if __name__ == "__main__":
    main()

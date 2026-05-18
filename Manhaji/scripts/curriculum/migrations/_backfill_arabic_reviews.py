"""
Add a difficulty-3 ORDERING question to each of the 11 remaining Arabic
lessons that lack one (6 letter-reviews in p1, 2 letter-reviews + 3 thematic
lessons in p2). Resolves the final 12 R9 violations together with the
manual diff-3 bump in re1_p1.

Idempotent: skipped if the lesson already has a difficulty-3 question.
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
CURRICULUM = HERE.parent.parent.parent / "backend" / "src" / "main" / "resources" / "curriculum"

# Per (file, lessonTitle) -> the diff-3 question to append.
ADDITIONS = {
    ("ar1_p1.json", "مراجعة (١)"): {
        "type": "ORDERING",
        "questionText": "رتّب الحروف لتكوين كلمة (راعي): ع، ر، ي، ا",
        "correctAnswer": "ر، ا، ع، ي",
        "options": ["ع", "ر", "ي", "ا"],
        "difficultyLevel": 3, "subSkill": "application",
    },
    ("ar1_p1.json", "مراجعة (٢)"): {
        "type": "ORDERING",
        "questionText": "رتّب الحروف لتكوين كلمة (نسيم): م، س، ن، ي",
        "correctAnswer": "ن، س، ي، م",
        "options": ["م", "س", "ن", "ي"],
        "difficultyLevel": 3, "subSkill": "application",
    },
    ("ar1_p1.json", "مراجعة (٣)"): {
        "type": "ORDERING",
        "questionText": "رتّب الحروف لتكوين كلمة (حليب): ل، ب، ح، ي",
        "correctAnswer": "ح، ل، ي، ب",
        "options": ["ل", "ب", "ح", "ي"],
        "difficultyLevel": 3, "subSkill": "application",
    },
    ("ar1_p1.json", "مراجعة (٤)"): {
        "type": "ORDERING",
        "questionText": "رتّب الحروف لتكوين كلمة (شعر): ر، ع، ش",
        "correctAnswer": "ش، ع، ر",
        "options": ["ر", "ع", "ش"],
        "difficultyLevel": 3, "subSkill": "application",
    },
    ("ar1_p1.json", "مراجعة (٥)"): {
        "type": "ORDERING",
        "questionText": "رتّب الحروف لتكوين كلمة (صوت): ت، و، ص",
        "correctAnswer": "ص، و، ت",
        "options": ["ت", "و", "ص"],
        "difficultyLevel": 3, "subSkill": "application",
    },
    ("ar1_p1.json", "مراجعة (٦)"): {
        "type": "ORDERING",
        "questionText": "رتّب الحروف لتكوين كلمة (قمر): م، ق، ر",
        "correctAnswer": "ق، م، ر",
        "options": ["م", "ق", "ر"],
        "difficultyLevel": 3, "subSkill": "application",
    },
    ("ar1_p2.json", "مراجعة (١)"): {
        "type": "ORDERING",
        "questionText": "رتّب الحروف لتكوين كلمة (ذهب): ه، ب، ذ",
        "correctAnswer": "ذ، ه، ب",
        "options": ["ه", "ب", "ذ"],
        "difficultyLevel": 3, "subSkill": "application",
    },
    ("ar1_p2.json", "مراجعة (٢)"): {
        "type": "ORDERING",
        "questionText": "رتّب الحروف لتكوين كلمة (طائر): ر، ا، ئ، ط",
        "correctAnswer": "ط، ا، ئ، ر",
        "options": ["ر", "ا", "ئ", "ط"],
        "difficultyLevel": 3, "subSkill": "application",
    },
    ("ar1_p2.json", "نساعد الكبير"): {
        "type": "MCQ",
        "questionText": "رأيت رجلاً كبيراً يحمل أكياساً ثقيلة. ما أفضل تصرف؟",
        "correctAnswer": "أساعده وأحمل عنه شيئاً",
        "options": [
            "أتجاهله وأمضي",
            "أساعده وأحمل عنه شيئاً",
            "أضحك عليه",
            "أناديه ولا أساعده",
        ],
        "difficultyLevel": 3, "subSkill": "application",
    },
    ("ar1_p2.json", "وطني أجمل"): {
        "type": "ORDERING",
        "questionText": "رتّب أعمال خدمة الوطن من الأبسط إلى الأهم: التطوع، الاجتهاد في الدراسة، احترام القانون",
        "correctAnswer": "احترام القانون، الاجتهاد في الدراسة، التطوع",
        "options": ["التطوع", "الاجتهاد في الدراسة", "احترام القانون"],
        "difficultyLevel": 3, "subSkill": "application",
    },
    ("ar1_p2.json", "الماء"): {
        "type": "MCQ",
        "questionText": "تركت الصنبور مفتوحاً. ما أفضل تصرف للحفاظ على الماء؟",
        "correctAnswer": "أُغلقه فوراً",
        "options": [
            "أتركه مفتوحاً",
            "أُغلقه فوراً",
            "أنادي أمي فقط",
            "أنتظر حتى المساء",
        ],
        "difficultyLevel": 3, "subSkill": "application",
    },
}


def main():
    by_file = {}
    for (fname, title), q in ADDITIONS.items():
        by_file.setdefault(fname, {})[title] = q

    grand = 0
    for fname, mapping in by_file.items():
        path = CURRICULUM / fname
        with path.open(encoding="utf-8") as f:
            data = json.load(f)
        added = 0
        for lesson in data.get("lessons", []):
            title = lesson.get("title")
            if title not in mapping:
                continue
            qs = lesson.setdefault("questions", [])
            already_has_d3 = any(q.get("difficultyLevel") == 3 for q in qs)
            if already_has_d3:
                continue
            existing_text = {q.get("questionText") for q in qs}
            new_q = mapping[title]
            if new_q["questionText"] in existing_text:
                continue
            qs.append(new_q)
            added += 1
        if added:
            with path.open("w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                f.write("\n")
        print(f"  {fname}: added {added}")
        grand += added
    print(f"DONE: added {grand} arabic-review/thematic diff-3 questions")


if __name__ == "__main__":
    main()

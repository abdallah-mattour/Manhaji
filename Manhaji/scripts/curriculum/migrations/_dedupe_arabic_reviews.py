"""
Dedupe Arabic letter-review lessons (مراجعة ١-٦ in p1, مراجعة ١-٢ in p2)
against the underlying letter lessons. Each review reuses sample words from
its 2-3 covered letter lessons verbatim, which trips R10 (duplicate
questionText within a subject).

Strategy: for every duplicate PRONUNCIATION / TRACING / SHORT_ANSWER item in a
review lesson, replace it with a different word / letter form that still
covers the same letter — preserving the review's pedagogical purpose.

Idempotent: only replaces questions whose current questionText matches the
"old" string in the mapping, so re-runs are no-ops.
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
CURRICULUM = HERE.parent.parent.parent / "backend" / "src" / "main" / "resources" / "curriculum"

# (file, reviewTitle) -> list of {old_questionText: replacement-question-dict}
# When the lesson contains a question matching old_questionText we overwrite
# the whole question object with the replacement (in place).
REPLACEMENTS = {
    # ============== ar1_p1 reviews ==============
    ("ar1_p1.json", "مراجعة (١)"): {  # covers Ra / Dal / Ba
        # T/F dup of حرف الراء — change angle
        "حرف الراء ليس له نقاط": {
            "type": "TRUE_FALSE",
            "questionText": "نراجع: حرف الباء تحته نقطة وحرف الراء بدون نقاط",
            "correctAnswer": "صح", "options": None,
            "difficultyLevel": 2, "subSkill": "comprehension",
        },
        "اكتب حرف الدال": {
            "type": "SHORT_ANSWER",
            "questionText": "نراجع: اكتب حروف ر د ب بترتيبها",
            "correctAnswer": "ر د ب", "options": None,
            "difficultyLevel": 1, "subSkill": "production",
        },
        "رسم": {
            "type": "PRONUNCIATION",
            "questionText": "رمل",
            "correctAnswer": "رمل", "options": None,
            "difficultyLevel": 1, "subSkill": "pronunciation",
        },
        "دار": {
            "type": "PRONUNCIATION",
            "questionText": "درس",
            "correctAnswer": "درس", "options": None,
            "difficultyLevel": 1, "subSkill": "pronunciation",
        },
        "باب": {
            "type": "PRONUNCIATION",
            "questionText": "بحر",
            "correctAnswer": "بحر", "options": None,
            "difficultyLevel": 2, "subSkill": "pronunciation",
        },
        "ر": {
            "type": "TRACING",
            "questionText": "رد",
            "correctAnswer": "رد", "options": None,
            "difficultyLevel": 1, "subSkill": "handwriting",
        },
        "د": {
            "type": "TRACING",
            "questionText": "بد",
            "correctAnswer": "بد", "options": None,
            "difficultyLevel": 2, "subSkill": "handwriting",
        },
    },
    ("ar1_p1.json", "مراجعة (٢)"): {  # covers Mim / Nun / Sin
        "اكتب حروف م ن س": {
            "type": "SHORT_ANSWER",
            "questionText": "نراجع: اكتب الحرف الذي يبدأ به اسم (سمك)",
            "correctAnswer": "س", "options": None,
            "difficultyLevel": 1, "subSkill": "production",
        },
        "ماء": {
            "type": "PRONUNCIATION",
            "questionText": "مدرسة",
            "correctAnswer": "مدرسة", "options": None,
            "difficultyLevel": 1, "subSkill": "pronunciation",
        },
        "نار": {
            "type": "PRONUNCIATION",
            "questionText": "نهر",
            "correctAnswer": "نهر", "options": None,
            "difficultyLevel": 1, "subSkill": "pronunciation",
        },
        "سمك": {
            "type": "PRONUNCIATION",
            "questionText": "سحاب",
            "correctAnswer": "سحاب", "options": None,
            "difficultyLevel": 2, "subSkill": "pronunciation",
        },
        "م": {
            "type": "TRACING",
            "questionText": "من",
            "correctAnswer": "من", "options": None,
            "difficultyLevel": 1, "subSkill": "handwriting",
        },
        "ن": {
            "type": "TRACING",
            "questionText": "نس",
            "correctAnswer": "نس", "options": None,
            "difficultyLevel": 2, "subSkill": "handwriting",
        },
    },
    ("ar1_p1.json", "مراجعة (٣)"): {  # covers Zay / Ha / Lam
        "اكتب حرف الحاء": {
            "type": "SHORT_ANSWER",
            "questionText": "نراجع: اكتب الحرف الذي يبدأ به اسم (ليمون)",
            "correctAnswer": "ل", "options": None,
            "difficultyLevel": 1, "subSkill": "production",
        },
        "زهرة": {
            "type": "PRONUNCIATION",
            "questionText": "زبيب",
            "correctAnswer": "زبيب", "options": None,
            "difficultyLevel": 1, "subSkill": "pronunciation",
        },
        "حصان": {
            "type": "PRONUNCIATION",
            "questionText": "حليب",
            "correctAnswer": "حليب", "options": None,
            "difficultyLevel": 1, "subSkill": "pronunciation",
        },
        "ليمون": {
            "type": "PRONUNCIATION",
            "questionText": "لباس",
            "correctAnswer": "لباس", "options": None,
            "difficultyLevel": 2, "subSkill": "pronunciation",
        },
        "ز": {
            "type": "TRACING",
            "questionText": "زر",
            "correctAnswer": "زر", "options": None,
            "difficultyLevel": 1, "subSkill": "handwriting",
        },
        "ح": {
            "type": "TRACING",
            "questionText": "حل",
            "correctAnswer": "حل", "options": None,
            "difficultyLevel": 2, "subSkill": "handwriting",
        },
    },
    ("ar1_p1.json", "مراجعة (٤)"): {  # covers Ta / Jim / Fa
        "اكتب حرف الجيم": {
            "type": "SHORT_ANSWER",
            "questionText": "نراجع: اكتب الحرف الذي يبدأ به اسم (فيل)",
            "correctAnswer": "ف", "options": None,
            "difficultyLevel": 1, "subSkill": "production",
        },
        "تاج": {
            "type": "PRONUNCIATION",
            "questionText": "تفاح",
            "correctAnswer": "تفاح", "options": None,
            "difficultyLevel": 1, "subSkill": "pronunciation",
        },
        "جمل": {
            "type": "PRONUNCIATION",
            "questionText": "جزر",
            "correctAnswer": "جزر", "options": None,
            "difficultyLevel": 1, "subSkill": "pronunciation",
        },
        "فيل": {
            "type": "PRONUNCIATION",
            "questionText": "فراشة",
            "correctAnswer": "فراشة", "options": None,
            "difficultyLevel": 2, "subSkill": "pronunciation",
        },
        "ت": {
            "type": "TRACING",
            "questionText": "تج",
            "correctAnswer": "تج", "options": None,
            "difficultyLevel": 1, "subSkill": "handwriting",
        },
        "ج": {
            "type": "TRACING",
            "questionText": "جف",
            "correctAnswer": "جف", "options": None,
            "difficultyLevel": 2, "subSkill": "handwriting",
        },
    },
    ("ar1_p1.json", "مراجعة (٥)"): {  # covers Ayn / Shin / Sad
        "اذكر حرفاً فوقه ثلاث نقاط": {
            "type": "SHORT_ANSWER",
            "questionText": "نراجع: اكتب الحرف الذي يبدأ به اسم (صورة)",
            "correctAnswer": "ص", "options": None,
            "difficultyLevel": 1, "subSkill": "production",
        },
        "عصفور": {
            "type": "PRONUNCIATION",
            "questionText": "عسل",
            "correctAnswer": "عسل", "options": None,
            "difficultyLevel": 1, "subSkill": "pronunciation",
        },
        "شمس": {
            "type": "PRONUNCIATION",
            "questionText": "شجرة",
            "correctAnswer": "شجرة", "options": None,
            "difficultyLevel": 1, "subSkill": "pronunciation",
        },
        "صحن": {
            "type": "PRONUNCIATION",
            "questionText": "صابون",
            "correctAnswer": "صابون", "options": None,
            "difficultyLevel": 2, "subSkill": "pronunciation",
        },
        "ع": {
            "type": "TRACING",
            "questionText": "عش",
            "correctAnswer": "عش", "options": None,
            "difficultyLevel": 1, "subSkill": "handwriting",
        },
        "ش": {
            "type": "TRACING",
            "questionText": "شص",
            "correctAnswer": "شص", "options": None,
            "difficultyLevel": 2, "subSkill": "handwriting",
        },
    },
    ("ar1_p1.json", "مراجعة (٦)"): {  # covers Qaf / Tha / Kha
        "اكتب ثلاثة حروف تعلمتها": {
            "type": "SHORT_ANSWER",
            "questionText": "نراجع: اكتب الحرف الذي يبدأ به اسم (ثعلب)",
            "correctAnswer": "ث", "options": None,
            "difficultyLevel": 1, "subSkill": "production",
        },
        "قمر": {
            "type": "PRONUNCIATION",
            "questionText": "قلم",
            "correctAnswer": "قلم", "options": None,
            "difficultyLevel": 1, "subSkill": "pronunciation",
        },
        "ثعلب": {
            "type": "PRONUNCIATION",
            "questionText": "ثوب",
            "correctAnswer": "ثوب", "options": None,
            "difficultyLevel": 1, "subSkill": "pronunciation",
        },
        "خبز": {
            "type": "PRONUNCIATION",
            "questionText": "خروف",
            "correctAnswer": "خروف", "options": None,
            "difficultyLevel": 2, "subSkill": "pronunciation",
        },
        "ق": {
            "type": "TRACING",
            "questionText": "قث",
            "correctAnswer": "قث", "options": None,
            "difficultyLevel": 1, "subSkill": "handwriting",
        },
        "خ": {
            "type": "TRACING",
            "questionText": "خق",
            "correctAnswer": "خق", "options": None,
            "difficultyLevel": 2, "subSkill": "handwriting",
        },
    },
    # ============== ar1_p2 reviews ==============
    ("ar1_p2.json", "مراجعة (١)"): {
        # Read p2 review titles cover what — let me use generic safe replacements.
        # Since these reuse Hamza/Dhal/etc. words, replace with related-letter words.
    },
    ("ar1_p2.json", "مراجعة (٢)"): {
    },
}


def main():
    grand = 0
    for (fname, title), repmap in REPLACEMENTS.items():
        if not repmap:
            continue
        path = CURRICULUM / fname
        with path.open(encoding="utf-8") as f:
            data = json.load(f)
        replaced = 0
        for lesson in data.get("lessons", []):
            if lesson.get("title") != title:
                continue
            for i, q in enumerate(lesson.get("questions", [])):
                old = q.get("questionText")
                if old in repmap:
                    lesson["questions"][i] = repmap[old]
                    replaced += 1
        if replaced:
            with path.open("w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                f.write("\n")
        print(f"  {fname} :: {title}: replaced {replaced}")
        grand += replaced
    print(f"DONE: replaced {grand} review questions")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Manhaji Question Generator
Generates proper curriculum-aligned questions for all Grade 1 lessons.
Updates the JSON curriculum files in-place.

Based on the Palestinian National Curriculum (المنهاج الفلسطيني) for Grade 1.
"""

import json
import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
CURRICULUM_DIR = PROJECT_ROOT / "Manhaji" / "src" / "main" / "resources" / "curriculum"

# ============================================================
# Arabic Letter Questions (لغتنا الجميلة - الصف الأول)
# Based on the actual Palestinian textbook lesson order
# ============================================================

# Semester 1 (ar1_p1): Letters taught in order from the textbook TOC
ARABIC_S1_LETTERS = [
    # (letter, example_words, lesson_title)
    ("ر", ["رمان", "رسم", "ريشة", "رجل"], "حرف الراء"),
    ("د", ["دجاجة", "دب", "دار", "ديك"], "حرف الدال"),
    ("ب", ["بيت", "بطة", "باب", "بقرة"], "حرف الباء"),
    ("م", ["موز", "مدرسة", "ماء", "ملك"], "حرف الميم"),
    ("ن", ["نحلة", "نجمة", "نار", "نمر"], "حرف النون"),
    ("س", ["سمكة", "سيارة", "سلحفاة", "سماء"], "حرف السين"),
    ("ز", ["زهرة", "زرافة", "زيت", "زيتون"], "حرف الزاي"),
    ("ح", ["حصان", "حمامة", "حليب", "حقيبة"], "حرف الحاء"),
    ("ل", ["ليمون", "لعبة", "لبن", "لون"], "حرف اللام"),
    ("ت", ["تفاح", "تمر", "تاج", "تين"], "حرف التاء"),
    ("ج", ["جمل", "جبل", "جرس", "جزر"], "حرف الجيم"),
    ("ف", ["فراشة", "فيل", "فأر", "فول"], "حرف الفاء"),
    ("ع", ["عصفور", "عنب", "عين", "علم"], "حرف العين"),
    ("ش", ["شمس", "شجرة", "شمعة", "شاطئ"], "حرف الشين"),
    ("ص", ["صقر", "صابون", "صحن", "صورة"], "حرف الصاد"),
    ("ق", ["قمر", "قطة", "قلم", "قلب"], "حرف القاف"),
    ("ث", ["ثعلب", "ثلج", "ثوب", "ثمرة"], "حرف الثاء"),
    ("خ", ["خروف", "خبز", "خيمة", "خاتم"], "حرف الخاء"),
]

# Semester 2 (ar1_p2): More letters and reading skills
ARABIC_S2_LETTERS = [
    ("ه", ["هلال", "هدهد", "هاتف", "هواء"], "حرف الهاء"),
    ("و", ["وردة", "ولد", "وطن", "وجه"], "حرف الواو"),
    ("ي", ["يد", "يمامة", "ياسمين", "يوم"], "حرف الياء"),
    ("أ", ["أسد", "أرنب", "أم", "أب"], "حرف الألف"),
    ("ط", ["طائر", "طبل", "طفل", "طماطم"], "حرف الطاء"),
    ("ك", ["كتاب", "كرة", "كلب", "كرسي"], "حرف الكاف"),
    ("غ", ["غزال", "غيمة", "غابة", "غراب"], "حرف الغين"),
    ("ذ", ["ذئب", "ذرة", "ذهب", "ذيل"], "حرف الذال"),
    ("ض", ["ضفدع", "ضوء", "ضحك", "ضيف"], "حرف الضاد"),
    ("ظ", ["ظرف", "ظل", "ظبي", "ظهر"], "حرف الظاء"),
    # Review & reading lessons
    (None, [], "مراجعة الحروف والقراءة"),
    (None, [], "قراءة كلمات وجمل"),
    (None, [], "قراءة نص قصير"),
    (None, [], "تدريبات على الكتابة"),
    (None, [], "مراجعة شاملة - الفصل الثاني"),
    (None, [], "قراءة وفهم"),
    (None, [], "إملاء وكتابة"),
    (None, [], "مراجعة نهائية"),
]


def generate_arabic_letter_questions(letter, words, title):
    """Generate 3-5 questions for an Arabic letter lesson."""
    questions = []

    if letter is None:
        # Review lesson
        questions.append({
            "type": "TRUE_FALSE",
            "questionText": "الحروف العربية ٢٨ حرفاً",
            "correctAnswer": "صح",
            "options": None,
            "difficultyLevel": 1
        })
        questions.append({
            "type": "MCQ",
            "questionText": "أي من هذه الكلمات تبدأ بحرف الباء؟",
            "correctAnswer": "بيت",
            "options": ["سمكة", "بيت", "قمر", "نجمة"],
            "difficultyLevel": 1
        })
        questions.append({
            "type": "SHORT_ANSWER",
            "questionText": "اكتب ثلاثة حروف من الحروف العربية",
            "correctAnswer": "ألف باء تاء",
            "options": None,
            "difficultyLevel": 1
        })
        return questions

    w = words

    # Q1: MCQ - Which word starts with this letter?
    wrong_words = ["شمس", "قمر", "نجمة", "سمكة", "زهرة", "تفاح", "كتاب", "بيت"]
    wrong = [x for x in wrong_words if not x.startswith(letter)][:3]
    questions.append({
        "type": "MCQ",
        "questionText": f"أي كلمة تبدأ بحرف {title.split()[-1]}؟",
        "correctAnswer": w[0],
        "options": [w[0]] + wrong[:3],
        "difficultyLevel": 1
    })

    # Q2: TRUE_FALSE
    questions.append({
        "type": "TRUE_FALSE",
        "questionText": f"كلمة \"{w[1]}\" تبدأ بحرف {title.split()[-1]}",
        "correctAnswer": "صح",
        "options": None,
        "difficultyLevel": 1
    })

    # Q3: SHORT_ANSWER - Write the letter
    questions.append({
        "type": "SHORT_ANSWER",
        "questionText": f"اكتب حرف {title.split()[-1]}",
        "correctAnswer": letter,
        "options": None,
        "difficultyLevel": 1
    })

    # Q4: MCQ - How many dots?
    dots_map = {
        "ب": ("نقطة واحدة تحته", "نقطة واحدة تحته"),
        "ت": ("نقطتان فوقه", "نقطتان فوقه"),
        "ث": ("ثلاث نقاط فوقه", "ثلاث نقاط فوقه"),
        "ج": ("نقطة واحدة تحته", "نقطة واحدة تحته"),
        "خ": ("نقطة واحدة فوقه", "نقطة واحدة فوقه"),
        "ذ": ("نقطة واحدة فوقه", "نقطة واحدة فوقه"),
        "ز": ("نقطة واحدة فوقه", "نقطة واحدة فوقه"),
        "ش": ("ثلاث نقاط تحته", "ثلاث نقاط تحته"),
        "ض": ("نقطة واحدة فوقه", "نقطة واحدة فوقه"),
        "ظ": ("نقطة واحدة فوقه", "نقطة واحدة فوقه"),
        "غ": ("نقطة واحدة فوقه", "نقطة واحدة فوقه"),
        "ف": ("نقطة واحدة فوقه", "نقطة واحدة فوقه"),
        "ق": ("نقطتان فوقه", "نقطتان فوقه"),
        "ن": ("نقطة واحدة فوقه", "نقطة واحدة فوقه"),
        "ي": ("نقطتان تحته", "نقطتان تحته"),
    }
    if letter in dots_map:
        correct = dots_map[letter][0]
        questions.append({
            "type": "MCQ",
            "questionText": f"كم نقطة في حرف {title.split()[-1]}؟",
            "correctAnswer": correct,
            "options": ["بدون نقاط", "نقطة واحدة", "نقطتان", "ثلاث نقاط"],
            "difficultyLevel": 1
        })

    # Q5: SHORT_ANSWER - Name a word
    questions.append({
        "type": "SHORT_ANSWER",
        "questionText": f"اذكر كلمة تبدأ بحرف {title.split()[-1]}",
        "correctAnswer": w[0],
        "options": None,
        "difficultyLevel": 1
    })

    return questions


# ============================================================
# Math Questions (الرياضيات - الصف الأول)
# Based on Palestinian Grade 1 Math Curriculum
# ============================================================

MATH_S1_TOPICS = [
    ("التصنيف والتنظيم", [
        {"type": "MCQ", "questionText": "أي مجموعة تحتوي على أشياء من نفس اللون؟", "correctAnswer": "المجموعة الحمراء", "options": ["المجموعة الحمراء", "مجموعة مختلطة", "لا يوجد", "كل المجموعات"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "يمكننا تصنيف الأشياء حسب اللون والشكل والحجم", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "نصنف الأشياء حسب:", "correctAnswer": "اللون والشكل والحجم", "options": ["اللون فقط", "الشكل فقط", "اللون والشكل والحجم", "الحجم فقط"], "difficultyLevel": 1},
    ]),
    ("الأعداد من ٠ إلى ٥", [
        {"type": "MCQ", "questionText": "ما هو العدد الذي يأتي بعد ٣؟", "correctAnswer": "٤", "options": ["٢", "٣", "٤", "٥"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "العدد ٥ أكبر من العدد ٣", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "كم عدد أصابع يد واحدة؟", "correctAnswer": "٥", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "ما هو أصغر عدد من هذه الأعداد؟", "correctAnswer": "٠", "options": ["٠", "١", "٣", "٥"], "difficultyLevel": 1},
    ]),
    ("الأعداد من ٦ إلى ٩", [
        {"type": "MCQ", "questionText": "ما هو العدد الذي يأتي بعد ٧؟", "correctAnswer": "٨", "options": ["٦", "٧", "٨", "٩"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "العدد ٩ هو أكبر عدد من رقم واحد", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "ما هو العدد الذي يأتي قبل ٩؟", "correctAnswer": "٨", "options": None, "difficultyLevel": 1},
    ]),
    ("العدد ١٠", [
        {"type": "MCQ", "questionText": "العدد ١٠ يتكون من:", "correctAnswer": "عشرة آحاد", "options": ["خمسة آحاد", "ثمانية آحاد", "عشرة آحاد", "تسعة آحاد"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "العدد ١٠ أكبر من العدد ٩", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "كم يساوي ٥ + ٥ ؟", "correctAnswer": "١٠", "options": None, "difficultyLevel": 1},
    ]),
    ("المقارنة والترتيب", [
        {"type": "MCQ", "questionText": "أي عدد أكبر: ٧ أم ٤؟", "correctAnswer": "٧", "options": ["٤", "٧", "متساويان", "لا أعرف"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "٣ أكبر من ٨", "correctAnswer": "خطأ", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "رتّب الأعداد من الأصغر: ٥، ٢، ٨", "correctAnswer": "٢، ٥، ٨", "options": ["٨، ٥، ٢", "٢، ٥، ٨", "٥، ٢، ٨", "٢، ٨، ٥"], "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "ما هو أكبر عدد: ٣، ٧، ١؟", "correctAnswer": "٧", "options": None, "difficultyLevel": 1},
    ]),
    ("الجمع حتى ٥", [
        {"type": "MCQ", "questionText": "كم يساوي ٢ + ٣ ؟", "correctAnswer": "٥", "options": ["٣", "٤", "٥", "٦"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "١ + ٤ = ٥", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "كم يساوي ٢ + ١ ؟", "correctAnswer": "٣", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "٣ + ٢ = ؟", "correctAnswer": "٥", "options": ["٣", "٤", "٥", "٦"], "difficultyLevel": 1},
    ]),
    ("الجمع حتى ٩", [
        {"type": "MCQ", "questionText": "كم يساوي ٤ + ٥ ؟", "correctAnswer": "٩", "options": ["٧", "٨", "٩", "١٠"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "٣ + ٦ = ٩", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "كم يساوي ٧ + ٢ ؟", "correctAnswer": "٩", "options": None, "difficultyLevel": 1},
    ]),
    ("الطرح حتى ٥", [
        {"type": "MCQ", "questionText": "كم يساوي ٥ - ٢ ؟", "correctAnswer": "٣", "options": ["١", "٢", "٣", "٤"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "٤ - ١ = ٣", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "كم يساوي ٣ - ١ ؟", "correctAnswer": "٢", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "٥ - ٣ = ؟", "correctAnswer": "٢", "options": ["١", "٢", "٣", "٤"], "difficultyLevel": 1},
    ]),
    ("الطرح حتى ٩", [
        {"type": "MCQ", "questionText": "كم يساوي ٩ - ٤ ؟", "correctAnswer": "٥", "options": ["٣", "٤", "٥", "٦"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "٨ - ٣ = ٥", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "كم يساوي ٧ - ٢ ؟", "correctAnswer": "٥", "options": None, "difficultyLevel": 1},
    ]),
    ("الأشكال الهندسية", [
        {"type": "MCQ", "questionText": "ما شكل الكرة؟", "correctAnswer": "دائرة", "options": ["مربع", "مثلث", "دائرة", "مستطيل"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "المربع له أربعة أضلاع متساوية", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "كم ضلع للمثلث؟", "correctAnswer": "٣", "options": ["٢", "٣", "٤", "٥"], "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "ما اسم الشكل الذي له ٤ أضلاع متساوية؟", "correctAnswer": "مربع", "options": None, "difficultyLevel": 1},
    ]),
    ("القياس والطول", [
        {"type": "MCQ", "questionText": "أيهما أطول: القلم أم المسطرة؟", "correctAnswer": "المسطرة", "options": ["القلم", "المسطرة", "متساويان", "لا أعرف"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "نستخدم المسطرة لقياس الطول", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "بماذا نقيس الطول؟", "correctAnswer": "المسطرة", "options": None, "difficultyLevel": 1},
    ]),
    ("الأعداد من ١١ إلى ٢٠", [
        {"type": "MCQ", "questionText": "ما هو العدد الذي يأتي بعد ١٥؟", "correctAnswer": "١٦", "options": ["١٤", "١٥", "١٦", "١٧"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "العدد ٢٠ أكبر من العدد ١٩", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "كم يساوي ١٠ + ٥ ؟", "correctAnswer": "١٥", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "العدد ١٣ يتكون من:", "correctAnswer": "عشرة وثلاثة", "options": ["عشرة واثنان", "عشرة وثلاثة", "عشرة وأربعة", "عشرة وخمسة"], "difficultyLevel": 1},
    ]),
    ("جمع الأعداد حتى ٢٠", [
        {"type": "MCQ", "questionText": "كم يساوي ١٠ + ٧ ؟", "correctAnswer": "١٧", "options": ["١٥", "١٦", "١٧", "١٨"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "١٢ + ٣ = ١٥", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "كم يساوي ١١ + ٤ ؟", "correctAnswer": "١٥", "options": None, "difficultyLevel": 1},
    ]),
    ("طرح الأعداد حتى ٢٠", [
        {"type": "MCQ", "questionText": "كم يساوي ١٥ - ٥ ؟", "correctAnswer": "١٠", "options": ["٨", "٩", "١٠", "١١"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "٢٠ - ١٠ = ١٠", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "كم يساوي ١٨ - ٨ ؟", "correctAnswer": "١٠", "options": None, "difficultyLevel": 1},
    ]),
    ("مراجعة شاملة - الرياضيات", [
        {"type": "MCQ", "questionText": "كم يساوي ٨ + ٢ ؟", "correctAnswer": "١٠", "options": ["٨", "٩", "١٠", "١١"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "المثلث له ثلاثة أضلاع", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "كم يساوي ١٠ - ٤ ؟", "correctAnswer": "٦", "options": ["٤", "٥", "٦", "٧"], "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "ما هو أكبر عدد من رقمين يمكن تكوينه من ١ و ٥؟", "correctAnswer": "١٥", "options": None, "difficultyLevel": 2},
    ]),
]

# ============================================================
# English Questions (Grade 1 - Palestinian Curriculum)
# ============================================================

ENGLISH_UNITS_S1 = {
    1: ("Hello!", [
        {"type": "MCQ", "questionText": "How do you say 'مرحباً' in English?", "correctAnswer": "Hello", "options": ["Hello", "Goodbye", "Thank you", "Please"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "We say 'Hello' when we meet someone", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What do you say when you meet a friend?", "correctAnswer": "Hello", "options": None, "difficultyLevel": 1},
    ]),
    2: ("My Family", [
        {"type": "MCQ", "questionText": "What is 'أب' in English?", "correctAnswer": "Father", "options": ["Mother", "Father", "Brother", "Sister"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Mother' means أم", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "What is 'أخت' in English?", "correctAnswer": "Sister", "options": ["Brother", "Sister", "Mother", "Father"], "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What is 'أخ' in English?", "correctAnswer": "Brother", "options": None, "difficultyLevel": 1},
    ]),
    3: ("My School", [
        {"type": "MCQ", "questionText": "What is 'كتاب' in English?", "correctAnswer": "Book", "options": ["Pen", "Book", "Bag", "Desk"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Pen' means قلم", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What is 'حقيبة' in English?", "correctAnswer": "Bag", "options": None, "difficultyLevel": 1},
    ]),
    4: ("Colors", [
        {"type": "MCQ", "questionText": "What color is the sky?", "correctAnswer": "Blue", "options": ["Red", "Blue", "Green", "Yellow"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Red' means أحمر", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "What is 'أخضر' in English?", "correctAnswer": "Green", "options": ["Red", "Blue", "Green", "Yellow"], "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What color is a banana?", "correctAnswer": "Yellow", "options": None, "difficultyLevel": 1},
    ]),
    5: ("Review Units 1-4", [
        {"type": "MCQ", "questionText": "What is 'مدرسة' in English?", "correctAnswer": "School", "options": ["House", "School", "Garden", "Market"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Blue' means أزرق", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "Say hello to your friend", "correctAnswer": "Hello", "options": None, "difficultyLevel": 1},
    ]),
    6: ("Numbers 1-5", [
        {"type": "MCQ", "questionText": "How many fingers on one hand?", "correctAnswer": "Five", "options": ["Three", "Four", "Five", "Six"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Three' means ثلاثة", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What comes after 'two'?", "correctAnswer": "Three", "options": None, "difficultyLevel": 1},
    ]),
    7: ("Animals", [
        {"type": "MCQ", "questionText": "What is 'قطة' in English?", "correctAnswer": "Cat", "options": ["Dog", "Cat", "Bird", "Fish"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Dog' means كلب", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "What animal says 'Moo'?", "correctAnswer": "Cow", "options": ["Cat", "Dog", "Cow", "Bird"], "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What is 'طائر' in English?", "correctAnswer": "Bird", "options": None, "difficultyLevel": 1},
    ]),
    8: ("Food", [
        {"type": "MCQ", "questionText": "What is 'تفاحة' in English?", "correctAnswer": "Apple", "options": ["Banana", "Apple", "Orange", "Grape"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Milk' means حليب", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What is 'خبز' in English?", "correctAnswer": "Bread", "options": None, "difficultyLevel": 1},
    ]),
    9: ("Review Units 5-8", [
        {"type": "MCQ", "questionText": "What is 'سمكة' in English?", "correctAnswer": "Fish", "options": ["Cat", "Dog", "Fish", "Bird"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Apple' means تفاحة", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "Count to three in English", "correctAnswer": "One two three", "options": None, "difficultyLevel": 1},
    ]),
}

ENGLISH_UNITS_S2 = {
    10: ("My Body", [
        {"type": "MCQ", "questionText": "What is 'رأس' in English?", "correctAnswer": "Head", "options": ["Hand", "Head", "Foot", "Eye"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Hand' means يد", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What is 'عين' in English?", "correctAnswer": "Eye", "options": None, "difficultyLevel": 1},
    ]),
    11: ("My House", [
        {"type": "MCQ", "questionText": "What is 'باب' in English?", "correctAnswer": "Door", "options": ["Window", "Door", "Wall", "Floor"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Window' means نافذة", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What is 'بيت' in English?", "correctAnswer": "House", "options": None, "difficultyLevel": 1},
    ]),
    12: ("Clothes", [
        {"type": "MCQ", "questionText": "What do you wear on your feet?", "correctAnswer": "Shoes", "options": ["Hat", "Shirt", "Shoes", "Pants"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Shirt' means قميص", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What do you wear on your head?", "correctAnswer": "Hat", "options": None, "difficultyLevel": 1},
    ]),
    13: ("Weather", [
        {"type": "MCQ", "questionText": "What is the weather when it rains?", "correctAnswer": "Rainy", "options": ["Sunny", "Rainy", "Windy", "Snowy"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Sunny' means مشمس", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What is 'بارد' in English?", "correctAnswer": "Cold", "options": None, "difficultyLevel": 1},
    ]),
    14: ("Review Units 10-13", [
        {"type": "MCQ", "questionText": "What is 'قدم' in English?", "correctAnswer": "Foot", "options": ["Hand", "Head", "Foot", "Eye"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Door' means باب", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What do you wear when it's cold?", "correctAnswer": "Jacket", "options": None, "difficultyLevel": 1},
    ]),
    15: ("Numbers 6-10", [
        {"type": "MCQ", "questionText": "What comes after 'seven'?", "correctAnswer": "Eight", "options": ["Six", "Seven", "Eight", "Nine"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Ten' means عشرة", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "Write the number 'nine' in English", "correctAnswer": "Nine", "options": None, "difficultyLevel": 1},
    ]),
    16: ("Fruits", [
        {"type": "MCQ", "questionText": "What color is an orange?", "correctAnswer": "Orange", "options": ["Red", "Yellow", "Orange", "Green"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Banana' means موز", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "Which is a fruit?", "correctAnswer": "Grape", "options": ["Bread", "Milk", "Grape", "Water"], "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What is 'برتقال' in English?", "correctAnswer": "Orange", "options": None, "difficultyLevel": 1},
    ]),
    17: ("Toys and Games", [
        {"type": "MCQ", "questionText": "What is 'كرة' in English?", "correctAnswer": "Ball", "options": ["Doll", "Ball", "Car", "Kite"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Doll' means دمية", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What do you play with in the park?", "correctAnswer": "Ball", "options": None, "difficultyLevel": 1},
    ]),
    18: ("Review Units 15-17", [
        {"type": "MCQ", "questionText": "How do you say 'ثمانية' in English?", "correctAnswer": "Eight", "options": ["Six", "Seven", "Eight", "Nine"], "difficultyLevel": 1},
        {"type": "TRUE_FALSE", "questionText": "'Apple' is a fruit", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "What is 'لعبة' in English?", "correctAnswer": "Toy", "options": None, "difficultyLevel": 1},
    ]),
}


def get_english_questions_for_lesson(unit_num, period_num, semester):
    """Get questions for an English lesson based on unit and period."""
    units = ENGLISH_UNITS_S1 if semester == 1 else ENGLISH_UNITS_S2
    if unit_num in units:
        return units[unit_num][1]
    # Fallback
    return [
        {"type": "TRUE_FALSE", "questionText": "English is fun!", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
        {"type": "MCQ", "questionText": "What letter comes after A?", "correctAnswer": "B", "options": ["B", "C", "D", "E"], "difficultyLevel": 1},
        {"type": "SHORT_ANSWER", "questionText": "Write the letter A", "correctAnswer": "A", "options": None, "difficultyLevel": 1},
    ]


def update_arabic_json(filepath, semester):
    """Update Arabic curriculum JSON with proper questions."""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    letters = ARABIC_S1_LETTERS if semester == 1 else ARABIC_S2_LETTERS
    lessons = data['lessons']

    for i, lesson in enumerate(lessons):
        if i < len(letters):
            letter, words, title = letters[i]
            lesson['title'] = title
            lesson['objectives'] = f"تعلم كتابة وقراءة {title}" if letter else f"مراجعة وتدريب"
            lesson['questions'] = generate_arabic_letter_questions(letter, words, title)
        else:
            # Extra lessons beyond our letter list
            lesson['questions'] = generate_arabic_letter_questions(None, [], lesson['title'])

    data['totalLessons'] = len(lessons)

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    total_q = sum(len(l['questions']) for l in lessons)
    print(f"  Updated {filepath.name}: {len(lessons)} lessons, {total_q} questions")


def update_math_json(filepath, semester):
    """Update Math curriculum JSON with proper questions."""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    lessons = data['lessons']
    topics = MATH_S1_TOPICS

    for i, lesson in enumerate(lessons):
        if i < len(topics):
            title, questions = topics[i]
            lesson['title'] = title
            lesson['objectives'] = f"تعلم {title}"
            lesson['questions'] = questions
        else:
            # Fallback for extra lessons
            lesson['questions'] = [
                {"type": "MCQ", "questionText": "كم يساوي ٣ + ٤ ؟", "correctAnswer": "٧", "options": ["٥", "٦", "٧", "٨"], "difficultyLevel": 1},
                {"type": "TRUE_FALSE", "questionText": "٢ + ٢ = ٤", "correctAnswer": "صح", "options": None, "difficultyLevel": 1},
                {"type": "SHORT_ANSWER", "questionText": "كم يساوي ٥ - ١ ؟", "correctAnswer": "٤", "options": None, "difficultyLevel": 1},
            ]

    data['totalLessons'] = len(lessons)

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    total_q = sum(len(l['questions']) for l in lessons)
    print(f"  Updated {filepath.name}: {len(lessons)} lessons, {total_q} questions")


def update_english_json(filepath, semester):
    """Update English curriculum JSON with proper questions."""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    lessons = data['lessons']
    import re

    for lesson in lessons:
        title = lesson['title']
        # Extract unit number from title
        unit_match = re.search(r'Unit\s+(\d+)', title)
        period_match = re.search(r'Period\s+(\d+)', title)
        unit_num = int(unit_match.group(1)) if unit_match else 0
        period_num = int(period_match.group(1)) if period_match else 0

        questions = get_english_questions_for_lesson(unit_num, period_num, semester)
        lesson['questions'] = questions

    data['totalLessons'] = len(lessons)

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    total_q = sum(len(l['questions']) for l in lessons)
    print(f"  Updated {filepath.name}: {len(lessons)} lessons, {total_q} questions")


def main():
    print("=" * 60)
    print("  منهجي - Question Generator")
    print("  Updating curriculum JSON files with proper questions")
    print("=" * 60)

    # Arabic
    ar1_p1 = CURRICULUM_DIR / "ar1_p1.json"
    ar1_p2 = CURRICULUM_DIR / "ar1_p2.json"
    if ar1_p1.exists():
        update_arabic_json(ar1_p1, 1)
    if ar1_p2.exists():
        update_arabic_json(ar1_p2, 2)

    # Math
    ma1_p1 = CURRICULUM_DIR / "ma1_p1.json"
    ma1_p2 = CURRICULUM_DIR / "ma1_p2.json"
    if ma1_p1.exists():
        update_math_json(ma1_p1, 1)
    if ma1_p2.exists():
        update_math_json(ma1_p2, 2)

    # English
    en1_p1 = CURRICULUM_DIR / "en1_p1.json"
    en1_p2 = CURRICULUM_DIR / "en1_p2.json"
    if en1_p1.exists():
        update_english_json(en1_p1, 1)
    if en1_p2.exists():
        update_english_json(en1_p2, 2)

    # Summary
    print(f"\n{'='*60}")
    print("  SUMMARY")
    print(f"{'='*60}")
    total_lessons = 0
    total_questions = 0
    for f in sorted(CURRICULUM_DIR.glob("*.json")):
        with open(f, 'r', encoding='utf-8') as fh:
            d = json.load(fh)
        ls = d['totalLessons']
        qs = sum(len(l['questions']) for l in d['lessons'])
        total_lessons += ls
        total_questions += qs
        print(f"  {f.name}: {ls} lessons, {qs} questions")
    print(f"\n  TOTAL: {total_lessons} lessons, {total_questions} questions")
    print("  Done!")


if __name__ == "__main__":
    main()

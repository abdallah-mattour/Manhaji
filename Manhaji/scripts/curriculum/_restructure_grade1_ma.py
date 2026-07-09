# -*- coding: utf-8 -*-
"""
Book-fidelity restructure (2026-07-04): الرياضيات grade 1.

Aligns both semesters with the real book (PDFBooks/1Grade/الرياضيات,
unit openers extracted from the PDFs):

  Semester 1 (book units): الأعداد ١-٩ · مقارنة الأعداد ١-٩ (incl. العدد
  التالي/السابق + العدد الترتيبي — previously missing) · الجمع ضمن ٩ ·
  الطرح ضمن ٩ · الأعداد ١٠-٢٠ · القياس (الطول والزمن — previously sat in
  semester 2).

  Semester 2 (book units): مقارنة الأعداد ضمن ٢٠ (بما فيها القيمة المنزلية
  والصورة الموسعة — previously missing) · الجمع ضمن ١٨ · الطرح ضمن ١٨ ·
  الأعداد ضمن ٩٩ (تمثيل + ٣٠-٩٩ — previously missing) · الهندسة
  (الأشكال + المجسّمات — المجسّمات previously missing).

Existing off-book lessons (الأنماط، الوزن والسعة، النقود، مسائل كلامية)
are kept as trailing enrichment after the book units.

Also fixes the renamed الجمع/الطرح ضمن ٢٠ → ضمن ١٨ lessons: sums that used
٢٠ are rewritten within ١٨, and the word problem's currency becomes شيقل
(the book is Palestinian; ريال was wrong).

Idempotent: safe to re-run.
"""
from __future__ import annotations

import json

from _common import CURRICULUM_DIR, q, omoji

# ---------------------------------------------------------------------------
# New lessons (book topics we lacked)
# ---------------------------------------------------------------------------

NEXT_PREV = {
    "title": "العدد التالي والعدد السابق",
    "orderIndex": 6,
    "content": "العدد التالي هو العدد الذي يأتي بعد العدد مباشرة، والعدد السابق "
               "هو الذي يأتي قبله مباشرة ضمن الأعداد من ١ إلى ٩.",
    "objectives": "إيجاد العدد التالي والعدد السابق لعدد معطى ضمن ٩",
    "imageUrls": [omoji("four")],
    "questions": [
        q("MCQ", "ما العدد التالي للعدد ٤؟", "٥", ["٥", "٣", "٦", "٧"], 1, "computation"),
        q("MCQ", "ما العدد السابق للعدد ٧؟", "٦", ["٦", "٨", "٥", "٩"], 1, "computation"),
        q("MCQ", "عدده التالي ٩ وعدده السابق ٧، فما هو؟", "٨", ["٨", "٦", "٩", "٧"], 3, "application"),
        q("TRUE_FALSE", "العدد التالي للعدد ٥ هو ٦.", "صح", None, 1, "comprehension"),
        q("TRUE_FALSE", "العدد السابق للعدد ٣ هو ٤.", "خطأ", None, 2, "comprehension"),
        q("FILL_BLANK", "أكمل: العدد التالي للعدد ٨ هو ___.", "٩", None, 1, "computation"),
        q("FILL_BLANK", "أكمل: العدد السابق للعدد ٢ هو ___.", "١", None, 1, "computation"),
        q("SHORT_ANSWER", "اكتب العدد الذي يقع بين ٥ و ٧.", "٦", None, 2, "computation"),
        q("ORDERING", "رتّب: العدد السابق للعدد ٣، العدد ٣، العدد التالي للعدد ٣",
          "٢، ٣، ٤", ["٣", "٢", "٤"], 2, "application"),
        q("IMAGE_MCQ", "اختر صورة العدد التالي للعدد ٥", "٦",
          ["٦", "٤", "٧", "٥"], 2, "recognition",
          option_images=[omoji("six"), omoji("four"), omoji("seven"), omoji("five")]),
        q("DRAG_DROP", "صنّف الأعداد بالنسبة للعدد ٥: سابق أم تالٍ؟",
          "سابق للعدد ٥=٣,سابق للعدد ٥=٤,تالٍ للعدد ٥=٦,تالٍ للعدد ٥=٧",
          None, 2, "application",
          pairs={"targets": ["سابق للعدد ٥", "تالٍ للعدد ٥"],
                 "tokens": ["٣", "٦", "٤", "٧"]}),
        q("TRACING", "اكتب العدد التالي للعدد ٦ بخط جميل", "٧", None, 2, "handwriting"),
    ],
}

ORDINAL = {
    "title": "العدد الترتيبي",
    "orderIndex": 7,
    "content": "نستخدم الأعداد الترتيبية لبيان موقع الشيء: الأول، الثاني، "
               "الثالث، الرابع، الخامس.",
    "objectives": "استخدام الأعداد الترتيبية من الأول إلى الخامس",
    "imageUrls": [omoji("one")],
    "questions": [
        q("MCQ", "وقف أحمد بعد الطفل الأول مباشرة في الصف، فما ترتيبه؟", "الثاني",
          ["الثاني", "الأول", "الثالث", "الخامس"], 1, "comprehension"),
        q("MCQ", "ما الترتيب الذي يأتي بعد الثالث مباشرة؟", "الرابع",
          ["الرابع", "الثاني", "الخامس", "الأول"], 1, "computation"),
        q("MCQ", "في سباق الجري وصل سامر قبل الجميع، فما ترتيبه؟", "الأول",
          ["الأول", "الأخير", "الثالث", "الرابع"], 2, "application"),
        q("TRUE_FALSE", "الخامس يأتي بعد الرابع.", "صح", None, 1, "comprehension"),
        q("TRUE_FALSE", "الترتيب الثاني يعني آخر الصف.", "خطأ", None, 1, "comprehension"),
        q("FILL_BLANK", "أكمل الترتيب: الأول، الثاني، ___، الرابع.", "الثالث", None, 1, "computation"),
        q("SHORT_ANSWER", "اكتب الترتيب الذي يقع بين الرابع والسادس؟", "الخامس", None, 2, "computation"),
        q("ORDERING", "رتّب الكلمات الترتيبية: الثالث، الأول، الثاني",
          "الأول، الثاني، الثالث", ["الثالث", "الأول", "الثاني"], 2, "application"),
        q("MCQ", "خمسة أطفال في صف، رنا قبل الأخير مباشرة، فما ترتيبها؟", "الرابعة",
          ["الرابعة", "الثالثة", "الخامسة", "الثانية"], 3, "application"),
        q("DRAG_DROP", "صنّف: من الأعداد الترتيبية أم من أعداد العدّ؟",
          "أعداد ترتيبية=الأول,أعداد ترتيبية=الثالث,أعداد العدّ=٤,أعداد العدّ=٧",
          None, 2, "application",
          pairs={"targets": ["أعداد ترتيبية", "أعداد العدّ"],
                 "tokens": ["الأول", "٤", "الثالث", "٧"]}),
        q("PRONUNCIATION", "الأَوَّل", "الأَوَّل", None, 1, "pronunciation"),
        q("FILL_BLANK", "أكمل: يقف اللاعب ___ في بداية الصف قبل الجميع.", "الأول", None, 2, "production"),
    ],
}

CMP_20 = {
    "title": "مقارنة وترتيب الأعداد ضمن ٢٠",
    "orderIndex": 1,
    "content": "نقارن بين عددين ضمن ٢٠ باستخدام أكبر من وأصغر من ويساوي، "
               "ونرتب الأعداد تصاعدياً وتنازلياً.",
    "objectives": "مقارنة الأعداد ضمن ٢٠ وترتيبها تصاعدياً وتنازلياً",
    "imageUrls": [],
    "questions": [
        q("MCQ", "أي عدد أكبر: ١٧ أم ١٤؟", "١٧", ["١٧", "١٤", "متساويان", "١٠"], 1, "computation"),
        q("MCQ", "أي عدد أصغر: ١٩ أم ١٢؟", "١٢", ["١٢", "١٩", "متساويان", "٢٠"], 1, "computation"),
        q("MCQ", "أي مجموعة مرتبة تنازلياً؟", "٢٠، ١٥، ١١، ٦",
          ["٢٠، ١٥، ١١، ٦", "٦، ١١، ١٥، ٢٠", "١١، ٦، ٢٠، ١٥", "١٥، ٢٠، ٦، ١١"], 3, "application"),
        q("TRUE_FALSE", "العدد ١٦ أكبر من العدد ١٨.", "خطأ", None, 1, "comprehension"),
        q("TRUE_FALSE", "الترتيب التصاعدي يبدأ من الأصغر إلى الأكبر.", "صح", None, 1, "comprehension"),
        q("FILL_BLANK", "أكمل بإشارة أكبر أو أصغر: ١٣ ___ ١٩.", "أصغر", None, 2, "computation"),
        q("SHORT_ANSWER", "اكتب أكبر عدد مكوّن من: ١١، ١٧، ١٥.", "١٧", None, 1, "computation"),
        q("ORDERING", "رتّب الأعداد تصاعدياً: ١٦، ١٠، ١٩، ١٣",
          "١٠، ١٣، ١٦، ١٩", ["١٦", "١٠", "١٩", "١٣"], 2, "application"),
        q("ORDERING", "رتّب الأعداد تنازلياً: ١٢، ١٨، ١٤",
          "١٨، ١٤، ١٢", ["١٢", "١٨", "١٤"], 2, "application"),
        q("DRAG_DROP", "صنّف الأعداد بالنسبة للعدد ١٥: أصغر أم أكبر؟",
          "أصغر من ١٥=١١,أصغر من ١٥=١٣,أكبر من ١٥=١٧,أكبر من ١٥=١٩",
          None, 2, "application",
          pairs={"targets": ["أصغر من ١٥", "أكبر من ١٥"],
                 "tokens": ["١١", "١٧", "١٣", "١٩"]}),
        q("MCQ", "مع ليلى ١٤ قلماً ومع عمر ١٦ قلماً، مع من أقلام أكثر؟", "عمر",
          ["عمر", "ليلى", "متساويان", "لا نعرف"], 2, "application"),
        q("FILL_BLANK", "أكمل: العدد التالي للعدد ١٩ هو ___.", "٢٠", None, 2, "computation"),
    ],
}

PLACE_VALUE_20 = {
    "title": "القيمة المنزلية والصورة الموسعة ضمن ٢٠",
    "orderIndex": 2,
    "content": "العدد ضمن ٢٠ يتكوّن من آحاد وعشرات: العدد ١٧ فيه عشرة واحدة "
               "و٧ آحاد، وصورته الموسعة ١٠ + ٧.",
    "objectives": "تحليل الأعداد ضمن ٢٠ إلى عشرات وآحاد وكتابة الصورة الموسعة",
    "imageUrls": [],
    "questions": [
        q("MCQ", "كم عدد الآحاد في العدد ١٦؟", "٦", ["٦", "١", "١٦", "١٠"], 1, "computation"),
        q("MCQ", "كم عدد العشرات في العدد ١٤؟", "١", ["١", "٤", "١٤", "١٠"], 1, "computation"),
        q("MCQ", "ما الصورة الموسعة للعدد ١٨؟", "١٠ + ٨",
          ["١٠ + ٨", "٨ + ٨", "١٠ + ١", "١٨ + ٠"], 2, "computation"),
        q("TRUE_FALSE", "العدد ١٣ يتكوّن من عشرة واحدة و٣ آحاد.", "صح", None, 1, "comprehension"),
        q("TRUE_FALSE", "الصورة الموسعة للعدد ١٥ هي ٥ + ١.", "خطأ", None, 2, "comprehension"),
        q("FILL_BLANK", "أكمل الصورة الموسعة: ١٢ = ١٠ + ___.", "٢", None, 1, "computation"),
        q("FILL_BLANK", "أكمل: العدد المكوّن من عشرة واحدة و٩ آحاد هو ___.", "١٩", None, 2, "computation"),
        q("SHORT_ANSWER", "اكتب العدد الذي صورته الموسعة ١٠ + ٥.", "١٥", None, 1, "computation"),
        q("ORDERING", "رتّب خطوات تحليل العدد ١٧: نكتب ١٠ + ٧، نحدد العشرات، نحدد الآحاد",
          "نحدد العشرات، نحدد الآحاد، نكتب ١٠ + ٧",
          ["نكتب ١٠ + ٧", "نحدد العشرات", "نحدد الآحاد"], 3, "application"),
        q("IMAGE_MATCH", "صِل العدد بصورته الموسعة", "1=a,2=b,3=c", None, 2, "computation",
          pairs={"left": [{"id": "1", "text": "١١"}, {"id": "2", "text": "١٦"}, {"id": "3", "text": "٢٠"}],
                 "right": [{"id": "a", "text": "١٠ + ١"}, {"id": "b", "text": "١٠ + ٦"}, {"id": "c", "text": "١٠ + ١٠"}]}),
        q("MCQ", "عددان مجموع آحادهما ٥ وعشرات كل منهما ١، أيهما أكبر: ١٤ أم ١١؟", "١٤",
          ["١٤", "١١", "متساويان", "٥١"], 3, "application"),
        q("TRACING", "اكتب العدد ١٥ بخط جميل", "١٥", None, 1, "handwriting"),
    ],
}

REPRESENT_99 = {
    "title": "تمثيل الأعداد ضمن ٩٩",
    "orderIndex": 6,
    "content": "نمثل الأعداد ضمن ٩٩ بالعشرات والآحاد: العدد ٤٣ هو ٤ عشرات "
               "و٣ آحاد، وصورته الموسعة ٤٠ + ٣.",
    "objectives": "تمثيل الأعداد ضمن ٩٩ بالعشرات والآحاد وقراءتها",
    "imageUrls": [],
    "questions": [
        q("MCQ", "العدد المكوّن من ٥ عشرات و٢ آحاد هو:", "٥٢",
          ["٥٢", "٢٥", "٥٠٢", "٧"], 1, "computation"),
        q("MCQ", "كم عشرة في العدد ٧٠؟", "٧", ["٧", "٠", "٧٠", "١٧"], 1, "computation"),
        q("MCQ", "ما الصورة الموسعة للعدد ٦٤؟", "٦٠ + ٤",
          ["٦٠ + ٤", "٦ + ٤", "٤٠ + ٦", "٦٤ + ٠"], 2, "computation"),
        q("TRUE_FALSE", "العدد ٣٨ فيه ٣ عشرات و٨ آحاد.", "صح", None, 1, "comprehension"),
        q("TRUE_FALSE", "العدد ٩٠ فيه ٩ آحاد.", "خطأ", None, 2, "comprehension"),
        q("FILL_BLANK", "أكمل: ٥٧ = ٥٠ + ___.", "٧", None, 1, "computation"),
        q("FILL_BLANK", "أكمل: العدد المكوّن من ٨ عشرات و٦ آحاد هو ___.", "٨٦", None, 2, "computation"),
        q("SHORT_ANSWER", "اكتب العدد الذي صورته الموسعة ٣٠ + ٩.", "٣٩", None, 1, "computation"),
        q("ORDERING", "رتّب الأعداد حسب عدد عشراتها من الأقل إلى الأكثر: ٧١، ٢٥، ٤٨",
          "٢٥، ٤٨، ٧١", ["٧١", "٢٥", "٤٨"], 3, "application"),
        q("IMAGE_MATCH", "صِل العدد بتحليله الصحيح", "1=a,2=b,3=c", None, 2, "computation",
          pairs={"left": [{"id": "1", "text": "٢٩"}, {"id": "2", "text": "٩٢"}, {"id": "3", "text": "٢٢"}],
                 "right": [{"id": "a", "text": "٢٠ + ٩"}, {"id": "b", "text": "٩٠ + ٢"}, {"id": "c", "text": "٢٠ + ٢"}]}),
        q("DRAG_DROP", "صنّف الأعداد: أقل من ٥٠ أم أكثر من ٥٠؟",
          "أقل من ٥٠=٣٤,أقل من ٥٠=٤٩,أكثر من ٥٠=٦٢,أكثر من ٥٠=٨٥",
          None, 2, "application",
          pairs={"targets": ["أقل من ٥٠", "أكثر من ٥٠"],
                 "tokens": ["٣٤", "٦٢", "٤٩", "٨٥"]}),
        q("TRACING", "اكتب العدد ٤٣ بخط جميل", "٤٣", None, 1, "handwriting"),
    ],
}

NUMBERS_30_99 = {
    "title": "الأعداد من ٣٠ إلى ٩٩",
    "orderIndex": 7,
    "content": "نقرأ الأعداد من ٣٠ إلى ٩٩ ونكتبها ونعدّ بالعشرات: "
               "٣٠، ٤٠، ٥٠، ٦٠، ٧٠، ٨٠، ٩٠.",
    "objectives": "قراءة الأعداد حتى ٩٩ وكتابتها والعد بالعشرات",
    "imageUrls": [],
    "questions": [
        q("MCQ", "ما العدد الذي يُقرأ (خمسة وسبعون)؟", "٧٥",
          ["٧٥", "٥٧", "٧٠", "٥٥"], 1, "recognition"),
        q("MCQ", "أكمل العد بالعشرات: ٣٠، ٤٠، ٥٠، ...", "٦٠",
          ["٦٠", "٥٥", "٧٠", "٥١"], 1, "computation"),
        q("MCQ", "ما العدد الواقع بين ٥٩ و ٦١؟", "٦٠", ["٦٠", "٥٨", "٦٢", "٥٠"], 2, "computation"),
        q("TRUE_FALSE", "العدد ٩٩ هو أكبر عدد مكوّن من رقمين.", "صح", None, 2, "comprehension"),
        q("TRUE_FALSE", "بعد العدد ٧٩ يأتي العدد ٧٠.", "خطأ", None, 1, "comprehension"),
        q("FILL_BLANK", "أكمل: ٨٧، ٨٨، ٨٩، ___.", "٩٠", None, 1, "computation"),
        q("FILL_BLANK", "أكمل العد بالعشرات: ٦٠، ٧٠، ___، ٩٠.", "٨٠", None, 1, "computation"),
        q("SHORT_ANSWER", "اكتب العدد التالي للعدد ٦٥.", "٦٦", None, 1, "computation"),
        q("ORDERING", "رتّب الأعداد تصاعدياً: ٨٤، ٣٧، ٥٩، ٩١",
          "٣٧، ٥٩، ٨٤، ٩١", ["٨٤", "٣٧", "٥٩", "٩١"], 2, "application"),
        q("MCQ", "صف فيه ٤ مجموعات في كل منها ١٠ طلاب و٣ طلاب زيادة، كم طالباً في الصف؟",
          "٤٣", ["٤٣", "٣٤", "٤٠", "١٣"], 3, "application"),
        q("DRAG_DROP", "صنّف الأعداد: من عائلة الخمسينات أم من عائلة التسعينات؟",
          "الخمسينات=٥٢,الخمسينات=٥٨,التسعينات=٩١,التسعينات=٩٧",
          None, 2, "application",
          pairs={"targets": ["الخمسينات", "التسعينات"],
                 "tokens": ["٥٢", "٩١", "٥٨", "٩٧"]}),
        q("PRONUNCIATION", "تِسْعَةٌ وَتِسْعُونَ", "تِسْعَةٌ وَتِسْعُونَ", None, 2, "pronunciation"),
    ],
}

SOLIDS = {
    "title": "المجسّمات",
    "orderIndex": 9,
    "content": "من المجسّمات: المكعب، متوازي المستطيلات، الكرة. المكعب أوجهه "
               "مربعة، والكرة تتدحرج.",
    "objectives": "التعرف إلى المكعب ومتوازي المستطيلات والكرة",
    "imageUrls": [omoji("soccer_ball")],
    "questions": [
        q("MCQ", "أي مجسّم يشبه كرة القدم؟", "الكرة",
          ["الكرة", "المكعب", "متوازي المستطيلات", "المثلث"], 1, "recognition"),
        q("MCQ", "المجسّم الذي كل أوجهه مربعات هو:", "المكعب",
          ["المكعب", "الكرة", "متوازي المستطيلات", "الدائرة"], 2, "recognition"),
        q("MCQ", "علبة الحليب تشبه:", "متوازي المستطيلات",
          ["متوازي المستطيلات", "الكرة", "الدائرة", "المثلث"], 2, "application"),
        q("TRUE_FALSE", "الكرة تتدحرج على الأرض.", "صح", None, 1, "comprehension"),
        q("TRUE_FALSE", "المكعب يتدحرج مثل الكرة.", "خطأ", None, 2, "comprehension"),
        q("FILL_BLANK", "أكمل: مكعب النرد كل أوجهه ___.", "مربعات", None, 2, "production"),
        q("SHORT_ANSWER", "اكتب اسم المجسّم الذي يشبه البرتقالة.", "الكرة", None, 1, "production"),
        q("ORDERING", "رتّب حسب قدرتها على التدحرج من الأسهل إلى الأصعب: المكعب، الكرة، متوازي المستطيلات",
          "الكرة، متوازي المستطيلات، المكعب",
          ["المكعب", "الكرة", "متوازي المستطيلات"], 3, "application"),
        q("IMAGE_MCQ", "أي صورة تشبه شكل الكرة؟", "كرة القدم",
          ["كرة القدم", "هدية", "كتاب", "مسطرة"], 1, "recognition",
          option_images=[omoji("soccer_ball"), omoji("gift"), omoji("book"), omoji("ruler")]),
        q("DRAG_DROP", "صنّف: مجسّم أم شكل مستوٍ؟",
          "مجسّم=المكعب,مجسّم=الكرة,شكل مستوٍ=المربع,شكل مستوٍ=الدائرة",
          None, 3, "application",
          pairs={"targets": ["مجسّم", "شكل مستوٍ"],
                 "tokens": ["المكعب", "المربع", "الكرة", "الدائرة"]}),
        q("IMAGE_MATCH", "صِل المجسّم بالشيء الذي يشبهه", "1=a,2=b,3=c", None, 2, "recognition",
          pairs={"left": [{"id": "1", "text": "الكرة"}, {"id": "2", "text": "متوازي المستطيلات"}, {"id": "3", "text": "المكعب"}],
                 "right": [{"id": "a", "image": omoji("basketball")}, {"id": "b", "image": omoji("books")}, {"id": "c", "image": omoji("gift")}]}),
        q("PRONUNCIATION", "المُكَعَّب", "المُكَعَّب", None, 1, "pronunciation"),
    ],
}

# ---------------------------------------------------------------------------
# Target structure (book order). Titles must exist after the moves/renames.
# ---------------------------------------------------------------------------

P1_ORDER = [
    "الأعداد ١-٥", "الأعداد ٦-٩", "العدد صفر",
    "مقارنة الأعداد", "ترتيب الأعداد",
    "العدد التالي والعدد السابق", "العدد الترتيبي",
    "مكونات الأعداد",
    "الجمع ضمن ٥", "الجمع ضمن ٩",
    "الطرح ضمن ٥", "الطرح ضمن ٩", "مراجعة الجمع والطرح",
    "العدد ١٠", "الأعداد ١١-١٥", "الأعداد ١٦-٢٠",
    "القياس والطول", "الوقت والساعة",
    "مراجعة شاملة",
]

P2_ORDER = [
    "مقارنة وترتيب الأعداد ضمن ٢٠", "القيمة المنزلية والصورة الموسعة ضمن ٢٠",
    "الجمع ضمن ١٨", "الطرح ضمن ١٨", "حقائق الجمع والطرح",
    "تمثيل الأعداد ضمن ٩٩", "الأعداد من ٣٠ إلى ٩٩",
    "الأشكال الهندسية", "المجسّمات",
    # trailing enrichment (off-book but pedagogically useful)
    "الأنماط", "الوزن والسعة", "النقود", "مسائل كلامية",
    "مراجعة نهائية",
]

RENAMES_P2 = {"الجمع ضمن ٢٠": "الجمع ضمن ١٨", "الطرح ضمن ٢٠": "الطرح ضمن ١٨"}

# Stems in the renamed lessons that exceed ١٨ (or use the wrong currency).
STEM_FIXES = {
    "أكمل: ١٢ + ___ = ٢٠": {"questionText": "أكمل: ١٢ + ___ = ١٨", "correctAnswer": "٦"},
    "٢٠ - ١٠ = ١٠": {"questionText": "١٦ - ٨ = ٨", "correctAnswer": "صح"},
    "٢٠ - ٧ = ؟": {"questionText": "١٧ - ٩ = ؟", "correctAnswer": "٨",
                    "options": ["٨", "٩", "٧", "٦"]},
    # Second key covers re-runs after the stem was already rewritten.
    "١٧ - ٩ = ؟": {"correctAnswer": "٨", "options": ["٨", "٩", "٧", "٦"]},
    "كان مع ريم ٢٠ ريالاً، اشترت لعبة بـ ٧ ريالات وكتاباً بـ ٥. كم بقي؟":
        {"questionText": "كان مع ريم ١٨ شيقلاً، اشترت لعبة بـ ٧ شواقل وكتاباً بـ ٥. كم بقي معها؟",
         "correctAnswer": "٦"},
}


def _load(stem):
    with (CURRICULUM_DIR / f"{stem}.json").open(encoding="utf-8") as f:
        return json.load(f)


def _save(stem, data):
    data["totalLessons"] = len(data["lessons"])
    with (CURRICULUM_DIR / f"{stem}.json").open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def main() -> None:
    p1 = _load("ma1_p1")
    p2 = _load("ma1_p2")

    by1 = {l["title"]: l for l in p1["lessons"]}
    by2 = {l["title"]: l for l in p2["lessons"]}

    # 1. Renames in p2 (with in-lesson stem fixes).
    for old, new in RENAMES_P2.items():
        lesson = by2.pop(old, None) or by2.get(new)
        if lesson is None:
            continue
        lesson["title"] = new
        lesson["content"] = lesson.get("content", "").replace("ضمن ٢٠", "ضمن ١٨")
        lesson["objectives"] = lesson.get("objectives", "").replace("ضمن ٢٠", "ضمن ١٨")
        for qq in lesson.get("questions", []):
            fix = STEM_FIXES.get(qq.get("questionText"))
            if fix:
                qq.update(fix)
        by2[new] = lesson

    # 2. Move القياس lessons from p2 to p1 (book: unit 6 of semester 1).
    for title in ("القياس والطول", "الوقت والساعة"):
        lesson = by2.pop(title, None)
        if lesson is not None and title not in by1:
            by1[title] = lesson

    # 3. Insert the new book-topic lessons.
    for lesson in (NEXT_PREV, ORDINAL):
        by1.setdefault(lesson["title"], lesson)
    for lesson in (CMP_20, PLACE_VALUE_20, REPRESENT_99, NUMBERS_30_99, SOLIDS):
        by2.setdefault(lesson["title"], lesson)

    # 4. Rebuild lesson lists in book order (unknown leftovers keep trailing).
    def ordered(by, order):
        out = [by[t] for t in order if t in by]
        leftovers = [l for t, l in by.items() if t not in order]
        out.extend(leftovers)
        for i, l in enumerate(out, start=1):
            l["orderIndex"] = i
        return out

    p1["lessons"] = ordered(by1, P1_ORDER)
    p2["lessons"] = ordered(by2, P2_ORDER)

    _save("ma1_p1", p1)
    _save("ma1_p2", p2)
    print(f"ma1_p1: {len(p1['lessons'])} lessons "
          f"({sum(len(l['questions']) for l in p1['lessons'])} questions)")
    print(f"ma1_p2: {len(p2['lessons'])} lessons "
          f"({sum(len(l['questions']) for l in p2['lessons'])} questions)")


if __name__ == "__main__":
    main()

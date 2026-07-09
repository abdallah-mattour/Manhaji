# -*- coding: utf-8 -*-
"""
Phase 3 (2026-07-04) — media-type enrichment for Grades 1-2.

Adds the tier-1/2/4 interactive question types (IMAGE_MCQ, LISTEN_CHOOSE,
IMAGE_MATCH, DRAG_DROP, READING) across all 16 grade-1/2 curriculum files,
plus topical OpenMoji lesson illustrations for teaching cards. Before this
pass grade 2 had ZERO media types and grade 1 had them only in en1_p1.

The dicts below are the canonical content source (same convention as the
`_backfill_*.py` scripts). The script is idempotent:
  * a question is inserted only if no (type, questionText) match exists;
  * lesson imageUrls are (re)written from LESSON_IMAGES only when the lesson
    currently has no images or holds a stale value.

Run directly (`python _enrich_media_g12.py`) after editing content here.
`build_grade2.py` also calls `main()` after regenerating the grade-2 files so
a rebuild never loses the enrichment.

Verify with:  ./gradlew test --tests '*QuestionAuditTest*'
"""
from __future__ import annotations

import json
import random
from typing import Any

from _common import CURRICULUM_DIR, q, omoji


def _match(pairs_left: list[tuple[str, str | None]],
           pairs_right: list[tuple[str, str | None]]) -> dict[str, Any]:
    """Build IMAGE_MATCH `pairs` from (text, image) tuples; ids are 1..n / a..z
    and the correct mapping is positional (1=a, 2=b, ...)."""
    left = []
    right = []
    for i, (text, image) in enumerate(pairs_left, start=1):
        item: dict[str, Any] = {"id": str(i), "text": text}
        if image:
            item["image"] = image
        left.append(item)
    for i, (text, image) in enumerate(pairs_right):
        item = {"id": chr(ord("a") + i), "text": text}
        if image:
            item["image"] = image
        right.append(item)
    return {"left": left, "right": right}


def _match_answer(n: int) -> str:
    return ",".join(f"{i + 1}={chr(ord('a') + i)}" for i in range(n))


# ---------------------------------------------------------------------------
# New questions per file → lesson title → [question dicts]
# ---------------------------------------------------------------------------

NEW_QUESTIONS: dict[str, dict[str, list[dict[str, Any]]]] = {

    # ================= GRADE 1 — ARABIC =================
    "ar1_p1": {
        "حرف الدال": [
            q("IMAGE_MCQ", "أيّ صورة تبدأ بحرف الدال؟", "دجاجة",
              ["دجاجة", "بقرة", "خروف", "حصان"], 1, "recognition",
              option_images=[omoji("chicken"), omoji("cow"), omoji("sheep"), omoji("horse")]),
        ],
        "حرف الباء": [
            q("IMAGE_MCQ", "اختر صورة الكلمة التي تبدأ بحرف الباء", "بيت",
              ["بيت", "شجرة", "قمر", "سمكة"], 1, "recognition",
              option_images=[omoji("house"), omoji("tree"), omoji("moon"), omoji("fish")]),
        ],
        "مراجعة (١)": [
            q("IMAGE_MCQ", "أين صورة الحيوان الذي يبدأ اسمه بحرف الدال؟", "دب",
              ["دب", "قطة", "أسد", "سمكة"], 2, "recognition",
              option_images=[omoji("bear"), omoji("cat"), omoji("lion"), omoji("fish")]),
        ],
        "مراجعة (٢)": [
            q("DRAG_DROP", "صنّف الكلمات حسب حرفها الأول",
              "بحرف الميم=موز,بحرف الميم=مسجد,بحرف السين=سمكة,بحرف السين=سحابة",
              None, 2, "application",
              pairs={"targets": ["بحرف الميم", "بحرف السين"],
                     "tokens": ["موز", "سمكة", "مسجد", "سحابة"]}),
        ],
        "مراجعة (٣)": [
            q("IMAGE_MATCH", "صِل الكلمة بالصورة المناسبة", _match_answer(3),
              None, 2, "recognition",
              pairs=_match([("حِصان", None), ("زَهْرَة", None), ("حَليب", None)],
                           [("", omoji("horse")), ("", omoji("rose")), ("", omoji("milk"))])),
        ],
        "مراجعة (٤)": [
            q("IMAGE_MCQ", "أين صورة الجَمَل؟", "جَمَل",
              ["جَمَل", "فيل", "قِطّة", "فَراشة"], 1, "recognition",
              option_images=[omoji("camel"), omoji("elephant"), omoji("cat"), omoji("butterfly")]),
        ],
        "مراجعة (٥)": [
            q("DRAG_DROP", "ضَعْ كلَّ كلمةٍ مع حرفها الأوّل",
              "حرف العين=عصفور,حرف العين=عنب,حرف الشين=شجرة,حرف الشين=شمعة",
              None, 2, "application",
              pairs={"targets": ["حرف العين", "حرف الشين"],
                     "tokens": ["عصفور", "شجرة", "عنب", "شمعة"]}),
        ],
        "مراجعة (٦)": [
            q("READING", "أَنَا أُحِبُّ وَطَني فِلَسْطين", "أَنَا أُحِبُّ وَطَني فِلَسْطين",
              None, 3, "reading"),
        ],
    },

    "ar1_p2": {
        "حرف الكاف": [
            q("IMAGE_MCQ", "أين صورة الكلب؟", "كلب",
              ["كلب", "قطة", "أسد", "دب"], 1, "recognition",
              option_images=[omoji("dog"), omoji("cat"), omoji("lion"), omoji("bear")]),
        ],
        "حرف الهاء": [
            q("IMAGE_MCQ", "أيّ صورة تبدأ بحرف الهاء؟", "هدية",
              ["هدية", "كتاب", "قلم", "كرة"], 1, "recognition",
              option_images=[omoji("gift"), omoji("book"), omoji("pencil"), omoji("soccer_ball")]),
        ],
        "مراجعة (١)": [
            q("DRAG_DROP", "صنّف الكلمات: حيوانات أم طعام؟",
              "حيوانات=أرنب,حيوانات=سلحفاة,طعام=خبز,طعام=جبنة",
              None, 2, "application",
              pairs={"targets": ["حيوانات", "طعام"],
                     "tokens": ["أرنب", "خبز", "سلحفاة", "جبنة"]}),
        ],
        "مراجعة (٢)": [
            q("IMAGE_MATCH", "صِلْ كلَّ كلمةٍ بصورتها", _match_answer(3),
              None, 2, "recognition",
              pairs=_match([("وَرْدَة", None), ("يَد", None), ("هاتِف", None)],
                           [("", omoji("rose")), ("", omoji("hand")), ("", omoji("phone"))])),
        ],
        "نساعد الكبير": [
            q("READING", "أُساعِدُ جَدّي وَجَدَّتي كُلَّ يَوْم", "أُساعِدُ جَدّي وَجَدَّتي كُلَّ يَوْم",
              None, 2, "reading"),
        ],
        "وطني أجمل": [
            q("READING", "فِلَسْطينُ وَطَني الجَميلُ الغالي", "فِلَسْطينُ وَطَني الجَميلُ الغالي",
              None, 2, "reading"),
        ],
        "الماء": [
            q("READING", "الماءُ سِرُّ الحَياةِ فَلا نُسْرِفُ فيه", "الماءُ سِرُّ الحَياةِ فَلا نُسْرِفُ فيه",
              None, 3, "reading"),
        ],
    },

    # ================= GRADE 1 — ENGLISH =================
    # ================= GRADE 1 — MATH =================
    "ma1_p1": {
        "الوقت والساعة": [
            q("IMAGE_MCQ", "أي صورة تدل على الساعة؟", "ساعة",
              ["ساعة", "مفتاح", "هاتف", "مصباح"], 1, "recognition",
              option_images=[omoji("clock"), omoji("key"), omoji("phone"), omoji("bulb")]),
        ],
        "الأعداد ١-٥": [
            q("IMAGE_MCQ", "أيُّ صورةٍ تُمثِّل العدد ثلاثة؟", "٣",
              ["٣", "١", "٥", "٢"], 1, "recognition",
              option_images=[omoji("three"), omoji("one"), omoji("five"), omoji("two")]),
        ],
        "الأعداد ٦-٩": [
            q("IMAGE_MCQ", "اختر صورة العدد سبعة", "٧",
              ["٧", "٦", "٨", "٩"], 1, "recognition",
              option_images=[omoji("seven"), omoji("six"), omoji("eight"), omoji("nine")]),
        ],
        "العدد صفر": [
            q("IMAGE_MCQ", "أين صورة العدد صفر؟", "٠",
              ["٠", "١٠", "١", "٨"], 1, "recognition",
              option_images=[omoji("zero"), omoji("ten"), omoji("one"), omoji("eight")]),
        ],
        "مقارنة الأعداد": [
            q("DRAG_DROP", "صنّف الأعداد: أصغر من ٥ أم أكبر من ٥؟",
              "أصغر من ٥=٢,أصغر من ٥=٣,أكبر من ٥=٧,أكبر من ٥=٩",
              None, 2, "application",
              pairs={"targets": ["أصغر من ٥", "أكبر من ٥"],
                     "tokens": ["٢", "٧", "٣", "٩"]}),
        ],
        "العدد ١٠": [
            q("IMAGE_MATCH", "صِل اسم العدد بصورته", _match_answer(3),
              None, 2, "recognition",
              pairs=_match([("عشرة", None), ("خمسة", None), ("صفر", None)],
                           [("", omoji("ten")), ("", omoji("five")), ("", omoji("zero"))])),
        ],
        "مراجعة شاملة": [
            q("DRAG_DROP", "صنّف نواتج العمليات: تساوي ٥ أم تساوي ١٠؟",
              "تساوي ٥=٢+٣,تساوي ٥=١+٤,تساوي ١٠=٦+٤,تساوي ١٠=٥+٥",
              None, 3, "application",
              pairs={"targets": ["تساوي ٥", "تساوي ١٠"],
                     "tokens": ["٢+٣", "٦+٤", "١+٤", "٥+٥"]}),
        ],
    },

    "ma1_p2": {
        "الأشكال الهندسية": [
            q("IMAGE_MCQ", "أيُّ صورةٍ تُظهر مثلثاً؟", "مثلث",
              ["مثلث", "دائرة", "مربع", "معين"], 1, "recognition",
              option_images=[omoji("triangle"), omoji("circle_red"), omoji("square_blue"), omoji("diamond")]),
            q("IMAGE_MATCH", "صِل كل شكل هندسي بصورته الصحيحة", _match_answer(3),
              None, 2, "recognition",
              pairs=_match([("دائرة حمراء", None), ("مربع أزرق", None), ("معين برتقالي", None)],
                           [("", omoji("circle_red")), ("", omoji("square_blue")), ("", omoji("diamond"))])),
        ],
        "مراجعة نهائية": [
            q("DRAG_DROP", "صنّف العمليات: جمع أم طرح؟",
              "جمع=٣+٢,جمع=٥+٥,طرح=٧-٤,طرح=٩-٦",
              None, 3, "application",
              pairs={"targets": ["جمع", "طرح"],
                     "tokens": ["٣+٢", "٧-٤", "٥+٥", "٩-٦"]}),
        ],
    },

    # ================= GRADE 1 — RELIGION =================
    "re1_p1": {
        "سورة الفاتحة": [
            q("READING", "بِسْمِ اللهِ الرَّحْمنِ الرَّحيمِ", "بِسْمِ اللهِ الرَّحْمنِ الرَّحيمِ",
              None, 2, "recitation"),
        ],
        "أحب خالقي": [
            q("IMAGE_MCQ", "اختر صورة النعمة التي نشربها", "الماء",
              ["الماء", "الكرسي", "المفتاح", "القلم"], 1, "comprehension",
              option_images=[omoji("water"), omoji("chair"), omoji("key"), omoji("pencil")]),
        ],
        "سورة الناس": [
            q("READING", "قُلْ أَعوذُ بِرَبِّ النّاسِ", "قُلْ أَعوذُ بِرَبِّ النّاسِ",
              None, 2, "recitation"),
        ],
        "أسرتي": [
            q("READING", "أُطيعُ أُمّي وَأَبي وَأَدْعو لَهُما", "أُطيعُ أُمّي وَأَبي وَأَدْعو لَهُما",
              None, 2, "reading"),
        ],
        "مراجعة عامة": [
            q("READING", "أَنا مُسْلِمٌ أَقولُ الصِّدْقَ دائِماً", "أَنا مُسْلِمٌ أَقولُ الصِّدْقَ دائِماً",
              None, 3, "reading"),
        ],
    },

    "re1_p2": {
        "الوضوء": [
            q("DRAG_DROP", "صنّف: من أعمال الوضوء أم من أعمال الصلاة؟",
              "من الوضوء=غسل اليدين,من الوضوء=المضمضة,من الصلاة=الركوع,من الصلاة=السجود",
              None, 2, "application",
              pairs={"targets": ["من الوضوء", "من الصلاة"],
                     "tokens": ["غسل اليدين", "الركوع", "المضمضة", "السجود"]}),
        ],
        "آداب الطعام": [
            q("DRAG_DROP", "صنّف: من آداب الطعام أم من آداب النظافة؟",
              "آداب الطعام=التسمية قبل الأكل,آداب الطعام=الأكل باليمين,آداب النظافة=غسل اليدين بالصابون,آداب النظافة=تقليم الأظافر",
              None, 2, "application",
              pairs={"targets": ["آداب الطعام", "آداب النظافة"],
                     "tokens": ["التسمية قبل الأكل", "غسل اليدين بالصابون", "الأكل باليمين", "تقليم الأظافر"]}),
        ],
        "الرفق بالحيوان": [
            q("IMAGE_MCQ", "اختر صورة الحيوان الذي سقاه الرجل فغفر الله له", "كلب",
              ["كلب", "أسد", "قرد", "سلحفاة"], 2, "comprehension",
              option_images=[omoji("dog"), omoji("lion"), omoji("monkey"), omoji("turtle")]),
        ],
        "مراجعة عامة": [
            q("IMAGE_MATCH", "صِل كل مكانٍ بما نفعله فيه", _match_answer(3),
              None, 3, "application",
              pairs=_match([("المسجد", omoji("mosque")), ("البيت", omoji("house")), ("المدرسة", omoji("school"))],
                           [("نُصلّي فيه", None), ("ننام فيه", None), ("نتعلّم فيه", None)])),
        ],
    },

    # ================= GRADE 2 — ARABIC =================
    "ar2_p1": {
        "الغراب والجرّة": [
            q("READING", "عَطِشَ الغُرابُ فَبَحَثَ عَنِ الماءِ في كُلِّ مَكانٍ",
              "عَطِشَ الغُرابُ فَبَحَثَ عَنِ الماءِ في كُلِّ مَكانٍ", None, 2, "reading"),
        ],
        "الأسد والفأر": [
            q("READING", "عَفا الأَسَدُ عَنِ الفَأْرِ الصَّغيرِ فَأَنْقَذَهُ يَوْماً",
              "عَفا الأَسَدُ عَنِ الفَأْرِ الصَّغيرِ فَأَنْقَذَهُ يَوْماً", None, 2, "reading"),
        ],
        "مصنع الألبان": [
            q("IMAGE_MCQ", "أيُّ صورةٍ تُظهر منتجاً مصنوعاً من الحليب؟", "جبنة",
              ["جبنة", "خبز", "تفاحة", "عسل"], 1, "recognition",
              option_images=[omoji("cheese"), omoji("bread"), omoji("apple"), omoji("honey")]),
        ],
        "الخروف والذئب": [
            q("IMAGE_MCQ", "اختر صورة الحيوان الأليف في القصة", "خروف",
              ["خروف", "أسد", "قرد", "ضفدع"], 1, "recognition",
              option_images=[omoji("sheep"), omoji("lion"), omoji("monkey"), omoji("frog")]),
        ],
        "عودة الطائر": [
            q("IMAGE_MATCH", "صِل الكائن بمكان عيشه", _match_answer(3),
              None, 3, "application",
              pairs=_match([("العصفور", omoji("bird")), ("السمكة", omoji("fish")), ("الأرنب", omoji("rabbit"))],
                           [("الشجرة", None), ("الماء", None), ("الحقل", None)])),
        ],
        "النظافة": [
            q("DRAG_DROP", "صنّف الأدوات: للنظافة أم للدراسة؟",
              "للنظافة=صابون,للنظافة=منشفة,للدراسة=قلم رصاص,للدراسة=مسطرة",
              None, 2, "application",
              pairs={"targets": ["للنظافة", "للدراسة"],
                     "tokens": ["صابون", "قلم رصاص", "منشفة", "مسطرة"]}),
        ],
    },

    "ar2_p2": {
        "النمر والحطّاب": [
            q("IMAGE_MATCH", "صِل الكلمة بضدّها", _match_answer(3),
              None, 3, "application",
              pairs=_match([("قَوِيّ", None), ("كَبير", None), ("سَريع", None)],
                           [("ضَعيف", None), ("صَغير", None), ("بَطيء", None)])),
        ],
        "العصفورة والأفعى": [
            q("IMAGE_MCQ", "اختر صورة الطائر الذي بنى العُشّ", "عصفور",
              ["عصفور", "بقرة", "حصان", "ماعز"], 1, "recognition",
              option_images=[omoji("bird"), omoji("cow"), omoji("horse"), omoji("goat")]),
        ],
        "في مدينة الخليل": [
            q("READING", "زُرْتُ مَدينَةَ الخَليلِ مَعَ عائِلَتي يَوْمَ الجُمُعَةِ",
              "زُرْتُ مَدينَةَ الخَليلِ مَعَ عائِلَتي يَوْمَ الجُمُعَةِ", None, 2, "reading"),
        ],
        "صباح جديد": [
            q("READING", "أَسْتَيْقِظُ صَباحاً وَأَغْسِلُ وَجْهي ثُمَّ أَتَناوَلُ فُطوري",
              "أَسْتَيْقِظُ صَباحاً وَأَغْسِلُ وَجْهي ثُمَّ أَتَناوَلُ فُطوري", None, 3, "reading"),
        ],
        "والدي الحبيب": [
            q("READING", "أَبي يَعْمَلُ بِجِدٍّ مِنْ أَجْلِنا فَأَنا أُحِبُّهُ كَثيراً",
              "أَبي يَعْمَلُ بِجِدٍّ مِنْ أَجْلِنا فَأَنا أُحِبُّهُ كَثيراً", None, 2, "reading"),
        ],
        "في البقّالة": [
            q("DRAG_DROP", "صنّف المشتريات: فواكه أم مشروبات؟",
              "فواكه=بطيخ,فواكه=خوخ,مشروبات=حليب,مشروبات=شاي",
              None, 2, "application",
              pairs={"targets": ["فواكه", "مشروبات"],
                     "tokens": ["بطيخ", "حليب", "خوخ", "شاي"]}),
        ],
    },

    # ================= GRADE 2 — ENGLISH =================
    "en2_p1": {
        "Hi, I'm ... (Unit 1)": [
            q("READING", "Hello, my name is Omar", "Hello, my name is Omar",
              None, 2, "reading"),
        ],
        "In the kitchen (Unit 2)": [
            q("IMAGE_MCQ", "Which picture shows an egg?", "Egg",
              ["Egg", "Cheese", "Bread", "Rice"], 1, "recognition",
              option_images=[omoji("egg"), omoji("cheese"), omoji("bread"), omoji("rice")]),
        ],
        "In the garden (Unit 3)": [
            q("LISTEN_CHOOSE", "Butterfly", "Butterfly",
              ["Butterfly", "Bee", "Bird", "Frog"], 1, "recognition",
              option_images=[omoji("butterfly"), omoji("bee"), omoji("bird"), omoji("frog")]),
        ],
        "My body (Unit 4)": [
            q("IMAGE_MATCH", "Match each body word to its picture", _match_answer(3),
              None, 2, "recognition",
              pairs=_match([("Tooth", None), ("Foot", None), ("Hand", None)],
                           [("", omoji("tooth")), ("", omoji("foot")), ("", omoji("hand"))])),
        ],
        "My home (Unit 7)": [
            q("DRAG_DROP", "Sort the things: bedroom or kitchen?",
              "Bedroom=Bed,Bedroom=Teddy bear,Kitchen=Cheese,Kitchen=Soup",
              None, 2, "application",
              pairs={"targets": ["Bedroom", "Kitchen"],
                     "tokens": ["Bed", "Cheese", "Teddy bear", "Soup"]}),
        ],
        "My town (Unit 8)": [
            q("IMAGE_MCQ", "Which picture shows a school?", "School",
              ["School", "House", "Mosque", "Ship"], 1, "recognition",
              option_images=[omoji("school"), omoji("house"), omoji("mosque"), omoji("ship")]),
        ],
        "Revision Units 6-8 (Unit 9)": [
            q("READING", "I can jump and run in the garden", "I can jump and run in the garden",
              None, 3, "reading"),
        ],
    },

    "en2_p2": {
        "My hobbies (Unit 10)": [
            q("LISTEN_CHOOSE", "Basketball", "Basketball",
              ["Basketball", "Football", "Kite", "Drum"], 1, "recognition",
              option_images=[omoji("basketball"), omoji("soccer_ball"), omoji("kite"), omoji("drum")]),
        ],
        "Transport (Unit 11)": [
            q("IMAGE_MCQ", "Which picture shows a train?", "Train",
              ["Train", "Bus", "Car", "Ship"], 1, "recognition",
              option_images=[omoji("train"), omoji("bus"), omoji("car"), omoji("ship")]),
            q("DRAG_DROP", "Sort the transport: land or water?",
              "Land=Bus,Land=Bicycle,Water=Ship,Water=Sailboat",
              None, 2, "application",
              pairs={"targets": ["Land", "Water"],
                     "tokens": ["Bus", "Ship", "Bicycle", "Sailboat"]}),
        ],
        "Let's go shopping! (Unit 13)": [
            q("IMAGE_MATCH", "Match each food word to its picture", _match_answer(3),
              None, 2, "recognition",
              pairs=_match([("Watermelon", None), ("Corn", None), ("Honey", None)],
                           [("", omoji("watermelon")), ("", omoji("corn")), ("", omoji("honey"))])),
        ],
        "My country (Unit 16)": [
            q("READING", "Palestine is my beautiful country", "Palestine is my beautiful country",
              None, 2, "reading"),
        ],
        "Happy birthday! (Unit 17)": [
            q("IMAGE_MCQ", "Which picture shows a gift?", "Gift",
              ["Gift", "Balloon", "Kite", "Drum"], 1, "recognition",
              option_images=[omoji("gift"), omoji("balloon"), omoji("kite"), omoji("drum")]),
        ],
        "Revision Units 10-17 (Unit 18)": [
            q("READING", "I go to the shop with my mother", "I go to the shop with my mother",
              None, 3, "reading"),
        ],
    },

    # ================= GRADE 2 — MATH =================
    "ma2_p1": {
        "العدد الزوجي والعدد الفردي": [
            q("DRAG_DROP", "صنّف الأعداد الآتية: زوجية أم فردية؟",
              "زوجية=١٢,زوجية=٢٤,فردية=٧,فردية=١٥",
              None, 2, "application",
              pairs={"targets": ["زوجية", "فردية"],
                     "tokens": ["١٢", "٧", "٢٤", "١٥"]}),
        ],
        "المثلث": [
            q("IMAGE_MCQ", "أيُّ صورةٍ تُطابق شكل المثلث؟", "المثلث",
              ["المثلث", "الدائرة", "المربع", "المعين"], 1, "recognition",
              option_images=[omoji("triangle"), omoji("circle_blue"), omoji("square_green"), omoji("diamond")]),
        ],
        "الدائرة": [
            q("IMAGE_MCQ", "اختر الصورة التي تُشبه شكل وجه الساعة", "دائرة",
              ["دائرة", "مثلث", "مربع", "معين"], 2, "recognition",
              option_images=[omoji("circle_red"), omoji("triangle"), omoji("square_blue"), omoji("diamond")]),
        ],
        "مراجعة الوحدة الأولى (الأعداد ضمن ٩٩)": [
            q("IMAGE_MATCH", "صِل اسم العدد بالصورة المناسبة", _match_answer(3),
              None, 2, "recognition",
              pairs=_match([("تسعة", None), ("ستة", None), ("عشرة", None)],
                           [("", omoji("nine")), ("", omoji("six")), ("", omoji("ten"))])),
        ],
        "مراجعة الوحدة الرابعة (الهندسة والقياس ١)": [
            q("DRAG_DROP", "صنّف الأشكال: له أضلاع أم ليس له أضلاع؟",
              "له أضلاع=المربع,له أضلاع=المثلث,ليس له أضلاع=الدائرة,ليس له أضلاع=الشكل البيضاوي",
              None, 3, "application",
              pairs={"targets": ["له أضلاع", "ليس له أضلاع"],
                     "tokens": ["المربع", "الدائرة", "المثلث", "الشكل البيضاوي"]}),
        ],
    },

    "ma2_p2": {
        "مفهوم الضرب": [
            q("DRAG_DROP", "صنّف نواتج الضرب: تساوي ١٠ أم تساوي ٢٠؟",
              "تساوي ١٠=٢×٥,تساوي ١٠=١٠×١,تساوي ٢٠=٤×٥,تساوي ٢٠=٢×١٠",
              None, 3, "application",
              pairs={"targets": ["تساوي ١٠", "تساوي ٢٠"],
                     "tokens": ["٢×٥", "٤×٥", "١٠×١", "٢×١٠"]}),
        ],
        "مراجعة الوحدة السابعة (الضرب)": [
            q("IMAGE_MATCH", "صِل حقيقة الضرب بناتجها", _match_answer(3),
              None, 2, "computation",
              pairs=_match([("٣×٣", None), ("٢×٤", None), ("٥×٢", None)],
                           [("٩", None), ("٨", None), ("١٠", None)])),
        ],
        "وحدات الطول": [
            q("IMAGE_MCQ", "أي أداة نستخدمها لقياس الطول؟", "المسطرة",
              ["المسطرة", "المقص", "القلم", "المفتاح"], 1, "recognition",
              option_images=[omoji("ruler"), omoji("scissors"), omoji("pencil"), omoji("key")]),
        ],
        "جمع البيانات البسيطة": [
            q("DRAG_DROP", "صنّف العناصر لجمع البيانات: وسائل نقل أم حيوانات؟",
              "وسائل نقل=حافلة,وسائل نقل=قطار,حيوانات=جَمَل,حيوانات=سلحفاة",
              None, 2, "application",
              pairs={"targets": ["وسائل نقل", "حيوانات"],
                     "tokens": ["حافلة", "جَمَل", "قطار", "سلحفاة"]}),
        ],
    },

    # ================= GRADE 2 — RELIGION =================
    "re2_p1": {
        "في غار حراء": [
            q("READING", "نَزَلَ الوَحْيُ عَلى رَسولِنا الكَريمِ في غارِ حِراء",
              "نَزَلَ الوَحْيُ عَلى رَسولِنا الكَريمِ في غارِ حِراء", None, 2, "reading"),
        ],
        "سورة العلق": [
            q("READING", "اقْرَأْ بِاسْمِ رَبِّكَ الَّذي خَلَقَ", "اقْرَأْ بِاسْمِ رَبِّكَ الَّذي خَلَقَ",
              None, 2, "recitation"),
        ],
        "آداب الطريق": [
            q("DRAG_DROP", "صنّف السلوك: من آداب الطريق أم من آداب المسجد؟",
              "آداب الطريق=إماطة الأذى,آداب الطريق=غضّ البصر,آداب المسجد=خفض الصوت أثناء الصلاة,آداب المسجد=الدخول باليمنى",
              None, 3, "application",
              pairs={"targets": ["آداب الطريق", "آداب المسجد"],
                     "tokens": ["إماطة الأذى", "خفض الصوت أثناء الصلاة", "غضّ البصر", "الدخول باليمنى"]}),
        ],
        "مدرستي نظيفة": [
            q("IMAGE_MCQ", "أيُّ صورةٍ تدلُّ على المكان الذي نتعلَّم فيه؟", "المدرسة",
              ["المدرسة", "البيت", "المسجد", "الحديقة"], 1, "comprehension",
              option_images=[omoji("school"), omoji("house"), omoji("mosque"), omoji("tree")]),
        ],
        "آداب التلاوة": [
            q("READING", "أَسْتَمِعُ إِلى القُرْآنِ الكَريمِ بِأَدَبٍ وَخُشوعٍ",
              "أَسْتَمِعُ إِلى القُرْآنِ الكَريمِ بِأَدَبٍ وَخُشوعٍ", None, 2, "reading"),
        ],
    },

    "re2_p2": {
        "الأذان": [
            q("READING", "اللهُ أَكْبَرُ اللهُ أَكْبَرُ لا إِلهَ إِلّا الله",
              "اللهُ أَكْبَرُ اللهُ أَكْبَرُ لا إِلهَ إِلّا الله", None, 2, "recitation"),
        ],
        "الصلوات الخمس": [
            q("DRAG_DROP", "صنّف الصلوات حسب عدد ركعاتها",
              "ركعتان=الفجر,ركعتان=الجمعة,أربع ركعات=الظهر,أربع ركعات=العصر",
              None, 3, "application",
              pairs={"targets": ["ركعتان", "أربع ركعات"],
                     "tokens": ["الفجر", "الظهر", "الجمعة", "العصر"]}),
        ],
        "في المسجد": [
            q("IMAGE_MCQ", "اختر صورة الكعبة المشرَّفة", "الكعبة",
              ["الكعبة", "المسجد", "البيت", "المدرسة"], 2, "comprehension",
              option_images=[omoji("kaaba"), omoji("mosque"), omoji("house"), omoji("school")]),
        ],
        "سورة الكوثر": [
            q("READING", "إِنّا أَعْطَيْناكَ الكَوْثَرَ", "إِنّا أَعْطَيْناكَ الكَوْثَرَ",
              None, 2, "recitation"),
        ],
        "آداب الزيارة": [
            q("READING", "أَسْتَأْذِنُ قَبْلَ الدُّخولِ وَأُلْقي السَّلامَ",
              "أَسْتَأْذِنُ قَبْلَ الدُّخولِ وَأُلْقي السَّلامَ", None, 2, "reading"),
        ],
    },
}


# ---------------------------------------------------------------------------
# Lesson teaching-card illustrations (file → lesson title → asset list)
# ---------------------------------------------------------------------------

LESSON_IMAGES: dict[str, dict[str, list[str]]] = {
    "ar1_p2": {
        "نساعد الكبير": [omoji("grandfather")],
        "الماء": [omoji("water")],
    },
    "ma1_p1": {
        "الوقت والساعة": [omoji("clock")],
        "الأعداد ١-٥": [omoji("five")],
        "العدد ١٠": [omoji("ten")],
    },
    "ma1_p2": {
        "الأشكال الهندسية": [omoji("triangle")],
    },
    "re1_p1": {
        "أحب خالقي": [omoji("tree")],
    },
    "re1_p2": {
        "الوضوء": [omoji("water")],
        "آداب الطعام": [omoji("flatbread")],
        "الرفق بالحيوان": [omoji("cat")],
    },
    "ar2_p1": {
        "الغراب والجرّة": [omoji("bird")],
        "الأسد والفأر": [omoji("lion")],
        "الخروف والذئب": [omoji("sheep")],
        "مصنع الألبان": [omoji("milk")],
    },
    "ar2_p2": {
        "العصفورة والأفعى": [omoji("bird")],
        "في البقّالة": [omoji("watermelon")],
    },
    "en2_p1": {
        "In the kitchen (Unit 2)": [omoji("cheese")],
        "In the garden (Unit 3)": [omoji("butterfly")],
        "My body (Unit 4)": [omoji("hand")],
        "My home (Unit 7)": [omoji("house")],
        "My town (Unit 8)": [omoji("school")],
    },
    "en2_p2": {
        "My hobbies (Unit 10)": [omoji("soccer_ball")],
        "Transport (Unit 11)": [omoji("bus")],
        "Happy birthday! (Unit 17)": [omoji("gift")],
    },
    "ma2_p1": {
        "العدد الزوجي والعدد الفردي": [omoji("two")],
        "المثلث": [omoji("triangle")],
        "الدائرة": [omoji("circle_red")],
        "المربع": [omoji("square_blue")],
    },
    "ma2_p2": {
        "قراءة الساعة": [omoji("clock")],
        "وحدات الطول": [omoji("ruler")],
    },
    "re2_p1": {
        "في غار حراء": [omoji("mountain")],
        "مدرستي نظيفة": [omoji("school")],
        "آداب التلاوة": [omoji("book")],
    },
    "re2_p2": {
        "الأذان": [omoji("mosque")],
        "في المسجد": [omoji("kaaba")],
        "الصلوات الخمس": [omoji("prayer_beads")],
    },
}


# ---------------------------------------------------------------------------
# Answer-position fairness (2026-07-04)
#
# A verification pass found two learnable patterns in the media questions:
# the correct IMAGE_MCQ / LISTEN_CHOOSE answer sat at position 0 in 37/38
# questions, and every IMAGE_MATCH right column was aligned with its left
# column (the correct pairing was always "straight across"). The passes below
# scramble both — DETERMINISTICALLY and IDEMPOTENTLY: items are first sorted
# into a canonical order, then permuted by an RNG seeded from the question
# stem, so any input order converges to the same output and rebuilds are
# byte-identical.
# ---------------------------------------------------------------------------

def _fix_choice_order(qq: dict[str, Any]) -> bool:
    """Scramble MCQ / IMAGE_MCQ / LISTEN_CHOOSE options (+parallel images) so
    the correct answer never sits at position 0. Returns True when changed."""
    opts = qq.get("options")
    if not isinstance(opts, list) or len(opts) < 2:
        return False
    imgs = qq.get("optionImages")
    paired = (list(zip(opts, imgs)) if isinstance(imgs, list) and len(imgs) == len(opts)
              else [(o, None) for o in opts])
    # Canonical base order (input-order independent), then seeded permutation.
    paired.sort(key=lambda t: str(t[0]))
    rng = random.Random("manhaji-fair:" + qq["questionText"])
    rng.shuffle(paired)
    if paired[0][0] == qq.get("correctAnswer"):
        paired = paired[1:] + paired[:1]
    new_opts = [o for o, _ in paired]
    changed = new_opts != opts
    qq["options"] = new_opts
    if isinstance(imgs, list) and len(imgs) == len(opts):
        qq["optionImages"] = [i for _, i in paired]
    return changed


def _fix_match_order(qq: dict[str, Any]) -> bool:
    """Scramble the IMAGE_MATCH right column so the correct pairing is never
    fully straight-across. Ids carry the answer mapping, so only the display
    order changes. Returns True when changed."""
    pairs = qq.get("pairs")
    if not isinstance(pairs, dict):
        return False
    left, right = pairs.get("left"), pairs.get("right")
    if not (isinstance(left, list) and isinstance(right, list) and len(right) >= 2):
        return False
    try:
        ans = dict(p.split("=") for p in qq["correctAnswer"].split(","))
    except ValueError:
        return False
    ordered = sorted(right, key=lambda item: str(item.get("id")))
    rng = random.Random("manhaji-fair:" + qq["questionText"])
    rng.shuffle(ordered)

    def _aligned(rl: list[dict[str, Any]]) -> bool:
        return all(str(ans.get(str(left[i].get("id")))) == str(rl[i].get("id"))
                   for i in range(min(len(left), len(rl))))

    if _aligned(ordered):
        ordered = ordered[1:] + ordered[:1]
    changed = ordered != right
    pairs["right"] = ordered
    return changed


def _fix_ordering_presolved(qq: dict[str, Any]) -> bool:
    """ORDERING options must not already sit in the correct-answer order
    (7 authored questions shipped pre-solved). Seeded shuffle; if the result
    still equals the answer sequence, rotate by one."""
    import re as _re
    opts = qq.get("options")
    if not isinstance(opts, list) or len(opts) < 2:
        return False
    answer_seq = [_re.sub(r"\s+", "", part)
                  for part in _re.split(r"[،,]\s*", qq.get("correctAnswer", ""))]

    def solved(seq: list[str]) -> bool:
        return [_re.sub(r"\s+", "", o) for o in seq] == answer_seq

    if not solved(opts):
        return False
    shuffled = sorted(opts, key=str)
    random.Random("manhaji-fair:" + qq["questionText"]).shuffle(shuffled)
    if solved(shuffled):
        shuffled = shuffled[1:] + shuffled[:1]
    qq["options"] = shuffled
    return True


def _apply_fairness(data: dict[str, Any]) -> int:
    fixed = 0
    for lesson in data.get("lessons", []):
        for qq in lesson.get("questions", []):
            t = qq.get("type")
            if t in ("MCQ", "IMAGE_MCQ", "LISTEN_CHOOSE"):
                fixed += _fix_choice_order(qq)
            elif t == "IMAGE_MATCH":
                fixed += _fix_match_order(qq)
            elif t == "ORDERING":
                fixed += _fix_ordering_presolved(qq)
    return fixed


# ---------------------------------------------------------------------------
# Apply
# ---------------------------------------------------------------------------

ALL_FILES = [
    "ar1_p1", "ar1_p2", "en1_p1", "en1_p2", "ma1_p1", "ma1_p2",
    "re1_p1", "re1_p2", "ar2_p1", "ar2_p2", "en2_p1", "en2_p2",
    "ma2_p1", "ma2_p2", "re2_p1", "re2_p2",
]


def main() -> None:
    files = ALL_FILES
    grand_added = 0
    grand_imaged = 0
    for stem in files:
        path = CURRICULUM_DIR / f"{stem}.json"
        if not path.exists():
            print(f"  !! {stem}.json missing — skipped")
            continue
        with path.open(encoding="utf-8") as f:
            data = json.load(f)

        added = 0
        imaged = 0
        by_title = {l["title"]: l for l in data["lessons"]}

        for title, new_qs in NEW_QUESTIONS.get(stem, {}).items():
            lesson = by_title.get(title)
            if lesson is None:
                print(f"  !! {stem}: lesson not found: {title}")
                continue
            existing = {(qq.get("type"), qq.get("questionText"))
                        for qq in lesson.get("questions", [])}
            for nq in new_qs:
                key = (nq["type"], nq["questionText"])
                if key in existing:
                    continue
                lesson.setdefault("questions", []).append(nq)
                existing.add(key)
                added += 1

        for title, imgs in LESSON_IMAGES.get(stem, {}).items():
            lesson = by_title.get(title)
            if lesson is None:
                print(f"  !! {stem}: lesson not found for images: {title}")
                continue
            if lesson.get("imageUrls") != imgs:
                lesson["imageUrls"] = imgs
                imaged += 1

        fixed = _apply_fairness(data)

        if added or imaged or fixed:
            with path.open("w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                f.write("\n")
        total_q = sum(len(l.get("questions", [])) for l in data["lessons"])
        print(f"  {stem}: +{added} questions, {imaged} lesson images, "
              f"{fixed} order-fixes (now {total_q} questions)")
        grand_added += added
        grand_imaged += imaged
    print(f"Done: +{grand_added} questions, {grand_imaged} lesson images.")


if __name__ == "__main__":
    main()

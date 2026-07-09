# -*- coding: utf-8 -*-
"""
Book-fidelity fix (2026-07-04): لغتنا الجميلة grade 1 semester 2.

The real book (PDFBooks/1Grade/لغتنا الجميلة/ar1-p2.pdf, ToC p5) has 15
lessons; our ar1_p2.json stopped at الماء and was missing the last two
reading lessons. This script inserts them, authored from the ACTUAL book
text (extracted pages 121-136):

  14  الفراشة والنحلة — الفراشات في الحقول، النحلة تجمع الرحيق لتصنع
      العسل (letters focus: ص/س/ث)
  15  القرد الطمّاع — قرد جائع وجد خوخة فتركها لموزة ثم جرى وراء أرنب
      فعاد جائعاً (letters focus: ط/ض/ظ)

Idempotent: skips lessons whose title already exists.
"""
from __future__ import annotations

import json

from _common import CURRICULUM_DIR, q, omoji

BUTTERFLY_BEE = {
    "title": "الفراشة والنحلة",
    "orderIndex": 16,
    "content": "طارَتِ الفَراشاتُ في الحُقولِ، سَمِعَتْ فَراشَةٌ صَغيرَةٌ طَنيناً، "
               "فَرَأَتِ النَّحْلَةَ تَنْتَقِلُ مِنْ زَهْرَةٍ إِلى زَهْرَةٍ تَجْمَعُ "
               "الرَّحيقَ لِتَصْنَعَ العَسَلَ اللَّذيذَ.",
    "objectives": "قراءة نص الفراشة والنحلة وفهمه، والتمييز بين الأحرف ص/س/ث",
    "imageUrls": [omoji("butterfly")],
    "questions": [
        q("MCQ", "أَيْنَ طارَتِ الفَراشاتُ؟", "في الحُقولِ",
          ["في الحُقولِ", "في البَحْرِ", "في المَطْبَخِ", "في المَدْرَسَةِ"], 1, "comprehension"),
        q("MCQ", "لِماذا تَنْتَقِلُ النَّحْلَةُ مِنْ زَهْرَةٍ إِلى زَهْرَةٍ؟", "لِتَجْمَعَ الرَّحيقَ",
          ["لِتَجْمَعَ الرَّحيقَ", "لِتَلْعَبَ مَعَ الفَراشَةِ", "لِتَنامَ", "لِتَشْرَبَ الماءَ"], 2, "comprehension"),
        q("MCQ", "ماذا تَصْنَعُ النَّحْلَةُ مِنَ الرَّحيقِ؟", "العَسَلَ",
          ["العَسَلَ", "الخُبْزَ", "الحَليبَ", "الجُبْنَ"], 1, "comprehension"),
        q("TRUE_FALSE", "سَمِعَتِ الفَراشَةُ الصَّغيرَةُ طَنيناً في الحَقْلِ.", "صح", None, 1, "comprehension"),
        q("TRUE_FALSE", "طَعْمُ العَسَلِ مالِحٌ.", "خطأ", None, 2, "comprehension"),
        q("FILL_BLANK", "أكمل من النص: تَجْمَعُ النَّحْلَةُ الرَّحيقَ لِتَصْنَعَ ___.", "العسل", None, 2, "production"),
        q("SHORT_ANSWER", "ما الحَشَرَةُ الَّتي تَصْنَعُ العَسَلَ؟", "النحلة", None, 1, "production"),
        q("ORDERING", "رتّب أحداث القصة: سَمِعَتْ طَنيناً، طارَتِ الفَراشاتُ، رَأَتِ النَّحْلَةَ",
          "طارَتِ الفَراشاتُ، سَمِعَتْ طَنيناً، رَأَتِ النَّحْلَةَ",
          ["سَمِعَتْ طَنيناً", "طارَتِ الفَراشاتُ", "رَأَتِ النَّحْلَةَ"], 3, "application"),
        q("IMAGE_MCQ", "اختر صورة الحَشَرَةِ الَّتي تجمع الرحيق في القصة", "النحلة",
          ["النحلة", "الفراشة", "العصفور", "الضفدع"], 1, "recognition",
          option_images=[omoji("bee"), omoji("butterfly"), omoji("bird"), omoji("frog")]),
        q("DRAG_DROP", "صنّف الكلمات حسب حرفها الأول: بحرف الصاد أم بحرف السين؟",
          "بحرف الصاد=صَغيرَة,بحرف الصاد=صَرَخَت,بحرف السين=سَمِعَت,بحرف السين=سَرير",
          None, 2, "application",
          pairs={"targets": ["بحرف الصاد", "بحرف السين"],
                 "tokens": ["صَغيرَة", "سَمِعَت", "صَرَخَت", "سَرير"]}),
        q("PRONUNCIATION", "الرَّحيق", "الرَّحيق", None, 2, "pronunciation"),
        q("READING", "طارَتِ الفَراشاتُ في الحُقولِ", "طارَتِ الفَراشاتُ في الحُقولِ",
          None, 2, "reading"),
    ],
}

GREEDY_MONKEY = {
    "title": "القرد الطمّاع",
    "orderIndex": 17,
    "content": "بَحَثَ قِرْدٌ جائِعٌ عَنْ طَعامٍ فَوَجَدَ خَوْخَةً، ثُمَّ وَجَدَ مَوْزَةً "
               "فَتَرَكَ الخَوْخَةَ وَأَخَذَ المَوْزَةَ، ثُمَّ شاهَدَ أَرْنَباً فَجَرى "
               "وَراءَهُ وَلَمْ يُمْسِكْ بِهِ، فَعادَ إِلى مَنْزِلِهِ جائِعاً.",
    "objectives": "قراءة نص القرد الطمّاع وفهم عاقبة الطمع، والتمييز بين الأحرف ط/ض/ظ",
    "imageUrls": [omoji("monkey")],
    "questions": [
        q("MCQ", "ماذا وَجَدَ القِرْدُ أَوَّلاً؟", "خَوْخَةً",
          ["خَوْخَةً", "مَوْزَةً", "تُفّاحَةً", "بُرْتُقالَةً"], 1, "comprehension"),
        q("MCQ", "لِماذا تَرَكَ القِرْدُ الخَوْخَةَ؟", "لِأَنَّهُ وَجَدَ مَوْزَةً",
          ["لِأَنَّهُ وَجَدَ مَوْزَةً", "لِأَنَّها كَبيرَةٌ", "لِأَنَّهُ شَبْعانُ", "لِأَنَّها بَعيدَةٌ"], 2, "comprehension"),
        q("MCQ", "بِمَ عادَ القِرْدُ إِلى مَنْزِلِهِ في نِهايَةِ القِصَّةِ؟", "بِلا شَيْءٍ",
          ["بِلا شَيْءٍ", "بِالخَوْخَةِ", "بِالمَوْزَةِ", "بِالأَرْنَبِ"], 3, "comprehension"),
        q("TRUE_FALSE", "شاهَدَ القِرْدُ أَرْنَباً فَجَرى وَراءَهُ.", "صح", None, 1, "comprehension"),
        q("TRUE_FALSE", "أَمْسَكَ القِرْدُ بِالأَرْنَبِ.", "خطأ", None, 1, "comprehension"),
        q("FILL_BLANK", "أكمل من النص: بَحَثَ قِرْدٌ ___ عَنْ طَعامٍ.", "جائع", None, 2, "production"),
        q("SHORT_ANSWER", "ما الصِّفَةُ الَّتي جَعَلَتِ القِرْدَ يَعودُ جائِعاً؟", "الطمع", None, 3, "production"),
        q("ORDERING", "رتّب ما وجده القرد في القصة: أَرْنَب، خَوْخَة، مَوْزَة",
          "خَوْخَة، مَوْزَة، أَرْنَب",
          ["أَرْنَب", "خَوْخَة", "مَوْزَة"], 2, "application"),
        q("IMAGE_MCQ", "اختر صورة الحيوان الذي جرى وراءه القرد", "الأرنب",
          ["الأرنب", "القرد", "السلحفاة", "الدب"], 1, "recognition",
          option_images=[omoji("rabbit"), omoji("monkey"), omoji("turtle"), omoji("bear")]),
        q("IMAGE_MATCH", "صِل كل كلمة من القصة بصورتها", "1=a,2=b,3=c",
          None, 2, "recognition",
          pairs={"left": [{"id": "1", "text": "مَوْزَة"}, {"id": "2", "text": "خَوْخَة"}, {"id": "3", "text": "قِرْد"}],
                 "right": [{"id": "a", "image": omoji("banana")}, {"id": "b", "image": omoji("peach")}, {"id": "c", "image": omoji("monkey")}]}),
        q("PRONUNCIATION", "الطَّمّاع", "الطَّمّاع", None, 2, "pronunciation"),
        q("READING", "بَحَثَ قِرْدٌ جائِعٌ عَنْ طَعامٍ فَوَجَدَ خَوْخَةً",
          "بَحَثَ قِرْدٌ جائِعٌ عَنْ طَعامٍ فَوَجَدَ خَوْخَةً", None, 3, "reading"),
    ],
}


def main() -> None:
    path = CURRICULUM_DIR / "ar1_p2.json"
    with path.open(encoding="utf-8") as f:
        data = json.load(f)
    titles = {l["title"] for l in data["lessons"]}
    added = 0
    for lesson in (BUTTERFLY_BEE, GREEDY_MONKEY):
        if lesson["title"] not in titles:
            data["lessons"].append(lesson)
            added += 1
    if added:
        data["totalLessons"] = len(data["lessons"])
        with path.open("w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
    print(f"ar1_p2: +{added} book lessons (now {len(data['lessons'])} lessons)")


if __name__ == "__main__":
    main()

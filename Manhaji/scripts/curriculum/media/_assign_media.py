"""
Add `imageUrl` / `audioUrl` references to Grade 1 curriculum questions based
on assets sourced under `backend/src/main/resources/static/assets/questions/`.

This script is the bridge between `Manhaji/docs/asset-manifest.md` (which lists
the assets the user is sourcing) and the curriculum JSON files (which need
media references added so the app renders the assets).

Workflow:
  1. User sources files into `static/assets/questions/...` per the manifest.
  2. Run this script. For each ASSIGNMENT entry:
     - If the asset file does NOT exist on disk → log SKIP (so partial bundles
       are safe to iterate on).
     - If the matching question is found → add the imageUrl/audioUrl field.
     - If the question is already references the asset → no-op (idempotent).
  3. Re-run the audit. R12/R13 should clear for any newly added references.

Question matching: each assignment specifies `(curriculum_file, lesson_title,
questionText_substring)`. The first question in that lesson whose
`questionText` CONTAINS the substring (case-insensitive trim) gets the field.
This is more forgiving than exact-match because review-rewrite passes may have
prefixed prompts ("نشاط: ", "(م) ", etc.).

To add a new mapping: append a tuple to ASSIGNMENTS. Re-run the script —
existing assignments are idempotent, only the new one is applied.
"""
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent  # scripts/curriculum/media/ → Manhaji/
CURRICULUM = ROOT / "backend" / "src" / "main" / "resources" / "curriculum"
STATIC = ROOT / "backend" / "src" / "main" / "resources" / "static"

# Each entry: (curriculum_file, lesson_title, questionText_substring,
#              media_field, asset_url_relative_to_static)
#
# media_field: "imageUrl" or "audioUrl"
# asset_url:   absolute path under /assets/... (Spring serves static/ at root)
ASSIGNMENTS = [
    # ============================================================
    # Religion — Surah recitation audio
    # ============================================================
    # Surah Al-Fatiha — PRONUNCIATION questions get per-ayah audio
    ("re1_p1.json", "سورة الفاتحة", "اقرأ: الحمد لله رب العالمين", "audioUrl",
     "/assets/questions/re/surahs/fatiha/re_fatiha_ayah2_mishary.mp3"),
    ("re1_p1.json", "سورة الفاتحة", "اقرأ: الرحمن الرحيم", "audioUrl",
     "/assets/questions/re/surahs/fatiha/re_fatiha_ayah3_mishary.mp3"),
    ("re1_p1.json", "سورة الفاتحة", "اقرأ: مالك يوم الدين", "audioUrl",
     "/assets/questions/re/surahs/fatiha/re_fatiha_ayah4_mishary.mp3"),

    # Surah Al-Ikhlas
    ("re1_p1.json", "سورة الإخلاص", "اقرأ: قل هو الله أحد", "audioUrl",
     "/assets/questions/re/surahs/ikhlas/re_ikhlas_ayah1_mishary.mp3"),
    ("re1_p1.json", "سورة الإخلاص", "اقرأ: الله الصمد", "audioUrl",
     "/assets/questions/re/surahs/ikhlas/re_ikhlas_ayah2_mishary.mp3"),
    ("re1_p1.json", "سورة الإخلاص", "اقرأ: لم يلد ولم يولد", "audioUrl",
     "/assets/questions/re/surahs/ikhlas/re_ikhlas_ayah3_mishary.mp3"),

    # Surah An-Naas
    ("re1_p2.json", "سورة الناس", "اقرأ: قل أعوذ برب الناس", "audioUrl",
     "/assets/questions/re/surahs/naas/re_naas_ayah1_mishary.mp3"),
    ("re1_p2.json", "سورة الناس", "اقرأ: ملك الناس", "audioUrl",
     "/assets/questions/re/surahs/naas/re_naas_ayah2_mishary.mp3"),
    ("re1_p2.json", "سورة الناس", "اقرأ: إله الناس", "audioUrl",
     "/assets/questions/re/surahs/naas/re_naas_ayah3_mishary.mp3"),

    # Surah Al-Falaq
    ("re1_p2.json", "سورة الفلق", "اقرأ: قل أعوذ برب الفلق", "audioUrl",
     "/assets/questions/re/surahs/falaq/re_falaq_ayah1_mishary.mp3"),
    ("re1_p2.json", "سورة الفلق", "اقرأ: من شر ما خلق", "audioUrl",
     "/assets/questions/re/surahs/falaq/re_falaq_ayah2_mishary.mp3"),
    ("re1_p2.json", "سورة الفلق", "اقرأ: ومن شر غاسق إذا وقب", "audioUrl",
     "/assets/questions/re/surahs/falaq/re_falaq_ayah3_mishary.mp3"),

    # Surah Al-Masad
    ("re1_p2.json", "سورة المسد", "اقرأ: تبت يدا أبي لهب وتب", "audioUrl",
     "/assets/questions/re/surahs/masad/re_masad_ayah1_mishary.mp3"),
    ("re1_p2.json", "سورة المسد", "اقرأ: ما أغنى عنه ماله وما كسب", "audioUrl",
     "/assets/questions/re/surahs/masad/re_masad_ayah2_mishary.mp3"),
    ("re1_p2.json", "سورة المسد", "اقرأ: سيصلى ناراً ذات لهب", "audioUrl",
     "/assets/questions/re/surahs/masad/re_masad_ayah3_mishary.mp3"),

    # ============================================================
    # Religion — Wudu / Salah / Prophet step images
    # ============================================================
    # Wudu — image on the procedural ORDERING question
    ("re1_p1.json", "الوضوء", "رتّب خطوات الوضوء", "imageUrl",
     "/assets/questions/re/wudu/re_wudu_step1_intent.png"),
    # Salah — image on the rakaa-order ORDERING question
    ("re1_p1.json", "الصلاة", "رتّب أركان الركعة", "imageUrl",
     "/assets/questions/re/salah/re_salah_qiyaam.png"),
    # Prophet timeline ORDERING gets the birth scene
    ("re1_p1.json", "رسولنا محمد ﷺ", "رتّب أحداث حياة النبي", "imageUrl",
     "/assets/questions/re/prophet/re_prophet_birth.png"),

    # ============================================================
    # Arabic — letter exemplars (image on the "أي كلمة تبدأ بحرف X؟" MCQ)
    # ============================================================
    ("ar1_p1.json", "حرف الراء", "أي كلمة تبدأ بحرف الراء", "imageUrl",
     "/assets/questions/ar/letters/ra/ar_ra_remmaan.png"),
    ("ar1_p1.json", "حرف الدال", "أي كلمة تبدأ بحرف الدال", "imageUrl",
     "/assets/questions/ar/letters/dal/ar_dal_dajaja.png"),
    ("ar1_p1.json", "حرف الباء", "أي كلمة تبدأ بحرف الباء", "imageUrl",
     "/assets/questions/ar/letters/ba/ar_ba_bayt.png"),
    ("ar1_p1.json", "حرف الميم", "أي كلمة تبدأ بحرف الميم", "imageUrl",
     "/assets/questions/ar/letters/mim/ar_mim_maa.png"),
    ("ar1_p1.json", "حرف النون", "أي كلمة تبدأ بحرف النون", "imageUrl",
     "/assets/questions/ar/letters/nun/ar_nun_nahla.png"),
    ("ar1_p1.json", "حرف السين", "أي كلمة تبدأ بحرف السين", "imageUrl",
     "/assets/questions/ar/letters/sin/ar_sin_samaka.png"),
    ("ar1_p1.json", "حرف الزاي", "أي كلمة تبدأ بحرف الزاي", "imageUrl",
     "/assets/questions/ar/letters/zay/ar_zay_zahra.png"),
    ("ar1_p1.json", "حرف الحاء", "أي كلمة تبدأ بحرف الحاء", "imageUrl",
     "/assets/questions/ar/letters/ha/ar_ha_hisan.png"),
    ("ar1_p1.json", "حرف اللام", "أي كلمة تبدأ بحرف اللام", "imageUrl",
     "/assets/questions/ar/letters/lam/ar_lam_laymoon.png"),
    ("ar1_p1.json", "حرف التاء", "أي كلمة تبدأ بحرف التاء", "imageUrl",
     "/assets/questions/ar/letters/ta/ar_ta_taj.png"),
    ("ar1_p1.json", "حرف الجيم", "أي كلمة تبدأ بحرف الجيم", "imageUrl",
     "/assets/questions/ar/letters/jim/ar_jim_jamal.png"),
    ("ar1_p1.json", "حرف الفاء", "أي كلمة تبدأ بحرف الفاء", "imageUrl",
     "/assets/questions/ar/letters/fa/ar_fa_feel.png"),
    ("ar1_p1.json", "حرف العين", "أي كلمة تبدأ بحرف العين", "imageUrl",
     "/assets/questions/ar/letters/ayn/ar_ayn_asfoor.png"),
    ("ar1_p1.json", "حرف الشين", "أي كلمة تبدأ بحرف الشين", "imageUrl",
     "/assets/questions/ar/letters/shin/ar_shin_shams.png"),
    ("ar1_p1.json", "حرف الصاد", "أي كلمة تبدأ بحرف الصاد", "imageUrl",
     "/assets/questions/ar/letters/sad/ar_sad_sahn.png"),
    ("ar1_p1.json", "حرف القاف", "أي كلمة تبدأ بحرف القاف", "imageUrl",
     "/assets/questions/ar/letters/qaf/ar_qaf_qamar.png"),
    ("ar1_p1.json", "حرف الثاء", "أي كلمة تبدأ بحرف الثاء", "imageUrl",
     "/assets/questions/ar/letters/tha/ar_tha_thawb.png"),
    ("ar1_p1.json", "حرف الخاء", "أي كلمة تبدأ بحرف الخاء", "imageUrl",
     "/assets/questions/ar/letters/kha/ar_kha_khubz.png"),

    # ============================================================
    # English — alphabet (per-letter PRONUNCIATION audio + sample-word images)
    # ============================================================
    # Lesson "English Alphabet (A-G)"
    ("en1_p1.json", "English Alphabet (A-G)", "Say the letter: A", "audioUrl",
     "/assets/questions/en/alphabet/en_alphabet_a_sound.mp3"),
    ("en1_p1.json", "English Alphabet (A-G)", "Say the letter: G", "audioUrl",
     "/assets/questions/en/alphabet/en_alphabet_g_sound.mp3"),
    ("en1_p1.json", "English Alphabet (A-G)", "Which letter does the word 'Cat' start with", "imageUrl",
     "/assets/questions/en/vocab/animals/en_animals_cat.png"),

    # Lesson "English Alphabet (H-N)"
    ("en1_p1.json", "English Alphabet (H-N)", "Say the letter: J", "audioUrl",
     "/assets/questions/en/alphabet/en_alphabet_j_sound.mp3"),
    ("en1_p1.json", "English Alphabet (H-N)", "Say the letter: K", "audioUrl",
     "/assets/questions/en/alphabet/en_alphabet_k_sound.mp3"),
    ("en1_p1.json", "English Alphabet (H-N)", "Which letter does the word 'Hat' start with", "imageUrl",
     "/assets/questions/en/alphabet/en_alphabet_hat.png"),

    # Lesson "English Alphabet (O-T)"
    ("en1_p1.json", "English Alphabet (O-T)", "Say the letter: Q", "audioUrl",
     "/assets/questions/en/alphabet/en_alphabet_q_sound.mp3"),
    ("en1_p1.json", "English Alphabet (O-T)", "Say the letter: R", "audioUrl",
     "/assets/questions/en/alphabet/en_alphabet_r_sound.mp3"),

    # Lesson "English Alphabet (U-Z)"
    ("en1_p1.json", "English Alphabet (U-Z)", "Say the letter: W", "audioUrl",
     "/assets/questions/en/alphabet/en_alphabet_w_sound.mp3"),
    ("en1_p1.json", "English Alphabet (U-Z)", "Say the letter: Y", "audioUrl",
     "/assets/questions/en/alphabet/en_alphabet_y_sound.mp3"),
    ("en1_p1.json", "English Alphabet (U-Z)", "Which letter does the word 'Zoo' start with", "imageUrl",
     "/assets/questions/en/alphabet/en_alphabet_zoo.png"),

    # ============================================================
    # English — vocabulary unit images (image-MCQ)
    # ============================================================
    # Family
    ("en1_p1.json", "My Family (Unit 3)", "What is 'أم' in English", "imageUrl",
     "/assets/questions/en/vocab/family/en_family_mother.png"),
    ("en1_p1.json", "My Family (Unit 3)", "Your mother's son is your", "imageUrl",
     "/assets/questions/en/vocab/family/en_family_brother.png"),

    # School
    ("en1_p1.json", "My School (Unit 2)", "What is 'كتاب' in English", "imageUrl",
     "/assets/questions/en/vocab/school/en_school_book.png"),
    ("en1_p1.json", "My School (Unit 2)", "What do you write with", "imageUrl",
     "/assets/questions/en/vocab/school/en_school_pencil.png"),

    # Colors
    ("en1_p1.json", "Colors (Unit 5)", "What color is the sun", "imageUrl",
     "/assets/questions/en/vocab/colors/en_colors_yellow.png"),
    ("en1_p1.json", "Colors (Unit 5)", "Mixing red and yellow", "imageUrl",
     "/assets/questions/en/vocab/colors/en_colors_red.png"),

    # Body
    ("en1_p1.json", "My Body (Unit 6)", "Which body part do you use to walk", "imageUrl",
     "/assets/questions/en/vocab/body/en_body_foot.png"),

    # Animals
    ("en1_p1.json", "Animals (Unit 7)", "Which animal says 'meow'", "imageUrl",
     "/assets/questions/en/vocab/animals/en_animals_cat.png"),
    ("en1_p1.json", "Animals (Unit 7)", "Which animal can fly", "imageUrl",
     "/assets/questions/en/vocab/animals/en_animals_bird.png"),

    # Food
    ("en1_p1.json", "Food (Unit 8)", "What color is a banana", "imageUrl",
     "/assets/questions/en/vocab/food/en_food_banana.png"),
    ("en1_p1.json", "Food (Unit 8)", "Which is a fruit", "imageUrl",
     "/assets/questions/en/vocab/food/en_food_apple.png"),

    # ============================================================
    # Math — visual MCQ on shapes / counting / time / money
    # ============================================================
    # Shapes
    ("ma1_p2.json", "الأشكال الهندسية", "كم ضلعاً للمثلث", "imageUrl",
     "/assets/questions/ma/shapes/ma_shapes_triangle.png"),
    ("ma1_p2.json", "الأشكال الهندسية", "للمربع أربعة أضلاع متساوية", "imageUrl",
     "/assets/questions/ma/shapes/ma_shapes_square.png"),
    ("ma1_p2.json", "الأشكال الهندسية", "أي شكل يشبه عجلة السيارة", "imageUrl",
     "/assets/questions/ma/shapes/ma_shapes_circle.png"),

    # Counting
    ("ma1_p1.json", "الأعداد ١-٥", "كم تفاحة في الصورة", "imageUrl",
     "/assets/questions/ma/numbers/ma_numbers_3_apples.png"),
    ("ma1_p1.json", "الأعداد ٦-٩", "كم نجمة", "imageUrl",
     "/assets/questions/ma/numbers/ma_numbers_5_stars.png"),

    # Time
    ("ma1_p2.json", "الوقت والساعة", "كم ساعة في اليوم", "imageUrl",
     "/assets/questions/ma/time/ma_time_clock_3oclock.png"),

    # Money
    ("ma1_p2.json", "النقود", "كم قرشاً في الشيكل الواحد", "imageUrl",
     "/assets/questions/ma/money/ma_money_1shekel.png"),
]


def find_question(lesson_questions, substring):
    """Find first question whose questionText contains the given substring
    (case-insensitive trim)."""
    needle = substring.strip().lower()
    for q in lesson_questions:
        text = (q.get("questionText") or "").strip().lower()
        if needle in text:
            return q
    return None


def main():
    files_data = {}
    matched = 0
    skipped_no_file = 0
    skipped_no_match = 0
    already_set = 0

    for fname, lesson_title, qtext_sub, field, asset_url in ASSIGNMENTS:
        # Resolve & check the asset file
        rel = asset_url.lstrip("/")
        asset_path = STATIC / rel
        if not asset_path.exists():
            skipped_no_file += 1
            continue

        # Load the curriculum file (cached)
        if fname not in files_data:
            with (CURRICULUM / fname).open(encoding="utf-8") as f:
                files_data[fname] = json.load(f)

        # Find the lesson
        lesson = None
        for ls in files_data[fname].get("lessons", []):
            if ls.get("title") == lesson_title:
                lesson = ls
                break
        if lesson is None:
            skipped_no_match += 1
            print(f"  SKIP no-lesson: {fname} :: {lesson_title}")
            continue

        # Find the matching question
        q = find_question(lesson.get("questions", []), qtext_sub)
        if q is None:
            skipped_no_match += 1
            print(f"  SKIP no-question: {fname} :: {lesson_title}  ~contains~  '{qtext_sub}'")
            continue

        # Idempotent: don't re-set if already pointing to the same URL
        if q.get(field) == asset_url:
            already_set += 1
            continue

        q[field] = asset_url
        matched += 1
        print(f"  + {fname} :: {lesson_title}  [{field}] = {asset_url}")

    # Save back any modified files
    for fname, data in files_data.items():
        with (CURRICULUM / fname).open("w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")

    print()
    print(f"DONE: {matched} new assignments, {already_set} already set, "
          f"{skipped_no_file} skipped (file missing), "
          f"{skipped_no_match} skipped (no matching question).")
    if skipped_no_file:
        print("    Note: 'file missing' is expected for assets not yet sourced. "
              "Re-run after dropping more files in.")


if __name__ == "__main__":
    main()

# Manhaji — Grade 1 Asset Manifest

**Owner:** Abdallah Mattour · **Created:** 2026-04-27 · **Status:** Sourcing in progress

This is the canonical sourcing checklist for the Grade 1 image + audio bundle. Drop files into the indicated paths under `Manhaji/backend/src/main/resources/static/assets/questions/`. Filenames and paths are exact — they map to `imageUrl` / `audioUrl` JSON references that will be added by `_assign_media.py`.

## Conventions (per spec §8.2)

- **Images** — PNG, ≤ 200 KB each, transparent background where possible. Filename: `<subject>_<topic>_<keyword>.png` (lowercase, ASCII only, no spaces, underscores between words).
- **Audio** — MP3 (preferred) or M4A, ≤ 500 KB each, 44.1 kHz mono. Filename: `<subject>_<topic>_<keyword>[_<reciter>].mp3`.
- **Public URL pattern** — Spring serves anything under `static/` at the equivalent path. So `static/assets/questions/ar/letters/ra/ar_ra_remmaan.png` resolves to `/assets/questions/ar/letters/ra/ar_ra_remmaan.png` over HTTP.
- **Fail-soft** — if a file is missing, `Image.network` shows `SizedBox.shrink()` and `AudioPlayer` silently no-ops. So a partial bundle won't crash the app — but the `QuestionAuditTest` will print an R12/R13 warning.
- **Bundle budget** — Grade 1 ≤ 8 MB, all grades ≤ 25 MB. After dropping files in, run `du -sh backend/src/main/resources/static/assets/questions/` to verify.

## Status legend

- ⬜ TODO — needs to be sourced
- 🟦 SOURCED — file is in place, audit not re-run
- ✅ VERIFIED — audit + smoke test confirm it loads

---

## 1. Religion — Surah recitation audio (highest demo impact)

**Suggested source:** Mishary Rashid Alafasy public-domain MP3s from `mp3quran.net` (search "Alafasy 128kbps"). Educational use is permitted — record attribution in `CREDITS.txt`.

**Workflow:** Download per-surah MP3, then split into per-ayah clips using ffmpeg (`ffmpeg -i full.mp3 -ss <start> -to <end> -c copy ayah_N.mp3`). Each clip should be ~3-15 seconds.

### Surah Al-Fatiha (`re/surahs/fatiha/`)

| File | Ayah | Duration target | Status |
|---|---|---|---|
| `re_fatiha_ayah1_mishary.mp3` | بسم الله الرحمن الرحيم | ~5 s | ⬜ |
| `re_fatiha_ayah2_mishary.mp3` | الحمد لله رب العالمين | ~4 s | ⬜ |
| `re_fatiha_ayah3_mishary.mp3` | الرحمن الرحيم | ~3 s | ⬜ |

### Surah Al-Ikhlas (`re/surahs/ikhlas/`)

| File | Ayah | Status |
|---|---|---|
| `re_ikhlas_ayah1_mishary.mp3` | قل هو الله أحد | ⬜ |
| `re_ikhlas_ayah2_mishary.mp3` | الله الصمد | ⬜ |
| `re_ikhlas_ayah3_mishary.mp3` | لم يلد ولم يولد | ⬜ |

### Surah An-Naas (`re/surahs/naas/`)

| File | Ayah | Status |
|---|---|---|
| `re_naas_ayah1_mishary.mp3` | قل أعوذ برب الناس | ⬜ |
| `re_naas_ayah2_mishary.mp3` | ملك الناس | ⬜ |
| `re_naas_ayah3_mishary.mp3` | إله الناس | ⬜ |

### Surah Al-Falaq (`re/surahs/falaq/`)

| File | Ayah | Status |
|---|---|---|
| `re_falaq_ayah1_mishary.mp3` | قل أعوذ برب الفلق | ⬜ |
| `re_falaq_ayah2_mishary.mp3` | من شر ما خلق | ⬜ |
| `re_falaq_ayah3_mishary.mp3` | ومن شر غاسق إذا وقب | ⬜ |

### Surah Al-Masad (`re/surahs/masad/`)

| File | Ayah | Status |
|---|---|---|
| `re_masad_ayah1_mishary.mp3` | تبت يدا أبي لهب وتب | ⬜ |
| `re_masad_ayah2_mishary.mp3` | ما أغنى عنه ماله وما كسب | ⬜ |
| `re_masad_ayah3_mishary.mp3` | سيصلى ناراً ذات لهب | ⬜ |

**Subtotal: 15 audio files, ~5 MB.**

---

## 2. Religion — Wudu / Salah / Prophet step images

### Wudu (6 sequential step images for ORDERING) — `re/wudu/`

| File | Step | Status |
|---|---|---|
| `re_wudu_step1_intent.png` | Step 1: Intention + bismillah | ⬜ |
| `re_wudu_step2_hands.png` | Step 2: Wash hands 3× | ⬜ |
| `re_wudu_step3_face.png` | Step 3: Wash face 3× | ⬜ |
| `re_wudu_step4_arms.png` | Step 4: Wash arms to elbow 3× | ⬜ |
| `re_wudu_step5_head.png` | Step 5: Wipe head once | ⬜ |
| `re_wudu_step6_feet.png` | Step 6: Wash feet to ankle 3× | ⬜ |

### Salah rakaa (`re/salah/`)

| File | Step | Status |
|---|---|---|
| `re_salah_takbir.png` | تكبيرة الإحرام (hands raised) | ⬜ |
| `re_salah_qiyaam.png` | قيام (standing reading) | ⬜ |
| `re_salah_ruku.png` | ركوع (bowing) | ⬜ |
| `re_salah_sujood.png` | سجود (prostration) | ⬜ |
| `re_salah_tashahhud.png` | تشهد (sitting) | ⬜ |

### Prophet timeline (`re/prophet/`)

| File | Event | Status |
|---|---|---|
| `re_prophet_birth.png` | الولادة في مكة | ⬜ |
| `re_prophet_revelation.png` | البعثة في غار حراء | ⬜ |
| `re_prophet_hijrah.png` | الهجرة إلى المدينة | ⬜ |
| `re_prophet_passing.png` | الوفاة | ⬜ |

**Subtotal: 15 images.**

---

## 3. Arabic — letter exemplars (image-MCQ for letter lessons)

For each Arabic letter lesson, a single PNG of an iconic word starting with that letter. Used in image-MCQ questions like "أي كلمة تبدأ بحرف الراء؟".

| Letter | Path | File | Word | Status |
|---|---|---|---|---|
| ر | `ar/letters/ra/` | `ar_ra_remmaan.png` | رمّان (pomegranate) | ⬜ |
| د | `ar/letters/dal/` | `ar_dal_dajaja.png` | دجاجة (chicken) | ⬜ |
| ب | `ar/letters/ba/` | `ar_ba_bayt.png` | بيت (house) | ⬜ |
| م | `ar/letters/mim/` | `ar_mim_maa.png` | ماء (water) | ⬜ |
| ن | `ar/letters/nun/` | `ar_nun_nahla.png` | نحلة (bee) | ⬜ |
| س | `ar/letters/sin/` | `ar_sin_samaka.png` | سمكة (fish) | ⬜ |
| ز | `ar/letters/zay/` | `ar_zay_zahra.png` | زهرة (flower) | ⬜ |
| ح | `ar/letters/ha/` | `ar_ha_hisan.png` | حصان (horse) | ⬜ |
| ل | `ar/letters/lam/` | `ar_lam_laymoon.png` | ليمون (lemon) | ⬜ |
| ت | `ar/letters/ta/` | `ar_ta_taj.png` | تاج (crown) | ⬜ |
| ج | `ar/letters/jim/` | `ar_jim_jamal.png` | جمل (camel) | ⬜ |
| ف | `ar/letters/fa/` | `ar_fa_feel.png` | فيل (elephant) | ⬜ |
| ع | `ar/letters/ayn/` | `ar_ayn_asfoor.png` | عصفور (bird) | ⬜ |
| ش | `ar/letters/shin/` | `ar_shin_shams.png` | شمس (sun) | ⬜ |
| ص | `ar/letters/sad/` | `ar_sad_sahn.png` | صحن (plate) | ⬜ |
| ق | `ar/letters/qaf/` | `ar_qaf_qamar.png` | قمر (moon) | ⬜ |
| ث | `ar/letters/tha/` | `ar_tha_thawb.png` | ثوب (garment) | ⬜ |
| خ | `ar/letters/kha/` | `ar_kha_khubz.png` | خبز (bread) | ⬜ |

**Subtotal: 18 images for p1 letters. Add 10 more for p2 letters once p2 letter list is verified.**

---

## 4. English — alphabet (4 lessons: A-G, H-N, O-T, U-Z)

### Letter shape + sound (`en/alphabet/`)

For each letter A-Z: one PNG of the uppercase + lowercase letter pair (e.g., `Aa`), plus one MP3 of a native speaker saying the letter.

| File | Description | Status |
|---|---|---|
| `en_alphabet_a.png` | Aa (uppercase + lowercase together) | ⬜ |
| `en_alphabet_a_sound.mp3` | Spoken letter "A" | ⬜ |
| `en_alphabet_b.png` | Bb | ⬜ |
| `en_alphabet_b_sound.mp3` | Spoken "B" | ⬜ |
| ... | (one image + one audio per letter, A through Z) | ⬜ |
| `en_alphabet_z.png` | Zz | ⬜ |
| `en_alphabet_z_sound.mp3` | Spoken "Z" | ⬜ |

### Sample-word images (one per alphabet lesson's image-MCQ)

| File | Word | Status |
|---|---|---|
| `en_alphabet_apple.png` | Apple (A starter, used in lesson A-G) | ⬜ |
| `en_alphabet_egg.png` | Egg (E) | ⬜ |
| `en_alphabet_goat.png` | Goat (G) | ⬜ |
| `en_alphabet_hat.png` | Hat (H) | ⬜ |
| `en_alphabet_kite.png` | Kite (K) | ⬜ |
| `en_alphabet_moon.png` | Moon (M) | ⬜ |
| `en_alphabet_orange.png` | Orange (O) | ⬜ |
| `en_alphabet_queen.png` | Queen (Q) | ⬜ |
| `en_alphabet_sun.png` | Sun (S) | ⬜ |
| `en_alphabet_umbrella.png` | Umbrella (U) | ⬜ |
| `en_alphabet_yellow.png` | Yellow (Y) | ⬜ |
| `en_alphabet_zoo.png` | Zoo (Z) | ⬜ |

**Subtotal: 26 letter images + 26 audio + 12 word images = 64 files.** This is the largest single chunk; if budget tight, drop the per-letter audio and rely on TTS in the app.

---

## 5. English — vocabulary unit images (image-MCQ candidates)

### Greetings / Hello (`en/vocab/greetings/`)

| File | Description | Status |
|---|---|---|
| `en_greetings_wave.png` | Hand waving | ⬜ |
| `en_greetings_morning.png` | Sunrise scene for "Good morning" | ⬜ |

### Family (`en/vocab/family/`)

| File | Word | Status |
|---|---|---|
| `en_family_father.png` | Father (smiling man) | ⬜ |
| `en_family_mother.png` | Mother (smiling woman) | ⬜ |
| `en_family_brother.png` | Brother (boy) | ⬜ |
| `en_family_sister.png` | Sister (girl) | ⬜ |
| `en_family_baby.png` | Baby | ⬜ |

### School (`en/vocab/school/`)

| File | Word | Status |
|---|---|---|
| `en_school_book.png` | Book | ⬜ |
| `en_school_pen.png` | Pen | ⬜ |
| `en_school_pencil.png` | Pencil | ⬜ |
| `en_school_bag.png` | School bag | ⬜ |
| `en_school_ruler.png` | Ruler | ⬜ |
| `en_school_eraser.png` | Eraser | ⬜ |

### Colors (`en/vocab/colors/`)

| File | Color | Status |
|---|---|---|
| `en_colors_red.png` | Red square swatch | ⬜ |
| `en_colors_blue.png` | Blue square swatch | ⬜ |
| `en_colors_yellow.png` | Yellow square swatch | ⬜ |
| `en_colors_green.png` | Green square swatch | ⬜ |

### Body (`en/vocab/body/`)

| File | Part | Status |
|---|---|---|
| `en_body_eye.png` | Eye | ⬜ |
| `en_body_ear.png` | Ear | ⬜ |
| `en_body_hand.png` | Hand | ⬜ |
| `en_body_foot.png` | Foot | ⬜ |
| `en_body_mouth.png` | Mouth | ⬜ |

### Animals (`en/vocab/animals/`)

| File | Animal | Status |
|---|---|---|
| `en_animals_cat.png` | Cat | ⬜ |
| `en_animals_dog.png` | Dog | ⬜ |
| `en_animals_bird.png` | Bird | ⬜ |
| `en_animals_fish.png` | Fish | ⬜ |
| `en_animals_cow.png` | Cow | ⬜ |

### Food (`en/vocab/food/`)

| File | Item | Status |
|---|---|---|
| `en_food_apple.png` | Apple | ⬜ |
| `en_food_banana.png` | Banana | ⬜ |
| `en_food_bread.png` | Bread | ⬜ |
| `en_food_milk.png` | Glass of milk | ⬜ |
| `en_food_water.png` | Glass of water | ⬜ |

### House (`en/vocab/house/`) · Clothes · Toys · Weather · Fruits · Actions · Day

Skip per-item images at this scope to stay under the 150-asset cap. Image-MCQ for these units can be added in a future polish pass.

**Subtotal vocab: ~33 images.**

---

## 6. Math — visual-MCQ images

### Shapes (`ma/shapes/`)

| File | Shape | Status |
|---|---|---|
| `ma_shapes_circle.png` | Circle | ⬜ |
| `ma_shapes_square.png` | Square | ⬜ |
| `ma_shapes_triangle.png` | Triangle | ⬜ |
| `ma_shapes_rectangle.png` | Rectangle | ⬜ |

### Counting scenes (`ma/numbers/`)

| File | Description | Status |
|---|---|---|
| `ma_numbers_3_apples.png` | 3 apples in a row | ⬜ |
| `ma_numbers_5_stars.png` | 5 stars | ⬜ |
| `ma_numbers_7_balloons.png` | 7 balloons | ⬜ |
| `ma_numbers_10_blocks.png` | 10 blocks (for "العدد ١٠" lesson) | ⬜ |

### Time (`ma/time/`)

| File | Description | Status |
|---|---|---|
| `ma_time_clock_3oclock.png` | Clock face at 3:00 | ⬜ |
| `ma_time_clock_6oclock.png` | Clock face at 6:00 | ⬜ |
| `ma_time_clock_quarter.png` | Clock at 3:15 | ⬜ |

### Money (`ma/money/`)

| File | Description | Status |
|---|---|---|
| `ma_money_1shekel.png` | 1-shekel coin | ⬜ |
| `ma_money_5shekel.png` | 5-shekel coin | ⬜ |
| `ma_money_10shekel.png` | 10-shekel note | ⬜ |
| `ma_money_20shekel.png` | 20-shekel note | ⬜ |

**Subtotal math: ~15 images.**

---

## 7. Asset volume summary

| Category | Asset count | Approx size |
|---|---:|---:|
| Religion surah audio | 15 audio | ~5 MB |
| Religion procedural images | 15 images | ~1.5 MB |
| Arabic letter exemplars (p1) | 18 images | ~1.8 MB |
| English alphabet (letters + audio + words) | 64 files | ~5 MB |
| English vocab images | 33 images | ~3 MB |
| Math visuals | 15 images | ~1.5 MB |
| **Grade 1 total** | **~160 files** | **~17 MB** ⚠️ exceeds 8 MB budget |

⚠️ **Budget alert**: Initial estimate exceeds the 8 MB Grade 1 budget. Mitigation:
1. Compress all PNGs through `pngquant --quality 65-80` after sourcing (typically 60-70% reduction).
2. Encode audio at 96 kbps mono (typical 40-second ayah → ~480 KB → fits 500 KB cap).
3. If still over budget after compression, drop the 26 per-letter English audio files (can use device TTS via `flutter_tts` instead at runtime).

---

## 8. CREDITS.txt template

Drop this file at `backend/src/main/resources/static/assets/questions/CREDITS.txt` once sourcing is done:

```
Manhaji — Asset attributions
Compiled 2026-04-XX

== Quranic recitation ==
- Surahs Al-Fatiha, Al-Ikhlas, Al-Naas, Al-Falaq, Al-Masad
  Reciter: Mishary Rashid Alafasy
  Source: mp3quran.net (public-domain redistribution permitted for educational use)

== Clipart images ==
- All PNG files under ar/, en/, ma/, re/wudu/, re/salah/, re/prophet/
  Source: <name of CC0/freepik pack you used>
  License: <CC0 / freepik free / CC-BY 4.0 / etc>
  Per-file attribution: <add as needed>
```

---

## 9. Once you've sourced files

1. Run `du -sh backend/src/main/resources/static/assets/questions/` — verify ≤ 8 MB.
2. Tell me ("assets are in"), and I'll proceed with the next steps:
   - Write `_assign_media.py` to add `imageUrl` / `audioUrl` references to the matching JSON questions.
   - Re-run audit; iterate until R12/R13 are clean.
   - Promote R12, R13, R15-R18 to strict.
   - Run bootRun smoke test + flutter device test per the runbook in `partitioned-hopping-graham.md`.

If you need to skip any category (e.g., no per-letter English audio), update the status column to ❌ SKIP and let me know — I'll adjust `_assign_media.py` to skip the matching JSON references.

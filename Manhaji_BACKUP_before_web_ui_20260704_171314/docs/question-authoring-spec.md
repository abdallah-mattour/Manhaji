# Manhaji — Question Authoring Spec

**Owner:** Abdallah Mattour · **Audience:** Anyone (human or AI) writing curriculum JSON for `backend/src/main/resources/curriculum/`. **Status:** Living doc — update when adding subjects, types, or grades.

---

## 1. Why this exists

Every question in this app is one of seven types, each with strict shape requirements, scoring behavior, and pedagogical purpose. This document is the **single source of truth** for those requirements. The audit lint (`QuestionAuditTest`) enforces it on every CI run. If a question violates the spec, the build fails — not because the data model is broken, but because the lesson would teach nothing.

The Grade 1 baseline (623 questions) shipped before this spec existed. It scored **60/100** in our internal audit. Everything from the Grade 1 backfill onward — and 100% of grades 2-4 — must conform to this spec.

## 2. Universal rules (apply to every question, every type)

| Rule | Why | Enforced by |
|------|-----|-------------|
| `questionText` is non-empty, ≤500 chars | Render limits | Audit |
| `correctAnswer` is non-empty | Scoring | Audit |
| For MCQ: `correctAnswer ∈ options`, `options.size ∈ [3,5]` | Otherwise unscoreable / trivial | Audit |
| For TRUE_FALSE: `correctAnswer ∈ {"صح","خطأ","True","False"}`, `options == null` | Type discipline | Audit |
| `options` is null for non-MCQ types unless explicitly required (MCQ, ORDERING) | Schema cleanliness | Audit |
| `difficultyLevel ∈ {1,2,3}` | Adaptive engine assumes this range | Audit |
| Each lesson has **≥1 difficulty-3 question** | Headroom for mastery | Audit |
| Each lesson has **10–12 questions** (target 12; minimum 8 for review-style lessons) | Spaced retrieval needs depth | Audit |
| No two questions in the same subject share the exact `questionText` | Prevents pattern-match wins | Audit |
| Question language matches lesson language (no Arabic answers to English prompts and vice versa) | Mode confusion | Audit (heuristic) |
| Question topic must match lesson topic (no Unit-2 content in Unit 1) | Pedagogical integrity | Manual review |
| Every lesson covers ≥3 distinct sub-skills (see §6) | Whole-skill assessment | Audit |
| If `imageUrl` is set, file must exist at `static/assets/questions/<path>` | Broken-image avoidance | Audit (filesystem check) |
| If `audioUrl` is set, file must exist at `static/assets/questions/<path>` (mp3 or m4a) | Broken-audio avoidance | Audit (filesystem check) |

## 3. Per-type rules

### 3.1 MCQ
- 3–5 options, exactly one correct.
- Distractors must be **plausible at the lesson level** — no "obviously wrong" filler (e.g. "السماء" as a distractor for a Quran question). A child who guesses by elimination should still need to know the lesson.
- For Grade 1, prefer 4 options. Use 3 only when distractors are scarce.
- **If the prompt asks "true or false?" and options are `["صح","خطأ"]`, that's a TRUE_FALSE, not an MCQ.** This was a real bug in `ar1_p1.json` lines 41-47 — never repeat it.
- **Image-MCQ** is encouraged: set `imageUrl` to an image hosted at `static/assets/questions/<subject>/<topic>/<file>.png`. Distractors can be images by including image labels in `options` and an `imageUrl` array (future extension); for now, image is supplementary to a text prompt.

### 3.2 TRUE_FALSE
- Arabic: `correctAnswer` is `"صح"` or `"خطأ"`. English: `"True"` or `"False"`.
- `options` MUST be null. The widget renders the two buttons.
- Avoid trick wording. A first-grader should be able to verify correctness from the lesson content.
- **Mixing modes is forbidden**: never set `"correctAnswer": "صح"` on an English-language question (caught in `en1_p1.json` Unit 1; do not repeat).

### 3.3 SHORT_ANSWER
- Free-text input, scored on exact-match (after trim + diacritic normalization for Arabic).
- Answer should be **one or two words** at Grade 1. Sentence-length short-answers misfire under exact-match scoring.
- Provide alternates if there is genuine ambiguity (currently single-answer only — if you find a question that needs alternates, propose a schema change rather than picking one).

### 3.4 FILL_BLANK
- Stem contains exactly one `___` (three underscores) marker.
- `correctAnswer` is the word that fills the blank.
- Stem must be **lesson-specific**, not template-reusable. The pattern `"اسم السورة التي ندرسها هي سورة ___"` reused across 11 surahs is forbidden — it teaches stem-recognition, not the surah.

### 3.5 ORDERING
- `options` is the **shuffled** list (3–6 items); `correctAnswer` is the **correct order** as a comma-separated string with **no spaces around commas** (e.g. `"١,٢,٣"` not `"١, ٢, ٣"`).
- Use ORDERING for: number sequences, word-formation from letters, prophet-story sequencing, prayer/wudu steps, sentence construction.
- If two ORDERING questions in the same subject share `correctAnswer`, that's a duplicate (caught in `ma1_p1.json` between مقارنة and ترتيب; do not repeat).

### 3.6 PRONUNCIATION
- `questionText` is what the student sees as the prompt (usually the same as `correctAnswer`).
- `correctAnswer` is the target Arabic or English text. The scoring engine auto-detects language from the Arabic Unicode block (U+0600–U+06FF).
- Scoring threshold: ≥60 = isCorrect. Strings: ممتاز ≥90, جيد جداً ≥75, جيد ≥60, حاول مرة أخرى ≥40, لم أسمعك جيداً otherwise.
- For Religion Surah lessons, **provide reciter audio** at `audioUrl` so students hear the correct recitation before they record. Use Mishary or Hudhaifi (rights cleared for educational use).
- For English alphabet/words, set `audioUrl` to native-speaker pronunciation.

### 3.7 TRACING
- `questionText` is the character/word to trace (usually identical to `correctAnswer`).
- Currently scored client-side via bounding-box + stroke-count heuristic.
- Use TRACING for: Arabic letter shapes (initial/medial/final forms count separately when relevant), Arabic numerals, English letters (uppercase + lowercase separately), English numerals.
- For Grade 1, every Arabic letter lesson MUST include ≥3 tracing items (isolated, joined-from-right, in a 2-letter word). Every English alphabet lesson MUST include ≥1 tracing item per letter.

## 4. Per-subject lesson templates

The total in each template targets **10–12 questions**. Required diversity is enforced by the audit (≥3 sub-skills, ≥1 difficulty-3).

### 4.1 Arabic — letter lesson (28 letter lessons across `ar1_p1` + `ar1_p2`)

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 2 | One image-MCQ ("which picture starts with this letter?") if image available, else text-MCQ |
| TRUE_FALSE | 1 | About the letter's shape, sound, or dot-count |
| SHORT_ANSWER | 2 | "Write the letter" + "Name a word starting with this letter" |
| FILL_BLANK | 1 | Cloze in a 3-word sentence using a lesson-vocab word |
| ORDERING | 1 | Word-formation: shuffle 3-4 letters → form a lesson word |
| PRONUNCIATION | 3 | Three lesson words, ≥1 at difficulty 2 |
| TRACING | 2 | Isolated letter (diff 1) + 2-letter combination (diff 2) |
| **Total** | **12** | **≥1 difficulty-3** (typically the ORDERING or a multi-letter discrimination MCQ) |

### 4.2 Arabic — thematic lesson (e.g. "Helping the Elderly", "My Country") — there are ~3 of these

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 3 | Comprehension of the theme |
| TRUE_FALSE | 2 | Value-statements about the theme |
| SHORT_ANSWER | 2 | Vocabulary recall |
| FILL_BLANK | 2 | Cloze in lesson sentences |
| ORDERING | 1 | Sentence reconstruction or story sequence |
| PRONUNCIATION | 2 | Two key vocabulary words |
| **Total** | **12** | **≥1 difficulty-3** |

### 4.3 English — alphabet lesson (NEW; replaces missing alphabet coverage)

Split A-Z into **4 lessons of 6-7 letters each** (A-G, H-N, O-T, U-Z). Per lesson:

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 3 | Image-MCQ: "which picture starts with B?" |
| TRUE_FALSE | 1 | "B is the second letter of the alphabet" |
| SHORT_ANSWER | 2 | "Write the letter that comes after C" + "What letter does 'banana' start with?" |
| FILL_BLANK | 1 | "_pple" → "A" |
| ORDERING | 1 | Shuffle 4 letters → put in alphabet order |
| PRONUNCIATION | 2 | Two letters in this lesson + 1 sample word |
| TRACING | 4 | Uppercase + lowercase for 2 of the lesson's letters |
| **Total** | **14** | **≥1 difficulty-3** (image-MCQ with similar-sounding distractors, e.g. B vs P) |

### 4.4 English — vocabulary/theme lesson (Hello, School, Family, etc. — 18 existing units)

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 3 | ≥2 image-MCQs |
| TRUE_FALSE | 2 | English-only stems and answers |
| SHORT_ANSWER | 2 | One vocabulary, one comprehension |
| FILL_BLANK | 2 | Lesson-specific sentences only |
| ORDERING | 1 | Word order in a sentence |
| PRONUNCIATION | 3 | Three lesson words (was 0–1; now mandatory baseline) |
| **Total** | **13** | **≥1 difficulty-3** |

### 4.5 Math — numbers 0-20 lesson

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 3 | Image-MCQ counting + numeral recognition |
| TRUE_FALSE | 2 | Comparison statements |
| SHORT_ANSWER | 2 | Numeral writing + word→numeral |
| FILL_BLANK | 2 | Number-line cloze |
| ORDERING | 1 | Order 4 numbers ascending or descending |
| TRACING | 2 | Trace the Arabic + Western numeral form |
| **Total** | **12** | **≥1 difficulty-3** (multi-step: "What number is 3 more than 5?") |

### 4.6 Math — operations lesson (addition, subtraction)

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 4 | Mix of computation + word problem |
| TRUE_FALSE | 2 | Equation truth ("3+4=8") |
| SHORT_ANSWER | 2 | Plain computation |
| FILL_BLANK | 3 | "5 + ___ = 8" |
| ORDERING | 1 | Order 3 results of computations |
| **Total** | **12** | **≥1 difficulty-3** (2-step word problem) |

### 4.7 Math — geometry/measurement lesson

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 3 | Image-MCQ shape identification |
| TRUE_FALSE | 2 | Property statements |
| SHORT_ANSWER | 2 | Name the shape / read the clock |
| FILL_BLANK | 2 | Cloze |
| ORDERING | 1 | Order objects by size/weight/length |
| **Total** | **10** | **≥1 difficulty-3** |

### 4.8 Religion — Surah lesson (~11 surahs across `re1_p1` + `re1_p2`)

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 2 | Surah meaning + facts (number of ayahs, where revealed) |
| TRUE_FALSE | 1 | Statement about the surah |
| SHORT_ANSWER | 2 | Specific ayah completion |
| FILL_BLANK | 2 | **Per-surah unique stems** — no template reuse |
| ORDERING | 1 | Order the ayahs of the surah |
| PRONUNCIATION | 3 | Three ayahs OR the full short surah, with reciter audio |
| **Total** | **11** | **≥1 difficulty-3** (full-surah recitation or meaning interpretation) |

### 4.9 Religion — procedural lesson (Wudu, Salah)

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 2 | Image-MCQ: which step is this? |
| TRUE_FALSE | 1 | Procedural correctness statement |
| SHORT_ANSWER | 2 | Name the step |
| FILL_BLANK | 2 | Cloze in a procedural sentence |
| ORDERING | 2 | **Mandatory**: step-ordering — Wudu (6 steps), Salah rakaa (4-7 steps) |
| PRONUNCIATION | 2 | The duʿā or takbir said during the step |
| **Total** | **11** | **≥1 difficulty-3** (full sequence with distractor steps) |

### 4.10 Religion — Prophet stories / Adab lesson

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 3 | Story comprehension |
| TRUE_FALSE | 2 | Value statements about the adab |
| SHORT_ANSWER | 2 | Recall details |
| FILL_BLANK | 2 | Lesson-specific sentences |
| ORDERING | 1 | Story sequence (5-6 events) |
| **Total** | **10** | **≥1 difficulty-3** |

---

### 4.11 Arabic — narrative / reading-comprehension lesson (Grade 3+)

Reading at Grade 3 onward centers on **multi-paragraph passages** rather than letter recognition. Each lesson's `content` field holds the textbook's full reading passage (200-500 words); all 12 questions reference back to it.

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 3 | Literal recall, inference, main idea — in that order |
| TRUE_FALSE | 2 | One straightforward, one misleading |
| SHORT_ANSWER | 2 | One vocabulary (synonym/antonym), one open recall |
| FILL_BLANK | 2 | Vocabulary in passage context |
| ORDERING | 1 | Re-order story events OR re-order words to form a sentence |
| PRONUNCIATION | 2 | Read short sentences from the passage (not single words — students have moved past G1 single-word recitation) |
| **Total** | **12** | **≥1 difficulty-3** |

**No TRACING** for G3+: students have mastered handwriting and the textbook doesn't teach it anymore.

**Sub-skill mix**: comprehension (5), production (4), application (1), pronunciation (2).

### 4.12 Arabic — grammar concept lesson (Grade 3+)

Grade 3 introduces formal grammar concepts (verb/noun/particle identification, gender, number, demonstrative pronouns). These lessons don't have narrative passages; they have rule explanations + example words.

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 4 | "What kind of word is X?" — answer = grammatical category |
| TRUE_FALSE | 2 | Rule statements ("الفعل يدل على حدث") |
| SHORT_ANSWER | 2 | Apply the rule — "Give an example of a verb" |
| FILL_BLANK | 2 | Complete a sentence with the correct grammatical form |
| ORDERING | 1 | Re-order words to form a grammatically correct sentence |
| PRONUNCIATION | 1 | Read an example sentence demonstrating the concept |
| **Total** | **12** | **≥1 difficulty-3** |

**No TRACING** (G3+). **Sub-skill mix**: recognition (4), comprehension (2), production (4), application (1), pronunciation (1).

### 4.13 Math — multi-step word problem lesson (Grade 3+)

Grade 3+ introduces two-operation word problems ("Sara has 5 apples, gives 2 to her brother, then buys 7 more — how many?"). These are higher cognitive load than G1/G2 single-operation problems.

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 4 | Two single-step, two multi-step word problems |
| TRUE_FALSE | 2 | Statement about numerical relationship |
| SHORT_ANSWER | 3 | Pure calculation OR translation of word→equation |
| FILL_BLANK | 2 | Complete an equation OR fill in a missing operand |
| ORDERING | 1 | Re-order steps to solve a problem |
| **Total** | **12** | **≥1 difficulty-3** |

**No PRONUNCIATION** (math has no oral component at this level). **No TRACING**. **Sub-skill mix**: comprehension (2), computation (5), production (3), application (2).

### 4.14 Civics / geography lesson (Grade 4)

Grade 4 introduces civic concepts (Palestinian government structure, geography, national symbols). Existing subjects don't have a civics lesson type but if/when one is added, this is the template.

| Type | Count | Notes |
|------|------:|-------|
| MCQ | 4 | Factual recall — capitals, dates, names |
| TRUE_FALSE | 2 | Civic concept statements |
| SHORT_ANSWER | 2 | One-word fact answers |
| FILL_BLANK | 2 | Sentence with key civic vocabulary |
| ORDERING | 1 | Re-order historical events OR geographic features by size |
| PRONUNCIATION | 1 | Read an Arabic civic vocabulary phrase |
| **Total** | **12** | **≥1 difficulty-3** |

**No TRACING**. **Sub-skill mix**: recognition (4), comprehension (2), production (4), application (1), pronunciation (1).

---

## 5. Difficulty calibration

| Level | Definition | % of bank target |
|------:|------------|-----------------:|
| 1 | Direct recall from lesson content; one-step | ~60% |
| 2 | Application: applying lesson concept to a new instance; word problem with one transformation | ~30% |
| 3 | Synthesis or multi-step: combining concepts within the lesson, full-surah recitation, image-MCQ with similar-sounding distractors, 2-step math word problem | ~10% |

**Hard floor**: Every lesson has ≥1 difficulty-3 question. The audit fails the build otherwise.

## 6. Sub-skill tags (NEW — drives mastery analytics)

Every question carries a sub-skill tag in the JSON (added in this revision). Mastery is tracked per sub-skill, not just per lesson. Subjects:

| Subject | Sub-skills |
|---------|-----------|
| Arabic | `recognition`, `production`, `pronunciation`, `handwriting`, `comprehension` |
| English | `recognition`, `production`, `pronunciation`, `handwriting`, `comprehension` |
| Math | `recognition`, `computation`, `application`, `handwriting` |
| Religion | `memorization`, `recitation`, `comprehension`, `application` |

Mapping by question type (default — overridable per-question):
- MCQ → `recognition` (or `comprehension` if it's a reading-passage MCQ)
- TRUE_FALSE → `comprehension`
- SHORT_ANSWER → `production`
- FILL_BLANK → `production`
- ORDERING → `application`
- PRONUNCIATION → `pronunciation` (or `recitation` for Religion)
- TRACING → `handwriting`

## 7. Mastery policy

A lesson is considered **mastered** when:
- Student scores ≥80% on the lesson's questions, AND
- Across **at least 2 sittings separated by ≥24h** (spaced retrieval).

Stars per attempt:
- **3 stars**: ≥80% on first try, no retry-queue use.
- **2 stars**: ≥60% on first try, OR ≥80% on second try after retry-queue.
- **1 star**: completed only after retry-queue, with ≥60% on second pass.
- **0 stars**: lesson not completed (student abandoned or scored <60% twice).

The retry-queue caps re-queued questions at 1 star to discourage trial-and-error.

## 8. Image / audio asset rules

### 8.1 Layout

```
backend/src/main/resources/static/assets/questions/
├── ar/
│   ├── letters/
│   │   ├── ra/         # حرف الراء — words, scenes
│   │   └── ...
│   └── themes/
├── en/
│   ├── alphabet/
│   │   ├── a/
│   │   └── ...
│   └── vocab/
├── ma/
│   ├── numbers/
│   ├── shapes/
│   └── ...
└── re/
    ├── surahs/
    │   ├── fatiha/    # full Surah audio + per-ayah audio
    │   └── ...
    ├── wudu/
    └── salah/
```

### 8.2 Format conventions

- **Images**: PNG, ≤200KB each, transparent background where possible. Filename = `subject_topic_keyword.png` (e.g. `ar_ra_remmaan.png` for رمان under حرف الراء).
- **Audio**: MP3 (preferred — universal browser support) or M4A. ≤500KB per file. Sample rate 44.1kHz mono. Filename includes reciter for Religion: `re_fatiha_mishary.mp3`, `re_fatiha_hudhaifi.mp3`.
- **JSON reference**: relative path from `static/`. `imageUrl: "/assets/questions/ar/letters/ra/remmaan.png"` (Spring serves it at that exact URL).

### 8.3 Bundle size budget

Total `static/assets/questions/` ≤ 25MB across all 4 grades. Grade 1 alone ≤ 8MB. Audit checks at build time.

### 8.4 Sourcing & rights (demo scope)

- **Quranic recitation**: Mishary Rashid Alafasy + Ali Al-Hudhaifi public-domain MP3s (verses-only) acceptable for educational demo.
- **Cliparts**: Use freepik educational pack or OpenClipart (CC0). Avoid copyrighted character art.
- **Attribution**: maintain a single `assets/CREDITS.txt` in the assets folder listing source per asset.

## 9. JSON schema (canonical)

```json
{
  "subject": "اللغة العربية",
  "subjectCode": "ar",
  "gradeLevel": 1,
  "semester": 1,
  "lessons": [
    {
      "title": "حرف الراء",
      "orderIndex": 1,
      "content": "...",
      "objectives": "...",
      "questions": [
        {
          "type": "MCQ",
          "questionText": "أي صورة تبدأ بحرف الراء؟",
          "correctAnswer": "رمان",
          "options": ["رمان", "سمكة", "قمر", "نجمة"],
          "difficultyLevel": 1,
          "subSkill": "recognition",
          "imageUrl": "/assets/questions/ar/letters/ra/remmaan.png",
          "audioUrl": null
        }
      ],
      "imageUrls": []
    }
  ]
}
```

New fields: `subSkill`, `imageUrl`, `audioUrl` (all nullable). Old JSON without them remains valid; absent fields default to (auto-mapped sub-skill, null, null).

## 10. Quality gates (audit lint enforces these — `QuestionAuditTest`)

The audit is split into two checks:

- **`auditCurriculumSchemaIntegrity()`** — fails the build on R1, R3–R11, R14, RU. These are content-quality + schema-integrity rules.
- **`auditCurriculumQualityWarnings()`** — prints to stderr but does NOT fail the build for R12, R13, R15–R18 (mostly asset-existence checks that the asset-bundling pass has not yet shipped).

Numbered rules (R prefix matches the audit error messages):

| # | Rule | Severity |
|---|------|----|
| R1 | MCQ `correctAnswer ∉ options` | **strict** |
| R3 | TRUE_FALSE has non-null `options` OR invalid `correctAnswer`; FILL_BLANK missing the `___` marker | **strict** |
| R4 | MCQ has fewer than 3 or more than 5 options | **strict** |
| R5 | ORDERING `correctAnswer` shape wrong (need ≥3 comma-separated items matching `options`) | **strict** |
| R6 | ORDERING `options` null or has fewer than 3 elements; or non-MCQ/non-ORDERING type has options | **strict** |
| R7 | `difficultyLevel ∉ {1,2,3}` | **strict** |
| R8 | Lesson has fewer than 8 questions | **strict** |
| R9 | Lesson has zero difficulty-3 questions | **strict** |
| R10 | Two questions in the same subject share `questionText` (case-insensitive trimmed) | **strict** |
| R11 | MCQ with options `["صح","خطأ"]` (should be TRUE_FALSE) | **strict** |
| R12 | Question with non-null `imageUrl` whose file does not exist | warning |
| R13 | Question with non-null `audioUrl` whose file does not exist | warning |
| R14 | Lesson covers fewer than 3 distinct sub-skills | **strict** |
| R15 | Religion Surah lesson has zero PRONUNCIATION questions | warning |
| R16 | Religion procedural lesson has zero ORDERING questions | warning |
| R17 | Arabic letter lesson has fewer than 2 TRACING questions | warning |
| R18 | English alphabet lesson has fewer than 1 TRACING question per letter taught | warning |
| RU | Universal: empty `questionText` / `correctAnswer`, unknown `type`, invalid `subSkill` | **strict** |

R12, R13, R15–R18 will be promoted to strict once the asset-bundling pass adds image/audio under `static/assets/questions/...`.

## 11. Workflow when adding a new lesson

1. **Pick the template** from §4.
2. **Source assets** (images + audio) into `static/assets/questions/<subject>/<topic>/`.
3. **Write the JSON** following §9 schema, citing the textbook (page) in `objectives` for traceability.
4. **Run** `./gradlew test` — `QuestionAuditTest` must pass.
5. **Manual smoke test**: `./gradlew bootRun`, log in as student, navigate to the lesson, confirm every question renders + scores correctly (especially image/audio loads).
6. **Commit** with message `curriculum: <subject> <topic> — <N> questions`.

## 12. Re-seeding the dev database

For a clean rebuild after curriculum changes:

```yaml
manhaji:
  curriculum:
    reseed: true   # one-time: deletes all subjects/lessons/questions, re-inserts from JSON
```

Boot once with `reseed: true`, then flip back to `false`. **Existing student attempts and responses ARE wiped** (CASCADE), so this is a development convenience only — never run on production.

## 13. Open items & future revisions

- **Multi-answer SHORT_ANSWER** (alternates/synonyms) — not yet supported; current scoring is exact-match. Low-priority; flag a question with `// TODO: alternates` comment if you encounter ambiguity.
- **Image-MCQ with image options** — currently `imageUrl` is on the question, not on each option. If we add option-level images, schema bump required.
- **Adaptive difficulty within a session** — current adaptive engine is across-attempts. In-session difficulty adjustment (skip easy if student is acing) is a future enhancement.
- **Spaced repetition scheduler** — mastery requires 2 sittings ≥24h apart, but the app currently does not enforce the time gap server-side. Backend should track per-attempt timestamps and surface "review due" lessons in the home screen.

---

**Last updated:** 2026-04-25 (initial spec, written ahead of Grade 1 backfill + grades 2-4 expansion).

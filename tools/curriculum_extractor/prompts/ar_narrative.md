# Arabic — Narrative / Reading Comprehension Lesson Template

You are drafting a lesson for an AI-powered learning app used by Palestinian Grade 3 and Grade 4 students. Your output MUST be valid JSON conforming exactly to the schema below.

## Output schema (return EXACTLY this shape — no markdown, no extra prose)

```json
{
  "title": "<short Arabic title — 2-5 words, matches the textbook chapter>",
  "orderIndex": <integer, matches the chapter's order in the part>,
  "content": "<the reading passage from the textbook, 200-500 Arabic words>",
  "objectives": "<2-3 Arabic learning objectives, comma-separated>",
  "questions": [
    {
      "type": "MCQ",
      "questionText": "<Arabic prompt that references the passage>",
      "correctAnswer": "<one of the options>",
      "options": ["A", "B", "C", "D"],
      "difficultyLevel": 1,
      "subSkill": "comprehension"
    },
    ...
  ],
  "imageUrls": []
}
```

## Per-lesson rules (G3/G4 narrative template — spec §4.11)

Every lesson MUST have **EXACTLY 12 questions** in this order and mix:

| # | type           | difficulty | subSkill        | purpose                                |
|---|----------------|------------|-----------------|----------------------------------------|
| 1 | MCQ            | 1          | comprehension   | Literal fact recall from passage       |
| 2 | MCQ            | 2          | comprehension   | Inference / why questions              |
| 3 | MCQ            | 2          | comprehension   | Main idea / theme                      |
| 4 | TRUE_FALSE     | 1          | comprehension   | Simple factual statement               |
| 5 | TRUE_FALSE     | 2          | comprehension   | Misleading statement requiring thought |
| 6 | SHORT_ANSWER   | 2          | production      | Vocabulary — synonym/antonym           |
| 7 | SHORT_ANSWER   | 1          | production      | Open recall (1-3 word answer)          |
| 8 | FILL_BLANK     | 1          | production      | Vocabulary in sentence context         |
| 9 | FILL_BLANK     | 2          | production      | Grammatical/conceptual fill            |
| 10 | ORDERING      | 3          | application     | Re-order story events OR re-order words to form a sentence |
| 11 | PRONUNCIATION | 1          | pronunciation   | Read a short sentence from the passage |
| 12 | PRONUNCIATION | 2          | pronunciation   | Read a slightly longer phrase          |

**Do NOT include TRACING items for G3/G4** — students have mastered handwriting and the textbook doesn't teach it anymore.

## Universal rules (spec §2)

- All Arabic text. No English words mixed in. No Arabic translation prompts ("ما معنى X؟" is fine; "What is 'X' in English?" is NOT — this is the Arabic-language lesson).
- `correctAnswer` is non-empty for every question.
- For MCQ: `correctAnswer` MUST be exactly one of the `options` strings. `options` has 4 entries (3-5 allowed; 4 is conventional).
- For TRUE_FALSE: `correctAnswer` MUST be `"صح"` or `"خطأ"`. `options` MUST be `null` (omit the field).
- For SHORT_ANSWER, FILL_BLANK, PRONUNCIATION: `options` MUST be `null` (omit).
- For FILL_BLANK: `questionText` MUST contain exactly one `___` marker showing where the blank is.
- For ORDERING: `correctAnswer` is the comma-separated correct sequence; `options` lists the items to re-order (3-6 items).
- Question text ≤500 characters.
- Use the EXACT Arabic words/names from the reading passage when asking comprehension questions.

## Quality bar

- **Distractors matter.** Wrong MCQ options should be plausible at first glance but clearly wrong on careful reading. Avoid:
  - "All of the above" / "None of the above" style distractors
  - Distractors that are obviously absurd (a child would never pick them)
  - Distractors that share many words with the correct answer (giveaway by elimination)
  - One-option-much-longer-than-others (the longest answer becomes the obvious pick)
- **Passage-grounded.** Every comprehension question's answer should be findable in (or directly inferable from) the passage you put in `content`.
- **Cultural fit.** Use Palestinian-relevant names (عمر، ليلى، سامي، ياسمين، نور، خالد) and contexts. Avoid Western references unless they appear in the textbook.
- **Difficulty calibration:**
  - Level 1 = direct recall, one-step thinking, common vocabulary
  - Level 2 = inference, two-step thinking, moderate vocabulary
  - Level 3 = synthesis, multi-step ordering, less-common vocabulary

## Sub-skill values (use EXACTLY one of these)

`comprehension`, `production`, `pronunciation`, `application`, `recognition`, `memorization`, `recitation`

## One full worked example (mirror this shape exactly)

The example below is from Grade 2 (`ar2_p1.json` lesson 1) — it scored 84/100 in the May 2026 curriculum audit and is the gold standard for narrative-comprehension lessons:

```json
{
  "title": "الحرّيّة أجمل",
  "orderIndex": 1,
  "content": "بلبل جميل في قفص داخل بيت، يأكل ويشرب لكنه حزين، لأنه فقد حرّيّته. عصفور يطير حرّاً يقول له: الحرّيّة أجمل من كل شيء. الدرس يعلّمنا أن الحرّيّة قيمة عظيمة.",
  "objectives": "فهم النص، استنتاج قيمة الحرّيّة، توظيف مفردات (قفص، حر، حرّيّة، حزين).",
  "questions": [
    {"type": "MCQ", "questionText": "في الدرس، أين كان البلبل؟", "correctAnswer": "في قفص داخل بيت", "options": ["يطير في السماء", "في قفص داخل بيت", "على الشجرة", "في الغابة"], "difficultyLevel": 1, "subSkill": "comprehension"},
    {"type": "MCQ", "questionText": "لماذا كان البلبل حزيناً رغم الطعام والشراب؟", "correctAnswer": "لأنه فقد حرّيّته", "options": ["لأنه جائع", "لأنه فقد حرّيّته", "لأنه مريض", "لأنه يكره الطعام"], "difficultyLevel": 2, "subSkill": "comprehension"},
    {"type": "MCQ", "questionText": "ما القيمة الرئيسية في الدرس؟", "correctAnswer": "الحرّيّة قيمة عظيمة لا تعدلها نعمة", "options": ["الطعام أهم شيء", "الحرّيّة قيمة عظيمة لا تعدلها نعمة", "النوم خير من العمل", "السفر متعة"], "difficultyLevel": 2, "subSkill": "comprehension"},
    {"type": "TRUE_FALSE", "questionText": "أحبّ البلبل القفص وفرح به", "correctAnswer": "خطأ", "options": null, "difficultyLevel": 1, "subSkill": "comprehension"},
    {"type": "TRUE_FALSE", "questionText": "الحرّيّة من أجمل ما يطلبه الإنسان والحيوان", "correctAnswer": "صح", "options": null, "difficultyLevel": 1, "subSkill": "comprehension"},
    {"type": "SHORT_ANSWER", "questionText": "ما ضدّ كلمة 'حر'؟", "correctAnswer": "أسير", "options": null, "difficultyLevel": 2, "subSkill": "production"},
    {"type": "SHORT_ANSWER", "questionText": "اذكر طائراً يحب الحرّيّة كالبلبل", "correctAnswer": "العصفور", "options": null, "difficultyLevel": 1, "subSkill": "production"},
    {"type": "FILL_BLANK", "questionText": "أكمل: الحرّيّة ___ من كل شيء", "correctAnswer": "أجمل", "options": null, "difficultyLevel": 1, "subSkill": "production"},
    {"type": "FILL_BLANK", "questionText": "أكمل: البلبل كان في ___ داخل البيت", "correctAnswer": "قفص", "options": null, "difficultyLevel": 2, "subSkill": "production"},
    {"type": "ORDERING", "questionText": "رتّب الأحداث: العصفور يرى البلبل / البلبل في القفص / البلبل يحزن / العصفور يخبره عن الحرّيّة", "correctAnswer": "البلبل في القفص، البلبل يحزن، العصفور يرى البلبل، العصفور يخبره عن الحرّيّة", "options": ["العصفور يرى البلبل", "البلبل في القفص", "البلبل يحزن", "العصفور يخبره عن الحرّيّة"], "difficultyLevel": 3, "subSkill": "application"},
    {"type": "PRONUNCIATION", "questionText": "اقرأ: الحرّيّة أجمل من كل شيء", "correctAnswer": "الحرّيّة أجمل من كل شيء", "options": null, "difficultyLevel": 1, "subSkill": "pronunciation"},
    {"type": "PRONUNCIATION", "questionText": "اقرأ: البلبل في قفص داخل بيت يأكل ويشرب لكنه حزين", "correctAnswer": "البلبل في قفص داخل بيت يأكل ويشرب لكنه حزين", "options": null, "difficultyLevel": 2, "subSkill": "pronunciation"}
  ],
  "imageUrls": []
}
```

## Your task

Read the extracted chapter content below (which includes the textbook's full text, learning objectives, and any reading passage). Draft a lesson JSON following the template + rules above. Return ONLY the JSON object — no preamble, no explanation, no markdown fences.

If the chapter content lacks a clear narrative (e.g. it's a grammar concept page or a list of vocabulary words without context), say so by returning a JSON object with a single key `error` and a brief explanation in Arabic — then a human will use a different template instead.

---

**Extracted chapter content:**

{CHAPTER_JSON}

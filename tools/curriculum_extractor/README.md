# Manhaji Curriculum Extractor

End-to-end pipeline for turning a Palestinian MoE textbook PDF into a draft `lesson.json` ready to drop into `Manhaji/backend/src/main/resources/curriculum/`. Built specifically for the Grade 3 + Grade 4 backfill (where the volume jump makes hand-authoring infeasible) but also works for re-extracting G1/G2 if needed.

The pipeline is **AI-assisted** — Gemini drafts each lesson's questions from the extracted chapter; **you** review and edit before merging. The tooling automates the mechanical parts (PDF parsing, image extraction, JSON shape validation) and uses an AI model on the part humans are slowest at (writing 12 well-formed questions per lesson).

---

## The three steps

```
    PDF ─→ extract.py ─→ chapter.json + images/
                              ↓
                          draft.py (calls Gemini)
                              ↓
                          draft_lesson.json
                              ↓
                          lint.py  →  CLEAN
                              ↓
                          author reviews & edits
                              ↓
                          merge into curriculum/<file>.json
                              ↓
                          gradle test --tests "*QuestionAuditTest*"
```

Each step is a separate CLI so you can re-run any of them in isolation. Re-extracting a chapter doesn't re-call Gemini; re-drafting doesn't re-extract.

---

## Setup

```bash
# Install Python deps (one-time)
cd "Manhaji Claude"
pip install -r tools/curriculum_extractor/requirements.txt

# Export the Gemini API key (same key the backend uses)
# PowerShell:
$env:GEMINI_API_KEY = "<your-key>"
# Bash/Zsh:
export GEMINI_API_KEY="<your-key>"
```

The key lives in your env, not in any file in the repo. It's the same key configured as `app.ai.gemini.api-key` in `Manhaji/backend/src/main/resources/application.yaml`.

---

## Step 1 — Extract chapters from a PDF

```bash
# First, list the chapters detected so you can sanity-check:
python tools/curriculum_extractor/extract.py \
    "PDFBooks/3Grade/لغتنا الجميلة/ar3-p1.pdf" --list

# Output:
#   Found 6 chapters in ar3-p1.pdf:
#     [ 1] pages 9-18: ذهب ال
#     [ 2] pages 19-28: الارنب والس لحفاه
#     ...

# Then extract one chapter (or all):
python tools/curriculum_extractor/extract.py \
    "PDFBooks/3Grade/لغتنا الجميلة/ar3-p1.pdf" \
    --chapter 2 \
    --out tools/curriculum_extractor/_out/ar3_p1

# Or all chapters:
python tools/curriculum_extractor/extract.py \
    "PDFBooks/3Grade/لغتنا الجميلة/ar3-p1.pdf" \
    --out tools/curriculum_extractor/_out/ar3_p1
```

### What `extract.py` produces

Under your `--out` directory:

```
ar3_p1/
├── chapters.json                              # all 6 chapter spines
├── ch01_ذهب_ال.json                          # ChapterContent for chapter 1
├── ch01_ذهب_ال/                              # extracted images for chapter 1
│   ├── p009_x123.png
│   └── p012_x456.png
├── ch02_الارنب_والس_لحفاه.json
├── ch02_الارنب_والس_لحفاه/
└── ...
```

Each `ch<N>_<slug>.json` has:
- `title`, `orderIndex`, `page_range`
- `objectives` — extracted from the textbook's `النتاجات` block (if present)
- `full_text` — every word in the chapter, in reading order
- `reading_passage` — the longest paragraph (≥120 chars) — usually the textbook's main narrative for Arabic/Religion chapters
- `images[]` — list of `{page, rel_path, width, height, classification, surrounding_text}` per extracted image

### Known limitations of chapter detection

PDF detection quality varies by subject:

| Subject | Quality | Notes |
|---|---|---|
| Arabic G3/G4 | ⭐⭐⭐⭐ | Chapter spine usually correct; titles partly mangled by PDF rendering artifacts (you may want to clean them) |
| English G3/G4 | ⭐⭐⭐⭐⭐ | Clean — Macmillan's "UNIT" cover-page convention is reliable |
| Religion G3/G4 | ⭐⭐⭐⭐ | Similar to Arabic |
| Math G3/G4 | ⭐⭐ | Lots of false positives — Math has nested structure (Unit→Lesson→Section) and "الدرس" appears throughout. Always `--list` first and pass `--chapter N` explicitly for math. |

If a chapter title is mangled, edit the resulting `chN_*.json` file's `title` field by hand before running `draft.py`. The draft prompt uses your edited title.

---

## Step 2 — Draft questions via Gemini

```bash
# Available templates (more added as new lesson types are encoded):
python tools/curriculum_extractor/draft.py --list-templates
# → ar_narrative

# Draft a lesson from an extracted chapter:
python tools/curriculum_extractor/draft.py \
    "tools/curriculum_extractor/_out/ar3_p1/ch02_الارنب_والس_لحفاه.json" \
    --template ar_narrative \
    --out "tools/curriculum_extractor/_out/ar3_p1/ch02_draft.json"

# Dry-run to inspect the prompt without spending tokens:
python tools/curriculum_extractor/draft.py \
    "tools/curriculum_extractor/_out/ar3_p1/ch02_الارنب_والس_لحفاه.json" \
    --template ar_narrative --dry-run
```

### How the template + prompt work

Each prompt template (under `prompts/`) is a markdown file split into two sections by the `## Your task` heading:
- **Above** → system prompt sent as `system_instruction` (spec rules, schema, gold-standard example)
- **Below** → user prompt with `{CHAPTER_JSON}` replaced by your extracted chapter

The drafter calls Gemini 2.5 Flash with `response_mime_type: application/json` so the response parses directly. Temperature defaults to 0.4 (low enough that structure stays consistent, high enough that prompts get varied phrasing).

### Templates included

| Template | Use case | Based on spec § |
|---|---|---|
| `ar_narrative` | Arabic reading-comprehension lessons with a passage (G3+) | §4.11 |

Roadmap (not yet built — author can clone `ar_narrative.md` as the starting point):
- `ar_grammar` (G3+ grammar lessons — §4.12)
- `ma_arithmetic` (G1/G2 already has these; G3+ adds multi-step word problems — §4.13)
- `ma_geometry` (§4.7)
- `en_vocab` (G1/G2/G3/G4 — vocabulary themes)
- `en_grammar` (G3+ — present continuous, plural forms, etc.)
- `re_surah` (§4.8 — Surah memorization with mandatory PRONUNCIATION)
- `re_procedural` (§4.9 — wudu, salah with ORDERING)
- `re_story` (§4.10 — prophet stories)

To add a new template, copy `prompts/ar_narrative.md`, change the per-lesson rules table + gold-standard example, save as `prompts/<your_name>.md`. The CLI picks it up automatically (`--list-templates`).

### Why we provide a worked example in every template

The `ar_narrative` prompt includes a full Grade 2 lesson (الحرّيّة أجمل) as an in-template example. This is **3-shot prompting** at its most concrete — Gemini sees one complete, audit-passing lesson and produces output in the same shape. Without the example, the drafts drift toward generic ESL question patterns.

---

## Step 3 — Lint the draft

```bash
python tools/curriculum_extractor/lint.py \
    "tools/curriculum_extractor/_out/ar3_p1/ch02_draft.json"
# → [lint] ch02_draft.json: CLEAN
```

The Python lint mirrors `Manhaji/backend/src/test/java/com/springboot/manhaji/infrastructure/QuestionAuditTest.java`'s strict rules (R1, R3-R11, R14, RU) so you get the same audit verdict in milliseconds instead of spinning up gradle.

It checks:
- **R1** — MCQ `correctAnswer ∈ options`
- **R3** — TRUE_FALSE / FILL_BLANK shape
- **R4** — MCQ options count ∈ [3,5]
- **R5/R6** — ORDERING shape
- **R7** — `difficultyLevel ∈ {1,2,3}`
- **R8** — Lesson has ≥8 questions
- **R9** — Lesson has ≥1 difficulty-3
- **R10** — Duplicate `questionText` within the file
- **R11** — MCQ with TF-shaped options
- **R14** — Lesson covers ≥3 distinct sub-skills
- **RU** — empty fields, unknown types, invalid sub-skills

What it doesn't check (the gradle audit does):
- Cross-file dedup
- Asset file existence (`imageUrl` / `audioUrl` files on disk)

After the python lint passes, run the gradle audit as a final check before pushing:

```bash
cd "Manhaji Claude/Manhaji/backend"
./gradlew test --tests "*QuestionAuditTest*"
```

---

## Step 4 — Review, merge, ship

The Gemini draft is **a first draft**, not the final word. Things you should review per chapter:

1. **Title** — fix any PDF-extraction artifacts (e.g. "الارنب والس لحفاه" → "الأرنب والسلحفاة"). Make sure it matches the textbook chapter.
2. **content** (the reading passage) — confirm it's the right passage and not a header/footer fragment. Gemini cleans it up reasonably but textbook ligature artifacts can survive.
3. **Distractor quality** — read each MCQ's wrong options. Are they plausible? Same length as the correct answer? Not obvious by elimination? This is where the May 2026 audit dinged G2 narrative lessons most.
4. **Cultural fit** — are the names Palestinian? Does the worldview match (e.g. Religion lessons stay within Sunni Islamic tradition; values match Palestinian K-12 norms)?
5. **Image relevance** — the extractor pulls every image > 80x80; some may be decorative page borders. Drop them from `imageUrls` if not pedagogically useful.

Then merge into the canonical curriculum:

```bash
# The drafted lesson JSON drops directly as one entry in the file's lessons[]
# array. The naming convention is:
#   ar3_p1.json → all Grade 3 Arabic Part 1 lessons
#   ar3_p2.json → all Grade 3 Arabic Part 2 lessons
#   etc.
```

After merging, re-run the gradle audit and `gradle test` to confirm nothing regressed.

---

## Cost + speed envelope

Per Gemini 2.5 Flash call at default config (~5K input tokens, ~3K output):
- ~$0.003 (one-third of a US cent) per chapter
- ~3-8 seconds wall-clock per chapter

A whole Grade 3 subject (~10 chapters × 4 subjects × 2 parts = 80 chapters) costs ~$0.25 and ~10 minutes of API time — vs ~80 hours hand-authoring. The human review pass is the real time cost; budget ~15-20 minutes per chapter for careful review + edits.

---

## Troubleshooting

**"ERROR: GEMINI_API_KEY is not set"** — export the key in your current shell. The drafter reads `os.environ['GEMINI_API_KEY']` at runtime.

**"ERROR: no chapters detected in <pdf>"** — the PDF doesn't have TOC bookmarks AND has no recognized heading patterns. Check `extract.py --list` output; if completely empty, the PDF may be all-image (a scan). Re-OCR with a tool like `ocrmypdf` first, then retry.

**"Gemini returned text that isn't valid JSON"** — the model occasionally returns prose. Lower `--temperature` to 0.2, or use `--dry-run` to inspect the prompt and tighten the instructions in the template.

**Lint says R10 — duplicate questionText within file** — Gemini reused phrasing from the in-template example. Edit the duplicates to use different question stems.

**Lint says R1 — MCQ correctAnswer not in options** — Gemini sometimes drops a typo into one but not the other. Fix by hand; usually one character off.

**Image quality looks low** — `_pdf.py` resizes anything >800px on either dimension to keep the `static/assets/questions/` bundle under spec §8.3's budget. If you need full-resolution images for a specific figure, edit the constants `MAX_IMG_DIM` and `MIN_IMG_AREA` in `_pdf.py`.

---

## File layout

```
tools/curriculum_extractor/
├── README.md             # this file
├── requirements.txt      # Python deps
├── extract.py            # CLI: PDF → chapter JSON + images
├── draft.py              # CLI: chapter JSON + template → AI draft
├── lint.py               # CLI: validate against spec §10 rules
├── _pdf.py               # PDF helpers (chapter spine, image extraction)
├── _gemini.py            # Gemini client wrapper
├── prompts/
│   └── ar_narrative.md   # Arabic reading-comprehension template (§4.11)
└── _out/                 # default extraction output dir (gitignored)
```

`_out/` is meant to be ephemeral — it's where intermediate JSONs and images land. Final curriculum JSONs go under `Manhaji/backend/src/main/resources/curriculum/`; final assets go under `Manhaji/backend/src/main/resources/static/assets/questions/`.

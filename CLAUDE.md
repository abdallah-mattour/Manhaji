# Manhaji — Project Guide for Claude

AI-powered personalized learning app for Palestinian Grade 1 students. Birzeit University CS graduation project. **Deadline: July 1, 2026** (graduation showcase — optimize for demo impact, not production hardening).

Repo owner: Abdallah Mattour (solo dev on Claude-assisted workstreams).

## Repo layout

The git root is `C:\Users\abdal\Desktop\Manhaji Claude\` but **all code lives under `Manhaji/`**. Top-level holds PDFs, screenshots, and one .docx proposal.

```
Manhaji Claude/               <-- git root; open Claude Code here
├── Manhaji/
│   ├── backend/               Spring Boot 4.0.5, Java 17, Gradle Kotlin DSL
│   │   └── src/main/java/com/springboot/manhaji/
│   │       ├── controller/    REST controllers (Auth, Quiz, Lesson, Progress, Teacher, Parent, Admin, Audio, ProgressReport)
│   │       ├── service/       Business logic (same modules) + ai/ + storage/ + support/
│   │       │   └── ai/        GeminiService, WhisperService (Gemini-backed), TtsService, PronunciationScoringService
│   │       ├── entity/        JPA entities + enums/
│   │       ├── dto/           request/ + response/
│   │       ├── repository/    Spring Data JPA
│   │       ├── config/        Security, JWT, CORS
│   │       └── support/       DataSeeder.java (loads JSON curriculum on startup)
│   │   └── src/main/resources/
│   │       ├── application.yaml
│   │       └── curriculum/    ar1_p1.json, ar1_p2.json, en1_*, ma1_*, re1_* (seeded by DataSeeder)
│   ├── manhaji_app/           Flutter 3.10.4, Provider state mgmt
│   │   └── lib/
│   │       ├── models/        quiz.dart, pronunciation_score.dart, lesson.dart, ...
│   │       ├── providers/     auth, learning, lesson, teacher, parent, admin, progress, report
│   │       ├── screens/       splash, auth, home, learning, subject, progress, settings, teacher, parent, admin
│   │       ├── services/      api_service, audio_service, auth_service, tts_service
│   │       ├── widgets/       question_widgets/ (mcq, fill_blank, ordering, short_answer, true_false, pronunciation, tracing), voice_recorder_widget, ...
│   │       ├── config/        api_config.dart (baseUrl)
│   │       └── app/theme.dart (AppTheme constants — ALWAYS use these, not raw Colors)
│   ├── manhaji.sql            Legacy SQL dump (JPA ddl-auto=update creates schema)
│   └── README.md              Auto-generated, ignore
└── PDFBooks/                  Grade 1 textbook PDFs (Arabic/English/Math)
```

## Tech stack

- **Backend**: Spring Boot 4.0.5, Java 17 toolchain, MySQL 8, JPA/Hibernate (`ddl-auto=update`), JWT auth, WebFlux client (for Gemini), Lombok, JUnit 5 + Mockito
- **Frontend**: Flutter 3.10.4, Provider, Dio (HTTP + multipart), just_audio, record, confetti, flutter_animate, fl_chart, cached_network_image. (flutter_tts REMOVED 2026-07-03 — TTS is backend-API only by product decision; the `AudioFocus` singleton in `lib/services/audio_focus.dart` enforces one voice at a time app-wide.)
- **AI services**: Google Gemini 2.5 Flash (generation + transcription — replaced OpenAI Whisper; the class is still named `WhisperService`), Google Cloud TTS
- **Auth**: JWT bearer tokens, role-based (STUDENT / PARENT / TEACHER / ADMIN)
- **Language/locale**: Arabic (RTL) is primary. All UI text uses the **Cairo** font family.

## Running the project

### Backend tests — IMPORTANT: `JAVA_HOME` gotcha

`java` is NOT on PATH and `JAVA_HOME` is NOT set globally on this machine. Gradle will silently exit with code 0 (misleading!) if you just run `./gradlew`. Always export JDK first:

```bash
export JAVA_HOME="/c/Users/abdal/AppData/Local/Programs/Android Studio/jbr"
export PATH="$JAVA_HOME/bin:$PATH"
cd "C:/Users/abdal/Desktop/Manhaji Claude/Manhaji/backend"
./gradlew test       # ~40s cold, ~instant warm
./gradlew bootRun    # starts backend on :8080
```

The JBR bundled with Android Studio is a JDK 21 — works fine with the 17 toolchain spec.

### Flutter

`flutter` is NOT on PATH either. Use the full path:

```bash
/c/Users/abdal/Downloads/flutter_sdk/bin/flutter analyze      # ~85s, expect 6 pre-existing info hints (see below)
/c/Users/abdal/Downloads/flutter_sdk/bin/flutter test         # 41 tests, ~3s
/c/Users/abdal/Downloads/flutter_sdk/bin/flutter run -d <id>  # run on device/emulator
```

### Database

MySQL 8 on `localhost:3306`, db `manhaji_db`, user `root`, password `ben@me` (dev-only). JPA auto-creates/updates schema. DataSeeder populates curriculum from `resources/curriculum/*.json` on startup if DB is empty.

### Android emulator API base URL

`lib/config/api_config.dart` → `http://10.0.2.2:8080/api` (Android emulator's host-loopback alias). For physical device testing, change to host LAN IP.

### Required env vars for AI features

- `GEMINI_API_KEY` — used by `GeminiService` and `WhisperService` (transcription is Gemini, not OpenAI)
- `GOOGLE_TTS_API_KEY` — used by `TtsService`

If unset, defaults to literal `not-set` and AI endpoints return 500. Pronunciation/tracing UIs still render without them; only the scoring call breaks.

### Required env var for JWT auth

- `MANHAJI_JWT_SECRET` — Base64-encoded ≥256-bit random key used by `JwtService` to sign tokens. Generate with `openssl rand -base64 32`. If unset, `application.yaml` falls back to a hardcoded dev-only Base64 string suitable ONLY for the developer's laptop — it is NOT a production secret.

Audit fix S1/S2 (2026-04-29): the previous `app.jwt.secret` was a plaintext string committed to source, and `JwtService.getSigningKey()` round-tripped it through Base64 encode/decode (a no-op). Both are fixed. Set `MANHAJI_JWT_SECRET` in any non-laptop environment.

## Architecture notes

### Backend layering
Standard controller → service → repository with DTOs at boundary. Entity classes use Lombok `@Data @Entity`. Enums live under `entity/enums/` (e.g. `QuestionType`, `Role`, `AttemptStatus`).

### Curriculum seeding (DataSeeder)
`DataSeeder.java` reads JSON files from `resources/curriculum/` and calls `QuestionType.valueOf((String) data.get("type"))`. **Adding a new question type requires only: (1) new enum value, (2) DTO/scoring wiring if needed, (3) seed JSON entries, (4) matching Flutter widget.** No DataSeeder edits.

### Quiz flow
- `Attempt` tracks a student going through a quiz's questions (`IN_PROGRESS` / `COMPLETED`).
- `StudentResponse` stores per-question answers with `isCorrect` and `pointsEarned`.
- `QuizService` exposes `submitAnswer`, `submitPronunciation` (multipart audio → Whisper → PronunciationScoringService), plus standard start/complete.
- `QuizController`: endpoints under `/api/quiz/attempt/{attemptId}/...`.

### Flutter learning flow
- `LearningProvider` (`learning_provider.dart`) owns per-question trackers (attempt count, phase: stepIntro/stepQuestion/stepFeedback/stepRetry, last result, last pronunciation score, last tracing score, stars awarded).
- Retry queue logic: a wrong main-round answer gets re-queued once; second pass only awards 1 star max.
- `LearningScreen._buildAnswerArea()` dispatches on `question.type` → renders the matching widget from `widgets/question_widgets/`.
- Widgets receive `isAnswered` and callbacks; they do NOT hold answer state beyond local UI.

### Pronunciation scoring (Workstream A, shipped; English extended 2026-04-20)
- **Backend**: `PronunciationScoringService` is now **language-aware** via a 3-arg `score(expected, transcribed, language)` overload. Language is auto-detected from the `expected` string (Arabic unicode block U+0600–U+06FF → `ar`, else → `en`). Legacy 2-arg overload defaults to auto-detect.
  - **Arabic path**: strips diacritics `\u064B-\u065F\u0670`, unifies `أإآ→ا`, `ة→ه`, `ى→ي`, then Levenshtein.
  - **English path** (Metaphone-lite): lowercase → strip non-letters → `ph`→`f`, `ck`→`k`, `qu`→`kw`, `x`→`ks`, context-aware `c`→`s/k` → drop silent `kn-`/`wr-`/trailing `-e` → collapse double letters → Levenshtein on phonetic codes. Makes "apple" vs "aple" both normalize to "apl" (score 100).
  - Arabic rating strings unchanged: ممتاز ≥90, جيد جداً ≥75, جيد ≥60, حاول مرة أخرى ≥40, لم أسمعك جيداً otherwise. `isCorrect = score ≥ 60`.
- **Endpoint**: `POST /api/quiz/attempt/{attemptId}/pronunciation` multipart (`audio`, `questionId`, `language=ar` — `QuizService` auto-switches to `en` if the question's `correctAnswer` is non-Arabic script).
- **Graceful fallback**: if `GEMINI_API_KEY` is not exported (the demo laptop forgot to `export GEMINI_API_KEY=...`), `QuizService.submitPronunciation` checks `whisperService.isAvailable()` and returns a friendly zero-score response with feedback `"خدمة النطق غير متاحة الآن"` instead of 500-ing. No DB write in this path.
- **Frontend**: `pronunciation_widget.dart` → `VoiceRecorderWidget` → `AudioService.submitPronunciation()` → `LearningProvider.applyPronunciationResult()`. Processing spinner while awaiting backend.

### Tracing (Workstream B, shipped)
- **Pure client-side**, no backend endpoint. `tracing_widget.dart` captures strokes via `GestureDetector` + `CustomPainter`. Heuristic: bounding-box extent + point count + stroke count → score 0–100, then maps to stars/rating/feedback. `_TemplatePainter` renders target letter as faint blue (alpha 0.18) with user strokes in orange (stroke width 6).
- No ML Kit — intentionally avoided to keep the app offline-capable and bundle small.
- `LearningProvider.applyTracingResult()` mirrors pronunciation's star/retry logic.

### Arabic / RTL conventions
- `Directionality.of(context) == TextDirection.rtl` is assumed across screens.
- Cairo font is declared in `pubspec.yaml` and should be on every `TextStyle` that has Arabic content.
- Use `AppTheme.primaryGreen/Blue/Orange/Red/Yellow`, `AppTheme.textDark/textGray`, not raw `Colors.*`.

## Testing

### Backend (`./gradlew test`)
- JUnit 5 + Mockito. Main test: `QuizServiceTest` covers submit flows including pronunciation. `QuizService` now takes **12 constructor args** (added `WhisperService` + `PronunciationScoringService`); update mocks when adding new dependencies to that constructor.
- No integration tests currently; services are unit-tested with mocked repos.

### Flutter (`flutter test`)
- 41 tests covering providers (auth, admin, teacher, parent, learning, report, progress) and one widget smoke test. Mostly mock-based (mockito) around API service layer.

### Expected analyze baseline (5 info hints, ignore)
```
use_build_context_synchronously   lib/screens/admin/admin_dashboard_screen.dart:24
use_build_context_synchronously   lib/screens/parent/parent_dashboard_screen.dart:24
use_build_context_synchronously   lib/screens/progress/ai_reports_screen.dart:27
use_build_context_synchronously   lib/screens/teacher/class_students_screen.dart:21
use_build_context_synchronously   lib/screens/teacher/teacher_dashboard_screen.dart:25
```
(The old `unnecessary_underscores` hint in teaching_card_widget was fixed 2026-07-03.)

If analyze shows more than 5, your change introduced a new issue — fix before declaring done.

## Recent work completed (as of 2026-04-20)

- **Workstream A (Arabic Pronunciation Scoring)**: ✅ Shipped. Backend + endpoint + Flutter widget + 3 seeded questions (رمان, ريشة, رامي) in `ar1_p1.json` under حرف الراء lesson. Additional Arabic pronunciation questions added across letter-lessons in `ar1_p1.json`.
- **Workstream B (Arabic Letter Tracing)**: ✅ Shipped. Pure-client widget + backend persistence endpoint (`POST /api/quiz/attempt/{id}/tracing` → `StudentResponse`).
- **Workstream C (stability)**: ✅ Shipped earlier. Cleanup of async/BuildContext issues etc.
- **Child-friendly polish (commit `b7f4edf`)**: ✅ Shipped. Haptics on every tap, shake-on-wrong across all question types, TTS speaker button per question, `AnimatedScale` "boop" feedback on MCQ/TrueFalse, first-time onboarding overlay for pronunciation/tracing, RTL fix on MCQ row, 18pt bold MCQ options.
- **Demo hardening (this session, 2026-04-20)**: ✅ Shipped.
  - `ApiService` now throws `ApiException` with Arabic copy on any `DioException` (timeout / 5xx / network error). Providers surface this via `error_handler.extractError` — no more raw `DioException` crashes during the demo.
  - `PronunciationScoringService` extended with English Metaphone-lite path and auto language detection from the expected answer.
  - `QuizService.submitPronunciation` returns a friendly fallback when Gemini isn't configured.
  - 9 English PRONUNCIATION questions seeded in `en1_p1.json` (Hello, Book, Father, Three, Red, Head, Cat, Apple, Milk) + 9 in `en1_p2.json` (Home, Shoes, Seven, Ball, Sun, Orange, Run, Morning, Water).
  - `DataSeeder.backfillLessonQuestions` added so new PRONUNCIATION items in JSON flow into existing dev databases without requiring a wipe. `QuizRepository.findQuestionIdsByQuizId` used to avoid lazy-loading errors during seeding.
  - New `PronunciationScoringServiceTest` (14 cases covering Arabic + English) and `SubmitPronunciationFallbackTests` inside `QuizServiceTest`.
- All tests green as of last run: backend `BUILD SUCCESSFUL` (74 tests), flutter `41/41 passed`, `flutter analyze` 6 baseline issues (unchanged).

## Recent work completed (2026-04-26 / 2026-04-27) — Grade 1 quality backfill

A multi-session pass that took Grade 1 from "60/100, demo-ready" to "spec-compliant baseline, ready for grade 2-4 expansion".

- **Spec written**: `Manhaji/docs/question-authoring-spec.md` — 13 sections, per-type and per-subject lesson templates (§4.1–§4.10), difficulty calibration, sub-skill taxonomy, mastery policy, asset-bundle layout, JSON schema, R-prefixed audit rules table.
- **Audit lint shipped**: `backend/src/test/java/com/springboot/manhaji/support/QuestionAuditTest.java` (~430 lines). Two methods: `auditCurriculumSchemaIntegrity()` (strict — fails build) and `auditCurriculumQualityWarnings()` (stderr-only). Currently strict on R1, R3-R11, R14, RU. Currently warning-only on R12, R13, R15-R18 (asset-existence + per-subject-template rules); these promote to strict once images/audio are bundled.
- **Schema extension**: `Question` entity gained `subSkill`, `imageUrl`, `audioUrl` columns (all nullable). Wired through `QuestionResponse`, `QuestionBankItem`, `QuestionBankMapper`, `QuizService.toQuestionResponse`. `DataSeeder.importQuestion` reads the new fields.
- **Reseed flag**: `manhaji.curriculum.reseed: false` in `application.yaml`. Set to `true` once to wipe + re-seed all subjects/lessons/questions/attempts/responses cleanly. Required after major curriculum schema changes; safe to leave `false` after.
- **Flutter rendering**: `lib/widgets/question_media_header.dart` — fail-soft `Image.network` + `just_audio` play/stop button, used inside `QuizQuestionView`. `Question` model and `QuestionBankItem` model both gained the three new fields.
- **Massive content backfill** (623 → 1,164 questions across 113 lessons):
  - **Math**: +153 questions across 26 lessons (every lesson now has ≥10 questions, ≥1 difficulty-3, ORDERING + TRACING items where appropriate).
  - **English**: +115 questions across 18 vocabulary units. Plus **4 NEW alphabet lessons** (A-G, H-N, O-T, U-Z) inserted at orderIndex 1-4; existing units shifted to 5-13. Each alphabet lesson is 15 questions following spec §4.3.
  - **Religion**: +174 questions across 26 lessons. Surahs (Fatiha, Ikhlas, Naas, Falaq, Masad) gained per-ayah PRONUNCIATION + ORDERING memorization items. Wudu and Salah lessons gained mandatory ORDERING (step-sequencing) per spec §4.9.
  - **Arabic**: +11 difficulty-3 ORDERING / MCQ items in review and thematic lessons; ~50 review-lesson PRONUNCIATION / TRACING items rewritten with novel words/letter-combos to clear R10 duplicates.
- **Schema-integrity bugs fixed**: MCQ→TRUE_FALSE type confusion in `ar1_p1.json` (حرف الراء); 6 of 7 identical ORDERING dups in `ma1_p1.json` rewritten lesson-specific; Hello-unit "school" fill-blank replaced with greeting content; surah-name fill-blank stem reused across 5 surahs rewritten lesson-specific; cross-file Religion duplicates (5 prayers, eating-etiquette, pillars-of-Islam) deduped.
- **Test results**: backend `./gradlew test` BUILD SUCCESSFUL (75 tests); flutter `flutter test` 41/41 passed; `flutter analyze` 6 baseline issues unchanged. Audit warnings stderr block: empty.
- **Backfill scripts** (idempotent, safe to re-run): `Manhaji/scripts/curriculum/_backfill_math.py`, `_backfill_english.py`, `_backfill_religion.py`, `_backfill_arabic_reviews.py`, `_dedupe_arabic_full.py`, `_dedupe_final.py`, `_add_english_alphabet.py`. The dict structures inside are the canonical content source — edit them, re-run, and the JSON files are regenerated.

## Deferred / open items

- **Image + audio assets** — JSON schema supports `imageUrl` and `audioUrl` but no files are bundled yet. Layout per spec §8.1: `backend/src/main/resources/static/assets/questions/<subject>/<topic>/...`. Once assets ship, promote R12, R13, R15-R18 from `audit.warning()` to `audit.strict()` in `QuestionAuditTest.java` and update spec §10.
- **Grade 2-4 extraction** — Grade 1 baseline is now locked and audit-enforced. Use the spec's per-subject templates (§4.1–§4.10) as the authoring contract. Each new lesson must pass the strict audit on first add.
- **Reseed required for orderIndex change**: the alphabet-lesson insertion shifted en1_p1's existing units from orderIndex 1-9 to 5-13. On an existing dev DB this means running once with `manhaji.curriculum.reseed: true` (in `application.yaml`), then flipping back to `false`. Fresh DBs just work.
- **Demo rehearsal on physical device** — not yet done. See `HANDOFF.md` for the full runbook.
- **GEMINI_API_KEY on demo laptop** — MUST export before demo, or pronunciation falls back to "خدمة النطق غير متاحة الآن" (still doesn't crash, but no scoring).
- Many test files auto-generated (`*.mocks.dart`) — regenerate with `flutter pub run build_runner build --delete-conflicting-outputs` if changing mocked interfaces.
- No CI configured. All verification is local.

## Style guidance for Claude

- Be terse. This is a demo project — don't over-engineer. No defensive programming beyond the boundary (request validation, external AI call try/catch). No backwards-compat shims.
- Keep Arabic copy in sync with existing tone (friendly, child-facing). Match the rating strings already in `PronunciationScoringService.rating()` and `TracingWidget._score()` — don't invent new ones.
- When adding a question type: enum value → scoring service (if server-side) → DTO → Flutter model getter → widget → curriculum JSON. That's the pattern.
- When editing `QuizService` constructor: update `QuizServiceTest` mocks and constructor call together (previously missed and caused a BUILD FAILED).
- Use full paths for `flutter` and set `JAVA_HOME` before `./gradlew` — see "Running the project".
- Prefer editing over creating files. Never write READMEs or docs unless asked.

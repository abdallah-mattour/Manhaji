# Manhaji — Cross-Account Handoff

**Purpose:** If a completely fresh Claude instance (different account, new conversation, no memory) picks up this project, this doc must be enough to resume work at high performance without asking the user for context.

**Last updated:** 2026-04-29 by the monorepo restructure session.
**Owner:** Abdallah Mattour (solo dev, Birzeit CS graduation project).
**Deadline:** 2026-07-01 (graduation showcase).
**Current branch:** `main` (the only branch — repo was force-restructured 2026-04-29 to a single-branch monorepo).
**Repo layout:** monorepo at `github.com/abdallah-mattour/Manhaji.git` containing code (`Manhaji/`), textbooks (`PDFBooks/`, ~1.2 GB via Git LFS), tooling (`tools/`), and docs at the root.

> **Cloning note:** Run `git lfs install` once before your first clone, otherwise PDFBooks/* will appear as text-pointer stubs instead of real files. Then `git clone https://github.com/abdallah-mattour/Manhaji.git`.

---

## Read these first, in this order

1. **`CLAUDE.md`** (this repo root) — project-wide conventions, stack, commands, and file-layout rules. This is the canonical spec; treat it as load-bearing.
2. **This file (`HANDOFF.md`)** — session-to-session continuity: what's shipped, what's next, how to pick up.
3. **`~/.claude/plans/partitioned-hopping-graham.md`** — the plan file from the polish workstream (now fully shipped — reference only).
4. Run `git log --oneline -20` on the current branch to see the tail of recent commits.

---

## Golden-rule reminders (stolen from CLAUDE.md — repeat them because they've bitten us before)

1. **`JAVA_HOME` is NOT set globally.** Every `./gradlew` call must be prefixed with:
   ```bash
   export JAVA_HOME="/c/Users/abdal/AppData/Local/Programs/Android Studio/jbr"
   export PATH="$JAVA_HOME/bin:$PATH"
   ```
   Otherwise Gradle silently exits 0 — misleading green build.
2. **`flutter` is NOT on PATH.** Use `/c/Users/abdal/Downloads/flutter_sdk/bin/flutter` everywhere.
3. **`flutter analyze` baseline = 6 info issues.** Locations are pinned in `CLAUDE.md`. If your change brings the count above 6, fix it before declaring done.
4. **Never write READMEs or docs files unless explicitly asked** — this file is the exception because the user asked for cross-account handoff documentation.
5. **When adding a new question type**: enum → scoring (if server-side) → DTO → Flutter model getter → widget → curriculum JSON. Nothing else.
6. **When editing `QuizService` constructor**: update `QuizServiceTest` constructor call AND mocks in lockstep — previously missed and caused BUILD FAILED.
7. **No defensive programming beyond the boundary** (request validation, external AI call try/catch). This is a demo project, not production.

---

## Current state — what's shipped

### Backend (Spring Boot 4.0.5, Java 17)
- **JWT auth** with refresh tokens, role-based (STUDENT / PARENT / TEACHER / ADMIN).
- **Quiz flow**: start → submit answer (per question) → complete → results. All endpoints under `/api/quiz/attempt/{attemptId}/...`.
- **Pronunciation scoring**: `PronunciationScoringService.score(expected, transcribed, language)` — Arabic (diacritic-strip + Levenshtein) and English (Metaphone-lite + Levenshtein), auto language-detected from `expected`.
- **Tracing persistence**: `POST /api/quiz/attempt/{id}/tracing` stores a `StudentResponse` so dashboards reflect tracing activity. Scoring is still client-side (`TracingWidget`'s CustomPainter heuristic).
- **Gemini-unavailable fallback**: missing `GEMINI_API_KEY` returns a friendly zero-score response, not a 500.
- **DataSeeder backfill**: adding questions to an existing lesson's JSON now backfills them into dev MySQL automatically on next boot. Uses `(type, questionText)` as the identity key.
- **Curriculum JSON** lives at `Manhaji/backend/src/main/resources/curriculum/` — `ar1_p{1,2}.json`, `en1_p{1,2}.json`, `ma1_p{1,2}.json`, `re1_p{1,2}.json`.

### Flutter (3.10.4, Provider)
- **Screens**: splash, auth, home, learning, subject, progress, settings, teacher (dashboard + class/student), parent (dashboard + child), admin (dashboard).
- **Learning flow**: `LearningProvider` holds trackers per question. Phase transitions: `stepActive` → `stepFeedback` → `stepRetry` (optional) → next. A wrong answer gets re-queued once; the retry pass awards at most 1 star.
- **Question widgets** (`widgets/question_widgets/`): MCQ, TrueFalse, FillBlank, Ordering, ShortAnswer, Pronunciation, Tracing. All now have haptics, AppTheme colors, and (for MCQ/TF) `AnimatedScale` tap-boop.
- **API error handling**: `ApiService` throws `ApiException` with Arabic-friendly messages on timeout / 5xx / network error. Use `error_handler.extractError(e)` in providers.
- **Onboarding**: `OnboardingOverlay.showPronunciation/showTracing(context)` is shown once (persisted via `LocalStorageService.seenPronunciationTip / seenTracingTip`).
- **TTS speaker button** on every question via `QuizQuestionView(onSpeak: ...)`.

### Tests (all green as of 2026-04-20)
- **Backend**: 74 tests. Command: `./gradlew test`. Main file: `QuizServiceTest` (9 nested groups). New: `PronunciationScoringServiceTest` for Arabic + English.
- **Flutter**: 41 tests. Command: `/c/Users/abdal/Downloads/flutter_sdk/bin/flutter test`. Mostly provider-layer mocks.
- **Flutter analyze**: 6 baseline info hints — pinned list in `CLAUDE.md`.

---

## Key files you'll probably edit

| File | Why |
|---|---|
| `backend/src/main/java/com/springboot/manhaji/service/QuizService.java` | Adding a new question-submission flow, changing scoring, adding DB side-effects |
| `backend/src/main/java/com/springboot/manhaji/service/ai/PronunciationScoringService.java` | Scoring tweaks (Arabic / English / new language) |
| `backend/src/main/java/com/springboot/manhaji/entity/enums/QuestionType.java` | New question type enum value |
| `backend/src/main/java/com/springboot/manhaji/config/DataSeeder.java` | Seed behavior changes; **don't** forget the backfill path for existing dev DBs |
| `backend/src/main/resources/curriculum/*.json` | Adding questions — follow existing patterns |
| `manhaji_app/lib/providers/learning_provider.dart` | Learning flow state, retry logic, tracker plumbing |
| `manhaji_app/lib/screens/learning/learning_screen.dart` | Dispatcher for question widgets + post-answer effects |
| `manhaji_app/lib/widgets/question_widgets/*.dart` | Per-question UI |
| `manhaji_app/lib/services/api_service.dart` | HTTP client, interceptors, friendly-error translation |
| `manhaji_app/lib/app/theme.dart` | `AppTheme` color + text constants — use these, not raw `Colors.*` |

---

## How to run everything

### Prerequisites
- MySQL 8 on `localhost:3306`, db `manhaji_db`, user `root`, password `ben@me`.
- Android Studio installed (for JBR / JDK 21 bundled).
- Flutter SDK at `C:\Users\abdal\Downloads\flutter_sdk`.

### Environment variables
```bash
export GEMINI_API_KEY="..."        # for pronunciation transcription
export GOOGLE_TTS_API_KEY="..."    # for server-side TTS
```

Without these, AI endpoints degrade gracefully (no 500s after 2026-04-20 demo hardening).

### Run backend
```bash
export JAVA_HOME="/c/Users/abdal/AppData/Local/Programs/Android Studio/jbr"
export PATH="$JAVA_HOME/bin:$PATH"
cd "C:/Users/abdal/Desktop/Manhaji Claude/Manhaji/backend"
./gradlew bootRun          # starts on :8080
./gradlew test             # ~45s, 74 tests — all pass
```

### Run Flutter
```bash
cd "C:/Users/abdal/Desktop/Manhaji Claude/Manhaji/manhaji_app"
/c/Users/abdal/Downloads/flutter_sdk/bin/flutter analyze       # ~85s, 6 info baseline
/c/Users/abdal/Downloads/flutter_sdk/bin/flutter test          # ~5s, 41/41
/c/Users/abdal/Downloads/flutter_sdk/bin/flutter run -d <id>   # emulator/device
```

### Android emulator base URL
`lib/config/api_config.dart` → `http://10.0.2.2:8080/api`. For a physical device over LAN, change to host IP.

---

## Demo runbook (90-second walkthrough)

Rehearse this before the showcase. If any step breaks, *that* is what to fix first.

1. Launch backend + Flutter emulator. Pick a Grade 1 student account (seeded by DataSeeder).
2. Home → pick **اللغة العربية** → tap **حرف الراء** lesson.
3. Run through the quiz: expect MCQ → TrueFalse → Fill Blank → Pronunciation (3 questions: رمان, ريشة, رامي) → Tracing (ر, را).
   - Haptics should fire on every tap.
   - TTS speaker button should read the Arabic prompt.
   - On correct answer: confetti + "أحسنت!" TTS.
   - On wrong answer: shake animation + "حاول مرة أخرى" TTS.
   - First pronunciation question → onboarding overlay with 🎤.
   - First tracing question → onboarding overlay with ✍️.
4. Back to Home → **English** → pick **Hello! (Unit 1)**. Last question is now PRONUNCIATION "Hello" — that's the new English phonetics path.
5. Parent or Teacher login: dashboards should show real aggregate stats reflecting today's attempts, not placeholders.
6. Toggle airplane mode mid-lesson → TTS should still work (cached) and the app should not crash on API calls (ApiException shows friendly Arabic error).

**If the pronunciation step returns a generic "خدمة النطق غير متاحة الآن"**: `GEMINI_API_KEY` is not exported. Export it and restart the backend. The app intentionally no longer crashes in this case.

**If English PRONUNCIATION questions don't appear**: check backend startup logs for `"Backfilled N new questions into existing lesson '...'"`. If missing, the lesson titles in the JSON don't match what's in your DB — diff them.

---

## Where we left off (2026-04-20 end of session)

**Just committed / about to commit:** Demo hardening + English pronunciation pipeline.

**Files touched this session:**
- `backend/src/main/java/com/springboot/manhaji/service/ai/PronunciationScoringService.java` (English Metaphone-lite path, auto language detect)
- `backend/src/main/java/com/springboot/manhaji/service/QuizService.java` (Gemini-unavailable fallback, language dispatch)
- `backend/src/main/java/com/springboot/manhaji/config/DataSeeder.java` (backfill for existing lessons)
- `backend/src/main/java/com/springboot/manhaji/repository/QuizRepository.java` (findQuestionIdsByQuizId)
- `backend/src/main/resources/curriculum/en1_p1.json` (9 PRONUNCIATION questions)
- `backend/src/main/resources/curriculum/en1_p2.json` (9 PRONUNCIATION questions)
- `backend/src/test/java/com/springboot/manhaji/service/QuizServiceTest.java` (SubmitPronunciationFallbackTests nest)
- `backend/src/test/java/com/springboot/manhaji/service/ai/PronunciationScoringServiceTest.java` (new)
- `manhaji_app/lib/services/api_service.dart` (ApiException + friendly error translation)
- `manhaji_app/lib/utils/error_handler.dart` (ApiException awareness)

**Next tasks the user has NOT asked for but are logical:**
1. Physical-device demo rehearsal. Test on the actual phone the user will showcase.
2. Optional — Math and Religion PRONUNCIATION seeding (`ma1_*.json`, `re1_*.json`) if we want AI coverage in all 4 subjects. Current coverage: Arabic ✅, English ✅, Math ❌, Religion ❌.
3. Optional — record a demo video for the thesis defense.

**Do NOT do without asking:**
- Rewrite tests to use an integration DB — the project is intentionally unit-test only.
- Add CI. Deadline is 2026-07-01 and the user has been clear this is demo-focused.
- Add ML-Kit or TensorFlow Lite. We're keeping the app offline-capable and bundle-small.
- Add English equivalents of the Arabic rating strings. The UI is Arabic-first; feedback stays Arabic even for English pronunciation.

---

## Known gotchas

1. **`@SpringBootTest contextLoads()` is fragile.** It runs the full context including `DataSeeder`. If you add a `@Transactional` to `run()` or access lazy collections, it will AssertionFail with "null identifier" or LazyInitializationException. Prevention: use explicit repository queries (`findQuestionIdsByQuizId` pattern) instead of lazy-collection access inside the seeder.
2. **MySQL `ddl-auto=update`** means schema drift from entity renames won't be caught. If you change a column name, drop the old column manually.
3. **The `QuizService` constructor has 12 args.** `@RequiredArgsConstructor` picks them all up; if you add a 13th dependency, update `QuizServiceTest.setUp()`'s explicit `new QuizService(...)` call (the field list is in order).
4. **`AttemptStatus` values are `IN_PROGRESS / SUBMITTED / GRADED`** — there is **no `COMPLETED`**. A previous Claude conversation tripped on this.
5. **Arabic in Flutter source files**: the file encoding is UTF-8 and strings render RTL correctly inside widgets, but be careful when pasting Arabic into code comments — some editors flip display order.
6. **Curriculum JSON keys are case-sensitive**. `"type": "PRONUNCIATION"` matches `QuestionType.PRONUNCIATION` via `valueOf`. A lowercased `"pronunciation"` crashes seeding silently.
7. **Don't use `git add -A`** — prefer naming files explicitly. The user's `.env` and other secrets live near the repo.

---

## Communication preferences (from user history)

- Terse is fine. Skip throat-clearing like "Great question!" and "Let me explain...".
- This is a demo-focused project — the user optimizes for demo impact, not production hardening.
- Arabic copy in app UI stays Arabic even when the feature is English-adjacent. Don't invent new rating strings — match the existing ones.
- When the user asks "rate our work out of 100" or similar — give a direct numerical answer with a short dimensional breakdown. They know the project better than you; don't condescend.

---

## Emergency checklist — before any demo

- [ ] `./gradlew test` → BUILD SUCCESSFUL
- [ ] `flutter test` → 41/41 passed
- [ ] `flutter analyze` → 6 info issues (no more)
- [ ] Backend `bootRun` → no 500s in logs, DataSeeder logs say "Curriculum sync: all lessons already present" OR "Backfilled N new questions"
- [ ] `GEMINI_API_KEY` + `GOOGLE_TTS_API_KEY` exported (check with `echo $GEMINI_API_KEY`)
- [ ] MySQL running (`systemctl status mysql` or Windows service)
- [ ] Emulator / physical device connected: `flutter devices`
- [ ] API base URL in `api_config.dart` points to correct host (10.0.2.2 for emulator, LAN IP for device)
- [ ] Run the 90-second runbook above end-to-end at least once

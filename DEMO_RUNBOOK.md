# Manhaji Demo Runbook

**Target: 90-second golden-path walkthrough** that showcases the two flagship AI features (pronunciation scoring, letter tracing) plus the role dashboards and AI reports. Use this before the July 1, 2026 graduation showcase to spot-check everything works end-to-end.

---

## 0. Pre-flight checklist (run ~10 min before demo)

Run these in order. If any step fails, stop and fix before continuing.

### 0.1 Environment variables

```bash
# In the shell that will run the backend:
export GEMINI_API_KEY="<real key>"         # powers pronunciation transcription + AI reports
export GOOGLE_TTS_API_KEY="<real key>"     # powers text-to-speech for instructions
```

**Quick sanity check:** `echo $GEMINI_API_KEY` should print a real key, not `not-set`.

### 0.2 MySQL running

```bash
# Should show a mysqld process on :3306
netstat -ano | grep ":3306" | head -3
```

If MySQL isn't up: start MySQL service from Windows Services panel. Database `manhaji_db` is auto-created by JPA on first boot.

### 0.3 Backend

```bash
export JAVA_HOME="/c/Users/abdal/AppData/Local/Programs/Android Studio/jbr"
export PATH="$JAVA_HOME/bin:$PATH"
cd "C:/Users/abdal/Desktop/Manhaji Claude/Manhaji/backend"
./gradlew bootRun
```

**Wait for:** `Started ManhajiApplication in X seconds` in the log. Takes ~15s cold.

**Verify DataSeeder ran:** grep logs for `Seeded` / `curriculum` — should mention ar1_p1 with 24 lessons.

**Smoke test:** `curl http://localhost:8080/api/subjects` should return JSON (may need auth token for protected routes).

### 0.4 Flutter app

```bash
# Start Android emulator first (Android Studio → AVD Manager → Play on a Pixel-class device)
# Then:
cd "C:/Users/abdal/Desktop/Manhaji Claude/Manhaji/manhaji_app"
/c/Users/abdal/Downloads/flutter_sdk/bin/flutter run
```

`lib/config/api_config.dart` uses `10.0.2.2:8080` which is the emulator's alias for host-loopback. If running on a physical device, temporarily edit this to your LAN IP before `flutter run`.

**Wait for:** app loads to splash → auth screen.

---

## 1. Golden path (90 seconds)

### Step 1 — Student login (~10s)
- Enter demo student credentials
- **Spot check:** home screen renders with subject cards in Arabic, RTL layout, Cairo font

### Step 2 — Pick Arabic, pick حرف الراء (~5s)
- Tap اللغة العربية → first semester → حرف الراء
- **Spot check:** lesson intro shows objectives in Arabic, TTS button visible

### Step 3 — Warm-up MCQ (~10s)
- Answer "أي كلمة تبدأ بحرف الراء؟" → **رمان**
- **Spot check:** green checkmark, star awarded, confetti fires, next question auto-advances

### Step 4 — Pronunciation question (~20s)
- When PRONUNCIATION question appears with target word **رمان**
  - Tap the speaker button first to hear the target pronounced (TTS)
  - Tap the microphone, say "رمان" clearly
  - Wait for the processing spinner ("جاري تقييم النطق...") — should resolve in 2–4 seconds
- **Spot check:** score ring shows 80–100, rating ممتاز or جيد جداً, transcribed text matches, stars awarded

### Step 5 — Tracing question (~20s)
- When TRACING question appears with target letter **ر**
  - Trace the faint blue ر with finger/mouse, following the template shape
  - Tap تحقق (check)
- **Spot check:** score appears instantly (client-side heuristic), 2–3 stars, rating string renders

### Step 6 — Complete lesson (~5s)
- Tap through remaining questions (or exit mid-lesson if time is tight)
- **Spot check:** completion screen shows total stars and celebration animation

### Step 7 — Teacher view (~10s)
- Sign out, login as teacher demo account
- **Spot check:** dashboard shows real student list with points/mastery (not placeholder)
- Tap the demo student — student detail renders per-subject breakdown

### Step 8 — Parent view (~5s)
- Sign out, login as parent demo account
- **Spot check:** child card shows progress bar, points, streak

### Step 9 — AI report (~10s)
- From parent/teacher/admin view, navigate to AI Reports → Generate
- **Spot check:** spinner during generation, then report renders with risk badge (LOW/MEDIUM/HIGH) + Arabic recommendations

### Step 10 — Offline TTS spot check (~5s, optional)
- Toggle airplane mode on the device
- Re-open a lesson you've already visited, tap the TTS button on a cached phrase
- **Spot check:** audio still plays (from cache)
- Toggle airplane mode off before continuing

---

## 2. Features to spot-check throughout

| Aspect | Expected |
|---|---|
| Font | All Arabic text in **Cairo** (rounded, modern, not system default) |
| Direction | Everything flows right-to-left |
| Colors | AppTheme palette: primary green for success, orange for tracing ink, red for retry |
| Confetti | Fires on correct answers (bottom or center, 2s duration) |
| Stars | 1–3 stars shown per question, yellow when earned, gray when not |
| Transitions | No jank; pages fade/slide, not instant-swap |
| Loading states | Every async screen shows a spinner (never blank) |
| Empty states | Teacher/parent with no linked data shows a friendly message in Arabic, not a crash |

---

## 3. Lessons pre-loaded with PRONUNCIATION + TRACING

As of 2026-04-19, these three Arabic Grade 1 Semester 1 lessons have the flagship AI questions:

- **حرف الراء** — 3 pronunciation (رمان, ريشة, رامي) + 2 tracing (ر, را)
- **حرف الباء** — 3 pronunciation (باب, بطة, بيت) + 2 tracing (ب, با)
- **حرف الميم** — 3 pronunciation (موز, ماء, ملك) + 2 tracing (م, ما)

If the demo audience asks "does this only work on one letter?" — navigate to any of these three lessons to prove distribution.

---

## 4. Troubleshooting

### Pronunciation returns 500 / "لم أسمعك جيداً"
- Likely `GEMINI_API_KEY` is unset or invalid. Check backend startup log; re-export and restart.
- If key is valid but score is very low: ensure emulator mic permissions granted, say the word clearly, retry.

### Tracing score is always 0
- User probably traced too small / too few strokes. The heuristic requires ≥5 points and some bounding-box extent. Advise the presenter to trace boldly, filling the canvas.

### AI report generation hangs
- Gemini rate limit or connectivity. `ProgressReportService` has a fallback that returns synthetic recommendations — wait 10s, it'll render. Don't panic in front of the audience.

### TTS doesn't play on first try
- `just_audio` on Android sometimes needs a tap to unlock. First TTS call per app-launch is the slowest (~1.5s).

### Emulator can't reach backend
- `10.0.2.2` is the Android emulator's alias for host. If using iOS simulator or physical device, change `lib/config/api_config.dart` → `baseUrl` to LAN IP (e.g. `192.168.1.X:8080`), re-run `flutter run`.

### Backend `./gradlew` silently exits with code 0
- JAVA_HOME not set. Re-run with the export commands from step 0.3. Check the log — if it's empty, that's the symptom.

---

## 5. After the demo

- Note any pain points observed in a new issue or journal entry
- If a UX paper cut is 15 min to fix, fix it same-day before memory fades
- Don't commit new features hours before; freeze a week before graduation

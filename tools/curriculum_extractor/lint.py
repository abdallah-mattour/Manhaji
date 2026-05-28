#!/usr/bin/env python3
"""Lint a drafted lesson JSON against the spec's strict rules.

Mirrors the Java `QuestionAuditTest.schemaIntegrityRules` checks so the
author can validate a Gemini draft (or hand-edited lesson) WITHOUT spinning
up gradle. Exit 0 = clean; exit 1 = findings; exit 2 = bad input.

Coverage (per spec §10):
    R1   MCQ correctAnswer ∈ options
    R3   TRUE_FALSE options is null AND correctAnswer ∈ {صح,خطأ,True,False}
         FILL_BLANK questionText contains exactly one '___'
    R4   MCQ options size ∈ [3,5]
    R5/6 ORDERING shape sanity (comma-list, options=set of items)
    R7   difficultyLevel ∈ {1,2,3}
    R8   Lesson has ≥8 questions
    R9   Lesson has ≥1 difficulty-3 question
    R10  Duplicate questionText within file
    R11  MCQ with TF-shaped options
    R14  Lesson covers ≥3 distinct sub-skills
    RU   questionText, correctAnswer non-empty; valid subSkill (or null)

Does NOT cover:
    - R12/R13 image/audio file existence (those are filesystem checks)
    - Cross-FILE dedup (would require loading the whole curriculum dir)

Usage
-----

    # Lint a single drafted lesson:
    python tools/curriculum_extractor/lint.py path/to/draft.json

    # Lint a whole curriculum-shaped JSON file (with `lessons` array):
    python tools/curriculum_extractor/lint.py path/to/ar3_p1.json

The script accepts both forms automatically — single-lesson dicts (with
top-level `questions` key) and whole-file dicts (with top-level `lessons`).
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any

# Match the universal-rule sets from the Java audit
VALID_TYPES = {
    "MCQ", "TRUE_FALSE", "SHORT_ANSWER", "FILL_BLANK",
    "ORDERING", "PRONUNCIATION", "TRACING",
}
VALID_TF_ANSWERS = {"صح", "خطأ", "True", "False"}
VALID_SUB_SKILLS = {
    "recognition", "comprehension", "production", "application",
    "pronunciation", "recitation", "handwriting", "memorization",
    "computation",
}


class Audit:
    def __init__(self) -> None:
        self.findings: list[str] = []

    def add(self, rule: str, where: str, msg: str = "") -> None:
        suffix = f" — {msg}" if msg else ""
        self.findings.append(f"{rule}  {where}{suffix}")

    @property
    def ok(self) -> bool:
        return not self.findings


def check_question(q: dict, qtag: str, audit: Audit) -> None:
    qtype = q.get("type")
    text = (q.get("questionText") or "").strip()
    correct = (q.get("correctAnswer") or "").strip()
    options = q.get("options")
    diff = q.get("difficultyLevel")
    sub = q.get("subSkill")

    if not text:
        audit.add("RU", qtag, "questionText is missing or blank")
    elif len(text) > 500:
        audit.add("RU", qtag, f"questionText exceeds 500 chars ({len(text)})")

    if qtype != "TRACING" and not correct:
        audit.add("RU", qtag, "correctAnswer is missing or blank")

    if qtype not in VALID_TYPES:
        audit.add("RU", qtag, f"unknown type {qtype!r}")
        return

    if sub is not None and sub not in VALID_SUB_SKILLS:
        audit.add("RU", qtag, f"invalid subSkill {sub!r}")

    if not isinstance(diff, int) or diff not in (1, 2, 3):
        audit.add("R7", qtag, f"difficultyLevel must be 1/2/3 (got {diff!r})")

    # Per-type checks
    if qtype == "MCQ":
        if not isinstance(options, list):
            audit.add("R4", qtag, "MCQ missing options array")
        else:
            if len(options) < 3 or len(options) > 5:
                audit.add("R4", qtag, f"MCQ options count = {len(options)} (need 3-5)")
            if correct and correct not in options:
                audit.add("R1", qtag, f"correctAnswer {correct!r} not in options")
            opt_set = {o.strip() for o in options}
            tf_sets = ({"صح", "خطأ"}, {"True", "False"}, {"true", "false"}, {"Yes", "No"})
            for tf in tf_sets:
                if opt_set == tf:
                    audit.add("R11", qtag, "MCQ with TF-shaped options — should be TRUE_FALSE")

    elif qtype == "TRUE_FALSE":
        if options is not None:
            audit.add("R3", qtag, "TRUE_FALSE must have options=null")
        if correct not in VALID_TF_ANSWERS:
            audit.add("R3", qtag, f"TRUE_FALSE answer {correct!r} not in {VALID_TF_ANSWERS}")

    elif qtype == "FILL_BLANK":
        if options is not None:
            audit.add("R3", qtag, "FILL_BLANK must have options=null")
        if text and text.count("___") != 1:
            audit.add("R3", qtag, f"FILL_BLANK needs exactly one '___' marker (found {text.count('___')})")

    elif qtype == "ORDERING":
        if not isinstance(options, list) or len(options) < 3:
            audit.add("R5", qtag, "ORDERING needs options array (≥3 items)")
        else:
            # Accept either ASCII comma "," or Arabic comma "،" as separators.
            # Java's audit normalizes both via `split("[،,]")` — we mirror that.
            raw = (correct or "").replace("،", ",")
            tokens = [t.strip() for t in raw.split(",") if t.strip()]
            if sorted(tokens) != sorted(o.strip() for o in options):
                audit.add("R5", qtag,
                          f"ORDERING correctAnswer items {tokens} don't match options {options}")

    elif qtype in ("SHORT_ANSWER", "PRONUNCIATION", "TRACING"):
        if options is not None:
            audit.add("R3", qtag, f"{qtype} must have options=null")


def check_lesson(lesson: dict, lesson_tag: str, audit: Audit,
                 seen_text: dict[str, str]) -> None:
    questions = lesson.get("questions") or []

    if len(questions) < 8:
        audit.add("R8", lesson_tag, f"only {len(questions)} questions (need ≥8)")

    diffs = [q.get("difficultyLevel") for q in questions]
    if not any(d == 3 for d in diffs):
        audit.add("R9", lesson_tag, "no difficulty-3 question in this lesson")

    sub_skills = set()
    for q in questions:
        sub = q.get("subSkill")
        if sub:
            sub_skills.add(sub)
        else:
            # Derive default from type
            sub_skills.add({
                "MCQ": "recognition",
                "TRUE_FALSE": "comprehension",
                "SHORT_ANSWER": "production",
                "FILL_BLANK": "production",
                "ORDERING": "application",
                "PRONUNCIATION": "pronunciation",
                "TRACING": "handwriting",
            }.get(q.get("type"), "?"))
    if len(sub_skills) < 3:
        audit.add("R14", lesson_tag, f"only {len(sub_skills)} sub-skills covered (need ≥3)")

    for i, q in enumerate(questions, start=1):
        qtag = f"{lesson_tag} #{i}"
        check_question(q, qtag, audit)

        text = (q.get("questionText") or "").strip().lower()
        if text:
            if text in seen_text:
                audit.add("R10", qtag,
                          f"duplicate questionText (also at {seen_text[text]})")
            else:
                seen_text[text] = qtag


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("path", type=Path, help="Lesson JSON or curriculum-file JSON")
    args = ap.parse_args()

    if not args.path.exists():
        print(f"ERROR: {args.path} not found", file=sys.stderr)
        sys.exit(2)

    try:
        data = json.loads(args.path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"ERROR: {args.path} is not valid JSON: {e}", file=sys.stderr)
        sys.exit(2)

    audit = Audit()
    seen_text: dict[str, str] = {}

    if isinstance(data, dict) and "lessons" in data:
        for li, lesson in enumerate(data["lessons"], start=1):
            title = lesson.get("title", f"lesson-{li}")
            check_lesson(lesson, f"L{li:02d} {title}", audit, seen_text)
    elif isinstance(data, dict) and "questions" in data:
        title = data.get("title", "lesson")
        check_lesson(data, title, audit, seen_text)
    else:
        print("ERROR: input doesn't look like a lesson or curriculum file "
              "(missing 'lessons' or 'questions' key)", file=sys.stderr)
        sys.exit(2)

    if audit.ok:
        print(f"[lint] {args.path.name}: CLEAN")
        sys.exit(0)

    print(f"[lint] {args.path.name}: {len(audit.findings)} findings", file=sys.stderr)
    for f in audit.findings:
        print(f"  {f}", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()

"""
Shared helpers for curriculum-build scripts.

Used by every `_build_grade{N}_{subject}_p{semester}.py` script to avoid
duplicating the question-builder, output path logic, and subject metadata
described in `Manhaji/docs/question-authoring-spec.md`.

Typical usage in a sibling build script:

    from _common import q, write_curriculum

    LESSON_1 = {
        "title": "...",
        "orderIndex": 1,
        "content": "...",
        "objectives": "...",
        "questions": [
            q("MCQ", "...", "...", ["A", "B", "C"], 1, "recognition"),
            ...
        ],
        "imageUrls": [],
    }

    LESSONS = [LESSON_1, ...]

    def main():
        write_curriculum(subject_code="re", grade=2, semester=1, lessons=LESSONS)

    if __name__ == "__main__":
        main()

The module is intentionally a single flat file: it has no dependencies beyond
the standard library, no Spring/Java touchpoint, and is safe to import from
any sibling `_build_*` or `_backfill_*` script.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Optional

# ----------------------------------------------------------------------------
# Paths
# ----------------------------------------------------------------------------

_HERE = Path(__file__).resolve().parent

#: Project root (`Manhaji/`).
PROJECT_ROOT = _HERE.parent.parent

#: Canonical directory holding all curriculum JSON files served by the backend.
CURRICULUM_DIR = (PROJECT_ROOT / "backend" / "src" / "main"
                  / "resources" / "curriculum")


# ----------------------------------------------------------------------------
# Subject and schema metadata (kept in sync with spec §1, §6 and the audit)
# ----------------------------------------------------------------------------

#: subjectCode → subject (Arabic display name used in every JSON file).
#: These names MUST match Grade 1's exactly, since `Subject` rows are keyed
#: by (name, gradeLevel) and the audit's R10 rule is cross-grade per subject.
SUBJECT_NAMES: dict[str, str] = {
    "ar": "اللغة العربية",
    "en": "English",
    "ma": "الرياضيات",
    "re": "التربية الإسلامية",
}

#: Question types accepted by `QuestionType.valueOf(...)` in the backend's
#: `DataSeeder`. Mirrors `entity/enums/QuestionType.java`.
#: 2026-07: extended with the tier-1/2/4 interactive types (IMAGE_MCQ,
#: LISTEN_CHOOSE, IMAGE_MATCH, DRAG_DROP, READING).
QUESTION_TYPES: frozenset[str] = frozenset({
    "MCQ", "TRUE_FALSE", "SHORT_ANSWER", "FILL_BLANK",
    "ORDERING", "PRONUNCIATION", "TRACING",
    "IMAGE_MCQ", "LISTEN_CHOOSE", "IMAGE_MATCH", "DRAG_DROP", "READING",
})

#: Allowed `subSkill` values per spec §6 (+ `reading`, added with the
#: READING type in 2026-07).
VALID_SUB_SKILLS: frozenset[str] = frozenset({
    "recognition", "production", "pronunciation", "handwriting",
    "comprehension", "computation", "application",
    "memorization", "recitation", "reading",
})

#: Default sub-skill mapping (type → tag), per spec §6. Religion subject has
#: overrides — MCQ/T_F→`comprehension`, PRONUNCIATION→`recitation` — applied
#: in `_backfill_subskills.py`. Build scripts usually pass an explicit `sub`
#: rather than rely on derivation, but this table is exported for completeness.
DEFAULT_SUB_SKILL_BY_TYPE: dict[str, str] = {
    "MCQ":            "recognition",
    "TRUE_FALSE":     "comprehension",
    "SHORT_ANSWER":   "production",
    "FILL_BLANK":     "production",
    "ORDERING":       "application",
    "PRONUNCIATION":  "pronunciation",
    "TRACING":        "handwriting",
    "IMAGE_MCQ":      "recognition",
    "LISTEN_CHOOSE":  "recognition",
    "IMAGE_MATCH":    "application",
    "DRAG_DROP":      "application",
    "READING":        "reading",
}

#: Bundled Flutter asset path for an OpenMoji illustration. The audit's
#: media-existence warning verifies these against
#: `manhaji_app/assets/openmoji/` — see the library's ATTRIBUTION.txt.
def omoji(name: str) -> str:
    return f"assets/openmoji/{name}.png"


# ----------------------------------------------------------------------------
# Question builder
# ----------------------------------------------------------------------------

def q(qtype: str,
      text: str,
      answer: str,
      options: Optional[list[str]] = None,
      diff: int = 1,
      sub: Optional[str] = None,
      *,
      option_images: Optional[list[Optional[str]]] = None,
      pairs: Optional[dict[str, Any]] = None,
      image_url: Optional[str] = None) -> dict[str, Any]:
    """Compact question builder used by every build script.

    The returned dict matches the JSON schema in spec §9 (base six fields in
    the canonical order; media fields appended only when supplied). Audit
    rules R1, R3-R7, R10, R14, RU enforce shape.

    Args:
        qtype: One of `QUESTION_TYPES`.
        text: Student-visible prompt (≤ 500 chars). For READING this IS the
              read-aloud passage (and `answer` duplicates it for scoring).
        answer: Correct answer. For MCQ/IMAGE_MCQ/LISTEN_CHOOSE must appear
                in `options`. For TRUE_FALSE one of `{صح, خطأ, True, False}`.
                For ORDERING the comma-separated correct order. For
                IMAGE_MATCH / DRAG_DROP the "left=right,..." /
                "target=token,..." mapping.
        options: For MCQ-family (3-5 items) and ORDERING (3-6 items). Must be
                 None for SHORT_ANSWER / FILL_BLANK / TRUE_FALSE /
                 PRONUNCIATION / TRACING / READING.
        diff: 1, 2, or 3 (per spec §5). Each lesson needs ≥1 difficulty-3.
        sub: One of `VALID_SUB_SKILLS`. Pass None to let the audit derive
             from `qtype` via `DEFAULT_SUB_SKILL_BY_TYPE`.
        option_images: IMAGE_MCQ/LISTEN_CHOOSE — picture per option, parallel
                       to `options` (entries may be None → text fallback).
                       Use `omoji("apple")` for bundled OpenMoji paths.
        pairs: IMAGE_MATCH — `{"left": [{id,text,image?}], "right": [...]}`;
               DRAG_DROP — `{"targets": [...], "tokens": [...]}`.
        image_url: Optional illustration above the prompt (any type).
    """
    out: dict[str, Any] = {
        "type": qtype,
        "questionText": text,
        "correctAnswer": answer,
        "options": options,
        "difficultyLevel": diff,
        "subSkill": sub,
    }
    if option_images is not None:
        out["optionImages"] = option_images
    if pairs is not None:
        out["pairs"] = pairs
    if image_url is not None:
        out["imageUrl"] = image_url
    return out


# ----------------------------------------------------------------------------
# Output
# ----------------------------------------------------------------------------

def write_curriculum(*, subject_code: str, grade: int, semester: int,
                     lessons: list[dict[str, Any]]) -> Path:
    """Write a curriculum JSON file to the canonical path.

    Output path: `{CURRICULUM_DIR}/{subject_code}{grade}_p{semester}.json`.
    Encoding is UTF-8, indent=2, `ensure_ascii=False` so Arabic stays
    legible in source control. A trailing newline is appended to match
    the existing files in the repo (avoids a one-line `git diff` after
    every regenerate).

    Args:
        subject_code: One of `SUBJECT_NAMES` keys (`ar`, `en`, `ma`, `re`).
        grade: 1-4.
        semester: 1 or 2.
        lessons: Ordered list of lesson dicts. Each must have `title`,
                 `orderIndex`, `content`, `objectives`, `questions`,
                 `imageUrls`.

    Returns:
        The resolved output path.
    """
    if subject_code not in SUBJECT_NAMES:
        raise ValueError(
            f"Unknown subject_code {subject_code!r}. "
            f"Expected one of {sorted(SUBJECT_NAMES.keys())}."
        )

    # Assign a 1-based orderIndex to any lesson that doesn't declare one. The
    # backend's `lessons.order_index` column is NOT NULL (and has a unique
    # (subject, semester, order_index) key), so an omitted orderIndex fails the
    # DataSeeder import. Authoring scripts may still set orderIndex explicitly to
    # control ordering; only the missing ones are auto-numbered by position.
    for position, lesson in enumerate(lessons, start=1):
        lesson.setdefault("orderIndex", position)

    data: dict[str, Any] = {
        "subject": SUBJECT_NAMES[subject_code],
        "subjectCode": subject_code,
        "gradeLevel": grade,
        "semester": semester,
        "totalLessons": len(lessons),
        "lessons": lessons,
    }
    target = CURRICULUM_DIR / f"{subject_code}{grade}_p{semester}.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    total_q = sum(len(l.get("questions", [])) for l in lessons)
    print(f"  Wrote {target.name}: {len(lessons)} lessons, {total_q} questions")
    return target

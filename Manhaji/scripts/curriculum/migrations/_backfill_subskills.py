"""
Add `subSkill` tags to every question in every curriculum JSON that does not
already have one. Mapping is the spec §6 default-by-type table, with a
Religion override for MCQ/T-F (`comprehension` instead of `recognition`) and
PRONUNCIATION (`recitation` instead of `pronunciation`).

Idempotent. Safe to re-run; questions that already have a subSkill are left
untouched.
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
CURRICULUM = (HERE.parent.parent.parent
              / "backend" / "src" / "main" / "resources" / "curriculum")

ALL_FILES = [
    "ar1_p1.json", "ar1_p2.json",
    "en1_p1.json", "en1_p2.json",
    "ma1_p1.json", "ma1_p2.json",
    "re1_p1.json", "re1_p2.json",
]

DEFAULT_BY_TYPE = {
    "MCQ":            "recognition",
    "TRUE_FALSE":     "comprehension",
    "SHORT_ANSWER":   "production",
    "FILL_BLANK":     "production",
    "ORDERING":       "application",
    "PRONUNCIATION":  "pronunciation",
    "TRACING":        "handwriting",
}

# Religion subject overrides — recitation/comprehension framing per §6.
RELIGION_OVERRIDES = {
    "MCQ":            "comprehension",
    "TRUE_FALSE":     "comprehension",
    "PRONUNCIATION":  "recitation",
    # Math subjects don't appear in Religion files; SHORT_ANSWER/FILL stay
    # `production`, ORDERING stays `application`. Memorization is reserved
    # for explicit hand-tagging of full-surah recall items (not auto-derived).
}


def _is_religion(subject: str) -> bool:
    return subject is not None and "الإسلامية" in subject


def _process_file(path: Path) -> tuple[int, int]:
    if not path.exists():
        return (0, 0)
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    subject = data.get("subject", "")
    religion = _is_religion(subject)

    added = 0
    total = 0
    for lesson in data.get("lessons", []):
        for q in lesson.get("questions", []):
            total += 1
            if q.get("subSkill"):
                continue
            t = q.get("type")
            if religion and t in RELIGION_OVERRIDES:
                q["subSkill"] = RELIGION_OVERRIDES[t]
                added += 1
            elif t in DEFAULT_BY_TYPE:
                q["subSkill"] = DEFAULT_BY_TYPE[t]
                added += 1

    if added > 0:
        with path.open("w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")
    return (added, total)


def main():
    grand_added = 0
    grand_total = 0
    for fname in ALL_FILES:
        path = CURRICULUM / fname
        added, total = _process_file(path)
        grand_added += added
        grand_total += total
        # ASCII-only output to avoid Windows console encoding errors.
        print(f"  {fname:14s}  added={added:4d}  total={total:4d}")
    print(f"DONE: tagged {grand_added}/{grand_total} questions across "
          f"{len(ALL_FILES)} files.")


if __name__ == "__main__":
    main()

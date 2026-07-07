# -*- coding: utf-8 -*-
"""
Fairness pass for Grade 3–4 curriculum files.

Grades 1–2 get their fairness normalisation inside `_enrich_media_g12.py`
(which also injects extra media questions). Grade 3–4 are authored complete
by their `_build_grade{3,4}_*` scripts, so they only need the fairness
normalisation — reusing the exact same three fix functions to keep behaviour
identical across all grades:

  * `_fix_choice_order`      — MCQ / IMAGE_MCQ / LISTEN_CHOOSE answer never
                               at index 0; canonical-sort then seeded shuffle
                               (idempotent by construction).
  * `_fix_match_order`       — IMAGE_MATCH right-column derangement.
  * `_fix_ordering_presolved`— rotate ORDERING options when they already
                               equal the answer sequence.

Run AFTER the G3/G4 build scripts, and re-runnable safely (idempotent).
"""
from __future__ import annotations

import json

from _common import CURRICULUM_DIR
from _enrich_media_g12 import _apply_fairness

G34_FILES = [
    "ar3_p1", "ar3_p2", "en3_p1", "en3_p2",
    "ma3_p1", "ma3_p2", "re3_p1", "re3_p2",
    "ar4_p1", "ar4_p2", "en4_p1", "en4_p2",
    "ma4_p1", "ma4_p2", "re4_p1", "re4_p2",
]


def main() -> None:
    for stem in G34_FILES:
        path = CURRICULUM_DIR / f"{stem}.json"
        if not path.exists():
            continue
        with path.open(encoding="utf-8") as f:
            data = json.load(f)
        fixed = _apply_fairness(data)
        if fixed:
            with path.open("w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
                f.write("\n")
        total_q = sum(len(l.get("questions", [])) for l in data["lessons"])
        print(f"  {stem}: {fixed} order-fixes (now {total_q} questions)")


if __name__ == "__main__":
    main()

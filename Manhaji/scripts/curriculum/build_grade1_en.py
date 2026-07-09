#!/usr/bin/env python3
"""
Regenerate the two English Grade 1 files from the book-aligned builders
(2026-07-04 rebuild, mirroring *English for Palestine 1A/1B* unit by unit),
then re-apply the media enrichment/fairness pass.

Usage:
    python Manhaji/scripts/curriculum/build_grade1_en.py

Verify with:
    cd Manhaji/backend && ./gradlew test --tests "QuestionAuditTest"
"""
from __future__ import annotations

import importlib
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))


def main() -> int:
    for mod_name in ("_build_grade1_en_p1", "_build_grade1_en_p2"):
        importlib.import_module(mod_name).main()
    # Fairness/enrichment pass (idempotent) — keeps answer positions unbiased.
    importlib.import_module("_enrich_media_g12").main()
    print("Done. Run `./gradlew test --tests QuestionAuditTest` to verify.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

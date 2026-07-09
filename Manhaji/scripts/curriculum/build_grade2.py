#!/usr/bin/env python3
"""
Regenerate all 8 Grade 2 curriculum JSON files in one shot.

Imports each sibling `_build_grade2_<subject>_p<semester>.py` module and
runs its `main()` function. Each builder is deterministic and idempotent,
so re-running this script produces byte-identical output unless a builder's
lesson content changed.

Usage:
    python Manhaji/scripts/curriculum/build_grade2.py

Output:
    Manhaji/backend/src/main/resources/curriculum/
        ar2_p1.json  ar2_p2.json
        en2_p1.json  en2_p2.json
        ma2_p1.json  ma2_p2.json
        re2_p1.json  re2_p2.json

After running, verify with:
    cd Manhaji/backend && ./gradlew test --tests "QuestionAuditTest"

The audit should report BUILD SUCCESSFUL with 0 R10 collisions across both
Grade 1 and Grade 2.
"""
from __future__ import annotations

import importlib
import sys
import time
from pathlib import Path

# Make sibling `_build_grade2_*` and `_common` importable as bare names.
sys.path.insert(0, str(Path(__file__).resolve().parent))

#: Build-script module names, in the order shown in the output banner.
#: Subject grouping (ar→en→ma→re) keeps the printed report easy to scan.
BUILDERS: list[str] = [
    "_build_grade2_ar_p1",
    "_build_grade2_ar_p2",
    "_build_grade2_en_p1",
    "_build_grade2_en_p2",
    "_build_grade2_ma_p1",
    "_build_grade2_ma_p2",
    "_build_grade2_re_p1",
    "_build_grade2_re_p2",
]


def main() -> int:
    start = time.perf_counter()
    print(f"Building Grade 2 curriculum ({len(BUILDERS)} files)...")
    for mod_name in BUILDERS:
        module = importlib.import_module(mod_name)
        module.main()
    # Phase 3 (2026-07): re-apply the media-type enrichment (IMAGE_MCQ /
    # LISTEN_CHOOSE / IMAGE_MATCH / DRAG_DROP / READING + lesson images) so a
    # rebuild never loses it. Idempotent; content lives in _enrich_media_g12.
    enrich = importlib.import_module("_enrich_media_g12")
    print("Re-applying media enrichment (_enrich_media_g12)...")
    enrich.main()
    elapsed_ms = (time.perf_counter() - start) * 1000
    print(f"Done in {elapsed_ms:.0f} ms. "
          f"Run `./gradlew test --tests QuestionAuditTest` to verify.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

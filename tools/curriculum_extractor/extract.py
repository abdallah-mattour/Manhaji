#!/usr/bin/env python3
"""Extract chapters + images from a Palestinian MoE textbook PDF.

Produces a per-chapter JSON file that the downstream `draft.py` (Gemini
drafter) ingests, plus on-disk image files under
`Manhaji/backend/src/main/resources/static/assets/questions/<grade>/<chapter>/`.

Typical usage
-------------

    # List the chapters in a PDF (sanity check):
    python tools/curriculum_extractor/extract.py \\
        PDFBooks/3Grade/لغتنا\\ الجميلة/ar3-p1.pdf --list

    # Extract all chapters → JSON + images:
    python tools/curriculum_extractor/extract.py \\
        PDFBooks/3Grade/لغتنا\\ الجميلة/ar3-p1.pdf \\
        --out tools/curriculum_extractor/_out/ar3_p1

    # Extract one specific chapter only:
    python tools/curriculum_extractor/extract.py \\
        PDFBooks/3Grade/لغتنا\\ الجميلة/ar3-p1.pdf \\
        --chapter 1 \\
        --out tools/curriculum_extractor/_out/ar3_p1

Output layout
-------------

    <out_dir>/
        chapters.json           # list of all Chapter objects (TOC spine)
        ch01_<slug>.json        # ChapterContent for chapter 1
        ch01_<slug>/            # extracted images for chapter 1
            p001_x42.png
            p001_x44.png
            ...
        ch02_<slug>.json
        ...

The JSON files are self-describing — every field documented in `_pdf.py`'s
`Chapter` and `ChapterContent` dataclasses. The image directory mirrors what
will eventually live under `static/assets/questions/...` once the author has
reviewed which images to keep.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# Windows cp1252 stdout can't render Arabic; force UTF-8 so chapter titles
# and any Arabic field values print without UnicodeEncodeError.
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

from _pdf import (
    chapters_from_outline,
    extract_chapter,
    Chapter,
    ChapterContent,
)


HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent


def slugify(s: str, max_len: int = 40) -> str:
    """Filename-safe slug. Preserves Arabic — Windows + Linux both handle UTF-8
    in filenames. Replaces whitespace + punctuation with underscore."""
    s = re.sub(r"\s+", "_", s.strip())
    s = re.sub(r"[\\/:\"*?<>|]+", "", s)
    return s[:max_len]


def write_json(obj, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
        f.write("\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("pdf", type=Path, help="Path to the textbook PDF")
    ap.add_argument("--out", type=Path,
                    help="Output directory (chapters.json + ch*.json + image dirs go here)")
    ap.add_argument("--chapter", type=int, default=None,
                    help="Extract only the chapter with this 1-based orderIndex "
                         "(omit to extract all chapters)")
    ap.add_argument("--list", action="store_true",
                    help="Just list the chapter spine and exit — no extraction")
    ap.add_argument("--no-images", action="store_true",
                    help="Skip image extraction (faster, useful when you only "
                         "need text for AI drafting and assets are deferred)")
    ap.add_argument("--image-prefix", default=None,
                    help="rel_path prefix injected into each ImageInfo. "
                         "Defaults to deriving from the PDF filename "
                         "(e.g. ar3_p1 → static/assets/questions/grade3/ar3_p1)")
    args = ap.parse_args()

    if not args.pdf.exists():
        print(f"ERROR: {args.pdf} not found", file=sys.stderr)
        sys.exit(1)

    chapters = chapters_from_outline(args.pdf)
    if not chapters:
        print(f"ERROR: no chapters detected in {args.pdf}", file=sys.stderr)
        sys.exit(2)

    print(f"Found {len(chapters)} chapters in {args.pdf.name}:")
    for ch in chapters:
        print(f"  [{ch.order_index:2d}] pages {ch.start_page+1}-{ch.end_page}: {ch.title}")

    if args.list:
        return

    if not args.out:
        print("ERROR: --out is required when extracting (use --list to just preview)",
              file=sys.stderr)
        sys.exit(3)

    # Derive image prefix from PDF filename if not given
    stem = args.pdf.stem.replace("-", "_")  # ar3-p1 → ar3_p1
    grade_match = re.search(r"\d", stem)
    grade = grade_match.group(0) if grade_match else "?"
    image_prefix_root = args.image_prefix or f"static/assets/questions/grade{grade}/{stem}"

    # Filter to single chapter if requested
    targets = chapters
    if args.chapter is not None:
        targets = [c for c in chapters if c.order_index == args.chapter]
        if not targets:
            print(f"ERROR: chapter {args.chapter} not found", file=sys.stderr)
            sys.exit(4)

    args.out.mkdir(parents=True, exist_ok=True)
    # 1. Write chapter spine
    write_json([c.to_dict() for c in chapters], args.out / "chapters.json")

    # 2. Per-chapter extraction
    for ch in targets:
        slug = slugify(ch.title)
        json_path = args.out / f"ch{ch.order_index:02d}_{slug}.json"
        img_dir = args.out / f"ch{ch.order_index:02d}_{slug}" if not args.no_images else None
        img_prefix = f"{image_prefix_root}/ch{ch.order_index:02d}" if not args.no_images else ""

        content = extract_chapter(
            args.pdf,
            ch,
            image_out_dir=img_dir,
            image_rel_prefix=img_prefix,
        )
        write_json(content.to_dict(), json_path)
        n_imgs = len(content.images)
        print(f"  wrote {json_path.name}  ({len(content.full_text)} chars, "
              f"{n_imgs} images, passage={len(content.reading_passage)} chars)")


if __name__ == "__main__":
    main()

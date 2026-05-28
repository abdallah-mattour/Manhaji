#!/usr/bin/env python3
"""Draft a lesson JSON from an extracted chapter via Gemini.

Pipeline position: this runs AFTER `extract.py` has produced a per-chapter
JSON, and BEFORE `lint.py` validates the output. The author then reviews
the draft, edits anything they want to change, and copies into
`backend/src/main/resources/curriculum/<file>.json`.

Usage
-----

    # Draft a lesson using the Arabic-narrative template:
    python tools/curriculum_extractor/draft.py \\
        tools/curriculum_extractor/_out/ar3_p1/ch02_arnab.json \\
        --template ar_narrative \\
        --out tools/curriculum_extractor/_out/ar3_p1/ch02_draft.json

    # Dry-run — emit the assembled prompt to stdout without calling Gemini:
    python tools/curriculum_extractor/draft.py \\
        tools/curriculum_extractor/_out/ar3_p1/ch02_arnab.json \\
        --template ar_narrative --dry-run

    # List available templates:
    python tools/curriculum_extractor/draft.py --list-templates

Environment
-----------

`GEMINI_API_KEY` must be set. Same key the backend uses (see
`Manhaji/backend/src/main/resources/application.yaml` >
`app.ai.gemini.api-key`).
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

# Force UTF-8 stdout on Windows so Arabic JSON output prints cleanly
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

from _gemini import draft_lesson_json, GeminiError


HERE = Path(__file__).resolve().parent
PROMPTS_DIR = HERE / "prompts"


def list_templates() -> list[str]:
    return sorted(p.stem for p in PROMPTS_DIR.glob("*.md"))


def load_template(name: str) -> str:
    path = PROMPTS_DIR / f"{name}.md"
    if not path.exists():
        raise SystemExit(
            f"ERROR: template '{name}' not found. Available templates: "
            f"{', '.join(list_templates())}"
        )
    return path.read_text(encoding="utf-8")


def build_prompts(template: str, chapter_json: dict) -> tuple[str, str]:
    """Split the template into (system_prompt, user_prompt).

    Convention: the template has a `## Your task` heading that separates
    the system-instructions block (everything above) from the user-message
    block (everything below). The `{CHAPTER_JSON}` placeholder in the
    user block is replaced with the chapter content.
    """
    # JSON-encode the chapter for inclusion in the user prompt
    chapter_text = json.dumps(chapter_json, ensure_ascii=False, indent=2)

    # Split on "## Your task" heading
    marker = "## Your task"
    if marker in template:
        sys_part, user_part = template.split(marker, 1)
        user_part = marker + user_part
    else:
        # Fallback: send everything as system, then the chapter as user
        sys_part = template
        user_part = chapter_text

    user_part = user_part.replace("{CHAPTER_JSON}", chapter_text)
    return sys_part.strip(), user_part.strip()


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("chapter_json", type=Path, nargs="?",
                    help="Path to an extracted chapter JSON (from extract.py)")
    ap.add_argument("--template", required=False,
                    help="Prompt template name (without .md). Use --list-templates "
                         "to see available templates.")
    ap.add_argument("--out", type=Path,
                    help="Output JSON path. If omitted, draft is printed to stdout.")
    ap.add_argument("--dry-run", action="store_true",
                    help="Print the assembled prompt to stdout without calling Gemini. "
                         "Useful for tuning the template or estimating token cost.")
    ap.add_argument("--list-templates", action="store_true",
                    help="List available prompt templates and exit.")
    ap.add_argument("--model", default=None,
                    help="Override the default Gemini model (default: gemini-2.5-flash)")
    ap.add_argument("--temperature", type=float, default=0.4,
                    help="Sampling temperature (default 0.4 — balances structure consistency "
                         "with phrasing variety)")
    args = ap.parse_args()

    if args.list_templates:
        for t in list_templates():
            print(t)
        return

    if not args.chapter_json or not args.template:
        ap.error("chapter_json and --template are required (or use --list-templates)")

    if not args.chapter_json.exists():
        print(f"ERROR: {args.chapter_json} not found", file=sys.stderr)
        sys.exit(1)

    template = load_template(args.template)
    with args.chapter_json.open(encoding="utf-8") as f:
        chapter_data = json.load(f)

    system_prompt, user_prompt = build_prompts(template, chapter_data)

    if args.dry_run:
        print("===== SYSTEM PROMPT =====")
        print(system_prompt)
        print()
        print("===== USER PROMPT =====")
        print(user_prompt)
        return

    print(f"Drafting lesson via Gemini (template={args.template}, "
          f"chapter={args.chapter_json.name})...", file=sys.stderr)

    try:
        draft = draft_lesson_json(
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            model=args.model or "gemini-2.5-flash",
            temperature=args.temperature,
        )
    except GeminiError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(2)

    if "error" in draft and "questions" not in draft:
        print(f"Gemini rejected this chapter for the '{args.template}' template:",
              file=sys.stderr)
        print(f"  {draft['error']}", file=sys.stderr)
        sys.exit(3)

    output = json.dumps(draft, ensure_ascii=False, indent=2)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(output + "\n", encoding="utf-8")
        n_q = len(draft.get("questions", []))
        print(f"Wrote {args.out}  ({n_q} questions)", file=sys.stderr)
    else:
        print(output)


if __name__ == "__main__":
    main()

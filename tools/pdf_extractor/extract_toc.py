#!/usr/bin/env python3
"""
Lightweight Table-of-Contents extractor for Grade 2 PDFs.

Dumps the first N pages of every Grade 2 PDF into a single Markdown
reference doc the author can read and translate into a clean ToC
before hand-authoring questions per the spec.

We deliberately do NOT try to be clever: this just renders every page
with PyMuPDF's "text" mode (reading-order) and falls back to a
bidi-reshape pass if the first attempt looks reversed. Manual review
afterwards is the source of truth.

Usage:
    python tools/pdf_extractor/extract_toc.py
    python tools/pdf_extractor/extract_toc.py --pages 30
    python tools/pdf_extractor/extract_toc.py --grade 3

Output:
    Manhaji/docs/grade{N}-toc-raw.md
"""
import argparse
import sys
from pathlib import Path

import fitz  # PyMuPDF
import arabic_reshaper
from bidi.algorithm import get_display


HERE = Path(__file__).resolve().parent
PROJECT_ROOT = HERE.parent.parent
PDFBOOKS = PROJECT_ROOT / "PDFBooks"
DOCS = PROJECT_ROOT / "Manhaji" / "docs"

# Folder name in Arabic → (subjectCode, English label) so we can output stable headers.
SUBJECT_FOLDERS = {
    "لغتنا الجميلة":      ("ar", "Arabic (لغتنا الجميلة)"),
    "الرياضيات":          ("ma", "Math (الرياضيات)"),
    "English":            ("en", "English"),
    "التربية الاسلامية":  ("re", "Islamic Education (التربية الإسلامية)"),
}


def looks_reversed(text: str) -> bool:
    """Heuristic: a few common Arabic markers in their reversed form."""
    reversed_markers = ["سردلا", "ةدحولا", "فرح", "باتك", "ةحفصلا"]
    normal_markers = ["الدرس", "الوحدة", "حرف", "كتاب", "الصفحة"]
    return (any(m in text for m in reversed_markers)
            and not any(m in text for m in normal_markers))


def reshape_arabic(text: str) -> str:
    """Apply arabic_reshaper + bidi to flip reversed text."""
    try:
        reshaped = arabic_reshaper.reshape(text)
        return get_display(reshaped)
    except Exception:
        return text


def extract_pdf_pages(pdf_path: Path, num_pages: int) -> list[str]:
    """Return the first `num_pages` pages of text from the PDF.

    Each entry is plain reading-order text. For pages that look reversed,
    we also append the bidi-shaped variant so the reader can pick whichever
    is more legible.
    """
    pages_out: list[str] = []
    doc = fitz.open(pdf_path)
    try:
        last = min(num_pages, doc.page_count)
        for i in range(last):
            page = doc.load_page(i)
            text = page.get_text("text", sort=True) or ""
            text = text.strip()
            if looks_reversed(text):
                pages_out.append(text + "\n\n— bidi-reshaped attempt —\n" + reshape_arabic(text))
            else:
                pages_out.append(text)
    finally:
        doc.close()
    return pages_out


def discover_pdfs(grade: int) -> list[tuple[str, str, Path]]:
    """Yield (subject_code, subject_label, pdf_path) for every PDF in
    PDFBooks/<grade>Grade/<subject>/*.pdf — sorted by subject then filename."""
    grade_dir = PDFBOOKS / f"{grade}Grade"
    found: list[tuple[str, str, Path]] = []
    if not grade_dir.exists():
        return found
    for folder_name, (code, label) in SUBJECT_FOLDERS.items():
        subj_dir = grade_dir / folder_name
        if not subj_dir.is_dir():
            continue
        for pdf in sorted(subj_dir.glob("*.pdf")):
            found.append((code, label, pdf))
    return found


def main():
    ap = argparse.ArgumentParser(description="Dump first N pages of Grade-N PDFs as Markdown")
    ap.add_argument("--grade", type=int, default=2, help="Grade level (default: 2)")
    ap.add_argument("--pages", type=int, default=20, help="Pages to extract per PDF (default: 20)")
    ap.add_argument("--out", type=Path, default=None,
                    help="Output markdown path (default: Manhaji/docs/grade{N}-toc-raw.md)")
    args = ap.parse_args()

    pdfs = discover_pdfs(args.grade)
    if not pdfs:
        print(f"No PDFs found under PDFBooks/{args.grade}Grade/", file=sys.stderr)
        sys.exit(1)

    out_path = args.out or (DOCS / f"grade{args.grade}-toc-raw.md")
    out_path.parent.mkdir(parents=True, exist_ok=True)

    lines: list[str] = []
    lines.append(f"# Grade {args.grade} — Raw ToC dump")
    lines.append("")
    lines.append(f"First {args.pages} pages of each PDF, extracted via PyMuPDF.")
    lines.append("Arabic blocks that looked reversed include a `— bidi-reshaped attempt —` companion.")
    lines.append("**Manual review required**: PDF text extraction is imperfect for Arabic textbooks.")
    lines.append("")

    for code, label, pdf in pdfs:
        rel = pdf.relative_to(PROJECT_ROOT).as_posix()
        lines.append("---")
        lines.append("")
        lines.append(f"## {label} — `{pdf.name}` (`{code}`)")
        lines.append("")
        lines.append(f"Path: `{rel}`")
        lines.append("")
        pages = extract_pdf_pages(pdf, args.pages)
        for i, text in enumerate(pages, start=1):
            lines.append(f"### Page {i}")
            lines.append("")
            lines.append("```")
            lines.append(text if text else "(empty)")
            lines.append("```")
            lines.append("")

    out_path.write_text("\n".join(lines), encoding="utf-8")
    size_kb = out_path.stat().st_size / 1024
    print(f"Wrote {out_path}  ({size_kb:.0f} KB, {len(pdfs)} PDFs, {args.pages} pages each)")


if __name__ == "__main__":
    main()

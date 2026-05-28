"""PDF parsing helpers — chapter detection, text extraction, image extraction.

Designed for the Palestinian MoE textbook PDFs in `PDFBooks/<N>Grade/`.
Those PDFs are well-formed (PyMuPDF reads them cleanly) but use a mix of
Arabic visual order and logical order depending on the chapter — we
detect the case and re-shape only when needed.

The two public helpers most callers want:

    chapters_from_outline(pdf)  → list[Chapter]
        Use the PDF's bookmark outline as the chapter spine. Falls back
        to a heading-text heuristic if the PDF has no bookmarks.

    extract_chapter(pdf, chapter) → ChapterContent
        Full text + image inventory + suggested reading passage for one
        chapter. Output is JSON-serializable so the downstream AI drafter
        can ingest it.

Everything else (image classification, passage segmentation) is a
private detail of these two.
"""
from __future__ import annotations

import io
import re
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Any

import fitz  # PyMuPDF
from PIL import Image

# Re-shaping is only used when text comes out visually reversed
import arabic_reshaper
from bidi.algorithm import get_display


# Minimum image dimensions to keep (drop tiny page-decoration glyphs).
# 100x100 catches small icons, 80px floor for either dim catches narrow strips.
MIN_IMG_W = 80
MIN_IMG_H = 80
MIN_IMG_AREA = 100 * 100

# Maximum image dimensions before we resize for asset bundling. Keeps the
# `static/assets/questions/` directory manageable (the spec §8.3 budget is
# ~10MB per grade).
MAX_IMG_DIM = 800


@dataclass
class Chapter:
    """One chapter in a textbook — derived from outline bookmark or heading scan."""

    title: str
    """Chapter heading as it appears in the PDF outline or first page."""

    order_index: int
    """1-based position in the book."""

    start_page: int
    """0-based page index where the chapter starts."""

    end_page: int
    """0-based page index where the chapter ends (exclusive — i.e. start of next)."""

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class ImageInfo:
    """One extracted image with metadata for the AI drafter to reason about."""

    page: int
    """0-based PDF page index where this image lives."""

    rel_path: str
    """Path relative to project root (e.g. `static/assets/questions/grade3/lesson1/img_3.png`)."""

    width: int
    height: int

    classification: str = "unknown"
    """One of: 'pedagogical', 'decorative', 'unknown'. Heuristic; author should review."""

    surrounding_text: str = ""
    """Up to 200 chars of nearby text, useful for the AI to caption the image."""

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class ChapterContent:
    """Everything we extracted from one chapter for the AI drafter."""

    title: str
    order_index: int
    page_range: tuple[int, int]
    """0-based (start, end_exclusive)."""

    objectives: str = ""
    """Learning objectives extracted from the opening page (Palestinian textbooks
       label this 'النتاجات' at the top of each chapter)."""

    full_text: str = ""
    """All text from the chapter, in reading order."""

    reading_passage: str = ""
    """The longest contiguous paragraph in the chapter — usually the textbook's
       main reading material for Arabic / Religion. For Math this may be empty."""

    images: list[ImageInfo] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        d = asdict(self)
        d["page_range"] = list(self.page_range)
        return d


# ---------------------------------------------------------------------------
# Chapter spine detection
# ---------------------------------------------------------------------------


def chapters_from_outline(pdf_path: Path) -> list[Chapter]:
    """Return chapters via PDF bookmarks; fall back to heading heuristic.

    Palestinian MoE textbooks ship with PDF bookmarks for each chapter
    ('الدرس الأول', 'الدرس الثاني', etc.). That's our preferred source —
    they're authored by the publisher and align with the textbook's own
    structure. If bookmarks are missing (rare; some older scans), we
    scan for chapter-heading text patterns instead.
    """
    doc = fitz.open(pdf_path)
    try:
        toc = doc.get_toc()  # list of [level, title, page] (1-based page)
        if toc:
            return _chapters_from_toc(toc, doc.page_count)
        return _chapters_from_headings(doc)
    finally:
        doc.close()


def _chapters_from_toc(toc: list[list], page_count: int) -> list[Chapter]:
    """Build Chapter list from PDF's TOC bookmarks. Use only top-level
    entries (level==1) as chapter spine — sub-bookmarks become noise."""
    top_level = [(title, page - 1) for level, title, page in toc if level == 1]
    chapters: list[Chapter] = []
    for i, (title, start) in enumerate(top_level):
        end = top_level[i + 1][1] if i + 1 < len(top_level) else page_count
        chapters.append(Chapter(
            title=_clean_title(title),
            order_index=i + 1,
            start_page=start,
            end_page=end,
        ))
    return chapters


# Arabic diacritics + tatweel + the orphan "Խ" PDF artifact that bleeds into
# some Palestinian textbooks (probably a font-substitution leftover).
_AR_DIACRITICS_RE = re.compile(r"[ً-ْٰـ]|[԰-֏]|[-]|�")  # diacritics + tatweel + Armenian artifacts + PUA + replacement char

# Hamza variants → bare alef; final-yaa → ya; taa-marbuta → ha.
# Collapses spelling variants that PDF extraction produces.
_AR_NORM_MAP = str.maketrans({
    "أ": "ا", "إ": "ا", "آ": "ا",
    "ى": "ي", "ة": "ه",
})

# Arabic ordinal words used in Palestinian textbook lesson headings.
# Listed WITHOUT the "ال" definite-article prefix because PDF extraction
# sometimes splits "ال" off from the noun (right-to-left visual ordering
# bleeds through). The matcher accepts both with and without "ال".
# All entries below are already normalized (no diacritics, hamza, or ta-marbuta).
_AR_ORDINALS_BARE = (
    "اول",  # awl
    "ثاني",  # thani
    "ثالث",  # thalith
    "رابع",  # rabi'
    "خامس",  # khamis
    "سادس",  # sadis
    "سابع",  # sabi'
    "ثامن",  # thamin
    "تاسع",  # tasi'
    "عاشر",  # 'ashir
    # Feminine forms
    "اولي", "ثانيه",
    "ثالثه", "رابعه",
    "خامسه", "سادسه",
    "سابعه", "ثامنه",
    "تاسعه", "عاشره",
    # 11-20 compound
    "حادي عشر",
    "ثاني عشر",
    "ثالث عشر",
    "رابع عشر",
    "خامس عشر",
    "سادس عشر",
    "سابع عشر",
    "ثامن عشر",
    "تاسع عشر",
    "عشرون",
)

_ORD = r"(?:ال)?(?:" + "|".join(re.escape(o) for o in _AR_ORDINALS_BARE) + r")"

# Arabic patterns allow EITHER ordering (drs + ord, or ord + drs) because
# PyMuPDF visual-order extraction reverses RTL text unpredictably.
# "الدرس" = "الدرس", "الوحده" = "الوحده"
_CHAPTER_PATTERNS = [
    re.compile(r"الدرس\s+" + _ORD),
    re.compile(_ORD + r"\s+الدرس"),
    re.compile(r"الوحده\s+" + _ORD),
    re.compile(_ORD + r"\s+الوحده"),
    # Macmillan English-for-Palestine convention: chapter COVER pages
    # have the literal "UNIT" in ALL-CAPS at the top, followed (within
    # the heading window) by the unit number. Mid-unit "Period" pages
    # use mixed-case "Unit 1 Period 3" — those must NOT be treated as
    # new chapters, so this pattern is case-SENSITIVE (no IGNORECASE).
    re.compile(r"\bUNIT\b[\s\S]{0,300}?\b(\d{1,2})\b"),
    # Other English textbooks using "Lesson X" / "Chapter X" — those
    # don't have the cover-vs-period split so case-insensitive is safe.
    re.compile(r"\b(?:Lesson|Chapter)\s+\d+\b", re.IGNORECASE),
]

_HEADING_WINDOW = 600


def _normalize_ar(s: str) -> str:
    """Strip Arabic diacritics + tatweel + orphan ligature artifacts, AND
    collapse hamza/yaa/taa-marbuta variants to bare forms. Idempotent.
    Non-Arabic content passes through unchanged.

    After this, chapter headings like awwal-with-diacritics become bare
    "اول" which is what _CHAPTER_PATTERNS expects."""
    s = _AR_DIACRITICS_RE.sub("", s or "")
    return s.translate(_AR_NORM_MAP)


def _find_chapter_marker(text: str) -> str | None:
    """Return the chapter-heading substring found in the first
    _HEADING_WINDOW chars, normalized; or None if no heading."""
    window = _normalize_ar(text)[:_HEADING_WINDOW]
    for pat in _CHAPTER_PATTERNS:
        m = pat.search(window)
        if m:
            return m.group(0)
    return None


def _chapters_from_headings(doc: fitz.Document) -> list[Chapter]:
    """Fallback when the PDF has no TOC bookmarks: scan every page for
    chapter-heading patterns. A page starts a new chapter iff its leading
    text contains a chapter marker AND that marker is different from the
    one on the most-recent chapter-start page (de-duplicates the same
    chapter heading repeating across all its pages).

    Title comes from a separate pass that looks for the largest-font text
    near the marker — that's the textbook's actual chapter name (e.g.
    "ذهب الأرض"), not just "الدرس الأول"."""
    starts: list[tuple[int, str, str]] = []  # (page_index, marker, full_title)
    for i in range(doc.page_count):
        page = doc.load_page(i)
        text = page.get_text("text", sort=True) or ""
        marker = _find_chapter_marker(text)
        if not marker:
            continue
        # Skip the Table-of-Contents page — its listing of chapter titles
        # would otherwise trip the chapter-marker pattern (it contains
        # "الدرس الأول ..." etc. by definition).
        norm_head = _normalize_ar(text)[:200]
        if "المحتويات" in norm_head or "الفهرس" in norm_head or "Contents" in text[:200]:
            continue
        # Only count as a new chapter if marker differs from previous
        if starts and starts[-1][1] == marker:
            continue
        # Pull a more descriptive title: largest-font run near the marker.
        title = _largest_font_title(page) or _normalize_ar(text)[:80].strip()
        starts.append((i, marker, title))

    chapters: list[Chapter] = []
    for j, (start, marker, title) in enumerate(starts):
        end = starts[j + 1][0] if j + 1 < len(starts) else doc.page_count
        chapters.append(Chapter(
            title=_clean_title(title),
            order_index=j + 1,
            start_page=start,
            end_page=end,
        ))
    return chapters


def _largest_font_title(page: fitz.Page) -> str:
    """Return the text of the largest-font span on this page that's NOT
    pure digits (page numbers). Palestinian textbooks set chapter titles
    in a distinctly larger font than body text, so this is a reliable
    way to find 'ذهب الأرض' over the generic 'الدرس الأول' marker."""
    try:
        blocks = page.get_text("dict").get("blocks", [])
    except Exception:
        return ""
    best_size = 0.0
    best_text = ""
    for block in blocks:
        for line in block.get("lines", []):
            for span in line.get("spans", []):
                text = (span.get("text") or "").strip()
                size = span.get("size", 0)
                if not text or text.isdigit() or len(text) < 3:
                    continue
                if size > best_size:
                    best_size = size
                    best_text = text
    return _normalize_ar(best_text).strip()


def _clean_title(s: str) -> str:
    """Strip extra whitespace + leading numbering noise from a chapter title."""
    s = s.strip()
    # Drop trailing page numbers like "حرف الراء ..... 21"
    s = re.sub(r"\s*\.{2,}\s*\d+\s*$", "", s)
    # Collapse multi-space
    s = re.sub(r"\s+", " ", s)
    return s


# ---------------------------------------------------------------------------
# Per-chapter content extraction
# ---------------------------------------------------------------------------


def extract_chapter(pdf_path: Path, chapter: Chapter,
                    image_out_dir: Path | None = None,
                    image_rel_prefix: str = "") -> ChapterContent:
    """Extract text + images for one chapter.

    Args:
        pdf_path: PDF file.
        chapter: Chapter spine (from `chapters_from_outline`).
        image_out_dir: Filesystem directory to write extracted images to.
                       If None, images are scanned but not saved.
        image_rel_prefix: Prefix path inserted into each image's `rel_path`
                          field — e.g. `static/assets/questions/grade3/lesson1`.

    Returns:
        ChapterContent — JSON-serializable via `.to_dict()`.
    """
    doc = fitz.open(pdf_path)
    try:
        # 1. Text — page by page, joined with double-newline
        pages_text: list[str] = []
        for p in range(chapter.start_page, chapter.end_page):
            text = doc.load_page(p).get_text("text", sort=True) or ""
            text = text.strip()
            if not text:
                continue
            if _looks_reversed(text):
                text = _reshape(text)
            pages_text.append(text)
        full_text = "\n\n".join(pages_text)

        # 2. Objectives — first paragraph after the 'النتاجات' marker if present
        objectives = _extract_objectives(full_text)

        # 3. Reading passage — longest contiguous paragraph (>120 chars).
        #    For Arabic narrative chapters this is the textbook's story.
        reading_passage = _longest_paragraph(full_text)

        # 4. Images — extracted page-by-page, deduped by xref
        images: list[ImageInfo] = []
        seen_xrefs: set[int] = set()
        if image_out_dir is not None:
            image_out_dir.mkdir(parents=True, exist_ok=True)

        for p in range(chapter.start_page, chapter.end_page):
            page = doc.load_page(p)
            page_text = page.get_text("text") or ""

            for img_index, img in enumerate(page.get_images(full=True)):
                xref = img[0]
                if xref in seen_xrefs:
                    continue
                seen_xrefs.add(xref)

                try:
                    base = doc.extract_image(xref)
                except Exception:
                    continue

                img_bytes = base["image"]
                ext = base.get("ext", "png")
                width = base.get("width", 0)
                height = base.get("height", 0)

                if width < MIN_IMG_W or height < MIN_IMG_H:
                    continue
                if width * height < MIN_IMG_AREA:
                    continue

                # Resize if huge — keeps asset bundle under budget
                img_bytes, width, height = _maybe_resize(img_bytes, ext, width, height)

                # Classify by aspect ratio + size + page-text context
                classification = _classify(width, height, page_text)

                # Filename and on-disk path
                fname = f"p{p+1:03d}_x{xref}.{_safe_ext(ext)}"
                rel = f"{image_rel_prefix}/{fname}" if image_rel_prefix else fname

                if image_out_dir is not None:
                    out_file = image_out_dir / fname
                    out_file.write_bytes(img_bytes)

                images.append(ImageInfo(
                    page=p,
                    rel_path=rel,
                    width=width,
                    height=height,
                    classification=classification,
                    surrounding_text=_nearby_text(page_text, 200),
                ))

        return ChapterContent(
            title=chapter.title,
            order_index=chapter.order_index,
            page_range=(chapter.start_page, chapter.end_page),
            objectives=objectives,
            full_text=full_text,
            reading_passage=reading_passage,
            images=images,
        )
    finally:
        doc.close()


# ---------------------------------------------------------------------------
# Text helpers
# ---------------------------------------------------------------------------


# Reversed-text markers; if we see these but NOT their forward forms, the PDF
# is visually-ordered and we need to re-shape.
_REVERSED_MARKERS = ["سردلا", "ةدحولا", "فرح", "باتك", "ةحفصلا"]
_NORMAL_MARKERS = ["الدرس", "الوحدة", "حرف", "كتاب", "الصفحة"]


def _looks_reversed(text: str) -> bool:
    return (any(m in text for m in _REVERSED_MARKERS)
            and not any(m in text for m in _NORMAL_MARKERS))


def _reshape(text: str) -> str:
    try:
        return get_display(arabic_reshaper.reshape(text))
    except Exception:
        return text


def _extract_objectives(text: str) -> str:
    """Find 'النتاجات' marker and return the paragraph after it (up to 600 chars)."""
    for marker in ("النتاجات", "النِّتاجات", "Objectives", "Learning Objectives"):
        idx = text.find(marker)
        if idx >= 0:
            after = text[idx + len(marker):].lstrip(":\n .—")
            # Stop at the next blank line OR 600 chars
            stop = after.find("\n\n")
            if stop < 0 or stop > 600:
                stop = 600
            return after[:stop].strip()
    return ""


def _longest_paragraph(text: str) -> str:
    """Return the longest paragraph (split on blank lines). Useful for Arabic
    narrative chapters where the AI drafter wants the textbook's actual story
    as `lesson.content`."""
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    if not paragraphs:
        return ""
    longest = max(paragraphs, key=len)
    # Don't return short paragraphs as "the" reading passage — they're noise
    if len(longest) < 120:
        return ""
    # Cap at 1200 chars (~250 words) — anything more is multi-chapter spillover
    return longest[:1200]


def _nearby_text(page_text: str, n: int) -> str:
    """Just the first N chars of the page — good enough for image captioning."""
    return (page_text or "")[:n].replace("\n", " ").strip()


# ---------------------------------------------------------------------------
# Image helpers
# ---------------------------------------------------------------------------


def _safe_ext(ext: str) -> str:
    """PyMuPDF returns 'jpx', 'jpeg', etc. Normalize for browser-friendliness."""
    if ext in ("jpeg", "jpg"):
        return "jpg"
    if ext == "png":
        return "png"
    return "png"


def _maybe_resize(img_bytes: bytes, ext: str, w: int, h: int) -> tuple[bytes, int, int]:
    """If either dim > MAX_IMG_DIM, downscale proportionally. Keeps the
    `static/assets/questions/` bundle within the spec §8.3 budget."""
    if w <= MAX_IMG_DIM and h <= MAX_IMG_DIM:
        return img_bytes, w, h
    try:
        im = Image.open(io.BytesIO(img_bytes))
    except Exception:
        return img_bytes, w, h
    im.thumbnail((MAX_IMG_DIM, MAX_IMG_DIM), Image.LANCZOS)
    buf = io.BytesIO()
    fmt = "JPEG" if ext in ("jpeg", "jpg") else "PNG"
    save_kwargs: dict[str, Any] = {}
    if fmt == "JPEG":
        save_kwargs["quality"] = 88
        save_kwargs["optimize"] = True
        if im.mode in ("RGBA", "P"):
            im = im.convert("RGB")
    im.save(buf, format=fmt, **save_kwargs)
    return buf.getvalue(), im.size[0], im.size[1]


def _classify(w: int, h: int, page_text: str) -> str:
    """Cheap heuristic: pedagogical vs decorative.

    'pedagogical' if image is large (>=300x300) AND nearby text contains
    math/diagram/geography keywords. 'decorative' if small + no such cue.
    Always fallback to 'unknown' — the author should make the final call.
    """
    if w < 200 and h < 200:
        return "decorative"

    cue_words = [
        # Arabic
        "شكل", "رسم", "خريطة", "صورة", "مخطط", "جدول", "آية", "ركوع", "سجود",
        # English
        "figure", "diagram", "chart", "map", "picture", "graph",
    ]
    lower = (page_text or "").lower()
    if any(w in lower for w in cue_words):
        return "pedagogical"
    if w >= 400 and h >= 400:
        # Large but no cue — still likely pedagogical (full-page illustration)
        return "pedagogical"
    return "unknown"

#!/usr/bin/env python3
"""
Manhaji PDF Content Extractor
Extracts lessons, text, and images from Palestinian National Curriculum textbooks.
Outputs JSON files for import into the Spring Boot backend.

Usage:
    python extract.py                          # Extract all PDFs in PDFBooks/
    python extract.py --pdf path/to/book.pdf   # Extract a single PDF
    python extract.py --gemini                 # Use Gemini AI for text cleanup
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

import pdfplumber
import fitz  # PyMuPDF
from bidi.algorithm import get_display
import arabic_reshaper

# Project root (two levels up from tools/pdf_extractor/)
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
PDF_DIR = PROJECT_ROOT / "PDFBooks"
OUTPUT_DIR = PROJECT_ROOT / "Manhaji" / "src" / "main" / "resources" / "curriculum"
IMAGE_DIR = PROJECT_ROOT / "Manhaji" / "uploads" / "images"

# Subject code mapping
SUBJECT_MAP = {
    "لغتنا الجميلة": {"code": "ar", "name": "اللغة العربية", "lang": "ar"},
    "الرياضيات": {"code": "ma", "name": "الرياضيات", "lang": "ar"},
    "English": {"code": "en", "name": "اللغة الإنجليزية", "lang": "en"},
}

# Common Arabic lesson title patterns
ARABIC_LESSON_PATTERNS = [
    r'الدرس\s+(الأول|الثاني|الثالث|الرابع|الخامس|السادس|السابع|الثامن|التاسع|العاشر)',
    r'الدرس\s+(\d+)',
    r'حرف\s+(\S+)',  # Letter lessons for Arabic
    r'الوحدة\s+(الأولى|الثانية|الثالثة|الرابعة|الخامسة)',
    r'Unit\s+(\d+)',
    r'Lesson\s+(\d+)',
]

# Arabic ordinal to number mapping
ORDINAL_MAP = {
    'الأول': 1, 'الثاني': 2, 'الثالث': 3, 'الرابع': 4, 'الخامس': 5,
    'السادس': 6, 'السابع': 7, 'الثامن': 8, 'التاسع': 9, 'العاشر': 10,
    'الحادي عشر': 11, 'الثاني عشر': 12,
    'الأولى': 1, 'الثانية': 2, 'الثالثة': 3, 'الرابعة': 4, 'الخامسة': 5,
}


def fix_arabic_text(text):
    """Fix reversed/garbled Arabic text from PDF extraction."""
    if not text:
        return ""

    # Check if text looks reversed (common issue with Arabic PDF extraction)
    # Heuristic: if common Arabic words appear reversed, flip the text
    reversed_markers = ['سردلا', 'ةدحولا', 'فرح', 'باتك']  # reversed: الدرس, الوحدة, حرف, كتاب
    normal_markers = ['الدرس', 'الوحدة', 'حرف', 'كتاب']

    has_reversed = any(marker in text for marker in reversed_markers)
    has_normal = any(marker in text for marker in normal_markers)

    if has_reversed and not has_normal:
        # Text is likely reversed — try bidi algorithm
        try:
            reshaped = arabic_reshaper.reshape(text)
            display = get_display(reshaped)
            # If the display version has normal markers, use it
            if any(marker in display for marker in normal_markers):
                return display
        except Exception:
            pass

        # Fallback: reverse line by line
        lines = text.split('\n')
        fixed_lines = []
        for line in lines:
            if any(c in line for c in 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي'):
                fixed_lines.append(line[::-1])
            else:
                fixed_lines.append(line)
        return '\n'.join(fixed_lines)

    return text


def clean_text(text):
    """Clean extracted text: normalize whitespace, remove artifacts."""
    if not text:
        return ""
    # Remove common PDF artifacts
    text = re.sub(r'\x00', '', text)
    # Normalize whitespace
    text = re.sub(r'[ \t]+', ' ', text)
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text.strip()


def extract_text_from_pdf(pdf_path):
    """Extract text from PDF using pdfplumber, page by page."""
    pages = []
    with pdfplumber.open(pdf_path) as pdf:
        for i, page in enumerate(pdf.pages):
            text = page.extract_text() or ""
            text = fix_arabic_text(text)
            text = clean_text(text)
            pages.append({
                "page_num": i + 1,
                "text": text
            })
    return pages


def extract_images_from_pdf(pdf_path, subject_code, output_dir):
    """Extract images from PDF using PyMuPDF."""
    images = []
    doc = fitz.open(pdf_path)

    subject_img_dir = output_dir / subject_code
    subject_img_dir.mkdir(parents=True, exist_ok=True)

    for page_num in range(len(doc)):
        page = doc[page_num]
        image_list = page.get_images(full=True)

        for img_idx, img_info in enumerate(image_list):
            xref = img_info[0]
            try:
                base_image = doc.extract_image(xref)
                if base_image:
                    image_bytes = base_image["image"]
                    image_ext = base_image["ext"]

                    # Skip very small images (likely decorations/bullets)
                    if len(image_bytes) < 2000:
                        continue

                    filename = f"page{page_num + 1:03d}_img{img_idx + 1:02d}.{image_ext}"
                    filepath = subject_img_dir / filename
                    with open(filepath, "wb") as f:
                        f.write(image_bytes)

                    images.append({
                        "page_num": page_num + 1,
                        "filename": filename,
                        "path": f"uploads/images/{subject_code}/{filename}",
                        "size": len(image_bytes)
                    })
            except Exception as e:
                print(f"  Warning: Could not extract image on page {page_num + 1}: {e}")

    doc.close()
    return images


def find_lesson_boundaries(pages, subject_code):
    """Identify lesson boundaries from page text."""
    lessons = []
    current_lesson = None

    for page in pages:
        text = page["text"]
        page_num = page["page_num"]

        # Try each lesson pattern
        for pattern in ARABIC_LESSON_PATTERNS:
            matches = re.finditer(pattern, text)
            for match in matches:
                # We found a new lesson boundary
                if current_lesson:
                    current_lesson["end_page"] = page_num - 1
                    lessons.append(current_lesson)

                title_text = match.group(0)
                # Try to get more context for the title (rest of the line)
                line_start = text.rfind('\n', 0, match.start()) + 1
                line_end = text.find('\n', match.end())
                if line_end == -1:
                    line_end = len(text)
                full_line = text[line_start:line_end].strip()

                current_lesson = {
                    "title": full_line if len(full_line) < 100 else title_text,
                    "start_page": page_num,
                    "end_page": None,
                    "order_index": len(lessons) + 1
                }
                break  # Only match one pattern per page scan pass

    # Close the last lesson
    if current_lesson:
        current_lesson["end_page"] = pages[-1]["page_num"] if pages else current_lesson["start_page"]
        lessons.append(current_lesson)

    # If no lessons were found, treat the whole book as chunks
    if not lessons:
        print(f"  No lesson patterns found for {subject_code}, creating page-based chunks")
        chunk_size = 8  # pages per "lesson"
        for i in range(0, len(pages), chunk_size):
            chunk_pages = pages[i:i + chunk_size]
            if chunk_pages:
                lessons.append({
                    "title": f"الدرس {len(lessons) + 1}",
                    "start_page": chunk_pages[0]["page_num"],
                    "end_page": chunk_pages[-1]["page_num"],
                    "order_index": len(lessons) + 1
                })

    return lessons


def collect_lesson_content(pages, lesson, images):
    """Collect text and images for a specific lesson."""
    start = lesson["start_page"]
    end = lesson["end_page"] or start

    # Collect text from lesson pages
    lesson_text = []
    for page in pages:
        if start <= page["page_num"] <= end:
            if page["text"]:
                lesson_text.append(page["text"])

    # Collect images from lesson pages
    lesson_images = [
        img["path"] for img in images
        if start <= img["page_num"] <= end
    ]

    return "\n\n".join(lesson_text), lesson_images


def generate_basic_questions(lesson_title, lesson_content, subject_code, difficulty=1):
    """Generate basic questions without AI (template-based fallback)."""
    questions = []

    if subject_code == "ar":
        # For Arabic letter lessons, generate letter-recognition questions
        letter_match = re.search(r'حرف\s+(\S+)', lesson_title)
        if letter_match:
            letter = letter_match.group(1)
            questions.append({
                "type": "TRUE_FALSE",
                "questionText": f"حرف {letter} من حروف اللغة العربية",
                "correctAnswer": "صح",
                "options": None,
                "difficultyLevel": 1
            })
            questions.append({
                "type": "SHORT_ANSWER",
                "questionText": f"اكتب حرف {letter}",
                "correctAnswer": letter,
                "options": None,
                "difficultyLevel": 1
            })
        else:
            questions.append({
                "type": "TRUE_FALSE",
                "questionText": f"هذا الدرس بعنوان: {lesson_title}",
                "correctAnswer": "صح",
                "options": None,
                "difficultyLevel": 1
            })

    elif subject_code == "ma":
        # Basic math questions
        questions.append({
            "type": "TRUE_FALSE",
            "questionText": "الرقم 5 أكبر من الرقم 3",
            "correctAnswer": "صح",
            "options": None,
            "difficultyLevel": 1
        })
        questions.append({
            "type": "MCQ",
            "questionText": "ما ناتج 2 + 3 ؟",
            "correctAnswer": "5",
            "options": ["3", "4", "5", "6"],
            "difficultyLevel": 1
        })

    elif subject_code == "en":
        questions.append({
            "type": "TRUE_FALSE",
            "questionText": "The letter A is the first letter of the alphabet",
            "correctAnswer": "صح",
            "options": None,
            "difficultyLevel": 1
        })

    return questions


def process_pdf(pdf_path, subject_info, grade, semester, use_gemini=False):
    """Process a single PDF textbook and return structured lesson data."""
    subject_code = subject_info["code"]
    subject_name = subject_info["name"]
    file_code = f"{subject_code}{grade}-p{semester}"

    print(f"\n{'='*60}")
    print(f"Processing: {pdf_path.name}")
    print(f"Subject: {subject_name} | Grade: {grade} | Semester: {semester}")
    print(f"{'='*60}")

    # Step 1: Extract text
    print("  [1/4] Extracting text...")
    pages = extract_text_from_pdf(str(pdf_path))
    print(f"         Extracted {len(pages)} pages")

    # Step 2: Extract images
    print("  [2/4] Extracting images...")
    images = extract_images_from_pdf(str(pdf_path), file_code, IMAGE_DIR)
    print(f"         Extracted {len(images)} images")

    # Step 3: Find lesson boundaries
    print("  [3/4] Finding lesson boundaries...")
    lessons = find_lesson_boundaries(pages, subject_code)
    print(f"         Found {len(lessons)} lessons")

    # Step 4: Build lesson data
    print("  [4/4] Building lesson content...")
    lesson_data = []
    for lesson in lessons:
        content, image_urls = collect_lesson_content(pages, lesson, images)

        # Generate questions (basic template or AI)
        questions = generate_basic_questions(
            lesson["title"], content, subject_code
        )

        lesson_entry = {
            "title": lesson["title"],
            "orderIndex": lesson["order_index"],
            "content": content[:5000] if content else "",  # Limit content size
            "objectives": f"أهداف درس: {lesson['title']}",
            "imageUrls": image_urls,
            "questions": questions,
            "startPage": lesson["start_page"],
            "endPage": lesson["end_page"]
        }
        lesson_data.append(lesson_entry)
        print(f"         Lesson {lesson['order_index']}: {lesson['title'][:50]} "
              f"(pages {lesson['start_page']}-{lesson['end_page']}, "
              f"{len(image_urls)} images, {len(questions)} questions)")

    return {
        "subject": subject_name,
        "subjectCode": subject_code,
        "gradeLevel": grade,
        "semester": semester,
        "totalLessons": len(lesson_data),
        "lessons": lesson_data
    }


def discover_pdfs():
    """Discover all PDFs in the PDFBooks directory."""
    pdfs = []
    if not PDF_DIR.exists():
        print(f"Error: PDFBooks directory not found at {PDF_DIR}")
        return pdfs

    for grade_dir in sorted(PDF_DIR.iterdir()):
        if not grade_dir.is_dir():
            continue

        # Extract grade number from folder name (e.g., "1Grade" -> 1)
        grade_match = re.search(r'(\d+)', grade_dir.name)
        if not grade_match:
            continue
        grade = int(grade_match.group(1))

        for subject_dir in sorted(grade_dir.iterdir()):
            if not subject_dir.is_dir():
                continue

            subject_name = subject_dir.name
            if subject_name not in SUBJECT_MAP:
                print(f"  Warning: Unknown subject folder '{subject_name}', skipping")
                continue

            subject_info = SUBJECT_MAP[subject_name]

            for pdf_file in sorted(subject_dir.glob("*.pdf")):
                # Determine semester from filename (e.g., "ar1-p1.pdf" -> semester 1)
                semester_match = re.search(r'p(\d+)', pdf_file.stem)
                semester = int(semester_match.group(1)) if semester_match else 1

                pdfs.append({
                    "path": pdf_file,
                    "subject_info": subject_info,
                    "grade": grade,
                    "semester": semester
                })

    return pdfs


def main():
    parser = argparse.ArgumentParser(description="Manhaji PDF Content Extractor")
    parser.add_argument("--pdf", type=str, help="Path to a single PDF to extract")
    parser.add_argument("--gemini", action="store_true", help="Use Gemini AI for text cleanup")
    parser.add_argument("--output", type=str, help="Custom output directory")
    args = parser.parse_args()

    output_dir = Path(args.output) if args.output else OUTPUT_DIR
    output_dir.mkdir(parents=True, exist_ok=True)
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("  منهجي - PDF Content Extractor")
    print("  Palestinian National Curriculum")
    print("=" * 60)

    if args.pdf:
        # Single PDF mode
        pdf_path = Path(args.pdf)
        if not pdf_path.exists():
            print(f"Error: PDF not found: {pdf_path}")
            sys.exit(1)

        # Try to infer subject/grade/semester from path
        subject_info = {"code": "unknown", "name": "Unknown", "lang": "ar"}
        grade = 1
        semester = 1

        for name, info in SUBJECT_MAP.items():
            if name in str(pdf_path):
                subject_info = info
                break

        grade_match = re.search(r'(\d+)Grade', str(pdf_path))
        if grade_match:
            grade = int(grade_match.group(1))

        semester_match = re.search(r'p(\d+)', pdf_path.stem)
        if semester_match:
            semester = int(semester_match.group(1))

        result = process_pdf(pdf_path, subject_info, grade, semester, args.gemini)

        output_file = output_dir / f"{subject_info['code']}{grade}_p{semester}.json"
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        print(f"\nOutput saved to: {output_file}")

    else:
        # Batch mode: process all discovered PDFs
        pdfs = discover_pdfs()
        if not pdfs:
            print("No PDFs found in PDFBooks directory.")
            sys.exit(1)

        print(f"\nFound {len(pdfs)} PDF files to process:")
        for pdf in pdfs:
            print(f"  - {pdf['path'].name} ({pdf['subject_info']['name']}, "
                  f"Grade {pdf['grade']}, Semester {pdf['semester']})")

        results = []
        for pdf in pdfs:
            result = process_pdf(
                pdf["path"], pdf["subject_info"],
                pdf["grade"], pdf["semester"], args.gemini
            )
            results.append(result)

            # Save individual JSON
            code = pdf["subject_info"]["code"]
            output_file = output_dir / f"{code}{pdf['grade']}_p{pdf['semester']}.json"
            with open(output_file, "w", encoding="utf-8") as f:
                json.dump(result, f, ensure_ascii=False, indent=2)
            print(f"  Saved: {output_file.name}")

        # Print summary
        print(f"\n{'='*60}")
        print("  EXTRACTION SUMMARY")
        print(f"{'='*60}")
        total_lessons = 0
        total_images = 0
        total_questions = 0
        for r in results:
            lessons_count = r["totalLessons"]
            imgs = sum(len(l["imageUrls"]) for l in r["lessons"])
            qs = sum(len(l["questions"]) for l in r["lessons"])
            total_lessons += lessons_count
            total_images += imgs
            total_questions += qs
            print(f"  {r['subject']}: {lessons_count} lessons, {imgs} images, {qs} questions")

        print(f"\n  Total: {total_lessons} lessons, {total_images} images, {total_questions} questions")
        print(f"  Output: {output_dir}")
        print(f"  Images: {IMAGE_DIR}")


if __name__ == "__main__":
    main()

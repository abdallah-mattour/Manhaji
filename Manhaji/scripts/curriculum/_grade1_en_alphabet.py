# -*- coding: utf-8 -*-
"""
English Grade 1 — the four alphabet lessons (A-G, H-N, O-T, U-Z).

The real *English for Palestine 1* books carry 'The alphabet' as an appendix
(PB1A/PB1B page 62), so these lessons are kept and appended AFTER the book
units by _build_grade1_en_p1/p2.py. Content extracted verbatim from the
pre-rebuild en1_p1.json (authored 2026-04-26); orderIndex is assigned by the
builder at append time.
"""
ALPHABET_LESSONS = [
  {
    "title": "English Alphabet (A-G)",
    "orderIndex": 1,
    "content": "Letters A B C D E F G. Sample words: Apple, Bag, Cat, Dog, Egg, Fish, Goat.",
    "objectives": "Learn the first seven letters of the English alphabet (A-G), recognize their shapes, hear their sounds, and write them.",
    "questions": [
      {
        "type": "MCQ",
        "questionText": "Which letter is FIRST in the English alphabet?",
        "correctAnswer": "A",
        "options": [
          "A",
          "B",
          "C",
          "D"
        ],
        "difficultyLevel": 1,
        "subSkill": "recognition"
      },
      {
        "type": "MCQ",
        "questionText": "Which letter does the word 'Cat' start with?",
        "correctAnswer": "C",
        "options": [
          "A",
          "B",
          "C",
          "G"
        ],
        "difficultyLevel": 1,
        "subSkill": "recognition"
      },
      {
        "type": "MCQ",
        "questionText": "Which letter sounds like /b/ as in 'Bag'?",
        "correctAnswer": "B",
        "options": [
          "A",
          "B",
          "C",
          "D"
        ],
        "difficultyLevel": 2,
        "subSkill": "comprehension"
      },
      {
        "type": "TRUE_FALSE",
        "questionText": "B is the second letter of the English alphabet",
        "correctAnswer": "True",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "comprehension"
      },
      {
        "type": "SHORT_ANSWER",
        "questionText": "What letter comes after C?",
        "correctAnswer": "D",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "production"
      },
      {
        "type": "SHORT_ANSWER",
        "questionText": "Write the first letter of the word 'Goat'",
        "correctAnswer": "G",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "production"
      },
      {
        "type": "FILL_BLANK",
        "questionText": "Complete: A, B, C, ___, E, F, G",
        "correctAnswer": "D",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "production"
      },
      {
        "type": "ORDERING",
        "questionText": "Put the letters in alphabet order: F, A, D, B",
        "correctAnswer": "A, B, D, F",
        "options": [
          "F",
          "A",
          "D",
          "B"
        ],
        "difficultyLevel": 2,
        "subSkill": "application"
      },
      {
        "type": "PRONUNCIATION",
        "questionText": "Say the letter: A",
        "correctAnswer": "A",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "pronunciation"
      },
      {
        "type": "PRONUNCIATION",
        "questionText": "Say the letter: G",
        "correctAnswer": "G",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "pronunciation"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter A",
        "correctAnswer": "A",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "handwriting"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter B",
        "correctAnswer": "B",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "handwriting"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter C",
        "correctAnswer": "C",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "handwriting"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter g (lowercase)",
        "correctAnswer": "g",
        "options": None,
        "difficultyLevel": 2,
        "subSkill": "handwriting"
      },
      {
        "type": "MCQ",
        "questionText": "If APPLE starts with A and BANANA starts with B, what about EGG?",
        "correctAnswer": "Starts with E",
        "options": [
          "Starts with A",
          "Starts with B",
          "Starts with E",
          "Starts with F"
        ],
        "difficultyLevel": 3,
        "subSkill": "application"
      }
    ],
    "imageUrls": []
  },
  {
    "title": "English Alphabet (H-N)",
    "orderIndex": 2,
    "content": "Letters H I J K L M N. Sample words: Hat, Ice, Jam, Kite, Leg, Moon, Nest.",
    "objectives": "Learn the second group of seven letters (H-N), recognize their shapes, hear their sounds, and write them.",
    "questions": [
      {
        "type": "MCQ",
        "questionText": "Which letter does the word 'Hat' start with?",
        "correctAnswer": "H",
        "options": [
          "G",
          "H",
          "I",
          "J"
        ],
        "difficultyLevel": 1,
        "subSkill": "recognition"
      },
      {
        "type": "MCQ",
        "questionText": "Which letter comes between K and M in the alphabet?",
        "correctAnswer": "L",
        "options": [
          "I",
          "J",
          "L",
          "N"
        ],
        "difficultyLevel": 2,
        "subSkill": "comprehension"
      },
      {
        "type": "MCQ",
        "questionText": "Which word starts with the letter J?",
        "correctAnswer": "Jam",
        "options": [
          "Hat",
          "Ice",
          "Jam",
          "Kite"
        ],
        "difficultyLevel": 1,
        "subSkill": "recognition"
      },
      {
        "type": "TRUE_FALSE",
        "questionText": "M comes before N in the English alphabet",
        "correctAnswer": "True",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "comprehension"
      },
      {
        "type": "SHORT_ANSWER",
        "questionText": "What letter comes after H?",
        "correctAnswer": "I",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "production"
      },
      {
        "type": "SHORT_ANSWER",
        "questionText": "Write the first letter of the word 'Moon'",
        "correctAnswer": "M",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "production"
      },
      {
        "type": "FILL_BLANK",
        "questionText": "Complete: H, I, J, ___, L, M, N",
        "correctAnswer": "K",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "production"
      },
      {
        "type": "ORDERING",
        "questionText": "Put the letters in alphabet order: N, J, L, H, K",
        "correctAnswer": "H, J, K, L, N",
        "options": [
          "N",
          "J",
          "L",
          "H",
          "K"
        ],
        "difficultyLevel": 2,
        "subSkill": "application"
      },
      {
        "type": "PRONUNCIATION",
        "questionText": "Say the letter: J",
        "correctAnswer": "J",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "pronunciation"
      },
      {
        "type": "PRONUNCIATION",
        "questionText": "Say the letter: K",
        "correctAnswer": "K",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "pronunciation"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter H",
        "correctAnswer": "H",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "handwriting"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter I",
        "correctAnswer": "I",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "handwriting"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter L",
        "correctAnswer": "L",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "handwriting"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter n (lowercase)",
        "correctAnswer": "n",
        "options": None,
        "difficultyLevel": 2,
        "subSkill": "handwriting"
      },
      {
        "type": "MCQ",
        "questionText": "Which letter is the SAME shape upside down: H, M, or J?",
        "correctAnswer": "H",
        "options": [
          "H",
          "M",
          "J",
          "None"
        ],
        "difficultyLevel": 3,
        "subSkill": "application"
      }
    ],
    "imageUrls": []
  },
  {
    "title": "English Alphabet (O-T)",
    "orderIndex": 3,
    "content": "Letters O P Q R S T. Sample words: Orange, Pen, Queen, Rabbit, Sun, Tree.",
    "objectives": "Learn the third group of six letters (O-T), recognize their shapes, hear their sounds, and write them.",
    "questions": [
      {
        "type": "MCQ",
        "questionText": "Which letter does the word 'Sun' start with?",
        "correctAnswer": "S",
        "options": [
          "O",
          "P",
          "S",
          "T"
        ],
        "difficultyLevel": 1,
        "subSkill": "recognition"
      },
      {
        "type": "MCQ",
        "questionText": "Which letter looks like a circle?",
        "correctAnswer": "O",
        "options": [
          "O",
          "P",
          "Q",
          "T"
        ],
        "difficultyLevel": 1,
        "subSkill": "recognition"
      },
      {
        "type": "MCQ",
        "questionText": "Which letter sounds like /t/ as in 'Tree'?",
        "correctAnswer": "T",
        "options": [
          "P",
          "Q",
          "S",
          "T"
        ],
        "difficultyLevel": 2,
        "subSkill": "comprehension"
      },
      {
        "type": "TRUE_FALSE",
        "questionText": "Q is followed by R in the English alphabet",
        "correctAnswer": "True",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "comprehension"
      },
      {
        "type": "SHORT_ANSWER",
        "questionText": "What letter comes between O and Q?",
        "correctAnswer": "P",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "production"
      },
      {
        "type": "SHORT_ANSWER",
        "questionText": "Write the first letter of the word 'Rabbit'",
        "correctAnswer": "R",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "production"
      },
      {
        "type": "FILL_BLANK",
        "questionText": "Complete: O, P, Q, ___, S, T",
        "correctAnswer": "R",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "production"
      },
      {
        "type": "ORDERING",
        "questionText": "Put the letters in alphabet order: T, P, R, O, S",
        "correctAnswer": "O, P, R, S, T",
        "options": [
          "T",
          "P",
          "R",
          "O",
          "S"
        ],
        "difficultyLevel": 2,
        "subSkill": "application"
      },
      {
        "type": "PRONUNCIATION",
        "questionText": "Say the letter: Q",
        "correctAnswer": "Q",
        "options": None,
        "difficultyLevel": 2,
        "subSkill": "pronunciation"
      },
      {
        "type": "PRONUNCIATION",
        "questionText": "Say the letter: R",
        "correctAnswer": "R",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "pronunciation"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter O",
        "correctAnswer": "O",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "handwriting"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter P",
        "correctAnswer": "P",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "handwriting"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter S",
        "correctAnswer": "S",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "handwriting"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter t (lowercase)",
        "correctAnswer": "t",
        "options": None,
        "difficultyLevel": 2,
        "subSkill": "handwriting"
      },
      {
        "type": "MCQ",
        "questionText": "Which TWO letters look most alike: O, P, Q?",
        "correctAnswer": "O and Q",
        "options": [
          "O and P",
          "O and Q",
          "P and Q",
          "All look the same"
        ],
        "difficultyLevel": 3,
        "subSkill": "application"
      }
    ],
    "imageUrls": []
  },
  {
    "title": "English Alphabet (U-Z)",
    "orderIndex": 4,
    "content": "Letters U V W X Y Z. Sample words: Umbrella, Van, Water, Box, Yellow, Zoo.",
    "objectives": "Learn the last six letters (U-Z), recognize their shapes, hear their sounds, and write them.",
    "questions": [
      {
        "type": "MCQ",
        "questionText": "Which letter is the LAST in the English alphabet?",
        "correctAnswer": "Z",
        "options": [
          "W",
          "X",
          "Y",
          "Z"
        ],
        "difficultyLevel": 1,
        "subSkill": "recognition"
      },
      {
        "type": "MCQ",
        "questionText": "Which letter does the word 'Zoo' start with?",
        "correctAnswer": "Z",
        "options": [
          "X",
          "Y",
          "Z",
          "W"
        ],
        "difficultyLevel": 1,
        "subSkill": "recognition"
      },
      {
        "type": "MCQ",
        "questionText": "Which letter sounds like /w/ as in 'Water'?",
        "correctAnswer": "W",
        "options": [
          "U",
          "V",
          "W",
          "X"
        ],
        "difficultyLevel": 2,
        "subSkill": "comprehension"
      },
      {
        "type": "TRUE_FALSE",
        "questionText": "There are 26 letters in the English alphabet",
        "correctAnswer": "True",
        "options": None,
        "difficultyLevel": 2,
        "subSkill": "comprehension"
      },
      {
        "type": "SHORT_ANSWER",
        "questionText": "What letter comes after V?",
        "correctAnswer": "W",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "production"
      },
      {
        "type": "SHORT_ANSWER",
        "questionText": "Write the first letter of the word 'Yellow'",
        "correctAnswer": "Y",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "production"
      },
      {
        "type": "FILL_BLANK",
        "questionText": "Complete: U, V, W, X, ___, Z",
        "correctAnswer": "Y",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "production"
      },
      {
        "type": "ORDERING",
        "questionText": "Put the letters in alphabet order: Z, V, X, U, W, Y",
        "correctAnswer": "U, V, W, X, Y, Z",
        "options": [
          "Z",
          "V",
          "X",
          "U",
          "W",
          "Y"
        ],
        "difficultyLevel": 2,
        "subSkill": "application"
      },
      {
        "type": "PRONUNCIATION",
        "questionText": "Say the letter: W",
        "correctAnswer": "W",
        "options": None,
        "difficultyLevel": 2,
        "subSkill": "pronunciation"
      },
      {
        "type": "PRONUNCIATION",
        "questionText": "Say the letter: Y",
        "correctAnswer": "Y",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "pronunciation"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter V",
        "correctAnswer": "V",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "handwriting"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter X",
        "correctAnswer": "X",
        "options": None,
        "difficultyLevel": 2,
        "subSkill": "handwriting"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter Y",
        "correctAnswer": "Y",
        "options": None,
        "difficultyLevel": 2,
        "subSkill": "handwriting"
      },
      {
        "type": "TRACING",
        "questionText": "Trace the letter z (lowercase)",
        "correctAnswer": "z",
        "options": None,
        "difficultyLevel": 1,
        "subSkill": "handwriting"
      },
      {
        "type": "MCQ",
        "questionText": "If we sing the alphabet song, which letter do we sing JUST BEFORE Z?",
        "correctAnswer": "Y",
        "options": [
          "W",
          "X",
          "Y",
          "U"
        ],
        "difficultyLevel": 3,
        "subSkill": "application"
      }
    ],
    "imageUrls": []
  }
]

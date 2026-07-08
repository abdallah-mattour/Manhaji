# -*- coding: utf-8 -*-
"""
Grade 4 English, semester 1 — authored from the real book
(PDFBooks/4Grade/English/en4-p1.pdf, unit/context scan).

Nine units (English for Palestine 4, part 1):
  1 A new friend      2 Our house        3 Lost!
  4 Shopping list     5 Revision (1-4)   6 On Sundays I …
  7 At the restaurant 8 My favourite season   9 Revision (6-8)

Questions are original (not copied from the book); vocabulary and language
targets follow the unit contexts. Run: python _build_grade4_en_p1.py
"""
from __future__ import annotations

from _common import q, write_curriculum

L = [
    {
        "title": "A new friend",
        "content": "Introducing yourself and other people: name, age, family and "
                   "jobs. I'm Hala. I'm from Jerusalem. His name's Sami. She's an engineer.",
        "objectives": "Introduce yourself and describe other people.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Choose the greeting for a new pupil.", "Welcome!",
              ["Welcome!", "Goodbye!", "Sorry!", "Good night!"], 1, "recognition"),
            q("MCQ", "Which word means a person who builds bridges and machines?", "engineer",
              ["engineer", "housewife", "pupil", "hobby"], 2, "recognition"),
            q("MCQ", "'She ___ from Haifa.' Choose the correct word.", "is",
              ["is", "am", "are", "be"], 2, "production"),
            q("MCQ", "What do we call something you like to do in your free time?", "a hobby",
              ["a hobby", "a job", "a name", "a city"], 1, "recognition"),
            q("TRUE_FALSE", "'I'm nine' tells us a person's age.", "True", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: His ___ is Sami. He is my friend.", "name", None, 1, "production"),
            q("SHORT_ANSWER", "Write one question you can ask a new friend about their home.",
              "Where are you from?", None, 2, "production"),
            q("ORDERING", "Put the words in order: from, I'm, Jerusalem",
              "I'm, from, Jerusalem", ["from", "I'm", "Jerusalem"], 3, "application"),
            q("PRONUNCIATION", "engineer", "engineer", None, 2, "pronunciation"),
            q("READING", "Hello! My name is Hala. I am from Jerusalem and I am nine.",
              "Hello! My name is Hala. I am from Jerusalem and I am nine.", None, 2, "reading"),
        ],
    },
    {
        "title": "Our house",
        "content": "Rooms in a house and saying what people are doing: living room, "
                   "kitchen, bathroom, bedroom, garden; watch TV, cook, sleep.",
        "objectives": "Name rooms and describe present actions.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Where do we usually cook food?", "in the kitchen",
              ["in the kitchen", "in the bedroom", "in the bathroom", "in the garden"], 1, "recognition"),
            q("MCQ", "Where do we sleep?", "in the bedroom",
              ["in the bedroom", "in the kitchen", "in the living room", "in the garden"], 1, "recognition"),
            q("MCQ", "'What is mum ___?' Choose the correct word.", "doing",
              ["doing", "does", "do", "did"], 2, "production"),
            q("MCQ", "'Dad is ___ a shower.' Choose the best word.", "having",
              ["having", "cooking", "reading", "sleeping"], 2, "recognition"),
            q("TRUE_FALSE", "We grow flowers and plants in the garden.", "True", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: We watch TV in the ___ room.", "living", None, 1, "production"),
            q("SHORT_ANSWER", "Name two rooms in a house.", "kitchen and bedroom", None, 2, "production"),
            q("ORDERING", "Put in order: is, Dad, the kitchen, in",
              "Dad, is, in, the kitchen", ["is", "Dad", "the kitchen", "in"], 3, "application"),
            q("PRONUNCIATION", "bathroom", "bathroom", None, 2, "pronunciation"),
            q("READING", "This is my house. It has a kitchen, two bedrooms and a small garden.",
              "This is my house. It has a kitchen, two bedrooms and a small garden.", None, 2, "reading"),
        ],
    },
    {
        "title": "Lost!",
        "content": "Things in a house and who they belong to: cupboard, drawer, shelf, "
                   "lamp; my, your, his, her, their; behind, in front of.",
        "objectives": "Talk about belongings and positions.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Where do we keep books to display them?", "on a shelf",
              ["on a shelf", "in a bin", "under a lamp", "behind a chair"], 1, "recognition"),
            q("MCQ", "We throw rubbish in the ___.", "bin",
              ["bin", "drawer", "shelf", "lamp"], 1, "recognition"),
            q("MCQ", "'This is ___ book.' It belongs to Fatima. Choose the best word.", "her",
              ["her", "his", "my", "their"], 2, "production"),
            q("MCQ", "The cat is ___ the chair (you cannot see it). Choose the best word.", "behind",
              ["behind", "in front of", "on", "under"], 2, "comprehension"),
            q("TRUE_FALSE", "'What a mess!' means the room is very tidy.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: I can't ___ my pencil. Where is it?", "find", None, 1, "production"),
            q("SHORT_ANSWER", "Where can you keep your clothes in a bedroom?", "in the cupboard", None, 2, "production"),
            q("ORDERING", "Put in order: my, is, book, this",
              "this, is, my, book", ["my", "is", "book", "this"], 3, "application"),
            q("PRONUNCIATION", "cupboard", "cupboard", None, 2, "pronunciation"),
            q("READING", "My room is a mess! My books are on the floor and my bag is behind the door.",
              "My room is a mess! My books are on the floor and my bag is behind the door.", None, 2, "reading"),
        ],
    },
    {
        "title": "Shopping list",
        "content": "Quantities and shopping: carton, packet, can, bag, bottle, kilo; "
                   "numbers 10-100; How much is it? Anything else?",
        "objectives": "Ask about prices and quantities when shopping.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "We buy milk in a ___.", "carton",
              ["carton", "kilo", "bag", "packet"], 1, "recognition"),
            q("MCQ", "We buy water in a ___.", "bottle",
              ["bottle", "can", "packet", "carton"], 1, "recognition"),
            q("MCQ", "Which question asks about price?", "How much is it?",
              ["How much is it?", "How old are you?", "Where is it?", "What time is it?"], 2, "comprehension"),
            q("MCQ", "Count by tens: 10, 20, 30, ___", "40",
              ["40", "35", "13", "50"], 2, "computation"),
            q("TRUE_FALSE", "We buy sugar by the kilo.", "True", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: We ___ some bread and eggs from the shop.", "need", None, 1, "production"),
            q("SHORT_ANSWER", "Write one thing you can buy in a packet.", "pasta", None, 2, "production"),
            q("ORDERING", "Put in order: much, is, how, it",
              "how, much, is, it", ["much", "is", "how", "it"], 3, "application"),
            q("PRONUNCIATION", "bottle", "bottle", None, 2, "pronunciation"),
            q("READING", "We need a bag of rice, two cartons of milk and a kilo of apples.",
              "We need a bag of rice, two cartons of milk and a kilo of apples.", None, 2, "reading"),
        ],
    },
    {
        "title": "Revision (Units 1-4)",
        "content": "Review of jobs and hobbies, rooms and actions, belongings and "
                   "positions, and shopping quantities from Units 1-4.",
        "objectives": "Review the language of Units 1-4.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Which one is a job?", "doctor",
              ["doctor", "kitchen", "bottle", "garden"], 1, "recognition"),
            q("MCQ", "Which one is a room?", "living room",
              ["living room", "engineer", "carton", "hobby"], 1, "recognition"),
            q("MCQ", "'They are in ___ garden.' Choose the best word.", "their",
              ["their", "her", "his", "my"], 2, "production"),
            q("MCQ", "We buy juice in a ___.", "bottle",
              ["bottle", "kilo", "shelf", "drawer"], 2, "recognition"),
            q("TRUE_FALSE", "An engineer is a place in a house.", "False", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: How ___ is this bag of oranges?", "much", None, 2, "production"),
            q("SHORT_ANSWER", "Write one hobby you enjoy.", "reading", None, 2, "production"),
            q("ORDERING", "Put in order: is, she, teacher, a",
              "she, is, a, teacher", ["is", "she", "teacher", "a"], 3, "application"),
            q("PRONUNCIATION", "kitchen", "kitchen", None, 2, "pronunciation"),
            q("READING", "My sister is a nurse. She works in a hospital near our house.",
              "My sister is a nurse. She works in a hospital near our house.", None, 2, "reading"),
        ],
    },
    {
        "title": "On Sundays I …",
        "content": "School subjects and days of the week: science, maths, English, "
                   "Arabic, religion, PE. On Mondays we have English.",
        "objectives": "Talk about subjects and weekly routines.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "In which subject do we learn about numbers?", "maths",
              ["maths", "PE", "art", "music"], 1, "recognition"),
            q("MCQ", "In which subject do we run and play sport?", "PE",
              ["PE", "science", "Arabic", "religion"], 1, "recognition"),
            q("MCQ", "Which is a day of the week?", "Monday",
              ["Monday", "science", "English", "maths"], 1, "recognition"),
            q("MCQ", "'On Fridays we ___ go to school.' Choose the best word.", "don't",
              ["don't", "doesn't", "isn't", "aren't"], 2, "production"),
            q("TRUE_FALSE", "In science we learn about plants and animals.", "True", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: On Mondays we ___ English and maths.", "have", None, 1, "production"),
            q("SHORT_ANSWER", "Write your favourite school subject.", "English", None, 2, "production"),
            q("ORDERING", "Put in order: have, we, maths, today",
              "we, have, maths, today", ["have", "we", "maths", "today"], 3, "application"),
            q("PRONUNCIATION", "science", "science", None, 2, "pronunciation"),
            q("READING", "On Sundays we have Arabic and science. I like science very much.",
              "On Sundays we have Arabic and science. I like science very much.", None, 2, "reading"),
        ],
    },
    {
        "title": "At the restaurant",
        "content": "Asking for things in a restaurant: glass, fork, spoon, knife, "
                   "napkin, menu, bill. Could I have a spoon, please?",
        "objectives": "Order food and ask politely at a restaurant.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Which one do we use to cut food?", "knife",
              ["knife", "spoon", "napkin", "menu"], 1, "recognition"),
            q("MCQ", "We drink water from a ___.", "glass",
              ["glass", "fork", "menu", "bill"], 1, "recognition"),
            q("MCQ", "Which shows the food you can order?", "the menu",
              ["the menu", "the bill", "the napkin", "the fork"], 2, "comprehension"),
            q("MCQ", "Choose the polite request.", "Could I have a spoon, please?",
              ["Could I have a spoon, please?", "Give me a spoon.", "Spoon now.", "I want spoon."], 2, "comprehension"),
            q("TRUE_FALSE", "We pay the bill at the end of the meal.", "True", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: I'd ___ fish, please.", "like", None, 1, "production"),
            q("SHORT_ANSWER", "Write one thing you would order for a drink.", "juice", None, 2, "production"),
            q("ORDERING", "Put in order: like, I'd, please, fish",
              "I'd, like, fish, please", ["like", "I'd", "please", "fish"], 3, "application"),
            q("PRONUNCIATION", "napkin", "napkin", None, 2, "pronunciation"),
            q("READING", "Excuse me. Could I have the menu, please? I would like fish and juice.",
              "Excuse me. Could I have the menu, please? I would like fish and juice.", None, 2, "reading"),
        ],
    },
    {
        "title": "My favourite season",
        "content": "Seasons and activities: spring, summer, autumn, winter; go on a "
                   "picnic, fly a kite, ride my bike, build a snowman, pick olives.",
        "objectives": "Talk about seasons and what you like to do.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "In which season do we build a snowman?", "winter",
              ["winter", "summer", "spring", "autumn"], 1, "recognition"),
            q("MCQ", "In which season do people pick olives in Palestine?", "autumn",
              ["autumn", "summer", "spring", "winter"], 2, "comprehension"),
            q("MCQ", "Which activity do we do with wind and a string?", "fly a kite",
              ["fly a kite", "build a snowman", "pick olives", "have a picnic"], 1, "recognition"),
            q("MCQ", "'What do you ___ to do in spring?' Choose the best word.", "like",
              ["like", "likes", "liking", "liked"], 2, "production"),
            q("TRUE_FALSE", "Summer is usually hot and dry.", "True", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: In ___ the leaves fall from the trees.", "autumn", None, 2, "production"),
            q("SHORT_ANSWER", "Write your favourite season.", "spring", None, 2, "production"),
            q("ORDERING", "Put in order: like, I, picnics, spring, in",
              "I, like, picnics, in, spring", ["like", "I", "picnics", "spring", "in"], 3, "application"),
            q("PRONUNCIATION", "winter", "winter", None, 2, "pronunciation"),
            q("READING", "My favourite season is spring. I like to play outdoors and fly my kite.",
              "My favourite season is spring. I like to play outdoors and fly my kite.", None, 2, "reading"),
        ],
    },
    {
        "title": "Revision (Units 6-8)",
        "content": "Review of subjects and days, restaurant language, and seasons and "
                   "activities from Units 6-8.",
        "objectives": "Review the language of Units 6-8.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Which one is a school subject?", "religion",
              ["religion", "spoon", "winter", "menu"], 1, "recognition"),
            q("MCQ", "Which one do we use to eat soup?", "spoon",
              ["spoon", "knife", "kite", "olive"], 1, "recognition"),
            q("MCQ", "Which activity belongs to winter?", "build a snowman",
              ["build a snowman", "pick olives", "fly a kite", "have a picnic"], 2, "comprehension"),
            q("MCQ", "'We ___ school on Fridays.' Choose the best word.", "don't have",
              ["don't have", "has", "having", "to have"], 2, "production"),
            q("TRUE_FALSE", "We say the bill when we ask for the food list.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: Could I ___ a glass of water, please?", "have", None, 1, "production"),
            q("SHORT_ANSWER", "Write one thing you do in summer.", "swim", None, 2, "production"),
            q("ORDERING", "Put in order: PE, have, we, today",
              "we, have, PE, today", ["PE", "have", "we", "today"], 3, "application"),
            q("PRONUNCIATION", "autumn", "autumn", None, 2, "pronunciation"),
            q("READING", "In summer I go to the beach. In winter I stay indoors and read books.",
              "In summer I go to the beach. In winter I stay indoors and read books.", None, 2, "reading"),
        ],
    },
]


def main():
    write_curriculum(subject_code="en", grade=4, semester=1, lessons=L)


if __name__ == "__main__":
    main()

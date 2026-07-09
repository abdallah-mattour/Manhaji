# -*- coding: utf-8 -*-
"""
Grade 4 English, semester 2 — authored from the real book
(PDFBooks/4Grade/English/en4-p2.pdf, unit/context scan).

Nine units (English for Palestine 4, part 2):
  10 Visiting Palestine  11 Let's make a cake  12 It's 7:30
  13 Good habits         14 Revision (10-13)   15 I can do it!
  16 In my street        17 On the farm        18 Revision (15-17)

Questions are original; vocabulary and language follow the unit contexts.
Run: python _build_grade4_en_p2.py
"""
from __future__ import annotations

from _common import q, write_curriculum

L = [
    {
        "title": "Visiting Palestine",
        "content": "Places in Palestine and future plans: Akka, Hebron, the old city, "
                   "Al-Aqsa Mosque, the Dome of the Rock, the Dead Sea, the Mount of Olives. "
                   "I'm going to visit Hebron.",
        "objectives": "Name places in Palestine and say what you are going to do.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "In which city is the Al-Ibrahimi Mosque?", "Hebron",
              ["Hebron", "Akka", "Gaza", "Nablus"], 2, "comprehension"),
            q("MCQ", "The Dome of the Rock is in ___.", "Jerusalem",
              ["Jerusalem", "Hebron", "Akka", "Bethlehem"], 1, "recognition"),
            q("MCQ", "Where can you float easily in very salty water?", "the Dead Sea",
              ["the Dead Sea", "the market", "the old city", "Mount Carmel"], 2, "comprehension"),
            q("MCQ", "'We ___ going to see Al-Aqsa Mosque.' Choose the best word.", "are",
              ["are", "is", "am", "be"], 2, "production"),
            q("TRUE_FALSE", "The Church of the Nativity is in Bethlehem.", "True", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: I'm going to ___ the old city of Jerusalem.", "visit", None, 1, "production"),
            q("SHORT_ANSWER", "Write one place you would like to visit in Palestine.", "Jerusalem", None, 2, "production"),
            q("ORDERING", "Put in order: going, I'm, to, Hebron, visit",
              "I'm, going, to, visit, Hebron", ["going", "I'm", "to", "Hebron", "visit"], 3, "application"),
            q("PRONUNCIATION", "Jerusalem", "Jerusalem", None, 2, "pronunciation"),
            q("READING", "Next week we are going to visit the old city and see Al-Aqsa Mosque.",
              "Next week we are going to visit the old city and see Al-Aqsa Mosque.", None, 2, "reading"),
        ],
    },
    {
        "title": "Let's make a cake",
        "content": "Kitchen items and instructions: flour, butter, sugar, milk, eggs, "
                   "cup, bowl, oven; put, mix, add, bake.",
        "objectives": "Understand and give simple cooking instructions.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "What do we bake a cake in?", "the oven",
              ["the oven", "the bowl", "the cup", "the fridge"], 1, "recognition"),
            q("MCQ", "Which one is white and used to make bread and cakes?", "flour",
              ["flour", "butter", "egg", "milk"], 1, "recognition"),
            q("MCQ", "We ___ the eggs and sugar together. Choose the best word.", "mix",
              ["mix", "bake", "read", "sleep"], 2, "comprehension"),
            q("MCQ", "In which order do we usually do these? First ___.", "mix the ingredients",
              ["mix the ingredients", "eat the cake", "bake the cake", "clean the plate"], 2, "comprehension"),
            q("TRUE_FALSE", "We put the cake in the oven to bake it.", "True", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: ___ the flour into the bowl.", "Put", None, 1, "production"),
            q("SHORT_ANSWER", "Write one thing you need to make a cake.", "sugar", None, 2, "production"),
            q("ORDERING", "Put the steps in order: bake it, mix it, add sugar",
              "add sugar, mix it, bake it", ["bake it", "mix it", "add sugar"], 3, "application"),
            q("PRONUNCIATION", "butter", "butter", None, 2, "pronunciation"),
            q("READING", "First, put the flour in a bowl. Then add sugar and eggs and mix well.",
              "First, put the flour in a bowl. Then add sugar and eggs and mix well.", None, 2, "reading"),
        ],
    },
    {
        "title": "It's 7:30",
        "content": "Telling the time and start/finish times: It's five o'clock. "
                   "It starts at five fifteen. It finishes at five forty-five.",
        "objectives": "Tell the time and say when things start and finish.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "How do we say 7:30?", "seven thirty",
              ["seven thirty", "seven o'clock", "half seven past", "thirty seven"], 2, "comprehension"),
            q("MCQ", "How do we say 5:00?", "five o'clock",
              ["five o'clock", "five thirty", "five fifteen", "quarter five"], 1, "recognition"),
            q("MCQ", "Count by fives: 5, 15, 25, ___", "35",
              ["35", "30", "20", "40"], 2, "computation"),
            q("MCQ", "'The film ___ at eight o'clock.' Choose the best word.", "starts",
              ["starts", "start", "starting", "started"], 2, "production"),
            q("TRUE_FALSE", "5:15 is 'five fifteen'.", "True", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: The lesson ___ at nine o'clock and ends at ten.", "starts", None, 2, "production"),
            q("SHORT_ANSWER", "What time do you get up in the morning?", "seven o'clock", None, 2, "production"),
            q("ORDERING", "Put in order: at, starts, it, six",
              "it, starts, at, six", ["at", "starts", "it", "six"], 3, "application"),
            q("PRONUNCIATION", "o'clock", "o'clock", None, 2, "pronunciation"),
            q("READING", "The match starts at four thirty and finishes at five forty-five.",
              "The match starts at four thirty and finishes at five forty-five.", None, 2, "reading"),
        ],
    },
    {
        "title": "Good habits",
        "content": "Daily habits and frequency: wash my face, brush my teeth, clean my "
                   "shoes, go to bed, do my homework; always, sometimes, never.",
        "objectives": "Talk about daily habits and how often you do things.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "What do we use to brush our teeth?", "a toothbrush",
              ["a toothbrush", "a towel", "a spoon", "a comb"], 1, "recognition"),
            q("MCQ", "Which is a good habit before sleeping?", "brush my teeth",
              ["brush my teeth", "eat sweets", "watch TV all night", "skip washing"], 2, "comprehension"),
            q("MCQ", "'I ___ go to bed late.' (100% of the time) Choose the best word.", "always",
              ["always", "never", "sometimes", "not"], 2, "comprehension"),
            q("MCQ", "Which word means '0% of the time'?", "never",
              ["never", "always", "sometimes", "often"], 2, "recognition"),
            q("TRUE_FALSE", "Washing your face is a good habit.", "True", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: I ___ my homework every evening.", "do", None, 1, "production"),
            q("SHORT_ANSWER", "Write one good habit you have.", "I brush my teeth", None, 2, "production"),
            q("ORDERING", "Put in order: my, I, teeth, brush",
              "I, brush, my, teeth", ["my", "I", "teeth", "brush"], 3, "application"),
            q("PRONUNCIATION", "always", "always", None, 2, "pronunciation"),
            q("READING", "Every morning I wash my face, brush my teeth and clean my shoes.",
              "Every morning I wash my face, brush my teeth and clean my shoes.", None, 2, "reading"),
        ],
    },
    {
        "title": "Revision (Units 10-13)",
        "content": "Review of places in Palestine, cooking a cake, telling the time, "
                   "and good habits from Units 10-13.",
        "objectives": "Review the language of Units 10-13.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Which one is a place in Palestine?", "Akka",
              ["Akka", "flour", "oven", "always"], 1, "recognition"),
            q("MCQ", "Which one do we use in cooking?", "bowl",
              ["bowl", "Hebron", "never", "o'clock"], 1, "recognition"),
            q("MCQ", "How do we say 9:15?", "nine fifteen",
              ["nine fifteen", "nine o'clock", "fifteen nine", "quarter nine"], 2, "comprehension"),
            q("MCQ", "'She ___ brushes her teeth at night.' (a good habit) Choose the best word.", "always",
              ["always", "never", "isn't", "don't"], 2, "production"),
            q("TRUE_FALSE", "We bake a cake in the fridge.", "False", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: I'm going to ___ my grandmother on Friday.", "visit", None, 2, "production"),
            q("SHORT_ANSWER", "Write the time you go to school.", "eight o'clock", None, 2, "production"),
            q("ORDERING", "Put in order: add, then, the, sugar",
              "then, add, the, sugar", ["add", "then", "the", "sugar"], 3, "application"),
            q("PRONUNCIATION", "oven", "oven", None, 2, "pronunciation"),
            q("READING", "We are going to make a cake at three o'clock and eat it together.",
              "We are going to make a cake at three o'clock and eat it together.", None, 2, "reading"),
        ],
    },
    {
        "title": "I can do it!",
        "content": "Abilities: can / can't; play volleyball, ride a bike, play the piano, "
                   "drive a car, swim, make a cake.",
        "objectives": "Say what you can and can't do.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "'I ___ swim very well.' (I am able to) Choose the best word.", "can",
              ["can", "can't", "am", "do"], 1, "production"),
            q("MCQ", "Which activity do we do in water?", "swim",
              ["swim", "ride a bike", "play the piano", "drive a car"], 1, "recognition"),
            q("MCQ", "Who can drive a car?", "an adult with a licence",
              ["an adult with a licence", "a baby", "a fish", "a book"], 2, "comprehension"),
            q("MCQ", "'She ___ play the piano.' (she is not able to) Choose the best word.", "can't",
              ["can't", "can", "cans", "doesn't can"], 2, "production"),
            q("TRUE_FALSE", "We play volleyball with a ball and a net.", "True", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: Can you ride a ___? Yes, I can.", "bike", None, 1, "production"),
            q("SHORT_ANSWER", "Write one thing you can do well.", "I can swim", None, 2, "production"),
            q("ORDERING", "Put in order: can, I, a, bike, ride",
              "I, can, ride, a, bike", ["can", "I", "a", "bike", "ride"], 3, "application"),
            q("PRONUNCIATION", "volleyball", "volleyball", None, 2, "pronunciation"),
            q("READING", "I can swim and ride a bike, but I can't play the piano yet.",
              "I can swim and ride a bike, but I can't play the piano yet.", None, 2, "reading"),
        ],
    },
    {
        "title": "In my street",
        "content": "Shops and the past: baker's, butcher's, grocer's, book shop; "
                   "I went to the butcher's. I bought meat. opposite, on the right.",
        "objectives": "Name shops and say what you did in the past.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Where do we buy bread?", "the baker's",
              ["the baker's", "the butcher's", "the book shop", "the music shop"], 1, "recognition"),
            q("MCQ", "Where do we buy meat?", "the butcher's",
              ["the butcher's", "the baker's", "the grocer's", "the clothes shop"], 1, "recognition"),
            q("MCQ", "'Yesterday I ___ to the market.' Choose the best word.", "went",
              ["went", "go", "going", "goes"], 2, "production"),
            q("MCQ", "'I ___ some meat at the butcher's.' Choose the best word.", "bought",
              ["bought", "buy", "buys", "buying"], 2, "production"),
            q("TRUE_FALSE", "A greengrocer's sells fruit and vegetables.", "True", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: The book shop is ___ the baker's, across the street.", "opposite", None, 2, "production"),
            q("SHORT_ANSWER", "Write one shop in your street.", "grocer's", None, 2, "production"),
            q("ORDERING", "Put in order: I, bread, bought, the, baker's, at",
              "I, bought, bread, at, the, baker's",
              ["I", "bread", "bought", "the", "baker's", "at"], 3, "application"),
            q("PRONUNCIATION", "butcher", "butcher", None, 2, "pronunciation"),
            q("READING", "Yesterday I went to the grocer's on the right and bought rice and oil.",
              "Yesterday I went to the grocer's on the right and bought rice and oil.", None, 2, "reading"),
        ],
    },
    {
        "title": "On the farm",
        "content": "Farm animals and the past: horse, duck, cow, dog, sheep, hen, "
                   "donkey; collect, help, watch. I collected the eggs.",
        "objectives": "Name farm animals and describe past activities.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Which farm animal gives us milk?", "cow",
              ["cow", "hen", "duck", "dog"], 1, "recognition"),
            q("MCQ", "Which animal lays eggs on the farm?", "hen",
              ["hen", "sheep", "horse", "donkey"], 1, "recognition"),
            q("MCQ", "'Last week I ___ the eggs from the hens.' Choose the best word.", "collected",
              ["collected", "collect", "collecting", "collects"], 2, "production"),
            q("MCQ", "Which animal can carry heavy bags on the farm?", "donkey",
              ["donkey", "duck", "hen", "dog"], 2, "comprehension"),
            q("TRUE_FALSE", "We get wool from sheep.", "True", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: I ___ my uncle feed the animals yesterday.", "helped", None, 2, "production"),
            q("SHORT_ANSWER", "Write one animal you can see on a farm.", "cow", None, 2, "production"),
            q("ORDERING", "Put in order: I, the, watched, sheep",
              "I, watched, the, sheep", ["I", "the", "watched", "sheep"], 3, "application"),
            q("PRONUNCIATION", "donkey", "donkey", None, 2, "pronunciation"),
            q("READING", "On the farm I collected the eggs, helped my uncle and watched the sheep. It was great!",
              "On the farm I collected the eggs, helped my uncle and watched the sheep. It was great!", None, 2, "reading"),
        ],
    },
    {
        "title": "Revision (Units 15-17)",
        "content": "Review of abilities, shops in the street, and farm animals and past "
                   "actions from Units 15-17.",
        "objectives": "Review the language of Units 15-17.",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Which one is a farm animal?", "sheep",
              ["sheep", "baker", "piano", "shop"], 1, "recognition"),
            q("MCQ", "Which sentence talks about the past?", "I bought some bread.",
              ["I bought some bread.", "I can swim.", "I am going to visit Akka.", "I brush my teeth."], 2, "comprehension"),
            q("MCQ", "'They ___ play volleyball.' (they are able to) Choose the best word.", "can",
              ["can", "can't", "was", "did"], 2, "production"),
            q("MCQ", "At which shop can we buy meat and chicken?", "the butcher's",
              ["the butcher's", "the baker's", "the book shop", "the farm"], 1, "recognition"),
            q("TRUE_FALSE", "A hen gives us wool.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: Yesterday I ___ to the farm with my family.", "went", None, 2, "production"),
            q("SHORT_ANSWER", "Write one thing you can't do yet.", "drive a car", None, 2, "production"),
            q("ORDERING", "Put in order: eggs, I, the, collected",
              "I, collected, the, eggs", ["eggs", "I", "the", "collected"], 3, "application"),
            q("PRONUNCIATION", "horse", "horse", None, 2, "pronunciation"),
            q("READING", "I can ride a horse. Last weekend I went to the farm and helped my grandfather.",
              "I can ride a horse. Last weekend I went to the farm and helped my grandfather.", None, 2, "reading"),
        ],
    },
]


def main():
    write_curriculum(subject_code="en", grade=4, semester=2, lessons=L)


if __name__ == "__main__":
    main()

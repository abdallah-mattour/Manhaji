# -*- coding: utf-8 -*-
"""
Grade 3 English, semester 2 — authored from the real book
(PDFBooks/3Grade/English/en3-p2.pdf, *English for Palestine 3B*, Contents p3).

Nine units, exact book order and vocabulary:
  10 What's the time?    — days of the week; telling the time; meals; 1–12
  11 At the playground   — swings, roundabout, slide, sandpit, seesaw,
                           climbing frame; up/down/round/over/under
  12 Open Day            — dance dabka, draw pictures, play music, paint,
                           act in a play, show our work
  13 I'm wearing a scarf — clothes; purple, pink; present continuous
  14 Revision            — Units 10–13
  15 They're jumping!    — free-time actions; present continuous
  16 I'm Palestinian     — countries, capitals, nationalities, languages
  17 My favourite …      — sports; likes / dislikes; opinions
  18 Revision            — Units 15–17

English-only throughout. TRUE_FALSE answers are True / False.

Run:  python _build_grade3_en_p2.py   then _fairness_g34.py
"""
from __future__ import annotations

from _common import q, write_curriculum, omoji

L = [
    # ---------------------------------------------------------------- Unit 10
    {
        "title": "What's the time? (Unit 10)",
        "content": "We talk about the days of the week and say the time and "
                   "when things happen: breakfast, lunch, dinner; the numbers "
                   "one to twelve; It's six o'clock.",
        "objectives": "Days of the week and telling the time",
        "imageUrls": [omoji("clock")],
        "questions": [
            q("MCQ", "What day comes after Sunday?", "Monday",
              ["Monday", "Friday", "Saturday", "Sunday"], 1, "recognition"),
            q("MCQ", "Someone asks 'What's the time?'. Choose the answer.", "It's six o'clock",
              ["It's six o'clock", "It's Monday", "It's sunny", "I'm nine"], 1, "comprehension"),
            q("MCQ", "Which meal do we eat in the morning?", "breakfast",
              ["breakfast", "lunch", "dinner", "supper"], 1, "recognition"),
            q("TRUE_FALSE", "There are seven days in a week.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "We eat dinner in the early morning.", "False", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: When do you go to school? ___ seven o'clock. (At / In)", "At", None, 2, "production"),
            q("SHORT_ANSWER", "What number comes after eleven?", "twelve", None, 2, "production"),
            q("ORDERING", "Put the days in order: Tuesday, Sunday, Monday", "Sunday, Monday, Tuesday",
              ["Tuesday", "Sunday", "Monday"], 2, "application"),
            q("PRONUNCIATION", "Say: Wednesday", "Wednesday", None, 2, "pronunciation"),
            q("MCQ", "The day before Friday is:", "Thursday",
              ["Thursday", "Saturday", "Monday", "Sunday"], 2, "comprehension"),
            q("MCQ", "School starts at eight o'clock. It is now seven o'clock. Is it time for school?", "No, not yet",
              ["No, not yet", "Yes, now", "It's dinner time", "It's Monday"], 3, "application"),
            q("IMAGE_MCQ", "Which picture shows a clock?", "clock",
              ["clock", "book", "car", "apple"], 1, "recognition",
              option_images=[omoji("clock"), omoji("book"), omoji("car"), omoji("apple")]),
        ],
    },
    # ---------------------------------------------------------------- Unit 11
    {
        "title": "At the playground (Unit 11)",
        "content": "We talk about the playground and make suggestions: swings, "
                   "roundabout, slide, sandpit, seesaw, climbing frame; up, "
                   "down, round, over, under.",
        "objectives": "Talking about the playground and making suggestions",
        "imageUrls": [],
        "questions": [
            q("MCQ", "On which thing do you go up and down at the playground?", "the seesaw",
              ["the seesaw", "the book", "the market", "the school"], 1, "recognition"),
            q("MCQ", "You want to suggest playing on the swings. What do you say?", "Let's go on the swings",
              ["Let's go on the swings", "Goodbye", "How old are you?", "It's rainy"], 2, "comprehension"),
            q("MCQ", "Where do you play with sand?", "the sandpit",
              ["the sandpit", "the slide", "the swings", "the roundabout"], 1, "recognition"),
            q("TRUE_FALSE", "You can climb up a climbing frame.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "A slide goes up, not down.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: Let's go ___ the sandpit. (in / of)", "in", None, 2, "production"),
            q("SHORT_ANSWER", "What is the opposite of 'up'?", "down", None, 2, "production"),
            q("ORDERING", "Put in order to make a suggestion: on, let's, go, the slide", "let's, go, on, the slide",
              ["on", "let's", "go", "the slide"], 2, "application"),
            q("PRONUNCIATION", "Say: roundabout", "roundabout", None, 2, "pronunciation"),
            q("MCQ", "The cat is on the chair. Then it goes below the chair. Where is the cat now?", "under the chair",
              ["under the chair", "over the chair", "on the chair", "round the chair"], 3, "comprehension"),
            q("MCQ", "Which one goes round and round?", "the roundabout",
              ["the roundabout", "the slide", "the seesaw", "the sandpit"], 2, "recognition"),
            q("IMAGE_MCQ", "Which picture shows a ball to play with?", "ball",
              ["ball", "clock", "shoe", "book"], 1, "recognition",
              option_images=[omoji("soccer_ball"), omoji("clock"), omoji("shoe"), omoji("book")]),
        ],
    },
    # ---------------------------------------------------------------- Unit 12
    {
        "title": "Open Day (Unit 12)",
        "content": "We talk about our school Open Day and say what we do: "
                   "dance dabka, draw pictures, play music, paint, act in a "
                   "play, show our work.",
        "objectives": "Talking about school Open Day activities",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Which is a traditional Palestinian dance?", "dabka",
              ["dabka", "football", "homework", "breakfast"], 1, "recognition"),
            q("MCQ", "Someone asks 'What do you do at the Open Day?'. Choose an answer.", "We dance",
              ["We dance", "I'm nine", "It's sunny", "Goodbye"], 2, "comprehension"),
            q("MCQ", "What do you use to paint a picture?", "paint",
              ["paint", "a car", "a tooth", "a clock"], 1, "recognition"),
            q("TRUE_FALSE", "On Open Day we show our work to visitors.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "Playing music is not an Open Day activity.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: We ___ pictures at the Open Day. (draw / draws)", "draw", None, 2, "production"),
            q("SHORT_ANSWER", "What do we call a story we act on a stage?", "a play", None, 2, "production"),
            q("ORDERING", "Put in order to make a sentence: music, we, play", "we, play, music",
              ["music", "we", "play"], 2, "application"),
            q("PRONUNCIATION", "Say: act in a play", "act in a play", None, 2, "pronunciation"),
            q("MCQ", "You are good at drawing. Which activity is best for you?", "draw pictures",
              ["draw pictures", "play music", "dance dabka", "act in a play"], 3, "application"),
            q("MCQ", "Which activity uses your voice and body to tell a story on stage?", "act in a play",
              ["act in a play", "paint", "draw pictures", "show our work"], 2, "comprehension"),
            q("IMAGE_MCQ", "Which picture shows a drum for playing music?", "drum",
              ["drum", "book", "apple", "car"], 1, "recognition",
              option_images=[omoji("drum"), omoji("book"), omoji("apple"), omoji("car")]),
        ],
    },
    # ---------------------------------------------------------------- Unit 13
    {
        "title": "I'm wearing a scarf (Unit 13)",
        "content": "We talk about clothes and describe what we are wearing: "
                   "scarf, jacket, trousers, trainers, tracksuit, slippers; "
                   "purple, pink; I'm wearing trousers.",
        "objectives": "Talking about clothes and what you are wearing",
        "imageUrls": [omoji("scarf")],
        "questions": [
            q("MCQ", "What do you wear on your legs?", "trousers",
              ["trousers", "a scarf", "a hat", "gloves"], 1, "recognition"),
            q("MCQ", "What do you wear around your neck when it's cold?", "a scarf",
              ["a scarf", "trainers", "trousers", "slippers"], 1, "recognition"),
            q("MCQ", "Which shoes do you wear for sport?", "trainers",
              ["trainers", "slippers", "a jacket", "a scarf"], 2, "recognition"),
            q("TRUE_FALSE", "Pink and purple are colours.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "We wear slippers to play football.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: She ___ wearing a jacket. (is / are)", "is", None, 2, "production"),
            q("SHORT_ANSWER", "What do you wear on your feet inside the house?", "slippers", None, 2, "production"),
            q("ORDERING", "Put in order to make a sentence: a scarf, wearing, I'm", "I'm, wearing, a scarf",
              ["a scarf", "wearing", "I'm"], 2, "application"),
            q("PRONUNCIATION", "Say: tracksuit", "tracksuit", None, 2, "pronunciation"),
            q("MCQ", "He is going to a party. What is he wearing? He's wearing a:", "jacket",
              ["jacket", "sandpit", "roundabout", "playground"], 2, "comprehension"),
            q("MCQ", "It is cold and windy outside. What is best to wear?", "a jacket and a scarf",
              ["a jacket and a scarf", "slippers and a tracksuit", "only a shirt", "trainers only"], 3, "application"),
            q("IMAGE_MCQ", "Which picture shows a scarf?", "scarf",
              ["scarf", "shoe", "socks", "gloves"], 1, "recognition",
              option_images=[omoji("scarf"), omoji("shoe"), omoji("socks"), omoji("gloves")]),
        ],
    },
    # ---------------------------------------------------------------- Unit 14
    {
        "title": "Revision 3 (Units 10–13)",
        "content": "We revise the time and the days, the playground, Open Day "
                   "activities and clothes.",
        "objectives": "Revising the language of Units 10–13",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Choose the day of the week.", "Thursday",
              ["Thursday", "trousers", "swings", "dabka"], 1, "recognition"),
            q("MCQ", "Choose the clothes word.", "jacket",
              ["jacket", "Monday", "slide", "lunch"], 1, "recognition"),
            q("MCQ", "Choose the playground word.", "swings",
              ["swings", "scarf", "breakfast", "pink"], 1, "recognition"),
            q("TRUE_FALSE", "We dance dabka on Open Day.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "There are five days in a week.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: What's the ___? It's five o'clock. (time / day)", "time", None, 2, "production"),
            q("SHORT_ANSWER", "Name one thing you can find at the playground.", "slide", None, 2, "production"),
            q("ORDERING", "Put in order to make a suggestion: the swings, go, let's, on", "let's, go, on, the swings",
              ["the swings", "go", "let's", "on"], 3, "application"),
            q("PRONUNCIATION", "Say: What's the time?", "What's the time?", None, 2, "pronunciation"),
            q("MCQ", "It is Open Day and it is cold. You will dance and it is windy outside. What do you wear?",
              "a tracksuit and trainers",
              ["a tracksuit and trainers", "slippers", "only a scarf", "a swimming suit"], 3, "application"),
            q("IMAGE_MCQ", "Which picture shows a shoe?", "shoe",
              ["shoe", "clock", "book", "apple"], 1, "recognition",
              option_images=[omoji("shoe"), omoji("clock"), omoji("book"), omoji("apple")]),
        ],
    },
    # ---------------------------------------------------------------- Unit 15
    {
        "title": "They're jumping! (Unit 15)",
        "content": "We talk about what we do in our free time and describe "
                   "what we are doing now: run, jump, fly a kite, play the "
                   "drums, listen to music, play computer games.",
        "objectives": "Talking about free time; the present continuous",
        "imageUrls": [omoji("kite")],
        "questions": [
            q("MCQ", "What do you do with a kite?", "fly it",
              ["fly it", "eat it", "read it", "drink it"], 1, "comprehension"),
            q("MCQ", "Someone asks 'What are they doing?'. Choose the answer.", "They're running",
              ["They're running", "It's Monday", "I'm nine", "Good night"], 2, "comprehension"),
            q("MCQ", "Which action means to move fast on your feet?", "run",
              ["run", "listen", "read", "sleep"], 1, "recognition"),
            q("TRUE_FALSE", "We can listen to music in our free time.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "'They're jumping' talks about the past.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: He ___ playing the drums. (is / are)", "is", None, 2, "production"),
            q("SHORT_ANSWER", "What do you need wind for, to make it fly high?", "a kite", None, 2, "production"),
            q("ORDERING", "Put in order to make a sentence: is, jumping, she", "she, is, jumping",
              ["is", "jumping", "she"], 2, "application"),
            q("PRONUNCIATION", "Say: listen to music", "listen to music", None, 2, "pronunciation"),
            q("MCQ", "The children are on the grass moving up in the air again and again. What are they doing?",
              "jumping",
              ["jumping", "sleeping", "eating", "reading"], 3, "comprehension"),
            q("MCQ", "What are you doing now? Use the present continuous.", "I'm reading",
              ["I'm reading", "I read yesterday", "I will read", "I read every day"], 3, "application"),
            q("IMAGE_MCQ", "Which picture shows a kite?", "kite",
              ["kite", "clock", "shoe", "book"], 1, "recognition",
              option_images=[omoji("kite"), omoji("clock"), omoji("shoe"), omoji("book")]),
        ],
    },
    # ---------------------------------------------------------------- Unit 16
    {
        "title": "I'm Palestinian (Unit 16)",
        "content": "We talk about where we are from and say what languages we "
                   "speak: Palestine, Britain, Jordan, Egypt, the United "
                   "States, Australia; Palestinian, British; Arabic, English.",
        "objectives": "Talking about countries, nationalities and languages",
        "imageUrls": [omoji("globe")],
        "questions": [
            q("MCQ", "Someone from Palestine is:", "Palestinian",
              ["Palestinian", "British", "Egyptian", "Australian"], 1, "recognition"),
            q("MCQ", "What is the capital city of Britain?", "London",
              ["London", "Cairo", "Amman", "Jerusalem"], 2, "recognition"),
            q("MCQ", "Which language do we speak in Palestine?", "Arabic",
              ["Arabic", "French", "German", "Spanish"], 1, "recognition"),
            q("TRUE_FALSE", "Egypt is a country.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "A person from Britain is called Egyptian.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: I'm from Palestine. I'm ___. (Palestinian / Palestine)", "Palestinian", None, 2, "production"),
            q("SHORT_ANSWER", "What is the capital city of Palestine?", "Jerusalem", None, 2, "production"),
            q("ORDERING", "Put in order to make a sentence: Palestinian, I'm, proud", "I'm, proud, Palestinian",
              ["Palestinian", "I'm", "proud"], 2, "application"),
            q("PRONUNCIATION", "Say: I'm Palestinian", "I'm Palestinian", None, 1, "pronunciation"),
            q("MCQ", "A person from Britain speaks English and is called:", "British",
              ["British", "Palestinian", "Jordanian", "Australian"], 2, "comprehension"),
            q("MCQ", "Your friend is from Amman. Which country is your friend from?", "Jordan",
              ["Jordan", "Egypt", "Australia", "Britain"], 3, "application"),
            q("IMAGE_MCQ", "Which picture shows the world (a globe)?", "globe",
              ["globe", "clock", "book", "car"], 1, "recognition",
              option_images=[omoji("globe"), omoji("clock"), omoji("book"), omoji("car")]),
        ],
    },
    # ---------------------------------------------------------------- Unit 17
    {
        "title": "My favourite … (Unit 17)",
        "content": "We describe sports and express likes and dislikes: "
                   "basketball, volleyball, table tennis; My favourite sport "
                   "is …; It's fun / boring / easy / difficult / great.",
        "objectives": "Describing sports and expressing likes and dislikes",
        "imageUrls": [omoji("basketball")],
        "questions": [
            q("MCQ", "Which sport do you play with a small ball and a small bat on a table?", "table tennis",
              ["table tennis", "basketball", "volleyball", "football"], 2, "recognition"),
            q("MCQ", "Someone asks 'What's your favourite sport?'. Choose an answer.", "My favourite sport is football",
              ["My favourite sport is football", "It's Monday", "I'm nine", "It's rainy"], 1, "comprehension"),
            q("MCQ", "Which word means the opposite of 'easy'?", "difficult",
              ["difficult", "great", "fun", "nice"], 2, "recognition"),
            q("TRUE_FALSE", "Basketball is a sport.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "'Boring' means something is very interesting.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: Do you like basketball? Yes, I ___ it. (like / likes)", "like", None, 2, "production"),
            q("SHORT_ANSWER", "Name one sport you play with a ball and a net over it.", "volleyball", None, 2, "production"),
            q("ORDERING", "Put in order to make a sentence: sport, my, is, favourite, football",
              "my, favourite, sport, is, football",
              ["sport", "my", "is", "favourite", "football"], 3, "application"),
            q("PRONUNCIATION", "Say: My favourite sport", "My favourite sport", None, 2, "pronunciation"),
            q("MCQ", "You think a game is very good and you enjoy it a lot. You say it's:", "great",
              ["great", "boring", "difficult", "bad"], 2, "comprehension"),
            q("MCQ", "You like football but you don't like table tennis. What is your favourite sport?", "football",
              ["football", "table tennis", "both", "none"], 3, "application"),
            q("IMAGE_MCQ", "Which picture shows a basketball?", "basketball",
              ["basketball", "book", "apple", "clock"], 1, "recognition",
              option_images=[omoji("basketball"), omoji("book"), omoji("apple"), omoji("clock")]),
        ],
    },
    # ---------------------------------------------------------------- Unit 18
    {
        "title": "Revision 4 (Units 15–17)",
        "content": "We revise free-time actions, countries and nationalities, "
                   "and sports with likes and dislikes.",
        "objectives": "Revising the language of Units 15–17",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Choose the free-time action.", "fly a kite",
              ["fly a kite", "London", "volleyball", "Jordan"], 1, "recognition"),
            q("MCQ", "Choose the country.", "Egypt",
              ["Egypt", "running", "basketball", "great"], 1, "recognition"),
            q("MCQ", "Choose the sport.", "volleyball",
              ["volleyball", "Australia", "jumping", "British"], 1, "recognition"),
            q("TRUE_FALSE", "We speak Arabic in Palestine.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "'They're running' means they ran last year.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: They ___ listening to music. (are / is)", "are", None, 2, "production"),
            q("SHORT_ANSWER", "What is your favourite sport?", "My favourite sport is ...", None, 2, "production"),
            q("ORDERING", "Put in order to make a question: doing, are, what, they", "what, are, they, doing",
              ["doing", "are", "what", "they"], 3, "application"),
            q("PRONUNCIATION", "Say: What are they doing?", "What are they doing?", None, 2, "pronunciation"),
            q("MCQ", "Rami is from Palestine and loves basketball; he finds it great. Which is true?",
              "Rami is Palestinian and likes basketball",
              ["Rami is Palestinian and likes basketball", "Rami is British", "Rami hates sport", "Rami is from Egypt"], 3, "comprehension"),
            q("IMAGE_MCQ", "Which picture shows a ball?", "ball",
              ["ball", "clock", "book", "car"], 1, "recognition",
              option_images=[omoji("soccer_ball"), omoji("clock"), omoji("book"), omoji("car")]),
        ],
    },
]

for i, lesson in enumerate(L, start=1):
    lesson["orderIndex"] = i


def main() -> None:
    write_curriculum(subject_code="en", grade=3, semester=2, lessons=L)


if __name__ == "__main__":
    main()

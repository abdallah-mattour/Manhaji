# -*- coding: utf-8 -*-
"""
Grade 3 English, semester 1 — authored from the real book
(PDFBooks/3Grade/English/en3-p1.pdf, *English for Palestine 3A*, Contents p3).

Nine units, exact book order and vocabulary:
  1 All about me       — greetings; name, age, where from
  2 He's a doctor      — jobs; family members
  3 At the market      — food; like / don't like
  4 At the zoo         — animals; colours, numbers 6–10
  5 Revision           — Units 1–4
  6 I don't feel well  — body parts / ailments; advice
  7 My day             — daily routine; times of day
  8 It's sunny         — weather; places
  9 Revision           — Units 1–8

Every prompt, option and answer is English-only (product requirement: the
English subject must contain no Arabic). TRUE_FALSE answers are True / False.

Run:  python _build_grade3_en_p1.py   then _fairness_g34.py
"""
from __future__ import annotations

from _common import q, write_curriculum, omoji

L = [
    # ---------------------------------------------------------------- Unit 1
    {
        "title": "All about me (Unit 1)",
        "content": "We greet people and give information about ourselves: our "
                   "name, our age and where we are from.",
        "objectives": "Greeting people and giving personal information",
        "imageUrls": [omoji("boy")],
        "questions": [
            q("MCQ", "How do you greet someone in the morning?", "Good morning",
              ["Good morning", "Good night", "Goodbye", "Thank you"], 1, "recognition"),
            q("MCQ", "Someone asks 'How are you?'. What do you say?", "Fine, thanks",
              ["Fine, thanks", "My name is Sara", "I am nine", "Goodbye"], 1, "comprehension"),
            q("MCQ", "How do you ask about someone's age?", "How old are you?",
              ["How old are you?", "What's your name?", "Where are you from?", "How are you?"], 2, "comprehension"),
            q("TRUE_FALSE", "'Good afternoon' is a greeting.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "We say 'Goodbye' when we meet someone for the first time.", "False", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: My name ___ Walid. (is / are)", "is", None, 1, "production"),
            q("SHORT_ANSWER", "Answer: What is your name?", "My name is ...", None, 1, "production"),
            q("ORDERING", "Put in order to make a question: are, how, you", "how, are, you",
              ["are", "how", "you"], 2, "application"),
            q("PRONUNCIATION", "Say: Good morning", "Good morning", None, 1, "pronunciation"),
            q("PRONUNCIATION", "Say: How are you?", "How are you?", None, 2, "pronunciation"),
            q("MCQ", "Walid is from Bethlehem. Where is Walid from?", "Bethlehem",
              ["Bethlehem", "Haifa", "Gaza", "Nablus"], 2, "comprehension"),
            q("MCQ", "You want to know where a new friend lives. What do you ask?", "Where are you from?",
              ["Where are you from?", "How old are you?", "What is this?", "How are you?"], 3, "application"),
        ],
    },
    # ---------------------------------------------------------------- Unit 2
    {
        "title": "He's a doctor (Unit 2)",
        "content": "We talk about jobs and say what members of our family do: "
                   "doctor, nurse, police officer, teacher, dentist, farmer, driver.",
        "objectives": "Talking about jobs and family members",
        "imageUrls": [],
        "questions": [
            q("MCQ", "A person who helps sick people at the hospital is a:", "doctor",
              ["doctor", "farmer", "driver", "teacher"], 1, "recognition"),
            q("MCQ", "A person who teaches children at school is a:", "teacher",
              ["teacher", "nurse", "farmer", "dentist"], 1, "recognition"),
            q("MCQ", "A person who takes care of your teeth is a:", "dentist",
              ["dentist", "doctor", "driver", "farmer"], 2, "recognition"),
            q("TRUE_FALSE", "A farmer works on the land and grows food.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "A driver teaches maths at school.", "False", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: What's his job? He's ___ nurse. (a / an)", "a", None, 2, "production"),
            q("SHORT_ANSWER", "What do we call the brother of your father?", "uncle", None, 2, "production"),
            q("ORDERING", "Put in order to make a question: his, what's, job", "what's, his, job",
              ["his", "what's", "job"], 2, "application"),
            q("PRONUNCIATION", "Say: police officer", "police officer", None, 2, "pronunciation"),
            q("MCQ", "Who's she? She's my grandmother. Who are we talking about?", "father's mother",
              ["father's mother", "father's brother", "my teacher", "my friend"], 3, "comprehension"),
            q("MCQ", "The sister of your mother is your:", "aunt",
              ["aunt", "uncle", "grandmother", "cousin"], 2, "recognition"),
            q("IMAGE_MCQ", "Which picture shows a family?", "family",
              ["family", "car", "book", "apple"], 1, "recognition",
              option_images=[omoji("family"), omoji("car"), omoji("book"), omoji("apple")]),
        ],
    },
    # ---------------------------------------------------------------- Unit 3
    {
        "title": "At the market (Unit 3)",
        "content": "We buy food at the market and say what we like and don't "
                   "like: apples, figs, onions, melon, oranges, carrots, "
                   "tomatoes, bananas, grapes, potatoes.",
        "objectives": "Buying food and saying what food you like",
        "imageUrls": [omoji("apple")],
        "questions": [
            q("MCQ", "Which of these is a fruit?", "banana",
              ["banana", "onion", "carrot", "potato"], 1, "recognition"),
            q("MCQ", "Which of these is a vegetable?", "carrot",
              ["carrot", "apple", "banana", "grapes"], 1, "recognition"),
            q("MCQ", "At the market you want to buy something. What do you say?", "I'd like figs, please",
              ["I'd like figs, please", "Goodbye", "How old are you?", "I am fine"], 2, "comprehension"),
            q("TRUE_FALSE", "Oranges are a kind of fruit.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "We pay money when we buy food at the market.", "True", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: I ___ carrots. (don't like / likes)", "don't like", None, 2, "production"),
            q("SHORT_ANSWER", "The seller gives you the food and says 'Here you are.' What do you say?", "Thank you", None, 2, "production"),
            q("ORDERING", "Put in order to make a sentence: like, grapes, I", "I, like, grapes",
              ["like", "grapes", "I"], 2, "application"),
            q("PRONUNCIATION", "Say: tomatoes", "tomatoes", None, 2, "pronunciation"),
            q("MCQ", "The apples cost 10 dinars. How much do they cost?", "10 dinars",
              ["10 dinars", "5 dinars", "20 dinars", "1 dinar"], 2, "comprehension"),
            q("IMAGE_MCQ", "Which picture shows grapes?", "grapes",
              ["grapes", "carrot", "potato", "lemon"], 1, "recognition",
              option_images=[omoji("grapes"), omoji("carrot"), omoji("potato"), omoji("lemon")]),
            q("MCQ", "You like bananas but you don't like onions. What do you buy?", "bananas",
              ["bananas", "onions", "both", "nothing"], 3, "application"),
        ],
    },
    # ---------------------------------------------------------------- Unit 4
    {
        "title": "At the zoo (Unit 4)",
        "content": "We talk about animals and describe them with colours and "
                   "other words: tiger, fox, giraffe, elephant, snake, monkey; "
                   "grey, brown, orange; the numbers six to ten.",
        "objectives": "Talking about animals; colours and numbers 6–10",
        "imageUrls": [omoji("elephant")],
        "questions": [
            q("MCQ", "Which animal is very big and grey and has a long trunk?", "elephant",
              ["elephant", "monkey", "snake", "fox"], 1, "recognition"),
            q("MCQ", "Which animal has no legs?", "snake",
              ["snake", "tiger", "giraffe", "monkey"], 2, "comprehension"),
            q("MCQ", "Which animal has a very long neck?", "giraffe",
              ["giraffe", "snake", "fox", "monkey"], 1, "recognition"),
            q("TRUE_FALSE", "A monkey can climb trees.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "An elephant is a small animal.", "False", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete the numbers: six, seven, eight, ___", "nine", None, 1, "production"),
            q("SHORT_ANSWER", "What colour is a banana?", "yellow", None, 2, "production"),
            q("ORDERING", "Put the numbers in order: ten, six, eight", "six, eight, ten",
              ["ten", "six", "eight"], 2, "application"),
            q("PRONUNCIATION", "Say: giraffe", "giraffe", None, 2, "pronunciation"),
            q("MCQ", "The number that comes after nine is:", "ten",
              ["ten", "eight", "seven", "six"], 1, "recognition"),
            q("IMAGE_MCQ", "Which picture shows a monkey?", "monkey",
              ["monkey", "elephant", "lion", "bear"], 1, "recognition",
              option_images=[omoji("monkey"), omoji("elephant"), omoji("lion"), omoji("bear")]),
            q("MCQ", "A tiger is orange with black lines. What colour is a tiger?", "orange",
              ["orange", "grey", "blue", "green"], 3, "comprehension"),
        ],
    },
    # ---------------------------------------------------------------- Unit 5
    {
        "title": "Revision 1 (Units 1–4)",
        "content": "We revise greetings and personal information, jobs and "
                   "family, food, and animals with colours and numbers.",
        "objectives": "Revising the language of Units 1–4",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Choose the greeting.", "Good afternoon",
              ["Good afternoon", "elephant", "carrot", "nine"], 1, "recognition"),
            q("MCQ", "Choose the job.", "nurse",
              ["nurse", "banana", "snake", "brown"], 1, "recognition"),
            q("MCQ", "Choose the food.", "melon",
              ["melon", "teacher", "giraffe", "grey"], 1, "recognition"),
            q("TRUE_FALSE", "A doctor helps sick people.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "The number after seven is nine.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: How ___ are you? I'm nine. (old / many)", "old", None, 2, "production"),
            q("SHORT_ANSWER", "Name one animal you can see at the zoo.", "monkey", None, 2, "production"),
            q("ORDERING", "Put in order: from, you, are, where", "where, are, you, from",
              ["from", "you", "are", "where"], 3, "application"),
            q("PRONUNCIATION", "Say: Good morning, children", "Good morning, children", None, 2, "pronunciation"),
            q("MCQ", "Sami likes apples. Rana doesn't like apples. Who likes apples?", "Sami",
              ["Sami", "Rana", "both", "nobody"], 3, "comprehension"),
            q("IMAGE_MCQ", "Which picture shows an apple?", "apple",
              ["apple", "car", "book", "elephant"], 1, "recognition",
              option_images=[omoji("apple"), omoji("car"), omoji("book"), omoji("elephant")]),
        ],
    },
    # ---------------------------------------------------------------- Unit 6
    {
        "title": "I don't feel well (Unit 6)",
        "content": "We say what is wrong with us and give and understand "
                   "advice: stomach, head, back, foot/feet, tooth/teeth; "
                   "Go to the doctor. Go to bed. Take this medicine.",
        "objectives": "Saying what is wrong and giving advice",
        "imageUrls": [omoji("tooth")],
        "questions": [
            q("MCQ", "You have a problem with your tooth. Where do you go?", "the dentist",
              ["the dentist", "the market", "the zoo", "the beach"], 1, "comprehension"),
            q("MCQ", "Someone asks 'What's the matter?'. What can you say?", "My head hurts",
              ["My head hurts", "I'm nine", "Good morning", "It's sunny"], 2, "comprehension"),
            q("MCQ", "The plural of 'foot' is:", "feet",
              ["feet", "foots", "feets", "foot"], 2, "recognition"),
            q("TRUE_FALSE", "When you don't feel well, you can go to the doctor.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "'Have a rest' is a kind of advice.", "True", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: My teeth ___. (hurt / hurts)", "hurt", None, 2, "production"),
            q("SHORT_ANSWER", "Which part of your body do you think with?", "head", None, 2, "production"),
            q("ORDERING", "Put in order to give advice: to, go, bed", "go, to, bed",
              ["to", "go", "bed"], 2, "application"),
            q("PRONUNCIATION", "Say: stomach", "stomach", None, 2, "pronunciation"),
            q("MCQ", "The plural of 'tooth' is:", "teeth",
              ["teeth", "tooths", "toothes", "tooth"], 3, "recognition"),
            q("IMAGE_MCQ", "Which picture shows a foot?", "foot",
              ["foot", "hand", "eye", "nose"], 1, "recognition",
              option_images=[omoji("foot"), omoji("hand"), omoji("eye"), omoji("nose")]),
            q("MCQ", "Your friend's stomach hurts. What advice do you give?", "Go to the doctor",
              ["Go to the doctor", "Play football", "Eat more sweets", "Run fast"], 3, "application"),
        ],
    },
    # ---------------------------------------------------------------- Unit 7
    {
        "title": "My day (Unit 7)",
        "content": "We talk about our daily routine and say when we do things: "
                   "I get up, I go to school, I do homework, I go to bed; in "
                   "the morning, in the afternoon, in the evening, at night.",
        "objectives": "Talking about your daily routine and times of day",
        "imageUrls": [omoji("sun")],
        "questions": [
            q("MCQ", "What do you do first in the morning?", "I get up",
              ["I get up", "I go to bed", "I do homework", "I watch cartoons"], 1, "comprehension"),
            q("MCQ", "When do you sleep?", "at night",
              ["at night", "in the morning", "in the afternoon", "at school"], 1, "comprehension"),
            q("MCQ", "Where do you go to learn?", "to school",
              ["to school", "to bed", "to the zoo", "to the market"], 1, "recognition"),
            q("TRUE_FALSE", "We do homework after school.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "We get up at night and go to bed in the morning.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: I ___ up in the morning. (get / go)", "get", None, 2, "production"),
            q("SHORT_ANSWER", "What do you call the time after the morning and before the evening?", "afternoon", None, 2, "production"),
            q("ORDERING", "Put the day in order: go to school, get up, go to bed",
              "get up, go to school, go to bed",
              ["go to school", "get up", "go to bed"], 2, "application"),
            q("PRONUNCIATION", "Say: in the evening", "in the evening", None, 2, "pronunciation"),
            q("MCQ", "Someone asks 'When do you get up?'. Choose a good answer.", "In the morning",
              ["In the morning", "At school", "A doctor", "An elephant"], 2, "comprehension"),
            q("MCQ", "You finish school, then you play, then you do homework. What do you do last?", "do homework",
              ["do homework", "play", "go to school", "get up"], 3, "application"),
            q("IMAGE_MCQ", "Which picture shows the sun?", "sun",
              ["sun", "moon", "rain", "cloud"], 1, "recognition",
              option_images=[omoji("sun"), omoji("moon"), omoji("rain"), omoji("cloud")]),
        ],
    },
    # ---------------------------------------------------------------- Unit 8
    {
        "title": "It's sunny (Unit 8)",
        "content": "We talk about the weather and say where people are: rainy, "
                   "windy, sunny, cloudy, hot, cold; swimming pool, beach, "
                   "park, zoo, playground, river.",
        "objectives": "Talking about the weather and places",
        "imageUrls": [omoji("rainbow")],
        "questions": [
            q("MCQ", "The sun is shining. What's the weather like?", "It's sunny",
              ["It's sunny", "It's rainy", "It's snowy", "It's cloudy"], 1, "comprehension"),
            q("MCQ", "It is raining. What's the weather like?", "It's rainy",
              ["It's rainy", "It's sunny", "It's hot", "It's windy"], 1, "comprehension"),
            q("MCQ", "Where do you go to swim?", "the swimming pool",
              ["the swimming pool", "the school", "the market", "the zoo"], 2, "recognition"),
            q("TRUE_FALSE", "In summer the weather is often hot.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "When it's cold we usually wear light summer clothes.", "False", None, 2, "comprehension"),
            q("FILL_BLANK", "Complete: What's the ___? It's windy. (weather / time)", "weather", None, 2, "production"),
            q("SHORT_ANSWER", "Where can you play games outside with other children?", "playground", None, 2, "production"),
            q("ORDERING", "Put in order to make a sentence: at, the, we're, beach", "we're, at, the, beach",
              ["at", "the", "we're", "beach"], 2, "application"),
            q("PRONUNCIATION", "Say: It's cloudy", "It's cloudy", None, 2, "pronunciation"),
            q("MCQ", "There is a lot of wind today. What's the weather like?", "It's windy",
              ["It's windy", "It's sunny", "It's hot", "It's rainy"], 2, "comprehension"),
            q("IMAGE_MCQ", "Which picture shows rain?", "rain",
              ["rain", "sun", "star", "snowflake"], 1, "recognition",
              option_images=[omoji("rain"), omoji("sun"), omoji("star"), omoji("snowflake")]),
            q("MCQ", "It's hot and sunny. Which place is best to cool down?", "the swimming pool",
              ["the swimming pool", "the playground", "the school", "the market"], 3, "application"),
        ],
    },
    # ---------------------------------------------------------------- Unit 9
    {
        "title": "Revision 2 (Units 1–8)",
        "content": "We revise the language of the first semester: greetings, "
                   "jobs, food, animals, the body and advice, daily routine "
                   "and the weather.",
        "objectives": "Revising the language of Units 1–8",
        "imageUrls": [],
        "questions": [
            q("MCQ", "Choose the weather word.", "cloudy",
              ["cloudy", "dentist", "banana", "monkey"], 1, "recognition"),
            q("MCQ", "Choose the part of the body.", "back",
              ["back", "river", "farmer", "grey"], 1, "recognition"),
            q("MCQ", "Choose the place.", "beach",
              ["beach", "nurse", "tomato", "seven"], 1, "recognition"),
            q("TRUE_FALSE", "We go to bed at night.", "True", None, 1, "comprehension"),
            q("TRUE_FALSE", "A giraffe is a kind of food.", "False", None, 1, "comprehension"),
            q("FILL_BLANK", "Complete: It ___ sunny today. (is / are)", "is", None, 2, "production"),
            q("SHORT_ANSWER", "Name one job.", "teacher", None, 2, "production"),
            q("ORDERING", "Put in order: the, matter, what's", "what's, the, matter",
              ["the", "matter", "what's"], 3, "application"),
            q("PRONUNCIATION", "Say: What's the weather like?", "What's the weather like?", None, 2, "pronunciation"),
            q("MCQ", "It's cold and your head hurts. What do you do?", "Go to bed and have a rest",
              ["Go to bed and have a rest", "Go swimming", "Play in the rain", "Run outside"], 3, "application"),
            q("IMAGE_MCQ", "Which picture shows a hand?", "hand",
              ["hand", "foot", "eye", "ear"], 1, "recognition",
              option_images=[omoji("hand"), omoji("foot"), omoji("eye"), omoji("ear")]),
        ],
    },
]

for i, lesson in enumerate(L, start=1):
    lesson["orderIndex"] = i


def main() -> None:
    write_curriculum(subject_code="en", grade=3, semester=1, lessons=L)


if __name__ == "__main__":
    main()

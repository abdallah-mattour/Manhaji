# -*- coding: utf-8 -*-
"""
English — Grade 1 — Semester 1 (2026-07-04 book-alignment rebuild).

Mirrors the REAL *English for Palestine — Pupil's Book 1A* unit structure,
extracted from PDFBooks/1Grade/English/en1-p1.pdf (Contents, page 3):

  1  Hello!        hello, hi, goodbye, bye, good morning, good afternoon
                   What's your name? My name's Tala.
  2  Let's eat!    nut, olive, melon, date, egg, bread, cheese · numbers 1-3
  3  Animals       insect, goat, rabbit, cat, kitten, lion, zebra, dog · 4-6
  4  My body       head, hand, finger, leg, face, nose, mouth · 7-10
  5  Revision      Units 1-4
  6  My classroom  board, teacher, pencil, book, bag, desk · What's this?
  7  My family     Mum, Dad, sister, brother, baby, me · Who's this?
  8  Let's drink!  water, milk, tea, coffee, apple juice, orange juice
  9  Revision      Units 6-8
  (+ the book's alphabet appendix → the four existing alphabet lessons are
   kept, appended after the units at orderIndex 10-13 by build_grade1_en.py)

Every question uses only the unit's own book vocabulary and language
patterns. Media questions reference bundled OpenMoji assets.
"""
from __future__ import annotations

from _common import q, omoji, write_curriculum


def _match(left, right):
    out_l = [{"id": str(i + 1), **({"text": t} if t else {}), **({"image": img} if img else {})}
             for i, (t, img) in enumerate(left)]
    out_r = [{"id": chr(ord("a") + i), **({"text": t} if t else {}), **({"image": img} if img else {})}
             for i, (t, img) in enumerate(right)]
    return {"left": out_l, "right": out_r}


def _ans(n):
    return ",".join(f"{i + 1}={chr(ord('a') + i)}" for i in range(n))


U1 = {
    "title": "Hello! (Unit 1)",
    "orderIndex": 1,
    "content": "Greeting people and saying your name: hello, hi, goodbye, bye, "
               "good morning, good afternoon. What's your name? My name's Tala.",
    "objectives": "Greet people and introduce yourself",
    "imageUrls": [omoji("sun")],
    "questions": [
        q("MCQ", "What do you say when you meet your teacher in the morning?",
          "Good morning", ["Good morning", "Goodbye", "Good afternoon", "Bye"], 1, "recognition"),
        q("MCQ", "Tala meets a new friend. What does she ask?",
          "What's your name?", ["What's your name?", "Goodbye!", "Good afternoon.", "Bye bye!"], 2, "comprehension"),
        q("MCQ", "What do you say when you leave school?",
          "Goodbye", ["Goodbye", "Hello", "Good morning", "Hi"], 1, "recognition"),
        q("TRUE_FALSE", "We say 'good afternoon' after lunch time.", "True", None, 2, "comprehension"),
        q("TRUE_FALSE", "'Hi' is a way to greet a friend.", "True", None, 1, "comprehension"),
        q("FILL_BLANK", "Complete: What's your ___? My name's Tala.", "name", None, 1, "production"),
        q("FILL_BLANK", "Complete: My ___ is Omar.", "name", None, 2, "production"),
        q("SHORT_ANSWER", "Write the short greeting we use with friends (two letters).", "Hi", None, 2, "production"),
        q("ORDERING", "Put the words in order: name's / My / Tala", "My, name's, Tala",
          ["name's", "My", "Tala"], 3, "application"),
        q("PRONUNCIATION", "Hello", "Hello", None, 1, "pronunciation"),
        q("PRONUNCIATION", "Good morning", "Good morning", None, 2, "pronunciation"),
        q("LISTEN_CHOOSE", "Goodbye", "Goodbye",
          ["Hello", "Goodbye", "Hi", "Good morning"], 1, "recognition"),
        q("READING", "Hello, my name's Tala", "Hello, my name's Tala", None, 2, "reading"),
    ],
}

U2 = {
    "title": "Let's eat! (Unit 2)",
    "orderIndex": 2,
    "content": "Food words: nut, olive, melon, date, egg, bread, cheese. "
               "Counting 1, 2, 3.",
    "objectives": "Name foods and count 1-3",
    "imageUrls": [omoji("bread")],
    "questions": [
        q("MCQ", "Which of these foods grows on a tree in Palestine?",
          "Olive", ["Olive", "Egg", "Bread", "Cheese"], 2, "comprehension"),
        q("MCQ", "Which food do we get from a chicken?",
          "Egg", ["Egg", "Melon", "Nut", "Date"], 1, "recognition"),
        q("TRUE_FALSE", "Bread is a food we can eat.", "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "Three comes after two when we count.", "True", None, 1, "comprehension"),
        q("FILL_BLANK", "Count: one, two, ___.", "three", None, 1, "production"),
        q("FILL_BLANK", "Complete: I eat ___ and cheese.", "bread", None, 2, "production"),
        q("SHORT_ANSWER", "Write the number that comes before two.", "one", None, 2, "production"),
        q("ORDERING", "Put the numbers in order: three / one / two", "one, two, three",
          ["three", "one", "two"], 2, "application"),
        q("IMAGE_MCQ", "Which picture shows the olive?", "Olive",
          ["Olive", "Egg", "Bread", "Cheese"], 1, "recognition",
          option_images=[omoji("olive"), omoji("egg"), omoji("bread"), omoji("cheese")]),
        q("IMAGE_MATCH", "Match the food words to their pictures", _ans(3), None, 2, "recognition",
          pairs=_match([("Melon", None), ("Egg", None), ("Cheese", None)],
                       [("", omoji("watermelon")), ("", omoji("egg")), ("", omoji("cheese"))])),
        q("PRONUNCIATION", "Cheese", "Cheese", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "Bread", "Bread",
          ["Olive", "Bread", "Egg", "Melon"], 1, "recognition",
          option_images=[omoji("olive"), omoji("bread"), omoji("egg"), omoji("watermelon")]),
        q("MCQ", "You have one nut and take one more nut. How many nuts now?",
          "Two", ["Two", "One", "Three", "None"], 3, "application"),
    ],
}

U3 = {
    "title": "Animals (Unit 3)",
    "orderIndex": 3,
    "content": "Animal words: insect, goat, rabbit, cat, kitten, lion, zebra, dog. "
               "Counting 4, 5, 6.",
    "objectives": "Name animals and count 4-6",
    "imageUrls": [omoji("rabbit")],
    "questions": [
        q("MCQ", "A kitten is a baby ...", "Cat",
          ["Cat", "Dog", "Goat", "Lion"], 2, "comprehension"),
        q("MCQ", "Which animal has black and white stripes?",
          "Zebra", ["Zebra", "Rabbit", "Cat", "Goat"], 1, "recognition"),
        q("TRUE_FALSE", "A lion is a big animal.", "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "Six comes before five when we count.", "False", None, 2, "comprehension"),
        q("FILL_BLANK", "Count: four, five, ___.", "six", None, 1, "production"),
        q("FILL_BLANK", "Complete: The ___ says woof.", "dog", None, 1, "production"),
        q("SHORT_ANSWER", "Write the name of a very small animal from this unit.", "insect", None, 2, "production"),
        q("ORDERING", "Put the numbers in order: six / four / five", "four, five, six",
          ["six", "four", "five"], 2, "application"),
        q("IMAGE_MCQ", "Find the goat!", "Goat",
          ["Goat", "Rabbit", "Lion", "Dog"], 1, "recognition",
          option_images=[omoji("goat"), omoji("rabbit"), omoji("lion"), omoji("dog")]),
        q("DRAG_DROP", "Sort the animals: big or small?",
          "Big=Lion,Big=Zebra,Small=Insect,Small=Kitten", None, 2, "application",
          pairs={"targets": ["Big", "Small"], "tokens": ["Lion", "Insect", "Zebra", "Kitten"]}),
        q("PRONUNCIATION", "Rabbit", "Rabbit", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "Cat", "Cat",
          ["Dog", "Cat", "Goat", "Rabbit"], 1, "recognition",
          option_images=[omoji("dog"), omoji("cat"), omoji("goat"), omoji("rabbit")]),
        q("MCQ", "You see four rabbits and two more come. How many rabbits?",
          "Six", ["Six", "Four", "Five", "Two"], 3, "application"),
    ],
}

U4 = {
    "title": "My body (Unit 4)",
    "orderIndex": 4,
    "content": "Body words: head, hand, finger, leg, face, nose, mouth. "
               "Counting 7, 8, 9, 10.",
    "objectives": "Name parts of the body and count 7-10",
    "imageUrls": [omoji("hand")],
    "questions": [
        q("MCQ", "What is on your face between your eyes and your mouth?",
          "Nose", ["Nose", "Leg", "Hand", "Finger"], 1, "recognition"),
        q("MCQ", "How many fingers are on one hand?",
          "Five", ["Five", "Seven", "Ten", "Nine"], 2, "comprehension"),
        q("TRUE_FALSE", "We walk with our legs.", "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "Ten comes after nine when we count.", "True", None, 1, "comprehension"),
        q("FILL_BLANK", "Count: seven, eight, ___, ten.", "nine", None, 1, "production"),
        q("FILL_BLANK", "Complete: I eat with my ___.", "mouth", None, 2, "production"),
        q("SHORT_ANSWER", "Write the body word for the top part of your body.", "head", None, 2, "production"),
        q("ORDERING", "Put the numbers in order: ten / eight / nine / seven", "seven, eight, nine, ten",
          ["ten", "eight", "nine", "seven"], 2, "application"),
        q("IMAGE_MCQ", "Which picture shows the nose?", "Nose",
          ["Nose", "Mouth", "Hand", "Leg"], 1, "recognition",
          option_images=[omoji("nose"), omoji("mouth"), omoji("hand"), omoji("leg")]),
        q("IMAGE_MATCH", "Match the body word with the correct picture", _ans(3), None, 2, "recognition",
          pairs=_match([("Mouth", None), ("Leg", None), ("Hand", None)],
                       [("", omoji("mouth")), ("", omoji("leg")), ("", omoji("hand"))])),
        q("PRONUNCIATION", "Finger", "Finger", None, 2, "pronunciation"),
        q("LISTEN_CHOOSE", "Head", "Head",
          ["Head", "Hand", "Leg", "Face"], 1, "recognition"),
        q("MCQ", "You count seven fingers then three more. How many did you count?",
          "Ten", ["Ten", "Nine", "Eight", "Seven"], 3, "application"),
    ],
}

U5 = {
    "title": "Revision: Units 1-4 (Unit 5)",
    "orderIndex": 5,
    "content": "Revision of greetings, food, animals, body words and numbers 1-10.",
    "objectives": "Revise the language of Units 1-4",
    "imageUrls": [],
    "questions": [
        q("MCQ", "Pick the FOOD word.", "Cheese",
          ["Cheese", "Zebra", "Nose", "Hello"], 1, "recognition"),
        q("MCQ", "Pick the ANIMAL word.", "Goat",
          ["Goat", "Melon", "Mouth", "Goodbye"], 1, "recognition"),
        q("MCQ", "Pick the BODY word.", "Finger",
          ["Finger", "Date", "Kitten", "Hi"], 2, "recognition"),
        q("TRUE_FALSE", "A zebra is a food.", "False", None, 1, "comprehension"),
        q("FILL_BLANK", "Complete the greeting: Good ___, children!", "morning", None, 1, "production"),
        q("SHORT_ANSWER", "Write the number that comes after nine.", "ten", None, 2, "production"),
        q("ORDERING", "Order the words to make a sentence: your / What's / name / ?",
          "What's, your, name, ?", ["your", "What's", "name", "?"], 3, "application"),
        q("DRAG_DROP", "Sort the words: food or animal?",
          "Food=Date,Food=Nut,Animal=Kitten,Animal=Insect", None, 2, "application",
          pairs={"targets": ["Food", "Animal"], "tokens": ["Date", "Kitten", "Nut", "Insect"]}),
        q("IMAGE_MCQ", "Which picture shows something we EAT?", "Egg",
          ["Egg", "Cat", "Hand", "Sun"], 2, "recognition",
          option_images=[omoji("egg"), omoji("cat"), omoji("hand"), omoji("sun")]),
        q("READING", "I see a cat and a dog", "I see a cat and a dog", None, 3, "reading"),
        q("PRONUNCIATION", "Zebra", "Zebra", None, 2, "pronunciation"),
        q("LISTEN_CHOOSE", "Melon", "Melon",
          ["Melon", "Lemon", "Nose", "Lion"], 2, "recognition"),
    ],
}

U6 = {
    "title": "My classroom (Unit 6)",
    "orderIndex": 6,
    "content": "Classroom words: board, teacher, pencil, book, bag, desk. "
               "What's this? It's a pencil.",
    "objectives": "Name classroom items and ask What's this?",
    "imageUrls": [omoji("school")],
    "questions": [
        q("MCQ", "The teacher writes on the ...", "Board",
          ["Board", "Bag", "Desk", "Book"], 1, "recognition"),
        q("MCQ", "What do you ask to know the name of a thing?",
          "What's this?", ["What's this?", "Who's this?", "What's your name?", "How are you?"], 2, "comprehension"),
        q("TRUE_FALSE", "We carry our books in a bag.", "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "A desk is a person in the classroom.", "False", None, 1, "comprehension"),
        q("FILL_BLANK", "Complete: What's this? It's a ___. (you write with it)", "pencil", None, 2, "production"),
        q("FILL_BLANK", "Complete: I read my ___.", "book", None, 1, "production"),
        q("SHORT_ANSWER", "Who helps you learn in the classroom?", "teacher", None, 2, "production"),
        q("ORDERING", "Order the words: this / What's / ?", "What's, this, ?",
          ["this", "What's", "?"], 2, "application"),
        q("IMAGE_MCQ", "Which picture shows the pencil?", "Pencil",
          ["Pencil", "Book", "Bag", "Scissors"], 1, "recognition",
          option_images=[omoji("pencil"), omoji("book"), omoji("backpack"), omoji("scissors")]),
        q("IMAGE_MATCH", "Match each classroom word to its picture", _ans(3), None, 2, "recognition",
          pairs=_match([("Book", None), ("Bag", None), ("Pencil", None)],
                       [("", omoji("book")), ("", omoji("backpack")), ("", omoji("pencil"))])),
        q("PRONUNCIATION", "Pencil", "Pencil", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "Book", "Book",
          ["Board", "Book", "Bag", "Desk"], 1, "recognition"),
        q("MCQ", "It is NOT in the classroom:", "Zebra",
          ["Zebra", "Board", "Desk", "Teacher"], 3, "application"),
    ],
}

U7 = {
    "title": "My family (Unit 7)",
    "orderIndex": 7,
    "content": "Family words: Mum, Dad, sister, brother, baby, me. "
               "Who's this? This is my brother.",
    "objectives": "Talk about family members",
    "imageUrls": [omoji("family")],
    "questions": [
        q("MCQ", "Who is the woman in your family?",
          "Mum", ["Mum", "Dad", "Brother", "Baby"], 1, "recognition"),
        q("MCQ", "What do you ask about a person in a photo?",
          "Who's this?", ["Who's this?", "What's this?", "How many?", "Where's my ball?"], 2, "comprehension"),
        q("TRUE_FALSE", "A brother is a boy.", "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "The baby is the oldest in the family.", "False", None, 2, "comprehension"),
        q("FILL_BLANK", "Complete: Who's this? This is my ___. (a girl)", "sister", None, 2, "production"),
        q("FILL_BLANK", "Complete: My ___ is a man.", "Dad", None, 1, "production"),
        q("SHORT_ANSWER", "Write the family word for the smallest person.", "baby", None, 2, "production"),
        q("ORDERING", "Order the words: is / This / my / Dad", "This, is, my, Dad",
          ["is", "This", "my", "Dad"], 3, "application"),
        q("IMAGE_MCQ", "Which picture shows the baby?", "Baby",
          ["Baby", "Mum", "Dad", "Grandfather"], 1, "recognition",
          option_images=[omoji("baby"), omoji("woman"), omoji("man"), omoji("grandfather")]),
        q("IMAGE_MATCH", "Match each family word to the right picture", _ans(3), None, 2, "recognition",
          pairs=_match([("Mum", None), ("Dad", None), ("Baby", None)],
                       [("", omoji("woman")), ("", omoji("man")), ("", omoji("baby"))])),
        q("PRONUNCIATION", "Sister", "Sister", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "Brother", "Brother",
          ["Brother", "Mum", "Sister", "Baby"], 1, "recognition"),
        q("READING", "This is my Mum and Dad", "This is my Mum and Dad", None, 2, "reading"),
    ],
}

U8 = {
    "title": "Let's drink! (Unit 8)",
    "orderIndex": 8,
    "content": "Drink words: water, milk, tea, coffee, apple juice, orange juice. "
               "What's this? It's water.",
    "objectives": "Name drinks",
    "imageUrls": [omoji("milk")],
    "questions": [
        q("MCQ", "Which drink is white and comes from a cow?",
          "Milk", ["Milk", "Water", "Tea", "Coffee"], 1, "recognition"),
        q("MCQ", "Which juice is made from apples?",
          "Apple juice", ["Apple juice", "Orange juice", "Milk", "Tea"], 1, "recognition"),
        q("TRUE_FALSE", "We drink water every day.", "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "Coffee is a food we eat with a fork.", "False", None, 2, "comprehension"),
        q("FILL_BLANK", "Complete: What's this? It's orange ___.", "juice", None, 2, "production"),
        q("FILL_BLANK", "Complete: I drink ___ when I am thirsty.", "water", None, 1, "production"),
        q("SHORT_ANSWER", "Write the hot drink grown-ups love in the morning.", "coffee", None, 2, "production"),
        q("ORDERING", "Order the words: juice / It's / apple", "It's, apple, juice",
          ["juice", "It's", "apple"], 2, "application"),
        q("IMAGE_MCQ", "Which picture shows the tea?", "Tea",
          ["Tea", "Milk", "Water", "Soup"], 1, "recognition",
          option_images=[omoji("tea"), omoji("milk"), omoji("water"), omoji("soup")]),
        q("DRAG_DROP", "Sort them: drink or food?",
          "Drink=Tea,Drink=Milk,Food=Bread,Food=Cheese", None, 2, "application",
          pairs={"targets": ["Drink", "Food"], "tokens": ["Tea", "Bread", "Milk", "Cheese"]}),
        q("PRONUNCIATION", "Water", "Water", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "Milk", "Milk",
          ["Milk", "Water", "Tea", "Coffee"], 1, "recognition",
          option_images=[omoji("milk"), omoji("water"), omoji("tea"), None]),
        q("MCQ", "Sara wants a COLD drink. Which is best?",
          "Orange juice", ["Orange juice", "Tea", "Coffee", "Soup"], 3, "application"),
    ],
}

U9 = {
    "title": "Revision: Units 6-8 (Unit 9)",
    "orderIndex": 9,
    "content": "Revision of classroom, family and drink words.",
    "objectives": "Revise the language of Units 6-8",
    "imageUrls": [],
    "questions": [
        q("MCQ", "Pick the CLASSROOM word.", "Desk",
          ["Desk", "Milk", "Sister", "Water"], 1, "recognition"),
        q("MCQ", "Pick the FAMILY word.", "Brother",
          ["Brother", "Board", "Tea", "Pencil"], 1, "recognition"),
        q("MCQ", "Pick the DRINK word.", "Tea",
          ["Tea", "Bag", "Baby", "Book"], 1, "recognition"),
        q("TRUE_FALSE", "'Who's this?' is for asking about a THING.", "False", None, 2, "comprehension"),
        q("FILL_BLANK", "Complete: This is my Mum and this is my ___. (a man)", "Dad", None, 2, "production"),
        q("SHORT_ANSWER", "What drink do we make from oranges? (two words)", "orange juice", None, 3, "production"),
        q("ORDERING", "Order the words: my / This / is / sister", "This, is, my, sister",
          ["my", "This", "is", "sister"], 2, "application"),
        q("DRAG_DROP", "Sort the words: classroom or family?",
          "Classroom=Board,Classroom=Desk,Family=Mum,Family=Baby", None, 2, "application",
          pairs={"targets": ["Classroom", "Family"], "tokens": ["Board", "Mum", "Desk", "Baby"]}),
        q("IMAGE_MCQ", "Which picture shows something we DRINK?", "Water",
          ["Water", "Bread", "Book", "Cat"], 2, "recognition",
          option_images=[omoji("water"), omoji("bread"), omoji("book"), omoji("cat")]),
        q("READING", "I drink milk with my family", "I drink milk with my family", None, 3, "reading"),
        q("PRONUNCIATION", "Teacher", "Teacher", None, 2, "pronunciation"),
        q("LISTEN_CHOOSE", "Desk", "Desk",
          ["Desk", "Pencil", "Board", "Bag"], 2, "recognition"),
    ],
}

LESSONS = [U1, U2, U3, U4, U5, U6, U7, U8, U9]


def main():
    # The book's alphabet appendix → first two alphabet lessons after the units.
    from _grade1_en_alphabet import ALPHABET_LESSONS
    import copy
    lessons = list(LESSONS)
    for i, alpha in enumerate(copy.deepcopy(ALPHABET_LESSONS[0:2])):
        alpha["orderIndex"] = 10 + i
        lessons.append(alpha)
    write_curriculum(subject_code="en", grade=1, semester=1, lessons=lessons)


if __name__ == "__main__":
    main()

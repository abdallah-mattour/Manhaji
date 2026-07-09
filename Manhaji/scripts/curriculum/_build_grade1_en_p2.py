# -*- coding: utf-8 -*-
"""
English — Grade 1 — Semester 2 (2026-07-04 book-alignment rebuild).

Mirrors the REAL *English for Palestine — Pupil's Book 1B* unit structure,
extracted from PDFBooks/1Grade/English/en1-p2.pdf (Contents, page 3):

  10  Let's play!   ball, doll, yo-yo, kite, balloon, skates
                    Where's my ball? Here! There!
  11  Transport     car, bus, bike, van, taxi · How many taxis? Five taxis.
  12  Colours       red, green, white, blue, black, yellow, umbrella
                    What colour? Red and black.
  13  My clothes    t-shirt, shoes, shorts, jeans, dress, skirt
                    a red skirt, blue jeans
  14  Revision      Units 10-13
  15  My bedroom    bed, table, chair, box, window, door · in / on / under
  16  In my country orange, lemon, grape, apple, banana, fig, olive
                    It's (very) big / small.
  17  My friends    This is my friend. I'm short. He's/She's tall.
                    Stand up. Sit down. Jump up and down.
  18  Revision      Units 15-17
  (+ alphabet appendix → the last two alphabet lessons, orderIndex 10-11)
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


U10 = {
    "title": "Let's play! (Unit 10)",
    "orderIndex": 1,
    "content": "Toy words: ball, doll, yo-yo, kite, balloon, skates. "
               "Where's my ball? Here! There!",
    "objectives": "Name toys and say where something is",
    "imageUrls": [omoji("kite")],
    "questions": [
        q("MCQ", "Which toy flies in the sky on a string?",
          "Kite", ["Kite", "Doll", "Ball", "Skates"], 1, "recognition"),
        q("MCQ", "What do you ask when you cannot find your ball?",
          "Where's my ball?", ["Where's my ball?", "What's this?", "Who's this?", "What colour?"], 2, "comprehension"),
        q("TRUE_FALSE", "We answer 'Here!' when the toy is near us.", "True", None, 2, "comprehension"),
        q("TRUE_FALSE", "A balloon is a heavy toy.", "False", None, 1, "comprehension"),
        q("FILL_BLANK", "Complete: Where's my ___? There!", "kite", None, 2, "production"),
        q("FILL_BLANK", "Complete: I play with my ___ and my doll.", "ball", None, 1, "production"),
        q("SHORT_ANSWER", "Write the toy that goes up and down on a string.", "yo-yo", None, 2, "production"),
        q("ORDERING", "Order the words: my / Where's / doll / ?", "Where's, my, doll, ?",
          ["my", "Where's", "doll", "?"], 3, "application"),
        q("IMAGE_MCQ", "Which picture shows the balloon?", "Balloon",
          ["Balloon", "Kite", "Ball", "Teddy bear"], 1, "recognition",
          option_images=[omoji("balloon"), omoji("kite"), omoji("soccer_ball"), omoji("teddy_bear")]),
        q("IMAGE_MATCH", "Match each toy word to its picture", _ans(3), None, 2, "recognition",
          pairs=_match([("Ball", None), ("Kite", None), ("Balloon", None)],
                       [("", omoji("soccer_ball")), ("", omoji("kite")), ("", omoji("balloon"))])),
        q("PRONUNCIATION", "Balloon", "Balloon", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "Doll", "Doll",
          ["Doll", "Ball", "Kite", "Skates"], 1, "recognition"),
        q("READING", "Where's my ball? Here it is", "Where's my ball? Here it is", None, 3, "reading"),
    ],
}

U11 = {
    "title": "Transport (Unit 11)",
    "orderIndex": 2,
    "content": "Transport words: car, bus, bike, van, taxi. "
               "How many taxis? Five taxis.",
    "objectives": "Name transport and count vehicles",
    "imageUrls": [omoji("bus")],
    "questions": [
        q("MCQ", "Which one takes many children to school together?",
          "Bus", ["Bus", "Bike", "Taxi", "Van"], 1, "recognition"),
        q("MCQ", "Which one has two wheels and pedals?",
          "Bike", ["Bike", "Car", "Bus", "Van"], 1, "recognition"),
        q("TRUE_FALSE", "A taxi takes people from place to place.", "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "A van is smaller than a bike.", "False", None, 2, "comprehension"),
        q("FILL_BLANK", "Complete: How many taxis? ___ taxis.", "Five", None, 2, "production"),
        q("FILL_BLANK", "Complete: My dad drives a ___.", "car", None, 1, "production"),
        q("SHORT_ANSWER", "Write the transport word that rhymes with 'man'.", "van", None, 3, "production"),
        q("ORDERING", "Order the words: many / How / buses / ?", "How, many, buses, ?",
          ["many", "How", "buses", "?"], 2, "application"),
        q("IMAGE_MCQ", "Which picture shows the bus?", "Bus",
          ["Bus", "Car", "Bike", "Train"], 1, "recognition",
          option_images=[omoji("bus"), omoji("car"), omoji("bicycle"), omoji("train")]),
        q("DRAG_DROP", "Sort them: has two wheels or four wheels?",
          "Two wheels=Bike,Two wheels=Motorbike,Four wheels=Car,Four wheels=Van",
          None, 2, "application",
          pairs={"targets": ["Two wheels", "Four wheels"],
                 "tokens": ["Bike", "Car", "Motorbike", "Van"]}),
        q("PRONUNCIATION", "Taxi", "Taxi", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "Bus", "Bus",
          ["Bus", "Bike", "Car", "Taxi"], 1, "recognition",
          option_images=[omoji("bus"), omoji("bicycle"), omoji("car"), None]),
    ],
}

U12 = {
    "title": "Colours (Unit 12)",
    "orderIndex": 3,
    "content": "Colour words: red, green, white, blue, black, yellow, umbrella. "
               "What colour? Red and black.",
    "objectives": "Identify colours and say what colour something is",
    "imageUrls": [omoji("rainbow")],
    "questions": [
        q("MCQ", "What colour is the sky on a sunny day?",
          "Blue", ["Blue", "Black", "Red", "Green"], 1, "recognition"),
        q("MCQ", "What colour is snow?",
          "White", ["White", "Yellow", "Green", "Blue"], 1, "recognition"),
        q("TRUE_FALSE", "Grass is green.", "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "The sun looks black in the sky.", "False", None, 1, "comprehension"),
        q("FILL_BLANK", "Complete: What colour? Red and ___. (the darkest colour)", "black", None, 2, "production"),
        q("FILL_BLANK", "Complete: A banana is ___.", "yellow", None, 1, "production"),
        q("SHORT_ANSWER", "Write the colour of a tomato.", "red", None, 2, "production"),
        q("ORDERING", "Order the words: colour / What / ?", "What, colour, ?",
          ["colour", "What", "?"], 2, "application"),
        q("IMAGE_MCQ", "Which circle is the GREEN one?", "Green",
          ["Green", "Red", "Blue", "Yellow"], 1, "recognition",
          option_images=[omoji("green"), omoji("red"), omoji("blue"), omoji("yellow")]),
        q("IMAGE_MATCH", "Match the colour word to the right circle", _ans(3), None, 2, "recognition",
          pairs=_match([("White", None), ("Black", None), ("Blue", None)],
                       [("", omoji("circle_white")), ("", omoji("circle_black")), ("", omoji("circle_blue"))])),
        q("PRONUNCIATION", "Yellow", "Yellow", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "White", "White",
          ["White", "Black", "Red", "Green"], 1, "recognition",
          option_images=[omoji("circle_white"), omoji("circle_black"), omoji("circle_red"), omoji("square_green")]),
        q("MCQ", "An umbrella is red AND black. How many colours is that?",
          "Two", ["Two", "One", "Three", "Four"], 3, "application"),
    ],
}

U13 = {
    "title": "My clothes (Unit 13)",
    "orderIndex": 4,
    "content": "Clothes words: t-shirt, shoes, shorts, jeans, dress, skirt. "
               "A red skirt, blue jeans.",
    "objectives": "Identify clothes and describe them with colours",
    "imageUrls": [omoji("shirt")],
    "questions": [
        q("MCQ", "What do you wear on your feet?",
          "Shoes", ["Shoes", "Dress", "T-shirt", "Skirt"], 1, "recognition"),
        q("MCQ", "Jeans are usually ...",
          "Blue", ["Blue", "Pink", "White", "Yellow"], 2, "comprehension"),
        q("TRUE_FALSE", "A dress is a piece of clothing.", "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "We wear shorts on our head.", "False", None, 1, "comprehension"),
        q("FILL_BLANK", "Complete: Sara wears a red ___. (it spins when she turns)", "skirt", None, 2, "production"),
        q("FILL_BLANK", "Complete: In summer I wear a ___-shirt.", "t", None, 2, "production"),
        q("SHORT_ANSWER", "Write the clothes word for short trousers.", "shorts", None, 2, "production"),
        q("ORDERING", "Order the words: jeans / blue / my", "my, blue, jeans",
          ["jeans", "blue", "my"], 3, "application"),
        q("IMAGE_MCQ", "Which picture shows the dress?", "Dress",
          ["Dress", "T-shirt", "Shoes", "Jeans"], 1, "recognition",
          option_images=[omoji("dress"), omoji("shirt"), omoji("shoe"), omoji("jeans")]),
        q("IMAGE_MATCH", "Match each clothes word to its picture", _ans(3), None, 2, "recognition",
          pairs=_match([("T-shirt", None), ("Shoes", None), ("Jeans", None)],
                       [("", omoji("shirt")), ("", omoji("shoe")), ("", omoji("jeans"))])),
        q("PRONUNCIATION", "Shoes", "Shoes", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "Dress", "Dress",
          ["Dress", "Shorts", "Skirt", "Shoes"], 1, "recognition"),
    ],
}

U14 = {
    "title": "Revision: Units 10-13 (Unit 14)",
    "orderIndex": 5,
    "content": "Revision of toys, transport, colours and clothes.",
    "objectives": "Revise the language of Units 10-13",
    "imageUrls": [],
    "questions": [
        q("MCQ", "Pick the TOY word.", "Yo-yo",
          ["Yo-yo", "Taxi", "Skirt", "White"], 1, "recognition"),
        q("MCQ", "Pick the TRANSPORT word.", "Van",
          ["Van", "Doll", "Shorts", "Green"], 1, "recognition"),
        q("MCQ", "Pick the CLOTHES word.", "Skirt",
          ["Skirt", "Kite", "Bus", "Black"], 1, "recognition"),
        q("TRUE_FALSE", "'What colour?' asks about the name of a toy.", "False", None, 2, "comprehension"),
        q("FILL_BLANK", "Complete: I ride a blue ___ to school. (two wheels)", "bike", None, 2, "production"),
        q("SHORT_ANSWER", "Write the colour of the night sky.", "black", None, 2, "production"),
        q("ORDERING", "Order the words: skirt / a / red", "a, red, skirt",
          ["skirt", "a", "red"], 3, "application"),
        q("DRAG_DROP", "Sort the words: toys or clothes?",
          "Toys=Kite,Toys=Doll,Clothes=Dress,Clothes=Shorts", None, 2, "application",
          pairs={"targets": ["Toys", "Clothes"], "tokens": ["Kite", "Dress", "Doll", "Shorts"]}),
        q("IMAGE_MCQ", "Which picture shows something we WEAR?", "Shoes",
          ["Shoes", "Balloon", "Bus", "Kite"], 2, "recognition",
          option_images=[omoji("shoe"), omoji("balloon"), omoji("bus"), omoji("kite")]),
        q("READING", "My kite is red and blue", "My kite is red and blue", None, 3, "reading"),
        q("PRONUNCIATION", "Skates", "Skates", None, 2, "pronunciation"),
        q("LISTEN_CHOOSE", "Kite", "Kite",
          ["Kite", "Bike", "White", "Skates"], 2, "recognition"),
    ],
}

U15 = {
    "title": "My bedroom (Unit 15)",
    "orderIndex": 6,
    "content": "Bedroom words: bed, table, chair, box, window, door. "
               "It's in / on / under the bed.",
    "objectives": "Name bedroom things and say where something is",
    "imageUrls": [omoji("bed")],
    "questions": [
        q("MCQ", "Where do you sleep at night?",
          "Bed", ["Bed", "Chair", "Table", "Box"], 1, "recognition"),
        q("MCQ", "The ball is NOT on the bed. It is ___ the bed.",
          "under", ["under", "happy", "blue", "big"], 2, "comprehension"),
        q("TRUE_FALSE", "We open the window to get fresh air.", "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "We sit on the door.", "False", None, 1, "comprehension"),
        q("FILL_BLANK", "Complete: The doll is in the ___. (we keep toys inside it)", "box", None, 2, "production"),
        q("FILL_BLANK", "Complete: I sit on my ___.", "chair", None, 1, "production"),
        q("SHORT_ANSWER", "Write the word for the thing you walk through to enter a room.", "door", None, 2, "production"),
        q("ORDERING", "Order the words: on / It's / the / bed", "It's, on, the, bed",
          ["on", "It's", "the", "bed"], 3, "application"),
        q("IMAGE_MCQ", "Which picture shows the chair?", "Chair",
          ["Chair", "Bed", "Door", "Key"], 1, "recognition",
          option_images=[omoji("chair"), omoji("bed"), omoji("door"), omoji("key")]),
        q("IMAGE_MATCH", "Match each bedroom word to its picture", _ans(3), None, 2, "recognition",
          pairs=_match([("Bed", None), ("Door", None), ("Chair", None)],
                       [("", omoji("bed")), ("", omoji("door")), ("", omoji("chair"))])),
        q("PRONUNCIATION", "Window", "Window", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "Bed", "Bed",
          ["Bed", "Box", "Door", "Table"], 1, "recognition"),
    ],
}

U16 = {
    "title": "In my country (Unit 16)",
    "orderIndex": 7,
    "content": "Things that grow in Palestine: orange, lemon, grape, apple, "
               "banana, fig, olive. It's (very) big / small.",
    "objectives": "Name fruits that grow in Palestine and describe size",
    "imageUrls": [omoji("olive")],
    "questions": [
        q("MCQ", "Which fruit is yellow and sour?",
          "Lemon", ["Lemon", "Grape", "Fig", "Olive"], 1, "recognition"),
        q("MCQ", "Which small green or purple fruit grows in bunches?",
          "Grape", ["Grape", "Banana", "Orange", "Apple"], 2, "comprehension"),
        q("TRUE_FALSE", "Olives grow in Palestine.", "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "A watermelon is very small.", "False", None, 1, "comprehension"),
        q("FILL_BLANK", "Complete: The elephant is very ___.", "big", None, 1, "production"),
        q("FILL_BLANK", "Complete: An ___ tree gives us oil. (a Palestinian tree)", "olive", None, 3, "production"),
        q("SHORT_ANSWER", "Write the long yellow fruit monkeys love.", "banana", None, 1, "production"),
        q("ORDERING", "Order the words: very / It's / big", "It's, very, big",
          ["very", "It's", "big"], 2, "application"),
        q("IMAGE_MCQ", "Which picture shows the lemon?", "Lemon",
          ["Lemon", "Orange", "Apple", "Grapes"], 1, "recognition",
          option_images=[omoji("lemon"), omoji("orange"), omoji("apple"), omoji("grapes")]),
        q("DRAG_DROP", "Sort the fruits: big or small?",
          "Big=Watermelon,Big=Melon,Small=Grape,Small=Olive", None, 2, "application",
          pairs={"targets": ["Big", "Small"], "tokens": ["Watermelon", "Grape", "Melon", "Olive"]}),
        q("PRONUNCIATION", "Orange", "Orange", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "Grapes", "Grapes",
          ["Grapes", "Apple", "Banana", "Lemon"], 1, "recognition",
          option_images=[omoji("grapes"), omoji("apple"), omoji("banana"), omoji("lemon")]),
        q("READING", "The olive tree is very big", "The olive tree is very big", None, 3, "reading"),
    ],
}

U17 = {
    "title": "My friends (Unit 17)",
    "orderIndex": 8,
    "content": "This is my friend. I'm short. He's / She's tall. "
               "Stand up. Sit down. Jump up and down.",
    "objectives": "Introduce a friend, describe height, follow instructions",
    "imageUrls": [omoji("boy")],
    "questions": [
        q("MCQ", "How do you introduce your friend?",
          "This is my friend.", ["This is my friend.", "Where's my ball?", "What colour?", "How many taxis?"], 1, "comprehension"),
        q("MCQ", "The opposite of 'tall' is ...",
          "short", ["short", "big", "fast", "happy"], 2, "comprehension"),
        q("TRUE_FALSE", "'Stand up' means get on your feet.", "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "'Sit down' and 'stand up' mean the same thing.", "False", None, 1, "comprehension"),
        q("FILL_BLANK", "Complete: He's tall. She's ___.", "short", None, 2, "production"),
        q("FILL_BLANK", "Complete: Jump up and ___!", "down", None, 1, "production"),
        q("SHORT_ANSWER", "Write the instruction the teacher says when you should sit. (two words)", "sit down", None, 2, "production"),
        q("ORDERING", "Order the words: my / is / This / friend", "This, is, my, friend",
          ["my", "is", "This", "friend"], 3, "application"),
        q("ORDERING", "Order the actions as the teacher says them: Jump up / Stand up / Sit down",
          "Stand up, Jump up, Sit down", ["Jump up", "Stand up", "Sit down"], 2, "application"),
        q("PRONUNCIATION", "Friend", "Friend", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "Jump", "Jump",
          ["Jump", "Sit", "Stand", "Run"], 1, "recognition"),
        q("READING", "This is my friend and she is tall", "This is my friend and she is tall", None, 3, "reading"),
    ],
}

U18 = {
    "title": "Revision: Units 15-17 (Unit 18)",
    "orderIndex": 9,
    "content": "Revision of bedroom words, Palestinian fruits and describing friends.",
    "objectives": "Revise the language of Units 15-17",
    "imageUrls": [],
    "questions": [
        q("MCQ", "Pick the BEDROOM word.", "Window",
          ["Window", "Grape", "Friend", "Tall"], 1, "recognition"),
        q("MCQ", "Pick the FRUIT word.", "Fig",
          ["Fig", "Chair", "Short", "Door"], 1, "recognition"),
        q("MCQ", "Where can the cat be? Choose the PLACE phrase.",
          "under the table", ["under the table", "very tall", "my friend", "jump up"], 2, "comprehension"),
        q("TRUE_FALSE", "Bananas and oranges grow on trees.", "True", None, 1, "comprehension"),
        q("FILL_BLANK", "Complete: My friend is not short, he is ___.", "tall", None, 2, "production"),
        q("SHORT_ANSWER", "Write the fruit we press to make Palestinian oil.", "olive", None, 3, "production"),
        q("ORDERING", "Order the words: the / in / box / It's", "It's, in, the, box",
          ["the", "in", "box", "It's"], 2, "application"),
        q("DRAG_DROP", "Sort the words: bedroom or fruit?",
          "Bedroom=Window,Bedroom=Table,Fruit=Fig,Fruit=Lemon", None, 2, "application",
          pairs={"targets": ["Bedroom", "Fruit"], "tokens": ["Window", "Fig", "Table", "Lemon"]}),
        q("IMAGE_MCQ", "Which picture shows something that GROWS in Palestine?", "Olive",
          ["Olive", "Chair", "Kite", "Bus"], 2, "recognition",
          option_images=[omoji("olive"), omoji("chair"), omoji("kite"), omoji("bus")]),
        q("READING", "My bed is big and my box is small", "My bed is big and my box is small", None, 3, "reading"),
        q("PRONUNCIATION", "Banana", "Banana", None, 1, "pronunciation"),
        q("LISTEN_CHOOSE", "Apple", "Apple",
          ["Apple", "Olive", "Lemon", "Fig"], 2, "recognition",
          option_images=[omoji("apple"), omoji("olive"), omoji("lemon"), None]),
    ],
}

LESSONS = [U10, U11, U12, U13, U14, U15, U16, U17, U18]


def main():
    # The book's alphabet appendix → last two alphabet lessons after the units.
    from _grade1_en_alphabet import ALPHABET_LESSONS
    import copy
    lessons = list(LESSONS)
    for i, alpha in enumerate(copy.deepcopy(ALPHABET_LESSONS[2:4])):
        alpha["orderIndex"] = 10 + i
        lessons.append(alpha)
    write_curriculum(subject_code="en", grade=1, semester=2, lessons=lessons)


if __name__ == "__main__":
    main()
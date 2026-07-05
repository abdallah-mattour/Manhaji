"""
Build Grade 2 English, Semester 1 — en2_p1.json.

9 units (continuing Grade 1's structure but using Macmillan's Grade 2 syllabus):
  1. Hi, I'm ...      — names, ages, asking who
  2. In the kitchen   — food vocab + likes/dislikes + numbers 11-13
  3. In the garden    — bee/butterfly/bird/flower/tree + 'has' + numbers 14-16
  4. My body          — ear/eye/hair/shoulder + 'have/has' + numbers 17-20
  5. Revision (1-4)
  6. Jump!            — action commands + 'Don't ...'
  7. My home          — telephone/sofa/computer/rug/TV + prepositions on/in/under
  8. My town          — mosque/church/shop/school/park/playground + next to/between
  9. Revision (6-8)

Each unit hits spec §4.4 template (~13 questions):
  MCQ x3, TRUE_FALSE x2, SHORT_ANSWER x2, FILL_BLANK x2, ORDERING x1, PRONUNCIATION x3.
At least 1 difficulty-3, ≥3 sub-skills.

TRUE_FALSE uses "True"/"False" (English-pure). PRONUNCIATION prompts use the
"Say:" prefix to differ from Grade 1's "Say the letter:" / "Say the day:" / etc.
"""
from _common import q, write_curriculum


# ===========================================================================
# Unit 1: Hi, I'm ...
# ===========================================================================
UNIT_1 = {
    "title": "Hi, I'm ... (Unit 1)",
    "orderIndex": 1,
    "content": "Greetings and introductions. Asking and giving names and ages. Identifying boys and girls.",
    "objectives": "Ask and answer about names and ages. Introduce yourself and others. Review numbers 1-10.",
    "questions": [
        q("MCQ", "What do you ask to know someone's name?",
          "What's your name?",
          ["What's your name?", "How old are you?",
           "Where are you?", "Who's that?"], 1, "comprehension"),
        q("MCQ", "How do you reply when someone asks 'How old are you?' and you are 8?",
          "I'm eight",
          ["I'm seven", "I'm eight",
           "I'm nine", "My name is eight"], 1, "comprehension"),
        q("MCQ", "Salwa is 7 years old. How do you say her age?",
          "She's seven",
          ["He's seven", "She's seven",
           "It's seven", "They're seven"], 2, "application"),
        q("TRUE_FALSE", "We say 'My name's Tala' to tell people our name.",
          "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "We say 'How old is he?' when asking about a girl.",
          "False", None, 2, "comprehension"),
        q("SHORT_ANSWER", "Translate to English: ما اسمك؟",
          "What's your name?", None, 1, "production"),
        q("SHORT_ANSWER", "If a boy is in the picture, you ask: '___ that boy?'",
          "Who's", None, 2, "production"),
        q("FILL_BLANK", "Complete: My name ___ Sami.",
          "is", None, 1, "production"),
        q("FILL_BLANK", "Complete: I'm eight years ___.",
          "old", None, 1, "production"),
        q("ORDERING", "Put the words in order to form a question: name, your, what's, ?",
          "what's, your, name, ?",
          ["name", "your", "what's", "?"], 2, "application"),
        q("PRONUNCIATION", "Say: What's your name?",
          "What's your name?", None, 1, "pronunciation"),
        q("PRONUNCIATION", "Say: My name is Tala",
          "My name is Tala", None, 1, "pronunciation"),
        q("PRONUNCIATION", "Say: How old are you?",
          "How old are you?", None, 2, "pronunciation"),
        q("MCQ", "A new student joins the class. What is the best thing to say first?",
          "Hi, what's your name?",
          ["Goodbye", "Hi, what's your name?",
           "Be quiet!", "I don't know"], 3, "application"),
    ],
    "imageUrls": [],
}

# ===========================================================================
# Unit 2: In the kitchen
# ===========================================================================
UNIT_2 = {
    "title": "In the kitchen (Unit 2)",
    "orderIndex": 2,
    "content": "Food vocabulary: kunafeh, rice, meat, fish, chicken, salad, ice cream, chocolate. Talking about food likes. Numbers 11, 12, 13.",
    "objectives": "Name common food items. Ask and answer 'What does he/she like?'. Read numbers 11-13.",
    "questions": [
        q("MCQ", "What is 'أرز' in English?",
          "rice",
          ["rice", "meat", "fish", "chicken"], 1, "recognition"),
        q("MCQ", "What is the famous Palestinian dessert?",
          "kunafeh",
          ["chocolate", "kunafeh", "salad", "rice"], 2, "recognition"),
        q("MCQ", "How do you ask about Sami's favourite food?",
          "What does he like?",
          ["What does she like?", "What does he like?",
           "What do you like?", "What is your name?"], 2, "application"),
        q("TRUE_FALSE", "Ice cream is usually cold.",
          "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "Chicken is a kind of fruit.",
          "False", None, 1, "comprehension"),
        q("SHORT_ANSWER", "Translate to English: سمك",
          "fish", None, 1, "production"),
        q("SHORT_ANSWER", "What number comes after twelve?",
          "thirteen", None, 1, "production"),
        q("FILL_BLANK", "Complete: She ___ chocolate. (like / likes)",
          "likes", None, 2, "production"),
        q("FILL_BLANK", "Complete: 11, 12, ___",
          "13", None, 1, "production"),
        q("ORDERING", "Put in order to form a sentence: likes, rice, he, and meat",
          "he, likes, rice, and meat",
          ["likes", "rice", "he", "and meat"], 2, "application"),
        q("PRONUNCIATION", "Say: kunafeh",
          "kunafeh", None, 2, "pronunciation"),
        q("PRONUNCIATION", "Say: ice cream",
          "ice cream", None, 1, "pronunciation"),
        q("PRONUNCIATION", "Say: chocolate",
          "chocolate", None, 1, "pronunciation"),
        q("MCQ", "Tala likes salad and fish. Sami doesn't like fish. What does Sami like?",
          "He likes salad",
          ["He likes fish", "He likes salad",
           "He likes everything", "We don't know"], 3, "application"),
    ],
    "imageUrls": [],
}

# ===========================================================================
# Unit 3: In the garden
# ===========================================================================
UNIT_3 = {
    "title": "In the garden (Unit 3)",
    "orderIndex": 3,
    "content": "Garden vocabulary: bee, butterfly, bird, flower, tree. Numbers 14, 15, 16. Talking about things in the garden using 'has'.",
    "objectives": "Name common garden creatures and plants. Use 'has' in simple sentences. Read numbers 14-16.",
    "questions": [
        q("MCQ", "What is 'نحلة' in English?",
          "bee",
          ["bird", "butterfly", "bee", "tree"], 1, "recognition"),
        q("MCQ", "Which one can fly and has colourful wings?",
          "butterfly",
          ["tree", "butterfly", "flower", "stone"], 2, "recognition"),
        q("MCQ", "A bird ___ two legs.",
          "has",
          ["is", "has", "have", "do"], 2, "production"),
        q("TRUE_FALSE", "A flower has roots and petals.",
          "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "A tree usually has only one leaf.",
          "False", None, 1, "comprehension"),
        q("SHORT_ANSWER", "Translate to English: شجرة",
          "tree", None, 1, "production"),
        q("SHORT_ANSWER", "What number comes after fifteen?",
          "sixteen", None, 1, "production"),
        q("FILL_BLANK", "Complete: A bird has two ___.",
          "legs", None, 1, "production"),
        q("FILL_BLANK", "Complete: 14, ___, 16",
          "15", None, 1, "production"),
        q("ORDERING", "Put in order: tree, the, on, sits, bird, the",
          "the, bird, sits, on, the, tree",
          ["tree", "the", "on", "sits", "bird", "the"], 3, "application"),
        q("PRONUNCIATION", "Say: butterfly",
          "butterfly", None, 2, "pronunciation"),
        q("PRONUNCIATION", "Say: flower",
          "flower", None, 1, "pronunciation"),
        q("PRONUNCIATION", "Say: tree",
          "tree", None, 1, "pronunciation"),
        q("MCQ", "Look in a garden. Which of these would you NOT expect to see?",
          "fish",
          ["bee", "flower", "tree", "fish"], 2, "application"),
    ],
    "imageUrls": [],
}

# ===========================================================================
# Unit 4: My body
# ===========================================================================
UNIT_4 = {
    "title": "My body (Unit 4)",
    "orderIndex": 4,
    "content": "New body parts vocabulary: ear, eye, hair, shoulder. Using 'I/You/We have' and 'He/She has'. Simple commands. Numbers 17-20.",
    "objectives": "Name new body parts. Use 'have' and 'has' correctly. Follow simple commands. Read numbers 17-20.",
    "questions": [
        q("MCQ", "Which body part do you use to see?",
          "eye",
          ["ear", "eye", "hair", "shoulder"], 1, "comprehension"),
        q("MCQ", "Which body part do you use to hear?",
          "ear",
          ["ear", "eye", "hair", "shoulder"], 1, "comprehension"),
        q("MCQ", "Tala has long hair. We say: 'She ___ long hair'.",
          "has",
          ["have", "has", "is", "having"], 2, "production"),
        q("TRUE_FALSE", "We have two shoulders.",
          "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "We have three eyes.",
          "False", None, 1, "comprehension"),
        q("SHORT_ANSWER", "Translate to English: شعر",
          "hair", None, 1, "production"),
        q("SHORT_ANSWER", "What number comes after nineteen?",
          "twenty", None, 1, "production"),
        q("FILL_BLANK", "Complete: I have two ___ to listen.",
          "ears", None, 2, "production"),
        q("FILL_BLANK", "Complete: 17, 18, ___, 20",
          "19", None, 1, "production"),
        q("ORDERING", "Put in order: brown, has, hair, she",
          "she, has, brown, hair",
          ["brown", "has", "hair", "she"], 2, "application"),
        q("PRONUNCIATION", "Say: shoulder",
          "shoulder", None, 2, "pronunciation"),
        q("PRONUNCIATION", "Say: eye",
          "eye", None, 1, "pronunciation"),
        q("PRONUNCIATION", "Say: hair",
          "hair", None, 1, "pronunciation"),
        q("MCQ", "Your teacher says: 'Touch your hair'. What do you do?",
          "I put my hand on my head",
          ["I put my hand on my head",
           "I close my eyes",
           "I sit down",
           "I clap my hands"], 3, "application"),
    ],
    "imageUrls": [],
}

# ===========================================================================
# Unit 5: Revision (Units 1-4)
# ===========================================================================
UNIT_5 = {
    "title": "Revision Units 1-4 (Unit 5)",
    "orderIndex": 5,
    "content": "Review: greetings, names, ages, food, garden vocabulary, body parts, numbers 1-20.",
    "objectives": "Review the language and vocabulary from Units 1-4.",
    "questions": [
        q("MCQ", "Choose the correct greeting in the morning.",
          "Good morning",
          ["Good morning", "Good night",
           "Goodbye", "Be quiet"], 1, "recognition"),
        q("MCQ", "Which of these is food, NOT a garden item?",
          "chicken",
          ["bee", "flower", "chicken", "tree"], 2, "recognition"),
        q("MCQ", "She has a butterfly. Pick the correct rewrite as a question.",
          "Does she have a butterfly?",
          ["She does have a butterfly?",
           "Have she a butterfly?",
           "Does she have a butterfly?",
           "She a butterfly has?"], 3, "application"),
        q("TRUE_FALSE", "Number 17 is bigger than number 14.",
          "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "An eye is a kind of food.",
          "False", None, 1, "comprehension"),
        q("SHORT_ANSWER", "Translate to English: عمر",
          "age", None, 1, "production"),
        q("SHORT_ANSWER", "Name one thing you eat that is sweet.",
          "ice cream", None, 1, "production"),
        q("FILL_BLANK", "Complete: He ___ ice cream and salad.",
          "likes", None, 2, "production"),
        q("FILL_BLANK", "Complete: 12, 13, ___, 15",
          "14", None, 1, "production"),
        q("ORDERING", "Put the numbers in order from smallest to biggest: 19, 11, 16, 13",
          "11, 13, 16, 19",
          ["19", "11", "16", "13"], 2, "application"),
        q("PRONUNCIATION", "Say: ear",
          "ear", None, 1, "pronunciation"),
        q("PRONUNCIATION", "Say: bee",
          "bee", None, 1, "pronunciation"),
        q("MCQ", "I am 8. My friend Adam is 7. Who is older?",
          "I am older",
          ["Adam is older", "I am older",
           "We are the same age", "I don't know"], 3, "application"),
    ],
    "imageUrls": [],
}

# ===========================================================================
# Unit 6: Jump!
# ===========================================================================
UNIT_6 = {
    "title": "Jump! (Unit 6)",
    "orderIndex": 6,
    "content": "Action commands: jump, hop, clap, open, close, come here, go there, be quiet. Negative commands using 'Don't'.",
    "objectives": "Understand and obey simple commands. Form negative commands with 'Don't'.",
    "questions": [
        q("MCQ", "What is the English word for 'يقفز'?",
          "jump",
          ["clap", "jump", "hop", "open"], 1, "recognition"),
        q("MCQ", "Your teacher says 'Clap'. What do you do?",
          "I hit my hands together",
          ["I hit my hands together",
           "I close my eyes",
           "I stand still",
           "I sit on the floor"], 1, "application"),
        q("MCQ", "How do you tell a friend NOT to sit down?",
          "Don't sit down.",
          ["Sit down.", "Don't sit down.",
           "Please sit.", "I sit down."], 2, "production"),
        q("TRUE_FALSE", "'Be quiet' means we should not make noise.",
          "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "'Open' is the opposite of 'come'.",
          "False", None, 2, "comprehension"),
        q("SHORT_ANSWER", "Translate to English: اصمت",
          "Be quiet", None, 1, "production"),
        q("SHORT_ANSWER", "What is the opposite of 'open'?",
          "close", None, 1, "production"),
        q("FILL_BLANK", "Complete: ___ here, please.",
          "Come", None, 1, "production"),
        q("FILL_BLANK", "Complete: ___ run in the classroom!",
          "Don't", None, 2, "production"),
        q("ORDERING", "Put in order: the, please, open, door",
          "open, the, door, please",
          ["the", "please", "open", "door"], 2, "application"),
        q("PRONUNCIATION", "Say: jump",
          "jump", None, 1, "pronunciation"),
        q("PRONUNCIATION", "Say: clap",
          "clap", None, 1, "pronunciation"),
        q("PRONUNCIATION", "Say: come here",
          "come here", None, 2, "pronunciation"),
        q("MCQ", "Your little brother is making noise in the library. What do you say?",
          "Please be quiet.",
          ["Jump!", "Please be quiet.",
           "Open the door.", "Clap your hands."], 3, "application"),
    ],
    "imageUrls": [],
}

# ===========================================================================
# Unit 7: My home
# ===========================================================================
UNIT_7 = {
    "title": "My home (Unit 7)",
    "orderIndex": 7,
    "content": "Living-room vocabulary: telephone, sofa, computer, rug, TV. Prepositions: on, in, under. Saying where things are.",
    "objectives": "Name common living-room items. Use prepositions 'on/in/under' correctly.",
    "questions": [
        q("MCQ", "What do you use to call your friends?",
          "telephone",
          ["sofa", "telephone", "rug", "TV"], 1, "comprehension"),
        q("MCQ", "Where do you usually sit to watch TV?",
          "on the sofa",
          ["under the rug", "on the sofa",
           "in the telephone", "on the TV"], 2, "application"),
        q("MCQ", "The cat is ___ the table (she sits on top).",
          "on",
          ["in", "on", "under", "next to"], 1, "production"),
        q("TRUE_FALSE", "A computer can be used to play games and study.",
          "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "A rug is something we eat.",
          "False", None, 1, "comprehension"),
        q("SHORT_ANSWER", "Translate to English: تلفاز",
          "TV", None, 1, "production"),
        q("SHORT_ANSWER", "Name one thing in your living room.",
          "sofa", None, 1, "production"),
        q("FILL_BLANK", "Complete: My ball is ___ the chair (below it).",
          "under", None, 2, "production"),
        q("FILL_BLANK", "Complete: The toys are ___ the box (inside).",
          "in", None, 1, "production"),
        q("ORDERING", "Put in order: the, sofa, on, the, cat, is",
          "the, cat, is, on, the, sofa",
          ["the", "sofa", "on", "the", "cat", "is"], 2, "application"),
        q("PRONUNCIATION", "Say: telephone",
          "telephone", None, 2, "pronunciation"),
        q("PRONUNCIATION", "Say: computer",
          "computer", None, 1, "pronunciation"),
        q("PRONUNCIATION", "Say: rug",
          "rug", None, 1, "pronunciation"),
        q("MCQ", "Your book is missing. Your mum says 'Look under the sofa'. What do you do?",
          "I look below the sofa",
          ["I look on top of the sofa",
           "I look below the sofa",
           "I look inside the TV",
           "I sit on the sofa"], 3, "application"),
    ],
    "imageUrls": [],
}

# ===========================================================================
# Unit 8: My town
# ===========================================================================
UNIT_8 = {
    "title": "My town (Unit 8)",
    "orderIndex": 8,
    "content": "Town places: mosque, church, shop, school, park, playground, house. Prepositions: next to, between. Saying where places are.",
    "objectives": "Name places in town. Use 'next to' and 'between' to describe locations.",
    "questions": [
        q("MCQ", "Where do Muslims pray?",
          "mosque",
          ["shop", "mosque", "park", "school"], 1, "comprehension"),
        q("MCQ", "Where do children play games and run?",
          "playground",
          ["shop", "playground", "church", "house"], 1, "comprehension"),
        q("MCQ", "The library is ___ the school (right beside it).",
          "next to",
          ["between", "next to", "in", "under"], 2, "production"),
        q("TRUE_FALSE", "A park usually has trees and benches.",
          "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "A shop is where we go to sleep.",
          "False", None, 1, "comprehension"),
        q("SHORT_ANSWER", "Translate to English: متجر",
          "shop", None, 1, "production"),
        q("SHORT_ANSWER", "Name one place in your town that you visit on Fridays.",
          "mosque", None, 2, "production"),
        q("FILL_BLANK", "Complete: The park is ___ the school and the church.",
          "between", None, 2, "production"),
        q("FILL_BLANK", "Complete: I live in a ___ with my family.",
          "house", None, 1, "production"),
        q("ORDERING", "Put in order: school, the, the, next to, is, mosque",
          "the, school, is, next to, the, mosque",
          ["school", "the", "the", "next to", "is", "mosque"], 3, "application"),
        q("PRONUNCIATION", "Say: playground",
          "playground", None, 2, "pronunciation"),
        q("PRONUNCIATION", "Say: mosque",
          "mosque", None, 1, "pronunciation"),
        q("PRONUNCIATION", "Say: church",
          "church", None, 1, "pronunciation"),
        q("MCQ", "On the map, the park is between two places. Which sentence is correct?",
          "The park is between the church and the school.",
          ["The park is in the church.",
           "The park is between the church and the school.",
           "The park is under the school.",
           "The park is on the playground."], 3, "application"),
    ],
    "imageUrls": [],
}

# ===========================================================================
# Unit 9: Revision (Units 6-8)
# ===========================================================================
UNIT_9 = {
    "title": "Revision Units 6-8 (Unit 9)",
    "orderIndex": 9,
    "content": "Review: action commands, negative commands, living-room items, town places, prepositions.",
    "objectives": "Review the language and vocabulary from Units 6-8.",
    "questions": [
        q("MCQ", "Which one is NOT an action?",
          "rug",
          ["jump", "clap", "hop", "rug"], 1, "recognition"),
        q("MCQ", "Which item is in a living room, NOT in a town?",
          "sofa",
          ["mosque", "sofa", "playground", "shop"], 2, "recognition"),
        q("MCQ", "The ball is ___ the rug (above it).",
          "on",
          ["on", "in", "under", "between"], 1, "production"),
        q("TRUE_FALSE", "We say 'Don't go there' to stop someone from leaving.",
          "True", None, 1, "comprehension"),
        q("TRUE_FALSE", "A computer is a place in town.",
          "False", None, 1, "comprehension"),
        q("SHORT_ANSWER", "Translate to English: حديقة",
          "park", None, 1, "production"),
        q("SHORT_ANSWER", "What word means 'don't speak'?",
          "be quiet", None, 2, "production"),
        q("FILL_BLANK", "Complete: My toys are ___ the box (inside).",
          "in", None, 1, "production"),
        q("FILL_BLANK", "Complete: The shop is ___ to the mosque.",
          "next", None, 2, "production"),
        q("ORDERING", "Put in order: please, be, quiet, !",
          "be, quiet, please, !",
          ["please", "be", "quiet", "!"], 2, "application"),
        q("PRONUNCIATION", "Say: shop",
          "shop", None, 1, "pronunciation"),
        q("PRONUNCIATION", "Say: open",
          "open", None, 1, "pronunciation"),
        q("MCQ", "Sami is in the park with his sister, between the mosque and the school. Which sentence is true?",
          "Sami is between the mosque and the school.",
          ["Sami is in the school.",
           "Sami is in the mosque.",
           "Sami is between the mosque and the school.",
           "Sami is under the park."], 3, "application"),
    ],
    "imageUrls": [],
}


# ===========================================================================
# Assembly
# ===========================================================================
LESSONS = [UNIT_1, UNIT_2, UNIT_3, UNIT_4, UNIT_5,
           UNIT_6, UNIT_7, UNIT_8, UNIT_9]


def main():
    write_curriculum(subject_code="en", grade=2, semester=1, lessons=LESSONS)


if __name__ == "__main__":
    main()

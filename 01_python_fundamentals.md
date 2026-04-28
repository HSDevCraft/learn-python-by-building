# Module 01 — Python Fundamentals

> **Level:** Beginner | **Estimated Time:** 6 hours | **Prerequisites:** None

---

## Learning Objectives

By the end of this module you will be able to:
- Explain exactly how Python executes code (interpreter pipeline, REPL, scripts)
- Declare variables and deeply understand Python's dynamic typing model
- Use all primitive data types correctly: `int`, `float`, `str`, `bool`, `NoneType`
- Apply arithmetic, comparison, logical, and bitwise operators with confidence
- Control program flow with `if/elif/else`, `for`, `while`, `break`, `continue`, `pass`
- Write readable code following PEP 8 naming conventions
- Understand mutability vs immutability at the memory level with visual diagrams

---

## 1.1 How Python Works

### The Big Picture — Analogy First

Think of Python like a **translator at the United Nations**. You speak in Python (your native language). The translator converts your words into a simpler internal language (bytecode) that the UN's systems (the Python Virtual Machine) can process. This translation happens every time you run a script.

Compare this to compiled languages like C++, where you hire a translator up-front who permanently converts your speech into machine-level instructions. The compiled approach is faster to execute but inflexible — you cannot change your speech after it has been compiled. Python's "translate at runtime" approach is slower but lets you modify and run code instantly.

### The Execution Pipeline

When you run `python script.py`, here is **exactly** what happens step by step:

```
Your .py file
     │
     ▼
[1] Lexer (Tokenizer)
     │   Breaks source code into tokens: keywords, names, symbols
     │   "x = 42 + 1"  →  [NAME:'x', OP:'=', NUMBER:42, OP:'+', NUMBER:1]
     ▼
[2] Parser
     │   Converts token stream into an Abstract Syntax Tree (AST)
     │   The AST is a tree structure that captures the grammar of your program
     ▼
[3] Compiler
     │   Walks the AST and emits bytecode instructions
     │   Bytecode is saved to __pycache__/*.pyc (speeds up next run)
     ▼
[4] Python Virtual Machine (PVM)
     │   Executes bytecode instructions one by one
     │   Manages the call stack, heap, and garbage collection
     ▼
  Output / Side Effects
```

> **Why does Python cache `.pyc` files?**  
> Parsing and compiling source to bytecode takes time. On subsequent runs, if the source file has not changed, Python skips steps 1–3 and loads the bytecode directly — making startup faster.

### The REPL — Your Playground

REPL stands for **Read → Evaluate → Print → Loop**. It is Python's interactive shell, ideal for experimenting with small snippets without writing a full script.

```bash
$ python                    # launch the REPL (or 'python3' on some systems)
>>> 2 + 2                   # Python reads this expression
4                           # evaluates and prints the result
>>> "hello".upper()         # calling a string method
'HELLO'
>>> type(42)                # inspecting the type of an object
<class 'int'>
>>> quit()                  # exit the REPL
```

**Practical rule:** Use the REPL to:
- Test a single line before putting it in your script
- Explore what methods an object has (`dir(some_object)`)
- Quickly verify behaviour of built-in functions

Use `.py` files for code you want to save and reuse.

---

## 1.2 Variables and the Python Memory Model

### The Core Mental Model — Labels, Not Boxes

Most programming languages (C, Java) treat variables as **boxes** — named storage locations that hold a value.

Python is fundamentally different: **variables are labels (references) that point to objects in memory**.

```
C/Java mental model:         Python mental model:
┌─────────────┐              ┌─────────┐
│  x  │  42  │              │    x ───┼──► [int object: 42]
└─────────────┘              └─────────┘
  box holds value              label points to object
```

This distinction matters enormously. Let's trace through an example step by step:

```python
x = 42      # Step 1: Python creates an int object with value 42.
            #         The label 'x' is bound to that object.
            #
            #   x ──► [int: 42]   (object lives somewhere in memory)

y = x       # Step 2: 'y' is bound to the SAME object that 'x' points to.
            #         No new object is created — both labels share one object.
            #
            #   x ──► [int: 42] ◄── y

x = 100     # Step 3: A NEW int object 100 is created.
            #         'x' is rebound to the new object.
            #         'y' still points to the original object 42.
            #
            #   x ──► [int: 100]
            #   y ──► [int: 42]    ← unchanged

print(y)    # Output: 42
            # Because 'y' never moved — it still labels the object 42.
```

### Proving It with `id()`

Every Python object has a unique identity — think of it as the object's memory address. Use `id()` to inspect it:

```python
x = 42
y = x

# Both labels point to the same memory address
print(id(x))        # e.g., 140593728001200
print(id(y))        # same number as id(x)
print(id(x) == id(y))  # True — same object

x = 100             # rebind x to a new object
print(id(x))        # DIFFERENT address now
print(id(y))        # same as before — y is unchanged
```

### Every Object Has Three Properties

```python
name = "Alice"

print(id(name))       # Identity: unique integer (memory address)
                      # e.g., 2145732819248

print(type(name))     # Type: what kind of object it is
                      # <class 'str'>

print(name)           # Value: the data the object stores
                      # Alice
```

### Naming Conventions (PEP 8)

PEP 8 is Python's official style guide. Following it makes your code immediately readable to any Python developer. Here are the naming conventions with the reasoning behind each:

| Use Case | Convention | Example | Why? |
|----------|-----------|---------|------|
| Variables, functions | `snake_case` | `user_name`, `get_total` | Lowercase words are easy to scan; underscores separate them visually |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRIES = 3` | ALL CAPS signals "do not reassign this" |
| Classes | `PascalCase` | `UserAccount` | Capitalised words make class names stand out |
| Private (by convention) | `_leading_underscore` | `_cache` | Single underscore = "internal use, not part of public API" |
| Name-mangling | `__double_underscore` | `__secret` | Double underscore triggers Python's name-mangling mechanism |

```python
# GOOD naming — intention is instantly clear
max_login_attempts = 3          # a count
user_email = "alice@example.com"  # a string representing an email address
IS_PRODUCTION = False           # a flag, treated as a constant

# BAD naming — forces the reader to guess what these mean
MaxAttempts = 5                 # looks like a class (PascalCase)
a = 5                           # meaningless; reader cannot infer purpose
string1 = "alice@example.com"   # named after the TYPE, not the PURPOSE
```

---

## 1.3 Data Types

### Integers (`int`)

Python integers have **arbitrary precision** — they can be as large as your computer's memory allows. Unlike C's `int` (32-bit), Python never overflows.

```python
# Regular integer literals
count = 100
negative = -42

# Underscores as visual separators — Python ignores them
population = 8_100_000_000     # same as 8100000000; much easier to read
salary = 1_00_000              # Indian numbering style works too

# Other base literals — all stored as regular ints internally
binary     = 0b1010            # 0b prefix → binary; value is 10
hexadecimal = 0xFF             # 0x prefix → hex; value is 255
octal      = 0o17              # 0o prefix → octal; value is 15

# Python arithmetic never overflows
huge = 10 ** 100               # a googol — works perfectly
print(huge)                    # 10000000...0 (101 digits)

# Useful built-in operations on integers
print(abs(-42))                # 42 — absolute value
print(divmod(17, 5))           # (3, 2) — quotient AND remainder at once
print(pow(2, 10))              # 1024 — same as 2 ** 10
print(pow(2, 10, 1000))        # 24  — modular exponentiation: (2^10) % 1000
```

### Floats (`float`)

Floats represent decimal numbers using the **IEEE 754 double-precision** standard (64 bits total: 1 sign + 11 exponent + 52 mantissa).

```python
pi = 3.14159
temperature = -273.15
scientific = 1.5e-3            # 1.5 × 10⁻³ = 0.0015  (scientific notation)
large = 6.022e23               # Avogadro's number

# Special float values
import math
print(math.inf)                # infinity
print(-math.inf)               # negative infinity
print(math.nan)                # Not a Number — result of invalid operations
print(math.isnan(math.nan))    # True — check for NaN with isnan, not ==
```

**The Floating-Point Trap — Every Developer Needs to Know This:**

```python
# This is one of the most common sources of bugs in any language!
result = 0.1 + 0.2
print(result)                       # 0.30000000000000004  ← NOT 0.3!
print(0.1 + 0.2 == 0.3)            # False  ← dangerous if used in conditions

# WHY does this happen?
# 0.1 in binary is 0.0001100110011... (repeating forever)
# Just like 1/3 in decimal is 0.3333... (repeating forever)
# The computer truncates it to 52 bits, introducing a tiny rounding error.
# When you add two truncated numbers, the errors accumulate.

# FIX 1: Use math.isclose() for float comparisons
import math
print(math.isclose(0.1 + 0.2, 0.3))         # True
print(math.isclose(0.1 + 0.2, 0.3, rel_tol=1e-9))  # True (explicit tolerance)

# FIX 2: Use the decimal module for financial/exact calculations
from decimal import Decimal, ROUND_HALF_UP

price1 = Decimal("0.10")           # ALWAYS pass strings to Decimal, not floats
price2 = Decimal("0.20")           # Decimal("0.1") is exact; Decimal(0.1) is not!
total = price1 + price2
print(total)                        # 0.30  — exact!

# Rounding with Decimal
amount = Decimal("2.675")
rounded = amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
print(rounded)                      # 2.68
```

### Strings (`str`)

Strings are **immutable sequences of Unicode characters**. "Immutable" means once a string is created, you cannot change it in place — any operation that looks like it modifies a string actually creates a new one.

```python
# Three ways to write string literals
single   = 'Hello'                  # single quotes
double   = "World"                  # double quotes (prefer for most cases)
multiline = """
Line one
Line two
Line three
"""                                 # triple quotes preserve newlines

# Raw strings — backslashes are treated literally (great for file paths and regex)
windows_path = r"C:\Users\Alice\Documents"   # r prefix = raw string
regex_pattern = r"\d{3}-\d{4}"              # \d and \{ are literal characters

# f-strings (formatted string literals — Python 3.6+)
# The f prefix lets you embed ANY Python expression inside {}
name = "Alice"
age = 30
score = 98.765

print(f"Hello, {name}!")                    # embed a variable
print(f"Next year: {age + 1}")              # embed an expression
print(f"Name upper: {name.upper()}")        # embed a method call
print(f"Score: {score:.2f}")                # format float to 2 decimal places
print(f"Score: {score:>10.2f}")             # right-align in a field of width 10
print(f"Count: {1_000_000:,}")              # add thousand separators → 1,000,000
print(f"Binary: {42:08b}")                  # 42 in binary, zero-padded to 8 bits

# Strings are immutable — this creates a NEW string, not modifying 'greeting'
greeting = "hello"
upper_greeting = greeting.upper()           # new string "HELLO"
print(greeting)                             # still "hello" — unchanged

# Essential string methods
text = "  Hello, World!  "
print(text.strip())                         # "Hello, World!"   — remove whitespace
print(text.lstrip())                        # "Hello, World!  " — left only
print(text.rstrip())                        # "  Hello, World!" — right only
print(text.lower())                         # "  hello, world!  "
print(text.upper())                         # "  HELLO, WORLD!  "
print(text.replace("World", "Python"))      # "  Hello, Python!  "
print("hello".startswith("he"))             # True
print("hello".endswith("lo"))               # True
print("hello world".capitalize())           # "Hello world"
print("hello world".title())                # "Hello World"
print(",".join(["a", "b", "c"]))            # "a,b,c"  — join list elements
print("a,b,c".split(","))                   # ['a', 'b', 'c']  — split into list
print("hello".find("ll"))                   # 2  — index of first match (-1 if not found)
print("hello".count("l"))                   # 2  — count occurrences

# Indexing and slicing — strings behave like lists of characters
s = "Python"
#    P  y  t  h  o  n
#    0  1  2  3  4  5   ← positive indices
#   -6 -5 -4 -3 -2 -1   ← negative indices (count from the end)

print(s[0])             # 'P'   — first character
print(s[-1])            # 'n'   — last character (negative index)
print(s[1:4])           # 'yth' — slice: indices 1, 2, 3 (4 is excluded)
print(s[2:])            # 'thon' — from index 2 to the end
print(s[:3])            # 'Pyt'  — from start up to (not including) index 3
print(s[::2])           # 'Pto'  — every 2nd character
print(s[::-1])          # 'nohtyP' — step=-1 reverses the string
```

### Booleans (`bool`)

`True` and `False` are the only boolean values. Importantly, `bool` is a **subclass of `int`**: `True == 1` and `False == 0`.

```python
is_admin = True
is_deleted = False

# Since bool is a subclass of int, you can do arithmetic with booleans
print(True + True)      # 2
print(True * 10)        # 10
print(False + 1)        # 1
# This is occasionally useful for counting: sum(is_even(x) for x in numbers)

# Truthiness — Python evaluates ANY object in a boolean context
# The rule: an object is "falsy" if it represents emptiness or zero.
# FALSY values (evaluate to False):
print(bool(False))      # False — the boolean False
print(bool(None))       # False — the null value
print(bool(0))          # False — integer zero
print(bool(0.0))        # False — float zero
print(bool(""))         # False — empty string
print(bool([]))         # False — empty list
print(bool({}))         # False — empty dict
print(bool(set()))      # False — empty set
print(bool(()))         # False — empty tuple

# TRUTHY values (evaluate to True): everything else
print(bool(1))          # True — any non-zero number
print(bool(-42))        # True — negative numbers are truthy
print(bool("hi"))       # True — any non-empty string
print(bool([0]))        # True — list with one item (even if item is 0!)
print(bool({"a": 1}))  # True — any non-empty dict

# PYTHONIC use of truthiness:
items = []
if not items:                       # reads naturally: "if not items..."
    print("The list is empty")

# NON-PYTHONIC (avoid):
if len(items) == 0:                 # verbose and unnecessary
    print("The list is empty")
if items == []:                     # even more verbose
    print("The list is empty")
```

### None (`NoneType`)

`None` is Python's way of representing "no value" or "absence of a result". It is a **singleton** — there is only one `None` object in the entire Python runtime.

```python
# None is used as:
# 1. Default "empty" return value for functions that produce no output
# 2. A sentinel value meaning "not yet set" or "not applicable"
# 3. Default argument values

result = None               # not yet computed

# CORRECT: compare with 'is' because None is a singleton
# There is only ONE None object, so identity check is the right test.
if result is None:
    print("No result yet")

if result is not None:
    print(f"Got: {result}")

# WRONG: using '==' works but is misleading and slightly slower
if result == None:          # works, but not the Python way
    print("Don't do this")

# Functions return None when there is no explicit return
def print_hello(name: str) -> None:
    print(f"Hello, {name}")     # side effect: printing
    # no return statement → implicitly returns None

output = print_hello("Alice")   # prints "Hello, Alice"
print(output)                   # None — the function returned nothing
print(type(output))             # <class 'NoneType'>
```

---

## 1.4 Operators

### Arithmetic Operators

```python
a, b = 10, 3    # multiple assignment in one line

# Basic arithmetic
print(a + b)    # 13  — addition
print(a - b)    # 7   — subtraction
print(a * b)    # 30  — multiplication
print(a / b)    # 3.3333...  — TRUE division (ALWAYS returns float, even if divisible)
print(a // b)   # 3   — FLOOR division: divides then rounds DOWN to nearest integer
print(a % b)    # 1   — modulo: the remainder after floor division
print(a ** b)   # 1000 — exponentiation: 10³

# CRITICAL detail about floor division vs true division:
print(7 / 2)    # 3.5   — true division
print(7 // 2)   # 3     — floor division (not truncation! — important for negatives)
print(-7 // 2)  # -4    — floor is -4, NOT -3 (floors TOWARDS negative infinity)
print(-7 / 2)   # -3.5  — true division

# Modulo with negatives follows the same floor-division rule:
print(7 % 3)    # 1   — (7 = 2*3 + 1)
print(-7 % 3)   # 2   — (-7 = -3*3 + 2, because floor(-7/3) = -3)

# Practical modulo uses:
print(15 % 2 == 0)      # False  — is 15 even?
print(15 % 3 == 0)      # True   — is 15 divisible by 3?
hour = 14
print(f"3 hours later: {(hour + 3) % 24}:00")  # 17:00  — clock arithmetic
```

### Comparison Operators

```python
x = 5

print(x > 3)    # True   — greater than
print(x >= 5)   # True   — greater than or equal
print(x < 10)   # True   — less than
print(x <= 4)   # False  — less than or equal
print(x == 5)   # True   — equal in value
print(x != 3)   # True   — not equal

# Python's chained comparisons — unique and very readable
# "is age between 18 and 65 (exclusive)?"
age = 25
print(18 <= age < 65)           # True
# This is equivalent to: (18 <= age) and (age < 65)
# Python evaluates each link once, efficiently

# Chained equality:
a = b = c = 5
print(a == b == c)              # True — all equal
```

### Logical Operators and Short-Circuit Evaluation

```python
# 'and' returns the first FALSY value it encounters,
#         or the last value if ALL are truthy
print(True and True)    # True   — both truthy, returns last value
print(True and False)   # False  — second is falsy, returns it
print(False and True)   # False  — first is falsy, stops here (short-circuit)
print(1 and 2)          # 2      — both truthy, returns the last one
print(0 and 2)          # 0      — first is falsy, stops immediately

# 'or' returns the first TRUTHY value it encounters,
#        or the last value if ALL are falsy
print(True or False)    # True   — first is truthy, stops immediately
print(False or True)    # True   — second is truthy, returns it
print(False or False)   # False  — all falsy, returns last
print(0 or 42)          # 42     — first is falsy, second is truthy
print(0 or "")          # ""     — all falsy, returns last

# 'not' inverts the boolean value
print(not True)         # False
print(not False)        # True
print(not 0)            # True  — 0 is falsy, not falsy = truthy
print(not [])           # True  — empty list is falsy

# Short-circuit evaluation saves time (and prevents errors):
# Python stops evaluating as soon as the result is determined.
def check_db() -> bool:
    print("  → checking database...")   # expensive or side-effect-ful
    return True

# Because False makes 'and' definitely False, check_db() never runs:
result = False and check_db()           # check_db() NOT called
print(result)                           # False  (no "checking database..." printed)

# Because True makes 'or' definitely True, check_db() never runs:
result = True or check_db()             # check_db() NOT called
print(result)                           # True

# PRACTICAL USE — safe default values with 'or':
user_input = ""                         # simulating empty input
name = user_input or "Anonymous"        # if user_input is falsy, use "Anonymous"
print(name)                             # "Anonymous"

# PRACTICAL USE — guard before calling a method:
config = None
value = config and config.get("key")    # if config is None, short-circuit to None
                                        # avoids AttributeError on None.get()
```

### Identity and Membership Operators

```python
# 'is' — checks if two variables point to the SAME object in memory
# '==' — checks if two objects have the SAME VALUE

a = [1, 2, 3]
b = a               # b and a point to the SAME list object
c = [1, 2, 3]       # c is a DIFFERENT list object with the same values

print(a is b)       # True  — same object (same id())
print(a is c)       # False — different objects (different id()), even though values match
print(a == c)       # True  — same VALUES

# WHEN TO USE WHICH:
# Use 'is' only for: None, True, False (singletons)
# Use '==' for: comparing values of strings, lists, dicts, etc.

x = None
if x is None:       # CORRECT
    print("No value")
if x == None:       # WORKS but misleading — prefer 'is'
    print("No value")

# 'in' — checks membership (works on any iterable)
fruits = ["apple", "banana", "cherry"]
print("apple" in fruits)        # True
print("grape" in fruits)        # False
print("grape" not in fruits)    # True

# 'in' also works on strings (substring check), dicts (key check), sets
print("py" in "python")         # True — substring
config = {"debug": True, "port": 8080}
print("debug" in config)        # True — checks KEYS, not values
print(8080 in config)           # False — 8080 is a value, not a key
print(8080 in config.values())  # True  — check values explicitly
```

### Assignment Operators

```python
count = 10

count += 5      # count = count + 5  →  15
print(count)    # 15

count -= 3      # count = count - 3  →  12
print(count)    # 12

count *= 2      # count = count * 2  →  24
print(count)    # 24

count //= 5     # count = count // 5 →  4  (floor division)
print(count)    # 4

count **= 3     # count = count ** 3 →  64
print(count)    # 64

count %= 10     # count = count % 10 →  4
print(count)    # 4
```

---

## 1.5 Control Flow

### if / elif / else — Decision Making

Think of `if/elif/else` as a **decision tree**. Python evaluates each condition in order and executes only the FIRST branch whose condition is `True`. All other branches are skipped.

```python
def classify_bmi(bmi: float) -> str:
    """
    Classify BMI into WHO standard health categories.

    Python evaluates from top to bottom and stops at the first True condition.
    The ORDER of the conditions matters — each elif assumes all previous
    conditions were False.
    """
    if bmi < 0:                 # guard clause: catch invalid input first
        return "Invalid BMI"
    elif bmi < 18.5:            # we now KNOW bmi >= 0 (previous was False)
        return "Underweight"
    elif bmi < 25.0:            # we now KNOW bmi >= 18.5
        return "Normal weight"
    elif bmi < 30.0:            # we now KNOW bmi >= 25.0
        return "Overweight"
    else:                       # we now KNOW bmi >= 30.0 — catch-all
        return "Obese"

print(classify_bmi(22.1))       # Normal weight
print(classify_bmi(31.5))       # Obese
print(classify_bmi(-5))         # Invalid BMI
```

### Ternary Expression (Conditional Expression)

The ternary expression lets you write a simple if/else in a single line. Only use it when it improves readability.

```python
# Syntax: <value_if_true> if <condition> else <value_if_false>
score = 75
result = "Pass" if score >= 50 else "Fail"
print(result)                   # Pass

# GOOD use: simple, fits on one line, self-explanatory
label = "even" if number % 2 == 0 else "odd"

# BAD use: too complex — break it into a full if/else block
# category = "A" if x > 90 else "B" if x > 80 else "C" if x > 70 else "F"
# ↑ Hard to read — avoid chaining ternaries
```

### for Loops — Iterating Over Sequences

A `for` loop in Python works differently from C/Java. Instead of managing an index counter, Python's `for` loop asks the collection to produce items one by one. This is called the **iterator protocol**.

```python
# Basic iteration — Python gives you each item directly
fruits = ["apple", "banana", "cherry"]
for fruit in fruits:
    print(fruit)
# apple
# banana
# cherry

# range() generates a sequence of integers on demand (memory-efficient)
# range(stop)          → 0, 1, ..., stop-1
# range(start, stop)   → start, start+1, ..., stop-1
# range(start, stop, step)  → start, start+step, ..., up to stop

for i in range(5):              # 0, 1, 2, 3, 4
    print(i, end=" ")
print()                         # newline

for i in range(1, 6):           # 1, 2, 3, 4, 5
    print(i, end=" ")
print()

for i in range(0, 10, 2):       # 0, 2, 4, 6, 8  (step=2)
    print(i, end=" ")
print()

for i in range(10, 0, -1):      # 10, 9, 8, ..., 1  (step=-1, counting down)
    print(i, end=" ")
print()

# enumerate() — when you need BOTH the index AND the value
# Without enumerate (bad practice):
for i in range(len(fruits)):
    print(f"{i}: {fruits[i]}")  # verbose and error-prone

# With enumerate (Pythonic):
for index, fruit in enumerate(fruits):          # starts at 0 by default
    print(f"{index}: {fruit}")

for index, fruit in enumerate(fruits, start=1): # start counting from 1
    print(f"{index}. {fruit}")
# 1. apple
# 2. banana
# 3. cherry

# zip() — pair up two iterables element by element
# Think of it like a zipper on a jacket: it joins two separate sides together
names  = ["Alice", "Bob", "Carol"]
scores = [92,      85,    78     ]

for name, score in zip(names, scores):
    # zip produces tuples: ("Alice", 92), ("Bob", 85), ("Carol", 78)
    print(f"{name}: {score}")
# Alice: 92
# Bob: 85
# Carol: 78

# zip stops at the SHORTEST iterable
letters = ["a", "b", "c"]
numbers = [1, 2, 3, 4, 5]              # longer than letters
for letter, number in zip(letters, numbers):
    print(letter, number)              # only 3 pairs: (a,1), (b,2), (c,3)

# zip_longest (from itertools) pads with a fill value instead
from itertools import zip_longest
for letter, number in zip_longest(letters, numbers, fillvalue="?"):
    print(letter, number)              # (a,1), (b,2), (c,3), (?,4), (?,5)
```

### while Loops — Condition-Based Repetition

Use `for` when you know the number of iterations. Use `while` when you repeat **until a condition changes** — and you don't know in advance how many iterations that will take.

```python
# Pattern: keep looping while a condition is True

# Example 1: Input validation — keep asking until the user gives valid input
def get_positive_number() -> float:
    """
    Repeatedly prompt the user until they enter a positive number.
    We can't use a 'for' loop here because we don't know how many
    bad inputs the user will give before providing a valid one.
    """
    while True:                             # loop forever until we explicitly break
        try:
            value = float(input("Enter a positive number: "))
            if value > 0:
                return value                # exit the function (and the loop)
            print("Must be positive. Try again.")
        except ValueError:
            print("That's not a number. Try again.")

# Example 2: Password attempts — limited retries
attempts = 0                                # track how many tries have been made
max_attempts = 3                            # the limit we set

while attempts < max_attempts:              # condition checked BEFORE each iteration
    user_input = input("Enter password: ")

    if user_input == "secret":              # correct password
        print("Access granted!")
        break                               # exit the loop early
    else:
        attempts += 1                       # count this failed attempt
        remaining = max_attempts - attempts
        if remaining > 0:
            print(f"Wrong password. {remaining} attempt(s) remaining.")
else:
    # The 'else' on a while loop runs ONLY if the condition became False naturally
    # (i.e., the loop was NOT exited via 'break')
    # This is a very useful Python feature — use it to detect "no break occurred"
    print("Too many failed attempts. Account locked.")

# Example 3: Processing a queue until empty
queue = [3, 1, 4, 1, 5, 9]             # simulated work queue

while queue:                            # Pythonic: 'while queue' is True until queue is empty
    item = queue.pop(0)                 # remove and get the first item
    print(f"Processing item: {item}")
# Processes all 6 items then stops because queue is [] (falsy)
```

### break, continue, pass — Fine-Grained Loop Control

```python
# ──────────────────────────────────────────────────────────────────────────
# break — immediately exit the entire loop
# ──────────────────────────────────────────────────────────────────────────
# USE CASE: searching — stop as soon as you find what you need
numbers = [4, 7, 2, 9, 1, 5, 8]
target = 9

for i, num in enumerate(numbers):
    if num == target:
        print(f"Found {target} at index {i}")
        break                           # no point checking further
    # If we reach here, this number wasn't the target
else:
    # else runs only if we finished the loop WITHOUT breaking
    # meaning: target was NOT found
    print(f"{target} not in the list")

# ──────────────────────────────────────────────────────────────────────────
# continue — skip the REST of this iteration and go to the next one
# ──────────────────────────────────────────────────────────────────────────
# USE CASE: filtering — skip items that don't meet a condition
data = [10, -3, 7, -1, 0, 4, -8, 2]

print("Positive numbers only:")
for n in data:
    if n <= 0:
        continue        # skip non-positive numbers; jump to next iteration
    # Only reach here if n > 0
    print(n, end=" ")  # 10 7 4 2
print()

# ──────────────────────────────────────────────────────────────────────────
# pass — do nothing (syntactic placeholder)
# ──────────────────────────────────────────────────────────────────────────
# Python requires a body in every block (if, for, while, class, def).
# 'pass' satisfies this requirement without doing anything.
# USE CASE: stub out code you'll fill in later

def process_payment(amount: float) -> None:
    pass        # TODO: implement payment logic

class DatabaseConnection:
    pass        # TODO: add attributes and methods

for _ in range(5):
    pass        # deliberate no-op loop (rarely needed)

# The difference between break, continue, and pass:
# break    → exit the loop completely
# continue → skip to the next iteration
# pass     → do nothing, continue normally (as if the line wasn't there)
```

---

## 1.6 Type Conversion

Python is **strongly typed** — it will never silently convert types for you the way JavaScript does. All type conversions must be explicit.

```python
# ──────────────────────────────────────────────────────────────────────────
# String → Number conversions
# ──────────────────────────────────────────────────────────────────────────
num_str = "42"
num_int = int(num_str)      # "42" (str) → 42 (int)
print(num_int + 1)          # 43  — now we can do arithmetic

price_str = "19.99"
price = float(price_str)    # "19.99" (str) → 19.99 (float)
print(price * 1.1)          # 21.989 — 10% markup

# Common mistake: int() on a float-formatted string will FAIL
# int("19.99")              # ValueError: invalid literal for int()
# FIX: convert to float first, then to int
value = int(float("19.99"))  # "19.99" → 19.99 → 19 (truncates decimal)
print(value)                 # 19

# ──────────────────────────────────────────────────────────────────────────
# Number → String conversion
# ──────────────────────────────────────────────────────────────────────────
age = 25
age_str = str(age)          # 25 (int) → "25" (str)
print("Age: " + age_str)    # "Age: 25" — can now concatenate

# Python will NOT implicitly convert:
# print("Age: " + 25)       # TypeError: can only concatenate str (not "int") to str
# You MUST convert explicitly:
print("Age: " + str(25))    # Works fine
print(f"Age: {25}")         # Even better: f-strings handle conversion automatically

# ──────────────────────────────────────────────────────────────────────────
# int() truncation vs rounding
# ──────────────────────────────────────────────────────────────────────────
print(int(3.9))     # 3  — truncates towards zero, does NOT round
print(int(-3.9))    # -3 — truncates towards zero (not -4!)
print(round(3.9))   # 4  — rounds to nearest integer
print(round(3.5))   # 4  — Python uses "banker's rounding" (round half to even)
print(round(2.5))   # 2  — 2 is even, so 2.5 rounds to 2 (not 3!)

# ──────────────────────────────────────────────────────────────────────────
# bool() conversion — any type to boolean
# ──────────────────────────────────────────────────────────────────────────
print(bool(0))      # False — zero int
print(bool(0.0))    # False — zero float
print(bool(""))     # False — empty string
print(bool([]))     # False — empty list
print(bool(None))   # False — None
print(bool(1))      # True  — non-zero
print(bool("hi"))   # True  — non-empty string
print(bool([0]))    # True  — list with one element (even if element is 0)

# ──────────────────────────────────────────────────────────────────────────
# list(), tuple(), set() — converting between collection types
# ──────────────────────────────────────────────────────────────────────────
my_tuple = (1, 2, 3, 2, 1)
my_list  = list(my_tuple)   # (1,2,3,2,1) → [1,2,3,2,1]  (mutable)
my_set   = set(my_tuple)    # (1,2,3,2,1) → {1,2,3}      (unique, unordered)

print(my_list)              # [1, 2, 3, 2, 1]
print(my_set)               # {1, 2, 3}  — duplicates removed

# Converting a string to a list of characters:
chars = list("hello")       # "hello" → ['h', 'e', 'l', 'l', 'o']
print(chars)
```

---

## Best Practices

### 1. Name Variables After What They Represent, Not Their Type

```python
# BAD — type-based names force the reader to remember what 's' means
s = "Alice"
lst = [85, 92, 78]
d = {"name": "Alice", "score": 85}

# GOOD — purpose-based names tell a story
student_name = "Alice"
exam_scores = [85, 92, 78]
student_record = {"name": "Alice", "score": 85}
```

### 2. One Statement Per Line

```python
# BAD — semicolons squeeze multiple statements on one line
x = 1; y = 2; z = x + y

# GOOD — each statement on its own line
x = 1
y = 2
z = x + y
```

### 3. Use `is` for `None`, `==` for Values

```python
result = None

if result is None:      # CORRECT — identity check for singleton
    compute()

if result == None:      # WORKS but style violation (linters will warn you)
    compute()
```

### 4. Replace Magic Numbers with Named Constants

```python
# BAD — the reader has no idea what 3 means
if attempts >= 3:
    lock_account()

# GOOD — the constant name explains the meaning
MAX_LOGIN_ATTEMPTS = 3
if attempts >= MAX_LOGIN_ATTEMPTS:
    lock_account()
```

### 5. Prefer f-strings for All String Formatting

```python
name = "Alice"
score = 98.5

# BAD — old-style % formatting (legacy, cryptic)
print("Hello, %s! Score: %.1f" % (name, score))

# BAD — .format() is verbose
print("Hello, {}! Score: {:.1f}".format(name, score))

# GOOD — f-string: clean, readable, and supports arbitrary expressions
print(f"Hello, {name}! Score: {score:.1f}")
```

### 6. Use `math.isclose()` for Float Comparisons

```python
import math

# BAD — direct equality on floats
if 0.1 + 0.2 == 0.3:                           # False! (bug)
    print("equal")

# GOOD — tolerance-based comparison
if math.isclose(0.1 + 0.2, 0.3, rel_tol=1e-9):  # True
    print("close enough to be considered equal")
```

---

## Exercises

### Exercise 1.1 — Temperature Converter (Beginner)

**Problem:** Write a program that converts Celsius to Fahrenheit and Kelvin.  
**Formulas:** `F = C × 9/5 + 32`, `K = C + 273.15`  
**Test with:** 0°C, 100°C, -40°C

**Solution:**
```python
def celsius_to_fahrenheit(celsius: float) -> float:
    """Convert Celsius to Fahrenheit using the standard formula."""
    return celsius * 9 / 5 + 32     # multiply by 9/5 then add 32

def celsius_to_kelvin(celsius: float) -> float:
    """Convert Celsius to Kelvin — just an offset."""
    return celsius + 273.15         # 0 Kelvin = -273.15 °C (absolute zero)

def convert_temperature(celsius: float) -> None:
    """Print all three temperature scales for a given Celsius value."""
    fahrenheit = celsius_to_fahrenheit(celsius)
    kelvin     = celsius_to_kelvin(celsius)
    # :.2f in the f-string formats the float to exactly 2 decimal places
    print(f"{celsius:6.1f}°C  =  {fahrenheit:7.2f}°F  =  {kelvin:7.2f}K")

# Test cases
convert_temperature(0)      #   0.0°C  =    32.00°F  =  273.15K
convert_temperature(100)    # 100.0°C  =   212.00°F  =  373.15K
convert_temperature(-40)    # -40.0°C  =   -40.00°F  =  233.15K
# Fun fact: -40 is the one temperature where Fahrenheit and Celsius are equal!
```

---

### Exercise 1.2 — FizzBuzz (Classic Control Flow)

**Problem:** Print numbers 1–100. For multiples of 3 print "Fizz", for multiples of 5 print "Buzz", for both print "FizzBuzz".

**Key insight:** Check `% 15 == 0` FIRST. 15 = 3 × 5, so a number divisible by both is divisible by 15. If you check `% 3` first and print "Fizz", you will never reach the FizzBuzz case.

**Solution:**
```python
def fizzbuzz(n: int) -> str:
    """
    Return the FizzBuzz label for integer n.

    Order of checks matters:
      1. Check 15 (both 3 and 5) first — most specific case
      2. Then 3
      3. Then 5
      4. Otherwise return the number as a string
    """
    if n % 15 == 0:         # divisible by both 3 AND 5 → FizzBuzz
        return "FizzBuzz"
    elif n % 3 == 0:        # divisible by 3 only → Fizz
        return "Fizz"
    elif n % 5 == 0:        # divisible by 5 only → Buzz
        return "Buzz"
    else:                   # not divisible by 3 or 5 → the number itself
        return str(n)       # convert int to str for consistent return type

for i in range(1, 101):     # range(1, 101) gives 1 through 100 (101 excluded)
    print(fizzbuzz(i))
```

---

### Exercise 1.3 — Simple Calculator (Operators)

**Problem:** Build a calculator that takes two numbers and an operator (`+`, `-`, `*`, `/`) and returns the result. Handle division by zero gracefully.

**Solution:**
```python
def calculate(a: float, b: float, operator: str) -> float | None:
    """
    Perform arithmetic on two numbers.

    Returns:
        The result as a float, or None if the operation is invalid.

    The '|' in 'float | None' is Python 3.10+ union type syntax.
    It means "this function returns either a float OR None".
    """
    if operator == "+":
        return a + b
    elif operator == "-":
        return a - b
    elif operator == "*":
        return a * b
    elif operator == "/":
        # Guard against division by zero BEFORE performing the division
        if b == 0:
            print("Error: Division by zero is undefined.")
            return None         # signal failure without crashing
        return a / b            # true division — always returns float
    else:
        # Catch any operator we don't recognise
        print(f"Error: Unknown operator '{operator}'. Use +, -, *, or /")
        return None

# Test all branches
print(calculate(10, 5, "+"))   # 15.0
print(calculate(10, 5, "-"))   # 5.0
print(calculate(10, 5, "*"))   # 50.0
print(calculate(10, 5, "/"))   # 2.0
print(calculate(10, 0, "/"))   # Error message, then None
print(calculate(7,  3, "%"))   # Error: Unknown operator
```

---

### Exercise 1.4 — Number Analysis (Intermediate)

**Problem:** Given a list of numbers, compute: min, max, sum, average, and count of even vs odd numbers.

**Solution:**
```python
def analyze_numbers(numbers: list[int]) -> None:
    """
    Print a statistical summary of a list of integers.

    Demonstrates:
    - Guard clause for empty input
    - Built-in functions: sum(), min(), max(), len()
    - List comprehension for filtering
    - f-string formatting
    """
    # Guard clause: handle the edge case of an empty list FIRST.
    # This keeps the main logic below free from "what if it's empty?" checks.
    if not numbers:             # 'not numbers' is True when numbers is []
        print("No numbers to analyze.")
        return

    # Built-in aggregate functions — clean and readable
    total   = sum(numbers)              # sum all elements
    minimum = min(numbers)              # smallest element
    maximum = max(numbers)              # largest element
    count   = len(numbers)              # how many elements
    average = total / count             # simple mean

    # List comprehensions — filter into two sublists
    evens = [n for n in numbers if n % 2 == 0]  # keep only even numbers
    odds  = [n for n in numbers if n % 2 != 0]  # keep only odd numbers

    # f-string alignment: < = left-align, > = right-align, number = field width
    print(f"{'Count:':<10} {count}")
    print(f"{'Min:':<10} {minimum}")
    print(f"{'Max:':<10} {maximum}")
    print(f"{'Sum:':<10} {total}")
    print(f"{'Average:':<10} {average:.2f}")    # 2 decimal places
    print(f"{'Evens:':<10} {len(evens)} → {evens}")
    print(f"{'Odds:':<10} {len(odds)} → {odds}")

analyze_numbers([3, 7, 2, 9, 4, 6, 1, 8, 5])
```

---

## Mini-Project — Grade Calculator

**Scenario:** A teacher needs a program that accepts student names and their exam scores (0–100), assigns letter grades, and prints a formatted class report with statistics.

**Grading scale:** A (90–100), B (80–89), C (70–79), D (60–69), F (0–59)

```python
def assign_grade(score: float) -> str:
    """
    Return the letter grade for a numeric score.

    Each elif assumes all previous conditions were False, so the ranges
    are implicitly bounded from below — no need to write 80 <= score < 90.
    """
    if score >= 90:     # 90–100
        return "A"
    elif score >= 80:   # we know score < 90, so this is 80–89
        return "B"
    elif score >= 70:   # we know score < 80, so this is 70–79
        return "C"
    elif score >= 60:   # we know score < 70, so this is 60–69
        return "D"
    else:               # we know score < 60, so this is 0–59
        return "F"


def generate_class_report(students: dict[str, float]) -> None:
    """
    Print a formatted class report with per-student grades and class statistics.

    Args:
        students: dict mapping student name → score (0.0 to 100.0)
    """
    if not students:            # guard clause: nothing to report
        print("No student data provided.")
        return

    # Print the header
    print("=" * 42)
    print(f"{'CLASS REPORT':^42}")         # ^42 = centre in 42 chars
    print("=" * 42)
    print(f"{'Name':<22} {'Score':>6} {'Grade':>6}")
    print("-" * 42)

    # sorted(students.items()) returns (name, score) pairs in alphabetical order
    for name, score in sorted(students.items()):
        grade = assign_grade(score)         # compute grade for this student
        # <22 = left-align name in 22 chars; >6.1f = right-align float with 1 decimal
        print(f"{name:<22} {score:>6.1f} {grade:>6}")

    # Compute class-wide statistics
    all_scores = list(students.values())
    class_avg  = sum(all_scores) / len(all_scores)
    top_score  = max(all_scores)
    low_score  = min(all_scores)
    # sum() with a generator: count students whose score is 60 or above
    passing_count = sum(1 for s in all_scores if s >= 60)

    print("=" * 42)
    print(f"Class Average : {class_avg:.1f}")
    print(f"Highest Score : {top_score:.1f}")
    print(f"Lowest Score  : {low_score:.1f}")
    print(f"Passing       : {passing_count}/{len(all_scores)} students")


# --- Test data ---
class_data = {
    "Alice Johnson": 94.5,
    "Bob Smith":     78.0,
    "Carol White":   85.5,
    "David Brown":   62.0,
    "Eva Green":     55.0,
    "Frank Lee":     91.0,
}

generate_class_report(class_data)
```

**Expected output:**
```
==========================================
               CLASS REPORT
==========================================
Name                   Score  Grade
------------------------------------------
Alice Johnson           94.5      A
Bob Smith               78.0      C
Carol White             85.5      B
David Brown             62.0      D
Eva Green               55.0      F
Frank Lee               91.0      A
==========================================
Class Average : 77.7
Highest Score : 94.5
Lowest Score  : 55.0
Passing       : 5/6 students
```

---

## Interview Prep — Top Questions for Python Fundamentals

> These are the most frequently asked Python fundamentals questions in technical interviews at FAANG, startups, and mid-size tech companies.

**Q1: What is the difference between `is` and `==` in Python?**
`==` compares **values** (calls `__eq__`). `is` compares **identity** (same object in memory, same `id()`). Use `is` only for `None`, `True`, `False` — never for strings or integers in general, because CPython caches small integers (-5 to 256) and interned strings, making `is` accidentally true for those.

**Q2: Why is `0.1 + 0.2 != 0.3` in Python?**
Floating-point numbers use IEEE 754 binary representation. `0.1` and `0.2` cannot be represented exactly in binary (like `1/3` can't be in decimal), so small rounding errors accumulate. Use `math.isclose(a, b, rel_tol=1e-9)` for comparisons, or `decimal.Decimal` for exact decimal arithmetic.

**Q3: What is the difference between mutable and immutable types? Give examples.**
Immutable types (int, float, str, tuple, frozenset) cannot be changed after creation. Mutable types (list, dict, set, most user-defined objects) can be modified in place. Immutable objects are safe as dict keys and set members (their hash never changes). Strings are immutable — `"hello" + "!"` creates a new string.

**Q4: How does Python manage memory?**
CPython uses **reference counting** — each object tracks how many references point to it. When the count reaches 0, memory is freed immediately. A **cyclic garbage collector** handles reference cycles (objects pointing to each other). The `gc` module controls cycle collection. `sys.getrefcount(obj)` shows the reference count.

**Q5: What are Python's built-in data types? Categorize them.**
- **Numeric**: `int`, `float`, `complex`, `bool` (bool is a subclass of int)
- **Sequence**: `str`, `list`, `tuple`, `range`, `bytes`, `bytearray`
- **Mapping**: `dict`
- **Set**: `set`, `frozenset`
- **Singleton**: `None`, `True`, `False`

**Q6: What is the difference between `list`, `tuple`, and `set`?**
- `list`: ordered, mutable, allows duplicates, O(n) membership test
- `tuple`: ordered, immutable, allows duplicates, hashable (can be dict key)
- `set`: unordered, mutable, no duplicates, O(1) membership test via hash

**Q7: What does Python's `for` loop actually do under the hood?**
`for item in obj` calls `iter(obj)` to get an iterator, then repeatedly calls `next(iterator)` until `StopIteration` is raised. Any object implementing `__iter__` and `__next__` can be iterated. This is the **iterator protocol** — the foundation of generators, comprehensions, and `itertools`.

**Q8: Explain Python's truthiness rules.**
`bool(x)` returns `False` for: `None`, `False`, `0` (any numeric zero), `""`, `[]`, `{}`, `set()`, `()` — i.e., falsy values are **empty or zero**. Everything else is truthy. Custom objects are truthy by default; override `__bool__` or `__len__` to change this. Always write `if items:` not `if len(items) > 0:`.

**Q9: What is a Python variable, really?**
A Python variable is a **name (label)** bound to an object in memory — not a box that stores a value. When you write `x = [1,2,3]; y = x`, both `x` and `y` are labels pointing to the **same list object**. Modifying through `y` is visible through `x`. This is why mutable defaults in functions are dangerous.

**Q10: What is the difference between shallow copy and deep copy?**
`copy.copy(obj)` creates a new container but references the **same inner objects** — modifying a nested list changes both. `copy.deepcopy(obj)` recursively copies all nested objects — fully independent copy. Use `deepcopy` when objects contain mutable nested structures; `copy` when inner objects are immutable (ints, strings).

---

## Module Summary

| Concept | Key Takeaway |
|---------|-------------|
| Python execution | Source → Lexer → Parser → AST → Bytecode → PVM |
| Variables | Labels pointing to objects — NOT boxes holding values |
| `id()` | Returns memory address; `is` compares identity, `==` compares value |
| `int` | Arbitrary precision; underscores for readability; never overflows |
| `float` | IEEE 754; `0.1 + 0.2 ≠ 0.3`; use `math.isclose()` or `Decimal` |
| `str` | Immutable; f-strings for formatting; slicing with `[start:stop:step]` |
| `bool` | Subclass of int; truthiness rules; use `not items` not `len(items) == 0` |
| `None` | Singleton; always use `is None`, never `== None` |
| Floor division | `//` floors towards −∞, not towards 0 (matters for negatives) |
| Modulo | Remainder follows floor division sign |
| Short-circuit | `and`/`or` stop early; use for safe defaults and guards |
| `for` vs `while` | `for` = known count; `while` = condition-based |
| `break`/`continue` | `break` exits loop; `continue` skips iteration; `else` on loops |
| Type conversion | Python is strongly typed; all conversions must be explicit |

---

## Quiz

1. What is the difference between `is` and `==` in Python? When should you use each?
2. Why does `0.1 + 0.2 == 0.3` return `False`, and how do you fix it?
3. What does `10 // 3` evaluate to? What about `-7 // 2`?
4. What is the output of `bool([])` and `bool([0])`? Explain why they differ.
5. What is the difference between `break` and `continue` inside a loop?
6. What does the `else` clause on a `while` loop mean, and when does it run?
7. Why should constants be written in `UPPER_SNAKE_CASE`?
8. What is the difference between `int("42")` and `int(42.9)`?
9. Given `a = [1,2,3]` and `b = a`, does `b is a` return `True` or `False`? Why?
10. Explain Python's short-circuit evaluation. Give a practical use case for `or`.

**Answers:**
1. `is` checks object identity (same memory address via `id()`); `==` checks value equality. Use `is` only for `None`, `True`, `False`. Use `==` for all value comparisons.
2. Floats use IEEE 754 binary representation; 0.1 cannot be represented exactly in binary, so rounding errors accumulate. Fix: `math.isclose(a, b)` or use `decimal.Decimal`.
3. `10 // 3` = `3` (floors down). `-7 // 2` = `-4` (not -3) — floor division always rounds towards negative infinity.
4. `bool([])` = `False` (empty list is falsy). `bool([0])` = `True` — the list has one element, so it is non-empty and therefore truthy (regardless of what the element's value is).
5. `break` exits the enclosing loop entirely. `continue` skips the remaining body of the current iteration and jumps to the next one.
6. The `else` clause on a `while` (or `for`) runs only if the loop terminated naturally (condition became `False`) — NOT if it was exited via `break`. Useful for "search and report not found" patterns.
7. `UPPER_SNAKE_CASE` is a signal to every reader that this value should not be reassigned. Python doesn't enforce it, but the convention is universally understood.
8. `int("42")` → `42` (parses the string as an integer). `int(42.9)` → `42` (truncates towards zero, does NOT round).
9. `True` — `b = a` does NOT copy the list; it makes `b` another label for the exact same list object. Both `a` and `b` have the same `id()`.
10. `and` stops at the first falsy value; `or` stops at the first truthy value. Practical use: `name = user_input or "Anonymous"` — if `user_input` is empty string (falsy), `name` gets the default "Anonymous".

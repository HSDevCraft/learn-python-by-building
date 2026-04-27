# Module 01 — Python Fundamentals

> **Level:** Beginner | **Estimated Time:** 6 hours | **Prerequisites:** None

---

## Learning Objectives

By the end of this module you will be able to:
- Explain how Python executes code (interpreter, REPL, scripts)
- Declare variables and understand Python's dynamic typing model
- Use all primitive data types correctly: `int`, `float`, `str`, `bool`, `NoneType`
- Apply arithmetic, comparison, logical, and bitwise operators
- Control program flow with `if/elif/else`, `for`, `while`, `break`, `continue`, `pass`
- Write readable code following PEP 8 naming conventions
- Understand mutability vs immutability at the memory level

---

## 1.1 How Python Works

### Conceptual Foundation

Python is an **interpreted, dynamically-typed, garbage-collected** language. When you run `python script.py`:

1. The **CPython interpreter** reads your source code (`.py` file)
2. It compiles it to **bytecode** (`.pyc` files in `__pycache__/`)
3. The **Python Virtual Machine (PVM)** executes that bytecode line by line

This differs from compiled languages like C++ where source → machine code happens before execution. The trade-off: Python is slower at runtime but vastly faster to develop in.

```
Source (.py) → Lexer → Parser → AST → Compiler → Bytecode (.pyc) → PVM → Output
```

### The REPL

The Read-Eval-Print Loop is Python's interactive shell. Use it to experiment:

```bash
$ python
>>> 2 + 2
4
>>> "hello".upper()
'HELLO'
>>> quit()
```

**Rule of thumb:** Use the REPL for exploration; `.py` files for anything you want to keep.

---

## 1.2 Variables and the Python Memory Model

### Conceptual Foundation

In Python, **variables are not boxes that hold values — they are labels pointing to objects**.

```python
x = 42        # x points to an integer object 42
y = x         # y points to the SAME object as x
x = 100       # x now points to a new object 100; y still points to 42
print(y)      # 42
```

Every object in Python has:
- An **identity** (`id(obj)`) — its memory address
- A **type** (`type(obj)`) — what kind of object it is
- A **value** — the data it holds

```python
name = "Alice"
print(id(name))    # e.g., 140234567890
print(type(name))  # <class 'str'>
print(name)        # Alice
```

### Naming Conventions (PEP 8)

| Use Case | Convention | Example |
|----------|-----------|---------|
| Variables and functions | `snake_case` | `user_name`, `calculate_total` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRIES = 3` |
| Classes | `PascalCase` | `UserAccount` |
| Private (by convention) | `_leading_underscore` | `_internal_cache` |

```python
# Good
max_attempts = 5
user_email = "alice@example.com"
IS_PRODUCTION = False

# Bad — avoid these
MaxAttempts = 5   # looks like a class
a = 5             # meaningless name
```

---

## 1.3 Data Types

### Integers and Floats

```python
# Integers — arbitrary precision in Python
population = 8_100_000_000   # underscores improve readability
negative = -42
binary = 0b1010              # 10 in binary
hexadecimal = 0xFF           # 255 in hex
octal = 0o17                 # 15 in octal

# Floats — IEEE 754 double precision
pi = 3.14159
scientific = 1.5e-3          # 0.0015
```

**The floating-point gotcha every developer must know:**

```python
# This surprises beginners
print(0.1 + 0.2)             # 0.30000000000000004
print(0.1 + 0.2 == 0.3)     # False !!

# Fix: use math.isclose() for comparisons
import math
print(math.isclose(0.1 + 0.2, 0.3))  # True

# Fix: use decimal for financial calculations
from decimal import Decimal
result = Decimal("0.1") + Decimal("0.2")
print(result)                # 0.3 — exact
```

### Strings

Strings are **immutable sequences of Unicode characters**.

```python
# String literals
single = 'hello'
double = "world"
multiline = """
This spans
multiple lines.
"""

# f-strings (Python 3.6+) — preferred for formatting
name = "Alice"
age = 30
greeting = f"Hello, {name}! You are {age} years old."
print(greeting)  # Hello, Alice! You are 30 years old.

# f-strings support expressions
print(f"Next year you'll be {age + 1}.")
print(f"Name in caps: {name.upper()}")
print(f"Pi to 3 places: {3.14159:.3f}")   # Pi to 3 places: 3.142

# Common string methods
text = "  Hello, World!  "
print(text.strip())           # "Hello, World!"
print(text.lower())           # "  hello, world!  "
print(text.replace("World", "Python"))  # "  Hello, Python!  "
print("hello".startswith("he"))         # True
print(",".join(["a", "b", "c"]))        # "a,b,c"
print("a,b,c".split(","))               # ['a', 'b', 'c']

# Strings are sequences — indexing and slicing
s = "Python"
print(s[0])     # 'P'
print(s[-1])    # 'n'  (negative index: from the end)
print(s[1:4])   # 'yth' (slice: start inclusive, end exclusive)
print(s[::-1])  # 'nohtyP' (reversed)
```

### Booleans

```python
is_active = True
is_deleted = False

# Truthiness — Python evaluates any object as True or False
# Falsy values: False, None, 0, 0.0, "", [], {}, set()
# Everything else is Truthy

print(bool(0))     # False
print(bool(""))    # False
print(bool([]))    # False
print(bool(42))    # True
print(bool("hi"))  # True

# Use truthiness directly — don't compare to True/False explicitly
items = []
if not items:           # Pythonic
    print("No items")

if items == []:         # Less Pythonic
    print("No items")
```

### None

`None` is Python's null value. It is an object — a singleton of type `NoneType`.

```python
result = None

# Check for None with 'is', not '=='
if result is None:
    print("No result yet")

# Functions return None implicitly
def greet(name: str) -> None:
    print(f"Hello, {name}")

output = greet("Alice")
print(output)   # None
```

---

## 1.4 Operators

```python
# Arithmetic
print(10 + 3)   # 13
print(10 - 3)   # 7
print(10 * 3)   # 30
print(10 / 3)   # 3.3333... (always returns float)
print(10 // 3)  # 3         (floor division, returns int)
print(10 % 3)   # 1         (modulo/remainder)
print(10 ** 3)  # 1000      (exponentiation)

# Comparison (return booleans)
print(5 > 3)    # True
print(5 >= 5)   # True
print(5 == 5)   # True
print(5 != 3)   # True

# Python allows chained comparisons (unlike most languages)
age = 25
print(18 <= age < 65)   # True — very readable!

# Logical operators
print(True and False)   # False
print(True or False)    # True
print(not True)         # False

# Short-circuit evaluation: Python stops as soon as result is known
def expensive() -> bool:
    print("Running expensive check")
    return True

# If first condition is False, expensive() never runs
print(False and expensive())   # False (no "Running expensive check")
print(True or expensive())     # True  (no "Running expensive check")

# Assignment operators
count = 10
count += 5    # count = count + 5 → 15
count -= 3    # 12
count *= 2    # 24
count //= 5   # 4

# Identity and membership
a = [1, 2, 3]
b = a
c = [1, 2, 3]

print(a is b)   # True  — same object in memory
print(a is c)   # False — same VALUE but different objects
print(a == c)   # True  — values are equal

print(2 in a)   # True
print(5 not in a)  # True
```

---

## 1.5 Control Flow

### if / elif / else

```python
def classify_bmi(bmi: float) -> str:
    """Classify BMI into standard health categories."""
    if bmi < 18.5:
        return "Underweight"
    elif bmi < 25.0:
        return "Normal weight"
    elif bmi < 30.0:
        return "Overweight"
    else:
        return "Obese"

print(classify_bmi(22.1))   # Normal weight
print(classify_bmi(31.5))   # Obese
```

### Ternary (Conditional Expression)

```python
# value_if_true if condition else value_if_false
score = 75
grade = "Pass" if score >= 50 else "Fail"
print(grade)   # Pass
```

### for Loops

```python
# Iterate over any iterable (list, string, range, etc.)
fruits = ["apple", "banana", "cherry"]
for fruit in fruits:
    print(fruit)

# range(start, stop, step)  — stop is exclusive
for i in range(5):           # 0, 1, 2, 3, 4
    print(i)

for i in range(2, 10, 2):   # 2, 4, 6, 8
    print(i)

# enumerate — when you need both index and value
for index, fruit in enumerate(fruits, start=1):
    print(f"{index}. {fruit}")
# 1. apple
# 2. banana
# 3. cherry

# zip — iterate over multiple iterables simultaneously
names = ["Alice", "Bob", "Carol"]
scores = [92, 85, 78]
for name, score in zip(names, scores):
    print(f"{name}: {score}")
```

### while Loops

```python
# Use while when the number of iterations is not known in advance
attempts = 0
max_attempts = 3

while attempts < max_attempts:
    user_input = input("Enter password: ")  # In practice, replace with actual check
    if user_input == "secret":
        print("Access granted")
        break
    attempts += 1
    print(f"Wrong. {max_attempts - attempts} attempts remaining.")
else:
    # The else clause runs if the loop completes WITHOUT hitting break
    print("Account locked.")
```

### break, continue, pass

```python
# break — exit the loop immediately
for n in range(10):
    if n == 5:
        break
    print(n)   # prints 0, 1, 2, 3, 4

# continue — skip the rest of this iteration
for n in range(10):
    if n % 2 == 0:
        continue
    print(n)   # prints 1, 3, 5, 7, 9

# pass — a no-op placeholder (code must be syntactically complete)
for n in range(10):
    pass   # do nothing; useful during development as a placeholder
```

---

## 1.6 Type Conversion

```python
# Explicit conversion (casting)
num_str = "42"
num = int(num_str)     # "42" → 42
print(num + 1)         # 43

price = "19.99"
price_float = float(price)   # "19.99" → 19.99

age = 25
age_str = str(age)     # 25 → "25"
print("Age: " + age_str)

# Implicit conversion rarely happens in Python (unlike JS)
# Python requires explicit conversions
# print("Age: " + 25)  # TypeError: can only concatenate str to str
print("Age: " + str(25))   # OK
```

---

## Best Practices

1. **Name variables after what they represent**, not their type.
   - Bad: `s = "Alice"`, `lst = [1, 2, 3]`
   - Good: `username = "Alice"`, `scores = [1, 2, 3]`

2. **One statement per line.** Python allows `x = 1; y = 2` but don't do it.

3. **Use `is` for `None` checks**, `==` for value equality.

4. **Avoid bare magic numbers.** Define named constants.
   ```python
   MAX_LOGIN_ATTEMPTS = 3   # clear intent
   if attempts >= MAX_LOGIN_ATTEMPTS:
       lock_account()
   ```

5. **Prefer f-strings** over `%` formatting or `str.format()`.

6. **Use `math.isclose()`** for float comparisons, never `==`.

---

## Exercises

### Exercise 1.1 — Temperature Converter (Beginner)
Write a program that converts Celsius to Fahrenheit and Kelvin.
- Formula: `F = C * 9/5 + 32`, `K = C + 273.15`
- Test with: 0°C, 100°C, -40°C

**Solution:**
```python
def celsius_to_fahrenheit(celsius: float) -> float:
    """Convert Celsius to Fahrenheit."""
    return celsius * 9 / 5 + 32

def celsius_to_kelvin(celsius: float) -> float:
    """Convert Celsius to Kelvin."""
    return celsius + 273.15

def convert_temperature(celsius: float) -> None:
    """Print all conversions for a given Celsius temperature."""
    fahrenheit = celsius_to_fahrenheit(celsius)
    kelvin = celsius_to_kelvin(celsius)
    print(f"{celsius}°C = {fahrenheit:.2f}°F = {kelvin:.2f}K")

convert_temperature(0)     # 0°C = 32.00°F = 273.15K
convert_temperature(100)   # 100°C = 212.00°F = 373.15K
convert_temperature(-40)   # -40°C = -40.00°F = 233.15K
```

---

### Exercise 1.2 — FizzBuzz (Classic Control Flow)
Print numbers 1–100. For multiples of 3 print "Fizz", for multiples of 5 print "Buzz", for multiples of both print "FizzBuzz".

**Solution:**
```python
def fizzbuzz(n: int) -> str:
    """Return FizzBuzz string for a given number."""
    if n % 15 == 0:    # Check 15 first (multiple of both 3 and 5)
        return "FizzBuzz"
    elif n % 3 == 0:
        return "Fizz"
    elif n % 5 == 0:
        return "Buzz"
    else:
        return str(n)

for i in range(1, 101):
    print(fizzbuzz(i))
```

---

### Exercise 1.3 — Simple Calculator (Operators)
Build a calculator that takes two numbers and an operator (`+`, `-`, `*`, `/`) and returns the result. Handle division by zero gracefully.

**Solution:**
```python
def calculate(a: float, b: float, operator: str) -> float | None:
    """
    Perform arithmetic operation on two numbers.
    Returns None if the operation is invalid.
    """
    if operator == "+":
        return a + b
    elif operator == "-":
        return a - b
    elif operator == "*":
        return a * b
    elif operator == "/":
        if b == 0:
            print("Error: Division by zero is undefined.")
            return None
        return a / b
    else:
        print(f"Error: Unknown operator '{operator}'")
        return None

print(calculate(10, 5, "+"))   # 15.0
print(calculate(10, 0, "/"))   # Error message, then None
print(calculate(7, 3, "%"))    # Error: Unknown operator
```

---

### Exercise 1.4 — Number Analysis (Intermediate)
Given a list of numbers, calculate and print: min, max, sum, average, and count of even vs odd numbers.

**Solution:**
```python
def analyze_numbers(numbers: list[int]) -> None:
    """Print statistical analysis of a list of integers."""
    if not numbers:
        print("No numbers to analyze.")
        return

    total = sum(numbers)
    average = total / len(numbers)
    evens = [n for n in numbers if n % 2 == 0]
    odds = [n for n in numbers if n % 2 != 0]

    print(f"Count:   {len(numbers)}")
    print(f"Min:     {min(numbers)}")
    print(f"Max:     {max(numbers)}")
    print(f"Sum:     {total}")
    print(f"Average: {average:.2f}")
    print(f"Evens:   {len(evens)} → {evens}")
    print(f"Odds:    {len(odds)} → {odds}")

analyze_numbers([3, 7, 2, 9, 4, 6, 1, 8, 5])
```

---

## Mini-Project — Grade Calculator

**Scenario:** A teacher needs a program that accepts student names and their exam scores (0–100), then assigns letter grades and prints a class report.

**Grading scale:** A (90–100), B (80–89), C (70–79), D (60–69), F (0–59)

```python
def assign_grade(score: float) -> str:
    """Return letter grade for a numeric score."""
    if score >= 90:
        return "A"
    elif score >= 80:
        return "B"
    elif score >= 70:
        return "C"
    elif score >= 60:
        return "D"
    else:
        return "F"


def generate_class_report(students: dict[str, float]) -> None:
    """
    Print a formatted class report with individual grades and class statistics.

    Args:
        students: Mapping of student name to their score (0-100).
    """
    if not students:
        print("No student data provided.")
        return

    print("=" * 40)
    print(f"{'CLASS REPORT':^40}")
    print("=" * 40)
    print(f"{'Name':<20} {'Score':>6} {'Grade':>5}")
    print("-" * 40)

    scores = list(students.values())

    for name, score in sorted(students.items()):
        grade = assign_grade(score)
        print(f"{name:<20} {score:>6.1f} {grade:>5}")

    print("=" * 40)
    print(f"Class Average: {sum(scores) / len(scores):.1f}")
    print(f"Highest Score: {max(scores):.1f}")
    print(f"Lowest Score:  {min(scores):.1f}")
    passing = sum(1 for s in scores if s >= 60)
    print(f"Passing: {passing}/{len(scores)} students")


# --- Run ---
class_data = {
    "Alice Johnson": 94.5,
    "Bob Smith": 78.0,
    "Carol White": 85.5,
    "David Brown": 62.0,
    "Eva Green": 55.0,
    "Frank Lee": 91.0,
}

generate_class_report(class_data)
```

**Expected output:**
```
========================================
              CLASS REPORT
========================================
Name                  Score Grade
----------------------------------------
Alice Johnson          94.5     A
Bob Smith              78.0     C
Carol White            85.5     B
David Brown            62.0     D
Eva Green              55.0     F
Frank Lee              91.0     A
========================================
Class Average: 77.7
Highest Score: 94.5
Lowest Score:  55.0
Passing: 5/6 students
```

---

## Module Summary

| Concept | Key Takeaway |
|---------|-------------|
| Variables | Labels pointing to objects, not containers |
| Dynamic typing | Type is attached to the object, not the variable |
| `None` | Always compare with `is`, not `==` |
| Float equality | Use `math.isclose()`, never `==` |
| Strings | Immutable; use f-strings for formatting |
| Truthiness | Empty collections, 0, None, "" are all falsy |
| `for` vs `while` | `for` when count is known; `while` for conditions |
| `break`/`continue` | Control loop flow; `else` on loops is often overlooked |

---

## Quiz

1. What is the difference between `is` and `==` in Python?
2. Why does `0.1 + 0.2 == 0.3` return `False`?
3. What does `10 // 3` evaluate to? Why?
4. What is the output of `bool([])` and `bool([0])`?
5. What is the difference between `break` and `continue`?
6. What does the `else` clause on a `while` loop mean?
7. Why should constants be `UPPER_SNAKE_CASE`?
8. What is the difference between `int("42")` and `int(42.9)`?
9. Given `a = [1,2,3]` and `b = a`, does `b is a` return `True` or `False`?
10. How does Python's short-circuit evaluation work in `and` / `or` expressions?

**Answers:**
1. `is` checks object identity (same memory address); `==` checks value equality.
2. Floats use binary IEEE 754 representation; 0.1 and 0.2 cannot be represented exactly.
3. `3` — floor division returns the integer quotient, discarding the remainder.
4. `False` (empty list is falsy); `True` (`[0]` is a non-empty list, which is truthy).
5. `break` exits the loop entirely; `continue` skips to the next iteration.
6. It runs only if the loop completes normally (without hitting `break`).
7. Convention signals to readers that the value should not be reassigned.
8. `int("42")` → 42; `int(42.9)` → 42 (truncates, does not round).
9. `True` — `b = a` makes `b` point to the same list object.
10. `and` returns the first falsy value (or last if all truthy); `or` returns the first truthy value (or last if all falsy).

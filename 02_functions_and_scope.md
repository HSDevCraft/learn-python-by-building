# Module 02 — Functions and Scope

> **Level:** Beginner–Intermediate | **Estimated Time:** 5 hours | **Prerequisites:** Module 01

---

## Learning Objectives

By the end of this module you will be able to:
- Define and call functions with all five parameter types (positional, keyword, default, `*args`, `**kwargs`)
- Deeply understand Python's LEGB scoping rules with visual memory traces
- Build and use closures, understanding exactly what "capturing a variable" means
- Write decorators from first principles (with and without arguments)
- Use `lambda`, `map`, `filter`, `functools.partial`, and `functools.reduce` appropriately
- Type-hint all function signatures and write Google-style docstrings
- Understand first-class functions and why they make Python so expressive

---

## 2.1 Defining Functions

### The Big Picture — Why Functions?

Imagine you are building a payroll system. Without functions, every time you need to calculate tax you paste the same 10 lines of code. Change the tax rate? Update it in 50 places. Functions solve this by giving a **name to a reusable computation**.

Beyond reuse, functions:
- **Decompose complexity** — a 500-line problem becomes 20 small 25-line functions
- **Enable testing** — you can test each function independently
- **Document intent** — a well-named function is self-documenting

### Functions Are First-Class Objects

In Python, functions are objects just like integers and strings. This means you can:
- **Assign** them to variables
- **Pass** them as arguments to other functions
- **Return** them from functions
- **Store** them in lists, dicts, etc.

This is the foundation for closures, decorators, and functional programming patterns.

```python
# Functions are objects — you can store them in variables
def greet(name: str) -> str:
    """Return a greeting string."""
    return f"Hello, {name}!"

# 'say_hello' is now another label pointing to the same function object
say_hello = greet               # no () — we're not CALLING it, just referencing it

print(say_hello("Alice"))       # "Hello, Alice!" — works exactly like greet()
print(greet is say_hello)       # True — same object in memory

# Functions can be stored in data structures
operations = {
    "double": lambda x: x * 2,
    "square": lambda x: x ** 2,
    "negate": lambda x: -x,
}
print(operations["double"](5))  # 10
print(operations["square"](4))  # 16
```

### The Anatomy of a Function

```python
def calculate_discount(price: float, discount_percent: float = 10.0) -> float:
    """
    Calculate the discounted price after applying a percentage discount.

    This is a Google-style docstring. The first line is a one-sentence
    summary. Subsequent sections describe args and return values.

    Args:
        price: The original price in dollars. Must be >= 0.
        discount_percent: Percentage to discount (0-100). Defaults to 10.

    Returns:
        The price after the discount has been applied.

    Raises:
        ValueError: If price is negative or discount_percent is out of range.

    Example:
        >>> calculate_discount(100, 20)
        80.0
        >>> calculate_discount(50)
        45.0
    """
    # Input validation — reject invalid values early
    if price < 0:
        raise ValueError(f"Price must be non-negative, got {price}")
    if not (0 <= discount_percent <= 100):
        raise ValueError(f"Discount must be 0-100, got {discount_percent}")

    # The actual computation
    discount_amount = price * (discount_percent / 100)  # e.g., 100 * 0.20 = 20
    return price - discount_amount                       # e.g., 100 - 20 = 80

print(calculate_discount(100, 20))  # 80.0
print(calculate_discount(50))       # 45.0  (uses default 10%)
```

### Return Values

```python
# A function with no return statement implicitly returns None
def log_message(message: str) -> None:
    print(f"[LOG] {message}")
    # Python automatically adds 'return None' here

result = log_message("Server started")  # prints the log
print(result)                           # None — the function returned nothing

# ──────────────────────────────────────────────────────────────────────────
# Multiple return values — Python actually returns a TUPLE
# ──────────────────────────────────────────────────────────────────────────
def describe_list(numbers: list[float]) -> tuple[float, float, float]:
    """
    Return statistics about a list of numbers.
    
    Python packages the three values into a tuple automatically.
    The caller can unpack them or receive the whole tuple.
    """
    return min(numbers), max(numbers), sum(numbers) / len(numbers)

# Tuple unpacking — assign each return value to its own variable
minimum, maximum, average = describe_list([3, 1, 7, 2, 9])
print(f"Min={minimum}, Max={maximum}, Avg={average:.2f}")  # Min=1, Max=9, Avg=4.40

# Or receive the whole tuple at once
stats = describe_list([3, 1, 7, 2, 9])
print(type(stats))   # <class 'tuple'>
print(stats)         # (1, 9, 4.4)

# ──────────────────────────────────────────────────────────────────────────
# Guard clauses — return early to avoid deep nesting
# ──────────────────────────────────────────────────────────────────────────
# BAD: arrow-shaped code with deep nesting
def divide_bad(a: float, b: float) -> float | str:
    if b != 0:
        if isinstance(a, (int, float)):
            if isinstance(b, (int, float)):
                return a / b
            else:
                return "b must be a number"
        else:
            return "a must be a number"
    else:
        return "cannot divide by zero"

# GOOD: guard clauses — handle error cases first and return early
# The "happy path" (normal case) is at the lowest indentation level
def divide(a: float, b: float) -> float:
    """
    Divide a by b.

    Uses guard clauses to validate input before doing the computation.
    This keeps the main logic at the top indentation level.
    """
    if not isinstance(a, (int, float)):   # guard 1: validate a
        raise TypeError(f"a must be a number, got {type(a)}")
    if not isinstance(b, (int, float)):   # guard 2: validate b
        raise TypeError(f"b must be a number, got {type(b)}")
    if b == 0:                            # guard 3: prevent division by zero
        raise ValueError("Cannot divide by zero")
    return a / b                          # happy path — clear and at low indent
```

---

## 2.2 Parameter Types — All Five Kinds

Python has five different parameter types. Understanding them lets you write flexible, clean APIs.

```python
# ──────────────────────────────────────────────────────────────────────────
# PARAMETER TYPE 1: Positional — caller must supply them in the correct order
# ──────────────────────────────────────────────────────────────────────────
def connect(host: str, port: int) -> str:
    """Both host and port are positional — ORDER matters."""
    return f"Connecting to {host}:{port}"

print(connect("localhost", 8080))   # "Connecting to localhost:8080"
# connect(8080, "localhost")        # works syntactically but logically wrong

# You CAN call positional args by name (keyword syntax) to be explicit:
print(connect(host="localhost", port=8080))  # same result, but explicit
print(connect(port=8080, host="localhost"))  # order doesn't matter when named

# ──────────────────────────────────────────────────────────────────────────
# PARAMETER TYPE 2: Default — caller may omit them; Python uses the default
# ──────────────────────────────────────────────────────────────────────────
def send_email(to: str, subject: str, body: str = "", priority: str = "normal") -> dict:
    """'body' and 'priority' have defaults; 'to' and 'subject' are required."""
    return {"to": to, "subject": subject, "body": body, "priority": priority}

# Must provide 'to' and 'subject'; 'body' and 'priority' use defaults
print(send_email("alice@example.com", "Hello"))
# {'to': 'alice@example.com', 'subject': 'Hello', 'body': '', 'priority': 'normal'}

# Override just 'priority'
print(send_email("alice@example.com", "URGENT", priority="high"))
# {'to': ..., 'subject': 'URGENT', 'body': '', 'priority': 'high'}

# ──────────────────────────────────────────────────────────────────────────
# THE MUTABLE DEFAULT ARGUMENT BUG — one of Python's most notorious gotchas
# ──────────────────────────────────────────────────────────────────────────
# WHY it happens: default values are created ONCE when the function is
# DEFINED, not each time the function is CALLED. If the default is mutable
# (list, dict, set), all calls share the same object.

def add_item_buggy(item: str, cart: list = []) -> list:
    """BUG: the empty list [] is created ONCE at function definition time."""
    cart.append(item)       # mutating the SHARED default list
    return cart

print(add_item_buggy("apple"))   # ['apple']
print(add_item_buggy("banana"))  # ['apple', 'banana']  ← BUG! apple is still there
print(add_item_buggy("cherry"))  # ['apple', 'banana', 'cherry']  ← all accumulate

# CORRECT PATTERN: use None as sentinel, create the mutable inside the function
def add_item(item: str, cart: list[str] | None = None) -> list[str]:
    """
    None as default. We check and create a fresh list inside the body.
    
    Each call that passes no 'cart' gets a BRAND NEW empty list.
    """
    if cart is None:            # None means "caller didn't provide one"
        cart = []               # create a fresh list for THIS call only
    cart.append(item)
    return cart

print(add_item("apple"))        # ['apple']    — fresh list
print(add_item("banana"))       # ['banana']   — another fresh list
print(add_item("cherry", ["existing"]))  # ['existing', 'cherry']  — caller's list

# ──────────────────────────────────────────────────────────────────────────
# PARAMETER TYPE 3: *args — captures extra positional arguments into a TUPLE
# ──────────────────────────────────────────────────────────────────────────
# The * means "collect any remaining positional arguments into a tuple called 'args'"
# The name 'args' is a convention — you could write *numbers, *values, etc.
def sum_all(*numbers: float) -> float:
    """
    Accept any number of positional arguments and return their sum.
    
    *numbers collects all positional args into an immutable tuple.
    You can iterate over it but cannot modify it.
    """
    print(f"Received {len(numbers)} numbers: {numbers}")  # numbers is a tuple
    return sum(numbers)     # sum() works on any iterable, including tuples

print(sum_all(1, 2, 3))         # Received 3 numbers: (1, 2, 3)  →  6
print(sum_all(10, 20))          # Received 2 numbers: (10, 20)   →  30
print(sum_all(5))               # Received 1 numbers: (5,)        →  5
print(sum_all())                # Received 0 numbers: ()           →  0

# You can also UNPACK a list/tuple into *args using the * operator at the call site:
values = [1, 2, 3, 4, 5]
print(sum_all(*values))         # same as sum_all(1, 2, 3, 4, 5)

# ──────────────────────────────────────────────────────────────────────────
# PARAMETER TYPE 4: **kwargs — captures extra keyword arguments into a DICT
# ──────────────────────────────────────────────────────────────────────────
# The ** means "collect any remaining keyword arguments into a dict called 'kwargs'"
def build_html_tag(tag: str, content: str, **attributes: str) -> str:
    """
    Build an HTML tag with arbitrary attributes.
    
    **attributes collects all remaining keyword arguments into a dict.
    E.g., class_="btn", id="submit" → {"class_": "btn", "id": "submit"}
    """
    # Build the attribute string: class_="btn" → class="btn" (remove trailing _)
    attr_str = " ".join(
        f'{key.rstrip("_")}="{value}"'   # rstrip removes trailing underscore
        for key, value in attributes.items()
    )
    if attr_str:
        return f"<{tag} {attr_str}>{content}</{tag}>"
    return f"<{tag}>{content}</{tag}>"

print(build_html_tag("p", "Hello"))
# <p>Hello</p>

print(build_html_tag("a", "Click me", href="/home", class_="btn", id="nav"))
# <a href="/home" class="btn" id="nav">Click me</a>
# Note: 'class' is a Python keyword, so we use 'class_' and strip the underscore

# You can unpack a dict into **kwargs at the call site:
tag_attrs = {"href": "/home", "class_": "link"}
print(build_html_tag("a", "Go home", **tag_attrs))

# ──────────────────────────────────────────────────────────────────────────
# PARAMETER TYPE 5: Combined — the full parameter order
# ──────────────────────────────────────────────────────────────────────────
# Order MUST be: positional → *args → keyword-only → **kwargs
# Breaking this order is a SyntaxError.

def full_signature(
    required: int,          # 1. required positional
    optional: int = 0,      # 2. optional with default
    *extra: int,            # 3. variable positional (tuple)
    flag: bool = False,     # 4. keyword-only (after *) — CANNOT be passed positionally
    **meta: str             # 5. variable keyword (dict)
) -> None:
    print(f"required={required}, optional={optional}, extra={extra}")
    print(f"flag={flag}, meta={meta}")

full_signature(1)                                      # required=1, optional=0, extra=()
full_signature(1, 2)                                   # required=1, optional=2, extra=()
full_signature(1, 2, 3, 4, 5)                          # extra=(3, 4, 5)
full_signature(1, 2, 3, flag=True, name="Alice")       # flag=True, meta={'name':'Alice'}
```

### Positional-Only (`/`) and Keyword-Only (`*`) Markers

```python
# Python 3.8+ allows you to enforce how arguments must be passed.
# This is useful when you want to protect the parameter name as part of the API.

def create_user(
    name: str,          # can be passed positionally OR as keyword
    /,                  # everything BEFORE '/' = positional-only
    email: str,         # can be passed positionally OR as keyword
    *,                  # everything AFTER '*' = keyword-only
    role: str = "user", # MUST be passed as role=... (keyword)
    active: bool = True # MUST be passed as active=... (keyword)
) -> dict:
    """
    The / and * markers control how callers must supply arguments.

    Positional-only (before /): callers cannot use keyword syntax.
    Keyword-only (after *): callers MUST use keyword syntax.
    """
    return {"name": name, "email": email, "role": role, "active": active}

# 'name' is positional-only:
create_user("Alice", "alice@example.com")           # OK
# create_user(name="Alice", email="alice@example.com")  # TypeError for 'name'

# 'role' and 'active' are keyword-only:
create_user("Alice", "alice@example.com", role="admin", active=False)  # OK
# create_user("Alice", "alice@example.com", "admin")  # TypeError for 'role'
```

---

## 2.3 Scope — The LEGB Rule

### The Problem Scope Solves

Imagine every variable in a program shared the same "namespace". A function named `count` inside a loop would clash with a `count` variable in another function. **Scope** creates isolated namespaces so names in different parts of the program don't interfere.

### LEGB — Python's Name Lookup Order

When Python encounters a name (e.g., `x`), it searches four scopes in order and stops at the first match:

```
1. L — Local scope        The body of the currently executing function
2. E — Enclosing scope    Outer function(s) (for nested functions/closures)
3. G — Global scope       Module-level names (the .py file's top level)
4. B — Built-in scope     Python's built-in names: len, print, range, True, ...
```

**Visual trace:**

```python
#            GLOBAL scope
x = "global"                   # G: x = "global"

def outer():
    #        ENCLOSING scope
    x = "enclosing"            # E: x = "enclosing"

    def inner():
        #    LOCAL scope
        x = "local"            # L: x = "local"
        print(x)               # search: L → found "local"  → prints "local"

    inner()
    print(x)                   # search: L (none) → E → found "enclosing" → prints "enclosing"

outer()
print(x)                       # search: L (none) → E (none) → G → found "global" → prints "global"
```

**What if a name is NOT in local scope?**

```python
MAX_SIZE = 100              # Global

def check_size(n: int) -> bool:
    # Python doesn't find 'MAX_SIZE' in local scope,
    # so it moves to Global scope and finds it there.
    # This is a READ — we don't need 'global' for reading.
    return n <= MAX_SIZE    # reads MAX_SIZE from global scope

print(check_size(50))   # True
print(check_size(150))  # False
```

### `global` — Modifying a Global Variable from Inside a Function

```python
# By default, assignment inside a function creates a LOCAL variable,
# it does NOT modify the global one.

visit_count = 0             # Global

def record_visit_broken() -> None:
    # This creates a LOCAL 'visit_count' and increments that.
    # It does NOT touch the global 'visit_count'.
    visit_count = visit_count + 1   # UnboundLocalError! Python sees the assignment
    # and treats 'visit_count' as local, but it hasn't been assigned yet locally.

# visit_count = 0
# record_visit_broken()  # ← UnboundLocalError

# CORRECT: declare 'global' to tell Python "when I write visit_count, 
# I mean the global one, not a new local one."
def record_visit() -> None:
    global visit_count          # declaration: "I'm working with the global"
    visit_count += 1            # now this modifies the global variable

record_visit()
record_visit()
record_visit()
print(visit_count)              # 3

# NOTE: 'global' is rarely needed in good Python code.
# Prefer returning values instead of modifying globals.
# Global state makes functions hard to test and reason about.
```

### `nonlocal` — Modifying an Enclosing Scope Variable

```python
# 'nonlocal' is like 'global' but for the enclosing function's scope.
# It's needed when a nested function wants to WRITE to a variable
# in its enclosing (not global) scope.

def make_accumulator(initial: float = 0.0):
    """
    Create a running-total accumulator.

    'total' lives in make_accumulator's local scope.
    The returned 'add' function can READ it via closure,
    but to WRITE to it, it needs 'nonlocal'.
    """
    total = initial             # this variable lives in make_accumulator's scope

    def add(amount: float) -> float:
        nonlocal total          # "I want to WRITE to the 'total' in the enclosing scope"
        total += amount         # now this modifies make_accumulator's 'total'
        return total

    return add

# Each call to make_accumulator() creates a SEPARATE 'total' variable
wallet = make_accumulator(100.0)
savings = make_accumulator(1000.0)

print(wallet(50))       # 150.0   — wallet's total
print(wallet(-30))      # 120.0   — wallet's total
print(savings(500))     # 1500.0  — savings' total (completely independent)
print(wallet(10))       # 130.0   — wallet's total unaffected by savings
```

---

## 2.4 Closures — Functions That Remember

### What Is a Closure?

A **closure** is created when:
1. A function is defined inside another function
2. The inner function references a variable from the outer function's scope
3. The outer function returns the inner function

The inner function "closes over" the variables it uses from the outer scope — it captures them and keeps them alive even after the outer function has finished executing.

**Analogy:** Think of a closure like a backpack. When the inner function is created, it packs the variables it needs from its environment into a backpack. Even after the outer function is gone, the inner function still has its backpack with the captured values.

```python
def make_multiplier(factor: float):
    """
    Returns a new function that multiplies any number by 'factor'.

    When this function returns 'multiply', Python packages 'factor'
    into the closure. The 'factor' variable lives on even after
    make_multiplier() has finished executing.
    """
    # 'factor' is a local variable here — but it will be captured by 'multiply'
    
    def multiply(x: float) -> float:
        # 'factor' is NOT a local variable of multiply.
        # It comes from the ENCLOSING scope — it's a closure variable.
        return x * factor    # access the captured 'factor'

    # Return the FUNCTION OBJECT (not its result).
    # At this point, 'multiply' is closed over 'factor'.
    return multiply

# Each call to make_multiplier() creates a NEW closure with its own 'factor'
double = make_multiplier(2)     # multiply closes over factor=2
triple = make_multiplier(3)     # multiply closes over factor=3
percent = make_multiplier(0.01) # multiply closes over factor=0.01

print(double(5))        # 10   — factor=2 is captured in double's closure
print(triple(5))        # 15   — factor=3 is captured in triple's closure
print(percent(1500))    # 15.0 — factor=0.01 is captured in percent's closure

# Inspect the closure:
print(double.__closure__)           # (<cell at ...>, ) — the closure cells
print(double.__closure__[0].cell_contents)  # 2  — the captured value

# Practical example — pre-configured greeting generators
def make_greeter(greeting: str, punctuation: str = "!"):
    """Return a function that greets with a specific style."""
    def greet(name: str) -> str:
        return f"{greeting}, {name}{punctuation}"
    return greet

hello   = make_greeter("Hello")         # closes over greeting="Hello", punctuation="!"
hi      = make_greeter("Hi", ".")       # closes over greeting="Hi", punctuation="."
bonjour = make_greeter("Bonjour", " :)")

print(hello("Alice"))    # Hello, Alice!
print(hi("Bob"))         # Hi, Bob.
print(bonjour("Carol"))  # Bonjour, Carol :)
```

### The Classic Closure Bug — Loop Variable Capture

This is one of the most common Python surprises. Understanding it teaches you exactly how closures work.

```python
# ──────────────────────────────────────────────────────────────────────────
# THE BUG: closures capture the VARIABLE, not the VALUE
# ──────────────────────────────────────────────────────────────────────────
funcs = []
for i in range(3):          # i takes values 0, 1, 2 in sequence
    def show():
        return i            # captures the VARIABLE 'i', not its current VALUE
    funcs.append(show)

# By the time we call these functions, the loop is done.
# 'i' is now 2 (its final value). ALL functions see i=2.
print([f() for f in funcs])   # [2, 2, 2]  ← all three return 2!

# ──────────────────────────────────────────────────────────────────────────
# FIX 1: Use a default argument to bind the CURRENT value at definition time
# Default arguments are evaluated when the function is DEFINED, not when called.
# ──────────────────────────────────────────────────────────────────────────
funcs = []
for i in range(3):
    def show(captured_i=i):  # 'i' is evaluated NOW and stored as default
        return captured_i    # returns the captured default, not the loop variable
    funcs.append(show)

print([f() for f in funcs])   # [0, 1, 2]  ← correct!

# ──────────────────────────────────────────────────────────────────────────
# FIX 2: Use functools.partial to bind the value
# ──────────────────────────────────────────────────────────────────────────
import functools

def show_value(value: int) -> int:
    return value

funcs = [functools.partial(show_value, i) for i in range(3)]
print([f() for f in funcs])   # [0, 1, 2]  ← correct!

# ──────────────────────────────────────────────────────────────────────────
# FIX 3: Use a factory function that creates a fresh scope
# ──────────────────────────────────────────────────────────────────────────
def make_show(value: int):
    def show():
        return value    # 'value' is a parameter — its own local variable
    return show

funcs = [make_show(i) for i in range(3)]
print([f() for f in funcs])   # [0, 1, 2]  ← correct!
```

---

## 2.5 Lambda Functions

### What They Are and When to Use Them

A `lambda` is a **small, anonymous function** defined in a single expression. It has no name, no docstring, and no multi-line body. It exists purely for convenience in situations where a full `def` would be overkill.

```python
# Syntax: lambda <parameters>: <single_expression>
# The expression is automatically the return value

# A named function:
def square(x: int) -> int:
    return x ** 2

# The equivalent lambda:
square_lambda = lambda x: x ** 2

print(square(5))         # 25
print(square_lambda(5))  # 25

# Lambdas can take multiple parameters:
add = lambda a, b: a + b
print(add(3, 4))         # 7

# Lambdas can have default values:
greet = lambda name, greeting="Hello": f"{greeting}, {name}!"
print(greet("Alice"))            # Hello, Alice!
print(greet("Bob", "Goodbye"))   # Goodbye, Bob!
```

### When to Use Lambdas (and When Not To)

```python
# ✅ GOOD: lambdas as the key= argument to sorted()
# Here the lambda is a single-use sorting key — a full def would be verbose
people = [
    {"name": "Charlie", "age": 35},
    {"name": "Alice",   "age": 28},
    {"name": "Bob",     "age": 42},
]

# Sort by age (ascending)
by_age = sorted(people, key=lambda person: person["age"])
print([p["name"] for p in by_age])   # ['Alice', 'Charlie', 'Bob']

# Sort by name (alphabetical)
by_name = sorted(people, key=lambda p: p["name"])
print([p["name"] for p in by_name])  # ['Alice', 'Bob', 'Charlie']

# Sort by multiple keys: first by age, then by name (tuple comparison)
data = [("Alice", 30), ("Bob", 25), ("Carol", 30)]
sorted_data = sorted(data, key=lambda t: (t[1], t[0]))
print(sorted_data)  # [('Bob', 25), ('Alice', 30), ('Carol', 30)]

# ✅ GOOD: lambdas with map() and filter()
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
squares = list(map(lambda x: x ** 2, numbers))   # [1, 4, 9, 16, 25, ...]
evens   = list(filter(lambda x: x % 2 == 0, numbers))  # [2, 4, 6, 8, 10]

# But list comprehensions are generally more readable:
squares = [x ** 2 for x in numbers]         # prefer this
evens   = [x for x in numbers if x % 2 == 0]  # prefer this

# ❌ BAD: complex logic in a lambda — use def instead
# Hard to read, debug, or test:
process = lambda x: x ** 2 if x > 0 else -x if x < 0 else 0  # confusing!

# Clear and readable with def:
def process(x: float) -> float:
    """Square positive numbers, negate negatives, return 0 for zero."""
    if x > 0:
        return x ** 2
    elif x < 0:
        return -x
    return 0
```

---

## 2.6 Decorators — Wrapping Functions

### The Mental Model

A decorator is a **function that takes a function as input and returns a new function** as output. The new function typically:
1. Does something BEFORE calling the original
2. Calls the original function
3. Does something AFTER (or with the result of) the original

**Analogy:** Think of a decorator like a gift wrapper. The gift (original function) is still there inside. The wrapper adds extra presentation (logging, timing, retrying) around it. The caller sees the wrapped version.

```
Caller
  │
  ▼
Wrapper function      ← the decorator adds this layer
  │  (before)
  ▼
Original function     ← your actual code
  │  (result)
  ▼
Wrapper function      ← can inspect/modify the result
  │
  ▼
Caller receives result
```

### Building a Decorator from First Principles

```python
import functools
import time

# Step 1: Understand that @decorator is just syntactic sugar for:
#   wrapped_function = decorator(original_function)

# Step 2: Build a timer decorator
def timer(func):
    """
    Decorator that measures and prints how long 'func' takes to run.

    Parameters:
        func: The function to be wrapped.

    Returns:
        A new function 'wrapper' that does the same thing as 'func'
        but also prints execution time.
    """
    @functools.wraps(func)   # copy func's __name__, __doc__, etc. onto wrapper
    def wrapper(*args, **kwargs):
        # *args and **kwargs allow 'wrapper' to accept ANY arguments
        # and pass them through to 'func' unchanged.

        start = time.perf_counter()         # record the start time
        result = func(*args, **kwargs)      # call the ORIGINAL function
        elapsed = time.perf_counter() - start  # compute elapsed time

        print(f"[TIMER] {func.__name__} took {elapsed:.6f} seconds")
        return result                       # return the ORIGINAL result unchanged

    return wrapper                          # return the wrapper, not a call to it!

# Step 3: Apply the decorator using @ syntax
@timer
def slow_sum(n: int) -> int:
    """Sum all integers from 0 to n."""
    return sum(range(n))

# This is EXACTLY equivalent to: slow_sum = timer(slow_sum)
# 'slow_sum' now points to 'wrapper', not the original function.
# But wrapper calls the original 'func' internally.

result = slow_sum(1_000_000)
# Prints: [TIMER] slow_sum took 0.034521 seconds
print(result)   # 499999500000

# @functools.wraps preserves metadata — without it:
# print(slow_sum.__name__)  # would print 'wrapper' (wrong)
# with @functools.wraps:
print(slow_sum.__name__)    # 'slow_sum' (correct)
print(slow_sum.__doc__)     # "Sum all integers from 0 to n." (correct)
```

### A Practical Decorator — Input Validation

```python
import functools

def validate_positive(func):
    """
    Decorator: ensures all numeric arguments to 'func' are positive.
    Raises ValueError if any argument is <= 0.
    """
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        # Check all positional arguments
        for i, arg in enumerate(args):
            if isinstance(arg, (int, float)) and arg <= 0:
                raise ValueError(
                    f"Argument {i} ({arg}) to {func.__name__}() must be positive"
                )
        # Check all keyword arguments
        for name, val in kwargs.items():
            if isinstance(val, (int, float)) and val <= 0:
                raise ValueError(
                    f"Argument '{name}' ({val}) to {func.__name__}() must be positive"
                )
        return func(*args, **kwargs)    # all checks passed — call the original
    return wrapper

@validate_positive
def calculate_area(width: float, height: float) -> float:
    """Return the area of a rectangle."""
    return width * height

print(calculate_area(5.0, 3.0))     # 15.0
# calculate_area(-1, 3)              # ValueError: Argument 0 (-1) must be positive
# calculate_area(5, height=-2)       # ValueError: Argument 'height' (-2) must be positive
```

### Decorator with Arguments (Three-Level Nesting)

When a decorator itself needs parameters, you add one more level of nesting:

```python
import functools
import time

def retry(max_attempts: int = 3, delay: float = 1.0, exceptions: tuple = (Exception,)):
    """
    Decorator factory: returns a decorator that retries 'func' on failure.

    Usage:
        @retry(max_attempts=3, delay=0.5)
        def flaky_function(): ...

    Three levels of nesting:
        retry(3, 0.5)   → returns 'decorator'
        decorator(func) → returns 'wrapper'
        wrapper(...)    → runs the retry logic and calls func
    """
    def decorator(func):                    # level 2: receives the actual function
        @functools.wraps(func)
        def wrapper(*args, **kwargs):       # level 3: runs on every call
            last_error: Exception | None = None

            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)    # try calling the function
                except exceptions as e:
                    last_error = e
                    print(f"  Attempt {attempt}/{max_attempts} failed: {e}")
                    if attempt < max_attempts:
                        time.sleep(delay)           # wait before retrying

            # If we reach here, all attempts failed — re-raise the last error
            raise last_error

        return wrapper
    return decorator                        # return the decorator (not the wrapper)

@retry(max_attempts=3, delay=0.1, exceptions=(ConnectionError, TimeoutError))
def fetch_data(url: str) -> str:
    """Simulate a flaky network call that sometimes fails."""
    import random
    if random.random() < 0.6:              # 60% chance of failure
        raise ConnectionError(f"Network timeout fetching {url}")
    return f"Data from {url}"

# When this is called: retry(3, 0.1, ...) → decorator → wrapper is called
# wrapper runs up to 3 times, sleeping 0.1s between attempts
try:
    data = fetch_data("https://api.example.com/data")
    print(data)
except ConnectionError:
    print("All attempts failed.")
```

### Stacking Multiple Decorators

```python
import functools

def log_call(func):
    """Log every call to the decorated function."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        print(f"→ Calling {func.__name__}({args}, {kwargs})")
        result = func(*args, **kwargs)
        print(f"← {func.__name__} returned {result!r}")
        return result
    return wrapper

def validate_positive(func):
    """Ensure all numeric args are positive."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        for arg in args:
            if isinstance(arg, (int, float)) and arg <= 0:
                raise ValueError(f"All arguments to {func.__name__} must be positive")
        return func(*args, **kwargs)
    return wrapper

# Stacking decorators — applied BOTTOM UP at decoration time,
# but executed TOP DOWN at call time.
@log_call                   # applied second → outermost wrapper
@validate_positive          # applied first  → innermost wrapper (closest to original)
def multiply(a: float, b: float) -> float:
    return a * b

# Execution order when multiply(3, 4) is called:
# 1. log_call's wrapper runs first (outermost)
# 2. validate_positive's wrapper runs second
# 3. original multiply(3, 4) runs last
multiply(3, 4)
# → Calling multiply((3, 4), {})
# ← multiply returned 12
```

---

## 2.7 `functools` — Essential Higher-Order Functions

```python
import functools

# ──────────────────────────────────────────────────────────────────────────
# functools.lru_cache — memoization (cache results of expensive functions)
# ──────────────────────────────────────────────────────────────────────────
# LRU = Least Recently Used. Stores up to 'maxsize' results.
# When the cache is full, the least-recently-used entry is discarded.
# The function must be PURE (same inputs always give same outputs).

@functools.lru_cache(maxsize=128)
def fibonacci(n: int) -> int:
    """
    Compute the nth Fibonacci number.
    
    WITHOUT caching: fib(40) makes 2^40 ≈ 1 billion calls (exponential).
    WITH lru_cache:  fib(40) makes only 40 calls (linear).
    
    The cache key is the tuple of arguments: (n,).
    """
    if n < 2:
        return n                    # base cases: fib(0)=0, fib(1)=1
    return fibonacci(n - 1) + fibonacci(n - 2)  # recursive calls — cached!

print(fibonacci(40))                # 102334155 — computed in milliseconds
print(fibonacci.cache_info())       # CacheInfo(hits=38, misses=41, maxsize=128, currsize=41)

# ──────────────────────────────────────────────────────────────────────────
# functools.partial — create specialised versions of functions
# ──────────────────────────────────────────────────────────────────────────
# partial() pre-fills some arguments of a function, returning a new function
# that only needs the remaining arguments.

def power(base: float, exponent: float) -> float:
    """Raise base to the power of exponent."""
    return base ** exponent

# Pre-fill the 'exponent' argument to create specialised functions:
square = functools.partial(power, exponent=2)   # power(x, exponent=2)
cube   = functools.partial(power, exponent=3)   # power(x, exponent=3)

print(square(4))    # 16   — same as power(4, exponent=2)
print(cube(3))      # 27   — same as power(3, exponent=3)

# Practical use: pre-configure a print function
import sys
error_print = functools.partial(print, file=sys.stderr, end="\n")
error_print("Something went wrong!")   # prints to stderr

# ──────────────────────────────────────────────────────────────────────────
# functools.reduce — fold a sequence into a single cumulative value
# ──────────────────────────────────────────────────────────────────────────
from functools import reduce

# reduce(func, iterable, initializer)
# Applies func(accumulator, element) left to right.
# [1, 2, 3, 4, 5] with '*': ((((1*2)*3)*4)*5) = 120

product = reduce(lambda acc, x: acc * x, [1, 2, 3, 4, 5])
print(product)      # 120  — factorial of 5

# With an initial value (initializer):
total = reduce(lambda acc, x: acc + x, [10, 20, 30], 100)
print(total)        # 160  — starts at 100, then adds 10+20+30

# Real-world: flatten a list of lists
nested = [[1, 2], [3, 4], [5, 6]]
flat = reduce(lambda acc, lst: acc + lst, nested, [])
print(flat)         # [1, 2, 3, 4, 5, 6]
# Note: for large lists, itertools.chain.from_iterable is more efficient
```

---

## Best Practices

### 1. One Function, One Responsibility

```python
# BAD: one function doing too many things
def process_order(order: dict) -> None:
    # validates, saves to DB, sends email, generates invoice all in one place
    ...

# GOOD: each function does exactly one thing
def validate_order(order: dict) -> bool: ...
def save_order(order: dict) -> int: ...        # returns order_id
def send_confirmation_email(order_id: int) -> None: ...
def generate_invoice(order_id: int) -> str: ...
```

### 2. Always Use `@functools.wraps` in Decorators

```python
# Without @functools.wraps, the wrapper hides the original's identity:
def bad_decorator(func):
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    return wrapper  # wrapper.__name__ = 'wrapper', wrapper.__doc__ = None

# With @functools.wraps, the wrapper correctly identifies as the original:
def good_decorator(func):
    @functools.wraps(func)   # copies __name__, __doc__, __annotations__, etc.
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)
    return wrapper  # wrapper.__name__ = func.__name__, etc.
```

### 3. Prefer Returning Values Over Side Effects

```python
# BAD: function prints instead of returning — cannot be tested or composed
def get_total_bad(prices: list[float]) -> None:
    print(sum(prices))

# GOOD: return the value; caller decides what to do with it
def get_total(prices: list[float]) -> float:
    return sum(prices)

# Now you can use the result in any context:
total = get_total([10, 20, 30])
print(f"Total: ${total:.2f}")           # printing
assert get_total([1, 2, 3]) == 6        # testing
discounted = get_total(prices) * 0.9   # composing with other logic
```

---

## Exercises

### Exercise 2.1 — Is Palindrome (Beginner)

**Problem:** Write `is_palindrome(text: str) -> bool` that returns `True` if the text reads the same forwards and backwards (case-insensitive, ignoring spaces and punctuation).

**Solution:**
```python
import re

def is_palindrome(text: str) -> bool:
    """
    Return True if text is a palindrome.

    Strategy:
    1. Remove all non-alphanumeric characters using regex
    2. Convert to lowercase for case-insensitive comparison
    3. Compare the cleaned string to its reverse (s == s[::-1])
    """
    # re.sub(pattern, replacement, string)
    # r'[^a-z0-9]' matches any character that is NOT a-z or 0-9
    cleaned = re.sub(r'[^a-z0-9]', '', text.lower())
    # cleaned[::-1] reverses the string using step=-1 slicing
    return cleaned == cleaned[::-1]

print(is_palindrome("racecar"))                          # True
print(is_palindrome("A man, a plan, a canal: Panama"))  # True
print(is_palindrome("hello"))                           # False
print(is_palindrome("Was it a car or a cat I saw?"))    # True
```

---

### Exercise 2.2 — Closure Counter (Intermediate)

**Problem:** Create `make_counter(start=0, step=1)` that returns a counter with `increment`, `decrement`, and `reset` operations (all as closures).

**Solution:**
```python
from typing import Callable

def make_counter(start: int = 0, step: int = 1) -> dict[str, Callable]:
    """
    Create a stateful counter using closures.

    'count' is a variable in make_counter's scope.
    All inner functions close over the SAME 'count' variable,
    so changes made by one are visible to the others.
    This is how you share mutable state between closures.
    """
    count = start               # the shared state — all inner functions see this

    def increment() -> int:
        nonlocal count          # we're writing to the enclosing 'count'
        count += step
        return count

    def decrement() -> int:
        nonlocal count
        count -= step
        return count

    def reset() -> int:
        nonlocal count
        count = start           # 'start' is also closed over (read-only, so no nonlocal needed)
        return count

    def current() -> int:
        return count            # read-only access — no nonlocal needed

    return {
        "increment": increment,
        "decrement": decrement,
        "reset": reset,
        "current": current,
    }

counter = make_counter(start=10, step=5)
print(counter["current"]())     # 10
print(counter["increment"]())   # 15
print(counter["increment"]())   # 20
print(counter["decrement"]())   # 15
print(counter["reset"]())       # 10
```

---

### Exercise 2.3 — Logging Decorator (Intermediate)

**Problem:** Write a `@log_call` decorator that prints the function name, all arguments, and the return value each time the function is called.

**Solution:**
```python
import functools

def log_call(func):
    """
    Decorator that logs every call with its arguments and return value.

    repr() is used so strings show their quotes: "Alice" not Alice.
    The !r format specifier in f-strings is shorthand for repr().
    """
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        # Build a readable signature string like: add(3, b=5)
        args_repr   = [repr(a) for a in args]                      # positional args
        kwargs_repr = [f"{k}={v!r}" for k, v in kwargs.items()]    # keyword args
        signature   = ", ".join(args_repr + kwargs_repr)

        print(f"→ {func.__name__}({signature})")
        result = func(*args, **kwargs)                              # call the original
        print(f"← {func.__name__} returned {result!r}")
        return result                                               # don't forget to return!

    return wrapper

@log_call
def add(a: int, b: int) -> int:
    return a + b

@log_call
def greet(name: str, greeting: str = "Hello") -> str:
    return f"{greeting}, {name}!"

add(3, 5)
# → add(3, 5)
# ← add returned 8

greet("Alice", greeting="Hi")
# → greet('Alice', greeting='Hi')
# ← greet returned 'Hi, Alice!'
```

---

### Exercise 2.4 — Memoized Fibonacci with Benchmark (Advanced)

**Problem:** Implement Fibonacci with `lru_cache` and benchmark against the naive recursive version.

**Solution:**
```python
import functools
import time

def fib_naive(n: int) -> int:
    """
    Naive recursive Fibonacci — NO caching.
    
    Time complexity: O(2^n) — exponential!
    Each call spawns two more calls, creating a binary tree of calls.
    fib(40) makes approximately 2^40 = 1 trillion recursive calls.
    """
    if n < 2:
        return n
    return fib_naive(n - 1) + fib_naive(n - 2)

@functools.lru_cache(maxsize=None)  # unlimited cache size
def fib_cached(n: int) -> int:
    """
    Memoized recursive Fibonacci — results are cached.
    
    Time complexity: O(n) — linear!
    Each value fib(k) is computed ONCE, cached, then reused.
    fib(40) makes exactly 41 unique calls (one per value 0-40).
    """
    if n < 2:
        return n
    return fib_cached(n - 1) + fib_cached(n - 2)

def benchmark(name: str, func, n: int) -> None:
    """Run 'func(n)' and print timing information."""
    start   = time.perf_counter()
    result  = func(n)
    elapsed = time.perf_counter() - start
    print(f"{name:20s}  fib({n}) = {result:>15,}  in {elapsed:>10.6f}s")

N = 35
print(f"{'Function':<20}  {'Result':>24}  {'Time':>12}")
print("-" * 65)
benchmark("fib_naive",   fib_naive,   N)    # ~3 seconds on most machines
benchmark("fib_cached",  fib_cached,  N)    # microseconds
benchmark("fib_cached",  fib_cached,  N)    # even faster — already cached
print(fib_cached.cache_info())              # see how many hits/misses
```

---

## Mini-Project — Function Pipeline Composer

**Scenario:** Build a `compose(*functions)` utility that chains multiple functions together, applying them right to left (like mathematical function composition: `f(g(h(x)))`).

```python
import functools
from typing import Callable, Any

def compose(*functions: Callable) -> Callable:
    """
    Return a new function that applies the given functions right to left.

    compose(f, g, h)(x) == f(g(h(x)))

    HOW IT WORKS:
    - reversed(functions) gives us [h, g, f] — right to left
    - functools.reduce applies them in sequence:
      start with x, apply h → get h(x)
      apply g to h(x) → get g(h(x))
      apply f to g(h(x)) → get f(g(h(x)))
    """
    def composed(value: Any) -> Any:
        # reduce(lambda acc, f: f(acc), [h, g, f], x)
        return functools.reduce(lambda acc, f: f(acc), reversed(functions), value)
    return composed

# Build text-processing pipeline steps
def strip_whitespace(text: str) -> str:
    """Remove leading and trailing whitespace."""
    return text.strip()

def to_lowercase(text: str) -> str:
    """Convert to lowercase."""
    return text.lower()

def remove_punctuation(text: str) -> str:
    """Remove all punctuation characters."""
    import string
    # str.maketrans("", "", chars_to_delete) creates a translation table
    return text.translate(str.maketrans("", "", string.punctuation))

def tokenize(text: str) -> list[str]:
    """Split text into a list of words."""
    return text.split()

# Compose them into a pipeline: strip → lowercase → remove punct → split
# Applied RIGHT to LEFT: strip_whitespace first, tokenize last
preprocess = compose(
    tokenize,           # applied last  — split into words
    remove_punctuation, # applied third — remove ! , . etc.
    to_lowercase,       # applied second — make lowercase
    strip_whitespace,   # applied first  — strip outer whitespace
)

raw_text = "  Hello, World! Python is AMAZING.  "
tokens   = preprocess(raw_text)
print(tokens)   # ['hello', 'world', 'python', 'is', 'amazing']

# Build a number-processing pipeline
def clamp(value: float, minimum: float = 0.0, maximum: float = 1.0) -> float:
    """Clamp a value to [minimum, maximum]."""
    return max(minimum, min(maximum, value))

normalize_score = compose(
    functools.partial(clamp, minimum=0.0, maximum=1.0),   # ensure 0-1
    lambda x: x / 100,                                     # convert percent to decimal
    lambda x: max(0.0, x),                                 # remove negatives
)

print(normalize_score(85))    # 0.85
print(normalize_score(110))   # 1.0  — clamped at max
print(normalize_score(-20))   # 0.0  — clamped at min
```

---

## Interview Prep — Top Questions for Functions and Scope

**Q1: What is a closure and why is it useful?**
A closure is an inner function that **captures variables from its enclosing scope** even after the outer function has returned. The inner function keeps a reference to the enclosing scope's variables (not their values). Used for: factory functions, decorators, memoization, callbacks with state. Example: a `make_multiplier(n)` factory returns a function that multiplies by `n`.

**Q2: What is a decorator and how does it work internally?**
A decorator is a function that takes a function as input and returns a modified function. `@decorator` is syntactic sugar for `func = decorator(func)`. It wraps behavior around the original function. Production uses: logging, timing, authentication, caching (`@lru_cache`), retry logic. Always use `@functools.wraps(func)` to preserve the wrapped function's metadata.

**Q3: Explain the LEGB rule.**
Python resolves names in this order: **L**ocal → **E**nclosing → **G**lobal → **B**uilt-in. If a name isn't found at one level, Python searches the next. `global x` declares that `x` refers to the global scope. `nonlocal x` refers to the nearest enclosing non-global scope. This is tested heavily — know which scope each variable resolves to.

**Q4: What is the mutable default argument trap?**
`def f(lst=[])` creates the default list **once** at function definition time — the same list object is reused across all calls. Appending to it in one call persists to the next. Fix: use `None` as default and create the mutable object inside the function: `if lst is None: lst = []`. This is one of the most common Python interview gotchas.

**Q5: What is `*args` and `**kwargs`?**
`*args` collects extra positional arguments into a tuple. `**kwargs` collects extra keyword arguments into a dict. They let functions accept arbitrary numbers of arguments. Order: `def f(pos, /, normal, *args, kw_only, **kwargs)`. Used in decorators, wrappers, and APIs that need to forward arguments.

**Q6: What is `functools.lru_cache` and when should you use it?**
`@lru_cache(maxsize=128)` memoizes a function — caches return values keyed by arguments. When called again with the same args, returns the cached result in O(1). Use for: pure functions called repeatedly with the same inputs, recursive algorithms with overlapping subproblems (Fibonacci, DP). Requirements: all arguments must be **hashable**. Use `maxsize=None` for unbounded cache.

**Q7: What is the difference between a generator function and a regular function?**
A generator function contains `yield` instead of `return`. Calling it returns a **generator object** — it doesn't execute the body yet. Each `next()` call runs until the next `yield`, pausing execution and returning the yielded value. Generators are lazy — they produce values on demand, using O(1) memory regardless of the sequence length.

**Q8: Explain `lambda` — when to use and when to avoid.**
`lambda args: expression` creates an anonymous function. Use it for simple, one-line callbacks in `sorted(key=...)`, `map()`, `filter()`. Avoid for anything complex — `lambda` cannot contain statements, multi-line logic, or docstrings. If you need more than one expression, write a regular function. Prefer named functions for readability and testability.

---

## Module Summary

| Concept | Key Takeaway |
|---------|-------------|
| First-class functions | Functions are objects — assign, pass, return, store them |
| Five parameter types | Positional → default → `*args` → keyword-only → `**kwargs` |
| Mutable defaults | NEVER use `[]` or `{}` as default; use `None` as sentinel |
| LEGB rule | Python searches Local → Enclosing → Global → Built-in |
| `global` | Required only when you WRITE to a global from inside a function |
| `nonlocal` | Required when an inner function WRITES to an enclosing scope variable |
| Closures | Inner function + captured variables; captures the VARIABLE, not the value |
| Loop closure bug | Use default arg `(i=i)` or a factory function to capture the current value |
| `lambda` | Anonymous single-expression function; use for `key=` and short callbacks |
| Decorators | `@dec` = `func = dec(func)`; always use `@functools.wraps` |
| Decorator with args | Three-level nesting: `factory → decorator → wrapper` |
| `lru_cache` | Built-in memoization; transforms O(2^n) recursion to O(n) |
| `partial` | Pre-fill arguments to create specialised versions of a function |
| `reduce` | Fold a sequence into a single value left to right |

---

## Quiz

1. What is the LEGB rule, and in what order does Python search for a name?
2. Why should you never use `[]` as a default argument value?
3. What does `@functools.wraps(func)` do, and why is it important?
4. What is the difference between a closure and a regular function?
5. What do `*args` and `**kwargs` collect, and what types are they?
6. Explain the loop closure bug: why does `[lambda: i for i in range(3)]` produce `[2, 2, 2]`?
7. When would you choose `functools.partial` over a lambda?
8. What is the difference between `map(f, lst)` and `[f(x) for x in lst]`?
9. In a decorator with arguments, how many levels of nesting are there? Explain each level.
10. How does `functools.lru_cache` decide whether two calls are the same (cache hit)?

**Answers:**
1. **L**ocal → **E**nclosing → **G**lobal → **B**uilt-in. Python stops at the first scope where it finds the name.
2. The default list `[]` is created ONCE when the function is defined. All calls that don't pass `lst` share the same list object, so changes from one call persist to the next.
3. It copies `__name__`, `__doc__`, `__annotations__`, and other attributes from the wrapped function to the wrapper. Without it, the wrapper pretends to be itself, breaking introspection, help(), and doctest.
4. A closure is a function that captures and retains references to variables from its enclosing scope, even after that scope has exited. A regular function has no such captured variables.
5. `*args` collects extra positional arguments into a **tuple**. `**kwargs` collects extra keyword arguments into a **dict**.
6. All lambdas close over the same loop variable `i`. Since they capture the variable (not its current value), they all see `i`'s final value of `2` when called after the loop ends.
7. Use `partial` when you want to reuse a configuration in multiple places (it's more descriptive and creates a named, reusable object). Use `lambda` for truly one-off single-use callbacks.
8. `map(f, lst)` returns a lazy iterator (computes values on demand). `[f(x) for x in lst]` returns a fully materialised list. Both produce the same values, but the comprehension is generally more readable.
9. Three levels: (1) the **factory** function receives decorator arguments and returns (2) the **decorator** function which receives the original function and returns (3) the **wrapper** function which runs the actual logic.
10. `lru_cache` hashes all positional arguments into a cache key tuple. If the same tuple of arguments has been seen before, it returns the cached result without calling the function. Arguments must be hashable (lists and dicts cannot be used as arguments to cached functions).

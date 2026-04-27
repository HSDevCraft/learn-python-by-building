# Module 02 — Functions and Scope

> **Level:** Beginner–Intermediate | **Estimated Time:** 5 hours | **Prerequisites:** Module 01

---

## Learning Objectives

By the end of this module you will be able to:
- Define and call functions with positional, keyword, default, and variable arguments
- Understand Python's scoping rules (LEGB)
- Use closures and understand the closure over mutable state pattern
- Write and apply decorators (with and without arguments)
- Use `lambda`, `map`, `filter`, `functools.partial`, and `functools.reduce`
- Apply type hints to all function signatures
- Write proper docstrings (Google style)

---

## 2.1 Defining Functions

### Conceptual Foundation

A function is a **named, reusable block of code** that takes inputs (parameters), performs a computation, and optionally returns an output. Functions are **first-class objects** in Python — they can be assigned to variables, passed as arguments, and returned from other functions.

```python
# Basic anatomy
def function_name(parameter1: type, parameter2: type) -> return_type:
    """One-line summary.

    Longer description if needed.

    Args:
        parameter1: Description of parameter1.
        parameter2: Description of parameter2.

    Returns:
        Description of return value.
    """
    # body
    return result
```

```python
def add(a: int, b: int) -> int:
    """Return the sum of two integers."""
    return a + b

result = add(3, 5)    # 8
print(result)
```

### Return Values

```python
# A function with no return statement returns None implicitly
def print_greeting(name: str) -> None:
    print(f"Hello, {name}!")

# Multiple return values (actually returns a tuple)
def min_max(numbers: list[float]) -> tuple[float, float]:
    """Return the minimum and maximum values from a list."""
    return min(numbers), max(numbers)

low, high = min_max([3, 1, 7, 2, 9])
print(f"Min: {low}, Max: {high}")   # Min: 1, Max: 9

# Early return for guard clauses — keep happy path at low indentation
def divide(a: float, b: float) -> float | None:
    """Divide a by b; return None if b is zero."""
    if b == 0:
        return None          # guard clause
    return a / b
```

---

## 2.2 Parameter Types

```python
# 1. Positional parameters — order matters
def describe_person(name: str, age: int) -> str:
    return f"{name} is {age} years old."

print(describe_person("Alice", 30))   # positional
print(describe_person(age=30, name="Alice"))  # keyword — order irrelevant

# 2. Default parameters
def greet(name: str, greeting: str = "Hello") -> str:
    """Greet someone, using 'Hello' by default."""
    return f"{greeting}, {name}!"

print(greet("Bob"))               # Hello, Bob!
print(greet("Bob", "Good morning"))  # Good morning, Bob!

# CRITICAL: Never use mutable objects as default arguments!
# BUG — the list is shared across all calls
def append_to_bad(item, lst=[]):
    lst.append(item)
    return lst

print(append_to_bad(1))   # [1]
print(append_to_bad(2))   # [1, 2]  ← BUG! Should be [2]

# CORRECT — use None as sentinel
def append_to_good(item: int, lst: list[int] | None = None) -> list[int]:
    if lst is None:
        lst = []
    lst.append(item)
    return lst

print(append_to_good(1))   # [1]
print(append_to_good(2))   # [2]  ← Correct

# 3. *args — variable positional arguments (collected as a tuple)
def total(*amounts: float) -> float:
    """Sum any number of amounts."""
    return sum(amounts)

print(total(10, 20, 30))       # 60
print(total(5.5, 2.5))         # 8.0

# 4. **kwargs — variable keyword arguments (collected as a dict)
def build_profile(name: str, **attributes: str) -> dict:
    """Build a user profile dict from keyword arguments."""
    profile = {"name": name}
    profile.update(attributes)
    return profile

print(build_profile("Alice", role="engineer", city="NYC"))
# {'name': 'Alice', 'role': 'engineer', 'city': 'NYC'}

# 5. Combined — order must be: positional, *args, keyword-only, **kwargs
def full_example(a: int, b: int, *args: int, verbose: bool = False, **kwargs: str) -> None:
    print(f"a={a}, b={b}, args={args}, verbose={verbose}, kwargs={kwargs}")

full_example(1, 2, 3, 4, verbose=True, tag="test")
```

### Positional-Only and Keyword-Only Parameters (Python 3.8+)

```python
# / marks the end of positional-only params
# * marks the start of keyword-only params
def process(pos_only: int, /, normal: int, *, kw_only: int) -> None:
    print(f"{pos_only}, {normal}, {kw_only}")

process(1, 2, kw_only=3)       # OK
process(1, normal=2, kw_only=3) # OK
# process(pos_only=1, ...)     # TypeError — pos_only cannot be keyword
```

---

## 2.3 Scope: The LEGB Rule

### Conceptual Foundation

When Python encounters a name, it searches in this order:
1. **L**ocal — the current function
2. **E**nclosing — outer function scopes (for closures)
3. **G**lobal — module-level names
4. **B**uilt-in — Python's built-in names (`len`, `print`, etc.)

```python
x = "global"   # Global scope

def outer():
    x = "enclosing"  # Enclosing scope

    def inner():
        x = "local"  # Local scope
        print(x)     # local — found immediately in L

    inner()
    print(x)     # enclosing — inner's local is gone

outer()
print(x)        # global — enclosing scope is gone
```

### `global` and `nonlocal`

```python
# global — declare intent to modify a global variable
counter = 0

def increment() -> None:
    global counter
    counter += 1

increment()
increment()
print(counter)   # 2

# nonlocal — modify a variable in the enclosing (not global) scope
def make_counter() -> callable:
    count = 0
    def increment() -> int:
        nonlocal count
        count += 1
        return count
    return increment

c = make_counter()
print(c())   # 1
print(c())   # 2
print(c())   # 3
```

---

## 2.4 Closures

### Conceptual Foundation

A **closure** is a function that remembers the environment in which it was created — specifically, it holds references to variables from its enclosing scope even after that scope has finished executing.

```python
def make_multiplier(factor: float):
    """Return a function that multiplies its argument by factor."""
    def multiply(x: float) -> float:
        return x * factor    # 'factor' is captured from enclosing scope
    return multiply

double = make_multiplier(2)
triple = make_multiplier(3)

print(double(5))   # 10
print(triple(5))   # 15
print(double(triple(4)))  # 24 = double(12)
```

**Classic closure bug** — loop variable capture:

```python
# BUG: all functions capture the SAME variable 'i'
funcs = [lambda: i for i in range(3)]
print([f() for f in funcs])   # [2, 2, 2] — all see i=2

# FIX: bind the current value using a default argument
funcs = [lambda i=i: i for i in range(3)]
print([f() for f in funcs])   # [0, 1, 2] — correct
```

---

## 2.5 Lambda Functions

Lambdas are **anonymous, single-expression functions**. Use them for short, throwaway operations.

```python
# Syntax: lambda parameters: expression
square = lambda x: x ** 2
print(square(5))   # 25

# Best use: as arguments to higher-order functions
numbers = [3, 1, 4, 1, 5, 9, 2, 6]

sorted_nums = sorted(numbers)                      # [1, 1, 2, 3, 4, 5, 6, 9]
sorted_desc = sorted(numbers, reverse=True)        # [9, 6, 5, 4, 3, 2, 1, 1]

# Sort list of dicts by a key
people = [{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]
by_age = sorted(people, key=lambda p: p["age"])    # sorted by age
print(by_age[0]["name"])   # Bob

# map — apply a function to every element
squared = list(map(lambda x: x ** 2, [1, 2, 3, 4]))
# Prefer list comprehension: [x**2 for x in [1, 2, 3, 4]]

# filter — keep elements where function returns True
evens = list(filter(lambda x: x % 2 == 0, [1, 2, 3, 4, 5, 6]))
# Prefer: [x for x in range(1, 7) if x % 2 == 0]
```

**Rule:** Prefer list comprehensions over `map`/`filter` with lambdas for readability. Use lambdas for `sorted(key=...)` and one-liners passed to libraries.

---

## 2.6 Decorators

### Conceptual Foundation

A **decorator** is a function that takes another function as input, wraps it with additional behaviour, and returns the wrapped function. It leverages closures and first-class functions.

```
original_function → decorator → wrapped_function
```

```python
import functools
import time

# Building a decorator from first principles
def timer(func):
    """Measure and print execution time of the wrapped function."""
    @functools.wraps(func)   # preserve the original function's metadata
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{func.__name__} took {elapsed:.4f}s")
        return result
    return wrapper

@timer
def slow_sum(n: int) -> int:
    """Sum numbers from 0 to n."""
    return sum(range(n))

# @timer is syntactic sugar for: slow_sum = timer(slow_sum)
print(slow_sum(1_000_000))   # slow_sum took 0.0423s   \n  499999500000
```

### Decorator with Arguments

```python
def retry(max_attempts: int = 3, delay: float = 1.0):
    """Retry the wrapped function up to max_attempts times on failure."""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            last_error = None
            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_error = e
                    print(f"Attempt {attempt} failed: {e}")
                    if attempt < max_attempts:
                        time.sleep(delay)
            raise last_error
        return wrapper
    return decorator

@retry(max_attempts=3, delay=0.5)
def fetch_data(url: str) -> str:
    """Simulate a flaky network call."""
    import random
    if random.random() < 0.7:
        raise ConnectionError("Network timeout")
    return f"Data from {url}"
```

### Stacking Decorators

```python
@timer
@retry(max_attempts=2)
def unreliable_computation(n: int) -> int:
    """Compute something that might fail."""
    import random
    if random.random() < 0.5:
        raise ValueError("Random failure")
    return n ** 2

# Execution order: timer wraps retry wraps unreliable_computation
# Call: timer.wrapper → retry.wrapper → unreliable_computation
```

### Class-based Decorators

```python
class cache:
    """Simple memoization decorator using a class."""

    def __init__(self, func):
        functools.update_wrapper(self, func)
        self.func = func
        self._cache: dict = {}

    def __call__(self, *args):
        if args not in self._cache:
            self._cache[args] = self.func(*args)
        return self._cache[args]

@cache
def fibonacci(n: int) -> int:
    """Return the nth Fibonacci number (memoized)."""
    if n < 2:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

print(fibonacci(50))   # Fast — results are cached
# Use functools.lru_cache for production (more efficient)
```

---

## 2.7 `functools` — Essential Higher-Order Functions

```python
import functools

# lru_cache — Memoize with LRU eviction
@functools.lru_cache(maxsize=128)
def expensive_calc(n: int) -> int:
    return sum(i ** 2 for i in range(n))

print(expensive_calc(1000))   # computed
print(expensive_calc(1000))   # returned from cache instantly

# partial — fix some arguments of a function
def power(base: float, exponent: float) -> float:
    return base ** exponent

square = functools.partial(power, exponent=2)
cube = functools.partial(power, exponent=3)
print(square(5))   # 25
print(cube(3))     # 27

# reduce — fold a sequence into a single value
from functools import reduce
product = reduce(lambda acc, x: acc * x, [1, 2, 3, 4, 5])
print(product)   # 120
```

---

## Best Practices

1. **Keep functions small** — one function, one responsibility. If it needs a long docstring to explain what it does, split it.
2. **Always use `@functools.wraps`** in decorators to preserve `__name__`, `__doc__`, etc.
3. **Avoid mutable default arguments** — use `None` as a sentinel instead.
4. **Type-hint all function signatures** — use `from __future__ import annotations` for forward references.
5. **Prefer list comprehensions over `map`/`filter` with lambdas** for readability.
6. **Use `functools.lru_cache`** for pure functions with expensive repeated calls.
7. **Return meaningful values** — functions that only print are hard to test. Separate computation from I/O.

---

## Exercises

### Exercise 2.1 — Pure Functions (Beginner)
Write a function `is_palindrome(text: str) -> bool` that returns `True` if `text` is a palindrome (ignoring case and spaces).

**Solution:**
```python
def is_palindrome(text: str) -> bool:
    """Return True if text reads the same forwards and backwards (case-insensitive, ignoring spaces)."""
    cleaned = text.replace(" ", "").lower()
    return cleaned == cleaned[::-1]

print(is_palindrome("racecar"))         # True
print(is_palindrome("A man a plan a canal Panama"))  # True
print(is_palindrome("hello"))           # False
```

---

### Exercise 2.2 — Closure Counter (Intermediate)
Create a `make_counter(start=0, step=1)` factory that returns a counter object with `increment()`, `decrement()`, and `reset()` methods (implemented as closures returning a dict of functions).

**Solution:**
```python
def make_counter(start: int = 0, step: int = 1) -> dict:
    """
    Create a counter with increment, decrement, and reset operations.

    Returns:
        Dict with keys 'increment', 'decrement', 'reset', 'value'.
    """
    count = start

    def increment() -> int:
        nonlocal count
        count += step
        return count

    def decrement() -> int:
        nonlocal count
        count -= step
        return count

    def reset() -> int:
        nonlocal count
        count = start
        return count

    def value() -> int:
        return count

    return {"increment": increment, "decrement": decrement,
            "reset": reset, "value": value}

c = make_counter(start=10, step=5)
print(c["value"]())      # 10
print(c["increment"]())  # 15
print(c["increment"]())  # 20
print(c["decrement"]())  # 15
print(c["reset"]())      # 10
```

---

### Exercise 2.3 — Logging Decorator (Intermediate)
Write a `@log_call` decorator that prints the function name, arguments, keyword arguments, and return value every time the function is called.

**Solution:**
```python
import functools

def log_call(func):
    """Decorator that logs function calls with their arguments and return value."""
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        args_repr = [repr(a) for a in args]
        kwargs_repr = [f"{k}={v!r}" for k, v in kwargs.items()]
        signature = ", ".join(args_repr + kwargs_repr)
        print(f"→ Calling {func.__name__}({signature})")
        result = func(*args, **kwargs)
        print(f"← {func.__name__} returned {result!r}")
        return result
    return wrapper

@log_call
def add(a: int, b: int) -> int:
    return a + b

@log_call
def greet(name: str, greeting: str = "Hello") -> str:
    return f"{greeting}, {name}!"

add(3, 5)
greet("Alice", greeting="Hi")
```

---

### Exercise 2.4 — Memoized Fibonacci (Advanced)
Implement Fibonacci using `functools.lru_cache`. Then compare its performance against the naive recursive version using `time.perf_counter`.

**Solution:**
```python
import functools
import time

def fib_naive(n: int) -> int:
    """Naive recursive Fibonacci — exponential time O(2^n)."""
    if n < 2:
        return n
    return fib_naive(n - 1) + fib_naive(n - 2)

@functools.lru_cache(maxsize=None)
def fib_cached(n: int) -> int:
    """Memoized Fibonacci — linear time O(n)."""
    if n < 2:
        return n
    return fib_cached(n - 1) + fib_cached(n - 2)

def benchmark(func, n: int) -> float:
    start = time.perf_counter()
    result = func(n)
    elapsed = time.perf_counter() - start
    print(f"{func.__name__}({n}) = {result} in {elapsed:.6f}s")
    return elapsed

N = 35
benchmark(fib_naive, N)    # ~3s for n=35
benchmark(fib_cached, N)   # <0.0001s
```

---

## Mini-Project — Pipeline Function Composer

Build a `compose(*functions)` utility that returns a new function applying the given functions from right to left (mathematical function composition).

```python
import functools
from typing import Callable, TypeVar

T = TypeVar("T")

def compose(*functions: Callable) -> Callable:
    """
    Compose multiple functions right-to-left.

    compose(f, g, h)(x) == f(g(h(x)))

    Args:
        *functions: Functions to compose.

    Returns:
        A new function that is the composition of all provided functions.
    """
    def composed(value):
        return functools.reduce(lambda v, f: f(v), reversed(functions), value)
    return composed

# Pipeline utilities
def remove_whitespace(text: str) -> str:
    return text.strip()

def to_lowercase(text: str) -> str:
    return text.lower()

def remove_punctuation(text: str) -> str:
    import string
    return text.translate(str.maketrans("", "", string.punctuation))

def tokenize(text: str) -> list[str]:
    return text.split()

# Build a text-preprocessing pipeline
preprocess = compose(tokenize, remove_punctuation, to_lowercase, remove_whitespace)

raw_text = "  Hello, World! Python is AMAZING.  "
tokens = preprocess(raw_text)
print(tokens)   # ['hello', 'world', 'python', 'is', 'amazing']

# Build a number pipeline
normalize = compose(
    lambda x: round(x, 2),
    lambda x: x / 100,
    lambda x: x - min_val,
)
min_val = 10
print(normalize(60))   # (60 - 10) / 100 = 0.5
```

---

## Module Summary

| Concept | Key Takeaway |
|---------|-------------|
| First-class functions | Functions can be passed, returned, and stored like any value |
| Default args | Never use mutable objects (lists, dicts) as defaults |
| `*args` / `**kwargs` | Pack variable positional/keyword args into tuple/dict |
| LEGB | Python searches Local → Enclosing → Global → Built-in |
| Closure | A function + its enclosing environment; use `nonlocal` to write |
| Decorator | A function that wraps another; always use `@functools.wraps` |
| `lru_cache` | Built-in memoization; use `maxsize=None` for unlimited caching |
| Lambda | Short anonymous function; prefer comprehensions for readability |

---

## Quiz

1. What is the LEGB rule and in which order does Python look up names?
2. Why should you never use `[]` as a default argument?
3. What does `@functools.wraps(func)` do in a decorator?
4. What is the difference between a closure and a regular function?
5. What does `*args` collect arguments into? What about `**kwargs`?
6. What is the output of `compose(str, lambda x: x+1, int)("5")`?
7. When would you use `functools.partial`?
8. What is the difference between `map(f, lst)` and `[f(x) for x in lst]`?
9. Why does `[lambda: i for i in range(3)]` produce `[2, 2, 2]` when called?
10. How does `functools.lru_cache` decide when two calls are the same?

**Answers:**
1. Local → Enclosing → Global → Built-in.
2. The default object is created once when the function is defined, shared across all calls.
3. Copies `__name__`, `__doc__`, `__annotations__` etc. from the wrapped function onto the wrapper.
4. A closure captures and retains references to variables from its enclosing scope after that scope has exited.
5. `*args` → `tuple`; `**kwargs` → `dict`.
6. `"6"` — `int("5")=5`, then `5+1=6`, then `str(6)="6"`.
7. When you want to create a specialised version of a function with some arguments pre-filled.
8. `map` returns a lazy iterator; the comprehension returns a fully evaluated list. Both produce the same values.
9. All lambdas close over the same variable `i`; by the time they are called, `i` has its final value `2`.
10. It hashes all positional arguments (must be hashable); same args → same cache key.

# Module 03 — Data Structures

> **Level:** Beginner–Intermediate | **Estimated Time:** 6 hours | **Prerequisites:** Modules 01–02

---

## Learning Objectives

By the end of this module you will be able to:
- Choose the right built-in data structure for each problem
- Use lists, tuples, dictionaries, sets, and frozensets correctly
- Write expressive list, dict, and set comprehensions
- Understand time complexity of common operations (O(1) vs O(n))
- Use `collections` module types: `defaultdict`, `Counter`, `deque`, `namedtuple`
- Apply unpacking and the splat operators `*` and `**`

---

## 3.1 Lists

Lists are **ordered, mutable sequences**. They are Python's most versatile container.

```python
# Creation
empty: list = []
numbers: list[int] = [1, 2, 3, 4, 5]
mixed = [1, "hello", True, 3.14, None]   # lists can hold any type

# Indexing and Slicing
fruits = ["apple", "banana", "cherry", "date", "elderberry"]
print(fruits[0])      # apple      (first)
print(fruits[-1])     # elderberry (last)
print(fruits[1:3])    # ['banana', 'cherry']
print(fruits[::2])    # ['apple', 'cherry', 'elderberry'] (every other)
print(fruits[::-1])   # reversed list

# Mutation
fruits.append("fig")          # add to end          O(1)
fruits.insert(1, "avocado")   # insert at index      O(n)
fruits.extend(["grape", "honeydew"])  # add many     O(k)
removed = fruits.pop()        # remove last, return  O(1)
removed = fruits.pop(0)       # remove at index      O(n)
fruits.remove("banana")       # remove by value      O(n)
fruits.sort()                 # in-place sort        O(n log n)
fruits.reverse()              # in-place reverse     O(n)

# Non-mutating operations
sorted_copy = sorted(fruits)       # new list, original unchanged
length = len(fruits)               # O(1)
count = fruits.count("apple")      # O(n)
index = fruits.index("cherry")     # O(n), raises ValueError if not found

# Check membership — O(n) for list
print("apple" in fruits)           # True
```

### List Comprehensions

List comprehensions are the **Pythonic way** to transform and filter sequences. They are faster than equivalent `for` loops.

```python
# Syntax: [expression for item in iterable if condition]

# Basic transformation
squares = [x ** 2 for x in range(10)]
# [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]

# With filtering
even_squares = [x ** 2 for x in range(10) if x % 2 == 0]
# [0, 4, 16, 36, 64]

# Nested — flatten a 2D matrix
matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
flat = [n for row in matrix for n in row]
# [1, 2, 3, 4, 5, 6, 7, 8, 9]

# String processing
words = ["Hello", "World", "Python"]
lower_words = [w.lower() for w in words]
# ['hello', 'world', 'python']

# Conditional expression in comprehension
labels = ["even" if x % 2 == 0 else "odd" for x in range(6)]
# ['even', 'odd', 'even', 'odd', 'even', 'odd']
```

---

## 3.2 Tuples

Tuples are **ordered, immutable sequences**. Use them for data that should not change.

```python
point = (3, 4)
rgb = (255, 128, 0)
single = (42,)    # Note the trailing comma — (42) is just parentheses!
empty = ()

# Tuples are faster than lists for read-only access
# Use tuples for: coordinates, RGB colours, DB rows, multi-return values

# Tuple unpacking
x, y = point
print(f"x={x}, y={y}")   # x=3, y=4

# Swap without temp variable (uses tuple packing/unpacking)
a, b = 1, 2
a, b = b, a
print(a, b)   # 2 1

# Extended unpacking with *
first, *rest = [1, 2, 3, 4, 5]
print(first)   # 1
print(rest)    # [2, 3, 4, 5]

*head, last = [1, 2, 3, 4, 5]
print(head)    # [1, 2, 3, 4]
print(last)    # 5

first, *middle, last = [1, 2, 3, 4, 5]
print(middle)  # [2, 3, 4]

# Named tuples — give fields meaningful names (read-only struct)
from collections import namedtuple

Point = namedtuple("Point", ["x", "y"])
p = Point(x=3, y=4)
print(p.x, p.y)          # 3 4
print(p)                  # Point(x=3, y=4)
print(p._asdict())        # {'x': 3, 'y': 4}

# Python 3.6+ typed named tuple
from typing import NamedTuple

class Vector(NamedTuple):
    x: float
    y: float
    z: float = 0.0

    def magnitude(self) -> float:
        return (self.x**2 + self.y**2 + self.z**2) ** 0.5

v = Vector(1.0, 2.0, 2.0)
print(v.magnitude())   # 3.0
```

---

## 3.3 Dictionaries

Dictionaries are **key-value mappings** with O(1) average lookup, insertion, and deletion (hash table internally).

```python
# Creation
empty: dict = {}
user = {"name": "Alice", "age": 30, "active": True}
from_keys = dict.fromkeys(["x", "y", "z"], 0)   # {'x': 0, 'y': 0, 'z': 0}

# Access
print(user["name"])           # Alice — KeyError if key missing
print(user.get("email"))      # None — safe, no error
print(user.get("email", "N/A"))  # "N/A" — with default

# Modification
user["email"] = "alice@example.com"    # add/update
user.update({"city": "NYC", "age": 31})  # bulk update
del user["active"]                       # remove key
popped = user.pop("city")               # remove and return, KeyError if missing
popped = user.pop("city", None)         # safe pop with default

# Iteration
for key in user:               # iterates over keys
    print(key)

for key, value in user.items():   # iterates over (key, value) pairs
    print(f"{key}: {value}")

keys = list(user.keys())       # dict_keys view → list
values = list(user.values())   # dict_values view → list

# Check membership — O(1)
print("name" in user)    # True (checks keys only)

# Merging dicts (Python 3.9+)
defaults = {"timeout": 30, "retries": 3}
overrides = {"timeout": 60}
config = defaults | overrides    # {'timeout': 60, 'retries': 3}

# Python 3.5+ spread operator
config = {**defaults, **overrides}   # same as above

# Nested dicts
database = {
    "users": {
        "alice": {"email": "alice@ex.com", "role": "admin"},
        "bob":   {"email": "bob@ex.com",   "role": "user"},
    }
}
print(database["users"]["alice"]["role"])   # admin
```

### Dict Comprehensions

```python
# {key_expr: value_expr for item in iterable if condition}
squares = {x: x**2 for x in range(1, 6)}
# {1: 1, 2: 4, 3: 9, 4: 16, 5: 25}

# Invert a dict
original = {"a": 1, "b": 2, "c": 3}
inverted = {v: k for k, v in original.items()}
# {1: 'a', 2: 'b', 3: 'c'}

# Filter
users = {"alice": "admin", "bob": "user", "carol": "admin"}
admins = {name: role for name, role in users.items() if role == "admin"}
# {'alice': 'admin', 'carol': 'admin'}
```

---

## 3.4 Sets

Sets are **unordered collections of unique elements**. Use them for membership testing and deduplication.

```python
# Creation
empty_set = set()   # NOT {} — that's an empty dict!
primes = {2, 3, 5, 7, 11, 13}
from_list = set([1, 2, 2, 3, 3, 3])   # {1, 2, 3} — deduplicates

# O(1) membership test — much faster than list for large collections
print(7 in primes)          # True
print(4 in primes)          # False

# Mutation
primes.add(17)
primes.discard(2)           # safe remove (no error if missing)
primes.remove(3)            # raises KeyError if missing

# Set operations — the power of sets
a = {1, 2, 3, 4, 5}
b = {4, 5, 6, 7, 8}

print(a | b)    # Union:        {1, 2, 3, 4, 5, 6, 7, 8}
print(a & b)    # Intersection: {4, 5}
print(a - b)    # Difference:   {1, 2, 3}  (in a but not b)
print(a ^ b)    # Symmetric difference: {1, 2, 3, 6, 7, 8}

# Subset / superset
print({1, 2}.issubset(a))       # True
print(a.issuperset({1, 2}))     # True
print(a.isdisjoint({6, 7}))     # True (no common elements)

# Set comprehension
even_set = {x for x in range(20) if x % 2 == 0}

# frozenset — immutable set (can be used as dict key)
frozen = frozenset([1, 2, 3])
lookup = {frozen: "key!"}   # valid dict key
```

**When to use sets:**
- Deduplication: `unique_items = list(set(items))`
- Fast membership: "is X in this group?"
- Mathematical set operations on collections

---

## 3.5 `collections` Module

```python
from collections import defaultdict, Counter, deque, OrderedDict

# defaultdict — auto-creates missing keys
word_list = ["apple", "banana", "apple", "cherry", "banana", "apple"]

# Regular dict approach (verbose)
counts = {}
for word in word_list:
    if word not in counts:
        counts[word] = 0
    counts[word] += 1

# defaultdict approach (clean)
counts = defaultdict(int)
for word in word_list:
    counts[word] += 1
print(dict(counts))   # {'apple': 3, 'banana': 2, 'cherry': 1}

# Group items by a key
groups = defaultdict(list)
data = [("Alice", "eng"), ("Bob", "eng"), ("Carol", "pm"), ("David", "pm")]
for name, dept in data:
    groups[dept].append(name)
print(dict(groups))   # {'eng': ['Alice', 'Bob'], 'pm': ['Carol', 'David']}

# Counter — count elements in any iterable
text = "the quick brown fox jumps over the lazy dog"
char_count = Counter(text)
print(char_count.most_common(5))   # [(' ', 8), ('o', 4), ...]

word_count = Counter(text.split())
print(word_count.most_common(3))   # [('the', 2), ...]

# Counter arithmetic
c1 = Counter(["a", "b", "a", "c"])
c2 = Counter(["a", "b", "b"])
print(c1 + c2)   # Counter({'a': 3, 'b': 3, 'c': 1})
print(c1 - c2)   # Counter({'a': 1, 'c': 1})

# deque — double-ended queue; O(1) append/pop on both ends
from collections import deque

queue = deque()
queue.append("first")     # right append
queue.append("second")
queue.appendleft("zero")  # left append
print(queue)              # deque(['zero', 'first', 'second'])
queue.popleft()           # efficient O(1) — unlike list.pop(0) which is O(n)

# deque as a sliding window
def moving_average(data: list[float], window: int) -> list[float]:
    """Compute moving average using a deque as window buffer."""
    window_data = deque(maxlen=window)
    averages = []
    for value in data:
        window_data.append(value)
        if len(window_data) == window:
            averages.append(sum(window_data) / window)
    return averages

prices = [10, 11, 12, 10, 9, 11, 13, 12]
print(moving_average(prices, 3))   # [11.0, 11.0, 10.33, 10.0, 11.0, 12.0]
```

---

## 3.6 Time Complexity Reference

| Operation | list | dict | set |
|-----------|------|------|-----|
| Index `a[i]` | O(1) | — | — |
| `x in a` | O(n) | **O(1)** | **O(1)** |
| Append | O(1) | — | O(1) |
| Insert at index | O(n) | — | — |
| Delete | O(n) | **O(1)** | O(1) |
| Iteration | O(n) | O(n) | O(n) |

> **Key insight:** Use a `set` or `dict` when you need fast membership testing. Using `in` on a list with 1M items is 1,000,000× slower than a set.

---

## Best Practices

1. **Choose the right structure:** list (ordered/mutable) → tuple (ordered/immutable) → set (unique/fast membership) → dict (key-value mapping).
2. **Prefer comprehensions** over `append`-in-a-loop — more readable and 30–50% faster.
3. **Use `dict.get(key, default)`** instead of `key in dict` check + `dict[key]` access.
4. **Use `Counter`** instead of manual counting loops.
5. **Use `deque`** instead of `list` when you need O(1) operations on both ends.
6. **Never mutate a list/dict while iterating over it** — iterate over a copy or collect changes separately.
7. **Use `frozenset` as dict key** when you need a set-valued key.

```python
# Anti-pattern: modifying a list while iterating
items = [1, 2, 3, 4, 5]
for item in items:
    if item % 2 == 0:
        items.remove(item)   # BUG: skips elements

# Correct: filter into a new list
items = [item for item in items if item % 2 != 0]
```

---

## Exercises

### Exercise 3.1 — Anagram Checker (Beginner)
Write `are_anagrams(a: str, b: str) -> bool` using `Counter`.

**Solution:**
```python
from collections import Counter

def are_anagrams(a: str, b: str) -> bool:
    """Return True if a and b are anagrams (same letters, different order)."""
    return Counter(a.lower().replace(" ", "")) == Counter(b.lower().replace(" ", ""))

print(are_anagrams("listen", "silent"))         # True
print(are_anagrams("Astronomer", "Moon starer"))  # True
print(are_anagrams("hello", "world"))           # False
```

---

### Exercise 3.2 — Word Frequency (Intermediate)
Given a block of text, return the top-N most frequent words (excluding common stop words).

**Solution:**
```python
from collections import Counter

STOP_WORDS = {"the", "a", "an", "is", "in", "of", "and", "to", "it", "that", "was"}

def top_words(text: str, n: int = 10) -> list[tuple[str, int]]:
    """Return the top-n most frequent non-stop words in text."""
    words = text.lower().split()
    cleaned = [w.strip(".,!?;:\"'") for w in words]
    filtered = [w for w in cleaned if w and w not in STOP_WORDS]
    return Counter(filtered).most_common(n)

text = "Python is a great language. Python is used in data science and AI. Python is awesome."
print(top_words(text, 5))
# [('python', 3), ('is', 2→filtered), ...]
```

---

### Exercise 3.3 — Two-Sum Problem (Intermediate)
Given a list of integers and a target sum, return the indices of two numbers that add up to the target. Solve in O(n) using a dict.

**Solution:**
```python
def two_sum(numbers: list[int], target: int) -> tuple[int, int] | None:
    """
    Return indices of two numbers that sum to target.
    Time: O(n) | Space: O(n)
    """
    seen: dict[int, int] = {}   # value → index

    for i, num in enumerate(numbers):
        complement = target - num
        if complement in seen:
            return (seen[complement], i)
        seen[num] = i

    return None

print(two_sum([2, 7, 11, 15], 9))    # (0, 1) → 2 + 7 = 9
print(two_sum([3, 2, 4], 6))         # (1, 2) → 2 + 4 = 6
print(two_sum([1, 2, 3], 10))        # None
```

---

### Exercise 3.4 — Group By (Advanced)
Implement a `group_by(items, key_func)` function that groups items using a callable key.

**Solution:**
```python
from collections import defaultdict
from typing import TypeVar, Callable

T = TypeVar("T")
K = TypeVar("K")

def group_by(items: list[T], key_func: Callable[[T], K]) -> dict[K, list[T]]:
    """Group items by the result of key_func."""
    result: dict[K, list[T]] = defaultdict(list)
    for item in items:
        result[key_func(item)].append(item)
    return dict(result)

words = ["apple", "banana", "avocado", "blueberry", "cherry", "apricot"]
by_first_letter = group_by(words, lambda w: w[0])
print(by_first_letter)
# {'a': ['apple', 'avocado', 'apricot'], 'b': ['banana', 'blueberry'], 'c': ['cherry']}

numbers = range(-5, 6)
by_sign = group_by(list(numbers), lambda n: "negative" if n < 0 else ("zero" if n == 0 else "positive"))
print(by_sign)
```

---

## Mini-Project — Inventory Management System

```python
from collections import defaultdict
from typing import Optional

class Inventory:
    """
    A simple inventory management system using dicts and sets.

    Demonstrates real-world data structure usage patterns.
    """

    def __init__(self) -> None:
        self._stock: dict[str, int] = {}           # item → quantity
        self._categories: dict[str, set[str]] = defaultdict(set)  # category → items
        self._prices: dict[str, float] = {}        # item → price

    def add_item(self, name: str, quantity: int, price: float, category: str) -> None:
        """Add or restock an item."""
        self._stock[name] = self._stock.get(name, 0) + quantity
        self._prices[name] = price
        self._categories[category].add(name)

    def sell_item(self, name: str, quantity: int) -> bool:
        """Sell quantity units of item. Returns False if insufficient stock."""
        if self._stock.get(name, 0) < quantity:
            return False
        self._stock[name] -= quantity
        if self._stock[name] == 0:
            del self._stock[name]
        return True

    def get_low_stock(self, threshold: int = 5) -> dict[str, int]:
        """Return items with stock at or below threshold."""
        return {item: qty for item, qty in self._stock.items() if qty <= threshold}

    def get_category_value(self, category: str) -> float:
        """Return total value (stock * price) of all items in a category."""
        items = self._categories.get(category, set())
        return sum(
            self._stock.get(item, 0) * self._prices.get(item, 0)
            for item in items
        )

    def search(self, query: str) -> list[str]:
        """Return items whose names contain the query string."""
        q = query.lower()
        return [item for item in self._stock if q in item.lower()]

    def report(self) -> None:
        """Print a formatted inventory report."""
        print(f"\n{'INVENTORY REPORT':=^50}")
        print(f"{'Item':<20} {'Stock':>8} {'Price':>10} {'Value':>10}")
        print("-" * 50)
        total_value = 0.0
        for item in sorted(self._stock):
            qty = self._stock[item]
            price = self._prices[item]
            value = qty * price
            total_value += value
            print(f"{item:<20} {qty:>8} {price:>10.2f} {value:>10.2f}")
        print("=" * 50)
        print(f"{'Total Value':>40} {total_value:>10.2f}")
        low = self.get_low_stock()
        if low:
            print(f"\nLow Stock Alert: {list(low.keys())}")


# --- Demo ---
inv = Inventory()
inv.add_item("Python Book", 50, 39.99, "books")
inv.add_item("Data Science Book", 3, 49.99, "books")
inv.add_item("USB-C Cable", 100, 9.99, "electronics")
inv.add_item("Laptop Stand", 4, 29.99, "electronics")
inv.add_item("Notebook", 200, 2.99, "stationery")

inv.sell_item("Python Book", 47)
inv.sell_item("Laptop Stand", 1)

inv.report()
print(f"\nBooks value: ${inv.get_category_value('books'):.2f}")
print(f"Search 'book': {inv.search('book')}")
```

---

## Module Summary

| Structure | Ordered | Mutable | Unique | Lookup |
|-----------|---------|---------|--------|--------|
| `list` | ✓ | ✓ | ✗ | O(n) |
| `tuple` | ✓ | ✗ | ✗ | O(n) |
| `dict` | ✓* | ✓ | keys only | O(1) |
| `set` | ✗ | ✓ | ✓ | O(1) |
| `frozenset` | ✗ | ✗ | ✓ | O(1) |

*Dicts preserve insertion order since Python 3.7.

---

## Quiz

1. What is the time complexity of `x in my_list` vs `x in my_set`?
2. Why is `{}` an empty dict, not an empty set?
3. What does `list.pop(0)` have O(n) complexity?
4. What is the difference between `dict.get("key")` and `dict["key"]`?
5. When would you use a `defaultdict` over a regular `dict`?
6. What makes a `frozenset` different from a `set`?
7. What does the `*` operator do in `first, *rest = [1,2,3,4]`?
8. How does `Counter` handle arithmetic between two Counter objects?
9. Why should you use `deque` instead of a list for a queue?
10. What is the output of `{1, 2, 3} & {2, 3, 4, 5}`?

# Module 03 — Data Structures

> **Level:** Beginner–Intermediate | **Estimated Time:** 6 hours | **Prerequisites:** Modules 01–02

---

## Learning Objectives

By the end of this module you will be able to:
- Choose the right built-in data structure for each problem (and explain WHY in a system design interview)
- Use lists, tuples, dictionaries, sets, and frozensets with deep understanding of their internals
- Write expressive, Pythonic list, dict, and set comprehensions
- Reason about time complexity: O(1), O(log n), O(n), O(n log n) — and why it matters at scale
- Use `collections` module types: `defaultdict`, `Counter`, `deque`, `namedtuple`, `OrderedDict`
- Apply data structures to solve real system design problems (caches, queues, rate limiters)
- Apply unpacking, the splat `*`/`**` operators, and walrus operator `:=`

---

## The Big Picture — Which Structure When?

Choosing the wrong data structure is one of the most common causes of slow systems. Before diving in, internalize this decision map:

```
Need ordered items?
  └─ Yes: Can items change after creation?
  │     ├─ Yes → LIST  [1, 2, 3]           O(1) append, O(n) insert/search
  │     └─ No  → TUPLE (1, 2, 3)           immutable, hashable, faster than list
  └─ No: Need key → value mapping?
        ├─ Yes → DICT  {"key": value}       O(1) lookup by key (hash table)
        └─ No  → SET   {1, 2, 3}           O(1) membership, deduplication, set math
```

| Structure   | Ordered   | Mutable | Duplicates | Lookup    | Best For |
|-------------|-----------|---------|------------|-----------|----------|
| `list`      | ✅ (index)| ✅      | ✅         | O(n)      | Sequences, stacks, ordered data |
| `tuple`     | ✅ (index)| ❌      | ✅         | O(n)      | Fixed records, dict keys, return values |
| `dict`      | ✅ (3.7+) | ✅      | Keys: ❌   | **O(1)**  | Config, caches, fast lookup by name |
| `set`       | ❌        | ✅      | ❌         | **O(1)**  | Uniqueness checks, intersection, union |
| `frozenset` | ❌        | ❌      | ❌         | **O(1)**  | Immutable set, dict key |
| `deque`     | ✅        | ✅      | ✅         | O(n) mid  | Queues, sliding windows, BFS |
| `Counter`   | By count  | ✅      | N/A        | **O(1)**  | Frequency counting, top-K |

**System Design Rule:** When you have 1 million items and need to check `if x in collection` thousands of times per second → always use a `set` or `dict`, never a `list`.

---

## 3.1 Lists — Ordered, Mutable Sequences

### Internal Representation — Dynamic Array

A Python list is a **dynamic array** holding pointers (memory addresses) to objects. The list itself doesn't store the objects; it stores references to where they live.

```
list: ["apple", "banana", "cherry"]

Memory layout:
┌────────────────────────────────────────┐
│  list object                           │
│  length = 3                            │
│  capacity = 4  (pre-allocated)         │
│  data ──►  [ ptr0 | ptr1 | ptr2 | _  ]│
│              │       │       │         │
│              ▼       ▼       ▼         │
│           "apple" "banana" "cherry"    │
└────────────────────────────────────────┘

Why this matters:
  list[i]          → O(1)  — direct pointer jump
  len(list)        → O(1)  — stored as an attribute
  list.append(x)   → O(1) amortised — writes to next slot; resizes when full
  list.insert(0,x) → O(n)  — all pointers shift right
  x in list        → O(n)  — must scan pointers one by one
```

```python
# ──────────────────────────────────────────────────────────────────────────
# Creating lists
# ──────────────────────────────────────────────────────────────────────────
empty   = []                            # empty list literal — fastest
numbers = [1, 2, 3, 4, 5]              # integer list
from_range  = list(range(1, 6))        # [1, 2, 3, 4, 5]
from_string = list("hello")            # ['h', 'e', 'l', 'l', 'o']

# ── PITFALL: nested list with * shares the same inner list ──────────────
wrong = [[0] * 3] * 3       # one inner list, referenced 3 times!
wrong[0][0] = 99
print(wrong)                # [[99,0,0],[99,0,0],[99,0,0]] ← ALL changed

correct = [[0] * 3 for _ in range(3)]  # 3 independent inner lists
correct[0][0] = 99
print(correct)              # [[99,0,0],[0,0,0],[0,0,0]] ← only row 0

# ──────────────────────────────────────────────────────────────────────────
# Indexing: list[start:stop:step]  O(1) for single index, O(k) for slice
# ──────────────────────────────────────────────────────────────────────────
fruits = ["apple", "banana", "cherry", "date", "elderberry"]
#             0        1         2        3          4         ← positive
#            -5       -4        -3       -2         -1         ← negative

print(fruits[0])        # 'apple'       — first
print(fruits[-1])       # 'elderberry'  — last
print(fruits[1:3])      # ['banana','cherry']  — stop is EXCLUSIVE
print(fruits[::2])      # ['apple','cherry','elderberry']  — every 2nd
print(fruits[::-1])     # reversed  — step=-1 walks backwards
fruits[1:3] = ["avocado"]   # slice assignment: replace 2 items with 1

# ──────────────────────────────────────────────────────────────────────────
# Mutation operations with time complexity
# ──────────────────────────────────────────────────────────────────────────
items = [1, 2, 3]
items.append(4)             # O(1) amortised — add to end
items.insert(0, 0)          # O(n)  — shift all elements right
items.extend([5, 6])        # O(k)  — k = len of argument
last = items.pop()          # O(1)  — remove and return last
first = items.pop(0)        # O(n)  — shift all elements left (use deque!)
items.remove(3)             # O(n)  — scan to find, then shift
items.sort()                # O(n log n)  — Timsort, in-place
items.reverse()             # O(n)  — in-place

sorted_copy = sorted(items) # O(n log n) — returns NEW list, original unchanged
print(3 in items)           # O(n)  — scan; for O(1) use a set

# ──────────────────────────────────────────────────────────────────────────
# Sorting with a custom key
# ──────────────────────────────────────────────────────────────────────────
people = [{"name": "Charlie", "age": 35}, {"name": "Alice", "age": 28}]
by_age  = sorted(people, key=lambda p: p["age"])          # ascending
by_name = sorted(people, key=lambda p: p["name"])         # alphabetical
by_age_desc = sorted(people, key=lambda p: p["age"], reverse=True)

# Sort by multiple criteria — tuple comparison
students = [("Alice", 90), ("Bob", 85), ("Carol", 90)]
by_score_name = sorted(students, key=lambda s: (-s[1], s[0]))
# Sort by score descending (-score), then name ascending
print(by_score_name)   # [('Alice', 90), ('Carol', 90), ('Bob', 85)]
```

### List Comprehensions — Pythonic Transformations

```python
# ── Basic pattern: [expression for item in iterable if condition] ─────────

numbers = list(range(1, 11))   # [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# Transform every element:
squares = [n ** 2 for n in numbers]   # [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]

# Filter then transform:
even_squares = [n ** 2 for n in numbers if n % 2 == 0]   # [4, 16, 36, 64, 100]

# Conditional expression (ternary) inside:
labels = ["even" if n % 2 == 0 else "odd" for n in numbers]

# Flatten a 2D structure (read as nested for-loops):
matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
flat = [cell for row in matrix for cell in row]   # [1,2,3,4,5,6,7,8,9]
# Rule: outer loop first, inner loop second — same order as nested for

# Transpose a matrix:
transposed = [[row[i] for row in matrix] for i in range(3)]
# [[1,4,7],[2,5,8],[3,6,9]]

# ── Generator expressions — lazy, memory-efficient alternative ───────────
# Use () instead of [] → computes values on demand, not all at once
gen = (n ** 2 for n in range(1_000_000))   # no memory allocated yet!
print(next(gen))    # 0 — computes only the first value
print(next(gen))    # 1

# When to use generator vs list:
total = sum(n ** 2 for n in range(1_000_000))   # generator: ~8MB RAM
total = sum([n ** 2 for n in range(1_000_000)]) # list: ~40MB RAM — avoid!
```

---

## 3.2 Tuples — Ordered, Immutable Sequences

**Analogy:** A list is a shopping cart (contents change freely). A tuple is a receipt (a permanent record — cannot be altered).

```python
# ──────────────────────────────────────────────────────────────────────────
# Creating tuples
# ──────────────────────────────────────────────────────────────────────────
empty  = ()
single = (42,)          # ← the trailing comma is MANDATORY for single-element tuples
                        # (42) without comma is just the integer 42 in parentheses!
coords = (3.0, 4.0)
rgb    = (255, 128, 0)
no_paren = 1, 2, 3      # parentheses are optional — this IS a tuple
print(type(no_paren))   # <class 'tuple'>

# ──────────────────────────────────────────────────────────────────────────
# Why use tuples over lists?
# 1. Immutability = safety (callers can't accidentally modify your data)
# 2. Hashable     = can be used as dict keys and in sets
# 3. Performance  = ~20% faster than list for creation and iteration
# ──────────────────────────────────────────────────────────────────────────
d = {(0, 0): "origin", (1, 0): "right"}   # tuples as dict keys ← valid
# d = {[0, 0]: "origin"}                  # lists as dict keys  ← TypeError!

# ──────────────────────────────────────────────────────────────────────────
# Tuple unpacking — one of Python's most powerful and idiomatic features
# ──────────────────────────────────────────────────────────────────────────
x, y       = (3, 4)             # assign each element to its own variable
a, b       = b, a               # swap WITHOUT temp variable (packs to tuple, unpacks)
first, *rest  = (1, 2, 3, 4, 5)  # *rest captures remainder as a LIST
*init, last   = (1, 2, 3, 4, 5)
head, *mid, tail = (1, 2, 3, 4, 5)

print(first, rest)      # 1 [2, 3, 4, 5]
print(init, last)       # [1, 2, 3, 4] 5
print(head, mid, tail)  # 1 [2, 3, 4] 5

# Unpack from a function returning multiple values:
def bounding_box(points: list[tuple]) -> tuple[float, float, float, float]:
    """Return (min_x, min_y, max_x, max_y) of a list of (x,y) points."""
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return min(xs), min(ys), max(xs), max(ys)

min_x, min_y, max_x, max_y = bounding_box([(1,2),(3,4),(0,5)])
print(f"Box: ({min_x},{min_y}) to ({max_x},{max_y})")

# ──────────────────────────────────────────────────────────────────────────
# NamedTuple — tuple with named fields (best of both worlds)
# ──────────────────────────────────────────────────────────────────────────
from typing import NamedTuple

class Point(NamedTuple):
    """2D point with immutable (x, y) coordinates."""
    x: float
    y: float

    def distance_to(self, other: "Point") -> float:
        """Euclidean distance to another point."""
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5

p1 = Point(0.0, 0.0)
p2 = Point(3.0, 4.0)
print(p2.x, p2.y)           # 3.0 4.0  — named access
print(p2[0], p2[1])         # 3.0 4.0  — index access (still a tuple)
print(p1.distance_to(p2))   # 5.0
print(p2)                   # Point(x=3.0, y=4.0) — descriptive repr

# Use namedtuple/NamedTuple for:
# - Database rows: Row = namedtuple("Row", ["id","name","email"])
# - Config entries, API responses, geographic coordinates
```

---

## 3.3 Dictionaries — Hash Tables for Key-Value Mapping

### How Hash Tables Work

```
dict["alice"] = 92

Step 1: hash("alice") → 7891234 (some integer)
Step 2: slot = 7891234 % table_size → e.g., slot 4
Step 3: store (key="alice", value=92) at slot 4

dict["alice"]  (lookup)
Step 1: hash("alice") → 7891234
Step 2: slot = 4
Step 3: return value at slot 4 → 92       ← O(1)!

Why keys must be hashable:
  - int, str, float, tuple → hashable ✅
  - list, dict, set → not hashable ❌ (they can change, hash would be invalid)
```

```python
# ──────────────────────────────────────────────────────────────────────────
# Creating dicts
# ──────────────────────────────────────────────────────────────────────────
empty    = {}                                   # empty dict (NOT empty set!)
user     = {"name": "Alice", "age": 30}         # literal — most readable
from_kw  = dict(host="localhost", port=8080)    # keyword syntax
from_pairs = dict([("a", 1), ("b", 2)])         # from iterable of pairs
zeroed   = dict.fromkeys(["x", "y", "z"], 0)   # {'x':0,'y':0,'z':0}

# ──────────────────────────────────────────────────────────────────────────
# Access patterns — O(1)
# ──────────────────────────────────────────────────────────────────────────
scores = {"Alice": 92, "Bob": 85, "Carol": 78}

print(scores["Alice"])          # 92
# scores["Dave"]                # KeyError — key doesn't exist!

print(scores.get("Dave"))       # None  — safe, no error
print(scores.get("Dave", 0))    # 0     — with explicit default

# setdefault — get if exists, else set AND return default
scores.setdefault("Eve", 0)     # adds Eve:0 only if key missing
scores.setdefault("Alice", 0)   # does NOT change Alice:92 — already exists
print(scores["Alice"])          # 92  — unchanged

# ──────────────────────────────────────────────────────────────────────────
# Modifying dicts
# ──────────────────────────────────────────────────────────────────────────
scores["Frank"] = 88            # add new key-value pair
scores["Alice"] = 95            # update existing key
del scores["Bob"]               # remove key — KeyError if missing
score = scores.pop("Carol")     # remove and return value — KeyError if missing
score = scores.pop("Carol", 0)  # safe pop with default

scores.update({"George": 72, "Alice": 97})  # bulk update/add

# Python 3.9+ merge operators:
defaults = {"timeout": 30, "retries": 3, "debug": False}
overrides = {"timeout": 60, "debug": True}
merged = defaults | overrides   # new dict; overrides wins on conflicts
defaults |= overrides           # in-place merge

# ──────────────────────────────────────────────────────────────────────────
# Iterating — insertion order is preserved (Python 3.7+)
# ──────────────────────────────────────────────────────────────────────────
for name in scores:                     # iterate over keys
    print(name)

for score_val in scores.values():       # iterate over values
    print(score_val)

for name, score_val in scores.items():  # iterate over (key, value) pairs
    print(f"{name}: {score_val}")       # ← most common pattern

# Sorted iteration:
for name in sorted(scores, key=scores.get, reverse=True):
    print(f"{name}: {scores[name]}")    # highest score first

# ──────────────────────────────────────────────────────────────────────────
# Dict comprehensions
# ──────────────────────────────────────────────────────────────────────────
squares   = {n: n**2 for n in range(1, 6)}       # {1:1, 2:4, 3:9, 4:16, 5:25}
inverted  = {v: k for k, v in squares.items()}   # swap keys and values
passing   = {k: v for k, v in scores.items() if v >= 80}  # filter
scaled    = {k: round(v/100, 2) for k, v in scores.items()}  # transform values

# ──────────────────────────────────────────────────────────────────────────
# Common patterns
# ──────────────────────────────────────────────────────────────────────────

# Pattern 1: Grouping (without defaultdict)
words = ["apple", "ant", "bat", "avocado", "cat"]
groups: dict[str, list] = {}
for w in words:
    groups.setdefault(w[0], []).append(w)
print(groups)   # {'a': ['apple','ant','avocado'], 'b': ['bat'], 'c': ['cat']}

# Pattern 2: Counting
text = "hello world hello python world"
word_freq: dict[str, int] = {}
for word in text.split():
    word_freq[word] = word_freq.get(word, 0) + 1
print(word_freq)    # {'hello':2, 'world':2, 'python':1}

# Pattern 3: Config with fallback chain
def get_config(key: str, *sources: dict) -> object:
    """Search multiple config dicts, return first match."""
    for source in sources:
        if key in source:
            return source[key]
    raise KeyError(f"'{key}' not found in any config source")

env_vars = {"DB_HOST": "prod.db.com"}
defaults_cfg = {"DB_HOST": "localhost", "DB_PORT": 5432}
print(get_config("DB_HOST", env_vars, defaults_cfg))   # 'prod.db.com'
print(get_config("DB_PORT", env_vars, defaults_cfg))   # 5432
```

---

## 3.4 Sets — O(1) Membership and Set Mathematics

```python
# ──────────────────────────────────────────────────────────────────────────
# Creating sets — MUST use set() for empty (not {}!)
# ──────────────────────────────────────────────────────────────────────────
empty   = set()         # {} creates an empty DICT, not a set!
primes  = {2, 3, 5, 7, 11, 13}
unique  = set([1, 2, 2, 3, 3, 3, 4])   # {1, 2, 3, 4} — deduplication

# ──────────────────────────────────────────────────────────────────────────
# Membership test — O(1) via hash table
# ──────────────────────────────────────────────────────────────────────────
import time

million_list = list(range(1_000_000))
million_set  = set(range(1_000_000))

t0 = time.perf_counter()
_ = 999_999 in million_list       # O(n): scan all elements
print(f"List:  {time.perf_counter()-t0:.5f}s")   # ~0.03s

t0 = time.perf_counter()
_ = 999_999 in million_set        # O(1): hash lookup
print(f"Set:   {time.perf_counter()-t0:.7f}s")   # ~0.0000001s  ← 100,000x faster

# ──────────────────────────────────────────────────────────────────────────
# Mutation
# ──────────────────────────────────────────────────────────────────────────
s = {1, 2, 3}
s.add(4)            # add one element — O(1); no-op if already present
s.update([5, 6])    # add multiple elements from iterable
s.remove(1)         # O(1); raises KeyError if missing
s.discard(99)       # O(1); NO error if missing — use this when uncertain
popped = s.pop()    # remove and return ARBITRARY element (sets are unordered)

# ──────────────────────────────────────────────────────────────────────────
# Mathematical set operations — extremely useful for data analysis
# ──────────────────────────────────────────────────────────────────────────
premium_users = {"alice", "bob", "carol", "dave"}
active_users  = {"bob", "carol", "eve", "frank"}

# Union: everyone
all_users = premium_users | active_users
print(all_users)    # {'alice','bob','carol','dave','eve','frank'}

# Intersection: premium AND active
vip = premium_users & active_users
print(vip)          # {'bob', 'carol'}

# Difference: premium but NOT active (churned premium)
churned = premium_users - active_users
print(churned)      # {'alice', 'dave'}

# Symmetric difference: in one but not both (exclusive)
unique_to_each = premium_users ^ active_users
print(unique_to_each)   # {'alice','dave','eve','frank'}

# Subset/superset checks:
print({"bob"}.issubset(premium_users))      # True
print(premium_users.issuperset({"bob"}))    # True
print({"alice"}.isdisjoint({"bob","carol"}))   # True — no overlap

# ──────────────────────────────────────────────────────────────────────────
# Set comprehension
# ──────────────────────────────────────────────────────────────────────────
even_set = {n for n in range(20) if n % 2 == 0}
char_set = {c.lower() for c in "Hello World" if c.isalpha()}

# frozenset — immutable set; can be used as a dict key
edge = frozenset({"A", "B"})        # undirected graph edge
graph = {frozenset({"A","B"}): 5, frozenset({"B","C"}): 3}
print(graph[frozenset({"B","A"})])  # 5 — same edge regardless of order
```

---

## 3.5 `collections` Module — Specialized Containers

```python
from collections import defaultdict, Counter, deque, OrderedDict
from typing import Callable, TypeVar

# ──────────────────────────────────────────────────────────────────────────
# defaultdict — auto-creates missing key with a factory function
# ──────────────────────────────────────────────────────────────────────────
# PROBLEM: Grouping requires checking if the key exists first
words = ["apple", "ant", "bat", "avocado", "cat", "cherry"]

# Without defaultdict (verbose):
groups_plain: dict = {}
for word in words:
    if word[0] not in groups_plain:
        groups_plain[word[0]] = []
    groups_plain[word[0]].append(word)

# With defaultdict(list) — clean and idiomatic:
# The 'list' factory is called with no args when a key is missing → creates []
groups = defaultdict(list)
for word in words:
    groups[word[0]].append(word)   # no KeyError; missing key auto-gets []
print(dict(groups))   # {'a':['apple','ant','avocado'],'b':['bat'],'c':['cat','cherry']}

# defaultdict(int) — missing keys get 0; great for counting
char_freq = defaultdict(int)
for char in "hello world":
    char_freq[char] += 1    # no need to initialise to 0

# defaultdict(set) — great for relationship graphs
followers = defaultdict(set)
follows = [("Alice","Bob"), ("Alice","Carol"), ("Bob","Alice")]
for follower, followed in follows:
    followers[followed].add(follower)
print(dict(followers))  # {'Bob':{'Alice'},'Carol':{'Alice'},'Alice':{'Bob'}}

# ──────────────────────────────────────────────────────────────────────────
# Counter — count occurrences, find top-K, do arithmetic on counts
# ──────────────────────────────────────────────────────────────────────────
# Counter is a dict subclass where missing keys return 0 (not KeyError)

text = "the quick brown fox jumps over the lazy dog"
word_count = Counter(text.split())
print(word_count.most_common(3))    # [('the',2), ('quick',1), ...]
print(word_count["the"])            # 2
print(word_count["xyz"])            # 0  ← missing keys return 0, not KeyError

char_count = Counter("mississippi")
print(char_count)   # Counter({'i':4,'s':4,'p':2,'m':1})

# Counter arithmetic — useful for comparing distributions
inventory   = Counter({"apple": 5, "banana": 3, "cherry": 8})
sold        = Counter({"apple": 2, "banana": 3, "cherry": 1})
remaining   = inventory - sold              # Counter({'cherry':7,'apple':3})
restock     = (sold - inventory) + Counter()  # what we owe (positive only)

# ──────────────────────────────────────────────────────────────────────────
# deque — double-ended queue with O(1) append/pop on BOTH ends
# ──────────────────────────────────────────────────────────────────────────
# list.pop(0) and list.insert(0,x) are O(n) — they shift all elements.
# deque.popleft() and deque.appendleft() are O(1) — constant time always.

from collections import deque

# As a queue (FIFO — first in, first out):
request_queue: deque = deque()
request_queue.append("req1")            # enqueue at right
request_queue.append("req2")
request_queue.append("req3")
first = request_queue.popleft()         # dequeue from left — O(1)
print(first)                            # 'req1'

# As a sliding window with maxlen:
# When maxlen is set, appending to a full deque auto-removes from the other end
window: deque = deque(maxlen=3)         # keep only last 3 items
for n in [10, 20, 30, 40, 50]:
    window.append(n)
    if len(window) == 3:
        avg = sum(window) / 3
        print(f"Window {list(window)}: avg={avg:.1f}")
# Window [10,20,30]: avg=20.0
# Window [20,30,40]: avg=30.0
# Window [30,40,50]: avg=40.0

# As a stack (LIFO):
stack: deque = deque()
stack.append("a")           # push
stack.append("b")
stack.append("c")
print(stack.pop())          # pop from right — 'c'
print(stack.pop())          # 'b'
```

---

## 3.6 Time Complexity Reference

| Operation       | `list`     | `dict`    | `set`     | `deque`   |
|----------------|------------|-----------|-----------|-----------|
| Index `a[i]`   | **O(1)**   | —         | —         | O(n)      |
| `x in a`       | O(n)       | **O(1)**  | **O(1)**  | O(n)      |
| Append right   | O(1)*      | —         | O(1)*     | **O(1)**  |
| Append left    | O(n)       | —         | —         | **O(1)**  |
| Pop right      | **O(1)**   | —         | O(1)*     | **O(1)**  |
| Pop left       | O(n)       | —         | —         | **O(1)**  |
| Insert at i    | O(n)       | —         | —         | O(n)      |
| Delete key     | O(n)       | **O(1)**  | **O(1)**  | O(n)      |
| Iteration      | O(n)       | O(n)      | O(n)      | O(n)      |
| `len(a)`       | **O(1)**   | **O(1)**  | **O(1)**  | **O(1)**  |

*\* amortised — occasional resizing is O(n) but averages out*

---

## 3.7 System Design Applications

### Pattern 1 — LRU Cache with `dict` + `deque`

```python
from collections import deque, OrderedDict

class LRUCache:
    """
    Least-Recently-Used cache — a key system design component.

    Used in: CDNs, database query caches, browser caches, CPU caches.

    Implementation: OrderedDict maintains insertion order AND allows
    O(1) move_to_end() — perfect for tracking recency.
    """
    def __init__(self, capacity: int) -> None:
        self.capacity = capacity
        self._cache = OrderedDict()     # key → value; maintains insertion order

    def get(self, key: str) -> object:
        if key not in self._cache:
            return None
        self._cache.move_to_end(key)    # mark as recently used
        return self._cache[key]

    def put(self, key: str, value: object) -> None:
        if key in self._cache:
            self._cache.move_to_end(key)   # update recency
        self._cache[key] = value
        if len(self._cache) > self.capacity:
            self._cache.popitem(last=False)  # evict least recently used (front)

cache = LRUCache(3)
cache.put("user:1", {"name": "Alice"})
cache.put("user:2", {"name": "Bob"})
cache.put("user:3", {"name": "Carol"})
cache.get("user:1")                     # access user:1 — moves it to most-recent
cache.put("user:4", {"name": "Dave"})   # evicts user:2 (least recently used)
print(cache.get("user:2"))  # None — evicted
print(cache.get("user:1"))  # {'name': 'Alice'} — still in cache
```

### Pattern 2 — Rate Limiter with `deque` (Sliding Window)

```python
import time
from collections import deque

class SlidingWindowRateLimiter:
    """
    Rate limiter: allow at most max_requests per window_seconds.

    Used in: API gateways, login throttling, message brokers.

    Each user has a deque of timestamps of their recent requests.
    On each request: evict timestamps older than window, then check count.
    """
    def __init__(self, max_requests: int, window_seconds: float) -> None:
        self.max_requests   = max_requests
        self.window_seconds = window_seconds
        self._timestamps: dict[str, deque] = defaultdict(deque)

    def is_allowed(self, user_id: str) -> bool:
        """Return True if this request should be allowed."""
        now = time.monotonic()
        window_start = now - self.window_seconds
        timestamps = self._timestamps[user_id]

        # Remove timestamps older than the window (from the left — oldest first)
        while timestamps and timestamps[0] < window_start:
            timestamps.popleft()            # O(1) deque operation

        if len(timestamps) < self.max_requests:
            timestamps.append(now)          # record this request
            return True
        return False                        # rate limit exceeded

limiter = SlidingWindowRateLimiter(max_requests=3, window_seconds=1.0)
for _ in range(5):
    result = limiter.is_allowed("alice")
    print(f"alice: {'✓ allowed' if result else '✗ blocked'}")
```

### Pattern 3 — Word Frequency / Top-K with `Counter`

```python
from collections import Counter
import heapq

def top_k_frequent_words(text: str, k: int) -> list[tuple[str, int]]:
    """
    Find the k most frequent words in a text.

    Used in: search engines (query suggestions), analytics dashboards,
             spam detection, trending topics.

    Time: O(n log k) where n = word count
    """
    STOP_WORDS = {"the", "a", "an", "is", "in", "of", "and", "to"}
    words = [
        w.strip(".,!?;:'\"").lower()
        for w in text.split()
        if w.lower() not in STOP_WORDS
    ]
    counter = Counter(words)
    return counter.most_common(k)   # O(n log k) internally

article = """
Python is an amazing programming language. Python is used everywhere
in data science, web development, and automation. Python is the most
popular language for machine learning and artificial intelligence.
"""
print(top_k_frequent_words(article, 5))
# [('python', 3), ('language', 2), ...]
```

### Pattern 4 — Two-Sum / Fast Lookup with `dict`

```python
def two_sum(numbers: list[int], target: int) -> tuple[int, int] | None:
    """
    Find two indices whose values sum to target.

    NAIVE approach: O(n²) — check every pair
    DICT approach:  O(n)  — one pass with complement lookup

    This pattern appears everywhere in system design:
    - Finding cache misses (complement = what's missing)
    - Matching buy/sell orders in a trading system
    - Finding pairs that satisfy a constraint
    """
    seen: dict[int, int] = {}           # maps value → its index

    for i, num in enumerate(numbers):
        complement = target - num       # what value we need to pair with num

        if complement in seen:          # O(1) lookup — have we seen it?
            return seen[complement], i  # found! return both indices

        seen[num] = i                   # record this number's index

    return None                         # no pair found

print(two_sum([2, 7, 11, 15], 9))      # (0, 1)  — 2+7=9
print(two_sum([3, 2, 4], 6))           # (1, 2)  — 2+4=6
```

---

## Best Practices

```python
# ── 1. Never mutate a list while iterating over it ───────────────────────
items = [1, 2, 3, 4, 5, 6]
# BAD — skips elements because indices shift after each remove
for item in items:
    if item % 2 == 0:
        items.remove(item)   # BUG!

# GOOD — build a new filtered list
items = [item for item in items if item % 2 != 0]

# ── 2. Use dict.get() instead of KeyError-prone direct access ───────────
config = {"port": 8080}
port = config.get("port", 3000)        # safe — returns 3000 if missing

# ── 3. Use set for any "is X in this collection?" check ─────────────────
valid_roles = {"admin", "editor", "viewer"}  # NOT a list!
if user_role in valid_roles:
    grant_access()

# ── 4. Use Counter instead of manual counting ────────────────────────────
from collections import Counter
counts = Counter(some_list)             # one line vs a loop

# ── 5. Use deque for queue-like operations ────────────────────────────────
from collections import deque
q = deque()
q.append("item")        # O(1)
item = q.popleft()      # O(1) — NOT q.pop(0) which is O(n)!

# ── 6. Use dict.setdefault() for group-by patterns ───────────────────────
groups: dict = {}
for item in items:
    groups.setdefault(item.category, []).append(item)
```

---

## Exercises

### Exercise 3.1 — Anagram Checker

```python
from collections import Counter

def are_anagrams(a: str, b: str) -> bool:
    """
    Two strings are anagrams if they have the same character frequencies.
    Counter gives us the frequency map in one call.
    """
    clean = lambda s: s.lower().replace(" ", "")
    return Counter(clean(a)) == Counter(clean(b))

print(are_anagrams("listen", "silent"))                    # True
print(are_anagrams("Astronomer", "Moon starer"))           # True
print(are_anagrams("hello", "world"))                      # False
```

### Exercise 3.2 — Top-N Words

```python
from collections import Counter

STOP = {"the","a","an","is","in","of","and","to","it","was","for"}

def top_words(text: str, n: int = 5) -> list[tuple[str, int]]:
    words = [w.strip(".,!?;:'\"").lower() for w in text.split()]
    filtered = [w for w in words if w and w not in STOP]
    return Counter(filtered).most_common(n)
```

### Exercise 3.3 — Group By

```python
from collections import defaultdict
from typing import Callable, TypeVar

T = TypeVar("T"); K = TypeVar("K")

def group_by(items: list[T], key_fn: Callable[[T], K]) -> dict[K, list[T]]:
    """Group items by the result of key_fn in one pass."""
    result: dict[K, list[T]] = defaultdict(list)
    for item in items:
        result[key_fn(item)].append(item)
    return dict(result)

words = ["apple", "avocado", "banana", "cherry", "apricot"]
print(group_by(words, lambda w: w[0]))
# {'a': ['apple','avocado','apricot'], 'b': ['banana'], 'c': ['cherry']}
```

### Exercise 3.4 — Sliding Window Maximum

```python
from collections import deque

def sliding_window_max(nums: list[int], k: int) -> list[int]:
    """
    Return max value in each sliding window of size k.
    O(n) using a monotonic deque (stores indices, front = max).

    System design use: real-time dashboards, stream processing.
    """
    dq: deque = deque()     # stores indices; front has index of current max
    result: list[int] = []

    for i, val in enumerate(nums):
        # Remove indices outside the current window
        while dq and dq[0] < i - k + 1:
            dq.popleft()

        # Remove indices whose values are smaller than current (they can never be max)
        while dq and nums[dq[-1]] < val:
            dq.pop()

        dq.append(i)

        if i >= k - 1:          # window is full — record the max
            result.append(nums[dq[0]])

    return result

print(sliding_window_max([1, 3, -1, -3, 5, 3, 6, 7], 3))
# [3, 3, 5, 5, 6, 7]
```

---

## Mini-Project — Inventory Management System

```python
from collections import defaultdict, Counter
from dataclasses import dataclass, field
from typing import Optional

@dataclass
class Product:
    name: str
    price: float
    category: str
    quantity: int = 0

class Inventory:
    """
    Production-style inventory system demonstrating dict, set, Counter, defaultdict.
    """
    def __init__(self) -> None:
        self._products: dict[str, Product] = {}           # O(1) lookup by name
        self._by_category: dict[str, set[str]] = defaultdict(set)  # category index
        self._sales_history: Counter = Counter()           # track what sells

    def add(self, product: Product) -> None:
        existing = self._products.get(product.name)
        if existing:
            existing.quantity += product.quantity          # restock
        else:
            self._products[product.name] = product         # new product
        self._by_category[product.category].add(product.name)

    def sell(self, name: str, qty: int = 1) -> bool:
        p = self._products.get(name)
        if not p or p.quantity < qty:
            return False
        p.quantity -= qty
        self._sales_history[name] += qty
        return True

    def low_stock(self, threshold: int = 5) -> list[Product]:
        return [p for p in self._products.values() if p.quantity <= threshold]

    def category_value(self, category: str) -> float:
        return sum(
            self._products[n].price * self._products[n].quantity
            for n in self._by_category.get(category, set())
        )

    def bestsellers(self, top: int = 3) -> list[tuple[str, int]]:
        return self._sales_history.most_common(top)

    def report(self) -> None:
        print(f"\n{'INVENTORY':=^50}")
        for p in sorted(self._products.values(), key=lambda x: x.name):
            flag = " ⚠ LOW" if p.quantity <= 5 else ""
            print(f"{p.name:<25} {p.quantity:>5} @ ${p.price:.2f}{flag}")
        print(f"\nTop sellers: {self.bestsellers()}")

# Demo
inv = Inventory()
for p in [
    Product("Python Book", 39.99, "books", 50),
    Product("Data Science Book", 49.99, "books", 3),
    Product("USB-C Cable", 9.99, "electronics", 100),
    Product("Laptop Stand", 29.99, "electronics", 4),
]:
    inv.add(p)

inv.sell("Python Book", 47)
inv.sell("Laptop Stand", 2)
inv.sell("Python Book", 1)
inv.report()
print(f"Books value: ${inv.category_value('books'):.2f}")
```

---

## Interview Prep — Top Questions for Data Structures

**Q1: What is the time complexity of common list operations?**
- Append: O(1) amortized — Python over-allocates by 12.5%, occasional O(n) resize
- Insert at index i: O(n) — shifts all elements after i
- Delete by index: O(n) — shifts elements
- `x in list`: O(n) — linear scan
- `x in set`: O(1) — hash lookup
- `list[i]`: O(1) — direct memory address via index

**Q2: Why are Python dicts ordered since Python 3.7?**
CPython 3.7+ guarantees insertion-order preservation as an implementation detail promoted to language spec. Internally, dicts use a compact array with hash-indexed positions and a separate entries array maintaining insertion order. Before 3.7, you needed `collections.OrderedDict` for ordered iteration.

**Q3: What makes an object hashable? Can lists be dict keys?**
An object is hashable if it implements `__hash__` AND `__eq__`, and its hash never changes during its lifetime. Lists are **not hashable** — they're mutable, so their content (and thus hash) could change. Tuples of hashable elements **are** hashable and can be dict keys. User-defined classes are hashable by default (hash based on `id()`).

**Q4: When would you choose `deque` over `list`?**
`collections.deque` has O(1) appends and pops from **both ends**. `list` has O(1) append/pop from the **right** but O(n) from the left (`list.insert(0, x)` shifts all elements). Use `deque` for: BFS queues, sliding windows, LRU cache implementation, any algorithm that needs efficient head insertions/deletions.

**Q5: How does Python's `set` work internally?**
A `set` is a hash table with open addressing. Each element is hashed to a slot. Collisions are resolved by probing. Average O(1) for add/remove/lookup; worst case O(n) with many hash collisions. Sets require elements to be **hashable** and use ~4x–8x more memory than a list of the same elements due to the hash table structure.

**Q6: What is the difference between `Counter`, `defaultdict`, and `dict.setdefault()`?**
- `Counter(iterable)` counts occurrences — `most_common(n)` returns top n elements
- `defaultdict(factory)` auto-creates missing keys using the factory function (e.g., `defaultdict(list)` creates `[]` for new keys)
- `dict.setdefault(key, default)` returns existing value or sets and returns `default` — modifies in place

**Q7: When is a list comprehension slower than a for loop?**
List comprehensions are typically 10–35% faster for simple transformations because they're implemented as a bytecode optimized loop. However, they can be slower when: the predicate involves expensive function calls (call overhead per element), when you don't need the list (use a generator expression), or when the list is never fully consumed.

**Q8: Explain the difference between `copy.copy()` and slicing for lists.**
Both create a **shallow copy** — a new list containing references to the same inner objects. `lst[:]` is idiomatic Python. `copy.copy(lst)` is equivalent. Neither copies nested mutable objects — modifying `inner_list` in one copy affects the other. Use `copy.deepcopy()` for full independence.

**Q9: What is a frozenset and when would you use it?**
A `frozenset` is an immutable set — same hash-table internals as `set`, but cannot be modified after creation. Use cases: dict keys that should be sets (`frozenset` is hashable, `set` is not), set elements that themselves need to be sets, caching set results.

**Q10: How would you implement an LRU Cache using Python data structures?**
Use `collections.OrderedDict` — move accessed items to the end, evict from the front when capacity is exceeded. Python 3.2+ has `functools.lru_cache` built-in. The underlying structure is a hash map (O(1) lookup) + doubly linked list (O(1) move-to-front/evict-oldest). This is a classic interview question at Google, Meta, Amazon.

---

## Module Summary

| Structure   | Ordered | Mutable | Duplicates | Lookup  | System Design Use |
|-------------|---------|---------|------------|---------|-------------------|
| `list`      | ✅      | ✅      | ✅         | O(n)    | Task queues, result sets, ordered data |
| `tuple`     | ✅      | ❌      | ✅         | O(n)    | DB rows, config, function return values |
| `dict`      | ✅(3.7) | ✅      | Keys: ❌   | **O(1)**| Caches, config maps, indexes |
| `set`       | ❌      | ✅      | ❌         | **O(1)**| Membership checks, dedup, set math |
| `frozenset` | ❌      | ❌      | ❌         | **O(1)**| Dict keys, immutable sets |
| `deque`     | ✅      | ✅      | ✅         | O(1) ends | BFS queues, sliding windows, rate limiters |
| `Counter`   | —       | ✅      | N/A        | **O(1)**| Word freq, top-K, analytics |
| `defaultdict`| ✅     | ✅      | ✅         | **O(1)**| Grouping, counting, graph adjacency |

---

## Quiz

1. What is the time complexity of `x in my_list` vs `x in my_set`? Why?
2. Why does `{}` create an empty dict instead of an empty set?
3. Why does `list.pop(0)` have O(n) complexity? How do you fix this?
4. What is the difference between `dict.get("key")` and `dict["key"]`?
5. When would you use `defaultdict(list)` over a regular dict with `setdefault`?
6. What makes `frozenset` useful that a regular `set` cannot do?
7. What does `*rest` capture in `first, *rest = [1, 2, 3, 4]`? What type is it?
8. What does `Counter({"a": 3}) - Counter({"a": 5})` produce?
9. Why is `deque` preferred over `list` for a FIFO queue?
10. You need to implement a feature-flag service that checks `if feature in enabled_features` 10,000 times per second across 1M features. Which structure do you choose and why?

**Answers:**
1. `list`: O(n) — scans each element. `set`: O(1) — hashes the value and jumps directly to the slot. The set is 10,000–100,000× faster for large collections.
2. `{}` was already used for dict literals before sets were added. `set()` is needed for an empty set.
3. `list.pop(0)` shifts every remaining pointer one slot left — O(n) work. Use `deque.popleft()` which is O(1).
4. `dict["key"]` raises `KeyError` if the key is absent. `dict.get("key")` returns `None` (or a default) safely.
5. `defaultdict(list)` is cleaner and faster — you skip the `if key not in d` check. Use it when ALL missing keys should get the same default type.
6. `frozenset` is hashable — it can be used as a dictionary key or stored in a `set`. Regular `set` is mutable and therefore not hashable.
7. `rest = [2, 3, 4]` — `*rest` always collects into a **list**, even if the source is a tuple.
8. `Counter()` (empty) — Counter subtraction floors at 0 and drops zero/negative results.
9. `list.pop(0)` is O(n). `deque.popleft()` is O(1). For a busy queue with millions of operations, this is a critical difference.
10. **`set`** — O(1) membership check regardless of size. A list would be O(n) per check = 10,000 × 1,000,000 = 10 billion operations per second (impossible). A set handles it trivially.

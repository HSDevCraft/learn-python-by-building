# Module 09 — Debugging and Performance Optimization

> **Level:** Intermediate–Advanced | **Estimated Time:** 5 hours | **Prerequisites:** Modules 01–08

---

## Learning Objectives

By the end of this module you will be able to:
- Debug Python code using `pdb`, breakpoints, and VS Code debugger
- Use `logging` for structured, production-grade logging
- Profile code with `cProfile`, `timeit`, and `line_profiler`
- Identify and fix common performance bottlenecks
- Use generators and lazy evaluation for memory efficiency
- Apply `functools.lru_cache` and algorithmic improvements
- Understand the GIL and when to use threads vs processes

---

## The Big Picture — Debug, Measure, Then Optimize

```
Common mistake:  Guess where the slow code is → optimize it → no speedup
Correct approach: Profile first → find the ACTUAL bottleneck → optimize

"Premature optimization is the root of all evil" — Donald Knuth

Workflow:
  1. WRITE correct code (tests pass)
  2. PROFILE (cProfile, timeit) — find where 90% of time is spent
  3. OPTIMIZE that specific bottleneck (algorithm, data structure, caching)
  4. MEASURE again — verify the improvement
  5. REPEAT until fast enough

Logging workflow:
  Development:  print() is fine for one-off debugging
  Production:   logging/structlog with structured JSON output
  Why?         Logs have levels, timestamps, context — searchable in log aggregators
```

---

## 9.1 Debugging

### `pdb` — Python Debugger

```python
# Method 1: Built-in breakpoint() (Python 3.7+)
def compute(data: list[int]) -> int:
    total = 0
    for item in data:
        breakpoint()      # execution pauses here; opens pdb shell
        total += item
    return total

# pdb commands:
# n (next)      — execute next line (don't step into functions)
# s (step)      — step into function call
# c (continue)  — continue until next breakpoint
# l (list)      — show source code around current line
# p expr        — print expression
# pp expr       — pretty-print expression
# w (where)     — show call stack
# u / d         — move up/down the call stack
# b 42          — set breakpoint at line 42
# q (quit)      — exit the debugger
```

```bash
# Run a script directly under pdb
python -m pdb my_script.py

# Post-mortem debugging — examine state after an exception
python -c "
import pdb, traceback
try:
    exec(open('my_script.py').read())
except:
    pdb.post_mortem()
"
```

### Debugging Techniques

```python
# 1. Print debugging — quick but messy
print(f"DEBUG: value={value!r}, type={type(value).__name__}")

# 2. Assertion — document assumptions and catch violations early
def process_age(age: int) -> str:
    assert isinstance(age, int), f"age must be int, got {type(age)}"
    assert 0 <= age <= 150, f"unrealistic age: {age}"
    return f"Age: {age}"

# 3. icecream — better print debugging
# pip install icecream
from icecream import ic
result = ic(compute([1, 2, 3]))    # prints: ic| compute([1, 2, 3]): 6

# 4. Rich.inspect — beautiful object introspection
# pip install rich
from rich import inspect
inspect(some_object, methods=True)

# 5. Tracing with sys.settrace (advanced)
import sys

def trace_calls(frame, event, arg):
    if event == "call":
        print(f"Calling: {frame.f_code.co_name} at line {frame.f_lineno}")
    return trace_calls

sys.settrace(trace_calls)
# ... run code ...
sys.settrace(None)
```

---

## 9.2 Logging

### Conceptual Foundation

`print()` is for development. `logging` is for production. Logging provides:
- Severity levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- Timestamps and context (file, line number, function)
- Multiple output targets (file, stdout, remote service)
- Filtering — turn off debug logs in production without code changes

```python
import logging
import sys
from pathlib import Path

# Basic configuration
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s | %(levelname)-8s | %(name)s:%(lineno)d | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[
        logging.StreamHandler(sys.stdout),               # console
        logging.FileHandler("app.log", encoding="utf-8") # file
    ]
)

logger = logging.getLogger(__name__)   # use module name as logger name

def process_order(order_id: int, amount: float) -> bool:
    logger.info("Processing order %s for $%.2f", order_id, amount)
    try:
        # ... processing ...
        if amount <= 0:
            logger.warning("Order %s has non-positive amount: %s", order_id, amount)
            return False
        logger.info("Order %s processed successfully", order_id)
        return True
    except Exception as e:
        logger.error("Failed to process order %s: %s", order_id, e, exc_info=True)
        return False

# Log levels (in increasing severity)
logger.debug("Detailed diagnostic info — normally off in production")
logger.info("Normal operational message")
logger.warning("Something unexpected but non-fatal")
logger.error("A serious failure")
logger.critical("System cannot continue")
```

### Structured Logging with `structlog`

```bash
pip install structlog
```

```python
import structlog

# Configure structlog for JSON output (production)
structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ]
)

log = structlog.get_logger()

def process_payment(payment_id: str, amount: float, currency: str) -> None:
    log.info("payment.started", payment_id=payment_id, amount=amount, currency=currency)
    try:
        # process...
        log.info("payment.success", payment_id=payment_id)
    except Exception as e:
        log.error("payment.failed", payment_id=payment_id, error=str(e))
        raise

# Output: {"event": "payment.started", "payment_id": "pay_123", "amount": 99.99, ...}
```

---

## 9.3 Profiling

### `timeit` — Micro-benchmarking

```python
import timeit

# Compare two approaches for concatenating strings
def concat_with_plus(n: int) -> str:
    s = ""
    for i in range(n):
        s += str(i)
    return s

def concat_with_join(n: int) -> str:
    return "".join(str(i) for i in range(n))

n = 10_000
t_plus = timeit.timeit(lambda: concat_with_plus(n), number=100)
t_join = timeit.timeit(lambda: concat_with_join(n), number=100)
print(f"+ operator: {t_plus:.3f}s")
print(f".join():    {t_join:.3f}s")
print(f"join is {t_plus / t_join:.1f}x faster")
```

### `cProfile` — Function-Level Profiling

```python
import cProfile
import pstats
from pstats import SortKey

# Profile a function call
cProfile.run("my_expensive_function()", "profile_output.prof")

# Analyse the profile
with open("profile_stats.txt", "w") as stream:
    stats = pstats.Stats("profile_output.prof", stream=stream)
    stats.sort_stats(SortKey.CUMULATIVE)
    stats.print_stats(20)    # top 20 functions by cumulative time

# Or use as a context manager
with cProfile.Profile() as pr:
    result = my_expensive_function()

ps = pstats.Stats(pr)
ps.sort_stats(SortKey.CUMULATIVE)
ps.print_stats(10)
```

```bash
# Profile from command line
python -m cProfile -s cumulative my_script.py

# Visualise with snakeviz
pip install snakeviz
python -m cProfile -o output.prof my_script.py
snakeviz output.prof
```

### `line_profiler` — Line-Level Profiling

```bash
pip install line_profiler
```

```python
# Decorate the function to profile
from line_profiler import profile

@profile
def slow_function(data: list[int]) -> list[int]:
    result = []
    for item in data:
        if item % 2 == 0:
            result.append(item ** 2)
    return result

slow_function(list(range(100_000)))
```

```bash
kernprof -l -v script.py
```

---

## 9.4 Common Performance Bottlenecks and Fixes

### String Concatenation in Loops

```python
# BAD: O(n²) — creates a new string on every iteration
def bad_join(items: list[str]) -> str:
    result = ""
    for item in items:
        result += item + ", "
    return result

# GOOD: O(n) — join is implemented in C
def good_join(items: list[str]) -> str:
    return ", ".join(items)
```

### Membership Testing

```python
# BAD: O(n) per lookup
allowed_list = ["admin", "editor", "viewer"]
if role in allowed_list:    # scans entire list each time
    pass

# GOOD: O(1) per lookup
ALLOWED_ROLES = {"admin", "editor", "viewer"}
if role in ALLOWED_ROLES:
    pass
```

### Generators vs Lists

```python
# BAD: loads 1M items into memory
def get_even_squares_list(n: int) -> list[int]:
    return [x ** 2 for x in range(n) if x % 2 == 0]

# GOOD: lazy — generates one item at a time
def get_even_squares_gen(n: int):
    return (x ** 2 for x in range(n) if x % 2 == 0)

# Use generators in pipelines
def process_large_file(path: str):
    """Read a large file without loading it all into memory."""
    with open(path) as f:
        for line in f:             # file is an iterator — lazy
            line = line.strip()
            if line and not line.startswith("#"):
                yield line

for record in process_large_file("huge_dataset.csv"):
    process(record)   # only one line in memory at a time
```

### Avoid Repeated Global Lookups

```python
# BAD: Python looks up 'math.sqrt' in the global dict on every call
import math
def compute_distances(points):
    return [math.sqrt(p[0]**2 + p[1]**2) for p in points]

# GOOD: bind frequently-used names to locals
def compute_distances_fast(points):
    sqrt = math.sqrt   # local name lookup is faster
    return [sqrt(p[0]**2 + p[1]**2) for p in points]
```

### Memoisation

```python
import functools

@functools.lru_cache(maxsize=None)
def expensive_computation(n: int) -> int:
    """Cache results — subsequent calls with same n are O(1)."""
    return sum(i ** 3 for i in range(n))

# Or cache to disk for expensive computations that persist across runs
import json
from pathlib import Path

def disk_cache(cache_file: str):
    """Simple disk-backed cache using JSON."""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args):
            path = Path(cache_file)
            cache = json.loads(path.read_text()) if path.exists() else {}
            key = str(args)
            if key not in cache:
                cache[key] = func(*args)
                path.write_text(json.dumps(cache))
            return cache[key]
        return wrapper
    return decorator
```

---

## 9.5 Concurrency: Threads vs Processes

### Conceptual Foundation

Python's **Global Interpreter Lock (GIL)** allows only one thread to execute Python bytecode at a time. This means:

| Workload type | Best approach |
|--------------|--------------|
| CPU-bound (number crunching) | `multiprocessing` (bypasses GIL) |
| I/O-bound (network, disk) | `threading` or `asyncio` |
| Mixed | `concurrent.futures` |

```python
import concurrent.futures
import requests
import time

URLS = [
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/1",
    "https://httpbin.org/delay/1",
]

def fetch(url: str) -> str:
    response = requests.get(url, timeout=10)
    return f"{url}: {response.status_code}"

# Sequential — ~3 seconds
start = time.perf_counter()
results = [fetch(url) for url in URLS]
print(f"Sequential: {time.perf_counter() - start:.2f}s")

# ThreadPoolExecutor — ~1 second (I/O-bound: GIL released during network wait)
start = time.perf_counter()
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
    results = list(executor.map(fetch, URLS))
print(f"Threaded: {time.perf_counter() - start:.2f}s")
```

```python
# ProcessPoolExecutor — for CPU-bound work
import multiprocessing

def cpu_bound(n: int) -> int:
    return sum(i ** 2 for i in range(n))

numbers = [10_000_000] * 4

# Sequential
results = [cpu_bound(n) for n in numbers]

# Parallel (uses all CPU cores)
with concurrent.futures.ProcessPoolExecutor() as executor:
    results = list(executor.map(cpu_bound, numbers))
```

### `asyncio` — Cooperative Concurrency

```python
import asyncio
import aiohttp    # pip install aiohttp

async def fetch_async(session: aiohttp.ClientSession, url: str) -> dict:
    """Async HTTP request — suspends while waiting for network I/O."""
    async with session.get(url) as response:
        return {"url": url, "status": response.status}

async def main():
    urls = [
        "https://httpbin.org/get",
        "https://httpbin.org/status/200",
        "https://httpbin.org/status/201",
    ]
    async with aiohttp.ClientSession() as session:
        tasks = [fetch_async(session, url) for url in urls]
        results = await asyncio.gather(*tasks)   # run concurrently
    return results

results = asyncio.run(main())
```

---

## 9.6 Memory Optimization

```python
import sys

# Check object size
x = [1, 2, 3, 4, 5]
print(sys.getsizeof(x))     # bytes used by the list object itself

# __slots__ — reduce per-instance overhead
class RegularPoint:
    def __init__(self, x, y):
        self.x, self.y = x, y

class SlottedPoint:
    __slots__ = ("x", "y")
    def __init__(self, x, y):
        self.x, self.y = x, y

# For 1M instances: SlottedPoint uses ~40% less memory

# array module — typed arrays (much smaller than lists of numbers)
import array
int_array = array.array("i", range(1000))   # C int array
list_of_ints = list(range(1000))
print(sys.getsizeof(int_array))   # ~4000 bytes
print(sys.getsizeof(list_of_ints))  # ~8056 bytes

# Generator expressions for large datasets
total = sum(x**2 for x in range(1_000_000))  # O(1) memory
```

---

## Best Practices

1. **Profile before optimizing** — don't guess where the bottleneck is.
2. **Use logging, not print** — logs have levels, can be filtered, and work in production.
3. **Use generators for large datasets** — avoid loading everything into memory.
4. **Use sets for membership tests** — O(1) vs O(n) for lists.
5. **Use `str.join()` for string concatenation** in loops.
6. **Cache pure functions** with `@functools.lru_cache`.
7. **Use `ThreadPoolExecutor` for I/O-bound tasks**, `ProcessPoolExecutor` for CPU-bound.
8. **Set `__slots__`** on classes instantiated millions of times.

---

## Exercises

### Exercise 9.1 — Profile and Optimize
Given the code below, profile it and optimize it to be at least 5x faster:

```python
# Slow version
def find_duplicates(numbers: list[int]) -> list[int]:
    """Find all numbers that appear more than once."""
    duplicates = []
    for i, num in enumerate(numbers):
        for j, other in enumerate(numbers):
            if i != j and num == other and num not in duplicates:
                duplicates.append(num)
    return duplicates
```

**Solution:**
```python
from collections import Counter

def find_duplicates_fast(numbers: list[int]) -> list[int]:
    """Find duplicates in O(n) time using Counter."""
    counts = Counter(numbers)
    return [num for num, count in counts.items() if count > 1]

# Benchmark
import timeit
data = list(range(1000)) + list(range(500))   # 500 duplicates

t_slow = timeit.timeit(lambda: find_duplicates(data), number=10)
t_fast = timeit.timeit(lambda: find_duplicates_fast(data), number=10)
print(f"Speedup: {t_slow / t_fast:.1f}x")   # ~100x or more
```

---

## Interview Prep — Top Questions for Debugging and Performance

**Q1: What is the GIL and when does it matter?**
The GIL (Global Interpreter Lock) is a mutex in CPython that allows only **one thread to execute Python bytecode at a time**. For CPU-bound code (computation), threading doesn't parallelize — use `multiprocessing`. For I/O-bound code (network, disk), the GIL is **released during I/O waits**, so threads do give concurrency. Alternatives: `asyncio` (single-threaded event loop), `ProcessPoolExecutor`, or Cython/C extensions.

**Q2: What is the difference between `threading` and `multiprocessing`?**
- **Threading**: Shared memory space, GIL prevents true CPU parallelism, lightweight (low overhead), use for I/O-bound work
- **Multiprocessing**: Separate memory spaces (no GIL), true CPU parallelism, heavier overhead, use for CPU-bound work
- **asyncio**: Single-threaded cooperative concurrency, lowest overhead, use for high-concurrency I/O (web servers, scrapers)

**Q3: How do you profile a Python application to find bottlenecks?**
1. `cProfile` / `-m cProfile`: function-level call counts and cumulative time
2. `line_profiler` (`@profile`, `kernprof`): line-by-line timing within a function
3. `timeit`: micro-benchmark two approaches
4. `snakeviz`: visualizes cProfile output as a flame graph
Workflow: Profile first → identify the 20% of code causing 80% of slowness → optimize only that.

**Q4: Why is `"".join(parts)` O(n) but `result += part` in a loop O(n²)?**
Strings are **immutable** in Python. Each `+=` creates a brand-new string by copying all existing characters plus the new one. After n iterations, you've done 1+2+3+...+n = O(n²) copy operations. `"".join(parts)` allocates the final string once (knowing the total size) and fills it in one C-level pass — O(n).

**Q5: What is `asyncio` and when should you use it vs threads?**
`asyncio` uses a single-threaded **event loop** with cooperative multitasking. Coroutines `await` I/O operations, yielding control to the loop which runs other coroutines. No context switching overhead. Use for: web servers, concurrent API calls, WebSockets, anything with many concurrent I/O operations. Don't use for: CPU-bound work (blocks the event loop), or when you need true parallelism.

**Q6: What is `@functools.lru_cache` and what are its constraints?**
`@lru_cache(maxsize=128)` caches function return values keyed by arguments, evicting least-recently-used entries. Constraints: all arguments must be **hashable** (no lists, dicts). The function must be **pure** (same inputs always produce the same output with no side effects). Use `maxsize=None` for an unbounded cache. Check `func.cache_info()` for hit/miss statistics.

**Q7: What is structured logging and why is it better than `print()` or plain `logging` in production?**
Structured logging emits log events as **key-value JSON objects** (e.g., `{"event": "payment.failed", "amount": 99.9, "user_id": "u123"}`). Benefits: searchable and filterable in log aggregators (Elasticsearch, Splunk, Datadog) by any field; no regex needed; machine-parseable. `structlog` is the Python library for this. Plain `logging` emits unstructured strings that require regex to parse.

---

## Module Summary

| Tool/Technique | Use Case |
|---------------|---------|
| `breakpoint()` | Interactive debugging in a running script |
| `logging` | Production logging with levels and handlers |
| `timeit` | Micro-benchmarking two approaches |
| `cProfile` | Find which functions consume the most time |
| `line_profiler` | Find which lines within a function are slow |
| Generator expressions | Memory-efficient processing of large datasets |
| `lru_cache` | Memoize pure functions with repeated inputs |
| `ThreadPoolExecutor` | Concurrent I/O-bound tasks |
| `ProcessPoolExecutor` | Parallel CPU-bound tasks |

---

## Quiz

1. What is the GIL, and how does it affect threaded programs?
2. When should you use `ProcessPoolExecutor` vs `ThreadPoolExecutor`?
3. What is the output complexity difference between `x in my_list` and `x in my_set`?
4. Why is `"".join(parts)` faster than `result += part` in a loop?
5. What does `cProfile` measure that `timeit` cannot?
6. What is the difference between a generator expression and a list comprehension?
7. What is `structlog` and why is it preferred over standard `logging` in microservices?
8. How do you profile a specific function without modifying the whole codebase?
9. What is `sys.getsizeof()` and what does it NOT measure?
10. How does `asyncio` achieve concurrency without multiple threads?

**Answers:**
1. The GIL (Global Interpreter Lock) is a mutex that allows only one thread to execute Python bytecode at a time. For CPU-bound work, it means threads can't truly run in parallel. For I/O-bound work, the GIL is released during I/O operations, so threading still provides speedup.
2. Use `ProcessPoolExecutor` for CPU-bound tasks (computations) — each process has its own GIL so they run truly in parallel. Use `ThreadPoolExecutor` for I/O-bound tasks (network calls, disk) — threads share the GIL but release it during I/O waits, giving concurrent throughput.
3. `x in my_list` is O(n) — Python scans elements one by one. `x in my_set` is O(1) average — uses a hash table. For 1M elements, the set is ~1M times faster.
4. Strings are immutable in Python. `result += part` creates a **new string** on each iteration, copying all previous characters — O(n²) total. `"".join(parts)` allocates once and writes all parts in one C-level loop — O(n) total.
5. `cProfile` shows the **call graph** — how much time each function spent, how many times it was called, and which functions called which. `timeit` only measures total elapsed time for a snippet — no breakdown by function.
6. A generator expression `(x for x in ...)` returns a lazy iterator — values are computed one at a time, using O(1) memory. A list comprehension `[x for x in ...]` evaluates immediately and stores all results in a list — uses O(n) memory.
7. `structlog` outputs structured (JSON) log events with key-value context. Standard `logging` outputs free-form strings. In microservices, structured logs can be parsed and queried in log aggregators (Elasticsearch, Splunk, Datadog) by field, while free-form strings require fragile regex parsing.
8. Use `cProfile` as a context manager: `with cProfile.Profile() as pr: my_func()`. Or decorate with `@line_profiler.profile` and run with `kernprof -l -v`. No need to modify the whole codebase.
9. `sys.getsizeof()` returns the size of the object itself in bytes. It does **NOT** include the size of objects referenced by it. For example, `sys.getsizeof([1, 2, 3])` returns the list overhead, not the size of the three integers it references.
10. `asyncio` uses a single-threaded **event loop** with cooperative multitasking. When a coroutine hits `await` (e.g., `await response.read()`), it voluntarily suspends and the event loop runs another coroutine. No threads needed — the OS handles I/O notifications asynchronously via select/epoll.

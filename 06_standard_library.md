# Module 06 — Standard Library and Package Management

> **Level:** Intermediate | **Estimated Time:** 5 hours | **Prerequisites:** Modules 01–05

---

## Learning Objectives

By the end of this module you will be able to:
- Use `os`, `sys`, `subprocess` for system-level operations
- Work with dates and times using `datetime` and `zoneinfo`
- Apply `itertools` and `functools` for efficient iteration and functional patterns
- Use `re` for regular expressions
- Use `typing` for robust type annotations
- Install, manage, and publish packages with `pip`
- Understand the Python Package Index (PyPI) ecosystem

---

## 6.1 `os` and `sys` — System Interface

```python
import os
import sys

# --- os: Operating system interface ---

# Environment variables
db_url = os.environ.get("DATABASE_URL", "sqlite:///default.db")
debug = os.getenv("DEBUG", "false").lower() == "true"
os.environ["MY_VAR"] = "hello"        # set env var for this process

# Path operations (prefer pathlib, but know os.path)
print(os.getcwd())                    # current working directory
print(os.path.join("a", "b", "c"))   # "a/b/c" or "a\\b\\c" on Windows
print(os.path.abspath("config.json"))
print(os.path.exists("/tmp"))         # True/False
print(os.path.basename("/home/user/file.txt"))  # "file.txt"
print(os.path.dirname("/home/user/file.txt"))   # "/home/user"

# Directory operations
os.makedirs("a/b/c", exist_ok=True)  # create nested dirs
os.listdir(".")                       # list directory entries
for root, dirs, files in os.walk("."):  # recursive directory traversal
    for file in files:
        print(os.path.join(root, file))

# Process info
print(os.getpid())    # current process ID
print(os.cpu_count()) # number of CPUs

# --- sys: Python interpreter interface ---

print(sys.version)        # "3.11.4 (default, ...)"
print(sys.platform)       # "linux", "win32", "darwin"
print(sys.executable)     # path to Python binary
print(sys.argv)           # command-line arguments list
print(sys.path)           # module search path

# Graceful exit
# sys.exit(0)             # exit code 0 = success, non-zero = error

# Redirect stdout/stderr
import io
buffer = io.StringIO()
sys.stdout = buffer
print("captured output")
sys.stdout = sys.__stdout__     # restore
print(buffer.getvalue())        # "captured output\n"
```

---

## 6.2 `subprocess` — Running Shell Commands

```python
import subprocess

# Run a command and capture output
result = subprocess.run(
    ["python", "--version"],
    capture_output=True,
    text=True,
    timeout=10,
)
print(result.stdout)       # "Python 3.11.4\n"
print(result.returncode)   # 0 (success)

# Check for errors
try:
    result = subprocess.run(
        ["git", "status"],
        capture_output=True,
        text=True,
        check=True,         # raises CalledProcessError if returncode != 0
    )
    print(result.stdout)
except subprocess.CalledProcessError as e:
    print(f"Command failed (code {e.returncode}): {e.stderr}")
except FileNotFoundError:
    print("git is not installed or not in PATH")

# Piping — chain commands
ps = subprocess.Popen(["ps", "aux"], stdout=subprocess.PIPE)
grep = subprocess.Popen(["grep", "python"], stdin=ps.stdout,
                        stdout=subprocess.PIPE, text=True)
ps.stdout.close()
output, _ = grep.communicate()
print(output)
```

---

## 6.3 `datetime` — Date and Time

```python
from datetime import datetime, date, time, timedelta, timezone

# Current time
now = datetime.now()               # local time, naive (no timezone)
utc_now = datetime.now(timezone.utc)  # UTC, aware

# Create specific datetimes
dt = datetime(2024, 6, 15, 14, 30, 0)
d = date(2024, 6, 15)
t = time(14, 30, 0)

# Formatting and parsing
iso_str = now.isoformat()           # "2024-06-15T14:30:00.123456"
formatted = now.strftime("%Y-%m-%d %H:%M:%S")   # "2024-06-15 14:30:00"
parsed = datetime.strptime("2024-06-15", "%Y-%m-%d")
from_iso = datetime.fromisoformat("2024-06-15T14:30:00")

# Arithmetic
tomorrow = now + timedelta(days=1)
two_weeks_ago = now - timedelta(weeks=2)
diff = datetime(2024, 12, 31) - datetime.now()
print(f"Days until year end: {diff.days}")

# Timezone handling (Python 3.9+ zoneinfo)
from zoneinfo import ZoneInfo

eastern = ZoneInfo("America/New_York")
london = ZoneInfo("Europe/London")

eastern_time = datetime.now(eastern)
london_time = eastern_time.astimezone(london)
print(f"Eastern: {eastern_time.strftime('%H:%M %Z')}")
print(f"London:  {london_time.strftime('%H:%M %Z')}")

# Practical: calculate age
def calculate_age(birthdate: date) -> int:
    """Calculate age in years from a birthdate."""
    today = date.today()
    age = today.year - birthdate.year
    if (today.month, today.day) < (birthdate.month, birthdate.day):
        age -= 1
    return age

print(calculate_age(date(1995, 8, 20)))
```

---

## 6.4 `itertools` — Efficient Iterators

```python
import itertools

# chain — combine multiple iterables
result = list(itertools.chain([1, 2], [3, 4], [5]))
# [1, 2, 3, 4, 5]

# chain.from_iterable — flatten one level
matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
flat = list(itertools.chain.from_iterable(matrix))
# [1, 2, 3, 4, 5, 6, 7, 8, 9]

# islice — lazy slice (memory efficient for large iterables)
first_five = list(itertools.islice(range(1_000_000), 5))
# [0, 1, 2, 3, 4]

# combinations and permutations
from itertools import combinations, permutations, product

chars = ['A', 'B', 'C']
print(list(combinations(chars, 2)))    # [('A','B'), ('A','C'), ('B','C')]
print(list(permutations(chars, 2)))    # [('A','B'), ('A','C'), ('B','A'), ...]
print(list(product([0, 1], repeat=3))) # all 3-bit binary numbers

# groupby — group consecutive elements by key
data = [
    {"name": "Alice", "dept": "eng"},
    {"name": "Bob",   "dept": "eng"},
    {"name": "Carol", "dept": "mkt"},
    {"name": "David", "dept": "mkt"},
]

# IMPORTANT: data must be sorted by the key for groupby to work correctly
sorted_data = sorted(data, key=lambda x: x["dept"])
for dept, members in itertools.groupby(sorted_data, key=lambda x: x["dept"]):
    names = [m["name"] for m in members]
    print(f"{dept}: {names}")
# eng: ['Alice', 'Bob']
# mkt: ['Carol', 'David']

# accumulate — running total
import operator
values = [1, 2, 3, 4, 5]
running_sum = list(itertools.accumulate(values))           # [1, 3, 6, 10, 15]
running_product = list(itertools.accumulate(values, operator.mul))  # [1, 2, 6, 24, 120]

# takewhile / dropwhile
nums = [2, 4, 6, 7, 8, 10]
print(list(itertools.takewhile(lambda x: x % 2 == 0, nums)))  # [2, 4, 6]
print(list(itertools.dropwhile(lambda x: x % 2 == 0, nums)))  # [7, 8, 10]
```

---

## 6.5 `re` — Regular Expressions

```python
import re

text = "Contact us at support@example.com or sales@company.org for help."

# Search for first match
match = re.search(r"[\w.+-]+@[\w-]+\.[a-zA-Z]+", text)
if match:
    print(match.group())    # support@example.com
    print(match.start())    # start index

# Find all matches
emails = re.findall(r"[\w.+-]+@[\w-]+\.[a-zA-Z]+", text)
print(emails)    # ['support@example.com', 'sales@company.org']

# Match at start of string
if re.match(r"\d{4}-\d{2}-\d{2}", "2024-06-15 is a date"):
    print("Valid date format at start")

# Full match
if re.fullmatch(r"\d{5}", "12345"):
    print("Valid 5-digit zip code")

# Substitution
cleaned = re.sub(r"\s+", " ", "too   many    spaces")
print(cleaned)    # "too many spaces"

# Split
parts = re.split(r"[,;]\s*", "Alice, Bob; Carol,David")
print(parts)    # ['Alice', 'Bob', 'Carol', 'David']

# Named groups — readable patterns
date_pattern = re.compile(r"(?P<year>\d{4})-(?P<month>\d{2})-(?P<day>\d{2})")
m = date_pattern.match("2024-06-15")
if m:
    print(m.group("year"))    # 2024
    print(m.group("month"))   # 06
    print(m.groupdict())      # {'year': '2024', 'month': '06', 'day': '15'}

# Pre-compile for repeated use (performance)
email_re = re.compile(r"[\w.+-]+@[\w-]+\.[a-zA-Z]+", re.IGNORECASE)

def extract_emails(text: str) -> list[str]:
    """Extract all email addresses from text."""
    return email_re.findall(text)
```

---

## 6.6 `typing` — Type Annotations

```python
from typing import (
    Any, Union, Optional, Literal,
    TypeVar, Generic, Protocol,
    Callable, Iterator, Generator,
    TYPE_CHECKING,
)
from collections.abc import Sequence, Mapping

# Modern type union syntax (Python 3.10+)
def process(value: int | str | None) -> str:
    return str(value) if value is not None else "none"

# TypeVar — generic types
T = TypeVar("T")
K = TypeVar("K")
V = TypeVar("V")

def first(items: list[T]) -> T:
    """Return the first element of a list."""
    if not items:
        raise ValueError("List is empty")
    return items[0]

# Callable type hint
from typing import Callable

def apply(func: Callable[[int], int], value: int) -> int:
    return func(value)

# Protocol — structural subtyping (duck typing made formal)
from typing import Protocol, runtime_checkable

@runtime_checkable
class Drawable(Protocol):
    def draw(self) -> None: ...
    def resize(self, factor: float) -> None: ...

class Circle:
    def draw(self) -> None: print("Drawing circle")
    def resize(self, factor: float) -> None: print(f"Resizing by {factor}")

def render(shape: Drawable) -> None:
    shape.draw()

# Circle satisfies Drawable even without explicit inheritance
render(Circle())
print(isinstance(Circle(), Drawable))  # True (due to @runtime_checkable)

# Literal — restrict to specific values
from typing import Literal

LogLevel = Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]

def set_log_level(level: LogLevel) -> None:
    print(f"Log level set to {level}")

# TypedDict — typed dictionaries
from typing import TypedDict

class UserDict(TypedDict):
    name: str
    age: int
    email: str

def process_user(user: UserDict) -> str:
    return f"{user['name']} ({user['age']})"
```

---

## 6.7 Package Management with `pip`

```bash
# Install a package
pip install requests

# Install specific version
pip install requests==2.31.0

# Install with version range
pip install "requests>=2.28,<3.0"

# Install from requirements file
pip install -r requirements.txt

# Upgrade a package
pip install --upgrade requests

# Uninstall
pip uninstall requests

# Show installed packages
pip list
pip show requests       # detailed info: version, location, deps

# Generate requirements file
pip freeze > requirements.txt

# Install in editable mode (for local development)
pip install -e .

# Install extras
pip install "fastapi[all]"
```

### `requirements.txt` Best Practices

```text
# requirements.txt — production dependencies with pinned versions
requests==2.31.0
pydantic==2.5.0
fastapi==0.104.0
uvicorn[standard]==0.24.0

# requirements-dev.txt — development-only dependencies
-r requirements.txt
pytest==7.4.0
pytest-cov==4.1.0
black==23.11.0
ruff==0.1.6
mypy==1.7.0
```

---

## Best Practices

1. **Use `os.environ.get()` with defaults** — never crash on missing env vars.
2. **Always specify `text=True` and `timeout=`** in `subprocess.run()`.
3. **Always work with timezone-aware datetimes** in production code.
4. **Compile regex patterns** that are used repeatedly: `re.compile(pattern)`.
5. **Use `itertools` for large datasets** — they return lazy iterators, not lists.
6. **Pin package versions** in `requirements.txt` — prevents "works on my machine" issues.
7. **Separate dev dependencies** from production dependencies.
8. **Use `Protocol`** for structural typing instead of explicit inheritance where possible.

---

## Exercises

### Exercise 6.1 — File Statistics Script
Using `os.walk` and `pathlib`, write a script that takes a directory and prints: total file count, total size in MB, top 5 file extensions by count, and largest files.

### Exercise 6.2 — Log Parser with Regex
Write a function that parses Apache/Nginx combined log format lines and returns structured dicts with: IP, method, path, status code, response size.

**Log format:** `127.0.0.1 - frank [10/Oct/2000:13:55:36] "GET /apache_pb.gif HTTP/1.0" 200 2326`

**Solution:**
```python
import re
from typing import Optional

LOG_PATTERN = re.compile(
    r'(?P<ip>\S+)\s+\S+\s+\S+\s+\[(?P<time>[^\]]+)\]\s+'
    r'"(?P<method>\w+)\s+(?P<path>\S+)\s+\S+"\s+'
    r'(?P<status>\d{3})\s+(?P<size>\d+|-)'
)

def parse_log_line(line: str) -> Optional[dict]:
    """Parse a single Apache combined log format line."""
    m = LOG_PATTERN.match(line.strip())
    if not m:
        return None
    return {
        "ip": m.group("ip"),
        "time": m.group("time"),
        "method": m.group("method"),
        "path": m.group("path"),
        "status": int(m.group("status")),
        "size": int(m.group("size")) if m.group("size") != "-" else 0,
    }

line = '127.0.0.1 - frank [10/Oct/2000:13:55:36] "GET /apache_pb.gif HTTP/1.0" 200 2326'
print(parse_log_line(line))
```

---

## Module Summary

| Module | Primary Use |
|--------|------------|
| `os` | Env vars, paths, directories, process info |
| `sys` | Interpreter info, stdin/stdout, argv |
| `subprocess` | Run shell commands, capture output |
| `datetime` | Date/time arithmetic and formatting |
| `zoneinfo` | Timezone handling (Python 3.9+) |
| `itertools` | Efficient combinatorial and lazy iteration |
| `re` | Pattern matching and text extraction |
| `typing` | Static type annotations and protocols |
| `pip` | Install and manage third-party packages |

---

## Quiz

1. What is the difference between `os.environ["KEY"]` and `os.environ.get("KEY")`?
2. Why should you prefer `subprocess.run()` over `os.system()`?
3. What is a "naive" vs "aware" datetime?
4. Why must data be sorted before using `itertools.groupby()`?
5. What does `re.compile()` return, and why is it useful?
6. What is the difference between `re.match()` and `re.search()`?
7. What is `pip freeze` used for?
8. What is a `TypedDict` and when would you use it over a dataclass?
9. What does `@runtime_checkable` do for a `Protocol`?
10. What is the output of `list(itertools.accumulate([1,2,3,4]))`?

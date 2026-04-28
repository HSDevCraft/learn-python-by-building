# Module 06 — Standard Library and Package Management

> **Level:** Intermediate | **Estimated Time:** 5 hours | **Prerequisites:** Modules 01–05

---

## Learning Objectives

By the end of this module you will be able to:
- Use `os`, `sys`, `subprocess` for system-level operations and environment configuration
- Work with dates and times correctly using `datetime` and `zoneinfo` — including timezone awareness
- Apply `itertools` for memory-efficient data pipelines without loading data into memory
- Use `re` for text extraction, validation, and parsing with named groups
- Use `typing` and `Protocol` for precise, self-documenting type annotations
- Install, pin, and manage packages with `pip` and `requirements.txt`

---

## Why the Standard Library Matters

Python ships with a rich "batteries included" standard library — hundreds of modules covering everything from file I/O to network protocols to cryptography. Understanding it prevents you from:
- Reinventing the wheel (writing your own JSON parser)
- Installing unnecessary third-party dependencies
- Shipping fragile code where a stdlib module would be battle-tested

---

## 6.1 `os` and `sys` — System Interface

```python
import os
import sys

# ── Environment variables — the right way to configure applications ───────
# 12-Factor App principle: store config in the environment, not in code
db_url = os.environ.get("DATABASE_URL", "sqlite:///default.db")  # safe: returns default
debug  = os.getenv("DEBUG", "false").lower() == "true"           # same as environ.get

# os.environ["KEY"] raises KeyError if missing — use only when the var is REQUIRED
try:
    secret = os.environ["SECRET_KEY"]   # crash fast if missing — better than silent wrong config
except KeyError:
    raise RuntimeError("SECRET_KEY environment variable must be set")

# ── Process and system information ────────────────────────────────────────
print(os.getpid())       # current process ID — useful for logging in multi-process systems
print(os.getppid())      # parent process ID
print(os.cpu_count())    # number of logical CPUs — use for ThreadPoolExecutor(max_workers)
print(os.getenv("HOME")) # home directory

# ── Directory operations (prefer pathlib for new code) ────────────────────
print(os.getcwd())                        # current working directory
os.makedirs("logs/2024/01", exist_ok=True) # create nested dirs safely

# os.walk: recursive directory traversal — yields (root, dirs, files) tuples
# Used in: backup utilities, file indexers, static site generators
def count_files(directory: str) -> dict[str, int]:
    """Count files by extension in a directory tree."""
    from collections import Counter
    counts: Counter = Counter()
    for root, _dirs, files in os.walk(directory):
        for filename in files:
            ext = os.path.splitext(filename)[1].lower() or "(no ext)"
            counts[ext] += 1
    return dict(counts)

# ── sys — Python interpreter interface ───────────────────────────────────
print(sys.version)      # "3.11.4 (main, Jul 5 2023, 13:45:01)"
print(sys.platform)     # "linux", "win32", "darwin"
print(sys.executable)   # full path to current Python binary
print(sys.argv)         # ["script.py", "arg1", "arg2"] — command-line args
print(sys.path)         # module search path (where import looks)

# Add a directory to the module search path (useful for scripts)
sys.path.insert(0, "/path/to/my/modules")

# Graceful exit with appropriate exit code
# sys.exit(0)   → success
# sys.exit(1)   → general error
# sys.exit(2)   → misuse of shell builtin (standard for CLI tools)

# Capture stdout — useful for testing output-producing functions
import io
buffer = io.StringIO()
old_stdout = sys.stdout
sys.stdout = buffer
print("captured!")
sys.stdout = old_stdout      # always restore, even on exception
print(buffer.getvalue())     # "captured!\n"
```

---

## 6.2 `subprocess` — Running Shell Commands

```python
import subprocess

# ── subprocess.run() — the main API for running commands ─────────────────
# Always use a LIST of strings, never a shell string
# BAD:  subprocess.run("git status", shell=True)   # shell injection risk!
# GOOD: subprocess.run(["git", "status"])           # each arg is separate

result = subprocess.run(
    ["python", "--version"],
    capture_output=True,    # capture both stdout and stderr
    text=True,              # decode bytes to str using default encoding
    timeout=30,             # kill after 30s — ALWAYS set a timeout
)
print(result.stdout)        # "Python 3.11.4\n"
print(result.returncode)    # 0 = success, non-zero = error

# ── check=True: raise exception on non-zero exit code ────────────────────
try:
    result = subprocess.run(
        ["git", "log", "--oneline", "-5"],
        capture_output=True,
        text=True,
        check=True,          # raises CalledProcessError if returncode != 0
        timeout=10,
    )
    print(result.stdout)
except subprocess.CalledProcessError as e:
    print(f"git failed (exit {e.returncode}):\n{e.stderr}")
except FileNotFoundError:
    print("git is not installed or not found in PATH")
except subprocess.TimeoutExpired:
    print("Command timed out")

# ── Helper: run command and return output or raise with context ───────────
def run(cmd: list[str], **kwargs) -> str:
    """Run a command, return stdout, raise RuntimeError with stderr on failure."""
    result = subprocess.run(
        cmd, capture_output=True, text=True, timeout=60, **kwargs
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Command {cmd[0]!r} failed (exit {result.returncode}):\n{result.stderr.strip()}"
        )
    return result.stdout.strip()

# Usage in a CI/CD-style script:
branch = run(["git", "rev-parse", "--abbrev-ref", "HEAD"])
commit = run(["git", "rev-parse", "--short", "HEAD"])
print(f"Building {branch} @ {commit}")
```

---

## 6.3 `datetime` — Date and Time

```python
from datetime import datetime, date, time, timedelta, timezone
from zoneinfo import ZoneInfo   # Python 3.9+

# ── Naive vs Aware datetimes — the most important concept ─────────────────
# NAIVE:  datetime with no timezone info — looks like a datetime but LIES
#         Two naive datetimes cannot be compared unless you know their timezones
# AWARE:  datetime with timezone — always correct, comparable across zones

now_naive = datetime.now()                    # LOCAL time, no tz — AVOID in prod
now_utc   = datetime.now(timezone.utc)        # UTC aware — ALWAYS use this
now_utc2  = datetime.utcnow()                 # DEPRECATED — returns naive UTC (confusing!)

# ── System Design Rule: always store and compare in UTC ───────────────────
# Store: now_utc.isoformat() → "2024-06-15T14:30:00+00:00"
# Display: convert to user's local timezone at presentation time

# ── Creating specific datetimes ───────────────────────────────────────────
dt = datetime(2024, 6, 15, 14, 30, 0, tzinfo=timezone.utc)   # aware
d  = date(2024, 6, 15)
t  = time(14, 30, 0)

# ── Formatting and parsing ────────────────────────────────────────────────
# isoformat() → ISO 8601 string — the standard for APIs and databases
iso = now_utc.isoformat()                          # "2024-06-15T14:30:00.123456+00:00"

# strftime: format string → human readable
formatted = now_utc.strftime("%Y-%m-%d %H:%M:%S %Z")  # "2024-06-15 14:30:00 UTC"

# strptime: parse string → datetime (NAIVE — add tzinfo if needed)
parsed = datetime.strptime("2024-06-15", "%Y-%m-%d")

# fromisoformat: parse ISO 8601 (Python 3.7+; handles timezone in 3.11+)
awake_dt = datetime.fromisoformat("2024-06-15T14:30:00+00:00")

# ── Arithmetic ────────────────────────────────────────────────────────────
now_utc = datetime.now(timezone.utc)
tomorrow     = now_utc + timedelta(days=1)
three_hours  = now_utc + timedelta(hours=3)
two_weeks_ago = now_utc - timedelta(weeks=2)

expiry = now_utc + timedelta(hours=24)
session_token_valid = datetime.now(timezone.utc) < expiry   # token expiry check

diff = datetime(2025, 1, 1, tzinfo=timezone.utc) - now_utc
print(f"Days until 2025: {diff.days}")

# ── Timezone conversion ────────────────────────────────────────────────────
# Store in UTC, convert to local zone for display
utc_event = datetime(2024, 6, 15, 18, 0, 0, tzinfo=timezone.utc)

new_york = ZoneInfo("America/New_York")
london   = ZoneInfo("Europe/London")
tokyo    = ZoneInfo("Asia/Tokyo")

print(utc_event.astimezone(new_york).strftime("%H:%M %Z"))  # 14:00 EDT
print(utc_event.astimezone(london).strftime("%H:%M %Z"))    # 19:00 BST
print(utc_event.astimezone(tokyo).strftime("%H:%M %Z"))     # 03:00 JST

# ── Practical utility ─────────────────────────────────────────────────────
def is_expired(timestamp_iso: str) -> bool:
    """Check if an ISO 8601 timestamp (with timezone) has expired."""
    dt = datetime.fromisoformat(timestamp_iso)
    return datetime.now(timezone.utc) > dt

def age_in_years(birthdate: date) -> int:
    """Calculate age accounting for whether birthday has occurred this year."""
    today = date.today()
    age = today.year - birthdate.year
    if (today.month, today.day) < (birthdate.month, birthdate.day):
        age -= 1
    return age
```

---

## 6.4 `itertools` — Memory-Efficient Data Processing

```python
import itertools
import operator

# ── WHY itertools? ────────────────────────────────────────────────────────
# itertools functions return LAZY ITERATORS — they process one item at a time
# without loading the entire dataset into memory.
# This is critical when processing large datasets (GB-scale CSV files, streams).

# ── chain — combine multiple iterables without creating a new list ─────────
result = list(itertools.chain([1, 2], [3, 4], [5]))
# [1, 2, 3, 4, 5] — works like unpacking without memory cost

# chain.from_iterable — flatten one level (great for nested lists)
matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
flat = list(itertools.chain.from_iterable(matrix))  # [1, 2, 3, 4, 5, 6, 7, 8, 9]

# ── islice — take the first N elements from any iterable ──────────────────
# Unlike list[:5], islice works on ANY iterator (including infinite ones)
first_five = list(itertools.islice(range(1_000_000), 5))   # [0, 1, 2, 3, 4]
# Never loads all 1M numbers — only processes 5

# ── groupby — group consecutive equal-key elements ─────────────────────────
# CRITICAL: data MUST be sorted by the key first — groupby only groups CONSECUTIVE items
data = [
    {"name": "Alice", "dept": "eng"},
    {"name": "Bob",   "dept": "eng"},
    {"name": "Carol", "dept": "mkt"},
    {"name": "David", "dept": "mkt"},
]
sorted_data = sorted(data, key=lambda x: x["dept"])   # sort first!
for dept, members in itertools.groupby(sorted_data, key=lambda x: x["dept"]):
    names = [m["name"] for m in members]    # consume the group iterator here!
    print(f"{dept}: {names}")
# eng: ['Alice', 'Bob']
# mkt: ['Carol', 'David']

# ── accumulate — running totals / prefix sums ─────────────────────────────
# Used in: balance tracking, prefix sum arrays for range queries
values = [1, 2, 3, 4, 5]
running_sum     = list(itertools.accumulate(values))                    # [1, 3, 6, 10, 15]
running_product = list(itertools.accumulate(values, operator.mul))      # [1, 2, 6, 24, 120]
running_max     = list(itertools.accumulate(values, max))               # [1, 2, 3, 4, 5]

# ── takewhile / dropwhile — conditional streaming ─────────────────────────
nums = [2, 4, 6, 7, 8, 10]
print(list(itertools.takewhile(lambda x: x % 2 == 0, nums)))  # [2, 4, 6] — stops at 7
print(list(itertools.dropwhile(lambda x: x % 2 == 0, nums)))  # [7, 8, 10] — skips leading evens

# ── combinations / permutations / product ─────────────────────────────────
# Used in: recommendation engines, test case generation, feature combinations
chars = ['A', 'B', 'C']
print(list(itertools.combinations(chars, 2)))   # [('A','B'), ('A','C'), ('B','C')]
print(list(itertools.permutations(chars, 2)))   # all ordered pairs
print(list(itertools.product([0, 1], repeat=3))) # all 3-bit binary: (0,0,0) ... (1,1,1)

# ── System Design: streaming batch processor ──────────────────────────────
def batch(iterable, size: int):
    """Yield successive batches of `size` items from any iterable.
    Never loads more than one batch into memory at once.
    Used in: bulk DB inserts, API pagination, chunked processing.
    """
    it = iter(iterable)
    while chunk := list(itertools.islice(it, size)):
        yield chunk

for batch_items in batch(range(100_000), size=1000):
    pass   # process each batch of 1000 without loading 100k at once
```

---

## 6.5 `re` — Regular Expressions

```python
import re

# ── Key functions ─────────────────────────────────────────────────────────
# re.search(p, s)     → first match anywhere in s (or None)
# re.match(p, s)      → match at START of s only (or None)
# re.fullmatch(p, s)  → match must cover ALL of s (or None)
# re.findall(p, s)    → list of all non-overlapping matches
# re.sub(p, r, s)     → replace matches with r
# re.split(p, s)      → split s at each match
# re.compile(p)       → compile a pattern for repeated use (faster)

text = "Contact: support@example.com or sales@company.org"

# ── Basic usage ───────────────────────────────────────────────────────────
match = re.search(r"[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}", text)
if match:
    print(match.group())    # support@example.com
    print(match.span())     # (10, 30) — (start, end) indices

emails = re.findall(r"[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}", text)
print(emails)               # ['support@example.com', 'sales@company.org']

# ── Named groups — the key to readable, maintainable regex ────────────────
# Instead of m.group(1), m.group(2) ... use descriptive names
log_pattern = re.compile(
    r"(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+"
    r"(?P<level>DEBUG|INFO|WARNING|ERROR|CRITICAL)\s+"
    r"(?P<message>.+)"
)

log_line = "2024-06-15 14:30:00 ERROR Failed to connect to database"
m = log_pattern.match(log_line)
if m:
    print(m.group("level"))      # ERROR
    print(m.group("timestamp"))  # 2024-06-15 14:30:00
    print(m.groupdict())         # {'timestamp': ..., 'level': 'ERROR', 'message': ...}

# ── Compiled patterns — compile once, use many times ──────────────────────
# If a pattern is used in a loop or hot path, compile it at module level
EMAIL_RE = re.compile(r"[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}", re.IGNORECASE)
ISO_DATE_RE = re.compile(r"(?P<y>\d{4})-(?P<m>\d{2})-(?P<d>\d{2})")

def extract_emails(text: str) -> list[str]:
    return EMAIL_RE.findall(text)

def parse_date(s: str) -> dict | None:
    m = ISO_DATE_RE.fullmatch(s.strip())
    return m.groupdict() if m else None

# ── Substitution and cleaning ─────────────────────────────────────────────
raw = "  Hello   World  \n\t  "
cleaned = re.sub(r"\s+", " ", raw).strip()    # "Hello World"

# Redact sensitive data in logs:
redacted = re.sub(r"password=[^&\s]+", "password=***", "user=alice&password=secret123")
# "user=alice&password=***"

# ── Splitting on multiple delimiters ─────────────────────────────────────
parts = re.split(r"[,;|\t]+", "Alice, Bob; Carol|David\tEve")
print(parts)    # ['Alice', 'Bob', 'Carol', 'David', 'Eve']

# ── Flags ─────────────────────────────────────────────────────────────────
# re.IGNORECASE (re.I)  — case insensitive
# re.MULTILINE  (re.M)  — ^ and $ match start/end of each LINE
# re.DOTALL     (re.S)  — . matches newlines too
# re.VERBOSE    (re.X)  — allow whitespace and comments in pattern

VERBOSE_EMAIL = re.compile(r"""
    [\w.+-]+     # local part (before @)
    @            # at symbol
    [\w-]+       # domain name
    \.           # dot
    [a-zA-Z]{2,} # TLD (at least 2 chars)
""", re.VERBOSE)
```

---

## 6.6 `typing` — Precise Type Annotations

```python
from typing import TypeVar, Generic, Protocol, runtime_checkable, Literal, TypedDict
from typing import Callable, Iterator, Generator, Any, TYPE_CHECKING
from collections.abc import Sequence, Mapping

# ── WHY type hints? ───────────────────────────────────────────────────────
# 1. Documentation: a reader sees exactly what a function expects and returns
# 2. Tooling: IDEs autocomplete, mypy catches bugs before runtime
# 3. Contracts: makes implicit assumptions explicit

# ── Modern union syntax (Python 3.10+) ───────────────────────────────────
def process(value: int | str | None) -> str:   # int OR str OR None
    return str(value) if value is not None else "none"

# ── TypeVar — write generic functions ─────────────────────────────────────
# T is a placeholder for "some type, determined by the caller"
T = TypeVar("T")

def first(items: list[T]) -> T:
    """Return the first item. The TYPE of return matches the list element type."""
    if not items:
        raise ValueError("List is empty")
    return items[0]

first([1, 2, 3])     # mypy knows return type is int
first(["a", "b"])    # mypy knows return type is str

# ── Callable — type-hint functions as arguments ───────────────────────────
def apply_twice(func: Callable[[int], int], value: int) -> int:
    """Applies func twice. func must take int and return int."""
    return func(func(value))

apply_twice(lambda x: x * 2, 3)   # 12 — mypy verifies lambda signature

# ── Protocol — structural subtyping (the right way to do duck typing) ─────
# Instead of: class Dog(Animal) — inheritance
# Use: class Dog satisfies Animal Protocol — just has the required methods

@runtime_checkable   # allows isinstance() checks at runtime
class Serializable(Protocol):
    """Anything that can serialize itself to a dict."""
    def to_dict(self) -> dict: ...

class User:
    def __init__(self, name: str): self.name = name
    def to_dict(self) -> dict: return {"name": self.name}

class Product:
    def __init__(self, sku: str): self.sku = sku
    def to_dict(self) -> dict: return {"sku": self.sku}

def serialize_all(items: list[Serializable]) -> list[dict]:
    """Works with ANY class that has to_dict() — no inheritance needed."""
    return [item.to_dict() for item in items]

result = serialize_all([User("Alice"), Product("SKU-001")])  # works!
print(isinstance(User("Bob"), Serializable))  # True — runtime_checkable

# ── Literal — restrict to specific allowed values ─────────────────────────
# Better than str for parameters with a fixed set of valid options
Environment = Literal["development", "staging", "production"]
LogLevel    = Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]

def deploy(env: Environment) -> None:
    print(f"Deploying to {env}")

# deploy("prod") → mypy error: "prod" is not a valid Environment

# ── TypedDict — typed dict shapes ────────────────────────────────────────
# Use when you have dicts with a known, fixed schema
# Great for: API response shapes, config dicts, typed database rows
class UserRecord(TypedDict):
    id: int
    name: str
    email: str
    active: bool

def format_user(user: UserRecord) -> str:
    return f"{'✓' if user['active'] else '✗'} {user['name']} <{user['email']}>"

# ── TYPE_CHECKING — avoid circular imports ────────────────────────────────
if TYPE_CHECKING:
    from mymodule import MyClass   # only imported during type checking, not at runtime
```

---

## 6.7 Package Management with `pip`

```bash
# ── Installing ────────────────────────────────────────────────────────────
pip install requests                    # latest version
pip install requests==2.31.0            # exact version (reproducible)
pip install "requests>=2.28,<3.0"       # version range
pip install -r requirements.txt         # install from file
pip install -e .                        # editable install (for local dev)
pip install "fastapi[all]"              # with optional extras

# ── Information ───────────────────────────────────────────────────────────
pip list                                # all installed packages
pip show requests                       # version, location, dependencies
pip check                               # check for dependency conflicts

# ── Dependency management ─────────────────────────────────────────────────
# WRONG: pip freeze > requirements.txt — includes ALL transitive deps (messy)
# BETTER: pip-compile (pip-tools) — generates pinned requirements from top-level deps
# BEST: use Poetry or pyproject.toml (see Module 07)

# For simple projects, pip freeze is fine:
pip freeze > requirements.txt           # pin current environment exactly
```

### `requirements.txt` — Best Practices

```text
# requirements.txt — production dependencies, PINNED for reproducibility
# Why pin? "pip install requests" today might install 2.31, tomorrow 2.32 — subtle breaks
requests==2.31.0
pydantic==2.5.3
fastapi==0.104.1
uvicorn[standard]==0.24.0

# requirements-dev.txt — development-only tools, NOT deployed to production
-r requirements.txt         # include all production deps
pytest==7.4.3
pytest-cov==4.1.0
black==23.11.0
ruff==0.1.6
mypy==1.7.1
```

### Version Specifiers

| Specifier | Meaning | Example |
|-----------|---------|--------|
| `==1.2.3` | Exact version | Reproducible builds |
| `>=1.2,<2.0` | Compatible range | Allows patch updates |
| `~=1.2.3` | Compatible release | `>=1.2.3, <1.3` |
| `!=1.3.0` | Exclude version | Known buggy release |

---

---

## Best Practices

```python
# 1. Use os.environ.get() with defaults — never crash on missing env var
db_url = os.environ.get("DATABASE_URL", "sqlite:///dev.db")

# 2. Always use list form and timeout in subprocess.run()
result = subprocess.run(["cmd", "arg"], capture_output=True, text=True, timeout=30)

# 3. Always work in UTC — store as UTC, convert to local only for display
from datetime import datetime, timezone
now = datetime.now(timezone.utc)   # always aware

# 4. Compile regex patterns at module level, not inside functions
EMAIL_RE = re.compile(r"[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}")  # compiled once

# 5. Use itertools for large data — lazy, never loads everything into RAM
for batch in itertools.islice(big_dataset, 100):
    process(batch)

# 6. Pin versions in requirements.txt
# requests==2.31.0  — not: requests>=2.0

# 7. Use Protocol for structural typing (duck typing with type safety)
class Serializable(Protocol):
    def to_dict(self) -> dict: ...
```

---

## Exercises

### Exercise 6.1 — File Statistics

```python
import os
from collections import Counter
from pathlib import Path

def file_stats(directory: str) -> dict:
    """Return total files, total size, extension counts, and top 5 largest."""
    counts: Counter = Counter()
    sizes: list[tuple[int, str]] = []
    total_size = 0

    for root, _dirs, files in os.walk(directory):
        for name in files:
            path = os.path.join(root, name)
            ext = os.path.splitext(name)[1].lower() or "(none)"
            counts[ext] += 1
            try:
                size = os.path.getsize(path)
                total_size += size
                sizes.append((size, path))
            except OSError:
                pass

    sizes.sort(reverse=True)
    return {
        "total_files": sum(counts.values()),
        "total_size_mb": round(total_size / 1_048_576, 2),
        "by_extension": counts.most_common(5),
        "largest_files": sizes[:5],
    }
```

### Exercise 6.2 — Log Parser with Regex

```python
import re

LOG_RE = re.compile(
    r'(?P<ip>\S+)\s+\S+\s+\S+\s+\[(?P<time>[^\]]+)\]\s+'
    r'"(?P<method>\w+)\s+(?P<path>\S+)[^"]*"\s+'
    r'(?P<status>\d{3})\s+(?P<size>\d+|-)'
)

def parse_log_line(line: str) -> dict | None:
    """Parse Apache/Nginx combined log format."""
    m = LOG_RE.match(line.strip())
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

line = '127.0.0.1 - frank [10/Oct/2000:13:55:36] "GET /index.html HTTP/1.0" 200 2326'
print(parse_log_line(line))
```

---

## Interview Prep — Top Questions for the Standard Library

**Q1: What is the 12-Factor App principle for configuration?**
Store configuration in environment variables — not hardcoded in source code, not in committed config files. This makes the app portable across environments (dev/staging/prod) by just changing env vars. Use `os.environ.get("KEY", "default")` for optional config and `os.environ["KEY"]` for required config (fail fast if missing). `pydantic-settings` automates this in production.

**Q2: Why use `subprocess.run(["cmd", "arg"])` instead of `os.system("cmd arg")`?**
`os.system` passes the command to a shell — enables shell injection (if any part is user-supplied). `subprocess.run` with a list bypasses the shell entirely: each element is treated as a literal argument. Also, `subprocess.run` lets you capture stdout/stderr, check return codes, set timeouts, and handle errors programmatically. `os.system` is a legacy API.

**Q3: Explain the difference between naive and aware `datetime` objects.**
A **naive** datetime has no timezone info — it could represent any timezone, making cross-timezone comparisons unreliable. An **aware** datetime has `tzinfo` set — it represents an exact moment in time. Always use `datetime.now(timezone.utc)` for timestamps. Store as UTC, convert to local timezone only for display. Never compare naive and aware datetimes.

**Q4: What is a `Protocol` in Python's typing system?**
`Protocol` enables **structural subtyping** (duck typing with type safety). A class satisfies a `Protocol` if it has the required methods/attributes — no explicit `class Foo(Protocol)` inheritance needed. The type checker verifies compliance statically. `@runtime_checkable` additionally allows `isinstance()` checks. This is how you write type-safe duck typing: define the interface separately from implementations.

**Q5: Why are `itertools` functions lazy (generators) rather than returning lists?**
Lazy evaluation avoids loading all data into memory at once. For 1GB CSV files, `itertools.islice(rows, 1000)` processes 1000 rows without loading 1M. Laziness also enables infinite sequences (`itertools.count()`), short-circuit evaluation (`takewhile`), and pipeline composition — each step processes one item at a time without intermediate lists.

**Q6: What is the difference between `re.match()`, `re.search()`, and `re.fullmatch()`?**
- `re.match(p, s)`: matches pattern at the **start** of the string only
- `re.search(p, s)`: finds the **first occurrence** anywhere in the string  
- `re.fullmatch(p, s)`: pattern must match the **entire** string  
Use `match` for prefix validation, `search` for extraction, `fullmatch` for strict format validation (phone numbers, dates, codes).

---

## Module Summary

| Module | Primary Use | System Design Relevance |
|--------|------------|-------------------------|
| `os` | Env vars, directory traversal | Config from environment (12-Factor) |
| `sys` | Interpreter info, argv, exit codes | CLI tools, exit status in scripts |
| `subprocess` | Run external programs | CI/CD pipelines, build tools |
| `datetime` + `zoneinfo` | Timezone-aware date/time | Scheduling, audit timestamps, token expiry |
| `itertools` | Lazy combinatorial iteration | Streaming pipelines, batch processing |
| `re` | Pattern matching, extraction | Log parsing, input validation, scraping |
| `typing` + `Protocol` | Type annotations, structural typing | APIs, interfaces, type-safe code |
| `pip` + `requirements.txt` | Dependency management | Reproducible builds, CI/CD |

---

## Quiz

1. What is the difference between `os.environ["KEY"]` and `os.environ.get("KEY")`?
2. Why should you use `subprocess.run(["cmd", "arg"])` instead of `subprocess.run("cmd arg", shell=True)`?
3. What is the difference between a naive and an aware `datetime`? Why does it matter in production?
4. Why must data be sorted by the grouping key before passing to `itertools.groupby()`?
5. What does `re.compile()` return, and when should you use it?
6. What is the difference between `re.match()` and `re.search()`?
7. What does `pip freeze > requirements.txt` capture, and what is its limitation?
8. What is the difference between `TypedDict` and `@dataclass`? When would you prefer each?
9. What does `@runtime_checkable` enable for a `Protocol`?
10. What is the output of `list(itertools.accumulate([1, 2, 3, 4]))`? What stdlib use case does this serve?

**Answers:**
1. `os.environ["KEY"]` raises `KeyError` if missing. `os.environ.get("KEY", default)` returns the default. Use `[]` for required vars (fail fast), `.get()` for optional vars.
2. `shell=True` passes the command to a shell — enabling shell injection attacks if any input is user-controlled. The list form treats each argument as a literal string — no shell parsing.
3. Naive = no timezone info. Aware = has timezone. In production, naive datetimes cause subtle bugs when servers span timezones — a naive UTC and naive local time compare as equal or wrong. Always use `datetime.now(timezone.utc)`.
4. `groupby` groups only **consecutive** elements with the same key. Unsorted data would create multiple groups for the same key (e.g., two separate "eng" groups). Sort first to consolidate.
5. `re.compile()` returns a compiled pattern object. Use it when the same pattern is applied many times — avoids recompiling on every call, which is a performance win in loops.
6. `re.match()` only matches at the **start** of the string. `re.search()` scans the entire string for the first match. Use `match` for format validation, `search` for extraction.
7. It captures exact versions of ALL installed packages (including transitive deps). Limitation: generates a very long file including dev tools; not suitable as a minimal production requirements list.
8. `TypedDict` is for existing dict-shaped data (API responses, JSON). `@dataclass` is for proper objects with methods and behavior. Prefer `@dataclass` for new code you control.
9. `@runtime_checkable` allows `isinstance(obj, MyProtocol)` at runtime. Without it, `isinstance` would raise `TypeError`.
10. `[1, 3, 6, 10]` — running prefix sums. Used for range-sum queries: `prefix[r] - prefix[l-1]` gives sum of any subrange in O(1) after O(n) setup.

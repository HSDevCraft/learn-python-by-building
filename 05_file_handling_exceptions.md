# Module 05 — File Handling and Exception Management

> **Level:** Intermediate | **Estimated Time:** 5 hours | **Prerequisites:** Modules 01–04

---

## Learning Objectives

By the end of this module you will be able to:
- Explain how the OS, Python, and the `with` statement manage file descriptors
- Read and write text and binary files safely using context managers
- Work with CSV, JSON, and structured file formats using the standard library
- Traverse directory trees using `pathlib` — the modern, cross-platform way
- Design a custom exception hierarchy for a real application
- Apply `try/except/else/finally` correctly — knowing when to use each block
- Build custom context managers with `__enter__`/`__exit__` and `@contextmanager`
- Implement system design patterns: config loading, audit logging, file-based event sourcing

---

## The Big Picture — Why Files and Exceptions Matter in System Design

Every real system touches the filesystem:
- **Config files** — load application settings at startup
- **Log files** — record events for debugging and audit
- **Data files** — read CSV/JSON exports, write reports
- **Temp files** — buffer large computations, stage uploads

And **every** production system must handle failures gracefully:
- What if the config file is missing? → Custom exception, descriptive message
- What if the network drops mid-write? → `finally` block, context manager cleanup
- What if JSON is malformed? → Catch, chain, re-raise with context

```
File I/O mental model:
  Your code  ──open()──►  OS file descriptor  ──►  Disk
                              ▲
                       open = acquire resource
                       close = release resource
                       
  If you forget close():
    - File descriptor leaked (limited resource, OS has ~1024 per process)
    - Data may not be flushed to disk (write buffer not flushed)
    - Other processes may be locked out
    
  The 'with' statement guarantees __exit__() is called,
  which calls file.close(), even when an exception occurs.
```

---

## 5.1 File I/O with Context Managers

```python
from pathlib import Path

# ── WRONG: file may not close if an exception occurs ─────────────────────
f = open("data.txt", "r")
data = f.read()              # if this raises, f.close() is never called!
f.close()                    # file descriptor leaked

# ── CORRECT: 'with' guarantees __exit__() → file.close() always runs ─────
with open("data.txt", "r", encoding="utf-8") as f:
    data = f.read()          # even if this raises, file is closed
# file is already closed here

# ── File open modes ──────────────────────────────────────────────────────
# "r"  — read text (default)
# "w"  — write text (creates file, TRUNCATES existing content)
# "a"  — append text (creates file if missing, adds to end)
# "x"  — exclusive create (fails if file already exists — safe create)
# "b"  — binary mode (combine: "rb", "wb")
# "+"  — read and write: "r+" (must exist), "w+" (create/truncate)

# ── Reading strategies — choose based on file size ───────────────────────
path = Path("sample.txt")

# 1. Read entire file at once — simple, fine for small files (<50MB)
content = path.read_text(encoding="utf-8")           # pathlib shorthand

# 2. Read line by line — O(1) memory, good for large files
with open(path, encoding="utf-8") as f:
    for line in f:                                   # f is a lazy iterator
        processed = line.rstrip("\n")                # strip trailing newline

# 3. Read all lines into a list — loads everything into RAM
with open(path, encoding="utf-8") as f:
    lines = [line.strip() for line in f]             # list comprehension

# 4. Read in chunks — for very large binary files (videos, blobs)
def read_chunks(filepath: Path, size: int = 65536):
    """Generator yielding file content in chunks of `size` bytes."""
    with open(filepath, "rb") as f:
        while chunk := f.read(size):                 # walrus: assign and test
            yield chunk                              # caller processes each chunk

# ── Writing strategies ────────────────────────────────────────────────────
output = Path("output.txt")

# Overwrite: creates file if missing, truncates if existing
with open(output, "w", encoding="utf-8") as f:
    f.write("Line 1\n")
    f.write("Line 2\n")
    f.writelines(["Line 3\n", "Line 4\n"])           # write many at once

# Append: add to end without touching existing content
with open(output, "a", encoding="utf-8") as f:
    f.write("Appended line\n")

# Atomic write pattern — prevents corrupt files on crash:
# Write to a temp file, then rename (rename is atomic on most OS)
import tempfile, shutil

def atomic_write(path: Path, content: str) -> None:
    """Write content atomically — reader never sees a partial file."""
    tmp = path.with_suffix(".tmp")
    try:
        tmp.write_text(content, encoding="utf-8")
        shutil.move(str(tmp), str(path))             # atomic on Unix; near-atomic on Windows
    except Exception:
        tmp.unlink(missing_ok=True)                  # clean up temp on failure
        raise
```

---

## 5.2 `pathlib` — Modern Cross-Platform Path Handling

```python
from pathlib import Path
import shutil

# ── Why pathlib over os.path? ─────────────────────────────────────────────
# os.path.join("data", "file.txt")  → string concatenation, error-prone
# Path("data") / "file.txt"         → object with methods, cross-platform

# ── Building paths ────────────────────────────────────────────────────────
base = Path("projects") / "my_app" / "data"     # / operator joins paths
home = Path.home()                               # /home/username or C:/Users/username
cwd  = Path.cwd()                                # current working directory

# ── Path inspection — all are properties, no () needed ───────────────────
p = Path("/home/alice/documents/report.pdf")
print(p.name)           # 'report.pdf'         — filename with extension
print(p.stem)           # 'report'             — filename without extension
print(p.suffix)         # '.pdf'               — extension including dot
print(p.suffixes)       # ['.pdf']             — all extensions (for .tar.gz → ['.tar','.gz'])
print(p.parent)         # /home/alice/documents
print(p.parents[1])     # /home/alice          — grandparent
print(p.parts)          # ('/', 'home', 'alice', 'documents', 'report.pdf')
print(p.is_absolute())  # True

# ── Creating and removing ─────────────────────────────────────────────────
data_dir = Path("data/raw/2024")
data_dir.mkdir(parents=True, exist_ok=True)     # create full tree safely

p = Path("temp/file.txt")
p.parent.mkdir(parents=True, exist_ok=True)     # ensure parent exists first
p.write_text("content", encoding="utf-8")

p.unlink(missing_ok=True)                       # delete file (no error if gone)
shutil.rmtree("temp", ignore_errors=True)       # delete directory tree

# ── Inspection ────────────────────────────────────────────────────────────
config = Path("config.json")
print(config.exists())                          # True/False
print(config.is_file())                         # True if it's a regular file
print(config.is_dir())                          # True if it's a directory

stat = config.stat()
print(f"Size: {stat.st_size:,} bytes")
print(f"Modified: {stat.st_mtime}")

# ── Iterating and globbing ────────────────────────────────────────────────
project = Path(".")

# Direct children:
for entry in project.iterdir():
    kind = "dir" if entry.is_dir() else "file"
    print(f"{kind}: {entry.name}")

# Glob — find by pattern:
python_files = list(project.glob("**/*.py"))    # ** = recursive
json_files   = list(project.glob("*.json"))     # *.json in current dir only

# rglob — recursive glob shorthand:
all_md = list(project.rglob("*.md"))            # same as glob("**/*.md")

# ── Renaming, copying, moving ─────────────────────────────────────────────
Path("old.txt").rename("new.txt")               # rename in same directory
shutil.copy2("source.txt", "backup.txt")        # copy with metadata preserved
shutil.move("file.txt", "archive/file.txt")     # move (rename across dirs)

# ── Path manipulation ─────────────────────────────────────────────────────
p = Path("reports/2024/q1.csv")
print(p.with_name("q2.csv"))        # reports/2024/q2.csv
print(p.with_suffix(".json"))       # reports/2024/q1.json
print(p.relative_to("reports"))    # 2024/q1.csv
print(p.resolve())                  # absolute path, resolves symlinks
```

---

## 5.3 Structured File Formats

### CSV — Tabular Data

```python
import csv
from pathlib import Path

# ── Writing CSV with DictWriter ───────────────────────────────────────────
employees = [
    {"name": "Alice", "department": "Engineering", "salary": 95000},
    {"name": "Bob",   "department": "Marketing",   "salary": 72000},
    {"name": "Carol", "department": "Engineering", "salary": 105000},
]

# ALWAYS use newline="" when opening CSV files to prevent blank rows on Windows
with open("employees.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["name", "department", "salary"])
    writer.writeheader()                # writes the header row
    writer.writerows(employees)         # writes all rows at once

# ── Reading CSV with DictReader ───────────────────────────────────────────
with open("employees.csv", "r", newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)          # first row becomes field names
    for row in reader:
        # NOTE: all values from CSV are strings — convert as needed
        print(f"{row['name']}: ${int(row['salary']):,}")

# ── Memory-efficient streaming for large CSVs ─────────────────────────────
def stream_csv(path: Path):
    """Yield rows one at a time without loading entire file."""
    with open(path, newline="", encoding="utf-8") as f:
        yield from csv.DictReader(f)    # generator — only reads one row at a time
```

### JSON — Structured Data

```python
import json
from pathlib import Path
from datetime import datetime, date
from typing import Any

# ── Basic read/write ──────────────────────────────────────────────────────
data = {
    "users": [
        {"id": 1, "name": "Alice", "active": True},
        {"id": 2, "name": "Bob",   "active": False},
    ],
    "count": 2,
}

# Write (indent=2 makes it human-readable)
with open("data.json", "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)   # ensure_ascii=False preserves Unicode

# Read
with open("data.json", "r", encoding="utf-8") as f:
    loaded = json.load(f)

# String conversion — for API payloads, Redis values, etc.
payload = json.dumps(data, indent=2)
parsed  = json.loads(payload)

# ── Custom encoder: handle types json doesn't know ────────────────────────
class AppJSONEncoder(json.JSONEncoder):
    """Extends JSON encoder to handle datetime, date, set, Path."""
    def default(self, obj: Any) -> Any:
        if isinstance(obj, (datetime, date)):
            return obj.isoformat()          # "2024-01-15T10:30:00"
        if isinstance(obj, set):
            return sorted(list(obj))        # set → sorted list (deterministic)
        if isinstance(obj, Path):
            return str(obj)                 # Path → string
        return super().default(obj)         # raises TypeError for unknown types

event = {
    "name": "Deploy",
    "timestamp": datetime.now(),
    "tags": {"python", "production"},
    "path": Path("logs/deploy.log"),
}
print(json.dumps(event, cls=AppJSONEncoder, indent=2))

# ── Pathlib shorthand ─────────────────────────────────────────────────────
path = Path("config.json")
path.write_text(json.dumps({"debug": True}, indent=2), encoding="utf-8")
config = json.loads(path.read_text(encoding="utf-8"))
```

---

## 5.4 Exception Handling — The Full Picture

### How Python Exceptions Work

```
try block raises ExceptionType
       │
       ▼
Python walks the CALL STACK upward, looking for:
  1. A matching except ExceptionType clause
  2. If found → execute that except block
  3. If not found → unwind the stack, print traceback, exit

Key blocks:
  try:     → normal code path
  except:  → error handling (runs INSTEAD of the rest of try)
  else:    → success path (runs ONLY if NO exception was raised in try)
  finally: → cleanup (runs ALWAYS — whether or not an exception occurred)
```

```python
def process_file(path: str) -> dict:
    """Demonstrates all four try/except/else/finally blocks."""
    f = None
    try:
        f = open(path, encoding="utf-8")          # might raise FileNotFoundError
        data = json.loads(f.read())               # might raise JSONDecodeError
        result = transform(data)                  # might raise anything
    except FileNotFoundError:
        print(f"File not found: {path}")
        return {}                                 # safe default
    except json.JSONDecodeError as e:
        print(f"Invalid JSON in {path}: {e}")
        return {}
    else:
        # This block ONLY runs if NO exception occurred in try
        print(f"Successfully processed {path}")
        return result
    finally:
        # ALWAYS runs — perfect for cleanup
        if f and not f.closed:
            f.close()
        print("Processing attempt complete")       # logs every attempt
```

### Python Exception Hierarchy

```
BaseException                    ← don't catch this directly
 ├── SystemExit                  ← sys.exit() — don't catch
 ├── KeyboardInterrupt           ← Ctrl+C — don't catch (usually)
 └── Exception                  ← catch this as a last resort
      ├── ValueError             ← bad value (int("abc"))
      ├── TypeError              ← wrong type (1 + "a")
      ├── AttributeError         ← missing attribute (None.split())
      ├── KeyError               ← missing dict key (d["x"])
      ├── IndexError             ← list index out of range
      ├── NameError              ← undefined variable
      ├── RuntimeError           ← generic runtime issue
      ├── NotImplementedError    ← abstract method not overridden
      ├── StopIteration          ← iterator exhausted
      └── OSError                ← I/O and system calls
           ├── FileNotFoundError  ← file/dir doesn't exist
           ├── PermissionError    ← access denied
           ├── IsADirectoryError  ← expected file, got directory
           └── ConnectionError    ← network issues
```

```python
# ── Catching the right things ─────────────────────────────────────────────

# Catch one specific exception:
try:
    value = int("abc")
except ValueError as e:
    print(f"Conversion failed: {e}")

# Catch multiple specific exceptions (same handler):
try:
    result = data["key"] + 1
except (KeyError, TypeError) as e:
    print(f"Data problem: {type(e).__name__}: {e}")

# Catch with different handlers per type:
try:
    result = risky_call()
except ValueError as e:
    handle_validation(e)
except OSError as e:
    handle_io(e)
except Exception as e:
    logger.error("Unexpected error", exc_info=True)
    raise           # always re-raise unexpected exceptions!

# ── Re-raising ────────────────────────────────────────────────────────────
try:
    do_work()
except Exception as e:
    logger.error(f"Work failed: {e}")
    raise           # re-raise the SAME exception with original traceback

# ── Exception chaining — preserve the original cause ─────────────────────
import json
from pathlib import Path

def load_config(path: str) -> dict:
    try:
        return json.loads(Path(path).read_text())
    except FileNotFoundError as e:
        raise RuntimeError(f"Config missing: {path}") from e    # chain!
    except json.JSONDecodeError as e:
        raise ValueError(f"Config corrupted: {path}") from e    # chain!
    # Callers see RuntimeError/ValueError but __cause__ holds the original

# ── NEVER do these ────────────────────────────────────────────────────────
try:
    something()
except:             # BAD: bare except catches KeyboardInterrupt, SystemExit
    pass            # BAD: silences ALL exceptions — bugs become invisible
```

### Custom Exception Hierarchies

```python
from __future__ import annotations
from dataclasses import dataclass
from http import HTTPStatus

# ── Define a hierarchy for your application ───────────────────────────────
class AppError(Exception):
    """Root exception for all application errors. Always catch at the boundary."""

class ConfigError(AppError):
    """Configuration loading or validation failed."""

class StorageError(AppError):
    """Database or file system operation failed."""

class NotFoundError(AppError):
    """Requested resource does not exist."""
    def __init__(self, resource: str, identifier: object) -> None:
        self.resource = resource
        self.identifier = identifier
        super().__init__(f"{resource} '{identifier}' not found")

class ValidationError(AppError):
    """Input data failed validation."""
    def __init__(self, field: str, value: object, reason: str) -> None:
        self.field = field
        self.value = value
        self.reason = reason
        super().__init__(f"Validation failed for '{field}={value!r}': {reason}")

class AuthError(AppError):
    """Authentication or authorization failed."""
    def __init__(self, message: str, status: HTTPStatus = HTTPStatus.UNAUTHORIZED) -> None:
        self.status = status
        super().__init__(message)

# ── Usage: callers can catch at any level of specificity ─────────────────
def get_user(user_id: int) -> dict:
    if not isinstance(user_id, int) or user_id <= 0:
        raise ValidationError("user_id", user_id, "must be a positive integer")

    db = {1: {"name": "Alice", "role": "admin"}, 2: {"name": "Bob", "role": "user"}}

    if user_id not in db:
        raise NotFoundError("User", user_id)

    return db[user_id]

# Caller can be specific or general:
try:
    user = get_user(99)
except NotFoundError as e:
    print(f"404: {e}")                  # handles specifically
except ValidationError as e:
    print(f"400: {e.field} → {e.reason}")
except AppError as e:
    print(f"Application error: {e}")    # catches any app error
```

---

## 5.5 Custom Context Managers

```python
import contextlib
import time
from pathlib import Path
from typing import Generator

# ── Method 1: Class with __enter__ and __exit__ ───────────────────────────
class Timer:
    """Measure elapsed time for any code block."""

    def __enter__(self) -> "Timer":
        self._start = time.perf_counter()
        return self                             # 'as t' gets this object

    def __exit__(self, exc_type, exc_val, exc_tb) -> bool:
        self.elapsed = time.perf_counter() - self._start
        # exc_type is None if no exception, or the exception class if one occurred
        if exc_type:
            print(f"Failed after {self.elapsed:.4f}s: {exc_val}")
        else:
            print(f"Completed in {self.elapsed:.4f}s")
        return False    # False = DO NOT suppress exceptions (they propagate normally)
                        # True  = suppress the exception (rarely correct)

with Timer() as t:
    total = sum(i**2 for i in range(1_000_000))
print(f"Sum: {total}, took {t.elapsed:.4f}s")

# ── Method 2: @contextmanager — simpler generator-based approach ──────────
# yield once: everything BEFORE yield is __enter__, AFTER yield is __exit__

@contextlib.contextmanager
def temp_directory() -> Generator[Path, None, None]:
    """Create a temporary directory, clean it up when done."""
    import tempfile, shutil
    tmp = Path(tempfile.mkdtemp())
    try:
        yield tmp               # caller works with the temp dir here
    finally:
        shutil.rmtree(tmp, ignore_errors=True)   # always clean up

with temp_directory() as tmp:
    (tmp / "data.txt").write_text("hello", encoding="utf-8")
    files = list(tmp.iterdir())
    print(f"Temp files: {files}")
# temp dir is deleted here

@contextlib.contextmanager
def database_transaction(db):
    """Wrap DB calls in a transaction — commit on success, rollback on error."""
    try:
        yield db
        db.commit()             # runs if no exception
    except Exception:
        db.rollback()           # runs if any exception
        raise                   # re-raise so caller knows it failed

# ── System Design: Distributed Lock via a file ────────────────────────────
@contextlib.contextmanager
def file_lock(lock_path: Path, timeout: float = 5.0) -> Generator[None, None, None]:
    """
    Simple file-based mutex — prevents two processes running the same task.
    Used in: cron job deduplication, multi-worker task queues.
    """
    import time
    start = time.monotonic()
    while True:
        try:
            fd = lock_path.open("x")    # "x" mode: exclusive create — fails if exists
            break
        except FileExistsError:
            if time.monotonic() - start > timeout:
                raise TimeoutError(f"Could not acquire lock: {lock_path}")
            time.sleep(0.1)             # wait and retry
    try:
        yield
    finally:
        fd.close()
        lock_path.unlink(missing_ok=True)   # release lock

with file_lock(Path("/tmp/my_job.lock")):
    print("Running exclusive task...")
```

---

## 5.6 System Design — Patterns Using File I/O

### Append-Only Audit Log (Event Sourcing)

```python
import json
from datetime import datetime, timezone
from pathlib import Path
from contextlib import contextmanager

class AuditLog:
    """
    Append-only audit log stored as newline-delimited JSON (NDJSON).
    Each line is an independent JSON object — robust to partial writes.

    Used in: financial systems, security auditing, event sourcing.
    NDJSON allows streaming reads without loading the entire file.
    """

    def __init__(self, log_path: Path) -> None:
        self._path = log_path
        self._path.parent.mkdir(parents=True, exist_ok=True)

    def record(self, event_type: str, actor: str, **details) -> None:
        """Append one audit event. Thread-safe for single-process use."""
        entry = {
            "timestamp": datetime.now(tz=timezone.utc).isoformat(),
            "event":     event_type,
            "actor":     actor,
            **details,
        }
        # "a" mode + one json.dumps per line = append-only, crash-safe
        with open(self._path, "a", encoding="utf-8") as f:
            f.write(json.dumps(entry) + "\n")   # one JSON object per line

    def read_events(self, event_type: str | None = None):
        """Stream events from the log, optionally filtered by type."""
        if not self._path.exists():
            return
        with open(self._path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                event = json.loads(line)
                if event_type is None or event["event"] == event_type:
                    yield event

audit = AuditLog(Path("logs/audit.ndjson"))
audit.record("user_login",    actor="alice",  ip="192.168.1.1")
audit.record("config_change", actor="admin",  key="timeout", old=30, new=60)
audit.record("user_login",    actor="bob",    ip="10.0.0.5")

print("All logins:")
for event in audit.read_events("user_login"):
    print(f"  {event['actor']} from {event['ip']} at {event['timestamp']}")
```

---

## Best Practices

```python
# 1. Always use 'with' — never bare open()
with open("file.txt", encoding="utf-8") as f:
    data = f.read()

# 2. Always specify encoding explicitly
with open("file.txt", encoding="utf-8") as f: ...   # not relying on platform default

# 3. Use pathlib.Path for all path operations
from pathlib import Path
path = Path("data") / "file.txt"     # not os.path.join("data", "file.txt")

# 4. Catch specific exceptions, never bare except
try: ...
except FileNotFoundError: ...        # specific
# NOT: except:  or  except Exception as e: pass

# 5. Always chain exceptions to preserve cause
try: ...
except json.JSONDecodeError as e:
    raise ConfigError("Bad JSON") from e    # not: raise ConfigError("Bad JSON")

# 6. Design custom exception hierarchies
class AppError(Exception): ...
class NotFoundError(AppError): ...

# 7. Use atomic writes for critical files
tmp = path.with_suffix(".tmp")
tmp.write_text(content)
shutil.move(str(tmp), str(path))     # atomic rename
```

---

## Exercises

### Exercise 5.1 — Log File Analyser

```python
from collections import Counter
from pathlib import Path
import re

def analyse_log(filepath: str | Path) -> dict[str, int]:
    """
    Parse log file and count occurrences of each log level.
    Log format: "2024-01-15 10:30:00 INFO message..."
    """
    levels = Counter()
    level_pattern = re.compile(r"\b(DEBUG|INFO|WARNING|ERROR|CRITICAL)\b")

    with open(filepath, encoding="utf-8") as f:
        for line in f:
            match = level_pattern.search(line)
            if match:
                levels[match.group(1)] += 1

    return dict(levels)
```

### Exercise 5.2 — Config Loader with Validation

```python
import json
from pathlib import Path

class ConfigError(Exception): ...

def load_config(path: str | Path, defaults: dict | None = None,
                required: list[str] | None = None) -> dict:
    """Load JSON config, merge with defaults, validate required keys."""
    config = dict(defaults or {})
    try:
        config.update(json.loads(Path(path).read_text(encoding="utf-8")))
    except FileNotFoundError:
        raise ConfigError(f"Config not found: {path}")
    except json.JSONDecodeError as e:
        raise ConfigError(f"Invalid JSON in {path}") from e

    if missing := [k for k in (required or []) if k not in config]:
        raise ConfigError(f"Missing required keys: {missing}")

    return config
```

### Exercise 5.3 — CSV Sales Report

```python
import csv
from pathlib import Path
from collections import defaultdict

def sales_report(input_csv: Path, output_csv: Path) -> dict:
    """Aggregate sales by product and write summary CSV."""
    totals = defaultdict(lambda: {"units": 0, "revenue": 0.0})

    with open(input_csv, newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            p = row["product"]
            totals[p]["units"]   += int(row["quantity"])
            totals[p]["revenue"] += int(row["quantity"]) * float(row["price"])

    with open(output_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["product", "units", "revenue"])
        w.writeheader()
        for product, data in sorted(totals.items()):
            w.writerow({"product": product, "units": data["units"],
                        "revenue": round(data["revenue"], 2)})
    return dict(totals)
```

---

## Mini-Project — JSON-Backed Expense Tracker

```python
import json, csv
from pathlib import Path
from datetime import datetime
from collections import defaultdict

class ExpenseTracker:
    """File-backed expense tracker with JSON persistence and CSV export."""

    def __init__(self, path: Path = Path("expenses.json")) -> None:
        self._path = path
        self._data: list[dict] = self._load()

    def _load(self) -> list[dict]:
        if not self._path.exists():
            return []
        try:
            return json.loads(self._path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            print("Warning: corrupt data file — starting fresh")
            return []

    def _save(self) -> None:
        self._path.write_text(json.dumps(self._data, indent=2), encoding="utf-8")

    def add(self, amount: float, category: str, note: str = "") -> None:
        if amount <= 0:
            raise ValueError("Amount must be positive")
        self._data.append({"date": datetime.now().isoformat("T", "seconds"),
                            "amount": round(amount, 2),
                            "category": category.lower().strip(),
                            "note": note.strip()})
        self._save()

    def summary(self) -> dict[str, float]:
        totals: dict[str, float] = defaultdict(float)
        for e in self._data:
            totals[e["category"]] += e["amount"]
        return dict(totals)

    def export_csv(self, path: Path) -> None:
        with open(path, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=["date","amount","category","note"])
            w.writeheader(); w.writerows(self._data)

    def report(self) -> None:
        if not self._data:
            print("No expenses recorded."); return
        total = sum(e["amount"] for e in self._data)
        print(f"\n{'EXPENSES':=^40}")
        for cat, amt in sorted(self.summary().items(), key=lambda x: -x[1]):
            bar = "█" * int(amt / total * 20)
            print(f"{cat:<15} ${amt:>8.2f}  {bar}")
        print(f"{'TOTAL':=<15} ${total:>8.2f}")

# Demo
t = ExpenseTracker(Path("demo.json"))
t.add(12.50, "food", "Lunch"); t.add(45.00, "food", "Groceries")
t.add(9.99, "transport", "Bus"); t.add(14.99, "subscriptions", "Netflix")
t.report(); t.export_csv(Path("expenses.csv"))
```

---

## Interview Prep — Top Questions for File Handling and Exceptions

**Q1: What is the difference between `Exception` and `BaseException`?**
`BaseException` is the root of all exceptions including `SystemExit`, `KeyboardInterrupt`, and `GeneratorExit` — which should generally propagate unhandled. `Exception` is the base for all **application-level** errors. Always catch `Exception` (or more specific subclasses), never `BaseException` — and never bare `except:` which catches everything including Ctrl+C.

**Q2: When does the `else` block of a `try` statement execute?**
Only when **no exception** was raised in the `try` block. It does NOT run if an exception was raised, even if caught. Use it for code that should only run on success. The `finally` block runs always. Pattern: `try` (risky) → `except` (handle error) → `else` (success work) → `finally` (cleanup always).

**Q3: What is exception chaining (`raise X from Y`)?**
`raise NewError("msg") from original_error` sets `__cause__` on the new exception, preserving the full traceback of the original. Without `from`, the original is lost or shown as `__context__`. Always chain exceptions when translating low-level errors to domain-level errors. In tracebacks, Python shows: "The above exception was the direct cause of the following exception".

**Q4: How do context managers work? What are `__enter__` and `__exit__`?**
A context manager implements `__enter__` (setup, returns value for `as`) and `__exit__(exc_type, exc_val, exc_tb)` (cleanup). The `with` statement calls `__enter__` on entry and `__exit__` on exit — even if an exception occurs. If `__exit__` returns `True`, the exception is suppressed. Use `@contextlib.contextmanager` for simpler generator-based context managers.

**Q5: What is an atomic write and why is it important in production?**
Write to a temporary file first, then `os.rename()` (atomic on POSIX) to the target path. This ensures readers never see a partially-written file. Without atomic writes: if the process crashes mid-write, the file is corrupted. Critical for: config files, checkpoints, any file read concurrently.

**Q6: What is NDJSON and why is it used for log files instead of JSON arrays?**
NDJSON (Newline-Delimited JSON) writes one JSON object per line. If the process crashes, all previously-written lines remain valid. A JSON array needs a closing `]` — a crash leaves it invalid and unparseable. NDJSON supports streaming reads (process line by line) and appending (just write another line). Used in: audit logs, event streams, data pipelines.

**Q7: How do you design a custom exception hierarchy for an application?**
Create a base `AppError(Exception)` for your app, then specific subclasses: `ValidationError`, `NotFoundError`, `AuthError`, `StorageError`. Callers can catch at any specificity level. Each subclass stores relevant context (`field`, `resource`, `status_code`). Map to HTTP status codes at the API boundary. This is the standard pattern at every professional Python shop.

---

## Module Summary

| Concept | Key Takeaway | System Design Use |
|---------|-------------|-------------------|
| `with open()` | Always use — guarantees file.close() | Resource management in any I/O-heavy system |
| `pathlib.Path` | Cross-platform, object-oriented paths | All file path manipulation |
| `encoding="utf-8"` | Always specify — avoid platform surprises | International data, Docker portability |
| `try/except/else/finally` | else=success only; finally=always | Transaction handling, resource cleanup |
| Custom exception hierarchy | Fine-grained error handling for callers | API error codes, service boundaries |
| Exception chaining (`from e`) | Preserves original cause in tracebacks | Debugging across service layers |
| Atomic write | Write to temp, rename — prevents corruption | Config updates, checkpoints |
| Append-only log (NDJSON) | One JSON per line — crash-safe | Audit logs, event sourcing |
| `@contextmanager` | Simple generator-based context manager | DB transactions, locks, timers |

---

## Quiz

1. What happens if an exception occurs inside a `with open(...)` block — is the file closed?
2. What is the difference between `f.read()`, `f.readline()`, and iterating `for line in f`?
3. When does the `else` block of a `try/except` run? When does `finally` run?
4. What does `raise ValueError("msg") from original_error` do that `raise ValueError("msg")` doesn't?
5. Why should you never use a bare `except:` clause?
6. What does `Path("a") / "b" / "c.txt"` produce? Why is this better than `os.path.join`?
7. Why use `open(path, "x")` instead of `open(path, "w")` when creating a new file?
8. How does NDJSON (newline-delimited JSON) make log files more robust than a single JSON array?
9. In `__exit__(self, exc_type, exc_val, exc_tb)`, what does returning `True` do?
10. You're writing a config loader. The file might not exist, might be invalid JSON, or might be missing required keys. Design the exception hierarchy and write the loader.

**Answers:**
1. Yes — `with` guarantees `__exit__()` runs, which closes the file, even if an exception propagates.
2. `f.read()` loads the entire file into one string. `f.readline()` reads one line. `for line in f` is a lazy iterator — reads one line at a time using minimal memory (best for large files).
3. `else` runs only when no exception was raised in the `try` block. `finally` runs unconditionally — whether or not an exception occurred.
4. `from original_error` sets `__cause__` on the new exception, preserving the full original traceback. Without it, the original error context is partially hidden.
5. Bare `except:` catches `SystemExit`, `KeyboardInterrupt`, and `GeneratorExit` — which should normally propagate. It also silences bugs you haven't anticipated.
6. `Path("a/b/c.txt")` — a `Path` object. The `/` operator is overloaded and always uses the correct OS separator. It's also an object with methods, not just a string.
7. `"x"` (exclusive create) raises `FileExistsError` if the file already exists — preventing accidental overwrites. `"w"` silently truncates and replaces any existing file.
8. NDJSON: if the process crashes mid-write, all previously written lines are still valid. A JSON array must have the closing `]` — a crash mid-write produces invalid JSON.
9. Returning `True` from `__exit__` **suppresses** the exception — it does not propagate. Usually wrong; return `False` or `None` to let exceptions propagate normally.
10. Hierarchy: `AppError → ConfigError`. Loader: catch `FileNotFoundError` → raise `ConfigError("not found") from e`; catch `JSONDecodeError` → raise `ConfigError("invalid JSON") from e`; check required keys → raise `ConfigError("missing keys: ...")` directly.

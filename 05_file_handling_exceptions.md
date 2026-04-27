# Module 05 — File Handling and Exception Management

> **Level:** Intermediate | **Estimated Time:** 5 hours | **Prerequisites:** Modules 01–04

---

## Learning Objectives

By the end of this module you will be able to:
- Read and write text and binary files using context managers
- Work with CSV, JSON, and YAML file formats
- Traverse directory trees using `pathlib`
- Design and raise custom exceptions
- Apply try/except/else/finally correctly
- Use `contextlib` to build custom context managers
- Handle real-world I/O errors gracefully

---

## 5.1 File I/O with Context Managers

### Conceptual Foundation

The `with` statement ensures that a file is **always closed**, even if an exception occurs. This is the only correct way to open files — never use bare `open()` without a context manager.

```python
from pathlib import Path

# WRONG — file may not be closed on exception
f = open("data.txt")
data = f.read()
f.close()

# CORRECT — guaranteed close via __exit__
with open("data.txt", "r", encoding="utf-8") as f:
    data = f.read()
```

### Reading Files

```python
from pathlib import Path

path = Path("sample.txt")

# Read entire file at once
content = path.read_text(encoding="utf-8")

# Read line by line — memory efficient for large files
with open(path, "r", encoding="utf-8") as f:
    for line in f:                        # f is an iterator over lines
        print(line.rstrip("\n"))

# Read all lines into a list
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()                 # includes newline characters
    lines = [line.strip() for line in lines]

# Read in chunks — for very large files
def read_in_chunks(filepath: Path, chunk_size: int = 4096):
    """Generator that yields file content in chunks."""
    with open(filepath, "rb") as f:
        while chunk := f.read(chunk_size):
            yield chunk
```

### Writing Files

```python
from pathlib import Path

path = Path("output.txt")

# Write (overwrites existing content)
with open(path, "w", encoding="utf-8") as f:
    f.write("First line\n")
    f.write("Second line\n")

# Append (adds to existing content)
with open(path, "a", encoding="utf-8") as f:
    f.write("Appended line\n")

# Write multiple lines at once
lines = ["line 1\n", "line 2\n", "line 3\n"]
with open(path, "w", encoding="utf-8") as f:
    f.writelines(lines)

# Shorthand via pathlib
path.write_text("Hello, file!\n", encoding="utf-8")
content = path.read_text(encoding="utf-8")
```

---

## 5.2 `pathlib` — Modern Path Handling

`pathlib.Path` is the modern, object-oriented way to work with filesystem paths.

```python
from pathlib import Path

# Build paths — works on Windows AND Unix
base = Path("projects") / "my_app" / "data"

# Path inspection
p = Path("/home/user/documents/report.pdf")
print(p.name)         # report.pdf
print(p.stem)         # report
print(p.suffix)       # .pdf
print(p.parent)       # /home/user/documents
print(p.parts)        # ('/', 'home', 'user', 'documents', 'report.pdf')

# Filesystem operations
data_dir = Path("data")
data_dir.mkdir(parents=True, exist_ok=True)   # create directory tree

# Glob — find files matching a pattern
project = Path(".")
python_files = list(project.glob("**/*.py"))   # recursive
md_files = list(project.glob("*.md"))          # current dir only

# Check existence
path = Path("config.json")
if path.exists():
    print(f"Size: {path.stat().st_size} bytes")
    print(f"Modified: {path.stat().st_mtime}")

# Iterate directory
for entry in Path(".").iterdir():
    if entry.is_file():
        print(f"File: {entry.name}")
    elif entry.is_dir():
        print(f"Dir:  {entry.name}/")

# Copy, move, rename
import shutil
shutil.copy("source.txt", "destination.txt")
shutil.move("old_name.txt", "new_name.txt")
Path("temp.txt").unlink(missing_ok=True)       # delete file safely
```

---

## 5.3 Structured File Formats

### CSV

```python
import csv
from pathlib import Path

# Writing CSV
employees = [
    {"name": "Alice", "department": "Engineering", "salary": 95000},
    {"name": "Bob",   "department": "Marketing",   "salary": 72000},
    {"name": "Carol", "department": "Engineering", "salary": 105000},
]

with open("employees.csv", "w", newline="", encoding="utf-8") as f:
    fieldnames = ["name", "department", "salary"]
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(employees)

# Reading CSV
with open("employees.csv", "r", newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        print(f"{row['name']}: ${int(row['salary']):,}")
```

### JSON

```python
import json
from pathlib import Path
from datetime import datetime

# Python object → JSON string
data = {
    "users": [
        {"id": 1, "name": "Alice", "active": True},
        {"id": 2, "name": "Bob",   "active": False},
    ],
    "generated_at": "2024-01-15",
    "count": 2,
}

# Write to file
with open("data.json", "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)

# Read from file
with open("data.json", "r", encoding="utf-8") as f:
    loaded = json.load(f)

# String conversion (for API responses, etc.)
json_str = json.dumps(data, indent=2)
parsed = json.loads(json_str)

# Custom JSON serialization
class DateTimeEncoder(json.JSONEncoder):
    """JSON encoder that handles datetime objects."""
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super().default(obj)

event = {"name": "Launch", "timestamp": datetime.now()}
print(json.dumps(event, cls=DateTimeEncoder))
```

---

## 5.4 Exception Handling

### Conceptual Foundation

Exceptions are Python's mechanism for signalling that something unexpected happened. The `try/except` block lets you handle those situations gracefully rather than crashing.

```
try:
    ← normal execution path
except SomeError:
    ← error handling path
else:
    ← runs ONLY if no exception was raised
finally:
    ← ALWAYS runs (cleanup)
```

```python
def safe_divide(a: float, b: float) -> float | None:
    """Divide a by b with comprehensive error handling."""
    try:
        result = a / b
    except ZeroDivisionError:
        print("Error: Division by zero.")
        return None
    except TypeError as e:
        print(f"Error: Invalid types — {e}")
        return None
    else:
        print(f"Success: {a} / {b} = {result}")
        return result
    finally:
        print("Division attempt complete.")   # always runs

safe_divide(10, 2)    # Success, then "complete"
safe_divide(10, 0)    # ZeroDivision error, then "complete"
safe_divide("a", 2)   # TypeError, then "complete"
```

### Exception Hierarchy

```
BaseException
 ├── SystemExit
 ├── KeyboardInterrupt
 └── Exception
      ├── ValueError
      ├── TypeError
      ├── KeyError
      ├── IndexError
      ├── AttributeError
      ├── FileNotFoundError (→ OSError → IOError)
      ├── PermissionError (→ OSError)
      ├── RuntimeError
      └── StopIteration
```

```python
# Catch multiple exception types
try:
    value = int(input("Enter a number: "))
    result = 100 / value
except (ValueError, ZeroDivisionError) as e:
    print(f"Invalid input: {e}")

# Catch all exceptions (use sparingly — only at top level)
try:
    risky_operation()
except Exception as e:
    log.error(f"Unexpected error: {e}", exc_info=True)
    raise   # re-raise after logging — don't swallow exceptions!

# Never do this — silences ALL exceptions including bugs
try:
    something()
except:         # bare except catches even SystemExit, KeyboardInterrupt
    pass        # BUG: errors vanish silently
```

### Custom Exceptions

```python
class AppError(Exception):
    """Base exception for all application errors."""

class ValidationError(AppError):
    """Raised when input data fails validation."""
    def __init__(self, field: str, message: str) -> None:
        self.field = field
        self.message = message
        super().__init__(f"Validation error on '{field}': {message}")

class DatabaseError(AppError):
    """Raised when a database operation fails."""
    def __init__(self, operation: str, detail: str) -> None:
        self.operation = operation
        super().__init__(f"Database {operation} failed: {detail}")

class NotFoundError(AppError):
    """Raised when a requested resource does not exist."""
    def __init__(self, resource: str, identifier) -> None:
        super().__init__(f"{resource} with id={identifier!r} not found")


# Usage
def get_user(user_id: int) -> dict:
    if not isinstance(user_id, int) or user_id <= 0:
        raise ValidationError("user_id", "Must be a positive integer")

    users = {1: {"name": "Alice"}, 2: {"name": "Bob"}}
    if user_id not in users:
        raise NotFoundError("User", user_id)

    return users[user_id]

try:
    user = get_user(99)
except NotFoundError as e:
    print(e)          # User with id=99 not found
except ValidationError as e:
    print(f"Bad input: {e.field} — {e.message}")
```

### Exception Chaining

```python
def parse_config(path: str) -> dict:
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError as e:
        raise RuntimeError(f"Config file not found: {path}") from e
    except json.JSONDecodeError as e:
        raise ValueError(f"Invalid JSON in config: {path}") from e

# The original exception is preserved as __cause__
```

---

## 5.5 Custom Context Managers

```python
import contextlib
import time

# Method 1: Class with __enter__ and __exit__
class Timer:
    """Context manager that measures elapsed time."""

    def __enter__(self):
        self.start = time.perf_counter()
        return self              # value assigned to 'as' variable

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.elapsed = time.perf_counter() - self.start
        print(f"Elapsed: {self.elapsed:.4f}s")
        return False             # False = don't suppress exceptions

with Timer() as t:
    total = sum(range(1_000_000))
print(f"Result: {total}, Time: {t.elapsed:.4f}s")

# Method 2: @contextlib.contextmanager (simpler)
@contextlib.contextmanager
def managed_temp_file(suffix: str = ".tmp"):
    """Create a temp file, yield its path, delete it afterward."""
    import tempfile, os
    fd, path = tempfile.mkstemp(suffix=suffix)
    try:
        os.close(fd)
        yield Path(path)
    finally:
        Path(path).unlink(missing_ok=True)
        print(f"Cleaned up {path}")

with managed_temp_file(".txt") as tmp:
    tmp.write_text("temporary data")
    print(f"Working with {tmp}")
# File deleted after block
```

---

## Best Practices

1. **Always use `with` for file operations** — guarantees proper resource cleanup.
2. **Use `pathlib.Path` over `os.path`** — more readable and cross-platform.
3. **Catch specific exceptions** — never use bare `except:`.
4. **Create custom exception hierarchies** — gives callers fine-grained control.
5. **Use exception chaining (`raise X from Y`)** — preserves the original cause.
6. **Don't swallow exceptions** — at minimum, log them and re-raise.
7. **Use `else` in try/except** — run success code only when no exception occurred.
8. **Use `finally` for cleanup** — not for error handling logic.
9. **Always specify encoding** — `open(..., encoding="utf-8")` to avoid platform issues.

---

## Exercises

### Exercise 5.1 — Log File Analyser (Intermediate)
Write a function that reads a log file and returns counts of each log level (INFO, WARNING, ERROR).

**Solution:**
```python
from collections import Counter
from pathlib import Path

def analyse_log(filepath: str | Path) -> dict[str, int]:
    """
    Parse a log file and count occurrences of each log level.

    Expected log format: "2024-01-15 10:30:00 - INFO - Message"
    """
    levels = Counter()
    filepath = Path(filepath)

    try:
        with open(filepath, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                parts = line.split(" - ")
                if len(parts) >= 2:
                    level = parts[1].strip()
                    levels[level] += 1
    except FileNotFoundError:
        raise FileNotFoundError(f"Log file not found: {filepath}")
    except PermissionError:
        raise PermissionError(f"Cannot read log file: {filepath}")

    return dict(levels)
```

---

### Exercise 5.2 — Safe JSON Config Loader (Intermediate)
Write `load_config(path, defaults)` that loads a JSON config file, merges it with defaults, and validates required keys. Raise descriptive custom exceptions on failure.

**Solution:**
```python
import json
from pathlib import Path

class ConfigError(Exception):
    """Raised when configuration loading or validation fails."""

def load_config(path: str | Path, defaults: dict | None = None,
                required_keys: list[str] | None = None) -> dict:
    """
    Load and validate a JSON config file.

    Args:
        path: Path to the JSON config file.
        defaults: Default values merged before the file values.
        required_keys: Keys that must be present in the final config.

    Returns:
        Merged configuration dictionary.

    Raises:
        ConfigError: If file is missing, invalid JSON, or keys are absent.
    """
    path = Path(path)
    config = dict(defaults or {})

    try:
        with open(path, encoding="utf-8") as f:
            file_config = json.load(f)
    except FileNotFoundError:
        raise ConfigError(f"Config file not found: {path}")
    except json.JSONDecodeError as e:
        raise ConfigError(f"Invalid JSON in {path}: {e}") from e

    config.update(file_config)

    if required_keys:
        missing = [k for k in required_keys if k not in config]
        if missing:
            raise ConfigError(f"Missing required config keys: {missing}")

    return config
```

---

### Exercise 5.3 — CSV Report Generator (Advanced)
Read a CSV of sales data (date, product, quantity, price), calculate totals per product, and write a summary report CSV.

**Solution:**
```python
import csv
from pathlib import Path
from collections import defaultdict

def generate_sales_report(input_path: str | Path, output_path: str | Path) -> dict:
    """
    Read sales CSV and write a summary report grouped by product.

    Input columns: date, product, quantity, price
    Output columns: product, units_sold, total_revenue
    """
    totals: dict[str, dict] = defaultdict(lambda: {"units_sold": 0, "total_revenue": 0.0})
    input_path = Path(input_path)

    with open(input_path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            product = row["product"]
            quantity = int(row["quantity"])
            price = float(row["price"])
            totals[product]["units_sold"] += quantity
            totals[product]["total_revenue"] += quantity * price

    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["product", "units_sold", "total_revenue"])
        writer.writeheader()
        for product, data in sorted(totals.items()):
            writer.writerow({
                "product": product,
                "units_sold": data["units_sold"],
                "total_revenue": round(data["total_revenue"], 2),
            })

    return dict(totals)
```

---

## Mini-Project — Personal Expense Tracker (CLI)

```python
import json
import csv
from pathlib import Path
from datetime import datetime
from collections import defaultdict

DATA_FILE = Path("expenses.json")

class ExpenseTracker:
    """File-backed expense tracker with JSON persistence."""

    def __init__(self, data_file: Path = DATA_FILE) -> None:
        self._file = data_file
        self._expenses: list[dict] = self._load()

    def _load(self) -> list[dict]:
        if not self._file.exists():
            return []
        try:
            return json.loads(self._file.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            print(f"Warning: Corrupt data file, starting fresh.")
            return []

    def _save(self) -> None:
        self._file.write_text(
            json.dumps(self._expenses, indent=2),
            encoding="utf-8"
        )

    def add(self, amount: float, category: str, description: str = "") -> None:
        """Record a new expense."""
        if amount <= 0:
            raise ValueError("Amount must be positive")
        self._expenses.append({
            "date": datetime.now().isoformat(timespec="seconds"),
            "amount": round(amount, 2),
            "category": category.strip().lower(),
            "description": description.strip(),
        })
        self._save()

    def summary(self) -> dict[str, float]:
        """Return total spending per category."""
        totals: dict[str, float] = defaultdict(float)
        for exp in self._expenses:
            totals[exp["category"]] += exp["amount"]
        return dict(totals)

    def export_csv(self, path: str | Path) -> None:
        """Export all expenses to a CSV file."""
        with open(path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=["date", "amount", "category", "description"])
            writer.writeheader()
            writer.writerows(self._expenses)
        print(f"Exported {len(self._expenses)} expenses to {path}")

    def report(self) -> None:
        """Print formatted spending report."""
        if not self._expenses:
            print("No expenses recorded.")
            return
        total = sum(e["amount"] for e in self._expenses)
        print(f"\n{'EXPENSE REPORT':=^40}")
        for cat, amount in sorted(self.summary().items(), key=lambda x: -x[1]):
            bar = "█" * int(amount / total * 20)
            print(f"{cat:<15} ${amount:>8.2f} {bar}")
        print(f"{'TOTAL':=<15} ${total:>8.2f}")


# --- Demo ---
tracker = ExpenseTracker(Path("demo_expenses.json"))
tracker.add(12.50, "food", "Lunch")
tracker.add(9.99, "transport", "Bus pass")
tracker.add(45.00, "food", "Groceries")
tracker.add(14.99, "entertainment", "Netflix")
tracker.add(8.50, "food", "Coffee and snack")
tracker.report()
tracker.export_csv("expenses_export.csv")
```

---

## Module Summary

| Concept | Key Takeaway |
|---------|-------------|
| `with open(...)` | Always use context managers for file I/O |
| `pathlib.Path` | Modern, cross-platform path handling |
| `encoding="utf-8"` | Always specify encoding explicitly |
| `try/except/else/finally` | `else` = success only; `finally` = always |
| Custom exceptions | Create hierarchies from `Exception`; add context |
| Exception chaining | `raise X from Y` preserves original cause |
| Bare `except:` | Never use — catches `SystemExit` and `KeyboardInterrupt` |
| `@contextmanager` | Simplest way to write a custom context manager |

---

## Quiz

1. Why must you always use `with open(...)` instead of bare `open()`?
2. What is the difference between `f.read()`, `f.readline()`, and `f.readlines()`?
3. When does the `else` block of a try/except execute?
4. What does `raise ValueError("msg") from original_error` do?
5. What is the difference between `except Exception:` and bare `except:`?
6. How do you create a directory tree with `pathlib`, creating parents if needed?
7. What is name-mangling in Python exceptions? Give an example.
8. What does `Path.glob("**/*.py")` match?
9. How do you make a custom context manager using a generator function?
10. Why should you never use `except: pass`?

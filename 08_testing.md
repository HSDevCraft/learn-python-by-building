# Module 08 — Testing with pytest

> **Level:** Intermediate | **Estimated Time:** 6 hours | **Prerequisites:** Modules 01–07

---

## Learning Objectives

By the end of this module you will be able to:
- Write and run unit tests with `pytest`
- Use fixtures, parametrize, and markers effectively
- Apply Test-Driven Development (TDD) workflow
- Mock external dependencies with `unittest.mock`
- Measure and improve test coverage
- Organise a professional test suite
- Write integration tests alongside unit tests

---

## 8.1 Why Test?

### Conceptual Foundation

Tests are **executable documentation** that verify your code does what you claim. They provide:
- **Confidence** to refactor without breaking things
- **Early bug detection** — minutes to find vs hours to debug in production
- **Design pressure** — hard-to-test code is often poorly designed
- **Living documentation** — tests show how code is meant to be used

**Test pyramid:**
```
        /\
       /E2E\        Few — slow, expensive, test full system
      /------\
     /  Integ  \    Some — test component interactions
    /------------\
   /  Unit tests  \ Many — fast, isolated, test one thing
  /________________\
```

---

## 8.2 Getting Started with pytest

```bash
pip install pytest pytest-cov
```

### Your First Test

```python
# src/calculator.py
def add(a: float, b: float) -> float:
    """Return the sum of a and b."""
    return a + b

def divide(a: float, b: float) -> float:
    """Return a divided by b. Raises ZeroDivisionError if b is 0."""
    if b == 0:
        raise ZeroDivisionError("Cannot divide by zero")
    return a / b
```

```python
# tests/test_calculator.py
import pytest
from src.calculator import add, divide

# Naming convention: test_ prefix on both file and function names

def test_add_positive_numbers():
    """Two positive numbers sum correctly."""
    assert add(2, 3) == 5

def test_add_negative_numbers():
    assert add(-1, -1) == -2

def test_add_floats():
    import math
    assert math.isclose(add(0.1, 0.2), 0.3)

def test_divide_normal():
    assert divide(10, 2) == 5.0

def test_divide_by_zero_raises():
    """divide() must raise ZeroDivisionError when b is 0."""
    with pytest.raises(ZeroDivisionError, match="Cannot divide by zero"):
        divide(10, 0)

def test_divide_returns_float():
    result = divide(7, 2)
    assert isinstance(result, float)
    assert result == 3.5
```

```bash
# Run tests
pytest

# Verbose output
pytest -v

# Run a specific file
pytest tests/test_calculator.py

# Run a specific test
pytest tests/test_calculator.py::test_add_positive_numbers

# Show stdout output
pytest -s

# Stop on first failure
pytest -x
```

---

## 8.3 Fixtures — Reusable Test Setup

Fixtures are functions that provide test prerequisites. pytest injects them automatically by name.

```python
# tests/conftest.py — fixtures available to all tests in directory
import pytest
from pathlib import Path
import tempfile

@pytest.fixture
def sample_numbers() -> list[int]:
    """Provide a standard list of test numbers."""
    return [1, 2, 3, 4, 5, 10, -1, 0]

@pytest.fixture
def temp_dir():
    """Provide a temporary directory that's cleaned up after the test."""
    with tempfile.TemporaryDirectory() as tmpdir:
        yield Path(tmpdir)   # yield → setup / teardown pattern

@pytest.fixture
def empty_db():
    """Set up and tear down an in-memory database."""
    from src.database import Database
    db = Database(":memory:")
    db.migrate()        # setup
    yield db            # test runs here
    db.close()          # teardown (always runs)

@pytest.fixture(scope="module")
def expensive_resource():
    """Created once per module — expensive setup."""
    resource = create_expensive_connection()
    yield resource
    resource.cleanup()
```

**Fixture scopes:**
- `scope="function"` — default, fresh fixture per test
- `scope="class"` — shared within a test class
- `scope="module"` — shared within a test file
- `scope="session"` — shared across the entire test run

```python
# tests/test_with_fixtures.py
def test_sum_with_fixture(sample_numbers):
    """Fixture is injected by name — no import needed."""
    assert sum(sample_numbers) == 24

def test_file_creation(temp_dir):
    output_file = temp_dir / "result.txt"
    output_file.write_text("test content")
    assert output_file.exists()
    assert output_file.read_text() == "test content"
```

### Fixture Factories

```python
@pytest.fixture
def make_user():
    """Factory fixture — returns a callable that creates users."""
    created = []

    def _make(name: str = "Alice", role: str = "user") -> dict:
        user = {"id": len(created) + 1, "name": name, "role": role}
        created.append(user)
        return user

    yield _make
    # teardown: cleanup created users
    for user in created:
        print(f"Cleaning up user {user['id']}")

def test_admin_can_delete(make_user):
    admin = make_user("Bob", role="admin")
    regular = make_user("Alice")
    assert admin["role"] == "admin"
    assert regular["role"] == "user"
```

---

## 8.4 Parametrize — Data-Driven Tests

```python
import pytest
from src.calculator import add, divide

@pytest.mark.parametrize("a, b, expected", [
    (1, 2, 3),
    (-1, -1, -2),
    (0, 0, 0),
    (1.5, 2.5, 4.0),
    (100, -100, 0),
])
def test_add_parametrized(a, b, expected):
    """Test add() with multiple input/output combinations."""
    assert add(a, b) == expected

# Parametrize with IDs for readable output
@pytest.mark.parametrize("value, expected", [
    (0, "zero"),
    (1, "positive"),
    (-1, "negative"),
    (999, "positive"),
], ids=["zero", "one", "minus_one", "large"])
def test_classify_number(value, expected):
    from src.utils import classify_number
    assert classify_number(value) == expected

# Parametrize exceptions
@pytest.mark.parametrize("a, b, error_type", [
    (10, 0, ZeroDivisionError),
    ("a", 1, TypeError),
])
def test_divide_errors(a, b, error_type):
    with pytest.raises(error_type):
        divide(a, b)
```

---

## 8.5 Markers — Categorising Tests

```python
# pytest.ini or pyproject.toml:
# [tool.pytest.ini_options]
# markers = [
#     "slow: marks tests as slow (deselect with '-m \"not slow\"')",
#     "integration: marks tests as integration tests",
#     "unit: fast unit tests",
# ]

import pytest

@pytest.mark.slow
def test_large_dataset_processing():
    """Slow test — takes several seconds."""
    ...

@pytest.mark.integration
def test_database_round_trip():
    """Requires a real database connection."""
    ...

@pytest.mark.skip(reason="Feature not implemented yet")
def test_future_feature():
    ...

@pytest.mark.skipif(
    condition=sys.platform == "win32",
    reason="File permissions test not applicable on Windows"
)
def test_unix_permissions():
    ...

@pytest.mark.xfail(reason="Known bug #123 — fix in progress")
def test_known_bug():
    ...
```

```bash
# Run only fast unit tests
pytest -m "not slow and not integration"

# Run only integration tests
pytest -m integration

# Run only slow tests
pytest -m slow
```

---

## 8.6 Mocking — Isolating External Dependencies

Mocking replaces real dependencies (database, API, filesystem) with controlled fake versions during tests.

```python
from unittest.mock import Mock, MagicMock, patch, call
import pytest

# --- Mock an external API call ---

# src/weather_service.py
import requests

def get_temperature(city: str) -> float:
    """Fetch current temperature from weather API."""
    response = requests.get(f"https://api.weather.com/v1/{city}")
    response.raise_for_status()
    return response.json()["temperature"]

# tests/test_weather_service.py
from unittest.mock import patch
from src.weather_service import get_temperature

def test_get_temperature_success():
    """Test the happy path without hitting the real API."""
    mock_response = Mock()
    mock_response.json.return_value = {"temperature": 22.5}
    mock_response.raise_for_status.return_value = None

    with patch("src.weather_service.requests.get", return_value=mock_response) as mock_get:
        temp = get_temperature("London")

    assert temp == 22.5
    mock_get.assert_called_once_with("https://api.weather.com/v1/London")

def test_get_temperature_api_failure():
    """Test that API errors propagate correctly."""
    import requests as req
    mock_response = Mock()
    mock_response.raise_for_status.side_effect = req.HTTPError("404 Not Found")

    with patch("src.weather_service.requests.get", return_value=mock_response):
        with pytest.raises(req.HTTPError):
            get_temperature("UnknownCity")

# Mock as a decorator
@patch("src.weather_service.requests.get")
def test_with_decorator(mock_get):
    mock_get.return_value.json.return_value = {"temperature": 18.0}
    mock_get.return_value.raise_for_status.return_value = None
    assert get_temperature("Paris") == 18.0
```

### `MagicMock` vs `Mock`

```python
from unittest.mock import MagicMock

# MagicMock auto-implements dunder methods
m = MagicMock()
m.__len__.return_value = 5
print(len(m))       # 5
print(m[0])         # another MagicMock (auto-created)
print(bool(m))      # True

# Track calls
m = Mock()
m(1, 2)
m(3, key="value")
print(m.call_count)        # 2
print(m.call_args_list)    # [call(1, 2), call(3, key='value')]
m.assert_called_with(3, key="value")
```

### `pytest-mock` — Simpler API

```bash
pip install pytest-mock
```

```python
def test_send_email(mocker):
    """Using pytest-mock's 'mocker' fixture — cleaner than patch context manager."""
    mock_smtp = mocker.patch("src.email_service.smtplib.SMTP")
    mock_smtp.return_value.__enter__.return_value.sendmail.return_value = {}

    from src.email_service import send_email
    send_email("alice@ex.com", "Hello!")

    mock_smtp.assert_called_once()
```

---

## 8.7 Test-Driven Development (TDD)

TDD cycle: **Red → Green → Refactor**

1. **Red**: Write a failing test (it describes desired behaviour)
2. **Green**: Write the minimum code to make it pass
3. **Refactor**: Clean up code while keeping tests green

```python
# STEP 1: Red — write the failing test first
def test_stack_push_and_pop():
    s = Stack()
    s.push(42)
    assert s.pop() == 42

def test_stack_pop_empty_raises():
    s = Stack()
    with pytest.raises(IndexError, match="empty stack"):
        s.pop()

def test_stack_is_fifo():  # LIFO, actually — fix the test name
    s = Stack()
    s.push(1); s.push(2); s.push(3)
    assert s.pop() == 3
    assert s.pop() == 2

# STEP 2: Green — minimal implementation
class Stack:
    def __init__(self):
        self._items = []
    def push(self, item):
        self._items.append(item)
    def pop(self):
        if not self._items:
            raise IndexError("pop from empty stack")
        return self._items.pop()

# STEP 3: Refactor — add type hints, docstrings, edge cases
```

---

## 8.8 Code Coverage

```bash
# Run with coverage
pytest --cov=src --cov-report=term-missing

# HTML report (open htmlcov/index.html)
pytest --cov=src --cov-report=html

# Fail if coverage drops below threshold
pytest --cov=src --cov-fail-under=80
```

**Coverage output:**
```
----------- coverage: platform linux, python 3.11 -----------
Name                    Stmts   Miss  Cover   Missing
-----------------------------------------------------
src/calculator.py          10      0   100%
src/weather_service.py     15      3    80%   25-27
-----------------------------------------------------
TOTAL                      25      3    88%
```

> **Aim for 80–90% coverage** on application code. 100% can encourage "coverage gaming" — tests that exercise lines without asserting anything useful.

---

## 8.9 Professional Test Organisation

```
tests/
├── conftest.py              # shared fixtures (session-scoped)
├── unit/
│   ├── conftest.py          # unit-test-specific fixtures
│   ├── test_calculator.py
│   ├── test_user_service.py
│   └── test_validators.py
├── integration/
│   ├── conftest.py          # integration fixtures (real DB, etc.)
│   └── test_api_endpoints.py
└── e2e/
    └── test_user_workflow.py
```

---

## Best Practices

1. **Name tests descriptively** — `test_divide_raises_on_zero` not `test_1`.
2. **One assertion concept per test** — a test that checks 10 things is hard to debug.
3. **Arrange / Act / Assert (AAA) pattern** — structure every test the same way.
4. **Never test implementation details** — test observable behaviour.
5. **Use `conftest.py` for shared fixtures** — not test helpers defined in individual files.
6. **Mock at the boundary** — mock the thing you don't own (external API, OS), not internal code.
7. **Keep tests fast** — slow test suites get skipped. Unit tests should run in milliseconds.
8. **Never delete a test** — if a bug was found, a regression test should prevent it forever.

```python
# AAA pattern example
def test_user_registration():
    # Arrange
    service = UserService(FakeEmailSender())
    user_data = {"name": "Alice", "email": "alice@ex.com"}

    # Act
    user = service.register(user_data)

    # Assert
    assert user.id is not None
    assert user.name == "Alice"
    assert service.email_sender.sent_count == 1
```

---

## Exercises

### Exercise 8.1 — TDD: String Calculator
Using TDD, implement `string_add(numbers: str) -> int` that:
- Returns 0 for empty string
- Handles single number: `"5"` → 5
- Handles two numbers: `"1,2"` → 3
- Handles any number of comma-separated values
- Handles newline as separator: `"1\n2,3"` → 6
- Raises `ValueError` if any number is negative (list all negatives in message)

**Solution:**
```python
# Write tests FIRST
import pytest

def test_empty_string_returns_zero():
    assert string_add("") == 0

def test_single_number():
    assert string_add("5") == 5

def test_two_numbers():
    assert string_add("1,2") == 3

def test_multiple_numbers():
    assert string_add("1,2,3,4,5") == 15

def test_newline_separator():
    assert string_add("1\n2,3") == 6

def test_negatives_raise():
    with pytest.raises(ValueError, match="-1, -3"):
        string_add("1,-1,2,-3")

# Then implement
def string_add(numbers: str) -> int:
    """Parse and sum a delimited string of numbers."""
    if not numbers:
        return 0
    parts = numbers.replace("\n", ",").split(",")
    values = [int(p) for p in parts if p]
    negatives = [v for v in values if v < 0]
    if negatives:
        raise ValueError(f"Negatives not allowed: {', '.join(str(n) for n in negatives)}")
    return sum(values)
```

---

## Mini-Project — Test Suite for a URL Shortener

```python
# src/url_shortener.py
import string, random, hashlib
from urllib.parse import urlparse

class URLShortener:
    """In-memory URL shortener service."""

    def __init__(self) -> None:
        self._store: dict[str, str] = {}   # short_code → original_url

    def shorten(self, url: str) -> str:
        """Create and return a short code for the given URL."""
        if not self._is_valid_url(url):
            raise ValueError(f"Invalid URL: {url}")
        code = self._generate_code(url)
        self._store[code] = url
        return code

    def resolve(self, code: str) -> str:
        """Return the original URL for a short code."""
        if code not in self._store:
            raise KeyError(f"Short code not found: {code}")
        return self._store[code]

    def _generate_code(self, url: str) -> str:
        return hashlib.md5(url.encode()).hexdigest()[:6]

    @staticmethod
    def _is_valid_url(url: str) -> bool:
        parsed = urlparse(url)
        return parsed.scheme in ("http", "https") and bool(parsed.netloc)


# tests/test_url_shortener.py
import pytest
from src.url_shortener import URLShortener

@pytest.fixture
def shortener() -> URLShortener:
    return URLShortener()

def test_shorten_valid_url(shortener):
    code = shortener.shorten("https://example.com")
    assert isinstance(code, str)
    assert len(code) == 6

def test_resolve_returns_original(shortener):
    url = "https://www.python.org"
    code = shortener.shorten(url)
    assert shortener.resolve(code) == url

def test_same_url_same_code(shortener):
    url = "https://example.com"
    assert shortener.shorten(url) == shortener.shorten(url)

def test_invalid_url_raises(shortener):
    with pytest.raises(ValueError, match="Invalid URL"):
        shortener.shorten("not-a-url")

def test_resolve_unknown_code_raises(shortener):
    with pytest.raises(KeyError, match="abc123"):
        shortener.resolve("abc123")

@pytest.mark.parametrize("invalid_url", [
    "ftp://files.example.com",
    "just-a-string",
    "",
    "http://",
])
def test_invalid_urls(shortener, invalid_url):
    with pytest.raises(ValueError):
        shortener.shorten(invalid_url)
```

---

## Module Summary

| Concept | Key Takeaway |
|---------|-------------|
| `pytest` | Run any function starting with `test_`; no boilerplate |
| Fixtures | Reusable setup/teardown; scoped by function/class/module/session |
| `@pytest.mark.parametrize` | Run same test with multiple inputs — DRY tests |
| `unittest.mock.patch` | Replace a real dependency with a fake during a test |
| TDD | Red → Green → Refactor; design through tests |
| Coverage | `--cov` flag; aim for 80–90%; 100% can be counterproductive |
| AAA pattern | Arrange / Act / Assert — standard test structure |

---

## Quiz

1. What is the difference between a unit test and an integration test?
2. What is a pytest fixture and how is it injected into a test?
3. What does `yield` in a fixture do?
4. What is the `scope` parameter on a fixture and what are the options?
5. How does `@pytest.mark.parametrize` help reduce code duplication?
6. What does `patch("module.function")` do exactly?
7. What is the difference between `Mock` and `MagicMock`?
8. What is the TDD cycle and why is the "Red" step important?
9. What does `pytest --cov-fail-under=80` do?
10. Why should you mock external dependencies rather than call them in tests?

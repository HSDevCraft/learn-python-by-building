# Module 07 — Virtual Environments and Dependency Management

> **Level:** Intermediate | **Estimated Time:** 3 hours | **Prerequisites:** Module 06

---

## Learning Objectives

By the end of this module you will be able to:
- Explain why virtual environments are essential
- Create, activate, and manage `venv` environments
- Structure projects using `pyproject.toml`
- Use Poetry for dependency management
- Understand semantic versioning
- Publish a simple package to PyPI

---

## 7.1 Why Virtual Environments?

### Conceptual Foundation

By default, `pip install` places packages in the **system Python** installation — shared across every project on your machine. This causes:

- **Version conflicts:** Project A needs `requests==2.28`, Project B needs `requests==2.31`
- **Reproducibility failures:** "It worked on my machine" bugs
- **Deployment hell:** Production gets wrong package versions

A **virtual environment** is an isolated Python installation for a single project. Each env has its own:
- Python interpreter (copy or symlink)
- `site-packages/` directory (installed packages)
- `pip` executable

```
System Python          Project A venv       Project B venv
───────────────        ─────────────────    ─────────────────
Python 3.11            Python 3.11          Python 3.11
requests 2.31          requests 2.28        requests 2.31
numpy 1.24             numpy 1.26           (no numpy)
```

---

## 7.2 `venv` — Built-in Virtual Environments

```bash
# Create a virtual environment
python -m venv .venv

# Activate (macOS / Linux)
source .venv/bin/activate

# Activate (Windows PowerShell)
.venv\Scripts\Activate.ps1

# Activate (Windows CMD)
.venv\Scripts\activate.bat

# Verify you're in the venv
which python          # should point to .venv/bin/python
python --version
pip list              # only shows packages installed in this env

# Install packages
pip install fastapi uvicorn pydantic

# Save dependencies
pip freeze > requirements.txt

# Install from saved requirements (on another machine)
pip install -r requirements.txt

# Deactivate
deactivate

# Delete env (just delete the folder)
rm -rf .venv
```

### Project Layout

```
my_project/
├── .venv/                  # virtual environment (gitignored)
├── src/
│   └── my_app/
│       ├── __init__.py
│       └── main.py
├── tests/
│   └── test_main.py
├── .gitignore
├── requirements.txt        # pinned production deps
├── requirements-dev.txt    # pinned dev deps (includes requirements.txt)
└── README.md
```

**.gitignore** (always ignore `.venv`):
```
.venv/
__pycache__/
*.pyc
*.egg-info/
dist/
build/
.pytest_cache/
.mypy_cache/
.ruff_cache/
```

---

## 7.3 `pyproject.toml` — Modern Project Configuration

`pyproject.toml` (PEP 517/518) is the modern standard for Python project metadata, replacing `setup.py` and `setup.cfg`.

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "my-awesome-tool"
version = "0.1.0"
description = "A brief description of what this does"
readme = "README.md"
requires-python = ">=3.10"
license = {text = "MIT"}
authors = [
    {name = "Alice Smith", email = "alice@example.com"},
]
keywords = ["cli", "automation", "tool"]
classifiers = [
    "Development Status :: 3 - Alpha",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "License :: OSI Approved :: MIT License",
]

# Runtime dependencies (installed with your package)
dependencies = [
    "requests>=2.28,<3.0",
    "pydantic>=2.0",
    "rich>=13.0",
]

# Optional extras
[project.optional-dependencies]
dev = [
    "pytest>=7.4",
    "pytest-cov>=4.1",
    "black>=23.0",
    "ruff>=0.1",
    "mypy>=1.7",
]
docs = [
    "mkdocs>=1.5",
    "mkdocs-material>=9.0",
]

# Command-line entry points
[project.scripts]
my-tool = "my_app.cli:main"

# Tool configuration (replaces individual config files)
[tool.black]
line-length = 88
target-version = ["py310", "py311"]

[tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "UP"]
ignore = ["E501"]

[tool.mypy]
python_version = "3.11"
strict = true
ignore_missing_imports = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=src --cov-report=term-missing -v"

[tool.coverage.run]
source = ["src"]
omit = ["tests/*"]
```

---

## 7.4 Poetry — Dependency Management

Poetry is the most popular tool for managing Python project dependencies and packaging.

```bash
# Install Poetry
curl -sSL https://install.python-poetry.org | python3 -
# Or on Windows: (Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | python -

# Create a new project
poetry new my-project
cd my-project

# Or initialise in an existing directory
poetry init

# Add dependencies
poetry add requests
poetry add pydantic@^2.0
poetry add --group dev pytest black ruff mypy

# Install all dependencies
poetry install

# Install with dev extras
poetry install --with dev

# Run commands in the venv
poetry run python script.py
poetry run pytest
poetry run black .

# Activate the venv shell
poetry shell

# Update dependencies
poetry update
poetry update requests     # update one package

# Show dependency tree
poetry show --tree

# Build distributable package
poetry build           # creates dist/*.whl and dist/*.tar.gz

# Publish to PyPI
poetry publish

# Export to requirements.txt (for Docker, CI/CD)
poetry export -f requirements.txt --output requirements.txt --without-hashes
```

### `poetry.lock`

Poetry generates a `poetry.lock` file that **pins exact versions** of every dependency (including transitive ones). Always commit this file to version control.

```
requests 2.31.0
  - certifi >=2017.4.17
  - charset-normalizer >=2,<4
  - idna >=2.5,<4
  - urllib3 >=1.21.1,<3
certifi 2023.11.17
charset-normalizer 3.3.2
...
```

---

## 7.5 Semantic Versioning

Packages use **semver**: `MAJOR.MINOR.PATCH`

| Change | Version bump | Example |
|--------|-------------|---------|
| Breaking API change | MAJOR | `1.x.x` → `2.0.0` |
| New backward-compatible feature | MINOR | `1.2.x` → `1.3.0` |
| Bug fix | PATCH | `1.2.3` → `1.2.4` |

### Version Specifiers in Requirements

```
requests==2.31.0       # exact version — use only for lockfiles
requests>=2.28         # minimum version
requests>=2.28,<3.0    # compatible range (no breaking changes)
requests~=2.28         # ~= means >=2.28, <3.0 (compatible release)
requests^2.28          # Poetry: >=2.28.0, <3.0.0 (caret constraint)
```

---

## 7.6 Building and Publishing a Package

### Minimal Package Structure

```
my_calculator/
├── src/
│   └── calculator/
│       ├── __init__.py          # public API
│       └── operations.py
├── tests/
│   └── test_operations.py
├── pyproject.toml
├── README.md
└── LICENSE
```

```python
# src/calculator/__init__.py
"""Simple calculator package."""

from .operations import add, subtract, multiply, divide

__version__ = "0.1.0"
__all__ = ["add", "subtract", "multiply", "divide"]

# src/calculator/operations.py
def add(a: float, b: float) -> float:
    """Return the sum of a and b."""
    return a + b

def subtract(a: float, b: float) -> float:
    """Return a minus b."""
    return a - b

def multiply(a: float, b: float) -> float:
    """Return the product of a and b."""
    return a * b

def divide(a: float, b: float) -> float:
    """Return a divided by b."""
    if b == 0:
        raise ZeroDivisionError("Cannot divide by zero")
    return a / b
```

```bash
# Build the package
pip install build
python -m build
# Creates dist/my_calculator-0.1.0.tar.gz and dist/my_calculator-0.1.0-py3-none-any.whl

# Install locally to test
pip install dist/my_calculator-0.1.0-py3-none-any.whl

# Upload to TestPyPI first
pip install twine
twine upload --repository testpypi dist/*

# Upload to PyPI (production)
twine upload dist/*
```

---

## 7.7 `pipx` — Installing CLI Tools

`pipx` installs Python CLI tools in isolated environments so they don't pollute your system.

```bash
pip install pipx
pipx install black
pipx install ruff
pipx install poetry
pipx install httpie

# Use the tools globally
black my_script.py
ruff check .
```

---

## Best Practices

1. **Every project gets its own `.venv`** — no exceptions.
2. **Add `.venv/` to `.gitignore`** — never commit the environment.
3. **Commit `poetry.lock` or `requirements.txt`** — ensures reproducible builds.
4. **Use `pyproject.toml`** — the single source of truth for project config.
5. **Pin development deps separately** from production deps.
6. **Use semantic versioning** for your own packages.
7. **Test on TestPyPI first** before publishing to the real PyPI.
8. **Use `src/` layout** — prevents accidentally importing from source instead of installed package.

---

## Module Summary

| Tool | Purpose |
|------|---------|
| `venv` | Built-in virtual environment creation |
| `pip` | Package installer |
| `pyproject.toml` | Project metadata + tool config (PEP 517/518) |
| `poetry` | Dependency management + packaging |
| `poetry.lock` | Exact dependency lockfile |
| `pipx` | Install CLI tools in isolated envs |
| `twine` | Upload packages to PyPI |

---

## Quiz

1. Why should every Python project have its own virtual environment?
2. What is the difference between `requirements.txt` and `poetry.lock`?
3. What does `~=2.28` mean as a version specifier?
4. Why is the `src/` layout preferred for packages?
5. What does `pip freeze` output, and when would you use it?
6. What is the difference between `poetry add requests` and `poetry add --group dev pytest`?
7. What files should always be committed to version control in a Poetry project?
8. What does `poetry export` do, and why is it useful for Docker?
9. What does `__all__` in `__init__.py` control?
10. What is semver, and how does it differ from a plain version number like "2024.1"?

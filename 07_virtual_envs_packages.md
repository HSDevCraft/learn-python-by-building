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

## The Big Picture — Dependency Management in Production

The dependency management story in Python:

```
── Complexity grows over time ────────────────────────────────────────────

Day 1:  pip install requests               Simple
Day 30: pip install requests pydantic fastapi uvicorn redis celery  Growing
Day 90: "It works on my machine but not CI"  ← the classic nightmare

The problem: Python has ONE global site-packages by default.
Every project can overwrite every other project's dependencies.

The solution stack:
  venv           → isolated per-project Python environment
  requirements.txt → reproducible dep list (simple projects)
  poetry.lock    → exact lockfile with ALL transitive deps
  pyproject.toml → single source of truth for project config
  pipx           → CLI tools in their own isolated envs
```

---

## 7.1 Why Virtual Environments?

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

The venv is just a directory (.venv/) with:
  .venv/bin/python   → symlink to system Python
  .venv/bin/pip      → pip for this env only
  .venv/lib/         → all packages installed here
  .venv/pyvenv.cfg   → metadata (python version, etc.)

Activating = prepending .venv/bin to PATH
Deactivating = removing it from PATH
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

## Interview Prep — Top Questions for Virtual Environments and Packages

**Q1: What happens when you run `python -m venv .venv` and then activate it?**
`python -m venv .venv` creates a directory with a Python interpreter symlink, a copy of `pip`, and an empty `site-packages`. Activating it prepends `.venv/bin` (or `.venv/Scripts` on Windows) to the `PATH`, so `python` and `pip` now resolve to the venv versions. All `pip install` commands install to the venv's `site-packages`, not the system Python.

**Q2: What is the difference between `requirements.txt` and `poetry.lock`?**
`requirements.txt` lists your direct dependencies with pinned versions. `poetry.lock` is a **complete lockfile** — it captures the exact resolved version of every package including all transitive dependencies (deps of deps). `poetry.lock` guarantees identical installs on every machine. Commit it to version control; never commit `.venv/`.

**Q3: Why is the `src/` layout recommended for Python packages?**
With a flat layout, `import mypackage` might resolve to the source directory instead of the installed package. This means tests can accidentally pass by importing uninstalled source. With `src/mypackage/`, the package is only importable after `pip install -e .`, ensuring you always test the installed version. It also prevents namespace collisions.

**Q4: What does `pip install -e .` do?**
Installs the package in **editable mode** — creates a link to your source directory instead of copying it. Changes to source files are immediately reflected without reinstalling. Essential for local development: you edit the code, run tests, and changes take effect instantly. Used with `pyproject.toml` or `setup.py` in the project root.

**Q5: What is semantic versioning (semver) and why does it matter?**
`MAJOR.MINOR.PATCH`: MAJOR = breaking change, MINOR = new backward-compatible feature, PATCH = bug fix. It matters because dependency resolvers use it: `>=2.1,<3.0` means "any 2.x that added the feature we need but hasn't broken our API". Violating semver (breaking API in a PATCH release) causes dependency hell for your users.

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

**Answers:**
1. Because Python has a single global `site-packages` by default. Without isolation, installing Package A v1 for one project can break another project that requires Package A v2. Each project needs its own locked set of dependencies.
2. `requirements.txt` lists the packages you explicitly want (with versions). `poetry.lock` captures the **complete resolved dependency graph** — every package and its exact version, including transitive dependencies of dependencies. `poetry.lock` guarantees identical installs across all environments.
3. `~=2.28` is the "compatible release" specifier: `>=2.28, <3.0`. It allows patch and minor updates but not a new major version (which could break APIs).
4. `src/` layout prevents accidentally running the uninstalled source code instead of the installed package. With `src/`, `import mypackage` only works after `pip install -e .`, ensuring you're always testing the installed version.
5. `pip freeze` outputs all installed packages with their pinned versions. Use it to capture a working environment as `requirements.txt`. Limitation: includes dev tools and transitive deps — more verbose than ideal for production.
6. `poetry add requests` adds to `[tool.poetry.dependencies]` (installed in production). `--group dev pytest` adds to `[tool.poetry.group.dev.dependencies]` (only for development, not shipped with the package).
7. Always commit: `pyproject.toml` (project metadata), `poetry.lock` (exact dependency lockfile). Never commit: `.venv/` (the environment itself, which is reconstructable).
8. `poetry export -f requirements.txt` converts `poetry.lock` to a standard `requirements.txt`. This is useful for Docker because it lets you do `pip install -r requirements.txt` without installing Poetry inside the container.
9. `__all__` controls what is exported when someone writes `from mypackage import *`. It also tells IDEs and tools what the public API is. Symbols not in `__all__` are considered private.
10. Semver encodes meaning in the version number: MAJOR.MINOR.PATCH. A bump in MAJOR signals breaking changes, MINOR signals new features, PATCH signals bug fixes. `2024.1` is calendar versioning — it tells you when it was released but nothing about compatibility.

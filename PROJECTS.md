# Projects and Capstone Challenges

> Hands-on projects that synthesise multiple modules into real-world applications.
> Each project includes: objective, requirements, starter structure, and evaluation criteria.

---

## Project Tiers

| Tier | Scope | Modules | Time |
|------|-------|---------|------|
| **Mini** | Single feature, ~100 LOC | 1–2 modules | 2–4h |
| **Intermediate** | Multi-feature app, ~300 LOC | 3–5 modules | 6–10h |
| **Capstone** | Production-quality system, ~1000+ LOC | All modules | 20–40h |

---

# Mini Projects

---

## Mini Project 1 — Word Frequency Analyser

**Covers:** Modules 01–03 (Fundamentals, Functions, Data Structures)

**Objective:** Analyse a text file and produce a report of word frequency statistics.

**Requirements:**
- Accept a file path as a command-line argument
- Clean text: lowercase, remove punctuation, strip stop words
- Report: top-20 words, total word count, unique word count, average word length
- Export results to a JSON file

**Starter Code:**
```python
# word_analyser.py
import sys
import json
import string
from collections import Counter
from pathlib import Path

STOP_WORDS = {
    "the", "a", "an", "is", "in", "of", "and", "to", "it",
    "that", "was", "he", "she", "they", "his", "her", "i",
    "we", "you", "be", "are", "were", "been", "have", "has",
    "had", "do", "does", "did", "will", "would", "could", "should",
}

def load_text(path: Path) -> str:
    """Load text from file."""
    # TODO: implement with proper error handling

def clean_text(text: str) -> list[str]:
    """Tokenise and clean text: lowercase, remove punctuation and stop words."""
    # TODO: implement

def analyse(words: list[str]) -> dict:
    """Compute frequency statistics."""
    # TODO: implement

def save_report(report: dict, output_path: Path) -> None:
    """Save report as JSON."""
    # TODO: implement

def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python word_analyser.py <input_file> [output_file]")
        sys.exit(1)
    # TODO: wire up the functions

if __name__ == "__main__":
    main()
```

**Evaluation Criteria:**
- [ ] Handles missing file gracefully (FileNotFoundError with message)
- [ ] Stop words are filtered correctly
- [ ] Top-20 output is sorted by frequency descending
- [ ] JSON output is well-formatted
- [ ] Unit tests for `clean_text()` and `analyse()`

---

## Mini Project 2 — Personal Expense CLI

**Covers:** Modules 01–05 (Fundamentals through File Handling)

**Objective:** A persistent command-line expense tracker.

**Requirements:**
- Commands: `add`, `list`, `summary`, `delete`, `export`
- Store expenses in a local JSON file
- `add`: amount, category, optional description
- `list`: show all or filter by category
- `summary`: total per category + overall total with a text bar chart
- `delete`: remove by ID
- `export`: write to CSV

**Full Solution available in:** `05_file_handling_exceptions.md` (Mini-Project section)

---

## Mini Project 3 — Web Scraper: Job Listings

**Covers:** Modules 05, 06, 12 (File Handling, Stdlib, Automation)

**Objective:** Scrape job listings from a public jobs board and save to CSV.

**Target site:** `https://realpython.github.io/fake-jobs/` (designed for scraping practice)

**Requirements:**
- Scrape: title, company, location, posting date, apply link
- Support pagination (the fake site has one page, but code for multi-page)
- Filter by keyword (e.g. only "Python" roles)
- Save to CSV with timestamp in filename
- Rate-limit: 1 second between requests

```python
# job_scraper.py
import requests
import csv
import time
from bs4 import BeautifulSoup
from pathlib import Path
from datetime import datetime

BASE_URL = "https://realpython.github.io/fake-jobs/"

def scrape_jobs(keyword: str | None = None) -> list[dict]:
    """Scrape job listings, optionally filtered by keyword."""
    jobs = []
    response = requests.get(BASE_URL, timeout=15)
    response.raise_for_status()

    soup = BeautifulSoup(response.text, "lxml")

    for card in soup.select("div.card"):
        title = card.select_one("h2.title").text.strip()
        company = card.select_one("h3.company").text.strip()
        location = card.select_one("p.location").text.strip()
        date = card.select_one("time")["datetime"]
        link = card.select_one("a.card-footer-item")["href"]

        if keyword and keyword.lower() not in title.lower():
            continue

        jobs.append({
            "title": title,
            "company": company,
            "location": location,
            "date": date,
            "apply_link": link,
        })

    return jobs

def save_csv(jobs: list[dict], keyword: str | None = None) -> Path:
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    suffix = f"_{keyword}" if keyword else ""
    path = Path(f"jobs{suffix}_{timestamp}.csv")

    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=jobs[0].keys())
        writer.writeheader()
        writer.writerows(jobs)

    return path

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Scrape fake job listings")
    parser.add_argument("--keyword", "-k", help="Filter by job title keyword")
    args = parser.parse_args()

    print(f"Scraping {BASE_URL}...")
    jobs = scrape_jobs(keyword=args.keyword)
    print(f"Found {len(jobs)} jobs")

    if jobs:
        path = save_csv(jobs, args.keyword)
        print(f"Saved to {path}")
```

---

## Mini Project 4 — REST API Client Library

**Covers:** Modules 04, 06, 10 (OOP, Stdlib, APIs)

**Objective:** Build a reusable Python client library for the JSONPlaceholder API.

**Requirements:**
- Class `JSONPlaceholderClient` with methods: `get_posts`, `get_post`, `create_post`, `update_post`, `delete_post`
- Pydantic models for `Post`, `Comment`, `User`
- Retry logic with exponential backoff
- Comprehensive unit tests using `unittest.mock`
- Type hints throughout

---

## Mini Project 5 — Data Pipeline: COVID Statistics

**Covers:** Modules 06, 11 (Stdlib, Data Analysis)

**Objective:** Fetch, clean, analyse, and visualise COVID statistics data.

**Data source:** `https://disease.sh/v3/covid-19/countries` (free, no auth required)

**Requirements:**
- Fetch live data from the API
- Load into Pandas DataFrame
- Clean: handle missing values, normalise column names
- Analyse: top 10 countries by cases/deaths, case fatality rate, cases per million
- Visualise: bar chart of top countries, scatter plot of cases vs deaths
- Save: cleaned CSV + PNG chart files

```python
# covid_analysis.py
import requests
import pandas as pd
import matplotlib.pyplot as plt

def fetch_data() -> pd.DataFrame:
    """Fetch COVID stats for all countries."""
    response = requests.get("https://disease.sh/v3/covid-19/countries", timeout=30)
    response.raise_for_status()
    data = response.json()
    df = pd.DataFrame(data)
    return df

def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """Select and clean relevant columns."""
    cols = {
        "country": "country",
        "cases": "total_cases",
        "deaths": "total_deaths",
        "recovered": "total_recovered",
        "active": "active_cases",
        "casesPerOneMillion": "cases_per_million",
        "deathsPerOneMillion": "deaths_per_million",
        "population": "population",
    }
    df = df[list(cols.keys())].rename(columns=cols)
    df = df.dropna(subset=["total_cases", "total_deaths"])
    df["case_fatality_rate"] = (df["total_deaths"] / df["total_cases"] * 100).round(2)
    return df.reset_index(drop=True)

def analyse(df: pd.DataFrame) -> None:
    """Print key statistics."""
    print(f"\nTotal countries: {len(df)}")
    print(f"\nTop 10 by Cases:")
    print(df.nlargest(10, "total_cases")[["country", "total_cases", "case_fatality_rate"]].to_string(index=False))
    print(f"\nHighest Case Fatality Rate (min 100k cases):")
    high_cases = df[df["total_cases"] > 100_000]
    print(high_cases.nlargest(5, "case_fatality_rate")[["country", "case_fatality_rate"]].to_string(index=False))

def plot(df: pd.DataFrame) -> None:
    """Generate and save visualisations."""
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))

    top10 = df.nlargest(10, "total_cases")
    axes[0].barh(top10["country"], top10["total_cases"] / 1e6)
    axes[0].set_xlabel("Total Cases (millions)")
    axes[0].set_title("Top 10 Countries by COVID Cases")
    axes[0].invert_yaxis()

    sample = df[df["total_cases"] > 1_000_000]
    axes[1].scatter(sample["total_cases"] / 1e6, sample["total_deaths"] / 1e6, alpha=0.6)
    axes[1].set_xlabel("Cases (millions)")
    axes[1].set_ylabel("Deaths (millions)")
    axes[1].set_title("Cases vs Deaths (countries > 1M cases)")

    plt.tight_layout()
    plt.savefig("covid_analysis.png", dpi=150, bbox_inches="tight")
    print("\nChart saved to covid_analysis.png")

if __name__ == "__main__":
    df = fetch_data()
    df = clean_data(df)
    df.to_csv("covid_data.csv", index=False)
    analyse(df)
    plot(df)
```

---

---

# Intermediate Projects

---

## Intermediate Project 1 — Task Management API

**Covers:** Modules 04, 07, 08, 10, 13, 14

**Objective:** Build a complete CRUD REST API for task management.

**Specification:**

```
Entities:
  User: id, name, email, created_at
  Project: id, name, description, owner_id, created_at
  Task: id, title, description, status, priority, project_id, assignee_id, due_date, created_at

Status values: "todo", "in_progress", "done", "cancelled"
Priority values: "low", "medium", "high", "critical"

Endpoints:
  POST   /auth/register          — register a new user
  POST   /auth/login             — login, receive JWT

  GET    /projects               — list my projects
  POST   /projects               — create project
  GET    /projects/{id}          — get project details + tasks
  PUT    /projects/{id}          — update project
  DELETE /projects/{id}          — delete project (and its tasks)

  GET    /projects/{id}/tasks    — list tasks (filter: status, priority, assignee)
  POST   /projects/{id}/tasks    — create task
  GET    /tasks/{id}             — get task details
  PATCH  /tasks/{id}             — update status/priority/assignee
  DELETE /tasks/{id}             — delete task

  GET    /users/{id}/tasks       — all tasks assigned to a user
```

**Technology Stack:**
- FastAPI + Pydantic v2
- SQLite with SQLAlchemy (async)
- JWT authentication (PyJWT + passlib)
- pytest + httpx for tests
- Docker + docker-compose
- GitHub Actions CI

**Project Structure:**
```
task_api/
├── src/
│   └── task_api/
│       ├── api/
│       │   ├── main.py
│       │   ├── routers/
│       │   │   ├── auth.py
│       │   │   ├── projects.py
│       │   │   └── tasks.py
│       │   └── schemas/
│       ├── core/
│       │   ├── config.py
│       │   ├── security.py
│       │   └── exceptions.py
│       ├── db/
│       │   ├── models.py
│       │   └── session.py
│       └── services/
│           ├── auth_service.py
│           ├── project_service.py
│           └── task_service.py
├── tests/
│   ├── conftest.py
│   ├── unit/
│   └── integration/
├── Dockerfile
├── docker-compose.yml
├── pyproject.toml
└── Makefile
```

**Evaluation Criteria:**
- [ ] Authentication works (register → login → use JWT on protected endpoints)
- [ ] All CRUD endpoints return correct status codes
- [ ] Validation errors return 422 with field details
- [ ] Users can only access their own projects
- [ ] Tests cover: auth flow, CRUD for each entity, permission errors
- [ ] Coverage ≥ 80%
- [ ] `mypy` passes with no errors
- [ ] Runs in Docker with `docker-compose up`

---

## Intermediate Project 2 — Data Analysis Dashboard (CLI)

**Covers:** Modules 03, 09, 11, 12

**Objective:** A command-line tool that performs automated EDA on any CSV file.

**Requirements:**
- `analyse <file.csv>` — run full EDA pipeline
- `profile <file.csv> --column <col>` — deep dive on one column
- `clean <file.csv> --output <out.csv>` — apply standard cleaning
- `compare <file1.csv> <file2.csv>` — statistical comparison of two datasets

**Output:**
- Rich-formatted tables in the terminal
- PNG plots exported to a `reports/` directory
- JSON summary report

**Key Features:**
- Detect and report: missing values, duplicates, outliers, skewed distributions
- Correlation analysis with significance testing
- Category encoding suggestions
- Memory usage optimisation recommendations

---

## Intermediate Project 3 — CLI Password Manager

**Covers:** Modules 04, 05, 07, 12, 14

**Objective:** A local encrypted password manager with a CLI interface.

**Requirements:**
- Master password (never stored; used to derive encryption key)
- AES-256-GCM encryption via `cryptography` library
- Commands: `add`, `get`, `list`, `delete`, `generate` (random password), `export`
- Vault stored as encrypted JSON in `~/.vault.enc`
- Password strength checker when adding
- Clipboard integration (copy password without printing)
- Timeout: clear clipboard after 30 seconds

```python
# Key derivation (PBKDF2 with salt)
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes
from cryptography.fernet import Fernet
import base64, os, secrets

def derive_key(master_password: str, salt: bytes) -> bytes:
    """Derive a Fernet-compatible key from master password using PBKDF2."""
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=480_000,   # OWASP recommendation 2023
    )
    key = kdf.derive(master_password.encode())
    return base64.urlsafe_b64encode(key)
```

---

---

# Capstone Projects

---

## Capstone A — Production REST API with Full DevOps Pipeline

**Level:** Advanced | **Time:** 30–40 hours  
**Covers:** All modules (01–15)

### Overview

Build and deploy a **Social Bookmarks API** — a service where users can save, tag, and share web bookmarks. The system must be production-quality with full DevOps tooling.

### Domain Model

```
User:
  - id (UUID), email, username, hashed_password, created_at, is_active

Bookmark:
  - id (UUID), url, title, description, is_public
  - created_by (FK → User), created_at, updated_at

Tag:
  - id (UUID), name (unique, slug-formatted)

BookmarkTag (many-to-many):
  - bookmark_id, tag_id

Collection:
  - id (UUID), name, description, owner_id
  - bookmarks (many-to-many with Bookmark)
```

### API Specification

```
Authentication:
  POST /auth/register     — email + username + password
  POST /auth/login        — returns access + refresh token
  POST /auth/refresh      — refresh access token
  POST /auth/logout       — revoke refresh token

Bookmarks:
  GET    /bookmarks                — my bookmarks (paginated, filterable)
  POST   /bookmarks                — create bookmark (auto-fetch title from URL)
  GET    /bookmarks/{id}           — get bookmark
  PATCH  /bookmarks/{id}           — update title/description/tags/visibility
  DELETE /bookmarks/{id}           — delete bookmark
  GET    /bookmarks/search?q=<>    — full-text search across title+description+tags
  GET    /public/bookmarks         — public bookmarks (no auth)

Tags:
  GET    /tags                     — list all my tags with bookmark counts
  GET    /tags/{slug}/bookmarks    — bookmarks with this tag

Collections:
  GET    /collections              — my collections
  POST   /collections              — create collection
  POST   /collections/{id}/bookmarks/{bookmark_id}  — add to collection
  DELETE /collections/{id}/bookmarks/{bookmark_id}  — remove from collection
```

### Technical Requirements

**Core:**
- FastAPI + Pydantic v2
- PostgreSQL + SQLAlchemy (async, Alembic migrations)
- Redis (JWT refresh token store, rate limiting)
- Background task: fetch page title from URL on bookmark creation

**Quality:**
- `mypy --strict` — zero errors
- `ruff` — zero warnings
- `pytest` — ≥ 85% coverage
- All endpoints tested (unit + integration)

**Security:**
- bcrypt password hashing
- JWT with refresh token rotation
- Rate limiting per user (60 requests/minute)
- Input validation on all endpoints
- SQL injection prevention (use SQLAlchemy ORM, never raw SQL with f-strings)

**DevOps:**
- Multi-stage `Dockerfile` (builder + runtime)
- `docker-compose.yml` (API + PostgreSQL + Redis + pgAdmin)
- GitHub Actions CI (lint → type-check → test → docker build)
- GitHub Actions CD (deploy on tag push)
- Health check endpoint (`GET /health`)
- Structured JSON logging with request ID

**Documentation:**
- Auto-generated OpenAPI docs (FastAPI default)
- `README.md` with: setup, environment variables, API overview, development guide
- `CHANGELOG.md` with semantic versioning
- `ARCHITECTURE.md` with component diagram

### Evaluation Rubric

| Category | Points | Criteria |
|----------|--------|---------|
| Functionality | 30 | All endpoints work correctly |
| Code Quality | 20 | mypy + ruff pass; clean, readable code |
| Testing | 20 | ≥85% coverage; unit + integration tests |
| Security | 15 | Auth, rate limiting, input validation |
| DevOps | 10 | Docker + CI/CD pipeline |
| Documentation | 5 | README, CHANGELOG, API docs |
| **Total** | **100** | |

---

## Capstone B — Data Analysis and ML Pipeline

**Level:** Advanced | **Time:** 25–35 hours  
**Covers:** Modules 01–09, 11, 13, 14

### Overview

Build an end-to-end machine learning pipeline for **customer churn prediction**. The pipeline takes raw customer data, cleans it, engineers features, trains models, evaluates them, and exposes predictions via a REST API.

### Dataset

Use the IBM Telco Customer Churn dataset (available at `https://raw.githubusercontent.com/dsrscientist/dataset1/master/Telco-Customer-Churn.csv`).

### Pipeline Stages

```
1. DATA INGESTION
   - Load CSV from file or URL
   - Validate schema (expected columns + dtypes)
   - Profile: missing values, distributions, class balance

2. DATA CLEANING
   - Handle missing values (median imputation for numeric, mode for categorical)
   - Remove duplicates
   - Fix data types (TotalCharges has spaces → convert to float)

3. FEATURE ENGINEERING
   - Encode categoricals (one-hot, label encoding)
   - Create: tenure_group (binned), charges_per_month_ratio
   - Scale numeric features (StandardScaler)
   - Split: train/validation/test (70/15/15, stratified)

4. MODEL TRAINING
   - Train multiple models: LogisticRegression, RandomForestClassifier, GradientBoostingClassifier
   - Hyperparameter search (GridSearchCV or RandomizedSearchCV)
   - Track experiments: model name, params, metrics → results.json

5. EVALUATION
   - Metrics: accuracy, precision, recall, F1, ROC-AUC
   - Confusion matrix plot
   - Feature importance plot
   - Select best model by F1 score

6. SERVING
   - Save best model with joblib
   - FastAPI endpoint: POST /predict (accepts customer features, returns churn probability)
   - Batch prediction: POST /predict/batch (CSV upload → results CSV)
```

### Project Structure

```
churn_pipeline/
├── src/
│   └── churn/
│       ├── data/
│       │   ├── loader.py          # CSV ingestion + validation
│       │   ├── cleaner.py         # cleaning pipeline
│       │   └── features.py        # feature engineering
│       ├── models/
│       │   ├── trainer.py         # training + cross-validation
│       │   ├── evaluator.py       # metrics + plots
│       │   └── registry.py        # save/load models
│       ├── api/
│       │   ├── main.py
│       │   └── routers/predict.py
│       └── pipeline.py            # orchestrates all stages
├── data/
│   ├── raw/                       # original data (gitignored)
│   └── processed/                 # cleaned data (gitignored)
├── models/                        # saved model artifacts (gitignored)
├── reports/                       # generated plots and metrics
├── notebooks/
│   └── exploration.ipynb          # EDA notebook
├── tests/
│   ├── test_cleaner.py
│   ├── test_features.py
│   └── test_api.py
├── pyproject.toml
├── Makefile
└── README.md
```

### Evaluation Rubric

| Category | Points | Criteria |
|----------|--------|---------|
| Data Pipeline | 25 | Clean, robust, handles edge cases |
| Feature Engineering | 15 | Appropriate encoding/scaling/feature creation |
| Model Training | 20 | Multiple models, cross-validation, param search |
| Evaluation | 15 | Correct metrics, meaningful plots |
| API | 15 | Works correctly, validates input |
| Code Quality | 10 | Type hints, tests, clean structure |
| **Total** | **100** | |

---

## Capstone C — CLI Developer Tool (Open Source Ready)

**Level:** Advanced | **Time:** 20–30 hours  
**Covers:** Modules 02–09, 12, 13, 14

### Overview

Build **`pyinspect`** — a CLI tool that analyses a Python codebase and generates a comprehensive health report covering: code quality, test coverage, dependency vulnerabilities, documentation completeness, and complexity metrics.

### Commands

```bash
pyinspect scan <directory>          # full codebase analysis
pyinspect scan . --format json      # JSON output for CI integration
pyinspect scan . --format html      # HTML report with charts

pyinspect deps <requirements.txt>   # audit dependencies for vulnerabilities
pyinspect coverage <directory>      # coverage report with file-level breakdown
pyinspect complexity <file.py>      # cyclomatic complexity per function
pyinspect docs <directory>          # documentation coverage (docstring %)

pyinspect diff <before.json> <after.json>  # compare two scan results
```

### Metrics to Report

```
Code Quality:
  - Files with no type hints
  - Functions > 50 lines (too long)
  - Functions with cyclomatic complexity > 10
  - TODO/FIXME/HACK comment count
  - Duplicate code blocks (hash-based detection)

Test Coverage:
  - Overall % coverage
  - Files with < 50% coverage
  - Functions not covered at all

Documentation:
  - % of public functions with docstrings
  - % of public classes with docstrings
  - Missing module-level docstrings

Dependencies:
  - Outdated packages (compare against PyPI latest)
  - Known vulnerabilities (check against OSV database)
  - Unused imports detected by ruff

Complexity:
  - Average function length
  - Average cyclomatic complexity
  - Deepest nesting level
```

### Technology Requirements

- `click` for CLI
- `ast` module for Python code parsing (no external AST lib)
- `rich` for beautiful terminal output
- `httpx` for PyPI/OSV API calls
- `subprocess` to call `pytest --cov` and `ruff`
- Pydantic for structured report data
- Export to JSON, HTML (Jinja2 template), and Markdown

### Open Source Requirements

- `README.md` with: badges (build, coverage, PyPI version), installation, usage examples
- `CONTRIBUTING.md`
- `CHANGELOG.md` (Conventional Commits style)
- `.github/ISSUE_TEMPLATE/` (bug report + feature request)
- `.github/PULL_REQUEST_TEMPLATE.md`
- MIT `LICENSE`
- Published to TestPyPI (optionally real PyPI)
- `pyproject.toml` with entry point: `pyinspect = "pyinspect.cli:main"`

---

## Assessment Framework

### Self-Assessment Checklist (for all Capstone projects)

**Functionality:**
- [ ] All required features are implemented
- [ ] Edge cases handled (empty input, invalid data, network errors)
- [ ] Error messages are clear and actionable

**Code Quality:**
- [ ] All public functions have type hints
- [ ] All public functions have docstrings
- [ ] No functions longer than 50 lines
- [ ] No nested functions deeper than 3 levels
- [ ] `ruff check` passes with zero warnings
- [ ] `mypy --strict` passes with zero errors

**Testing:**
- [ ] Coverage ≥ 80% (or ≥ 85% for Capstone A)
- [ ] Tests follow AAA pattern
- [ ] External dependencies are mocked
- [ ] Happy path + error cases tested

**Git & Collaboration:**
- [ ] Meaningful commit history (no "WIP", "changes", etc.)
- [ ] Feature branches used (not committing directly to main)
- [ ] `README.md` contains setup instructions that work from scratch
- [ ] `.env.example` committed (no real secrets in git)

**DevOps:**
- [ ] Application runs in Docker with `docker-compose up`
- [ ] CI pipeline passes on all pushes
- [ ] Health check endpoint works

---

## Suggested Order for Completing Projects

### For Beginners
1. Mini Project 1 (Word Frequency)
2. Mini Project 2 (Expense CLI)
3. Mini Project 3 (Job Scraper)
4. Mini Project 5 (COVID Analysis)
5. Intermediate Project 2 (Data Dashboard)

### For Backend/API Developers
1. Mini Project 4 (API Client)
2. Intermediate Project 1 (Task API)
3. Capstone A (Social Bookmarks API)

### For Data/ML Engineers
1. Mini Project 5 (COVID Analysis)
2. Intermediate Project 2 (Data Dashboard)
3. Capstone B (Churn Prediction Pipeline)

### For Open Source / Tool Builders
1. Mini Project 2 (Expense CLI) — learn click + file handling
2. Mini Project 3 (Job Scraper) — learn requests + BeautifulSoup
3. Intermediate Project 3 (Password Manager) — learn cryptography
4. Capstone C (pyinspect tool) — full open-source project

---

## Additional Challenge Problems

For extra practice between projects:

1. **Implement a simple rate limiter** using `time` and a sliding window (no Redis)
2. **Build a Markdown to HTML converter** using regex and string processing
3. **Write a grep clone** (`pygrep`) that supports recursive search with colour output
4. **Implement `pathlib.Path.walk()`** from scratch using `os.scandir`
5. **Build a simple key-value store** with WAL (Write-Ahead Log) for crash recovery
6. **Implement consistent hashing** for a distributed cache ring
7. **Write a query engine** that supports `SELECT`, `WHERE`, `ORDER BY`, `LIMIT` over CSV files
8. **Build a mini asyncio event loop** to understand how asyncio works internally

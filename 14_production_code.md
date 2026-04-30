# Module 14 — Production-Ready Code and Project Structuring

> **Level:** Advanced | **Estimated Time:** 6 hours | **Prerequisites:** Modules 01–13

---

## Learning Objectives

By the end of this module you will be able to:
- Structure a Python project for production deployment
- Apply comprehensive type hints and run static analysis with `mypy`
- Write self-documenting code using docstrings and type annotations
- Implement configuration management with environment-based settings
- Set up CI/CD pipelines with GitHub Actions
- Apply code quality tools: Black, Ruff, isort
- Use `Makefile` for reproducible developer workflows
- Understand containerisation with Docker for Python apps
- Apply security best practices: secrets management, dependency auditing

---

## 14.1 Professional Project Structure

```
my_app/
├── src/
│   └── my_app/
│       ├── __init__.py          # package entry point + version
│       ├── api/
│       │   ├── __init__.py
│       │   ├── main.py          # FastAPI app factory
│       │   ├── routers/
│       │   │   ├── __init__.py
│       │   │   ├── users.py
│       │   │   └── products.py
│       │   ├── middleware/
│       │   │   ├── __init__.py
│       │   │   ├── auth.py
│       │   │   └── logging.py
│       │   └── schemas/
│       │       ├── __init__.py
│       │       ├── user.py
│       │       └── product.py
│       ├── core/
│       │   ├── __init__.py
│       │   ├── config.py        # settings and env management
│       │   ├── exceptions.py    # custom exception hierarchy
│       │   └── security.py      # auth helpers
│       ├── db/
│       │   ├── __init__.py
│       │   ├── models.py        # ORM models
│       │   └── session.py       # DB session management
│       └── services/
│           ├── __init__.py
│           ├── user_service.py
│           └── email_service.py
├── tests/
│   ├── conftest.py
│   ├── unit/
│   │   ├── test_user_service.py
│   │   └── test_validators.py
│   └── integration/
│       └── test_api.py
├── scripts/
│   ├── seed_database.py
│   └── health_check.py
├── deploy/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── kubernetes/
├── docs/
│   └── api.md
├── .env.example                 # committed template (no real secrets)
├── .gitignore
├── .pre-commit-config.yaml
├── Makefile
├── pyproject.toml
├── README.md
└── CHANGELOG.md
```

---

## 14.2 Configuration Management

```python
# src/my_app/core/config.py
from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables or .env file.
    Pydantic-settings validates and coerces types automatically.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",     # ignore unknown env vars
    )

    # Application
    APP_NAME: str = "MyApp"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    ENVIRONMENT: Literal["development", "staging", "production"] = "development"

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    WORKERS: int = 1

    # Database
    DATABASE_URL: str = "sqlite:///./app.db"
    DB_POOL_SIZE: int = 5
    DB_MAX_OVERFLOW: int = 10

    # Redis
    REDIS_URL: str = "redis://localhost:6379"

    # Security
    SECRET_KEY: str = "change-me-in-production-use-a-64-char-random-string"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    ALLOWED_ORIGINS: list[str] = ["http://localhost:3000"]

    # Email
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""

    # External APIs
    OPENAI_API_KEY: str = ""

    @field_validator("SECRET_KEY")
    @classmethod
    def validate_secret_key(cls, v: str) -> str:
        if v == "change-me-in-production-use-a-64-char-random-string":
            import warnings
            warnings.warn("Using default SECRET_KEY — change this for production!", stacklevel=2)
        if len(v) < 32:
            raise ValueError("SECRET_KEY must be at least 32 characters")
        return v

    @model_validator(mode="after")
    def validate_production_settings(self) -> Settings:
        """Enforce stricter validation in production."""
        if self.ENVIRONMENT == "production":
            if self.DEBUG:
                raise ValueError("DEBUG must be False in production")
            if "sqlite" in self.DATABASE_URL:
                raise ValueError("SQLite is not allowed in production")
        return self

    @property
    def is_production(self) -> bool:
        return self.ENVIRONMENT == "production"

    @property
    def database_url_sync(self) -> str:
        """Return sync DB URL (replace async driver prefix if needed)."""
        return self.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Singleton settings instance — cached after first call."""
    return Settings()
```

**.env.example** (committed — contains no real secrets):
```bash
APP_NAME=MyApp
APP_VERSION=1.0.0
DEBUG=false
ENVIRONMENT=development

DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/myapp
REDIS_URL=redis://localhost:6379

SECRET_KEY=generate-with-python-secrets-token-hex-32
ACCESS_TOKEN_EXPIRE_MINUTES=30

SMTP_HOST=smtp.gmail.com
SMTP_USER=your@email.com
SMTP_PASSWORD=your-app-password

OPENAI_API_KEY=sk-...
```

---

## 14.3 Type Hints and Static Analysis

```python
# src/my_app/services/user_service.py
from __future__ import annotations

from typing import TYPE_CHECKING
from uuid import UUID, uuid4
from datetime import datetime

if TYPE_CHECKING:
    from my_app.db.session import AsyncSession

from my_app.core.exceptions import NotFoundError, DuplicateError
from my_app.api.schemas.user import UserCreate, UserUpdate, UserResponse


class UserService:
    """
    Business logic layer for user management.

    This class is responsible for all user-related operations.
    It interacts with the database via the session and returns
    domain objects (not raw database rows).
    """

    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def create(self, data: UserCreate) -> UserResponse:
        """
        Create a new user account.

        Args:
            data: Validated user creation data.

        Returns:
            The newly created user.

        Raises:
            DuplicateError: If a user with the same email already exists.
        """
        existing = await self._db.get_by_email(data.email)
        if existing:
            raise DuplicateError("User", "email", data.email)

        user = {
            "id": uuid4(),
            "email": data.email,
            "name": data.name,
            "hashed_password": self._hash_password(data.password),
            "created_at": datetime.utcnow(),
            "is_active": True,
        }
        await self._db.save(user)
        return UserResponse(**user)

    async def get_by_id(self, user_id: UUID) -> UserResponse:
        """
        Fetch a user by their UUID.

        Raises:
            NotFoundError: If no user exists with the given ID.
        """
        user = await self._db.get(user_id)
        if not user:
            raise NotFoundError("User", user_id)
        return UserResponse(**user)

    @staticmethod
    def _hash_password(password: str) -> str:
        import hashlib, os
        salt = os.urandom(32)
        key = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 100_000)
        return (salt + key).hex()
```

### Running `mypy`

```bash
# Install
pip install mypy types-requests types-PyYAML

# Run
mypy src/

# Strict mode (recommended for new projects)
mypy src/ --strict

# Configuration in pyproject.toml:
# [tool.mypy]
# python_version = "3.11"
# strict = true
# ignore_missing_imports = true
# exclude = ["tests/"]
```

---

## 14.4 Code Quality Toolchain

### Black — Autoformatter

```bash
# Format all Python files
black src/ tests/

# Check without modifying
black --check src/

# pyproject.toml config:
# [tool.black]
# line-length = 88
# target-version = ["py311"]
```

### Ruff — Ultra-Fast Linter

```bash
# Lint and fix auto-fixable issues
ruff check src/ tests/ --fix

# Format (replaces isort + Black's line formatting)
ruff format src/ tests/

# pyproject.toml config:
# [tool.ruff]
# line-length = 88
# target-version = "py311"
#
# [tool.ruff.lint]
# select = ["E", "F", "I", "N", "UP", "B", "C4", "SIM", "TID"]
# ignore = ["E501"]
#
# [tool.ruff.lint.isort]
# known-first-party = ["my_app"]
```

### Makefile — Developer Workflow

```makefile
# Makefile — reproducible developer commands
.PHONY: setup lint format type-check test test-cov clean run

PYTHON = python
PYTEST = pytest

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup:  ## Install dependencies
	$(PYTHON) -m pip install --upgrade pip
	pip install -e ".[dev]"
	pre-commit install

lint:  ## Run linter
	ruff check src/ tests/

format:  ## Auto-format code
	ruff format src/ tests/
	ruff check src/ tests/ --fix

type-check:  ## Run static type checker
	mypy src/

test:  ## Run all tests with coverage
	$(PYTEST) --cov=src --cov-report=term-missing --cov-report=html -v

test-fast:  ## Run fast unit tests only
	$(PYTEST) -m "not slow and not integration" -v

test-cov:  ## Check coverage meets threshold
	$(PYTEST) --cov=src --cov-fail-under=80 -q

clean:  ## Clean generated files
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache .mypy_cache .ruff_cache htmlcov dist build *.egg-info

run:  ## Run the application locally
	uvicorn src.my_app.api.main:app --reload --host 0.0.0.0 --port 8000

docker-build:  ## Build Docker image
	docker build -t my_app:latest .

docker-run:  ## Run Docker container
	docker-compose up -d
```

---

## 14.5 Docker for Python Applications

```dockerfile
# deploy/Dockerfile
# Multi-stage build: smaller final image, no build tools in production

# ─── Stage 1: Builder ───────────────────────────────────────────────
FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency files first (layer caching: only re-run if deps change)
COPY pyproject.toml README.md ./
COPY src/ src/

# Install project and its dependencies into /app/venv
RUN pip install --upgrade pip && \
    pip install --no-cache-dir build && \
    python -m build --wheel --no-isolation && \
    pip install --no-cache-dir dist/*.whl


# ─── Stage 2: Runtime ───────────────────────────────────────────────
FROM python:3.11-slim as runtime

# Security: non-root user
RUN useradd --uid 1001 --create-home appuser

WORKDIR /app

# Copy installed packages from builder (not build tools)
COPY --from=builder /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY --chown=appuser:appuser src/ src/

USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

EXPOSE 8000

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000

CMD ["uvicorn", "src.my_app.api.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
```

```yaml
# deploy/docker-compose.yml
version: "3.9"

services:
  api:
    build:
      context: ..
      dockerfile: deploy/Dockerfile
    ports:
      - "8000:8000"
    environment:
      - ENVIRONMENT=development
      - DATABASE_URL=postgresql+asyncpg://myapp:secret@db:5432/myapp
      - REDIS_URL=redis://redis:6379
    env_file:
      - ../.env
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    restart: unless-stopped
    volumes:
      - ../src:/app/src    # hot-reload in dev

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: myapp
      POSTGRES_PASSWORD: secret
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myapp"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

---

## 14.6 CI/CD with GitHub Actions

```yaml
# Example .github/workflows/ci.yml (not included in this course)
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  quality:
    name: Code Quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
          cache: "pip"

      - name: Install dependencies
        run: pip install ruff mypy

      - name: Lint
        run: ruff check src/ tests/

      - name: Format check
        run: ruff format --check src/ tests/

      - name: Type check
        run: mypy src/

  test:
    name: Tests (Python ${{ matrix.python-version }})
    runs-on: ubuntu-latest
    needs: quality
    strategy:
      matrix:
        python-version: ["3.10", "3.11", "3.12"]

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: test_user
          POSTGRES_PASSWORD: test_pass
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
          cache: "pip"

      - name: Install dependencies
        run: pip install -e ".[dev]"

      - name: Run tests
        env:
          DATABASE_URL: postgresql://test_user:test_pass@localhost:5432/test_db
          ENVIRONMENT: testing
          SECRET_KEY: test-secret-key-that-is-at-least-32-characters-long
        run: pytest --cov=src --cov-report=xml -v

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage.xml

  security:
    name: Security Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - name: Audit dependencies
        run: |
          pip install pip-audit
          pip-audit --requirement requirements.txt

  docker:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Build image
        run: docker build -t my_app:${{ github.sha }} -f deploy/Dockerfile .
```

---

## 14.7 Security Best Practices

```python
# src/my_app/core/security.py
import os
import secrets
import hashlib
import hmac
from datetime import datetime, timedelta, timezone
from typing import Any

import jwt   # pip install PyJWT
from passlib.context import CryptContext   # pip install passlib[bcrypt]

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(plain_password: str) -> str:
    """Hash a password using bcrypt (adaptive, salted)."""
    return pwd_context.hash(plain_password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain password against a bcrypt hash."""
    return pwd_context.verify(plain_password, hashed_password)

# JWT tokens
def create_access_token(data: dict[str, Any], secret_key: str,
                         expires_minutes: int = 30) -> str:
    """Create a signed JWT access token."""
    payload = {
        **data,
        "exp": datetime.now(timezone.utc) + timedelta(minutes=expires_minutes),
        "iat": datetime.now(timezone.utc),
        "jti": secrets.token_hex(16),   # unique token ID for revocation
    }
    return jwt.encode(payload, secret_key, algorithm="HS256")

def decode_token(token: str, secret_key: str) -> dict[str, Any]:
    """Decode and validate a JWT token."""
    return jwt.decode(token, secret_key, algorithms=["HS256"])

# Secrets generation
def generate_api_key() -> str:
    """Generate a cryptographically secure API key."""
    return f"sk_{secrets.token_urlsafe(32)}"

def generate_secret_key() -> str:
    """Generate a secret key for JWT signing."""
    return secrets.token_hex(32)   # 256-bit key

# Input sanitization
def sanitize_filename(filename: str) -> str:
    """Remove dangerous characters from a filename."""
    import re
    # Keep only safe characters
    safe = re.sub(r"[^\w\-. ]", "", filename)
    # Prevent path traversal
    return safe.replace("..", "").strip()

# Timing-safe string comparison (prevents timing attacks)
def safe_compare(a: str, b: str) -> bool:
    """Compare two strings in constant time."""
    return hmac.compare_digest(a.encode(), b.encode())
```

---

## 14.8 Logging Strategy

```python
# src/my_app/core/logging.py
import logging
import sys
from typing import Any

import structlog


def configure_logging(level: str = "INFO", json_output: bool = False) -> None:
    """
    Configure application-wide logging.

    In development: coloured, human-readable output.
    In production: JSON structured output for log aggregation.
    """
    shared_processors = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
    ]

    if json_output:
        renderer = structlog.processors.JSONRenderer()
    else:
        renderer = structlog.dev.ConsoleRenderer(colors=True)

    structlog.configure(
        processors=shared_processors + [renderer],
        wrapper_class=structlog.make_filtering_bound_logger(
            getattr(logging, level.upper())
        ),
        context_class=dict,
        logger_factory=structlog.PrintLoggerFactory(sys.stdout),
        cache_logger_on_first_use=True,
    )


def get_logger(name: str) -> Any:
    """Get a named logger instance."""
    return structlog.get_logger(name)
```

---

## Best Practices Summary

1. **`src/` layout** — prevents accidental imports from source rather than installed package.
2. **Pydantic settings** — validate all configuration at startup; fail fast on invalid config.
3. **Never commit secrets** — use `.env` files (gitignored) + environment variables.
4. **Multi-stage Docker builds** — separate build environment from runtime image.
5. **Non-root Docker user** — reduces attack surface; run as UID 1001+.
6. **CI on every PR** — lint + type-check + test + security audit.
7. **`mypy --strict`** — enforce complete type coverage.
8. **`bcrypt` for passwords** — never use MD5/SHA for passwords; adaptive hashing is required.
9. **JWT `jti` claim** — include a unique token ID to support token revocation.
10. **Health check endpoints** — essential for Kubernetes liveness/readiness probes.

---

## Exercises

### Exercise 14.1 — Settings Validation
Extend the `Settings` class to add:
- `MAX_FILE_UPLOAD_MB` (int, default 10, max 100)
- `ALLOWED_FILE_TYPES` (list of extensions, default [".jpg", ".png", ".pdf"])
- A validator that ensures `WORKERS` is between 1 and `os.cpu_count()`

### Exercise 14.2 — CI Pipeline
Create a GitHub Actions workflow for a Python project that:
- Runs on PR to main and on push to main
- Checks formatting with `ruff format --check`
- Lints with `ruff check`
- Type-checks with `mypy --strict`
- Runs tests with coverage ≥ 80%
- Fails the entire pipeline if any step fails

---

## Interview Prep — Top Questions for Production-Ready Code

**Q1: What is the 12-Factor App methodology?**
A set of best practices for cloud-native applications:
1. One codebase, many deploys
2. **Explicit dependencies** (`requirements.txt`/`pyproject.toml`)
3. **Config in environment** (not code)
4. **Backing services as attached resources** (DB, Redis via URL)
5. Strict build/release/run separation
6. **Stateless processes** (no local state)
7. Port binding
8. **Concurrency via process model**
9. Fast startup and graceful shutdown
10. Dev/prod parity
11. **Logs as event streams** (structured JSON to stdout)
12. Admin processes as one-off tasks
Factors 3, 6, 11 are the most commonly tested in Python interviews.

**Q2: What is Docker multi-stage build and why is it important?**
Multi-stage builds use multiple `FROM` instructions. Stage 1 (builder): installs compilers, build tools, compiles wheels. Stage 2 (runtime): copies only the compiled artifacts — no build tools, no source cache. Result: production image can be 5–10× smaller. Smaller images = faster pulls, reduced attack surface, less disk cost. Always use multi-stage for production Python images.

**Q3: How do you handle secrets securely in a Python application?**
Never hardcode: not in source code, not in `Dockerfile`, not in `docker-compose.yml`. Use: environment variables (`.env` locally, injected by platform in prod), cloud secrets managers (AWS Secrets Manager, GCP Secret Manager, HashiCorp Vault), or Kubernetes Secrets. In Python: `pydantic-settings` reads env vars cleanly. `pip-audit` checks dependencies for known CVEs.

**Q4: What is the difference between a linter and a formatter?**
- **Formatter** (Black, `ruff format`): automatically rewrites code to a consistent style. Zero configuration needed; just run it.
- **Linter** (Ruff, Flake8, Pylint): checks for code smells, unused imports, undefined names, anti-patterns. Reports issues but doesn't auto-fix everything.
- **Type checker** (mypy, Pyright): verifies type annotation consistency. Catches bugs the linter misses.
Use all three in CI. Run formatter first, then linter, then type checker.

**Q5: What is mypy strict mode and what does it enforce?**
`mypy --strict` enables: `--disallow-untyped-defs` (all functions must be annotated), `--disallow-any-generics` (no bare `list`, must be `list[int]`), `--warn-return-any`, `--no-implicit-optional`, `--strict-equality`. Strict mode catches: untyped function calls, missing return types, `Any` leakage. Start with default mode in existing codebases; gradually enable flags; require strict on new code.

**Q6: What is a CI/CD pipeline and what should a Python project's look like?**
CI (Continuous Integration) = automated quality checks on every PR. CD (Continuous Delivery/Deployment) = automated deployment on merge.
Typical Python CI: checkout → setup Python matrix (3.10, 3.11, 3.12) → install deps → **ruff** (lint) → **ruff format --check** (style) → **mypy** (types) → **pytest --cov --cov-fail-under=80** (tests) → **pip-audit** (security) → **docker build** (artifact). Block merge if any step fails.

**Q7: What is the difference between `COPY` and `ADD` in Dockerfile?**
`COPY` simply copies files/directories from build context to the image — explicit, predictable. `ADD` can also: extract tar archives automatically, fetch from URLs. Never use `ADD` unless you specifically need tar extraction — `COPY` makes intent clear and is more secure (no network fetches inside the build).

**Q8: How do you implement health checks in a production Python service?**
Expose a `GET /health` endpoint that returns `{"status": "healthy"}` with HTTP 200. Health checks should: verify the service can respond, optionally check DB connectivity and critical dependencies. Load balancers and Kubernetes use health checks to route traffic (readiness) and restart stuck pods (liveness). Keep them fast (≤50ms) and don't include heavy operations.

---

## Module Summary

| Area | Tool/Practice |
|------|-------------|
| Project structure | `src/` layout, separate tests/ and docs/ |
| Configuration | `pydantic-settings` + `.env` files |
| Type checking | `mypy --strict` |
| Formatting | `black` or `ruff format` |
| Linting | `ruff check` (replaces flake8 + isort + many plugins) |
| Security | `bcrypt` passwords, JWT with `jti`, `pip-audit` |
| Containerisation | Multi-stage Dockerfile, non-root user |
| CI/CD | GitHub Actions: quality → test → security → docker |
| Developer workflow | `Makefile` with `setup`, `lint`, `format`, `test`, `run` targets |

---

## Quiz

1. What is the `src/` layout and why is it preferred?
2. How does `pydantic-settings` load values from environment variables?
3. What is the difference between `mypy` strict mode and default mode?
4. Why should Docker containers run as a non-root user?
5. What is a multi-stage Docker build and what problem does it solve?
6. What does `pip-audit` check for?
7. Why is `bcrypt` preferred over `SHA-256` for password hashing?
8. What is the `jti` claim in a JWT and what does it enable?
9. What does `@lru_cache(maxsize=1)` on `get_settings()` achieve?
10. What is the difference between a linter and a type checker?

**Answers:**
1. With `src/` layout, your package lives in `src/mypackage/`. This prevents Python from accidentally importing the source directory directly when running tests — you must `pip install -e .` first, ensuring you always test the installed package, not the raw source. It also prevents namespace collisions and forces proper package structure.
2. `pydantic-settings` reads environment variables that **match field names** (case-insensitive). If a `Settings` class has `database_url: str`, it looks for `DATABASE_URL` in the environment, then falls back to `.env` files, then the field default. This implements the 12-Factor App config principle cleanly.
3. Default mypy mode only checks code that has type annotations — unannotated functions are silently ignored. `--strict` mode enables all strictness flags: `--disallow-untyped-defs`, `--no-implicit-optional`, `--warn-return-any`, etc. In strict mode, all functions must be annotated and `Any` must be explicit. Start with default, migrate to strict over time.
4. If a container runs as root and an attacker exploits a vulnerability in the application, they gain root access to the container. While container isolation limits damage, root inside a container can escape certain sandboxes, mount host volumes, and escalate privileges. Non-root (UID 1001+) limits the blast radius significantly.
5. Multi-stage builds use multiple `FROM` instructions. The first stage (builder) installs build tools, compiles, and installs dependencies. The final stage copies only the compiled artifacts — no build tools, compilers, or cached pip packages. Result: images can be 5–10× smaller, reducing attack surface and pull time.
6. `pip-audit` queries the Python Packaging Advisory Database (PyPA) and checks your installed dependencies against **known CVEs (security vulnerabilities)**. It reports vulnerable packages with version ranges and available fixes. Essential in CI/CD pipelines to prevent shipping code with known security holes.
7. `bcrypt` is a **slow** hashing algorithm by design — it includes a configurable work factor that increases computation time. This makes brute-force and dictionary attacks infeasible. `SHA-256` is extremely fast (nanoseconds per hash), making it trivial to try millions of passwords per second. Never use raw SHA-256 for passwords; use `bcrypt`, `argon2`, or `scrypt`.
8. `jti` (JWT ID) is a unique identifier for a token. It enables **token revocation**: store issued `jti` values in a blocklist (Redis). On each request, check if the token's `jti` is in the blocklist. Without `jti`, JWTs can't be individually revoked before expiry — only key rotation invalidates all tokens at once.
9. `@lru_cache(maxsize=1)` makes `get_settings()` return the **same `Settings` instance** on every call. The first call loads environment variables; all subsequent calls return the cached object instantly. This implements the singleton pattern for configuration — one load per process, no repeated env-var parsing.
10. A **linter** (Black, Ruff, pylint) checks code style, syntax errors, unused imports, and anti-patterns — it catches issues that can be detected without running the code. A **type checker** (mypy, pyright) verifies that **type annotations are consistent** — catching type mismatches that a linter won't find. Both are complementary; use both in CI.

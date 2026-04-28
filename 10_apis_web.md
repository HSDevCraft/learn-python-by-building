# Module 10 — APIs and Web Development Basics

> **Level:** Intermediate–Advanced | **Estimated Time:** 7 hours | **Prerequisites:** Modules 01–09

---

## Learning Objectives

By the end of this module you will be able to:
- Make HTTP requests with `requests` and handle responses correctly
- Understand REST API design principles
- Build a production-quality REST API with FastAPI
- Implement authentication, validation, and error handling in an API
- Work with Pydantic for data validation
- Test API endpoints with `httpx` and pytest
- Understand async HTTP with `aiohttp` / `httpx`

---

## The Big Picture — APIs as System Boundaries

```
Every modern application is a network of services communicating over HTTP.
Understanding APIs means understanding how systems talk to each other.

Client (browser/mobile/CLI)
    │
    │  HTTP Request (verb + URL + headers + body)
    ▼
API Gateway / Load Balancer
    │
    ├── /users  → User Service (FastAPI)
    ├── /orders → Order Service (Flask)
    └── /search → Search Service (Elasticsearch)

Why REST?
  - Stateless: each request contains everything needed
  - Cacheable: GET responses can be cached by proxies
  - Uniform interface: same verbs everywhere
  - Platform-agnostic: any language can speak HTTP

Why FastAPI?
  - Async-first: handles thousands of concurrent connections
  - Auto-documentation: OpenAPI spec generated from type hints
  - Pydantic: input validation at the boundary (the most important place)
  - 3x faster than Flask for most workloads
```

---

## 10.1 HTTP Fundamentals

### Conceptual Foundation

HTTP (HyperText Transfer Protocol) is the language of the web. Every API call is an HTTP request → response cycle.

```
Client ──── Request ────► Server
              (method, URL, headers, body)

Client ◄─── Response ─── Server
              (status code, headers, body)
```

**HTTP Methods (verbs):**
| Method | Purpose | Idempotent? |
|--------|---------|-------------|
| GET | Retrieve a resource | Yes |
| POST | Create a new resource | No |
| PUT | Replace a resource entirely | Yes |
| PATCH | Partially update a resource | No |
| DELETE | Remove a resource | Yes |

**Status Codes:**
| Range | Meaning | Examples |
|-------|---------|---------|
| 2xx | Success | 200 OK, 201 Created, 204 No Content |
| 3xx | Redirect | 301 Moved, 304 Not Modified |
| 4xx | Client error | 400 Bad Request, 401 Unauthorized, 404 Not Found |
| 5xx | Server error | 500 Internal Server Error, 503 Service Unavailable |

---

## 10.2 `requests` — HTTP Client

```bash
pip install requests
```

```python
import requests
from requests.exceptions import RequestException, HTTPError, Timeout

BASE_URL = "https://jsonplaceholder.typicode.com"

# GET — retrieve data
response = requests.get(f"{BASE_URL}/posts/1", timeout=10)
response.raise_for_status()   # raises HTTPError for 4xx/5xx
post = response.json()        # decode JSON body
print(post["title"])

# GET with query parameters
params = {"userId": 1, "_limit": 5}
response = requests.get(f"{BASE_URL}/posts", params=params, timeout=10)
posts = response.json()
print(f"Fetched {len(posts)} posts")

# POST — create data
new_post = {"title": "My Post", "body": "Content here", "userId": 1}
response = requests.post(
    f"{BASE_URL}/posts",
    json=new_post,          # automatically sets Content-Type: application/json
    timeout=10,
)
response.raise_for_status()
created = response.json()
print(f"Created post with id={created['id']}")

# PUT — update data
updated = {"id": 1, "title": "Updated Title", "body": "New body", "userId": 1}
response = requests.put(f"{BASE_URL}/posts/1", json=updated, timeout=10)
response.raise_for_status()

# DELETE
response = requests.delete(f"{BASE_URL}/posts/1", timeout=10)
print(response.status_code)  # 200

# With authentication
response = requests.get(
    "https://api.github.com/user",
    headers={"Authorization": "Bearer YOUR_TOKEN"},
    timeout=10,
)

# Session — reuse connection + share headers/auth/cookies
with requests.Session() as session:
    session.headers.update({
        "Authorization": "Bearer YOUR_TOKEN",
        "Accept": "application/json",
    })
    user = session.get("https://api.github.com/user", timeout=10).json()
    repos = session.get("https://api.github.com/user/repos", timeout=10).json()
```

### Robust API Client Pattern

```python
import requests
import time
import logging
from typing import Any

logger = logging.getLogger(__name__)

class APIClient:
    """
    Production-quality HTTP client with retry, timeout, and error handling.
    """

    def __init__(self, base_url: str, api_key: str, timeout: int = 30,
                 max_retries: int = 3) -> None:
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.max_retries = max_retries
        self._session = requests.Session()
        self._session.headers.update({
            "Authorization": f"Bearer {api_key}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        })

    def _request(self, method: str, endpoint: str, **kwargs) -> Any:
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        last_error = None

        for attempt in range(1, self.max_retries + 1):
            try:
                response = self._session.request(
                    method, url, timeout=self.timeout, **kwargs
                )
                response.raise_for_status()
                return response.json()
            except requests.HTTPError as e:
                if e.response.status_code < 500:
                    raise    # 4xx errors are client errors, don't retry
                logger.warning("HTTP %d on attempt %d: %s", e.response.status_code, attempt, url)
                last_error = e
            except requests.Timeout:
                logger.warning("Timeout on attempt %d: %s", attempt, url)
                last_error = requests.Timeout(f"Request to {url} timed out")
            except requests.ConnectionError as e:
                logger.warning("Connection error on attempt %d: %s", attempt, e)
                last_error = e

            if attempt < self.max_retries:
                time.sleep(2 ** attempt)   # exponential backoff

        raise last_error

    def get(self, endpoint: str, **kwargs) -> Any:
        return self._request("GET", endpoint, **kwargs)

    def post(self, endpoint: str, data: dict, **kwargs) -> Any:
        return self._request("POST", endpoint, json=data, **kwargs)

    def put(self, endpoint: str, data: dict, **kwargs) -> Any:
        return self._request("PUT", endpoint, json=data, **kwargs)

    def delete(self, endpoint: str, **kwargs) -> Any:
        return self._request("DELETE", endpoint, **kwargs)
```

---

## 10.3 REST API Design Principles

```
# Resource-oriented URLs — nouns, not verbs
GET    /users          — list all users
POST   /users          — create a user
GET    /users/{id}     — get a specific user
PUT    /users/{id}     — replace a user
PATCH  /users/{id}     — partially update a user
DELETE /users/{id}     — delete a user

GET    /users/{id}/posts      — posts belonging to a user
POST   /users/{id}/posts      — create a post for a user

# Filtering, sorting, pagination via query params
GET /posts?status=published&sort=created_at&order=desc&page=2&limit=20

# Versioning
GET /api/v1/users
GET /api/v2/users     (breaking change → new version)
```

---

## 10.4 FastAPI — Building a REST API

```bash
pip install fastapi uvicorn[standard] pydantic
```

### Core Application

```python
# main.py
from contextlib import asynccontextmanager
from typing import Annotated
import uvicorn
from fastapi import FastAPI, HTTPException, Depends, status, Query
from pydantic import BaseModel, EmailStr, Field, field_validator
from datetime import datetime

# --- Pydantic Models (Schemas) ---

class UserCreate(BaseModel):
    """Schema for creating a new user — input validation."""
    name: str = Field(..., min_length=1, max_length=100, description="Full name")
    email: EmailStr
    age: int = Field(..., ge=0, le=150, description="Age in years")
    role: str = Field(default="user")

    @field_validator("role")
    @classmethod
    def validate_role(cls, v: str) -> str:
        allowed = {"user", "admin", "editor"}
        if v not in allowed:
            raise ValueError(f"Role must be one of {allowed}")
        return v

class UserUpdate(BaseModel):
    """Schema for updating a user — all fields optional."""
    name: str | None = Field(None, min_length=1, max_length=100)
    email: EmailStr | None = None
    age: int | None = Field(None, ge=0, le=150)

class UserResponse(BaseModel):
    """Schema for user API responses — never expose internal fields."""
    id: int
    name: str
    email: str
    age: int
    role: str
    created_at: datetime

    model_config = {"from_attributes": True}

# --- In-memory database (replace with a real DB in production) ---
_db: dict[int, dict] = {}
_next_id = 1

def get_user_or_404(user_id: int) -> dict:
    """Dependency: fetch user or raise 404."""
    if user_id not in _db:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User with id={user_id} not found",
        )
    return _db[user_id]

# --- App lifecycle ---

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown logic."""
    print("Starting up: connecting to database...")
    yield
    print("Shutting down: closing connections...")

# --- App ---

app = FastAPI(
    title="User Management API",
    description="CRUD API for managing users",
    version="1.0.0",
    lifespan=lifespan,
)

# --- Routes ---

@app.get("/health", tags=["system"])
async def health_check() -> dict:
    """Health check endpoint for load balancers."""
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.get("/users", response_model=list[UserResponse], tags=["users"])
async def list_users(
    role: str | None = Query(None, description="Filter by role"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
) -> list[dict]:
    """List users with optional filtering and pagination."""
    users = list(_db.values())
    if role:
        users = [u for u in users if u["role"] == role]
    return users[offset : offset + limit]

@app.post("/users", response_model=UserResponse,
          status_code=status.HTTP_201_CREATED, tags=["users"])
async def create_user(user_data: UserCreate) -> dict:
    """Create a new user."""
    global _next_id
    # Check for duplicate email
    if any(u["email"] == user_data.email for u in _db.values()):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Email {user_data.email} already registered",
        )
    user = {
        "id": _next_id,
        **user_data.model_dump(),
        "created_at": datetime.utcnow(),
    }
    _db[_next_id] = user
    _next_id += 1
    return user

@app.get("/users/{user_id}", response_model=UserResponse, tags=["users"])
async def get_user(
    user: Annotated[dict, Depends(get_user_or_404)]
) -> dict:
    """Get a specific user by ID."""
    return user

@app.patch("/users/{user_id}", response_model=UserResponse, tags=["users"])
async def update_user(
    update_data: UserUpdate,
    user: Annotated[dict, Depends(get_user_or_404)],
) -> dict:
    """Partially update a user."""
    updated_fields = update_data.model_dump(exclude_none=True)
    user.update(updated_fields)
    return user

@app.delete("/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT, tags=["users"])
async def delete_user(
    user: Annotated[dict, Depends(get_user_or_404)],
) -> None:
    """Delete a user."""
    del _db[user["id"]]

# --- Run ---
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
```

```bash
uvicorn main:app --reload
# API docs: http://localhost:8000/docs (Swagger UI)
# API docs: http://localhost:8000/redoc (ReDoc)
# OpenAPI schema: http://localhost:8000/openapi.json
```

---

## 10.5 Middleware and Global Error Handling

```python
from fastapi import Request
from fastapi.responses import JSONResponse
import time

# Middleware — runs around every request
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    elapsed = time.perf_counter() - start
    response.headers["X-Process-Time"] = f"{elapsed:.4f}"
    return response

# Global exception handler
@app.exception_handler(ValueError)
async def value_error_handler(request: Request, exc: ValueError):
    return JSONResponse(
        status_code=422,
        content={"detail": str(exc), "type": "validation_error"},
    )
```

---

## 10.6 Testing FastAPI Applications

```bash
pip install httpx pytest-asyncio
```

```python
# tests/test_api.py
import pytest
from httpx import AsyncClient, ASGITransport
from main import app

@pytest.fixture
async def client():
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test"
    ) as c:
        yield c

@pytest.mark.asyncio
async def test_health_check(client):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

@pytest.mark.asyncio
async def test_create_user(client):
    response = await client.post("/users", json={
        "name": "Alice Smith",
        "email": "alice@example.com",
        "age": 30,
    })
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Alice Smith"
    assert data["id"] is not None

@pytest.mark.asyncio
async def test_create_user_invalid_email(client):
    response = await client.post("/users", json={
        "name": "Bob",
        "email": "not-an-email",
        "age": 25,
    })
    assert response.status_code == 422   # Pydantic validation error

@pytest.mark.asyncio
async def test_get_nonexistent_user(client):
    response = await client.get("/users/99999")
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_full_crud_workflow(client):
    # Create
    create_resp = await client.post("/users", json={
        "name": "Carol", "email": "carol@ex.com", "age": 28
    })
    user_id = create_resp.json()["id"]

    # Read
    get_resp = await client.get(f"/users/{user_id}")
    assert get_resp.json()["name"] == "Carol"

    # Update
    patch_resp = await client.patch(f"/users/{user_id}", json={"name": "Carol Updated"})
    assert patch_resp.json()["name"] == "Carol Updated"

    # Delete
    del_resp = await client.delete(f"/users/{user_id}")
    assert del_resp.status_code == 204

    # Verify deleted
    get_resp = await client.get(f"/users/{user_id}")
    assert get_resp.status_code == 404
```

---

## 10.7 Async HTTP with `httpx`

```python
import asyncio
import httpx

async def fetch_all(urls: list[str]) -> list[dict]:
    """Fetch multiple URLs concurrently."""
    async with httpx.AsyncClient(timeout=10) as client:
        tasks = [client.get(url) for url in urls]
        responses = await asyncio.gather(*tasks, return_exceptions=True)

    results = []
    for url, response in zip(urls, responses):
        if isinstance(response, Exception):
            results.append({"url": url, "error": str(response)})
        else:
            results.append({"url": url, "status": response.status_code})
    return results

# Run the async function
urls = [
    "https://httpbin.org/get",
    "https://httpbin.org/status/200",
    "https://httpbin.org/status/404",
]
results = asyncio.run(fetch_all(urls))
for r in results:
    print(r)
```

---

## Best Practices

1. **Always set timeouts** on HTTP requests — never `requests.get(url)` without `timeout=`.
2. **Use `response.raise_for_status()`** before processing the response body.
3. **Use `requests.Session()`** when making multiple requests to the same host.
4. **Validate all input** with Pydantic — never trust user-provided data.
5. **Never return raw database models** — use separate response schemas.
6. **Use dependency injection** (`Depends`) for shared logic (auth, DB, etc.) in FastAPI.
7. **Return proper HTTP status codes** — 201 for creation, 204 for delete, 404 for not found.
8. **Test the API, not the implementation** — make HTTP requests in tests as a real client would.
9. **Use `httpx`** (supports both sync and async) over `requests` for new projects.

---

## Exercises

### Exercise 10.1 — GitHub API Explorer
Write a script that fetches a GitHub user's profile and their top-5 most-starred repositories.

**Solution:**
```python
import requests

def get_github_summary(username: str) -> dict:
    """Fetch GitHub user summary and top starred repos."""
    with requests.Session() as session:
        session.headers["Accept"] = "application/vnd.github+json"

        user_resp = session.get(f"https://api.github.com/users/{username}", timeout=10)
        user_resp.raise_for_status()
        user = user_resp.json()

        repos_resp = session.get(
            f"https://api.github.com/users/{username}/repos",
            params={"sort": "stars", "per_page": 5},
            timeout=10,
        )
        repos_resp.raise_for_status()
        repos = repos_resp.json()

    return {
        "name": user.get("name"),
        "followers": user["followers"],
        "public_repos": user["public_repos"],
        "top_repos": [
            {"name": r["name"], "stars": r["stargazers_count"]}
            for r in repos
        ],
    }

summary = get_github_summary("torvalds")
print(f"Name: {summary['name']}")
print(f"Followers: {summary['followers']:,}")
for repo in summary["top_repos"]:
    print(f"  {repo['name']}: ⭐ {repo['stars']:,}")
```

---

### Exercise 10.2 — Products API (Mini Project)
Build a FastAPI CRUD API for a product catalog. Products have: `id`, `name`, `price`, `category`, `in_stock`. Include pagination, filtering by category, and validation that price > 0.

---

## Interview Prep — Top Questions for APIs and Web

**Q1: What makes an API RESTful?**
6 constraints: **Stateless** (each request contains all needed info — no server-side session), **Client-Server** separation, **Cacheable** (GET responses declare cacheability), **Uniform Interface** (resources identified by URIs, standard methods), **Layered System** (client can't tell if it's hitting a server or a proxy), **Code on Demand** (optional: server can send executable code). Statelessness is the most important — it enables horizontal scaling.

**Q2: What is the difference between PUT and PATCH?**
PUT replaces the **entire resource** — you must send all fields. PATCH applies a **partial update** — only send the fields to change. PUT is idempotent (same request twice = same result). PATCH can be non-idempotent. In practice: always use PATCH for partial updates (saves bandwidth and avoids accidentally zeroing un-sent fields).

**Q3: Explain FastAPI's dependency injection system.**
`Depends(my_func)` in a route parameter tells FastAPI to call `my_func` before the route handler and inject the return value. Dependencies are cached per request (unless `use_cache=False`). Supports: auth token extraction, DB session management, rate limiting, permission checks. Dependencies can depend on other dependencies — FastAPI builds a directed acyclic graph and resolves in order.

**Q4: How does Pydantic v2 validate data? What happens on validation failure?**
Pydantic creates a C-extension validator from your model's type annotations and `Field()` constraints. On validation, it coerces compatible types (e.g., `"42"` → `int(42)`) and rejects incompatible ones. On failure, raises `ValidationError` with a list of all errors (field, value, error type). FastAPI automatically returns these as HTTP 422 Unprocessable Entity with a structured JSON body.

**Q5: What is idempotency and which HTTP methods should be idempotent?**
An operation is **idempotent** if executing it multiple times produces the same result as executing it once. GET, PUT, DELETE should be idempotent. POST is NOT idempotent (each call creates a new resource). PATCH technically isn't guaranteed idempotent. Idempotency is critical for retry logic — if a network timeout causes you to retry a request, idempotent requests are safe to retry; POST creates duplicates.

**Q6: How do you test a FastAPI application without running an actual server?**
Use `httpx.AsyncClient` with `ASGITransport(app=app)` and `base_url="http://test"`. This makes real HTTP requests but in-process (no network, no port binding). Much faster than spinning up a server, works in CI. Use `@pytest.fixture` to create the client and `@pytest.mark.asyncio` for async tests. This tests the full middleware/route stack.

**Q7: What is the difference between synchronous and asynchronous endpoints in FastAPI?**
FastAPI runs `async def` routes in the event loop directly (non-blocking). `def` (sync) routes are run in a separate thread pool via `asyncio.run_in_executor()`. Use `async def` for I/O operations (DB queries, HTTP calls) using async drivers. Use `def` for CPU-bound or sync-only code. Mixing wrong (blocking I/O in `async def`) will starve the event loop.

**Q8: What HTTP status code should a DELETE return when the resource is already deleted?**
Two valid answers: **204 No Content** (idempotent — deleting again returns same success) or **404 Not Found** (the resource doesn't exist). The 204 approach is preferred for idempotent APIs where clients may retry. 404 is technically more accurate on the second call. Whichever you choose, be **consistent** and document it.

---

## Module Summary

| Concept | Key Takeaway |
|---------|-------------|
| HTTP methods | GET=read, POST=create, PUT=replace, PATCH=partial, DELETE=remove |
| `requests` | Simple sync HTTP client; always use `timeout` and `raise_for_status()` |
| `httpx` | Modern sync/async HTTP client |
| FastAPI | Async-first Python web framework; auto-docs from type hints |
| Pydantic | Data validation at API boundary; use `Field()` for constraints |
| `Depends()` | FastAPI dependency injection for shared logic |
| HTTP status codes | 2xx success, 4xx client error, 5xx server error |
| Testing | Use `httpx.AsyncClient` with `ASGITransport` for FastAPI tests |

---

## Quiz

1. What is the difference between PUT and PATCH in HTTP?
2. Why should you always set `timeout=` on HTTP requests?
3. What does `response.raise_for_status()` do?
4. What HTTP status code should a successful POST return?
5. What is the purpose of Pydantic's `Field(..., ge=0)`?
6. How does FastAPI's `Depends()` mechanism work?
7. What is the difference between `requests.get()` and a `requests.Session().get()`?
8. What does `model_dump(exclude_none=True)` do in Pydantic?
9. Why should you have separate request and response schemas?
10. What is ASGI and how does it differ from WSGI?

**Answers:**
1. PUT replaces the entire resource with the provided data (all fields required). PATCH partially updates a resource — only the fields you provide are changed. PUT is idempotent; PATCH semantically can be non-idempotent.
2. Without a timeout, a request can hang forever if the server is unresponsive. This blocks the thread (or event loop coroutine), eventually exhausting connection pools and crashing the application under load.
3. `raise_for_status()` raises `requests.HTTPError` if the response has a 4xx or 5xx status code. Without it, `requests` silently succeeds even for error responses — you'd need to check `response.status_code` manually.
4. `201 Created`. The response body should contain the created resource, and ideally a `Location` header pointing to the new resource's URL.
5. `Field(..., ge=0)` adds a validation constraint: the field is required (`...`) and must be **g**reater than or **e**qual to 0. Pydantic raises a `ValidationError` if a value doesn't meet this constraint.
6. When FastAPI sees `Depends(my_func)` in a route parameter, it calls `my_func` and injects its return value into the route. If `my_func` is a generator with `yield`, everything before `yield` is setup and after `yield` is teardown (like a fixture). Dependencies can depend on other dependencies.
7. `requests.get()` creates a new connection for each request. `Session().get()` reuses a connection pool (TCP keep-alive), shares headers/cookies/auth across requests, and is significantly more efficient for multiple calls to the same host.
8. `model_dump(exclude_none=True)` serializes the model to a dict, excluding any fields that are `None`. This is used for PATCH operations so that only explicitly provided fields are included in the update — `None` means "not provided", not "set to null".
9. Request schemas validate what comes IN (strict, minimal — only accept what you need). Response schemas control what goes OUT (never expose internal IDs, passwords, or implementation details). Mixing them would expose sensitive fields or accept fields that should be read-only.
10. ASGI (Asynchronous Server Gateway Interface) supports async Python web frameworks (FastAPI, Starlette). WSGI (Web Server Gateway Interface) is synchronous-only (Flask, Django). ASGI can handle WebSockets and long-polling; WSGI cannot. Uvicorn is an ASGI server; Gunicorn is typically WSGI.

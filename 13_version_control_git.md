# Module 13 — Version Control with Git

> **Level:** All Levels | **Estimated Time:** 4 hours | **Prerequisites:** Module 07

---

## Learning Objectives

By the end of this module you will be able to:
- Understand Git's data model (blobs, trees, commits, refs)
- Use the core Git workflow: stage, commit, push, pull
- Work with branches: create, merge, rebase, delete
- Resolve merge conflicts confidently
- Write meaningful commit messages
- Apply Git best practices for Python projects
- Use GitHub for collaboration: pull requests, code review, issues
- Integrate Git with Python tooling (hooks, pre-commit)

---

## 13.1 Git's Data Model

### Conceptual Foundation

Git is not a backup system or a file tracker — it is a **content-addressed file system**. Every object is identified by the SHA-1 hash of its content:

- **Blob** — file content (just bytes, no filename)
- **Tree** — directory listing (maps names → blobs/trees)
- **Commit** — snapshot of the entire tree + parent commit + metadata
- **Ref** (branch/tag) — a named pointer to a commit

```
Working Directory → (git add) → Staging Area → (git commit) → Local Repository → (git push) → Remote
```

Every commit is **immutable** — it stores a snapshot, not a diff. This is why Git operations are fast and reliable.

---

## 13.2 Initial Setup

```bash
# Configure your identity (stored in ~/.gitconfig)
git config --global user.name "Alice Smith"
git config --global user.email "alice@example.com"
git config --global core.editor "code --wait"    # VS Code as editor
git config --global init.defaultBranch main
git config --global pull.rebase false             # merge on pull (team preference)

# Useful aliases
git config --global alias.st "status -sb"
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.co "checkout"
git config --global alias.br "branch"

# View your config
git config --list --global
```

---

## 13.3 Core Workflow

```bash
# Initialize a new repository
mkdir my_project && cd my_project
git init

# Check status
git status

# Stage files
git add main.py                  # stage a specific file
git add src/                     # stage a directory
git add .                        # stage all changes (use carefully!)
git add -p                       # interactively stage chunks (recommended!)

# Commit
git commit -m "Add initial user authentication module"
git commit                       # opens editor for multi-line message

# View history
git log --oneline                # compact view
git log --oneline --graph --all  # show branches as graph
git show HEAD                    # show most recent commit

# Unstage a file
git restore --staged main.py

# Discard working directory changes
git restore main.py              # revert to last commit (DESTRUCTIVE)

# Connect to remote
git remote add origin https://github.com/user/repo.git
git remote -v                    # verify

# Push
git push -u origin main          # first push: sets upstream tracking
git push                         # subsequent pushes

# Pull (fetch + merge)
git pull

# Fetch (download changes, don't merge)
git fetch origin
git diff main origin/main       # see what changed on remote
```

---

## 13.4 Writing Good Commit Messages

A commit message has two parts: a **subject** and an optional **body**.

```
type(scope): short summary in imperative mood (max 72 chars)

Longer description if needed. Explain WHY this change was made,
not WHAT — the diff shows what. Reference issues or PRs.

Refs: #123
Breaking-Change: renamed get_user() to fetch_user()
```

**Types** (Conventional Commits standard):
| Type | When to use |
|------|------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change (no feature, no bug) |
| `test` | Adding or updating tests |
| `chore` | Build, CI, config changes |
| `perf` | Performance improvement |

**Good commit messages:**
```
feat(auth): add JWT token refresh mechanism
fix(api): return 404 instead of 500 for missing users
refactor(db): extract query builder into separate class
test(user): add parametrized tests for email validation
docs(readme): update installation instructions for Python 3.11
```

**Bad commit messages:**
```
fix stuff
WIP
changes
update
done
```

---

## 13.5 Branching Strategy

```bash
# Create and switch to a new branch
git checkout -b feature/user-authentication
# or
git switch -c feature/user-authentication

# List branches
git branch          # local branches
git branch -r       # remote branches
git branch -a       # all branches

# Switch branches
git switch main

# Merge feature branch into main
git switch main
git merge feature/user-authentication

# Fast-forward merge (linear history, no merge commit)
git merge --ff-only feature/simple-fix

# Merge with commit (preserves branch history)
git merge --no-ff feature/user-authentication

# Rebase — replay commits onto a new base (linear history)
git switch feature/user-authentication
git rebase main           # replay feature commits on top of latest main
git switch main
git merge --ff-only feature/user-authentication  # now fast-forward

# Delete a branch
git branch -d feature/user-authentication    # after merge
git branch -D feature/user-authentication    # force delete (unmerged)
git push origin --delete feature/user-authentication  # delete remote branch
```

### Standard Branch Model (GitHub Flow)

```
main ─────────────────────────────────────────────────────
        \                        /
         feature/login──────────
              \
               hotfix/sql-injection─────────(merge directly to main)
```

**GitHub Flow:**
1. `main` is always deployable
2. Work on feature branches
3. Open pull request from feature branch → main
4. Discuss and review in the PR
5. Deploy from the feature branch to test
6. Merge to main → deploy to production

---

## 13.6 Resolving Merge Conflicts

A conflict occurs when two branches modify the same lines. Git marks the conflict in the file:

```python
# conflicted file: src/config.py

<<<<<<< HEAD
DATABASE_URL = "postgresql://localhost/mydb"
MAX_CONNECTIONS = 10
=======
DATABASE_URL = "postgresql://prod-server/mydb"
MAX_CONNECTIONS = 50
TIMEOUT = 30
>>>>>>> feature/production-config
```

**Resolution steps:**
```bash
# 1. See which files have conflicts
git status

# 2. Open the conflicted file and choose the correct version
#    (edit manually, or use your editor's conflict resolution tool)
# The result should be:
# DATABASE_URL = "postgresql://prod-server/mydb"
# MAX_CONNECTIONS = 50
# TIMEOUT = 30

# 3. Stage the resolved file
git add src/config.py

# 4. Complete the merge
git merge --continue
# or
git commit

# To abort the merge and go back to where you were:
git merge --abort
```

---

## 13.7 Undoing Changes

```bash
# View previous commits
git log --oneline -10

# --- Before committing ---
git restore file.py              # discard working directory change
git restore --staged file.py     # unstage (keep working dir change)

# --- After committing ---

# Undo last commit but keep changes staged
git reset --soft HEAD~1

# Undo last commit and unstage changes (changes remain in working dir)
git reset HEAD~1
# or:
git reset --mixed HEAD~1

# Undo last commit and DISCARD changes (DESTRUCTIVE)
git reset --hard HEAD~1

# --- Safe undo: git revert (creates a new commit that undoes) ---
# Use this for commits that have already been pushed to remote
git revert HEAD                  # undo most recent commit
git revert abc1234               # undo a specific commit by hash

# --- Cherry-pick: apply a commit from another branch ---
git cherry-pick abc1234

# --- Stash: temporarily save changes ---
git stash                        # save working dir changes
git stash save "WIP: login form validation"
git stash list                   # view stashes
git stash pop                    # apply most recent stash + delete it
git stash apply stash@{1}        # apply a specific stash (keep it)
git stash drop stash@{0}         # delete a stash
```

---

## 13.8 Python-Specific Git Practices

### `.gitignore` for Python Projects

```gitignore
# Python bytecode
__pycache__/
*.py[cod]
*$py.class
*.pyc

# Distribution / packaging
dist/
build/
*.egg-info/
*.egg
MANIFEST

# Virtual environments
.venv/
venv/
env/
ENV/

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/
.mypy_cache/
.ruff_cache/

# Jupyter
.ipynb_checkpoints/
*.ipynb_checkpoints

# Environment variables / secrets
.env
.env.local
.env.*.local
*.pem
*.key

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
```

### Pre-commit Hooks

```bash
pip install pre-commit
```

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-json
      - id: check-merge-conflict
      - id: detect-private-key

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.6
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.7.1
    hooks:
      - id: mypy
        additional_dependencies: [pydantic]

  - repo: local
    hooks:
      - id: pytest
        name: pytest (fast tests only)
        entry: pytest -m "not slow" --tb=short
        language: system
        pass_filenames: false
        always_run: true
```

```bash
# Install hooks into .git/hooks/
pre-commit install

# Run all hooks manually
pre-commit run --all-files

# Skip hooks (emergency only)
git commit --no-verify -m "emergency fix"
```

---

## 13.9 GitHub Collaboration Workflow

### Pull Request Checklist

Before opening a PR:
- [ ] Branch is up-to-date with `main`
- [ ] All tests pass locally
- [ ] Pre-commit hooks pass
- [ ] New functionality has tests
- [ ] Code is documented
- [ ] CHANGELOG or PR description updated

### Useful GitHub CLI Commands

```bash
# Install GitHub CLI
# https://cli.github.com

# Create a PR
gh pr create --title "feat: add user authentication" --body "Closes #42"

# List open PRs
gh pr list

# Check out a PR for review
gh pr checkout 123

# Approve and merge
gh pr review 123 --approve
gh pr merge 123 --squash

# Create an issue
gh issue create --title "Bug: login fails on Safari" --label bug
```

---

## 13.10 Advanced Git

```bash
# Interactive rebase — rewrite history (only for local, unpushed commits!)
git rebase -i HEAD~5             # squash/edit/reorder last 5 commits
# Commands: pick, squash, fixup, edit, reword, drop

# bisect — binary search to find which commit introduced a bug
git bisect start
git bisect bad HEAD              # current commit is broken
git bisect good v1.2.0           # v1.2.0 was fine
# Git checks out a commit — test it, then:
git bisect good   # or: git bisect bad
# Repeat until git identifies the first bad commit
git bisect reset  # cleanup

# reflog — Git's safety net (shows all recent HEAD movements)
git reflog                       # if you accidentally delete a branch
git checkout HEAD@{3}            # recover to a previous state

# worktree — check out multiple branches simultaneously
git worktree add ../project-hotfix hotfix/security-patch
# work in ../project-hotfix without disturbing your main checkout
```

---

## Best Practices

1. **Commit small and often** — easier to review, revert, and understand.
2. **Use feature branches** — never commit directly to `main`.
3. **Write meaningful commit messages** — your future self will thank you.
4. **Use `git add -p`** — stage only related changes in each commit.
5. **Keep `main` deployable at all times**.
6. **Never force-push to shared branches** — use `git revert` instead.
7. **Use `.gitignore` before your first commit** — removing files from history is painful.
8. **Squash WIP commits before merging** — keep project history clean.
9. **Use pre-commit hooks** — catch issues before they reach CI.

---

## Exercises

### Exercise 13.1 — Repository Archaeology
Clone an open source Python repository (e.g., `git clone https://github.com/pallets/flask.git`). Then:
1. Find the commit that introduced the `@app.route()` decorator using `git log --all -S '@app.route'`
2. Use `git blame src/flask/app.py` to see who last modified each line
3. Use `git log --since="1 year ago" --author="Armin"` to see contributions

### Exercise 13.2 — Conflict Resolution Practice
1. Create a repo with `conflict_demo.py` containing `VERSION = "1.0.0"`
2. Create branch `feature/v2` and change it to `VERSION = "2.0.0"`
3. On `main`, change it to `VERSION = "1.5.0"`
4. Merge `feature/v2` into `main` — resolve the conflict to `VERSION = "2.0.0"`

### Exercise 13.3 — Pre-commit Setup
Set up a Python project with pre-commit hooks that run: `ruff`, `ruff-format`, and `pytest`. Commit a file with a lint error and verify the hook prevents the commit.

---

## Module Summary

| Concept | Key Takeaway |
|---------|-------------|
| Git objects | Blobs → Trees → Commits → Refs (all content-addressed) |
| Staging area | Allows partial commits; use `git add -p` for fine control |
| Branches | Lightweight pointers to commits; cheap to create |
| Merge vs Rebase | Merge preserves history; Rebase creates linear history |
| `git revert` | Safe undo for pushed commits (creates new commit) |
| `git reset` | Rewrites history; only safe for local unpushed commits |
| Pre-commit hooks | Automate quality checks before every commit |
| GitHub Flow | `main` always deployable; work in feature branches + PRs |

---

## Quiz

1. What is the difference between `git merge` and `git rebase`?
2. What does `git reset --soft HEAD~1` do to your working directory?
3. Why should you never `git reset --hard` on pushed commits?
4. What does `git stash` do, and when would you use it?
5. What is a fast-forward merge and when does it occur?
6. What is the purpose of `git add -p`?
7. When would you use `git revert` instead of `git reset`?
8. What does `git bisect` help you find?
9. What is a `.gitignore` file and where should it be committed?
10. What does `git reflog` show that `git log` does not?

# Python Mastery: Beginner to Production-Ready Developer

> A comprehensive, end-to-end Python course for software development, data science, and AI roles.

[![CI](https://github.com/yourusername/python-course/workflows/CI/badge.svg)](https://github.com/yourusername/python-course/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/Python-3.8%2B-blue)](https://www.python.org/downloads/)
[![Modules: 15](https://img.shields.io/badge/Modules-15-brightgreen)](./README.md)
[![Projects: 11](https://img.shields.io/badge/Projects-11-orange)](./PROJECTS.md)

---

## Course Philosophy

This course is built on three pillars:
1. **Conceptual depth** — understand *why*, not just *how*
2. **Practical application** — every concept is grounded in real-world use cases
3. **Industry alignment** — workflows, standards, and patterns used by professional engineers

---

## Course Structure

| Module | Title | Level | Est. Time |
|--------|-------|-------|-----------|
| 01 | [Python Fundamentals](./01_python_fundamentals.md) | Beginner | 6h |
| 02 | [Functions and Scope](./02_functions_and_scope.md) | Beginner | 5h |
| 03 | [Data Structures](./03_data_structures.md) | Beginner–Intermediate | 6h |
| 04 | [Object-Oriented Programming](./04_oop.md) | Intermediate | 8h |
| 05 | [File Handling & Exceptions](./05_file_handling_exceptions.md) | Intermediate | 5h |
| 06 | [Standard Library & Packages](./06_standard_library.md) | Intermediate | 5h |
| 07 | [Virtual Environments & Dependencies](./07_virtual_envs_packages.md) | Intermediate | 3h |
| 08 | [Testing with pytest](./08_testing.md) | Intermediate | 6h |
| 09 | [Debugging & Performance](./09_debugging_performance.md) | Intermediate–Advanced | 5h |
| 10 | [APIs & Web Development](./10_apis_web.md) | Intermediate–Advanced | 7h |
| 11 | [Data Analysis: NumPy & Pandas](./11_data_analysis.md) | Intermediate–Advanced | 8h |
| 12 | [Scripting & Automation](./12_scripting_automation.md) | Intermediate | 5h |
| 13 | [Version Control with Git](./13_version_control_git.md) | All Levels | 4h |
| 14 | [Production-Ready Code](./14_production_code.md) | Advanced | 6h |
| 15 | [Algorithms & Data Structures](./15_algorithms_dsa.md) | Advanced | 10h |
| — | [Projects & Capstones](./PROJECTS.md) | All Levels | 20h+ |

**Total estimated time:** ~100 hours of structured learning

---

## Learning Paths

### Path A — Software Developer (Backend/Scripting)
`01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 13 → 14`

### Path B — Data Scientist / ML Engineer
`01 → 02 → 03 → 04 → 05 → 06 → 07 → 11 → 08 → 09 → 13 → 14`

### Path C — AI / LLM Engineer
`01 → 02 → 03 → 04 → 05 → 07 → 10 → 11 → 08 → 14 → 15`

### Path D — Full Course (All Roles)
Follow modules 01–15 in sequence, then complete the capstone projects.

---

## Prerequisites

- A computer with Python 3.10+ installed
- A code editor (VS Code recommended)
- No prior programming experience required for modules 01–03
- Modules 10+ assume comfort with core Python

---

## How to Use This Course

Each module contains:
- **Learning Objectives** — what you will be able to do after completing the module
- **Conceptual Foundation** — the *why* behind each topic
- **Code Examples** — clean, annotated, runnable Python code
- **Best Practices** — industry-standard patterns and anti-patterns
- **Exercises** — progressively harder problems with full solutions
- **Mini-Project** — a self-contained real-world task
- **Module Summary** — key takeaways at a glance
- **Quiz** — 5–10 questions to test understanding

---

## Environment Setup

```bash
# Install Python 3.11+
# https://www.python.org/downloads/

# Verify installation
python --version

# Create a course workspace
mkdir python_course && cd python_course
python -m venv .venv

# Activate (Linux/macOS)
source .venv/bin/activate

# Activate (Windows)
.venv\Scripts\activate

# Install core packages used throughout the course
pip install pytest pytest-cov black ruff mypy ipython requests fastapi uvicorn numpy pandas
```

---

## Recommended Tools

| Tool | Purpose |
|------|---------|
| VS Code + Pylance | Editor + IntelliSense |
| Black | Auto-formatter |
| Ruff | Fast linter |
| Mypy | Static type checker |
| pytest | Testing framework |
| IPython | Interactive REPL |
| Git | Version control |

---

## Course Conventions

All code examples follow these standards:
- **PEP 8** style
- **Type hints** on all function signatures
- **Docstrings** on all public functions and classes
- No magic numbers — constants are named
- Errors are explicit, never silenced with bare `except`

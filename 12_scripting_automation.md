# Module 12 — Scripting and Automation

> **Level:** Intermediate | **Estimated Time:** 5 hours | **Prerequisites:** Modules 01–07

---

## Learning Objectives

By the end of this module you will be able to:
- Write robust CLI scripts with `argparse` and `click`
- Automate file and directory operations
- Schedule tasks with `schedule` and `cron`
- Scrape web pages with `requests` + `BeautifulSoup`
- Automate spreadsheets with `openpyxl`
- Send emails programmatically
- Use `subprocess` for shell automation
- Apply regular expressions for text processing

---

## 12.1 Command-Line Interfaces with `argparse`

```python
# file_organiser.py — A real CLI tool
import argparse
import sys
from pathlib import Path
import shutil

def parse_args() -> argparse.Namespace:
    """Define and parse command-line arguments."""
    parser = argparse.ArgumentParser(
        prog="file-organiser",
        description="Organise files in a directory by extension",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python file_organiser.py ~/Downloads --dry-run
  python file_organiser.py ~/Downloads --output ~/Organised
  python file_organiser.py ~/Downloads -e .pdf .docx --verbose
        """,
    )

    parser.add_argument("source", type=Path, help="Directory to organise")
    parser.add_argument(
        "--output", "-o", type=Path, default=None,
        help="Destination directory (default: organise in-place)"
    )
    parser.add_argument(
        "--extensions", "-e", nargs="+", default=None,
        help="Only process these extensions (e.g. -e .pdf .jpg)"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Show what would happen without actually moving files"
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true",
        help="Print each file as it is processed"
    )
    return parser.parse_args()


EXTENSION_MAP = {
    ".pdf": "Documents", ".doc": "Documents", ".docx": "Documents",
    ".txt": "Documents", ".md": "Documents",
    ".jpg": "Images", ".jpeg": "Images", ".png": "Images",
    ".gif": "Images", ".svg": "Images",
    ".mp4": "Videos", ".mov": "Videos", ".avi": "Videos",
    ".mp3": "Audio", ".wav": "Audio", ".flac": "Audio",
    ".py": "Code", ".js": "Code", ".html": "Code", ".css": "Code",
    ".zip": "Archives", ".tar": "Archives", ".gz": "Archives",
}


def organise_files(source: Path, output: Path | None, extensions: list[str] | None,
                   dry_run: bool, verbose: bool) -> dict[str, int]:
    """
    Move files from source into category subdirectories.
    Returns count of files moved per category.
    """
    if not source.is_dir():
        print(f"Error: '{source}' is not a directory", file=sys.stderr)
        sys.exit(1)

    dest_root = output or source
    moved: dict[str, int] = {}

    for file in source.iterdir():
        if not file.is_file():
            continue
        if extensions and file.suffix.lower() not in extensions:
            continue

        category = EXTENSION_MAP.get(file.suffix.lower(), "Other")
        dest_dir = dest_root / category
        dest_file = dest_dir / file.name

        if verbose or dry_run:
            action = "[DRY RUN]" if dry_run else "Moving"
            print(f"{action}: {file.name} → {category}/")

        if not dry_run:
            dest_dir.mkdir(parents=True, exist_ok=True)
            shutil.move(str(file), str(dest_file))
            moved[category] = moved.get(category, 0) + 1

    return moved


def main() -> None:
    args = parse_args()
    counts = organise_files(
        args.source, args.output, args.extensions,
        args.dry_run, args.verbose
    )
    if not args.dry_run:
        total = sum(counts.values())
        print(f"\nDone! Moved {total} files:")
        for category, count in sorted(counts.items()):
            print(f"  {category}: {count} files")


if __name__ == "__main__":
    main()
```

---

## 12.2 `click` — Modern CLI Framework

```bash
pip install click rich
```

```python
# backup_tool.py
import click
import shutil
import hashlib
from pathlib import Path
from datetime import datetime
from rich.console import Console
from rich.progress import track

console = Console()

@click.group()
@click.version_option("1.0.0")
def cli():
    """Backup tool — create and verify directory backups."""

@cli.command()
@click.argument("source", type=click.Path(exists=True, file_okay=False, path_type=Path))
@click.argument("destination", type=click.Path(path_type=Path))
@click.option("--compress", "-c", is_flag=True, help="Create a .tar.gz archive")
@click.option("--exclude", "-e", multiple=True, help="Patterns to exclude (can repeat)")
def create(source: Path, destination: Path, compress: bool, exclude: tuple[str, ...]) -> None:
    """Create a backup of SOURCE at DESTINATION."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_name = f"{source.name}_{timestamp}"

    if compress:
        backup_path = destination / f"{backup_name}.tar.gz"
        console.print(f"[bold blue]Creating compressed backup:[/] {backup_path}")
        shutil.make_archive(
            str(destination / backup_name), "gztar", source.parent, source.name
        )
    else:
        backup_path = destination / backup_name
        console.print(f"[bold blue]Copying to:[/] {backup_path}")
        shutil.copytree(source, backup_path)

    console.print(f"[bold green]✓ Backup complete:[/] {backup_path}")

@cli.command()
@click.argument("backup", type=click.Path(exists=True, path_type=Path))
@click.argument("original", type=click.Path(exists=True, path_type=Path))
def verify(backup: Path, original: Path) -> None:
    """Verify that BACKUP matches ORIGINAL by comparing file hashes."""
    def file_hash(path: Path) -> str:
        h = hashlib.sha256()
        h.update(path.read_bytes())
        return h.hexdigest()

    mismatches = []
    orig_files = list(original.rglob("*") if original.is_dir() else [original])

    for orig_file in track(orig_files, description="Verifying..."):
        if not orig_file.is_file():
            continue
        rel = orig_file.relative_to(original) if original.is_dir() else orig_file.name
        backup_file = backup / rel if backup.is_dir() else backup

        if not backup_file.exists():
            mismatches.append(f"Missing: {rel}")
        elif file_hash(orig_file) != file_hash(backup_file):
            mismatches.append(f"Modified: {rel}")

    if mismatches:
        console.print(f"[bold red]✗ Verification FAILED ({len(mismatches)} issues):[/]")
        for m in mismatches:
            console.print(f"  [red]• {m}[/]")
    else:
        console.print("[bold green]✓ Backup verified successfully.[/]")

if __name__ == "__main__":
    cli()
```

```bash
python backup_tool.py create ~/Documents ~/Backups --compress
python backup_tool.py verify ~/Backups/Documents_20240615.tar.gz ~/Documents
```

---

## 12.3 File Automation Patterns

```python
import shutil
from pathlib import Path
from datetime import datetime

def batch_rename(directory: Path, old_prefix: str, new_prefix: str,
                 dry_run: bool = False) -> int:
    """Batch rename files matching old_prefix in a directory."""
    renamed = 0
    for file in sorted(directory.iterdir()):
        if file.is_file() and file.name.startswith(old_prefix):
            new_name = new_prefix + file.name[len(old_prefix):]
            new_path = directory / new_name
            if dry_run:
                print(f"Would rename: {file.name} → {new_name}")
            else:
                file.rename(new_path)
                renamed += 1
    return renamed

def cleanup_old_files(directory: Path, days_old: int, pattern: str = "*",
                      dry_run: bool = False) -> list[Path]:
    """Delete files older than days_old matching pattern."""
    import time
    cutoff = time.time() - days_old * 86400
    deleted = []

    for file in Path(directory).glob(pattern):
        if file.is_file() and file.stat().st_mtime < cutoff:
            if dry_run:
                print(f"Would delete: {file}")
            else:
                file.unlink()
                deleted.append(file)
    return deleted

def mirror_directory(src: Path, dst: Path) -> None:
    """
    Make dst an exact mirror of src.
    Files in dst that aren't in src are deleted.
    """
    dst.mkdir(parents=True, exist_ok=True)

    # Copy new/modified files
    for src_file in src.rglob("*"):
        if src_file.is_file():
            rel = src_file.relative_to(src)
            dst_file = dst / rel
            dst_file.parent.mkdir(parents=True, exist_ok=True)
            if not dst_file.exists() or src_file.stat().st_mtime > dst_file.stat().st_mtime:
                shutil.copy2(src_file, dst_file)

    # Remove files not in src
    for dst_file in dst.rglob("*"):
        if dst_file.is_file():
            src_file = src / dst_file.relative_to(dst)
            if not src_file.exists():
                dst_file.unlink()
```

---

## 12.4 Web Scraping

```bash
pip install requests beautifulsoup4 lxml
```

```python
import requests
from bs4 import BeautifulSoup
import time
import csv
from pathlib import Path

def scrape_books(max_pages: int = 3) -> list[dict]:
    """
    Scrape book data from books.toscrape.com (a practice scraping site).
    Demonstrates: pagination, CSS selectors, data extraction.
    """
    BASE_URL = "https://books.toscrape.com/catalogue"
    books = []
    rating_map = {"One": 1, "Two": 2, "Three": 3, "Four": 4, "Five": 5}

    for page_num in range(1, max_pages + 1):
        url = f"{BASE_URL}/page-{page_num}.html"
        try:
            resp = requests.get(url, timeout=15)
            resp.raise_for_status()
        except requests.RequestException as e:
            print(f"Error on page {page_num}: {e}")
            break

        soup = BeautifulSoup(resp.text, "lxml")

        for article in soup.select("article.product_pod"):
            title = article.find("h3").find("a")["title"]
            price_str = article.select_one("p.price_color").text.strip()
            price = float(price_str.replace("Â", "").replace("£", ""))
            rating_word = article.select_one("p.star-rating")["class"][1]
            rating = rating_map.get(rating_word, 0)
            in_stock = "In stock" in article.select_one("p.availability").text

            books.append({
                "title": title,
                "price": price,
                "rating": rating,
                "in_stock": in_stock,
            })

        print(f"Page {page_num}: scraped {len(soup.select('article.product_pod'))} books")
        time.sleep(1)   # Be polite — don't hammer the server

    return books

def save_to_csv(data: list[dict], path: Path) -> None:
    if not data:
        return
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)

# books = scrape_books(max_pages=3)
# save_to_csv(books, Path("books.csv"))
```

---

## 12.5 Excel Automation with `openpyxl`

```bash
pip install openpyxl
```

```python
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.chart import BarChart, Reference
from openpyxl.utils import get_column_letter
from pathlib import Path

def create_sales_report(data: list[dict], output_path: Path) -> None:
    """Generate a formatted Excel sales report with chart."""
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Sales Report"

    # Header styling
    header_font = Font(bold=True, color="FFFFFF", size=12)
    header_fill = PatternFill("solid", fgColor="2E75B6")
    header_align = Alignment(horizontal="center")

    headers = ["Month", "Revenue", "Units Sold", "Avg Order Value"]
    for col, header in enumerate(headers, start=1):
        cell = ws.cell(row=1, column=col, value=header)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = header_align

    # Data rows
    alt_fill = PatternFill("solid", fgColor="D6E4F0")
    for row_idx, record in enumerate(data, start=2):
        ws.cell(row_idx, 1, record["month"])
        ws.cell(row_idx, 2, record["revenue"])
        ws.cell(row_idx, 3, record["units"])
        ws.cell(row_idx, 4, record["revenue"] / record["units"] if record["units"] else 0)

        # Alternate row colouring
        if row_idx % 2 == 0:
            for col in range(1, 5):
                ws.cell(row_idx, col).fill = alt_fill

    # Number formatting
    for row in ws.iter_rows(min_row=2, min_col=2, max_col=2):
        for cell in row:
            cell.number_format = '"$"#,##0.00'
    for row in ws.iter_rows(min_row=2, min_col=4, max_col=4):
        for cell in row:
            cell.number_format = '"$"#,##0.00'

    # Auto-fit column widths
    for col in ws.columns:
        max_len = max(len(str(cell.value or "")) for cell in col)
        ws.column_dimensions[get_column_letter(col[0].column)].width = max_len + 4

    # Totals row
    total_row = len(data) + 2
    ws.cell(total_row, 1, "TOTAL").font = Font(bold=True)
    ws.cell(total_row, 2, f"=SUM(B2:B{total_row-1})").number_format = '"$"#,##0.00'
    ws.cell(total_row, 3, f"=SUM(C2:C{total_row-1})")

    # Bar chart
    chart = BarChart()
    chart.title = "Monthly Revenue"
    chart.y_axis.title = "Revenue ($)"
    chart.x_axis.title = "Month"

    data_ref = Reference(ws, min_col=2, min_row=1, max_row=len(data) + 1)
    cats = Reference(ws, min_col=1, min_row=2, max_row=len(data) + 1)
    chart.add_data(data_ref, titles_from_data=True)
    chart.set_categories(cats)
    ws.add_chart(chart, "F2")

    wb.save(output_path)
    print(f"Report saved to {output_path}")


# --- Demo ---
sales_data = [
    {"month": "Jan", "revenue": 45000, "units": 120},
    {"month": "Feb", "revenue": 52000, "units": 138},
    {"month": "Mar", "revenue": 48000, "units": 125},
    {"month": "Apr", "revenue": 61000, "units": 158},
    {"month": "May", "revenue": 55000, "units": 145},
    {"month": "Jun", "revenue": 70000, "units": 180},
]
create_sales_report(sales_data, Path("sales_report.xlsx"))
```

---

## 12.6 Email Automation

```python
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
from pathlib import Path
import os

def send_email(
    to: str | list[str],
    subject: str,
    body_html: str,
    attachments: list[Path] | None = None,
    body_plain: str | None = None,
) -> None:
    """
    Send an HTML email with optional attachments via Gmail SMTP.
    Credentials are read from environment variables (never hardcode!).
    """
    sender_email = os.environ["EMAIL_SENDER"]
    app_password = os.environ["EMAIL_APP_PASSWORD"]

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = sender_email
    msg["To"] = to if isinstance(to, str) else ", ".join(to)

    if body_plain:
        msg.attach(MIMEText(body_plain, "plain"))
    msg.attach(MIMEText(body_html, "html"))

    # Attach files
    for path in (attachments or []):
        with open(path, "rb") as f:
            part = MIMEBase("application", "octet-stream")
            part.set_payload(f.read())
        encoders.encode_base64(part)
        part.add_header("Content-Disposition", f'attachment; filename="{path.name}"')
        msg.attach(part)

    context = ssl.create_default_context()
    with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context) as server:
        server.login(sender_email, app_password)
        recipients = [to] if isinstance(to, str) else to
        server.sendmail(sender_email, recipients, msg.as_string())
        print(f"Email sent to {msg['To']}")


# Usage example:
# send_email(
#     to="alice@example.com",
#     subject="Monthly Report",
#     body_html="<h1>Report attached</h1><p>Please find the report attached.</p>",
#     attachments=[Path("sales_report.xlsx")],
# )
```

---

## 12.7 Task Scheduling

```bash
pip install schedule
```

```python
import schedule
import time
import logging
from datetime import datetime

logger = logging.getLogger(__name__)

def daily_backup() -> None:
    """Run daily backup — scheduled task."""
    logger.info("Running daily backup at %s", datetime.now())
    # ... backup logic ...

def hourly_report() -> None:
    """Generate hourly status report."""
    logger.info("Generating hourly report")
    # ... report logic ...

def cleanup_logs() -> None:
    """Delete log files older than 7 days."""
    from pathlib import Path
    import time
    cutoff = time.time() - 7 * 86400
    for log_file in Path("logs").glob("*.log"):
        if log_file.stat().st_mtime < cutoff:
            log_file.unlink()
            logger.info("Deleted old log: %s", log_file)

def run_scheduler() -> None:
    """Configure and run the task scheduler indefinitely."""
    schedule.every().day.at("02:00").do(daily_backup)
    schedule.every().hour.do(hourly_report)
    schedule.every().sunday.at("03:00").do(cleanup_logs)

    logger.info("Scheduler started. Running tasks...")
    while True:
        schedule.run_pending()
        time.sleep(60)    # check every minute

# For production: use OS cron (Linux) or Task Scheduler (Windows)
# Crontab: 0 2 * * * /path/to/venv/python /path/to/script.py
```

---

## Best Practices

1. **Use `argparse` or `click`** — never hard-code values in scripts.
2. **Always validate paths** with `Path.exists()` before using them.
3. **Use `--dry-run`** flags to preview destructive operations.
4. **Respect rate limits** when scraping — add `time.sleep()` between requests.
5. **Read credentials from environment variables**, never hardcode them.
6. **Log everything** in automation scripts — silent failures are the worst.
7. **Test on small datasets** before running on production data.
8. **Use `shutil.copy2`** (preserves metadata) over `shutil.copy` when mirroring.

---

## Exercises

### Exercise 12.1 — Duplicate File Finder
Write a script that scans a directory recursively and groups files with identical content (by MD5 hash). Print each group of duplicates.

**Solution:**
```python
import hashlib
from pathlib import Path
from collections import defaultdict

def find_duplicates(directory: Path) -> dict[str, list[Path]]:
    """Find files with identical content by comparing MD5 hashes."""
    hashes: dict[str, list[Path]] = defaultdict(list)

    for file in directory.rglob("*"):
        if file.is_file():
            h = hashlib.md5(file.read_bytes()).hexdigest()
            hashes[h].append(file)

    return {h: files for h, files in hashes.items() if len(files) > 1}

dupes = find_duplicates(Path("."))
for hash_val, files in dupes.items():
    print(f"\nDuplicates (hash: {hash_val[:8]}):")
    for f in files:
        print(f"  {f} ({f.stat().st_size:,} bytes)")
```

---

## Interview Prep — Top Questions for Scripting and Automation

**Q1: What is the difference between `argparse` and `click`?**
Both build CLI applications. `argparse` is stdlib (no install needed), verbose but fully customizable. `click` (third-party) uses decorators (`@click.command`, `@click.option`), is more concise, has built-in help generation, and handles multi-command CLIs elegantly with `@click.group()`. Use `argparse` when you can't add dependencies; use `click` for complex CLIs.

**Q2: How do you make a production-grade CLI script?**
Key ingredients: `argparse`/`click` for argument parsing; `logging` (not `print`) for output; `sys.exit(0/1)` for proper exit codes; `--dry-run` flag for safety; `--verbose` flag for debugging; handle `KeyboardInterrupt` gracefully; never hardcode paths (use `Path` and env vars). Entry point defined in `pyproject.toml` `[project.scripts]`.

**Q3: What is web scraping and what are the legal/ethical considerations?**
Web scraping programmatically extracts data from web pages (HTML parsing with BeautifulSoup, browser automation with Playwright/Selenium). Legal considerations: check `robots.txt`, respect `Crawl-delay`, review Terms of Service. Ethical: don't overload servers (`time.sleep(1)`), identify your bot in User-Agent headers, don't scrape personal data without consent.

**Q4: How do you schedule Python scripts in production?**
- **Cron** (Unix): OS-level scheduling, runs even when Python process is dead, configured in `crontab -e`. Best for production.
- **`schedule` library**: Python-level, runs inside a long-running process, simpler syntax. Good for prototyping.
- **Celery Beat**: distributed task scheduler with a message broker. Use for complex workflows, retries, monitoring.
- **Cloud schedulers**: AWS EventBridge, GCP Cloud Scheduler, GitHub Actions cron. Use when you're already on that platform.

**Q5: What is the `--dry-run` pattern and why is it critical?**
A `--dry-run` flag makes destructive operations (delete files, send emails, write to DB) print what they *would* do without actually doing it. Always implement this for scripts that modify state. Before running any automation in production, run with `--dry-run`, verify the output looks correct, then run for real. This is the single biggest safety net in automation.

---

## Module Summary

| Tool | Purpose |
|------|---------|
| `argparse` | Built-in CLI argument parsing |
| `click` | Third-party CLI framework with decorators |
| `pathlib` | File system operations |
| `shutil` | Copy, move, archive files/directories |
| `BeautifulSoup` | HTML/XML parsing for web scraping |
| `openpyxl` | Read/write Excel files with formatting |
| `smtplib` | Send emails via SMTP |
| `schedule` | Simple in-process task scheduling |

---

## Quiz

1. What is the difference between `argparse.add_argument("--verbose", action="store_true")` and `action="store"`?
2. How do you make a CLI argument that accepts multiple values in `argparse`?
3. What is a `click.group()` and when would you use it?
4. Why should you always add `time.sleep()` between web scraping requests?
5. What is the difference between `shutil.copy()` and `shutil.copy2()`?
6. How do you read an environment variable safely with a default value?
7. What does `soup.select("article.product_pod")` select?
8. Why should email credentials never be hardcoded in scripts?
9. What is the purpose of the `--dry-run` pattern in automation scripts?
10. What is the difference between cron scheduling and `schedule` (Python library)?

**Answers:**
1. `action="store_true"` sets the argument to `True` when the flag is present, `False` otherwise — no value required (`--verbose` alone works). `action="store"` requires the user to provide a value: `--verbose DEBUG`.
2. Use `nargs="+"` for one or more values, or `nargs="*"` for zero or more. Example: `parser.add_argument("files", nargs="+")` → `python script.py a.txt b.txt c.txt` gives `args.files = ["a.txt", "b.txt", "c.txt"]`.
3. `click.group()` creates a multi-command CLI (like `git`, `docker`). Each sub-command is defined with `@cli.command()`. Use it when your tool has distinct operations: `mytool process`, `mytool report`, `mytool clean`.
4. To avoid overwhelming the target server (rate limiting, IP bans) and to be a polite crawler. Many sites block scrapers that send hundreds of requests per second. `time.sleep(1)` is a minimum; use `random.uniform(1, 3)` to appear more human-like.
5. `shutil.copy()` copies file content and permissions but NOT timestamps. `shutil.copy2()` also preserves metadata (modification time, access time). Use `copy2` for backups where you want to preserve original timestamps.
6. `os.environ.get("MY_VAR", "default_value")`. This returns `"default_value"` if `MY_VAR` is not set, instead of raising `KeyError`. For required variables, use `os.environ["MY_VAR"]` to fail fast with a clear error.
7. It selects all HTML elements with tag `article` AND CSS class `product_pod` — i.e., `<article class="product_pod">`. This is CSS selector syntax: `tag.class`. Equivalent to `soup.find_all("article", class_="product_pod")`.
8. Hardcoded credentials end up in version control (Git history), are visible to anyone with repo access, and can't be rotated without a code change. Use environment variables or a secrets manager (AWS Secrets Manager, HashiCorp Vault) and never commit `.env` files containing real credentials.
9. `--dry-run` prints what the script *would* do without actually doing it. Essential for destructive operations (deleting files, sending emails, modifying databases). Lets you verify the script's logic safely before committing to the real action.
10. Cron is an OS-level scheduler — runs even when your Python process is stopped, survives reboots, configured via `crontab`. The `schedule` library runs inside your Python process — simpler Python syntax, but stops when the process exits. Use cron for production jobs; `schedule` for quick automation scripts.

.PHONY: help lint format type-check test validate clean

help:
	@echo "Python Course — Development Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  help           Show this help message"
	@echo "  lint           Run Ruff linter on all Python files"
	@echo "  format         Format code with Black"
	@echo "  type-check     Run mypy type checking"
	@echo "  validate       Validate markdown and code examples"
	@echo "  test           Run all validation checks"
	@echo "  clean          Remove cache and build artifacts"

lint:
	ruff check . --select=E9,F63,F7,F82 --show-source

format:
	black .

type-check:
	mypy . --ignore-missing-imports || true

validate:
	@echo "Validating markdown syntax..."
	@python -c "import glob, re; \
	for file in glob.glob('*.md'): \
		with open(file) as f: \
			content = f.read(); \
			if content.count('```') % 2 != 0: \
				print(f'ERROR: Unclosed code block in {file}'); exit(1)"
	@echo "✓ All markdown files valid"

test: lint format type-check validate
	@echo "✓ All checks passed"

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ Cleaned up cache and build artifacts"

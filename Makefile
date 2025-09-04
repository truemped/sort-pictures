# Makefile for sort-pictures.sh

.PHONY: test test-unit test-integration test-performance test-all lint check install-deps clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  test           - Run all tests"
	@echo "  test-unit      - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  test-performance - Run performance tests only"
	@echo "  lint           - Run linting and static analysis"
	@echo "  check          - Run syntax check"
	@echo "  install-deps   - Install test dependencies"
	@echo "  clean          - Clean up test artifacts"
	@echo "  help           - Show this help message"

# Test targets
test: test-unit test-integration test-performance

test-unit:
	@echo "Running unit tests..."
	bats tests/unit_tests.bats

test-integration:
	@echo "Running integration tests..."
	bats tests/integration_tests.bats

test-performance:
	@echo "Running performance tests..."
	bats tests/performance_tests.bats

test-all: check lint test
	@echo "All tests completed successfully!"

# Linting and static analysis
lint:
	@echo "Running ShellCheck..."
	shellcheck sort-pictures.sh
	@echo "Checking test files..."
	shellcheck tests/*.sh 2>/dev/null || true
	@echo "Linting completed!"

check:
	@echo "Checking script syntax..."
	bash -n sort-pictures.sh
	@echo "Checking test helper syntax..."
	@for file in tests/*.bash tests/*.sh; do \
		if [ -f "$$file" ]; then \
			echo "Checking $$file..."; \
			bash -n "$$file"; \
		fi; \
	done
	@echo "Syntax check completed!"

# Dependency installation
install-deps:
	@echo "Installing test dependencies..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "Installing via Homebrew..."; \
		brew install bats-core shellcheck; \
	elif command -v apt-get >/dev/null 2>&1; then \
		echo "Installing via apt..."; \
		sudo apt-get update && sudo apt-get install -y bats shellcheck; \
	else \
		echo "Please install bats and shellcheck manually"; \
		exit 1; \
	fi
	@echo "Dependencies installed!"

# Cleanup
clean:
	@echo "Cleaning up test artifacts..."
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@rm -rf test_data 2>/dev/null || true
	@echo "Cleanup completed!"

# Development helpers
format-check:
	@echo "Checking code formatting..."
	@if grep -n '[[:space:]]$$' sort-pictures.sh; then \
		echo "Found trailing whitespace"; \
		exit 1; \
	fi
	@if grep -P '\t' sort-pictures.sh; then \
		echo "Found tab characters (use spaces)"; \
		exit 1; \
	fi
	@echo "Formatting check passed!"

# CI target (used by GitHub Actions)
ci: install-deps check lint test
	@echo "CI pipeline completed successfully!"

# Quick smoke test
smoke-test:
	@echo "Running quick smoke test..."
	@mkdir -p test_smoke
	@echo "dummy" > test_smoke/test.jpg
	@touch -t 202403150800 test_smoke/test.jpg
	@./sort-pictures.sh --dry-run test_smoke
	@rm -rf test_smoke
	@echo "Smoke test passed!"

# Generate test coverage report (basic)
coverage:
	@echo "Generating test coverage information..."
	@echo "Functions tested:"
	@grep -o "@test.*" tests/*.bats | wc -l | xargs echo "  Total tests:"
	@grep -o "run.*is_.*_file" tests/*.bats | sort -u | wc -l | xargs echo "  File type tests:"
	@grep -o "run.*SORT_PICTURES_SCRIPT" tests/*.bats | wc -l | xargs echo "  Integration tests:"
	@echo "Coverage report completed!"

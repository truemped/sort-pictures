#!/bin/bash

# Script to test the GitHub Actions workflow locally
# This simulates what happens in CI

set -euo pipefail

echo "🚀 Testing GitHub Actions workflow locally..."

# Check project structure
echo "📁 Verifying project structure..."
test -f sort-pictures.sh || { echo "❌ Main script missing"; exit 1; }
test -f tests/unit_tests.bats || { echo "❌ Unit tests missing"; exit 1; }
test -f tests/integration_tests.bats || { echo "❌ Integration tests missing"; exit 1; }
test -f tests/performance_tests.bats || { echo "❌ Performance tests missing"; exit 1; }
test -f tests/test_helper.bash || { echo "❌ Test helper missing"; exit 1; }
test -f Makefile || { echo "❌ Makefile missing"; exit 1; }
test -f README.md || { echo "❌ README missing"; exit 1; }
test -f CLAUDE.md || { echo "❌ CLAUDE.md missing"; exit 1; }
echo "✅ All required files present"

# Make script executable
echo "🔧 Making script executable..."
chmod +x sort-pictures.sh

# Check syntax
echo "📝 Checking script syntax..."
bash -n sort-pictures.sh
echo "✅ Script syntax is valid"

# Run tests
echo "🧪 Running unit tests..."
bats tests/unit_tests.bats

echo "🧪 Running integration tests..."
bats tests/integration_tests.bats

echo "🧪 Running performance tests..."
bats tests/performance_tests.bats

# Run Makefile targets
echo "🔨 Testing Makefile targets..."
make check
make smoke-test

# Check dependencies availability
echo "🔍 Checking tool availability..."
if command -v shellcheck >/dev/null; then
    echo "✅ shellcheck available"
    shellcheck sort-pictures.sh
else
    echo "⚠️  shellcheck not available (install with: brew install shellcheck)"
fi

if command -v exiftool >/dev/null; then
    echo "✅ exiftool available"
else
    echo "⚠️  exiftool not available (install with: brew install exiftool)"
fi

echo ""
echo "🎉 All workflow tests passed!"
echo "✅ Ready for GitHub Actions"
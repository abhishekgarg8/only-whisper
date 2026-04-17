#!/bin/bash
# Run all tests

set -e

echo "Running tests..."

cd "$(dirname "$0")/../codebase"

swift test

echo "✅ All tests passed!"

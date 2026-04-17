#!/bin/bash
# Run development build

set -e

echo "Starting development build..."

cd "$(dirname "$0")/../codebase"

swift build

echo "✅ Development build complete!"
echo "Run with: .build/debug/Typewriter"

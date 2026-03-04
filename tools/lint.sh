#!/usr/bin/env bash
# Run gdlint on all GDScript files in the game/ directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "==> Running gdlint..."
find "$PROJECT_ROOT/game" -name "*.gd" -not -path "*/addons/*" -print0 \
  | xargs -0 gdlint
echo "==> gdlint passed!"

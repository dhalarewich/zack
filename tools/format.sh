#!/usr/bin/env bash
# Run gdformat on all GDScript files. Use --check for CI (no modifications).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

CHECK_FLAG=""
if [[ "${1:-}" == "--check" ]]; then
  CHECK_FLAG="--check"
  echo "==> Running gdformat --check (no modifications)..."
else
  echo "==> Running gdformat (auto-formatting)..."
fi

find "$PROJECT_ROOT/game" -name "*.gd" -not -path "*/addons/*" -print0 \
  | xargs -0 gdformat $CHECK_FLAG
echo "==> gdformat done!"

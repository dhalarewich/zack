#!/usr/bin/env bash
# Run GUT tests headless using the Godot CLI.
# Requires: godot (or godot4) on PATH, GUT addon installed in game/addons/gut/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
GAME_DIR="$PROJECT_ROOT/game"

# Find Godot binary.
GODOT="${GODOT_BIN:-}"
if [[ -z "$GODOT" ]]; then
  for candidate in godot godot4 "Godot_v4.6-stable_linux.x86_64"; do
    if command -v "$candidate" &>/dev/null; then
      GODOT="$candidate"
      break
    fi
  done
fi

if [[ -z "$GODOT" ]]; then
  echo "ERROR: Godot binary not found. Set GODOT_BIN or add godot to PATH."
  exit 1
fi

# Install GUT if not present.
GUT_DIR="$GAME_DIR/addons/gut"
if [[ ! -d "$GUT_DIR" ]]; then
  echo "==> GUT not found. Installing from GitHub..."
  GUT_VERSION="${GUT_VERSION:-v9.3.0}"
  git clone --depth 1 --branch "$GUT_VERSION" \
    https://github.com/bitwes/Gut.git /tmp/gut-clone
  mkdir -p "$GAME_DIR/addons"
  cp -r /tmp/gut-clone/addons/gut "$GUT_DIR"
  rm -rf /tmp/gut-clone
  echo "==> GUT installed to $GUT_DIR"
fi

echo "==> Running GUT tests headless..."
cd "$GAME_DIR"
"$GODOT" --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/ \
  -gprefix=test_ \
  -gsuffix=.gd \
  -gexit

echo "==> Tests complete!"

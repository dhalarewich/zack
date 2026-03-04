# ZacksGalacticAdventure

A 2D top-down arcade spaceship shooter built with **Godot 4.6.x** and **GDScript**.
Old-school arena-style gameplay: survive waves of enemies, rack up your score.

## Quick Start (macOS)

### 1. Install Godot 4.6

```bash
# Option A: Homebrew
brew install --cask godot

# Option B: Direct download
# https://godotengine.org/download/macos/
```

### 2. Clone and Open

```bash
git clone <this-repo-url>
cd zack
```

Open Godot, click "Import", navigate to `game/project.godot`, and import.
Press **F5** (or the Play button) to run.

### 3. Controls

| Action    | Keyboard        | Gamepad (PS5 DualSense) |
|-----------|-----------------|-------------------------|
| Move      | WASD / Arrows   | Left Stick / D-Pad      |
| Shoot     | Space           | Cross (X) button        |
| Accept    | Enter / Space   | Cross (X) button        |
| Back      | Escape          | Circle button           |
| Pause     | Escape          | Options (Start) button  |

PS5 DualSense works over Bluetooth on macOS via Godot's standard SDL gamepad mapping. No extra drivers needed.

## Development

### Prerequisites

```bash
# Install gdtoolkit for linting/formatting
pip install "gdtoolkit==4.*"
```

### Commands

```bash
make lint          # Check GDScript style with gdlint
make format        # Auto-format all .gd files
make format-check  # Check formatting (no modifications, CI-safe)
make test          # Run GUT unit tests headless (requires Godot on PATH)
make all           # Run lint + format-check + test
```

### Install GUT (Test Framework)

GUT is not vendored in the repo. To run tests locally:

```bash
# Option A: Let the test script install it
make test   # tools/test.sh auto-installs GUT if missing

# Option B: Manual install
git clone --depth 1 --branch v9.3.0 https://github.com/bitwes/Gut.git /tmp/gut
cp -r /tmp/gut/addons/gut game/addons/gut
rm -rf /tmp/gut
```

### Project Structure

```
game/               Godot project root
  scenes/           .tscn scene files
  scripts/          .gd script files
  assets/           Audio, sprites, fonts
  tests/            GUT test files (test_*.gd)
tools/              Shell scripts for lint/format/test
docs/               Architecture, style guide, asset pipeline docs
.github/workflows/  CI configuration
```

## Web Export

This project uses the `gl_compatibility` renderer, which is required for Web (HTML5/WebAssembly) export.

### How to Export for Web

1. Open the project in Godot
2. Go to **Project > Export**
3. The "Web" preset is pre-configured
4. Install the Web export template if prompted
5. Click **Export Project**
6. Serve the exported files with any HTTP server

### Web Limitations

- Audio may not play until user interacts with the page (browser autoplay policy)
- Gamepad support depends on browser Gamepad API (works in Chrome/Firefox)
- File system access is sandboxed (no save files without IndexedDB)
- SharedArrayBuffer requires specific CORS headers for threading (not used in this project)
- Performance may vary; test in target browsers

## CI

GitHub Actions runs on every push and PR:
1. **GDScript Lint** — `gdlint` checks all `.gd` files
2. **Format Check** — `gdformat --check` ensures consistent style
3. **GUT Tests** — Downloads Godot headless, installs GUT, runs all tests

## Contributing

See [CLAUDE.md](CLAUDE.md) for coding conventions and rules for AI contributors.
See [docs/STYLEGUIDE.md](docs/STYLEGUIDE.md) for detailed style conventions.
See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for scene/script architecture.

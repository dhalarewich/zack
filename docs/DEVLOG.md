# Dev Log — ZacksGalacticAdventure

## 2026-03-04 — Project Creation

### What
Created the full project skeleton from scratch: Godot project config, game loop, testing, linting, CI, and documentation.

### Key Decisions

**Renderer: `gl_compatibility`**
Chose the compatibility renderer instead of Vulkan/Forward+ to support Web (HTML5/WebAssembly) export. This uses WebGL 2.0 under the hood. No visual downside for a 2D pixel art game.

**GameState as Resource, not Autoload**
Decided against using a global singleton for game state. Instead, `GameState` is a plain `Resource` created by the `Main` scene and passed to children via `setup()` methods. This keeps state ownership explicit, avoids hidden global dependencies, and makes testing straightforward.

**Viewport 960x540**
Picked a 16:9 resolution that scales cleanly to 1080p (2x) and 4K (4x). With the "viewport" stretch mode and nearest-neighbor filtering, pixel art will look crisp at any display resolution.

**Pure-logic classes for testability**
`WaveManager` and `EnemySpawner` are `RefCounted` classes with static methods — no Node dependencies. `GameState` is a `Resource`. All three can be instantiated in GUT tests without a scene tree.

**GUT not vendored**
The GUT testing addon is git-ignored and installed on demand (by `tools/test.sh` or manually). This keeps the repo clean and avoids version-pinning a large addon in source control.

**Placeholder visuals**
All game entities use `ColorRect` nodes instead of sprite art. Green = player, red = enemy, yellow = bullet. This lets the game run immediately without any art assets. Pixel art will replace these later.

### Files Created
- Project config: `game/project.godot`, `game/export_presets.cfg`
- Game scripts: 11 GDScript files (main, gameplay, player, enemy, bullet, HUD, screens, logic)
- Scenes: 8 `.tscn` files (hand-authored in text format)
- Tests: 5 test files with 25+ test cases
- Tooling: Makefile, 3 shell scripts, gdlint/gdformat configs
- CI: GitHub Actions workflow (lint + format + test)
- Docs: README, CLAUDE.md, STYLEGUIDE, ARCHITECTURE, ASSET_PIPELINE, DEVLOG

### What's Next
- Replace placeholder shapes with pixel art sprites
- Add sound effects (laser.wav is ready, hook it up to shooting)
- Add background music (level1.mp3 is ready, play during gameplay)
- Add explosion effect when enemies die
- Add screen shake on damage
- Consider adding powerups or different weapon types

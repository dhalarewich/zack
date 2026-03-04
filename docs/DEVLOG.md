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
- ~~Add sound effects (laser.wav is ready, hook it up to shooting)~~ Done
- ~~Add background music (level1.mp3 is ready, play during gameplay)~~ Done
- Add explosion effect when enemies die
- Add screen shake on damage
- Consider adding powerups or different weapon types

---

## 2026-03-04 — Multi-Level Architecture + Audio + Web Deployment

### What
Added multi-level progression with boss fights, wired up audio, and set up automated web deployment to GitHub Pages.

### Key Decisions

**Multi-level architecture**
The game now supports multiple levels (currently 3 defined, targeting 3-5). Each level has:
- A name and intro screen
- Configurable wave count, enemy speed/count bonuses
- Background color (will become pixel art backgrounds later)
- Background music track
- A boss fight at the end

Level configuration lives in `LevelData` (Resource) and `LevelRegistry` (pure logic). Adding a new level is a single function call in `LevelRegistry._levels()`.

**Boss as separate entity**
Bosses are a distinct scene (`boss.tscn`) with higher HP, a sweep movement pattern, and a large magenta placeholder. They share collision layers with regular enemies so bullets work automatically.

**Laser SFX via AudioStreamPlayer2D**
`laser.wav` is loaded into the Player scene as an `AudioStreamPlayer2D` and plays on every shot. Using 2D audio so it can be panned later if needed.

**Level music via dynamic AudioStreamPlayer**
Each level's music is loaded from the path in `LevelData` and played in a loop. Created dynamically in `gameplay.gd` rather than baked into the scene, since each level has different music.

**GitHub Pages deployment**
Added a `deploy-web.yml` workflow that automatically exports the game for Web and deploys to GitHub Pages on every push to main. Uses `coi-serviceworker.js` to add the Cross-Origin-Isolation headers that Godot 4.x needs for SharedArrayBuffer — GitHub Pages doesn't support custom headers natively, but this service worker approach is the standard community workaround.

### Files Added/Modified
- New scripts: `level_data.gd`, `level_registry.gd`, `level_intro.gd`, `boss.gd`
- New scenes: `level_intro.tscn`, `boss.tscn`
- Modified: `main.gd` (level flow), `gameplay.gd` (boss + music + level-aware waves), `game_state.gd` (level tracking), `player.gd` + `player.tscn` (laser SFX), `hud.gd` (boss wave text), `game_over.gd` + `game_over.tscn` (victory mode)
- New tests: `test_level_registry.gd`, additional tests in `test_game_state.gd`
- New CI: `.github/workflows/deploy-web.yml`
- Updated docs: ARCHITECTURE.md, CLAUDE.md, DEVLOG.md

### What's Next
- Replace placeholder shapes with pixel art sprites
- Add music tracks for levels 2 and 3
- Add explosion effects
- Add screen shake on damage
- More boss attack patterns (projectiles, phases)
- Consider powerups or different weapon types

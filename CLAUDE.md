# CLAUDE.md — Rules for AI Contributors

## Project Overview
**ZacksGalacticAdventure** — A 2D top-down arcade spaceship shooter built with Godot 4.6.x and GDScript.

## Golden Rule
**Always keep the game runnable.** Every commit must leave the project in a state where pressing Play in Godot works.

## Commit Discipline
- Small commits. Each commit message explains *what* changed and *why*.
- Never commit broken code to the main branch.
- All PR-level changes must pass lint + tests in CI.

## Code Style

### Naming Conventions
| Thing        | Convention      | Example                |
|-------------|----------------|------------------------|
| Scenes       | PascalCase.tscn | `TitleScreen.tscn`     |
| Scripts      | snake_case.gd   | `wave_manager.gd`      |
| Classes      | PascalCase      | `WaveManager`          |
| Nodes        | PascalCase      | `PlayerShip`           |
| Signals      | snake_case      | `score_changed`        |
| Constants    | SCREAMING_SNAKE | `MAX_HP`               |
| Variables    | snake_case      | `current_wave`         |

### GDScript Rules
- Use typed GDScript for public APIs (function params, return types, exported vars).
- Favor explicit types where they help readability; omit for obvious locals.
- Keep functions small and readable. Limit deep nesting (max 3 levels).
- Prefer simple Godot patterns: scenes + nodes + signals. Avoid overengineering.
- No global singletons/autoloads unless clearly justified. If used, document why in this file.

### Current Autoloads
None. GameState is a Resource created by the Main scene and passed to children.

## Folder Structure
```
/game/                 — Godot project root
  /scenes/             — All .tscn scene files
  /scripts/            — All .gd script files
  /assets/             — Art, audio, fonts
    /audio/
    /sprites/
  /tests/              — GUT test files (test_*.gd)
  /addons/             — Godot plugins (GUT, etc.) — git-ignored, installed locally
/tools/                — Shell scripts for lint, format, test
/docs/                 — Project documentation
```

## Input
- Use Godot Input Map actions only. **No hardcoded keys in gameplay code.**
- Required actions: `move_up`, `move_down`, `move_left`, `move_right`, `shoot`, `pause`, `accept`, `back`
- All actions must have both keyboard and gamepad bindings.

## Quality Gates
- `make lint` — must pass (gdlint)
- `make format-check` — must pass (gdformat)
- `make test` — must pass (GUT headless)
- All three run in CI on every push/PR.

## Testing
- Unit test non-Node logic: math, spawning rules, score, HP, wave progression.
- Test files go in `/game/tests/` and are named `test_*.gd`.
- Use deterministic randomness (seeded RNG) for testable spawning/game logic.
- Minimum 5 tests must exist and pass at all times.

## Level System
- Game has multiple levels (currently 3, target 3-5).
- Each level: unique background, enemy waves, music, and a boss fight.
- Level data is defined in `level_registry.gd` as `LevelData` resources.
- Flow per level: Level Intro → Waves (1..N) → Boss → Next Level (or Victory).
- To add a new level, add a `LevelData` entry in `LevelRegistry._levels()`.

## Adding a New Enemy
1. Create `game/scenes/NewEnemy.tscn` (CharacterBody2D + CollisionShape2D + visual).
2. Create `game/scripts/new_enemy.gd` extending the base enemy pattern.
3. Register it in `wave_manager.gd` spawn logic.
4. Add a test in `game/tests/test_new_enemy.gd`.
5. Update `docs/ARCHITECTURE.md` with the new enemy's behavior.

## Web Build
- Renderer must stay `gl_compatibility` for WebGL 2.0 support.
- No GDExtension/native plugins (breaks Web export).
- Test Web export periodically.

## Commands
```bash
make lint         # Run gdlint on all GDScript files
make format       # Auto-format all GDScript files
make format-check # Check formatting without modifying
make test         # Run GUT tests headless
```

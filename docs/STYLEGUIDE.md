# Style Guide — ZacksGalacticAdventure

## Naming Conventions

### Files
- **Scenes**: `PascalCase.tscn` — e.g., `TitleScreen.tscn`, `GameOver.tscn`
- **Scripts**: `snake_case.gd` — e.g., `wave_manager.gd`, `game_state.gd`
- **Test files**: `test_<name>.gd` — e.g., `test_game_state.gd`

### Code
- **Classes**: `PascalCase` — e.g., `GameState`, `WaveManager`
- **Nodes**: `PascalCase` — e.g., `PlayerShip`, `SpawnTimer`
- **Functions**: `snake_case` — e.g., `get_enemy_count()`, `take_damage()`
- **Variables**: `snake_case` — e.g., `current_wave`, `fire_timer`
- **Private members**: `_snake_case` — prefix with underscore for internal state
- **Constants**: `SCREAMING_SNAKE_CASE` — e.g., `MAX_HP`, `BASE_ENEMY_COUNT`
- **Signals**: `snake_case` — past tense for events: `score_changed`, `player_died`
- **Enums**: `PascalCase` for type, `SCREAMING_SNAKE` for values

## GDScript Rules

### Type Annotations
- **Always type** function parameters, return types, and exported variables
- **Optional** for obvious local variables (`var i := 0` is fine)
- Use `:=` for type inference on locals when the type is obvious

```gdscript
# Good
func get_enemy_count(wave: int) -> int:
    var count: int = BASE_ENEMY_COUNT + wave * 2
    return count

# Also good (inferred type is obvious)
var pos := Vector2(100, 200)

# Bad — public API without types
func get_enemy_count(wave):
    return 3 + wave * 2
```

### Function Size
- Keep functions under 20 lines when possible
- Extract helpers if a function exceeds 30 lines
- Maximum nesting depth: 3 levels

### Signals Over Direct Calls
- Use signals for communication between sibling nodes
- Parent-to-child: direct method calls are fine
- Child-to-parent: always use signals
- Never reach up the tree with `get_parent()` in gameplay code

### Scene Organization
- Each scene should have a single responsibility
- Prefer composition (child scenes) over inheritance
- Scripts live in `scripts/`, scenes in `scenes/` — not colocated

## File Structure

Every `.gd` file should follow this order:
1. `class_name` (if needed)
2. `extends`
3. `## Doc comment`
4. `signal` declarations
5. `enum` declarations
6. `const` declarations
7. `@export` variables
8. Public variables
9. Private variables (`_prefixed`)
10. `@onready` variables
11. `_ready()`, `_process()`, `_physics_process()`, `_input()`
12. Public methods
13. Private methods (`_prefixed`)

## Formatting
- Line length: 100 characters max
- Use tabs for indentation (Godot default)
- Run `make format` before committing
- One blank line between functions
- Two blank lines before `class_name` or top-level items

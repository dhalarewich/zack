# Architecture — ZacksGalacticAdventure

## Scene Tree

```
Main (Node)                          scripts/main.gd
├── [dynamic child: current screen]
│
│   TitleScreen (Control)            scripts/title_screen.gd
│   ├── Background (ColorRect)
│   ├── TitleLabel (Label)
│   ├── PromptLabel (Label)          — blinks "PRESS ENTER OR START"
│   └── ControlsLabel (Label)
│
│   LevelIntro (Control)             scripts/level_intro.gd
│   ├── Background (ColorRect)
│   ├── LevelNumberLabel (Label)     — "LEVEL 1"
│   └── LevelNameLabel (Label)       — "The Asteroid Belt"
│
│   Gameplay (Node2D)                scripts/gameplay.gd
│   ├── Background (ColorRect)       — color from LevelData
│   ├── Player (CharacterBody2D)     scripts/player.gd  [instance of player.tscn]
│   │   ├── Body (ColorRect)         — green placeholder ship body
│   │   ├── Nose (ColorRect)         — lighter green nose
│   │   ├── CollisionShape2D
│   │   └── LaserSound (AudioStreamPlayer2D)  — plays laser.wav on shoot
│   ├── Bullets (Node2D)             — container for bullet instances
│   │   └── Bullet (Area2D)          scripts/bullet.gd  [instances of bullet.tscn]
│   │       ├── Sprite (ColorRect)   — yellow placeholder
│   │       └── CollisionShape2D
│   ├── Enemies (Node2D)             — container for enemy + boss instances
│   │   ├── Enemy (CharacterBody2D)  scripts/enemy.gd  [instances of enemy.tscn]
│   │   │   ├── Body (ColorRect)     — red placeholder
│   │   │   ├── CollisionShape2D
│   │   │   └── HitArea (Area2D)
│   │   │       └── HitShape
│   │   └── Boss (CharacterBody2D)   scripts/boss.gd  [instance of boss.tscn]
│   │       ├── Body (ColorRect)     — magenta placeholder (larger)
│   │       ├── Core (ColorRect)
│   │       ├── CollisionShape2D
│   │       └── HitArea (Area2D)
│   │           └── HitShape
│   ├── HUD (CanvasLayer)            scripts/hud.gd  [instance of hud.tscn]
│   │   ├── ScoreLabel
│   │   ├── HPLabel
│   │   └── WaveLabel
│   ├── AudioStreamPlayer             — level music (created dynamically)
│   ├── SpawnTimer (Timer)
│   └── WaveDelayTimer (Timer)
│
│   GameOver (Control)               scripts/game_over.gd  (also used for victory)
│   ├── Background (ColorRect)
│   ├── GameOverLabel (Label)        — "GAME OVER" or "YOU WIN!"
│   ├── FinalScoreLabel (Label)
│   └── RetryLabel (Label)
```

## Level System

### Level Flow
```
TITLE
  │ [accept]
  ▼
LEVEL INTRO  ◄─────────────────────────────┐
  │ [3s timer or accept]                    │
  ▼                                         │
GAMEPLAY (waves 1..N)                       │
  │ [all waves cleared]                     │
  ▼                                         │
BOSS FIGHT                                  │
  │ [boss destroyed]                        │
  ├── [more levels] ──► advance_level() ────┘
  └── [final level] ──► VICTORY

GAMEPLAY ──[player dies]──► GAME OVER ──[accept]──► TITLE
VICTORY ──[accept]──► TITLE
```

### LevelData (Resource)
Each level is configured with a `LevelData` resource containing:
- `level_name`: Display name (e.g., "The Asteroid Belt")
- `level_number`: Sequential number
- `wave_count`: Number of enemy waves before boss (default 5)
- `background_color`: Arena background (replaced by pixel art later)
- `music_path`: Path to background music track
- `has_boss`: Whether level ends with a boss fight
- `boss_hp`, `boss_speed`: Boss configuration
- `enemy_speed_bonus`, `enemy_count_bonus`: Per-level difficulty scaling

### LevelRegistry (RefCounted)
Central registry that returns `LevelData` for each level. Currently defines 3 levels:

| # | Name             | Waves | Boss HP | Music         |
|---|------------------|-------|---------|---------------|
| 1 | The Asteroid Belt | 5     | 10      | level1.mp3    |
| 2 | Nebula Station    | 5     | 15      | (placeholder) |
| 3 | The Dark Void     | 5     | 20      | (placeholder) |

To add a new level, add another `LevelData` entry in `LevelRegistry._levels()`.

### GameState (Resource — NOT an autoload)
- Created by `Main` when starting a new game
- Passed to `Gameplay` and `HUD` via `setup(game_state)` methods
- Contains: `score`, `hp`, `current_wave`, `current_level`
- Emits: `score_changed`, `hp_changed`, `player_died`, `level_completed`
- Methods: `advance_wave()`, `advance_level()`, `get_level_data()`, `is_final_level()`

**Why not an autoload?** We avoid global singletons to keep state ownership explicit and testable. GameState is a plain Resource with no scene dependencies.

## Signal Flow

```
Player.shoot_requested   -->  Gameplay._on_player_shoot   -->  spawns Bullet + plays laser SFX
Player.player_hit        -->  Gameplay._on_player_hit     -->  GameState.take_damage()
Enemy.enemy_destroyed    -->  Gameplay._on_enemy_destroyed -->  GameState.add_score()
Boss.boss_destroyed      -->  Gameplay._on_boss_destroyed  -->  GameState.add_score() + level_cleared
GameState.score_changed  -->  HUD._on_score_changed
GameState.hp_changed     -->  HUD._on_hp_changed
GameState.player_died    -->  Gameplay._on_player_died    -->  Gameplay.game_over signal
Gameplay.game_over       -->  Main._show_game_over
Gameplay.level_cleared   -->  Main._on_level_cleared      -->  next level or victory
LevelIntro.intro_finished -> Main._start_level
TitleScreen.start_game   -->  Main._start_new_game
GameOver.retry_game      -->  Main._start_new_game
```

## Collision Layers

| Layer | Name         | Bit | Used By                    |
|-------|-------------|-----|----------------------------|
| 1     | Player      | 1   | Player body                |
| 2     | Enemy       | 2   | Enemy body + HitArea, Boss |
| 3     | PlayerBullet| 4   | Bullet area                |

- Player collision mask: Enemy (2)
- Enemy collision mask: Player (1) + PlayerBullet (4) = 5
- Bullet collision mask: Enemy (2)
- Boss uses same layers as Enemy

## Input Map

All input is routed through Godot's Input Map. **No hardcoded key checks in gameplay code.**

| Action      | Keyboard            | Gamepad                    |
|------------|---------------------|----------------------------|
| move_up    | W, Up Arrow         | Left Stick Up, DPad Up     |
| move_down  | S, Down Arrow       | Left Stick Down, DPad Down |
| move_left  | A, Left Arrow       | Left Stick Left, DPad Left |
| move_right | D, Right Arrow      | Left Stick Right, DPad Right|
| shoot      | Space               | Cross (button 0)           |
| pause      | Escape              | Start (button 6)           |
| accept     | Enter, Space        | Cross (button 0)           |
| back       | Escape              | Circle (button 1)          |

## Wave System

Managed by pure-logic classes plus per-level configuration:

- **WaveManager** — calculates per-wave parameters (enemy count, spawn delay, speed)
- **EnemySpawner** — picks spawn positions on arena edges using seeded RNG
- **LevelData** — provides per-level bonuses (enemy count/speed) and wave count

Gameplay scene orchestrates the per-level flow:
1. `_start_wave()` — reads wave params + level bonuses, starts SpawnTimer
2. SpawnTimer ticks → spawns enemies one at a time
3. All enemies dead → `_check_wave_complete()` → starts WaveDelayTimer
4. WaveDelayTimer fires → `advance_wave()` → `_start_wave()`
5. After all waves → `_start_boss()` → spawns Boss
6. Boss destroyed → `level_cleared` signal → Main advances to next level

## How to Add a New Enemy

1. **Scene**: Create `game/scenes/NewEnemy.tscn` (CharacterBody2D root)
   - Add CollisionShape2D + visual placeholder
   - Add HitArea (Area2D) on layer 2, mask 4
2. **Script**: Create `game/scripts/new_enemy.gd`
   - Must implement `setup(target, speed)` and `take_hit()`
   - Must emit `enemy_destroyed(points)` signal
3. **Registration**: In `gameplay.gd`, add a preload and spawn logic
   - Can use WaveManager to select enemy types based on wave number
4. **Test**: Add `game/tests/test_new_enemy.gd` with behavior tests
5. **Docs**: Update this file's scene tree and collision info

## How to Add a New Level

1. In `level_registry.gd`, add a new `LevelData` entry in `_levels()`
2. Set the level name, wave count, boss config, and music path
3. Add the background music file to `game/assets/audio/`
4. (Later) Add background pixel art to `game/assets/sprites/`
5. Update this file's level table

## Rendering

- Renderer: `gl_compatibility` (required for Web export via WebGL 2.0)
- Texture filter: Nearest (pixel art ready)
- Viewport: 960x540, stretch mode "viewport", aspect "keep"

## Web Deployment

The game is automatically exported and deployed to GitHub Pages on every push to main. The deployment workflow:
1. Exports the project using Godot CLI (`--export-release "Web"`)
2. Adds a `coi-serviceworker.js` to provide Cross-Origin-Isolation headers (required for SharedArrayBuffer in Godot 4.x)
3. Deploys to GitHub Pages via `actions/deploy-pages`

Play the latest build at: `https://<username>.github.io/zack/`

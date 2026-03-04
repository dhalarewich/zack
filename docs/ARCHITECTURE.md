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
│   Gameplay (Node2D)                scripts/gameplay.gd
│   ├── Background (ColorRect)
│   ├── Player (CharacterBody2D)     scripts/player.gd  [instance of player.tscn]
│   │   ├── Body (ColorRect)         — green placeholder ship body
│   │   ├── Nose (ColorRect)         — lighter green nose
│   │   └── CollisionShape2D
│   ├── Bullets (Node2D)             — container for bullet instances
│   │   └── Bullet (Area2D)          scripts/bullet.gd  [instances of bullet.tscn]
│   │       ├── Sprite (ColorRect)   — yellow placeholder
│   │       └── CollisionShape2D
│   ├── Enemies (Node2D)             — container for enemy instances
│   │   └── Enemy (CharacterBody2D)  scripts/enemy.gd  [instances of enemy.tscn]
│   │       ├── Body (ColorRect)     — red placeholder
│   │       ├── CollisionShape2D
│   │       └── HitArea (Area2D)
│   │           └── HitShape
│   ├── HUD (CanvasLayer)            scripts/hud.gd  [instance of hud.tscn]
│   │   ├── ScoreLabel
│   │   ├── HPLabel
│   │   └── WaveLabel
│   ├── SpawnTimer (Timer)
│   └── WaveDelayTimer (Timer)
│
│   GameOver (Control)               scripts/game_over.gd
│   ├── Background (ColorRect)
│   ├── GameOverLabel (Label)
│   ├── FinalScoreLabel (Label)
│   └── RetryLabel (Label)
```

## State Management

### Screen Flow (Main.gd)
```
TITLE  --[accept pressed]-->  PLAYING  --[player dies]-->  GAME_OVER
  ^                                                            |
  |                        [accept pressed]                    |
  +------------------------------------------------------------+
```

Main uses a simple enum (`Screen.TITLE`, `Screen.PLAYING`, `Screen.GAME_OVER`) and swaps child scenes via `queue_free()` + `add_child()`.

### GameState (Resource — NOT an autoload)
- Created by `Main` when entering `PLAYING` state
- Passed to `Gameplay` and `HUD` via `setup(game_state)` methods
- Contains: `score`, `hp`, `current_wave`
- Emits: `score_changed`, `hp_changed`, `player_died`

**Why not an autoload?** We avoid global singletons to keep state ownership explicit and testable. GameState is a plain Resource with no scene dependencies.

## Signal Flow

```
Player.shoot_requested  -->  Gameplay._on_player_shoot  -->  spawns Bullet
Player.player_hit       -->  Gameplay._on_player_hit    -->  GameState.take_damage()
Enemy.enemy_destroyed   -->  Gameplay._on_enemy_destroyed -> GameState.add_score()
GameState.score_changed -->  HUD._on_score_changed
GameState.hp_changed    -->  HUD._on_hp_changed
GameState.player_died   -->  Gameplay._on_player_died   -->  Gameplay.game_over signal
Gameplay.game_over      -->  Main._show_game_over
TitleScreen.start_game  -->  Main._start_game
GameOver.retry_game     -->  Main._start_game
```

## Collision Layers

| Layer | Name         | Bit | Used By            |
|-------|-------------|-----|--------------------|
| 1     | Player      | 1   | Player body        |
| 2     | Enemy       | 2   | Enemy body + HitArea |
| 3     | PlayerBullet| 4   | Bullet area        |

- Player collision mask: Enemy (2)
- Enemy collision mask: Player (1) + PlayerBullet (4) = 5
- Bullet collision mask: Enemy (2)

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

Managed by two pure-logic classes:

- **WaveManager** — calculates per-wave parameters (enemy count, spawn delay, speed)
- **EnemySpawner** — picks spawn positions on arena edges using seeded RNG

Gameplay scene orchestrates wave flow:
1. `_start_wave()` — reads wave params, starts SpawnTimer
2. SpawnTimer ticks → spawns enemies one at a time
3. All enemies dead → `_check_wave_complete()` → starts WaveDelayTimer
4. WaveDelayTimer fires → `advance_wave()` → `_start_wave()`

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

## Rendering

- Renderer: `gl_compatibility` (required for Web export via WebGL 2.0)
- Texture filter: Nearest (pixel art ready)
- Viewport: 960x540, stretch mode "viewport", aspect "keep"

class_name LevelData
extends Resource
## Defines the configuration for a single level.
## Each level has its own name, background, music, wave count, and boss.

@export var level_name: String = "Unknown Sector"
@export var level_number: int = 1
@export var wave_count: int = 5
@export var background_color: Color = Color(0.04, 0.02, 0.1, 1)
@export var music_path: String = ""
@export var has_boss: bool = true
@export var boss_hp: int = 10
@export var boss_speed: float = 60.0
@export var enemy_speed_bonus: float = 0.0
@export var enemy_count_bonus: int = 0

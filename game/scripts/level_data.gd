class_name LevelData
extends Resource
## Defines the configuration for a single level.
## Each level has its own name, background, music, wave count, and boss.

@export var level_name: String = "Unknown Sector"
@export var level_number: int = 1
@export var wave_count: int = 5
@export var background_color: Color = Color(0.04, 0.02, 0.1, 1)
@export var background_texture_path: String = ""
@export var music_path: String = ""
@export var has_boss: bool = true
@export var boss_hp: int = 10
@export var boss_speed: float = 60.0
@export var boss_sprite_path: String = ""
@export var enemy_speed_bonus: float = 0.0
@export var enemy_count_bonus: int = 0

# Boss shooting configuration
@export var boss_bullet_color: Color = Color(1.0, 0.2, 0.2, 1.0)
@export var boss_fire_interval_min: float = 1.5
@export var boss_fire_interval_max: float = 3.5
@export var boss_spread_count: int = 1
@export var boss_spread_angle: float = 0.0

# Boss visual / behavior enhancements
@export var boss_scale: float = 1.0
@export var boss_has_particles: bool = false
@export var boss_particle_color: Color = Color(1.0, 0.2, 0.1, 1.0)
@export var boss_has_dart_attack: bool = false
@export var boss_music_path: String = ""

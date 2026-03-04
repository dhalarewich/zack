class_name WaveManager
extends RefCounted
## Pure-logic class that calculates wave parameters.
## No scene dependency — easy to unit test.

const BASE_ENEMY_COUNT: int = 3
const ENEMIES_PER_WAVE: int = 2
const BASE_SPAWN_DELAY: float = 1.5
const MIN_SPAWN_DELAY: float = 0.3
const SPAWN_DELAY_REDUCTION: float = 0.15
const BASE_ENEMY_SPEED: float = 80.0
const SPEED_INCREMENT: float = 10.0
const MAX_ENEMY_SPEED: float = 250.0


static func get_enemy_count(wave: int) -> int:
	return BASE_ENEMY_COUNT + (wave - 1) * ENEMIES_PER_WAVE


static func get_spawn_delay(wave: int) -> float:
	var delay: float = BASE_SPAWN_DELAY - (wave - 1) * SPAWN_DELAY_REDUCTION
	return maxf(delay, MIN_SPAWN_DELAY)


static func get_enemy_speed(wave: int) -> float:
	var speed: float = BASE_ENEMY_SPEED + (wave - 1) * SPEED_INCREMENT
	return minf(speed, MAX_ENEMY_SPEED)

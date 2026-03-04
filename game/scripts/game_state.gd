class_name GameState
extends Resource
## Tracks score, HP, and wave state for a single game session.
## Created by Main scene and passed to Gameplay/HUD — not an autoload.

signal score_changed(new_score: int)
signal hp_changed(new_hp: int)
signal player_died

const MAX_HP: int = 3
const SCORE_PER_KILL: int = 100

var score: int = 0
var hp: int = MAX_HP
var current_wave: int = 1


func add_score(amount: int = SCORE_PER_KILL) -> void:
	score += amount
	score_changed.emit(score)


func take_damage(amount: int = 1) -> void:
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp)
	if hp <= 0:
		player_died.emit()


func is_game_over() -> bool:
	return hp <= 0


func advance_wave() -> void:
	current_wave += 1


func reset() -> void:
	score = 0
	hp = MAX_HP
	current_wave = 1

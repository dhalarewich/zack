class_name GameState
extends Resource
## Tracks score, HP, shield, and wave state for a game session.
## Supports 1 or 2 players with per-player HP/shields and shared score.
## Created by Main scene and passed to Gameplay/HUD — not an autoload.
## Backward-compat: single-player API (hp, shield_hp, take_damage, heal, etc.)
## delegates to player index 0.

signal score_changed(new_score: int)
signal hp_changed(new_hp: int)
signal shield_changed(new_shield: int)
signal shield_broken
signal player_died(player_index: int)
signal all_players_dead
signal level_completed(level_number: int)
signal player_hp_changed(player_index: int, new_hp: int)
signal player_shield_changed(player_index: int, new_shield: int)
signal player_shield_broken(player_index: int)
signal multiplier_changed(new_multiplier: float)
signal wave_bonus_awarded(bonus: int, is_perfect: bool)

const MAX_HP: int = 5
const SCORE_PER_KILL: int = 100
const MAX_SHIELD: int = 3
const KILLS_PER_MULTIPLIER_TIER: int = 5
const MAX_MULTIPLIER: float = 3.0
const MULTIPLIER_STEP: float = 0.5
const WAVE_CLEAR_BONUS_BASE: int = 200

var score: int = 0
var current_wave: int = 1
var current_level: int = 1
var player_count: int = 1
var player_hp: Array[int] = []
var player_shield: Array[int] = []
var player_alive: Array[bool] = []
var score_multiplier: float = 1.0

## Backward-compat: hp/shield_hp read from player 0.
var hp: int:
	get:
		if player_hp.size() > 0:
			return player_hp[0]
		return MAX_HP
	set(value):
		if player_hp.size() > 0:
			player_hp[0] = value

var shield_hp: int:
	get:
		if player_shield.size() > 0:
			return player_shield[0]
		return 0
	set(value):
		if player_shield.size() > 0:
			player_shield[0] = value

var _kills_without_damage: int = 0
var _wave_damage_count: int = 0


func _init() -> void:
	setup_players(1)


func setup_players(count: int) -> void:
	player_count = count
	player_hp.clear()
	player_shield.clear()
	player_alive.clear()
	for i: int in count:
		player_hp.append(MAX_HP)
		player_shield.append(0)
		player_alive.append(true)


func add_score(amount: int = SCORE_PER_KILL) -> void:
	var multiplied: int = int(amount * score_multiplier)
	score += multiplied
	score_changed.emit(score)


## Register a kill for the streak multiplier. Call before add_score().
func register_kill() -> void:
	_kills_without_damage += 1
	var old_mult: float = score_multiplier
	var tier: int = _kills_without_damage / KILLS_PER_MULTIPLIER_TIER
	score_multiplier = minf(1.0 + tier * MULTIPLIER_STEP, MAX_MULTIPLIER)
	if score_multiplier != old_mult:
		multiplier_changed.emit(score_multiplier)


## Reset wave damage counter at start of each wave.
func reset_wave_damage() -> void:
	_wave_damage_count = 0


## Award bonus points for clearing a wave. Perfect = no damage taken.
func award_wave_clear_bonus(wave: int) -> void:
	var is_perfect: bool = _wave_damage_count == 0
	var bonus: int = wave * WAVE_CLEAR_BONUS_BASE
	if is_perfect:
		bonus *= 2
	score += bonus
	score_changed.emit(score)
	wave_bonus_awarded.emit(bonus, is_perfect)


## Backward-compat: damage player 0.
func take_damage(amount: int = 1) -> void:
	take_damage_for(0, amount)


## Damage a specific player by index.
func take_damage_for(index: int, amount: int = 1) -> void:
	if index < 0 or index >= player_count:
		return
	if not player_alive[index]:
		return

	# Multiplier penalty: reset kill streak, drop multiplier by one tier
	_wave_damage_count += 1
	_kills_without_damage = 0
	var old_mult: float = score_multiplier
	score_multiplier = maxf(score_multiplier - MULTIPLIER_STEP, 1.0)
	if score_multiplier != old_mult:
		multiplier_changed.emit(score_multiplier)

	if player_shield[index] > 0:
		var absorbed: int = mini(amount, player_shield[index])
		player_shield[index] -= absorbed
		player_shield_changed.emit(index, player_shield[index])
		if index == 0:
			shield_changed.emit(player_shield[0])
		amount -= absorbed
		if player_shield[index] <= 0:
			player_shield_broken.emit(index)
			if index == 0:
				shield_broken.emit()
		if amount <= 0:
			return

	player_hp[index] = maxi(player_hp[index] - amount, 0)
	player_hp_changed.emit(index, player_hp[index])
	if index == 0:
		hp_changed.emit(player_hp[0])
	if player_hp[index] <= 0:
		player_alive[index] = false
		player_died.emit(index)
		if not _any_player_alive():
			all_players_dead.emit()


## Backward-compat: heal player 0.
func heal(amount: int = MAX_HP) -> void:
	heal_player(0, amount)


## Heal a specific player by index.
func heal_player(index: int, amount: int = MAX_HP) -> void:
	if index < 0 or index >= player_count:
		return
	if not player_alive[index]:
		return
	player_hp[index] = mini(player_hp[index] + amount, MAX_HP)
	player_hp_changed.emit(index, player_hp[index])
	if index == 0:
		hp_changed.emit(player_hp[0])


## Backward-compat: add shield to player 0.
func add_shield(amount: int = MAX_SHIELD) -> void:
	add_shield_for(0, amount)


## Add shield to a specific player by index.
func add_shield_for(index: int, amount: int = MAX_SHIELD) -> void:
	if index < 0 or index >= player_count:
		return
	if not player_alive[index]:
		return
	player_shield[index] = mini(player_shield[index] + amount, MAX_SHIELD)
	player_shield_changed.emit(index, player_shield[index])
	if index == 0:
		shield_changed.emit(player_shield[0])


## Backward-compat: delegates to not _any_player_alive().
func is_game_over() -> bool:
	return not _any_player_alive()


func _any_player_alive() -> bool:
	for alive: bool in player_alive:
		if alive:
			return true
	return false


## Revive dead players with full HP (used at level transitions).
func respawn_dead_players() -> void:
	for i: int in player_count:
		if not player_alive[i]:
			player_alive[i] = true
			player_hp[i] = MAX_HP
			player_shield[i] = 0
			player_hp_changed.emit(i, player_hp[i])
			player_shield_changed.emit(i, player_shield[i])
			if i == 0:
				hp_changed.emit(player_hp[0])
				shield_changed.emit(player_shield[0])


func advance_wave() -> void:
	current_wave += 1


func advance_level() -> void:
	level_completed.emit(current_level)
	current_level += 1
	current_wave = 1


func is_final_level() -> bool:
	return current_level >= LevelRegistry.get_level_count()


func get_level_data() -> LevelData:
	return LevelRegistry.get_level(current_level)


func reset() -> void:
	score = 0
	current_wave = 1
	current_level = 1
	score_multiplier = 1.0
	_kills_without_damage = 0
	_wave_damage_count = 0
	setup_players(player_count)

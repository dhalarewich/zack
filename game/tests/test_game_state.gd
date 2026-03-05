# gdlint: ignore=max-public-methods
extends GutTest
## Tests for GameState resource: score, HP, wave tracking, and multiplier.


func test_initial_state() -> void:
	var state := GameState.new()
	assert_eq(state.score, 0, "Initial score should be 0")
	assert_eq(state.hp, GameState.MAX_HP, "Initial HP should equal MAX_HP")
	assert_eq(state.current_wave, 1, "Initial wave should be 1")


func test_add_score_increments() -> void:
	var state := GameState.new()
	state.add_score(100)
	assert_eq(state.score, 100, "Score should be 100 after adding 100")
	state.add_score(50)
	assert_eq(state.score, 150, "Score should be 150 after adding 50 more")


func test_add_score_default_value() -> void:
	var state := GameState.new()
	state.add_score()
	assert_eq(state.score, GameState.SCORE_PER_KILL, "Default add_score uses SCORE_PER_KILL")


func test_take_damage_decreases_hp() -> void:
	var state := GameState.new()
	var initial_hp: int = state.hp
	state.take_damage()
	assert_eq(state.hp, initial_hp - 1, "HP should decrease by 1")


func test_take_damage_clamps_at_zero() -> void:
	var state := GameState.new()
	for i: int in range(GameState.MAX_HP + 5):
		state.take_damage()
	assert_eq(state.hp, 0, "HP should not go below 0")


func test_is_game_over_false_when_alive() -> void:
	var state := GameState.new()
	assert_false(state.is_game_over(), "Should not be game over at full HP")


func test_is_game_over_true_when_dead() -> void:
	var state := GameState.new()
	for i: int in range(GameState.MAX_HP):
		state.take_damage()
	assert_true(state.is_game_over(), "Should be game over at 0 HP")


func test_reset_restores_initial_values() -> void:
	var state := GameState.new()
	state.add_score(500)
	state.take_damage()
	state.advance_wave()
	state.reset()
	assert_eq(state.score, 0, "Score should reset to 0")
	assert_eq(state.hp, GameState.MAX_HP, "HP should reset to MAX_HP")
	assert_eq(state.current_wave, 1, "Wave should reset to 1")


func test_advance_wave() -> void:
	var state := GameState.new()
	state.advance_wave()
	assert_eq(state.current_wave, 2, "Wave should be 2 after advancing once")
	state.advance_wave()
	assert_eq(state.current_wave, 3, "Wave should be 3 after advancing twice")


func test_initial_level() -> void:
	var state := GameState.new()
	assert_eq(state.current_level, 1, "Initial level should be 1")


func test_advance_level_increments_and_resets_wave() -> void:
	var state := GameState.new()
	state.advance_wave()
	state.advance_wave()
	assert_eq(state.current_wave, 3, "Wave should be 3 before level advance")
	state.advance_level()
	assert_eq(state.current_level, 2, "Level should be 2 after advancing")
	assert_eq(state.current_wave, 1, "Wave should reset to 1 on new level")


func test_get_level_data_returns_valid() -> void:
	var state := GameState.new()
	var data: LevelData = state.get_level_data()
	assert_not_null(data, "Level data should not be null")
	assert_eq(data.level_number, 1, "First level data should be level 1")


func test_reset_restores_level() -> void:
	var state := GameState.new()
	state.advance_level()
	state.advance_level()
	state.reset()
	assert_eq(state.current_level, 1, "Level should reset to 1")


func test_initial_shield_is_zero() -> void:
	var state := GameState.new()
	assert_eq(state.shield_hp, 0, "Initial shield should be 0")


func test_add_shield() -> void:
	var state := GameState.new()
	state.add_shield(2)
	assert_eq(state.shield_hp, 2, "Shield should be 2 after adding 2")


func test_add_shield_clamps_at_max() -> void:
	var state := GameState.new()
	state.add_shield(10)
	assert_eq(state.shield_hp, GameState.MAX_SHIELD, "Shield should clamp to MAX_SHIELD")


func test_shield_absorbs_damage() -> void:
	var state := GameState.new()
	state.add_shield(3)
	state.take_damage(2)
	assert_eq(state.shield_hp, 1, "Shield should absorb 2 damage")
	assert_eq(state.hp, GameState.MAX_HP, "HP should remain full")


func test_shield_overflow_to_hp() -> void:
	var state := GameState.new()
	state.add_shield(1)
	state.take_damage(3)
	assert_eq(state.shield_hp, 0, "Shield should be depleted")
	assert_eq(state.hp, GameState.MAX_HP - 2, "Remaining damage should hit HP")


func test_heal_restores_hp() -> void:
	var state := GameState.new()
	state.take_damage(3)
	state.heal(2)
	assert_eq(state.hp, GameState.MAX_HP - 1, "HP should be MAX_HP - 1 after heal")


func test_heal_clamps_at_max() -> void:
	var state := GameState.new()
	state.take_damage(1)
	state.heal(999)
	assert_eq(state.hp, GameState.MAX_HP, "HP should clamp to MAX_HP")


func test_reset_clears_shield() -> void:
	var state := GameState.new()
	state.add_shield(3)
	state.reset()
	assert_eq(state.shield_hp, 0, "Shield should reset to 0")


# --- 2-Player Co-op Tests ---


func test_two_player_initial_state() -> void:
	var state := GameState.new()
	state.setup_players(2)
	assert_eq(state.player_count, 2, "Should have 2 players")
	assert_eq(state.player_hp[0], GameState.MAX_HP, "P1 HP should be MAX_HP")
	assert_eq(state.player_hp[1], GameState.MAX_HP, "P2 HP should be MAX_HP")
	assert_true(state.player_alive[0], "P1 should be alive")
	assert_true(state.player_alive[1], "P2 should be alive")
	assert_eq(state.player_shield[0], 0, "P1 shield should be 0")
	assert_eq(state.player_shield[1], 0, "P2 shield should be 0")


func test_two_player_independent_damage() -> void:
	var state := GameState.new()
	state.setup_players(2)
	state.take_damage_for(0, 2)
	assert_eq(state.player_hp[0], GameState.MAX_HP - 2, "P1 should take 2 damage")
	assert_eq(state.player_hp[1], GameState.MAX_HP, "P2 should be unaffected")


func test_one_player_dead_not_game_over() -> void:
	var state := GameState.new()
	state.setup_players(2)
	for i: int in range(GameState.MAX_HP):
		state.take_damage_for(0)
	assert_eq(state.player_hp[0], 0, "P1 should be dead")
	assert_false(state.player_alive[0], "P1 should not be alive")
	assert_true(state.player_alive[1], "P2 should still be alive")
	assert_false(state.is_game_over(), "Game should NOT be over with P2 alive")


func test_both_players_dead_game_over() -> void:
	var state := GameState.new()
	state.setup_players(2)
	for i: int in range(GameState.MAX_HP):
		state.take_damage_for(0)
		state.take_damage_for(1)
	assert_true(state.is_game_over(), "Game should be over when both dead")


func test_respawn_dead_players() -> void:
	var state := GameState.new()
	state.setup_players(2)
	# Kill P1
	for i: int in range(GameState.MAX_HP):
		state.take_damage_for(0)
	assert_false(state.player_alive[0], "P1 should be dead before respawn")
	state.respawn_dead_players()
	assert_true(state.player_alive[0], "P1 should be alive after respawn")
	assert_eq(state.player_hp[0], GameState.MAX_HP, "P1 should have full HP")
	assert_eq(state.player_shield[0], 0, "P1 shield should be 0 after respawn")


func test_shared_score_two_players() -> void:
	var state := GameState.new()
	state.setup_players(2)
	state.add_score(100)
	state.add_score(200)
	assert_eq(state.score, 300, "Score should be shared (300 total)")


func test_two_player_shield_independent() -> void:
	var state := GameState.new()
	state.setup_players(2)
	state.add_shield_for(0, 2)
	state.add_shield_for(1, 3)
	assert_eq(state.player_shield[0], 2, "P1 shield should be 2")
	assert_eq(state.player_shield[1], 3, "P2 shield should be 3")
	state.take_damage_for(0, 1)
	assert_eq(state.player_shield[0], 1, "P1 shield should absorb damage")
	assert_eq(state.player_shield[1], 3, "P2 shield should be unaffected")


# --- Score Multiplier Tests ---


func test_multiplier_starts_at_one() -> void:
	var state := GameState.new()
	assert_eq(state.score_multiplier, 1.0, "Multiplier should start at 1.0")


func test_multiplier_increases_after_kill_streak() -> void:
	var state := GameState.new()
	# 5 kills without damage should increase multiplier to 1.5
	for i: int in range(GameState.KILLS_PER_MULTIPLIER_TIER):
		state.register_kill()
	assert_eq(state.score_multiplier, 1.5, "Multiplier should be 1.5 after one tier")


func test_multiplier_caps_at_max() -> void:
	var state := GameState.new()
	# Register many kills to exceed max
	for i: int in range(50):
		state.register_kill()
	assert_eq(
		state.score_multiplier,
		GameState.MAX_MULTIPLIER,
		"Multiplier should cap at MAX_MULTIPLIER",
	)


func test_multiplier_drops_on_damage() -> void:
	var state := GameState.new()
	# Build up to 2.0x
	for i: int in range(GameState.KILLS_PER_MULTIPLIER_TIER * 2):
		state.register_kill()
	assert_eq(state.score_multiplier, 2.0, "Multiplier should be 2.0")
	state.take_damage()
	assert_eq(state.score_multiplier, 1.5, "Multiplier should drop by one tier on damage")


func test_multiplier_floors_at_one() -> void:
	var state := GameState.new()
	# Multiplier starts at 1.0; taking damage should not go below 1.0
	state.take_damage()
	assert_eq(state.score_multiplier, 1.0, "Multiplier should not go below 1.0")


func test_score_uses_multiplier() -> void:
	var state := GameState.new()
	# Build to 1.5x
	for i: int in range(GameState.KILLS_PER_MULTIPLIER_TIER):
		state.register_kill()
	state.add_score(100)
	assert_eq(state.score, 150, "Score should be 150 at 1.5x multiplier")


func test_wave_clear_bonus_perfect() -> void:
	var state := GameState.new()
	state.reset_wave_damage()
	# No damage taken = perfect wave
	state.award_wave_clear_bonus(3)
	# Perfect bonus = wave * BASE * 2 = 3 * 200 * 2 = 1200
	assert_eq(state.score, 1200, "Perfect wave bonus should be doubled")


func test_wave_clear_bonus_with_damage() -> void:
	var state := GameState.new()
	state.reset_wave_damage()
	state.take_damage()  # Take 1 damage
	state.award_wave_clear_bonus(2)
	# Normal bonus = wave * BASE = 2 * 200 = 400
	# Score also includes no kill-multiplied score, just the bonus
	assert_eq(state.score, 400, "Wave clear bonus with damage should be base amount")


func test_reset_clears_multiplier() -> void:
	var state := GameState.new()
	for i: int in range(GameState.KILLS_PER_MULTIPLIER_TIER):
		state.register_kill()
	assert_eq(state.score_multiplier, 1.5, "Multiplier should be 1.5 before reset")
	state.reset()
	assert_eq(state.score_multiplier, 1.0, "Multiplier should reset to 1.0")

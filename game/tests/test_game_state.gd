extends GutTest
## Tests for GameState resource: score, HP, and wave tracking.


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

extends GutTest
## Tests for player stats and damage interaction via GameState.


func test_player_initial_hp_is_three() -> void:
	var state := GameState.new()
	assert_eq(state.hp, 3, "Player should start with 3 HP")
	assert_eq(GameState.MAX_HP, 3, "MAX_HP constant should be 3")


func test_multiple_hits_reduce_hp_correctly() -> void:
	var state := GameState.new()
	state.take_damage(2)
	assert_eq(state.hp, 1, "Taking 2 damage from 3 HP should leave 1")


func test_damage_cannot_go_negative() -> void:
	var state := GameState.new()
	state.take_damage(999)
	assert_eq(state.hp, 0, "HP should clamp at 0, never go negative")
	assert_true(state.is_game_over(), "Game should be over at 0 HP")

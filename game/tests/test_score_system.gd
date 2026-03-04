extends GutTest
## Tests for score accumulation and signal emission.

var _last_score_received: int = -1


func before_each() -> void:
	_last_score_received = -1


func test_score_signal_emitted_on_add() -> void:
	var state := GameState.new()
	state.score_changed.connect(_on_score_changed)
	state.add_score(100)
	assert_eq(_last_score_received, 100, "Signal should emit with new score value")


func test_score_signal_cumulative() -> void:
	var state := GameState.new()
	state.score_changed.connect(_on_score_changed)
	state.add_score(100)
	state.add_score(200)
	assert_eq(_last_score_received, 300, "Signal should emit cumulative score")


func test_hp_signal_emitted_on_damage() -> void:
	var state := GameState.new()
	var hp_received: int = -1
	state.hp_changed.connect(func(hp: int) -> void: hp_received = hp)
	state.take_damage()
	assert_eq(hp_received, GameState.MAX_HP - 1, "HP signal should emit new HP value")


func test_player_died_signal() -> void:
	var state := GameState.new()
	var died: bool = false
	state.player_died.connect(func() -> void: died = true)
	for i: int in range(GameState.MAX_HP):
		state.take_damage()
	assert_true(died, "player_died signal should fire when HP reaches 0")


func _on_score_changed(new_score: int) -> void:
	_last_score_received = new_score

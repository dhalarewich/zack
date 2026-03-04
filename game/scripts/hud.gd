extends CanvasLayer
## Heads-up display: shows score, HP, and wave number during gameplay.

@onready var _score_label: Label = %ScoreLabel
@onready var _hp_label: Label = %HPLabel
@onready var _wave_label: Label = %WaveLabel

var _game_state: GameState


func setup(game_state: GameState) -> void:
	_game_state = game_state
	_game_state.score_changed.connect(_on_score_changed)
	_game_state.hp_changed.connect(_on_hp_changed)
	_update_all()


func set_wave(wave: int) -> void:
	if _wave_label:
		_wave_label.text = "WAVE " + str(wave)


func _update_all() -> void:
	if _game_state:
		_on_score_changed(_game_state.score)
		_on_hp_changed(_game_state.hp)
		set_wave(_game_state.current_wave)


func _on_score_changed(new_score: int) -> void:
	if _score_label:
		_score_label.text = "SCORE: " + str(new_score)


func _on_hp_changed(new_hp: int) -> void:
	if _hp_label:
		_hp_label.text = "HP: " + str(new_hp)

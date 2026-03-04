extends Control
## Game over screen: displays final score and lets player retry.

signal retry_game

@onready var _score_label: Label = %FinalScoreLabel
var _input_cooldown: float = 0.5


func show_score(final_score: int) -> void:
	if _score_label:
		_score_label.text = "SCORE: " + str(final_score)
	_input_cooldown = 0.5


func _process(delta: float) -> void:
	if _input_cooldown > 0.0:
		_input_cooldown -= delta


func _unhandled_input(event: InputEvent) -> void:
	if _input_cooldown > 0.0:
		return
	if event.is_action_pressed("accept"):
		retry_game.emit()
		get_viewport().set_input_as_handled()

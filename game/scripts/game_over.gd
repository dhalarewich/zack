extends Control
## Game over screen: displays final score and lets player retry.

signal retry_game

var _input_cooldown: float = 0.5

@onready var _score_label: Label = %FinalScoreLabel
@onready var _title_label: Label = %GameOverLabel
@onready var _retry_label: Label = %RetryLabel


func show_score(final_score: int) -> void:
	if _score_label:
		_score_label.text = "SCORE: " + str(final_score)
	_input_cooldown = 0.5


func show_victory(final_score: int) -> void:
	if _title_label:
		_title_label.text = "YOU WIN!"
	if _score_label:
		_score_label.text = "FINAL SCORE: " + str(final_score)
	if _retry_label:
		_retry_label.text = "PRESS ENTER TO PLAY AGAIN"
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

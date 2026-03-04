extends Control
## Title screen: shows game name and waits for player to press accept.

signal start_game

@onready var _blink_timer: float = 0.0
@onready var _prompt_label: Label = %PromptLabel


func _process(delta: float) -> void:
	_blink_timer += delta
	if _prompt_label:
		_prompt_label.visible = fmod(_blink_timer, 1.0) < 0.65


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("accept"):
		start_game.emit()
		get_viewport().set_input_as_handled()

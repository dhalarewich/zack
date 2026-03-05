extends Control
## Game over screen: displays story text, crashed ship, final score, and lets player retry.

signal retry_game

var _final_score: int = 0
var _input_cooldown: float = 0.5

@onready var _title_label: Label = %GameOverLabel
@onready var _description_label: Label = %DescriptionLabel
@onready var _score_label: Label = %FinalScoreLabel
@onready var _retry_label: Label = %RetryLabel
@onready var _ship_image: TextureRect = %ShipImage


func setup(final_score: int) -> void:
	_final_score = final_score


func _ready() -> void:
	if _score_label:
		_score_label.text = "SCORE: " + str(_final_score)
	if DisplayServer.is_touchscreen_available() and _retry_label:
		_retry_label.text = "TAP TO RETRY"
	_input_cooldown = 0.5


func _process(delta: float) -> void:
	if _input_cooldown > 0.0:
		_input_cooldown -= delta


func _input(event: InputEvent) -> void:
	if _input_cooldown > 0.0:
		return
	if _is_tap(event):
		retry_game.emit()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _input_cooldown > 0.0:
		return
	if event.is_action_pressed("accept"):
		retry_game.emit()
		get_viewport().set_input_as_handled()


static func _is_tap(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		if DisplayServer.is_touchscreen_available():
			return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	return false

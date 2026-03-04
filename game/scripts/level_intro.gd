extends Control
## Brief splash screen shown before each level starts.
## Displays level number and name, then auto-advances after a short delay.

signal intro_finished

const DISPLAY_TIME: float = 3.0

var _timer: float = 0.0
var _can_skip: bool = false

@onready var _level_number_label: Label = %LevelNumberLabel
@onready var _level_name_label: Label = %LevelNameLabel


func setup(level_data: LevelData) -> void:
	if _level_number_label:
		_level_number_label.text = "LEVEL " + str(level_data.level_number)
	if _level_name_label:
		_level_name_label.text = level_data.level_name


func _ready() -> void:
	_timer = DISPLAY_TIME
	# Brief delay before accepting skip input.
	await get_tree().create_timer(0.5).timeout
	_can_skip = true


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		intro_finished.emit()
		set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if _can_skip and event.is_action_pressed("accept"):
		intro_finished.emit()
		set_process(false)
		get_viewport().set_input_as_handled()

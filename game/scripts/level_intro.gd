extends Control
## Brief splash screen shown before each level starts.
## Displays level number and name, then auto-advances after a short delay.

signal intro_finished

const DISPLAY_TIME: float = 3.0

var _timer: float = 0.0
var _can_skip: bool = false
var _level_data: LevelData

@onready var _level_number_label: Label = %LevelNumberLabel
@onready var _level_name_label: Label = %LevelNameLabel


func setup(level_data: LevelData) -> void:
	_level_data = level_data


func _ready() -> void:
	if _level_data:
		if _level_number_label:
			_level_number_label.text = "LEVEL " + str(_level_data.level_number)
		if _level_name_label:
			_level_name_label.text = _level_data.level_name
	_timer = DISPLAY_TIME
	# Brief delay before accepting skip input.
	await get_tree().create_timer(0.5).timeout
	_can_skip = true


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		intro_finished.emit()
		set_process(false)


func _input(event: InputEvent) -> void:
	if not _can_skip:
		return
	if _is_tap(event):
		intro_finished.emit()
		set_process(false)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_skip:
		return
	if event.is_action_pressed("accept"):
		intro_finished.emit()
		set_process(false)
		get_viewport().set_input_as_handled()


static func _is_tap(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		if DisplayServer.is_touchscreen_available():
			return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	return false

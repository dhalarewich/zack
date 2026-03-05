extends Control
## Title screen: shows game name, mode selector (1P/2P), waits for accept.
## Mode selection uses two side-by-side labels with active/dim color styling.

signal start_game(player_count: int)

var _selected_mode: int = 1
var _active_settings: LabelSettings
var _dim_settings: LabelSettings

@onready var _pulse_timer: float = 0.0
@onready var _prompt_label: Label = %PromptLabel
@onready var _mode1_label: Label = %Mode1Label
@onready var _mode2_label: Label = %Mode2Label


func _ready() -> void:
	# Grab the initial label settings to reuse for swapping
	if _mode1_label:
		_active_settings = _mode1_label.label_settings
	if _mode2_label:
		_dim_settings = _mode2_label.label_settings
	_update_mode_labels()
	# On touch devices, hide 2P option and update prompt
	if DisplayServer.is_touchscreen_available():
		if _prompt_label:
			_prompt_label.text = "TAP TO START"
		if _mode1_label:
			_mode1_label.visible = false
		if _mode2_label:
			_mode2_label.visible = false


func _process(delta: float) -> void:
	_pulse_timer += delta
	if _prompt_label:
		var pulse: float = 1.0 + 0.08 * sin(_pulse_timer * 3.0)
		_prompt_label.scale = Vector2(pulse, pulse)


func _input(event: InputEvent) -> void:
	# Catch taps early — _unhandled_input won't see them because
	# Background (TextureRect) and BottomPanel (ColorRect) consume
	# the emulated mouse event with mouse_filter STOP.
	if _is_tap(event):
		start_game.emit(1)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		_selected_mode = 2 if _selected_mode == 1 else 1
		_update_mode_labels()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("accept"):
		start_game.emit(_selected_mode)
		get_viewport().set_input_as_handled()


static func _is_tap(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		if DisplayServer.is_touchscreen_available():
			return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	return false


func _update_mode_labels() -> void:
	if not _mode1_label or not _mode2_label:
		return
	if _selected_mode == 1:
		_mode1_label.label_settings = _active_settings
		_mode2_label.label_settings = _dim_settings
	else:
		_mode1_label.label_settings = _dim_settings
		_mode2_label.label_settings = _active_settings

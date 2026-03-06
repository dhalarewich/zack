extends CanvasLayer
## Pause overlay: dims the screen and shows RESUME / QUIT TO MENU options.
## Uses process_mode WHEN_PAUSED so input works while the tree is paused.

signal resume_requested
signal quit_to_menu_requested

const OPTION_RESUME: int = 0
const OPTION_QUIT: int = 1

var _selected: int = OPTION_RESUME
var _resume_label: Label
var _quit_label: Label
var _active_settings: LabelSettings
var _dim_settings: LabelSettings
var _draw_node: Control


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_build_ui()
	_update_labels()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("back"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("move_up") or event.is_action_pressed("move_left"):
		_selected = OPTION_RESUME
		_update_labels()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("move_right"):
		_selected = OPTION_QUIT
		_update_labels()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("accept"):
		_confirm_selection()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not _is_tap(event):
		return
	var vp_pos: Vector2 = _screen_to_viewport(event.position)
	if _is_in_label_area(vp_pos, 250.0):
		resume_requested.emit()
		get_viewport().set_input_as_handled()
	elif _is_in_label_area(vp_pos, 300.0):
		quit_to_menu_requested.emit()
		get_viewport().set_input_as_handled()


func _confirm_selection() -> void:
	if _selected == OPTION_RESUME:
		resume_requested.emit()
	else:
		quit_to_menu_requested.emit()


func _build_ui() -> void:
	_draw_node = Control.new()
	_draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_draw_node)

	# Semi-transparent black overlay
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_node.add_child(bg)

	# "PAUSED" title
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(title, 0.0, 170.0, 960.0, 230.0)
	var title_settings := LabelSettings.new()
	title_settings.font_size = 48
	title_settings.font_color = Color.WHITE
	title_settings.outline_size = 4
	title_settings.outline_color = Color.BLACK
	title.label_settings = title_settings
	_draw_node.add_child(title)

	# Label settings for menu options
	_active_settings = LabelSettings.new()
	_active_settings.font_size = 28
	_active_settings.font_color = Color(1.0, 1.0, 1.0, 1.0)
	_active_settings.outline_size = 3
	_active_settings.outline_color = Color.BLACK

	_dim_settings = LabelSettings.new()
	_dim_settings.font_size = 28
	_dim_settings.font_color = Color(0.5, 0.5, 0.5, 0.8)
	_dim_settings.outline_size = 3
	_dim_settings.outline_color = Color.BLACK

	# RESUME label
	_resume_label = Label.new()
	_resume_label.text = "RESUME"
	_resume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_resume_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_resume_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_resume_label, 0.0, 250.0, 960.0, 290.0)
	_draw_node.add_child(_resume_label)

	# QUIT TO MENU label
	_quit_label = Label.new()
	_quit_label.text = "QUIT TO MENU"
	_quit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_quit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_quit_label, 0.0, 300.0, 960.0, 340.0)
	_draw_node.add_child(_quit_label)


func _update_labels() -> void:
	if _selected == OPTION_RESUME:
		_resume_label.text = "> RESUME <"
		_resume_label.label_settings = _active_settings
		_quit_label.text = "QUIT TO MENU"
		_quit_label.label_settings = _dim_settings
	else:
		_resume_label.text = "RESUME"
		_resume_label.label_settings = _dim_settings
		_quit_label.text = "> QUIT TO MENU <"
		_quit_label.label_settings = _active_settings


func _set_rect(node: Control, left: float, top: float, right: float, bottom: float) -> void:
	node.offset_left = left
	node.offset_top = top
	node.offset_right = right
	node.offset_bottom = bottom


func _is_in_label_area(vp_pos: Vector2, y_top: float) -> bool:
	return (
		vp_pos.y >= y_top and vp_pos.y <= y_top + 40.0 and vp_pos.x >= 280.0 and vp_pos.x <= 680.0
	)


static func _is_tap(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		if DisplayServer.is_touchscreen_available():
			return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	return false


func _screen_to_viewport(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_screen_transform().affine_inverse() * screen_pos

extends CanvasLayer
## Virtual on-screen touch controls for mobile web.
## Renders a joystick (left) and fire button (right) and injects synthetic
## input via Input.action_press / Input.action_release so player.gd needs
## zero changes.

const JOYSTICK_CENTER := Vector2(120.0, 430.0)
const JOYSTICK_RADIUS: float = 60.0
const JOYSTICK_DEAD_ZONE: float = 12.0

const FIRE_CENTER := Vector2(840.0, 430.0)
const FIRE_RADIUS: float = 50.0

const BASE_ALPHA: float = 0.3
const ACTIVE_ALPHA: float = 0.5

var _joystick_finger: int = -1
var _joystick_start: Vector2 = Vector2.ZERO
var _joystick_current: Vector2 = Vector2.ZERO
var _fire_finger: int = -1

var _draw_node: Control


func _ready() -> void:
	layer = 100
	if not DisplayServer.is_touchscreen_available():
		visible = false
		set_process_input(false)
		return

	_draw_node = Control.new()
	_draw_node.name = "DrawLayer"
	_draw_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw_node.draw.connect(_on_draw)
	add_child(_draw_node)
	# On orientation change / resize, the screen→viewport transform changes
	# so we must release all fingers and redraw.
	get_viewport().size_changed.connect(_on_viewport_resized)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_drag(event as InputEventScreenDrag)
	elif event is InputEventMouseButton and DisplayServer.is_touchscreen_available():
		# Fallback: some mobile browsers only send emulated mouse events.
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var fake_touch := InputEventScreenTouch.new()
			fake_touch.index = 0
			fake_touch.position = mb.position
			fake_touch.pressed = mb.pressed
			_handle_touch(fake_touch)


func _handle_touch(event: InputEventScreenTouch) -> void:
	var vp_pos: Vector2 = _screen_to_viewport(event.position)

	if event.pressed:
		# Left half → joystick
		if vp_pos.x < 480.0 and _joystick_finger == -1:
			_joystick_finger = event.index
			_joystick_start = vp_pos
			_joystick_current = vp_pos
			_draw_node.queue_redraw()
			get_viewport().set_input_as_handled()
		# Right half → fire
		elif vp_pos.x >= 480.0 and _fire_finger == -1:
			_fire_finger = event.index
			Input.action_press("shoot")
			_draw_node.queue_redraw()
			get_viewport().set_input_as_handled()
	else:
		if event.index == _joystick_finger:
			_joystick_finger = -1
			Input.action_release("move_left")
			Input.action_release("move_right")
			Input.action_release("move_up")
			Input.action_release("move_down")
			_draw_node.queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.index == _fire_finger:
			_fire_finger = -1
			Input.action_release("shoot")
			_draw_node.queue_redraw()
			get_viewport().set_input_as_handled()


func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == _joystick_finger:
		var vp_pos: Vector2 = _screen_to_viewport(event.position)
		_joystick_current = vp_pos
		_apply_joystick_input()
		_draw_node.queue_redraw()
		get_viewport().set_input_as_handled()


func _apply_joystick_input() -> void:
	var delta_vec: Vector2 = _joystick_current - _joystick_start
	var dist: float = delta_vec.length()

	if dist < JOYSTICK_DEAD_ZONE:
		Input.action_release("move_left")
		Input.action_release("move_right")
		Input.action_release("move_up")
		Input.action_release("move_down")
		return

	var clamped: Vector2 = delta_vec
	if dist > JOYSTICK_RADIUS:
		clamped = delta_vec.normalized() * JOYSTICK_RADIUS

	var strength: Vector2 = clamped / JOYSTICK_RADIUS

	# Horizontal
	if strength.x < 0.0:
		Input.action_press("move_left", absf(strength.x))
		Input.action_release("move_right")
	elif strength.x > 0.0:
		Input.action_press("move_right", absf(strength.x))
		Input.action_release("move_left")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")

	# Vertical
	if strength.y < 0.0:
		Input.action_press("move_up", absf(strength.y))
		Input.action_release("move_down")
	elif strength.y > 0.0:
		Input.action_press("move_down", absf(strength.y))
		Input.action_release("move_up")
	else:
		Input.action_release("move_up")
		Input.action_release("move_down")


func _on_viewport_resized() -> void:
	# Release all active inputs so stale finger state doesn't persist
	# after an orientation change.
	if _joystick_finger != -1:
		_joystick_finger = -1
		Input.action_release("move_left")
		Input.action_release("move_right")
		Input.action_release("move_up")
		Input.action_release("move_down")
	if _fire_finger != -1:
		_fire_finger = -1
		Input.action_release("shoot")
	_draw_node.queue_redraw()


func _screen_to_viewport(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_screen_transform().affine_inverse() * screen_pos


func _on_draw() -> void:
	_draw_joystick()
	_draw_fire_button()


func _draw_joystick() -> void:
	var active: bool = _joystick_finger != -1
	var alpha: float = ACTIVE_ALPHA if active else BASE_ALPHA

	# Outer ring
	var base_center: Vector2 = _joystick_start if active else JOYSTICK_CENTER
	_draw_node.draw_arc(
		base_center, JOYSTICK_RADIUS, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, alpha), 2.0
	)

	# Inner knob
	var knob_pos: Vector2 = base_center
	if active:
		var delta_vec: Vector2 = _joystick_current - _joystick_start
		if delta_vec.length() > JOYSTICK_RADIUS:
			delta_vec = delta_vec.normalized() * JOYSTICK_RADIUS
		knob_pos = base_center + delta_vec
	_draw_node.draw_circle(knob_pos, 18.0, Color(1.0, 1.0, 1.0, alpha))


func _draw_fire_button() -> void:
	var active: bool = _fire_finger != -1
	var alpha: float = ACTIVE_ALPHA if active else BASE_ALPHA

	# Outer ring
	_draw_node.draw_arc(FIRE_CENTER, FIRE_RADIUS, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, alpha), 2.0)

	# Crosshair icon
	var s: float = 14.0
	var line_color := Color(1.0, 1.0, 1.0, alpha)
	_draw_node.draw_line(
		FIRE_CENTER + Vector2(0.0, -s), FIRE_CENTER + Vector2(0.0, s), line_color, 2.0
	)
	_draw_node.draw_line(
		FIRE_CENTER + Vector2(-s, 0.0), FIRE_CENTER + Vector2(s, 0.0), line_color, 2.0
	)
	_draw_node.draw_circle(FIRE_CENTER, 6.0, Color(1.0, 0.4, 0.3, alpha))

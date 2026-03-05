extends CanvasLayer
## Global fullscreen toggle button for touch devices.
## Added once by main.gd so it persists across all screens.
## Draws a small expand/collapse icon in the top-right corner.

const ICON_CENTER := Vector2(920.0, 30.0)
const TAP_RADIUS: float = 30.0
const ARROW_SIZE: float = 7.0
const ARROW_OFFSET: float = 10.0

var _draw_node: Control


func _ready() -> void:
	layer = 99
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


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var vp_pos: Vector2 = _screen_to_viewport(event.position)
		if vp_pos.distance_to(ICON_CENTER) <= TAP_RADIUS:
			_toggle_fullscreen()
			_draw_node.queue_redraw()
			get_viewport().set_input_as_handled()


func _toggle_fullscreen() -> void:
	var is_full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _screen_to_viewport(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_screen_transform().affine_inverse() * screen_pos


func _on_draw() -> void:
	var is_full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var alpha: float = 0.35
	var color := Color(1.0, 1.0, 1.0, alpha)

	# Background circle
	_draw_node.draw_circle(ICON_CENTER, 16.0, Color(0.0, 0.0, 0.0, 0.25))

	if is_full:
		# Collapse arrows — four arrows pointing inward
		_draw_corner_arrow(Vector2(-1.0, -1.0), true, color)
		_draw_corner_arrow(Vector2(1.0, -1.0), true, color)
		_draw_corner_arrow(Vector2(-1.0, 1.0), true, color)
		_draw_corner_arrow(Vector2(1.0, 1.0), true, color)
	else:
		# Expand arrows — four arrows pointing outward
		_draw_corner_arrow(Vector2(-1.0, -1.0), false, color)
		_draw_corner_arrow(Vector2(1.0, -1.0), false, color)
		_draw_corner_arrow(Vector2(-1.0, 1.0), false, color)
		_draw_corner_arrow(Vector2(1.0, 1.0), false, color)


func _draw_corner_arrow(direction: Vector2, inward: bool, color: Color) -> void:
	var corner: Vector2 = ICON_CENTER + direction * ARROW_OFFSET
	var tip: Vector2
	if inward:
		tip = ICON_CENTER + direction * 3.0
	else:
		tip = corner + direction * ARROW_SIZE
	_draw_node.draw_line(corner, tip, color, 2.0)
	# Small arrowhead lines
	var perp := Vector2(-direction.y, direction.x) * 3.0
	var back: Vector2
	if inward:
		back = tip + direction * 4.0
	else:
		back = tip - direction * 4.0
	_draw_node.draw_line(tip, back + perp, color, 1.5)
	_draw_node.draw_line(tip, back - perp, color, 1.5)

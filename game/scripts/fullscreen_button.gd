extends CanvasLayer
## Global fullscreen toggle button for touch devices.
## Added once by main.gd so it persists across all screens.
## Draws a small expand/collapse icon in the top-right corner.
## Uses the browser Fullscreen API via JavaScriptBridge on web.

const ICON_CENTER := Vector2(920.0, 30.0)
const TAP_RADIUS: float = 30.0
const ARROW_SIZE: float = 7.0
const ARROW_OFFSET: float = 10.0

var _draw_node: Control
var _is_fullscreen: bool = false


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

	# Listen for fullscreen changes via JS so the icon stays in sync.
	# NOTE: JavaScriptBridge.eval() is used here intentionally — this is a
	# Godot web export and eval is the standard way to call browser APIs
	# from GDScript (there is no other mechanism).
	if _has_js():
		JavaScriptBridge.eval(
			(
				"document.addEventListener('fullscreenchange', function() {"
				+ "  window._godotIsFullscreen = !!document.fullscreenElement;"
				+ "});"
			)
		)


func _input(event: InputEvent) -> void:
	if _is_tap(event):
		var vp_pos: Vector2 = _screen_to_viewport(event.position)
		if vp_pos.distance_to(ICON_CENTER) <= TAP_RADIUS:
			_toggle_fullscreen()
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	# Poll fullscreen state from JS each frame (cheap bool read).
	if _has_js():
		var js_val: Variant = JavaScriptBridge.eval("!!document.fullscreenElement")
		var new_state: bool = js_val == true
		if new_state != _is_fullscreen:
			_is_fullscreen = new_state
			_draw_node.queue_redraw()


func _toggle_fullscreen() -> void:
	if _has_js():
		# Use the browser Fullscreen API — DisplayServer.window_set_mode()
		# does not work on mobile browsers.
		if _is_fullscreen:
			JavaScriptBridge.eval("document.exitFullscreen().catch(function(){})")
		else:
			JavaScriptBridge.eval(
				(
					"document.documentElement.requestFullscreen"
					+ "? document.documentElement.requestFullscreen().catch(function(){})"
					+ ": (document.documentElement.webkitRequestFullscreen"
					+ "  ? document.documentElement.webkitRequestFullscreen()"
					+ "  : null)"
				)
			)
	else:
		# Fallback for non-web platforms
		var is_full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		if is_full:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_is_fullscreen = not is_full
		_draw_node.queue_redraw()


func _has_js() -> bool:
	return ClassDB.class_exists("JavaScriptBridge") and OS.has_feature("web")


func _screen_to_viewport(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_screen_transform().affine_inverse() * screen_pos


func _is_tap(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		if DisplayServer.is_touchscreen_available():
			return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	return false


func _on_draw() -> void:
	var alpha: float = 0.6
	var color := Color(1.0, 1.0, 1.0, alpha)

	# Background circle
	_draw_node.draw_circle(ICON_CENTER, 18.0, Color(0.0, 0.0, 0.0, 0.4))

	if _is_fullscreen:
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

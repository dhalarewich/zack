extends CharacterBody2D
## Player ship: moves via input actions, shoots bullets.

signal shoot_requested(position: Vector2, direction: Vector2)
signal player_hit

const SPEED: float = 300.0
const FIRE_COOLDOWN: float = 0.15

var _fire_timer: float = 0.0
var _shoot_direction: Vector2 = Vector2.UP

@onready var _laser_sound: AudioStreamPlayer2D = $LaserSound


func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_shooting(delta)
	_clamp_to_arena()


func _handle_movement() -> void:
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down"),
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	velocity = input_dir * SPEED
	if input_dir != Vector2.ZERO:
		_shoot_direction = input_dir.normalized()
	move_and_slide()


func _handle_shooting(delta: float) -> void:
	_fire_timer -= delta
	if Input.is_action_pressed("shoot") and _fire_timer <= 0.0:
		_fire_timer = FIRE_COOLDOWN
		shoot_requested.emit(global_position, _shoot_direction)
		if _laser_sound:
			_laser_sound.play()


func _clamp_to_arena() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	global_position = global_position.clamp(Vector2.ZERO, viewport_size)


func hit() -> void:
	player_hit.emit()

extends CharacterBody2D
## Basic enemy: moves toward the player. Dies when hit by a bullet.

signal enemy_destroyed(points: int)

const POINTS: int = 100
const CONTACT_COOLDOWN: float = 1.0

var speed: float = 80.0
var _target: Node2D = null
var _contact_timer: float = 0.0


func setup(target: Node2D, move_speed: float) -> void:
	_target = target
	speed = move_speed


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var dir: Vector2 = (_target.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	_contact_timer -= delta
	if _contact_timer <= 0.0:
		_check_player_contact()


func _check_player_contact() -> void:
	for i: int in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is CharacterBody2D and collider.has_method("hit"):
			collider.hit()
			_contact_timer = CONTACT_COOLDOWN


func take_hit() -> void:
	enemy_destroyed.emit(POINTS)
	queue_free()

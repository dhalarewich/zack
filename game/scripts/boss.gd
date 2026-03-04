extends CharacterBody2D
## Boss enemy: larger, more HP, appears after all waves in a level.
## Moves in patterns and requires multiple hits to defeat.

signal boss_destroyed(points: int)

const POINTS: int = 1000
const CONTACT_COOLDOWN: float = 0.8

var speed: float = 60.0
var hp: int = 10
var _target: Node2D = null
var _contact_timer: float = 0.0
var _phase_timer: float = 0.0


func setup(target: Node2D, boss_speed: float, boss_hp: int) -> void:
	_target = target
	speed = boss_speed
	hp = boss_hp


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	_phase_timer += delta
	var dir: Vector2 = _get_movement_direction()
	velocity = dir * speed
	move_and_slide()

	_contact_timer -= delta
	if _contact_timer <= 0.0:
		_check_player_contact()


func _get_movement_direction() -> Vector2:
	if not is_instance_valid(_target):
		return Vector2.ZERO
	# Sweep side-to-side while drifting toward player.
	var to_player: Vector2 = (_target.global_position - global_position).normalized()
	var sweep: Vector2 = Vector2(sin(_phase_timer * 2.0), 0.0)
	return (to_player * 0.7 + sweep * 0.3).normalized()


func _check_player_contact() -> void:
	for i: int in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is CharacterBody2D and collider.has_method("hit"):
			collider.hit()
			_contact_timer = CONTACT_COOLDOWN


func take_hit() -> void:
	hp -= 1
	if hp <= 0:
		boss_destroyed.emit(POINTS)
		queue_free()

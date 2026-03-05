extends CharacterBody2D
## Basic enemy: moves toward the closest alive player. Dies when hit by a bullet.
## Uses boid-like separation to prevent enemies from stacking on each other.
## Bounces away from player after contact to prevent sticking.
## Supports single target (backward compat) or array of targets for co-op.

signal enemy_destroyed(points: int, death_position: Vector2)

const POINTS: int = 100
const CONTACT_COOLDOWN: float = 1.0
const TARGET_SIZE: float = 55.0
const FLASH_DURATION: float = 0.08
const SEPARATION_RADIUS: float = 70.0
const SEPARATION_WEIGHT: float = 1.5
const BOUNCE_DURATION: float = 0.4
const BOUNCE_SPEED_MULT: float = 1.6

var speed: float = 80.0
var _targets: Array[Node2D] = []
var _contact_timer: float = 0.0
var _sprite_path: String = ""
var _dying: bool = false
var _bounce_timer: float = 0.0
var _bounce_dir: Vector2 = Vector2.ZERO


func setup(target: Variant, move_speed: float, sprite_path: String = "") -> void:
	if target is Array:
		for t: Node2D in target:
			_targets.append(t)
	elif target is Node2D:
		_targets.append(target)
	speed = move_speed
	_sprite_path = sprite_path


func _ready() -> void:
	if not _sprite_path.is_empty() and ResourceLoader.exists(_sprite_path):
		var sprite: Sprite2D = $Sprite
		if sprite:
			sprite.texture = load(_sprite_path)
			var tex_size: float = maxf(sprite.texture.get_width(), 1.0)
			var s: float = TARGET_SIZE / tex_size
			sprite.scale = Vector2(s, s)


func _physics_process(delta: float) -> void:
	if _dying:
		return

	# Bounce away from player after contact
	if _bounce_timer > 0.0:
		_bounce_timer -= delta
		velocity = _bounce_dir * speed * BOUNCE_SPEED_MULT
		move_and_slide()
		return

	var closest: Node2D = _get_closest_target()
	if not closest:
		return
	var dir: Vector2 = (closest.global_position - global_position).normalized()
	var separation: Vector2 = _get_separation_force() * SEPARATION_WEIGHT
	var combined: Vector2 = dir + separation
	if combined.length() > 0.01:
		velocity = combined.normalized() * speed
	else:
		velocity = dir * speed
	move_and_slide()

	_contact_timer -= delta
	if _contact_timer <= 0.0:
		_check_player_contact()


func _get_closest_target() -> Node2D:
	var closest: Node2D = null
	var closest_dist: float = INF
	for t: Node2D in _targets:
		if not is_instance_valid(t) or not t.visible:
			continue
		var dist: float = global_position.distance_to(t.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = t
	return closest


func _get_separation_force() -> Vector2:
	var force := Vector2.ZERO
	var parent := get_parent()
	if not parent:
		return force
	for child in parent.get_children():
		if child == self or not is_instance_valid(child):
			continue
		if not child is CharacterBody2D:
			continue
		var diff: Vector2 = global_position - child.global_position
		var dist: float = diff.length()
		if dist < SEPARATION_RADIUS and dist > 0.01:
			force += diff.normalized() * (1.0 - dist / SEPARATION_RADIUS)
	return force


func _check_player_contact() -> void:
	for i: int in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is CharacterBody2D and collider.has_method("hit"):
			collider.hit()
			_contact_timer = CONTACT_COOLDOWN
			# Bounce away from the player to prevent sticking
			var away: Vector2 = global_position - collider.global_position
			if away.length() > 0.01:
				_bounce_dir = away.normalized()
			else:
				_bounce_dir = Vector2.UP
			_bounce_timer = BOUNCE_DURATION


func take_hit() -> void:
	if _dying:
		return
	_dying = true
	enemy_destroyed.emit(POINTS, global_position)
	var sprite: Sprite2D = $Sprite
	if sprite:
		sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, FLASH_DURATION)
		tween.tween_callback(queue_free)
	else:
		queue_free()

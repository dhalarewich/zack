extends CharacterBody2D
## Boss enemy: larger, more HP, appears after all waves in a level.
## Moves in patterns, shoots at the closest alive player, requires many hits.
## Supports single target (backward compat) or array of targets for co-op.
## On death: pulses 3x, plays explosion sound, then emits boss_destroyed.
## Enhanced bosses can have spark particles, dart attacks, and custom scale.

signal boss_destroyed(points: int)
signal boss_shoot_requested(pos: Vector2, dir: Vector2, bullet_color: Color)
signal boss_hp_changed(current_hp: int, max_hp: int)

const POINTS: int = 1000
const CONTACT_COOLDOWN: float = 0.8
const FLASH_DURATION: float = 0.1
const DEATH_PULSE_COUNT: int = 3
const DEATH_PULSE_DURATION: float = 0.15

# Dart attack constants
const DART_SPEED_MULT: float = 4.0
const DART_DURATION: float = 0.5
const DART_STOP_DISTANCE: float = 80.0
const DART_COOLDOWN_MIN: float = 4.0
const DART_COOLDOWN_MAX: float = 8.0

# Contact bounce constants (prevents sticking to player)
const BOUNCE_DURATION: float = 0.25
const BOUNCE_SPEED_MULT: float = 1.3

var speed: float = 60.0
var hp: int = 10
var _max_hp: int = 10
var _targets: Array[Node2D] = []
var _contact_timer: float = 0.0
var _phase_timer: float = 0.0
var _sprite_path: String = ""
var _dying: bool = false
var _explosion_sound: AudioStreamPlayer2D
var _boss_scale: float = 1.0

# Shooting config
var _bullet_color: Color = Color(1.0, 0.2, 0.2, 1.0)
var _fire_interval_min: float = 1.5
var _fire_interval_max: float = 3.5
var _spread_count: int = 1
var _spread_angle: float = 0.0
var _fire_timer: float = 0.0
var _rng := RandomNumberGenerator.new()

# Particle config
var _has_particles: bool = false
var _particle_color: Color = Color(1.0, 0.2, 0.1, 1.0)

# Dart attack config
var _has_dart_attack: bool = false
var _dart_timer: float = 0.0
var _darting: bool = false
var _dart_elapsed: float = 0.0
var _dart_dir: Vector2 = Vector2.ZERO
var _dart_sound: AudioStreamPlayer2D
var _bounce_timer: float = 0.0
var _bounce_dir: Vector2 = Vector2.ZERO


func setup(
	target: Variant,
	boss_speed: float,
	boss_hp: int,
	sprite_path: String = "",
	bullet_color: Color = Color(1.0, 0.2, 0.2, 1.0),
	fire_min: float = 1.5,
	fire_max: float = 3.5,
	spread_count: int = 1,
	spread_angle: float = 0.0,
) -> void:
	if target is Array:
		for t: Node2D in target:
			_targets.append(t)
	elif target is Node2D:
		_targets.append(target)
	speed = boss_speed
	hp = boss_hp
	_max_hp = boss_hp
	_sprite_path = sprite_path
	_bullet_color = bullet_color
	_fire_interval_min = fire_min
	_fire_interval_max = fire_max
	_spread_count = spread_count
	_spread_angle = spread_angle


## Configure enhanced boss features: scale, particles, dart attack.
func setup_enhancements(
	scale_factor: float = 1.0,
	has_particles: bool = false,
	particle_color: Color = Color(1.0, 0.2, 0.1, 1.0),
	has_dart_attack: bool = false,
) -> void:
	_boss_scale = scale_factor
	_has_particles = has_particles
	_particle_color = particle_color
	_has_dart_attack = has_dart_attack


func _ready() -> void:
	_rng.randomize()
	_fire_timer = _rng.randf_range(_fire_interval_min, _fire_interval_max)
	if _has_dart_attack:
		_dart_timer = _rng.randf_range(DART_COOLDOWN_MIN, DART_COOLDOWN_MAX)

	if not _sprite_path.is_empty() and ResourceLoader.exists(_sprite_path):
		var sprite: Sprite2D = $Sprite
		if sprite:
			sprite.texture = load(_sprite_path)

	# Apply boss scale
	if _boss_scale != 1.0:
		var sprite: Sprite2D = $Sprite
		if sprite:
			sprite.scale *= _boss_scale
		var col: CollisionShape2D = $CollisionShape2D
		if col:
			col.scale *= _boss_scale
		var hit_shape: CollisionShape2D = get_node_or_null("HitArea/HitShape")
		if hit_shape:
			hit_shape.scale *= _boss_scale

	# Setup spark particles
	if _has_particles:
		_setup_spark_particles()

	# Setup dart attack sound
	if _has_dart_attack:
		_dart_sound = AudioStreamPlayer2D.new()
		_dart_sound.stream = _create_dart_sound()
		_dart_sound.volume_db = 0.0
		add_child(_dart_sound)

	_explosion_sound = AudioStreamPlayer2D.new()
	_explosion_sound.stream = _create_explosion_sound()
	_explosion_sound.volume_db = 2.0
	add_child(_explosion_sound)


func _physics_process(delta: float) -> void:
	if _dying:
		return

	# Bounce away from player after contact (prevents sticking)
	if _bounce_timer > 0.0:
		_bounce_timer -= delta
		velocity = _bounce_dir * speed * BOUNCE_SPEED_MULT
		move_and_slide()
		return

	# Handle dart attack movement
	if _darting:
		_dart_elapsed += delta
		if _dart_elapsed >= DART_DURATION:
			_darting = false
		else:
			velocity = _dart_dir * speed * DART_SPEED_MULT
			move_and_slide()
			_contact_timer -= delta
			if _contact_timer <= 0.0:
				_check_player_contact()
			return

	var closest: Node2D = _get_closest_target()
	if not closest:
		return
	_phase_timer += delta
	var dir: Vector2 = _get_movement_direction(closest)
	velocity = dir * speed
	move_and_slide()

	_contact_timer -= delta
	if _contact_timer <= 0.0:
		_check_player_contact()

	# Shooting
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = _rng.randf_range(_fire_interval_min, _fire_interval_max)
		_shoot(closest)

	# Dart attack
	if _has_dart_attack:
		_dart_timer -= delta
		if _dart_timer <= 0.0:
			_start_dart_attack(closest)


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


func _get_movement_direction(target: Node2D) -> Vector2:
	# Sweep side-to-side while drifting toward player.
	var to_player: Vector2 = (target.global_position - global_position).normalized()
	var sweep: Vector2 = Vector2(sin(_phase_timer * 2.0), 0.0)
	return (to_player * 0.7 + sweep * 0.3).normalized()


func _start_dart_attack(target: Node2D) -> void:
	_dart_timer = _rng.randf_range(DART_COOLDOWN_MIN, DART_COOLDOWN_MAX)
	var to_target: Vector2 = target.global_position - global_position
	var dist: float = to_target.length()
	if dist < DART_STOP_DISTANCE:
		return
	_dart_dir = to_target.normalized()
	_darting = true
	_dart_elapsed = 0.0
	if _dart_sound:
		_dart_sound.play()
	# Brief red flash to telegraph the dart
	var sprite: Sprite2D = $Sprite
	if sprite:
		sprite.modulate = Color(2.0, 0.5, 0.5, 1.0)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)


func _shoot(target: Node2D) -> void:
	var shoot_dir: Vector2 = (target.global_position - global_position).normalized()

	if _spread_count <= 1:
		boss_shoot_requested.emit(global_position, shoot_dir, _bullet_color)
	else:
		# Fire spread pattern
		var half_angle: float = deg_to_rad(_spread_angle) / 2.0
		for i: int in _spread_count:
			var frac: float = 0.0
			if _spread_count > 1:
				frac = float(i) / float(_spread_count - 1)
			var angle_offset: float = lerp(-half_angle, half_angle, frac)
			var rotated_dir: Vector2 = shoot_dir.rotated(angle_offset)
			boss_shoot_requested.emit(global_position, rotated_dir, _bullet_color)


func _check_player_contact() -> void:
	if _dying:
		return
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
			_darting = false


func take_hit() -> void:
	if _dying:
		return
	hp -= 1
	boss_hp_changed.emit(hp, _max_hp)
	_flash()
	if hp <= 0:
		_start_death_animation()


func _start_death_animation() -> void:
	_dying = true
	velocity = Vector2.ZERO

	if _explosion_sound:
		_explosion_sound.play()

	var sprite: Sprite2D = $Sprite
	if not sprite:
		boss_destroyed.emit(POINTS)
		queue_free()
		return

	var tween := create_tween()
	# 3 bright pulses: flash bright -> fade back
	for i: int in DEATH_PULSE_COUNT:
		tween.tween_property(sprite, "modulate", Color(4.0, 4.0, 4.0, 1.0), 0.05)
		tween.tween_property(sprite, "modulate", Color.WHITE, DEATH_PULSE_DURATION)
	# Final fade out
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.15)
	tween.tween_callback(_on_death_complete)


func _on_death_complete() -> void:
	boss_destroyed.emit(POINTS)
	queue_free()


func _flash() -> void:
	if _dying:
		return
	var sprite: Sprite2D = $Sprite
	if sprite:
		sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, FLASH_DURATION)


func _setup_spark_particles() -> void:
	var particles := GPUParticles2D.new()
	particles.amount = 12
	particles.lifetime = 0.8
	particles.preprocess = 0.5
	particles.randomness = 0.5
	particles.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 60.0
	mat.gravity = Vector3(0, 30, 0)
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = _particle_color
	# Fade out over lifetime
	var gradient := GradientTexture1D.new()
	var g := Gradient.new()
	g.set_color(0, _particle_color)
	g.add_point(0.5, Color(_particle_color.r, _particle_color.g, _particle_color.b, 0.6))
	g.set_color(g.get_point_count() - 1, Color(_particle_color.r, _particle_color.g, 0.0, 0.0))
	gradient.gradient = g
	mat.color_ramp = gradient

	particles.process_material = mat
	add_child(particles)


func _create_dart_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.3
	var sample_count: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng_local := RandomNumberGenerator.new()
	rng_local.seed = 77
	for i: int in sample_count:
		var t: float = float(i) / sample_rate
		var env: float = maxf(1.0 - t / duration, 0.0)
		# Descending screech (high freq sweep down)
		var freq: float = 800.0 - t * 2000.0
		var screech: float = sin(t * freq * TAU) * 0.4
		# Harsh buzz
		var buzz: float = sin(t * 180.0 * TAU) * 0.3
		# Noise
		var noise: float = (rng_local.randf() * 2.0 - 1.0) * 0.3 * env
		var wave: float = (screech + buzz + noise) * env * env
		var sample: int = int(clampf(wave, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


func _create_explosion_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.6
	var sample_count: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng_local := RandomNumberGenerator.new()
	rng_local.seed = 99
	for i: int in sample_count:
		var t: float = float(i) / sample_rate
		var env: float = (1.0 - t / duration) * (1.0 - t / duration)
		# Bass rumble (40-80 Hz sweep down)
		var freq: float = 80.0 - t * 60.0
		var rumble: float = sin(t * freq * TAU) * 0.5
		# Mid crunch
		var crunch: float = sin(t * 200.0 * TAU) * 0.3 * maxf(1.0 - t * 3.0, 0.0)
		# Noise burst
		var noise: float = (rng_local.randf() * 2.0 - 1.0) * 0.4 * maxf(1.0 - t * 2.0, 0.0)
		var wave: float = (rumble + crunch + noise) * env
		var sample: int = int(clampf(wave, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

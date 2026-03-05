extends CharacterBody2D
## Player ship: moves via input actions, shoots bullets, collects power-ups.
## Has invincibility frames after taking damage to prevent instant death.
## Supports per-player input via action prefix (e.g., "p1_" or "p2_").

signal shoot_requested(position: Vector2, direction: Vector2, player_idx: int)
signal player_hit(player_idx: int)
signal power_up_collected(type: String, player_idx: int)

const SPEED: float = 300.0
const FIRE_COOLDOWN: float = 0.15
const FLASH_DURATION: float = 0.12
const HIT_INVINCIBILITY: float = 1.5
const BLINK_RATE: float = 10.0

var player_index: int = 0
var _action_prefix: String = ""
var _fire_timer: float = 0.0
var _shoot_direction: Vector2 = Vector2.UP
var _hit_sound: AudioStreamPlayer2D
var _thruster_sound: AudioStreamPlayer2D
var _health_pickup_sound: AudioStreamPlayer2D
var _shield_pickup_sound: AudioStreamPlayer2D
var _shield_break_sound: AudioStreamPlayer2D
var _is_thrusting: bool = false
var _invincible: bool = false
var _invincible_timer: float = 0.0
var _disabled: bool = false

@onready var _laser_sound: AudioStreamPlayer2D = $LaserSound
@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_hit_sound = AudioStreamPlayer2D.new()
	_hit_sound.stream = _create_hit_sound()
	_hit_sound.volume_db = 0.0
	add_child(_hit_sound)

	_thruster_sound = AudioStreamPlayer2D.new()
	_thruster_sound.stream = _create_thruster_sound()
	_thruster_sound.volume_db = -14.0
	add_child(_thruster_sound)

	_health_pickup_sound = AudioStreamPlayer2D.new()
	_health_pickup_sound.stream = _create_health_pickup_sound()
	_health_pickup_sound.volume_db = -2.0
	add_child(_health_pickup_sound)

	_shield_pickup_sound = AudioStreamPlayer2D.new()
	_shield_pickup_sound.stream = _create_shield_pickup_sound()
	_shield_pickup_sound.volume_db = -2.0
	add_child(_shield_pickup_sound)

	_shield_break_sound = AudioStreamPlayer2D.new()
	_shield_break_sound.stream = _create_shield_break_sound()
	_shield_break_sound.volume_db = 0.0
	add_child(_shield_break_sound)


func setup_input(index: int, action_prefix: String) -> void:
	player_index = index
	_action_prefix = action_prefix


func disable() -> void:
	_disabled = true
	visible = false
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)


func enable() -> void:
	_disabled = false
	visible = true
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)
	_invincible = false
	if _sprite:
		_sprite.modulate = Color.WHITE


func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_shooting(delta)
	_handle_thruster()
	_handle_invincibility(delta)
	_clamp_to_arena()


func _handle_movement() -> void:
	var input_dir := Vector2(
		Input.get_axis(_action_prefix + "move_left", _action_prefix + "move_right"),
		Input.get_axis(_action_prefix + "move_up", _action_prefix + "move_down"),
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	velocity = input_dir * SPEED
	move_and_slide()


func _handle_shooting(delta: float) -> void:
	_fire_timer -= delta
	if Input.is_action_pressed(_action_prefix + "shoot") and _fire_timer <= 0.0:
		_fire_timer = FIRE_COOLDOWN
		shoot_requested.emit(global_position, _shoot_direction, player_index)
		if _laser_sound:
			_laser_sound.play()


func _handle_thruster() -> void:
	var moving: bool = velocity.length() > 1.0
	if moving and not _is_thrusting:
		_is_thrusting = true
		if _thruster_sound and not _thruster_sound.playing:
			_thruster_sound.play()
	elif not moving and _is_thrusting:
		_is_thrusting = false
		if _thruster_sound:
			_thruster_sound.stop()


func _handle_invincibility(delta: float) -> void:
	if not _invincible:
		return
	_invincible_timer -= delta
	if _invincible_timer <= 0.0:
		_invincible = false
		if _sprite:
			_sprite.modulate = Color.WHITE
	elif _sprite:
		# Blink effect: alternate between dim and full brightness
		var blink: float = sin(_invincible_timer * BLINK_RATE * TAU)
		if blink > 0.0:
			_sprite.modulate.a = 0.3
		else:
			_sprite.modulate.a = 1.0


func _clamp_to_arena() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	global_position = global_position.clamp(Vector2.ZERO, viewport_size)


func hit() -> void:
	if _invincible or _disabled:
		return
	_invincible = true
	_invincible_timer = HIT_INVINCIBILITY
	player_hit.emit(player_index)
	if _hit_sound:
		_hit_sound.play()
	_flash()


func collect_power_up(type: String) -> void:
	power_up_collected.emit(type, player_index)
	if type == "health":
		_play_health_effect()
	else:
		_play_shield_effect()


func play_shield_break_sound() -> void:
	if _shield_break_sound:
		_shield_break_sound.play()


func _play_health_effect() -> void:
	if _health_pickup_sound:
		_health_pickup_sound.play()
	# Green pulse
	if _sprite:
		_sprite.modulate = Color(0.3, 2.0, 0.3, 1.0)
		var tween := create_tween()
		tween.tween_property(_sprite, "modulate", Color.WHITE, 0.2)


func _play_shield_effect() -> void:
	if _shield_pickup_sound:
		_shield_pickup_sound.play()
	# Yellow double-pulse
	if _sprite:
		var tween := create_tween()
		tween.tween_property(_sprite, "modulate", Color(2.0, 2.0, 0.3, 1.0), 0.05)
		tween.tween_property(_sprite, "modulate", Color.WHITE, 0.1)
		tween.tween_property(_sprite, "modulate", Color(2.0, 2.0, 0.3, 1.0), 0.05)
		tween.tween_property(_sprite, "modulate", Color.WHITE, 0.1)


func _flash() -> void:
	if _sprite:
		_sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
		var tween := create_tween()
		tween.tween_property(_sprite, "modulate", Color.WHITE, FLASH_DURATION)


func _create_hit_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.08
	var sample_count: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i: int in sample_count:
		var t: float = float(i) / sample_rate
		var env: float = 1.0 - t / duration
		var wave: float = sin(t * 800.0 * TAU) * 0.5 + sin(t * 400.0 * TAU) * 0.4
		var sample: int = int(clampf(wave * env, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


# Rocket thruster: filtered noise roar + high-freq turbulence + subtle resonance
func _create_thruster_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.5
	var sample_count: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var filtered_noise: float = 0.0
	for i: int in sample_count:
		var t: float = float(i) / sample_rate
		# Slow amplitude modulation for natural engine fluctuation
		var mod: float = 0.8 + 0.2 * sin(t * 8.0 * TAU)
		# Raw white noise source
		var raw_noise: float = rng.randf() * 2.0 - 1.0
		# Low-pass filter to shape noise into a deep roar (~600 Hz cutoff)
		filtered_noise = filtered_noise * 0.82 + raw_noise * 0.18
		# High-frequency turbulence hiss (unfiltered, quieter)
		var hiss: float = raw_noise * 0.12
		# Very subtle low resonance (not a dominant tone, avoids buzzy sound)
		var resonance: float = sin(t * 40.0 * TAU) * 0.08
		# Combine: noise-based roar is the primary sound
		var wave: float = (filtered_noise * 0.55 + hiss + resonance) * mod
		var sample: int = int(clampf(wave, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = sample_count
	stream.data = data
	return stream


# Rising sweep "veeeeeeewp" for health pickup
func _create_health_pickup_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.35
	var sample_count: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i: int in sample_count:
		var t: float = float(i) / sample_rate
		var env: float = (1.0 - t / duration) * minf(t * 20.0, 1.0)
		var freq: float = 300.0 + (t / duration) * 900.0
		var wave: float = sin(t * freq * TAU) * 0.6 * env
		var sample: int = int(clampf(wave, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


# Metallic slide "Shhhhhhhwank!" for shield pickup
func _create_shield_pickup_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.4
	var sample_count: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i: int in sample_count:
		var t: float = float(i) / sample_rate
		var env: float = (1.0 - t / duration) * minf(t * 15.0, 1.0)
		var freq: float = 200.0 + (t / duration) * 600.0
		var tone: float = sin(t * freq * TAU) * 0.4
		var metallic: float = sin(t * freq * 2.5 * TAU) * 0.2
		var noise: float = (rng.randf() * 2.0 - 1.0) * 0.2 * maxf(1.0 - t * 4.0, 0.0)
		var wave: float = (tone + metallic + noise) * env
		var sample: int = int(clampf(wave, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


# Sharp "CHINNNG" for shield break
func _create_shield_break_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.25
	var sample_count: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	for i: int in sample_count:
		var t: float = float(i) / sample_rate
		var env: float = maxf(1.0 - t / duration, 0.0) * maxf(1.0 - t / duration, 0.0)
		var high: float = sin(t * 1500.0 * TAU) * 0.4
		var mid: float = sin(t * 600.0 * TAU) * 0.3
		var noise: float = (rng.randf() * 2.0 - 1.0) * 0.2
		var wave: float = (high + mid + noise) * env
		var sample: int = int(clampf(wave, -1.0, 1.0) * 32000.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

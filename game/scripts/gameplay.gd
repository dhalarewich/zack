extends Node2D
## Main gameplay scene: manages players, enemies, bullets, waves, and power-ups.
## Supports 1P and 2P co-op with per-player input and difficulty scaling.

signal game_over
signal level_cleared
signal quit_to_menu

const PlayerScene: PackedScene = preload("res://scenes/player.tscn")
const BulletScene: PackedScene = preload("res://scenes/bullet.tscn")
const EnemyScene: PackedScene = preload("res://scenes/enemy.tscn")
const BossScene: PackedScene = preload("res://scenes/boss.tscn")
const PowerUpScene: PackedScene = preload("res://scenes/power_up.tscn")
const TouchControlsScene: PackedScene = preload("res://scenes/touch_controls.tscn")
const PauseMenuScene: PackedScene = preload("res://scenes/PauseMenu.tscn")
const PLAYER2_SPRITE_PATH: String = "res://assets/sprites/player-ship2.png"
const ENEMY_SPRITES: Array[String] = [
	"res://assets/sprites/enemy-1.png",
	"res://assets/sprites/enemy-2.png",
	"res://assets/sprites/enemy-3.png",
	"res://assets/sprites/enemy-4.png",
	"res://assets/sprites/enemy-ship1.png",
	"res://assets/sprites/enemy-ship2.png",
	"res://assets/sprites/enemy-ship3.png",
	"res://assets/sprites/enemy-ship4.png",
]
const HEALTH_DROP_MIN: int = 8
const HEALTH_DROP_MAX: int = 12
const SHIELD_DROP_MIN: int = 16
const SHIELD_DROP_MAX: int = 24

# 2P difficulty scaling
const COOP_ENEMY_MULTIPLIER: float = 1.2
const COOP_SPAWN_RATE_MULTIPLIER: float = 0.83
const COOP_BOSS_HP_MULTIPLIER: float = 1.25
const LEVEL_CLEAR_FADE_DURATION: float = 2.0

var _game_state: GameState
var _level_data: LevelData
var _rng := RandomNumberGenerator.new()
var _enemies_to_spawn: int = 0
var _enemies_spawned_this_wave: int = 0
var _enemies_destroyed_this_wave: int = 0
var _boss_active: bool = false
var _music_player: AudioStreamPlayer
var _boss_music_player: AudioStreamPlayer
var _kills_since_health_drop: int = 0
var _kills_since_shield_drop: int = 0
var _next_health_drop: int = 0
var _next_shield_drop: int = 0
var _players: Array[CharacterBody2D] = []
var _coop_multiplier: float = 1.0
var _pause_menu: CanvasLayer = null
var _is_paused: bool = false
var _pause_touch_draw: Control

@onready var _player_container: Node2D = $Players
@onready var _bullet_container: Node2D = $Bullets
@onready var _enemy_container: Node2D = $Enemies
@onready var _power_up_container: Node2D = $PowerUps
@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _wave_delay_timer: Timer = $WaveDelayTimer
@onready var _hud: CanvasLayer = $HUD
@onready var _background: ColorRect = $Background
@onready var _bg_texture: TextureRect = $BackgroundTexture


func setup(game_state: GameState) -> void:
	_game_state = game_state
	_game_state.player_died.connect(_on_player_died)
	_game_state.all_players_dead.connect(_on_all_players_dead)
	_game_state.player_shield_broken.connect(_on_shield_broken)
	_level_data = _game_state.get_level_data()


func _ready() -> void:
	_rng.randomize()
	_next_health_drop = _rng.randi_range(HEALTH_DROP_MIN, HEALTH_DROP_MAX)
	_next_shield_drop = _rng.randi_range(SHIELD_DROP_MIN, SHIELD_DROP_MAX)
	if _game_state:
		_hud.setup(_game_state)
	if _level_data and _background:
		_background.color = _level_data.background_color
	if _level_data and _bg_texture and not _level_data.background_texture_path.is_empty():
		if ResourceLoader.exists(_level_data.background_texture_path):
			_bg_texture.texture = load(_level_data.background_texture_path)
	_spawn_players()
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_wave_delay_timer.timeout.connect(_on_wave_delay_timeout)
	_start_music()
	_start_wave()
	if DisplayServer.is_touchscreen_available():
		add_child(TouchControlsScene.instantiate())
		_build_pause_touch_button()


func _spawn_players() -> void:
	var count: int = _game_state.player_count if _game_state else 1
	var arena_size: Vector2 = get_viewport_rect().size
	var center: Vector2 = arena_size / 2.0

	if count >= 2:
		_coop_multiplier = COOP_ENEMY_MULTIPLIER
	else:
		_coop_multiplier = 1.0

	# Input prefixes: 1P uses legacy actions (""), 2P uses "p1_"/"p2_"
	var prefixes: Array[String] = []
	if count == 1:
		prefixes.append("")
	else:
		prefixes.append("p1_")
		prefixes.append("p2_")

	for i: int in count:
		var player: CharacterBody2D = PlayerScene.instantiate()
		# Spread players apart in 2P mode
		if count == 1:
			player.global_position = center
		elif i == 0:
			player.global_position = center + Vector2(-40.0, 0.0)
		else:
			player.global_position = center + Vector2(40.0, 0.0)

		player.setup_input(i, prefixes[i])

		# P2 uses a different ship sprite
		if i == 1 and ResourceLoader.exists(PLAYER2_SPRITE_PATH):
			var sprite: Sprite2D = player.get_node("Sprite")
			if sprite:
				sprite.texture = load(PLAYER2_SPRITE_PATH)

		# If player was dead from previous level, re-enable
		if _game_state and not _game_state.player_alive[i]:
			player.disable()

		player.shoot_requested.connect(_on_player_shoot)
		player.player_hit.connect(_on_player_hit)
		player.power_up_collected.connect(_on_power_up_collected)
		_player_container.add_child(player)
		_players.append(player)


func _get_alive_players() -> Array[Node2D]:
	var alive: Array[Node2D] = []
	for p: CharacterBody2D in _players:
		if is_instance_valid(p) and p.visible:
			alive.append(p)
	return alive


func _start_music() -> void:
	if not _level_data or _level_data.music_path.is_empty():
		return
	if not ResourceLoader.exists(_level_data.music_path):
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = load(_level_data.music_path)
	_music_player.volume_db = -40.0
	_music_player.autoplay = true
	add_child(_music_player)
	# Fade in level music over 1.5 seconds
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -10.0, 1.5)
	_music_player.finished.connect(_music_player.play)


func _crossfade_to_boss_music(music_path: String) -> void:
	if not ResourceLoader.exists(music_path):
		return
	# Fade out level music
	if _music_player and _music_player.playing:
		var fade_out := create_tween()
		fade_out.tween_property(_music_player, "volume_db", -40.0, 2.0)
		fade_out.tween_callback(_music_player.stop)
	# Fade in boss music
	_boss_music_player = AudioStreamPlayer.new()
	_boss_music_player.stream = load(music_path)
	_boss_music_player.volume_db = -40.0
	_boss_music_player.autoplay = true
	add_child(_boss_music_player)
	var fade_in := create_tween()
	fade_in.tween_property(_boss_music_player, "volume_db", -8.0, 2.0)
	_boss_music_player.finished.connect(_boss_music_player.play)


func _start_wave() -> void:
	var wave: int = _game_state.current_wave if _game_state else 1
	var max_waves: int = _level_data.wave_count if _level_data else 5
	if wave > max_waves:
		_start_boss()
		return
	if _game_state:
		_game_state.reset_wave_damage()
	var bonus: int = _level_data.enemy_count_bonus if _level_data else 0
	var base_count: int = WaveManager.get_enemy_count(wave) + bonus
	_enemies_to_spawn = int(base_count * _coop_multiplier)
	_enemies_spawned_this_wave = 0
	_enemies_destroyed_this_wave = 0
	var base_delay: float = WaveManager.get_spawn_delay(wave)
	_spawn_timer.wait_time = (
		base_delay * COOP_SPAWN_RATE_MULTIPLIER if _coop_multiplier > 1.0 else base_delay
	)
	_spawn_timer.start()
	_hud.set_wave(wave)


func _start_boss() -> void:
	if not _level_data or not _level_data.has_boss:
		_on_level_cleared()
		return
	_boss_active = true
	_hud.set_wave_text("BOSS!")
	var arena_size: Vector2 = get_viewport_rect().size
	var boss: CharacterBody2D = BossScene.instantiate()
	boss.global_position = Vector2(arena_size.x / 2.0, 60.0)

	var alive_targets: Array[Node2D] = _get_alive_players()
	var boss_hp: int = _level_data.boss_hp
	if _coop_multiplier > 1.0:
		boss_hp = int(boss_hp * COOP_BOSS_HP_MULTIPLIER)

	(
		boss
		. setup(
			alive_targets,
			_level_data.boss_speed,
			boss_hp,
			_level_data.boss_sprite_path,
			_level_data.boss_bullet_color,
			_level_data.boss_fire_interval_min,
			_level_data.boss_fire_interval_max,
			_level_data.boss_spread_count,
			_level_data.boss_spread_angle,
		)
	)
	(
		boss
		. setup_enhancements(
			_level_data.boss_scale,
			_level_data.boss_has_particles,
			_level_data.boss_particle_color,
			_level_data.boss_has_dart_attack,
		)
	)
	boss.boss_destroyed.connect(_on_boss_destroyed)
	boss.boss_shoot_requested.connect(_on_boss_shoot)
	boss.boss_hp_changed.connect(_hud.update_boss_health)
	_hud.show_boss_health(boss_hp)
	_enemy_container.add_child(boss)

	# Boss music crossfade: fade out level music, fade in boss music
	if not _level_data.boss_music_path.is_empty():
		_crossfade_to_boss_music(_level_data.boss_music_path)


func _on_spawn_timer_timeout() -> void:
	if _enemies_spawned_this_wave >= _enemies_to_spawn:
		_spawn_timer.stop()
		return
	_spawn_enemy()
	_enemies_spawned_this_wave += 1
	if _enemies_spawned_this_wave >= _enemies_to_spawn:
		_spawn_timer.stop()


func _spawn_enemy() -> void:
	var arena_size: Vector2 = get_viewport_rect().size
	var wave: int = _game_state.current_wave if _game_state else 1
	var speed_bonus: float = _level_data.enemy_speed_bonus if _level_data else 0.0
	var alive: Array[Node2D] = _get_alive_players()
	var avoid_pos: Vector2 = alive[0].global_position if alive.size() > 0 else arena_size / 2.0
	var pos: Vector2 = EnemySpawner.get_spawn_position(arena_size, _rng, avoid_pos)
	var enemy: CharacterBody2D = EnemyScene.instantiate()
	enemy.global_position = pos
	var sprite_path: String = ENEMY_SPRITES[_rng.randi() % ENEMY_SPRITES.size()]
	enemy.setup(alive, WaveManager.get_enemy_speed(wave) + speed_bonus, sprite_path)
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)
	_enemy_container.add_child(enemy)


func _on_player_shoot(pos: Vector2, dir: Vector2, _player_idx: int) -> void:
	var bullet: Area2D = BulletScene.instantiate()
	bullet.setup(pos, dir)
	_bullet_container.add_child(bullet)


func _on_player_hit(player_idx: int) -> void:
	if _game_state:
		_game_state.take_damage_for(player_idx)


func _on_enemy_destroyed(points: int, death_pos: Vector2) -> void:
	_enemies_destroyed_this_wave += 1
	if _game_state:
		_game_state.register_kill()
		_game_state.add_score(points)
	_check_power_up_drop(death_pos)
	_check_wave_complete()


func _on_boss_destroyed(points: int) -> void:
	_boss_active = false
	if _game_state:
		_game_state.add_score(points)
	_hud.hide_boss_health()
	_on_level_cleared()


func _on_level_cleared() -> void:
	_fade_out_level_music(_music_player)
	_fade_out_level_music(_boss_music_player)
	level_cleared.emit()


func _check_wave_complete() -> void:
	if _boss_active:
		return
	if _enemies_destroyed_this_wave >= _enemies_to_spawn:
		if _game_state:
			var completed_wave: int = _game_state.current_wave
			_game_state.award_wave_clear_bonus(completed_wave)
			_game_state.advance_wave()
		_wave_delay_timer.start()


func _on_wave_delay_timeout() -> void:
	_start_wave()


func _on_player_died(player_idx: int) -> void:
	if player_idx >= 0 and player_idx < _players.size():
		var p: CharacterBody2D = _players[player_idx]
		if is_instance_valid(p):
			p.disable()


func _on_all_players_dead() -> void:
	_fade_out_level_music(_music_player)
	_fade_out_level_music(_boss_music_player)
	game_over.emit()


func _fade_out_level_music(player: AudioStreamPlayer) -> void:
	if player and player.playing:
		var tween := create_tween()
		tween.tween_property(player, "volume_db", -40.0, LEVEL_CLEAR_FADE_DURATION)
		tween.tween_callback(player.stop)


func _check_power_up_drop(pos: Vector2) -> void:
	_kills_since_health_drop += 1
	_kills_since_shield_drop += 1

	if _kills_since_health_drop >= _next_health_drop:
		_spawn_power_up(pos, "health")
		_kills_since_health_drop = 0
		_next_health_drop = _rng.randi_range(HEALTH_DROP_MIN, HEALTH_DROP_MAX)
	elif _kills_since_shield_drop >= _next_shield_drop:
		_spawn_power_up(pos, "shield")
		_kills_since_shield_drop = 0
		_next_shield_drop = _rng.randi_range(SHIELD_DROP_MIN, SHIELD_DROP_MAX)


func _spawn_power_up(pos: Vector2, type: String) -> void:
	var power_up: Area2D = PowerUpScene.instantiate()
	power_up.setup(pos, type)
	_power_up_container.add_child(power_up)


func _on_power_up_collected(type: String, player_idx: int) -> void:
	if not _game_state:
		return
	if type == "health":
		_game_state.heal_player(player_idx)
	else:
		_game_state.add_shield_for(player_idx)


func _on_shield_broken(player_idx: int) -> void:
	if player_idx >= 0 and player_idx < _players.size():
		var p: CharacterBody2D = _players[player_idx]
		if is_instance_valid(p) and p.has_method("play_shield_break_sound"):
			p.play_shield_break_sound()


func _on_boss_shoot(pos: Vector2, dir: Vector2, bullet_color: Color) -> void:
	var bullet: Area2D = BulletScene.instantiate()
	bullet.setup(pos, dir, true, bullet_color)
	_bullet_container.add_child(bullet)


# ── Pause ──────────────────────────────────────────────────────────────


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not DisplayServer.is_touchscreen_available():
		return
	if _is_tap(event):
		var vp_pos: Vector2 = _screen_to_viewport(event.position)
		if vp_pos.distance_to(Vector2(880.0, 30.0)) <= 30.0:
			_toggle_pause()
			get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	if _is_paused:
		_unpause()
	else:
		_do_pause()


func _do_pause() -> void:
	_is_paused = true
	get_tree().paused = true
	_pause_menu = PauseMenuScene.instantiate()
	_pause_menu.resume_requested.connect(_unpause)
	_pause_menu.quit_to_menu_requested.connect(_on_quit_to_menu)
	add_child(_pause_menu)


func _unpause() -> void:
	_is_paused = false
	get_tree().paused = false
	if _pause_menu and is_instance_valid(_pause_menu):
		_pause_menu.queue_free()
		_pause_menu = null


func _on_quit_to_menu() -> void:
	_unpause()
	if _music_player:
		_music_player.stop()
	if _boss_music_player:
		_boss_music_player.stop()
	quit_to_menu.emit()


func _build_pause_touch_button() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 98
	_pause_touch_draw = Control.new()
	_pause_touch_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_touch_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_touch_draw.draw.connect(_draw_pause_icon)
	canvas.add_child(_pause_touch_draw)
	add_child(canvas)


func _draw_pause_icon() -> void:
	var center := Vector2(880.0, 30.0)
	_pause_touch_draw.draw_circle(center, 16.0, Color(0.0, 0.0, 0.0, 0.25))
	var bar_color := Color(1.0, 1.0, 1.0, 0.35)
	_pause_touch_draw.draw_rect(Rect2(center.x - 6.0, center.y - 7.0, 4.0, 14.0), bar_color)
	_pause_touch_draw.draw_rect(Rect2(center.x + 2.0, center.y - 7.0, 4.0, 14.0), bar_color)


static func _is_tap(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		if DisplayServer.is_touchscreen_available():
			return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	return false


func _screen_to_viewport(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_screen_transform().affine_inverse() * screen_pos

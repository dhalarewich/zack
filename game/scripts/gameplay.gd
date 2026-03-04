extends Node2D
## Main gameplay scene: manages player, enemies, bullets, and waves.
## Supports multi-level progression: waves -> boss -> level complete.

signal game_over
signal level_cleared

const BulletScene: PackedScene = preload("res://scenes/bullet.tscn")
const EnemyScene: PackedScene = preload("res://scenes/enemy.tscn")
const BossScene: PackedScene = preload("res://scenes/boss.tscn")

var _game_state: GameState
var _level_data: LevelData
var _rng := RandomNumberGenerator.new()
var _enemies_to_spawn: int = 0
var _enemies_spawned_this_wave: int = 0
var _boss_active: bool = false
var _music_player: AudioStreamPlayer

@onready var _player: CharacterBody2D = $Player
@onready var _bullet_container: Node2D = $Bullets
@onready var _enemy_container: Node2D = $Enemies
@onready var _spawn_timer: Timer = $SpawnTimer
@onready var _wave_delay_timer: Timer = $WaveDelayTimer
@onready var _hud: CanvasLayer = $HUD
@onready var _background: ColorRect = $Background


func setup(game_state: GameState) -> void:
	_game_state = game_state
	_game_state.player_died.connect(_on_player_died)
	_level_data = _game_state.get_level_data()


func _ready() -> void:
	_rng.randomize()
	if _game_state:
		_hud.setup(_game_state)
	if _level_data and _background:
		_background.color = _level_data.background_color
	_player.shoot_requested.connect(_on_player_shoot)
	_player.player_hit.connect(_on_player_hit)
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_wave_delay_timer.timeout.connect(_on_wave_delay_timeout)
	_player.global_position = get_viewport_rect().size / 2.0
	_start_music()
	_start_wave()


func _start_music() -> void:
	if not _level_data or _level_data.music_path.is_empty():
		return
	if not ResourceLoader.exists(_level_data.music_path):
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = load(_level_data.music_path)
	_music_player.volume_db = -10.0
	_music_player.autoplay = true
	add_child(_music_player)
	_music_player.finished.connect(_music_player.play)


func _start_wave() -> void:
	var wave: int = _game_state.current_wave if _game_state else 1
	var max_waves: int = _level_data.wave_count if _level_data else 5
	if wave > max_waves:
		_start_boss()
		return
	var bonus: int = _level_data.enemy_count_bonus if _level_data else 0
	_enemies_to_spawn = WaveManager.get_enemy_count(wave) + bonus
	_enemies_spawned_this_wave = 0
	_spawn_timer.wait_time = WaveManager.get_spawn_delay(wave)
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
	boss.setup(_player, _level_data.boss_speed, _level_data.boss_hp)
	boss.boss_destroyed.connect(_on_boss_destroyed)
	_enemy_container.add_child(boss)


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
	var pos: Vector2 = EnemySpawner.get_spawn_position(arena_size, _rng, _player.global_position)
	var enemy: CharacterBody2D = EnemyScene.instantiate()
	enemy.global_position = pos
	enemy.setup(_player, WaveManager.get_enemy_speed(wave) + speed_bonus)
	enemy.enemy_destroyed.connect(_on_enemy_destroyed)
	_enemy_container.add_child(enemy)


func _on_player_shoot(pos: Vector2, dir: Vector2) -> void:
	var bullet: Area2D = BulletScene.instantiate()
	bullet.setup(pos, dir)
	_bullet_container.add_child(bullet)


func _on_player_hit() -> void:
	if _game_state:
		_game_state.take_damage()


func _on_enemy_destroyed(points: int) -> void:
	if _game_state:
		_game_state.add_score(points)
	_check_wave_complete()


func _on_boss_destroyed(points: int) -> void:
	_boss_active = false
	if _game_state:
		_game_state.add_score(points)
	_on_level_cleared()


func _on_level_cleared() -> void:
	if _music_player:
		_music_player.stop()
	level_cleared.emit()


func _check_wave_complete() -> void:
	if _boss_active:
		return
	if _enemy_container.get_child_count() <= 0 and _enemies_spawned_this_wave >= _enemies_to_spawn:
		if _game_state:
			_game_state.advance_wave()
		_wave_delay_timer.start()


func _on_wave_delay_timeout() -> void:
	_start_wave()


func _on_player_died() -> void:
	if _music_player:
		_music_player.stop()
	game_over.emit()

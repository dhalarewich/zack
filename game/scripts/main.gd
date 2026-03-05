extends Node
## Root scene: manages screen transitions with multi-level support.
## Flow: Title -> Level Intro -> Gameplay -> (Transition -> Next Intro... or Victory)
## Creates GameState and passes it to child scenes — no autoloads.
## Manages title, game-over, and ending music with crossfade transitions.

enum Screen { TITLE, LEVEL_INTRO, PLAYING, GAME_OVER, VICTORY, TRANSITION }

const TitleScene: PackedScene = preload("res://scenes/title_screen.tscn")
const LevelIntroScene: PackedScene = preload("res://scenes/level_intro.tscn")
const GameplayScene: PackedScene = preload("res://scenes/gameplay.tscn")
const GameOverScene: PackedScene = preload("res://scenes/game_over.tscn")
const VictoryScene: PackedScene = preload("res://scenes/victory_screen.tscn")

const TITLE_MUSIC_PATH: String = "res://assets/audio/title-music.mp3"
const GAMEOVER_MUSIC_PATH: String = "res://assets/audio/gameover-music.mp3"
const ENDING_MUSIC_PATH: String = "res://assets/audio/ending-music.mp3"
const MUSIC_VOLUME: float = -10.0
const MUSIC_FADE_DURATION: float = 1.0

var _current_screen: Screen = Screen.TITLE
var _current_scene: Node = null
var _game_state: GameState
var _title_music: AudioStreamPlayer
var _gameover_music: AudioStreamPlayer
var _ending_music: AudioStreamPlayer


func _ready() -> void:
	_setup_music_players()
	_show_title()


func _setup_music_players() -> void:
	if ResourceLoader.exists(TITLE_MUSIC_PATH):
		_title_music = AudioStreamPlayer.new()
		_title_music.stream = load(TITLE_MUSIC_PATH)
		_title_music.volume_db = MUSIC_VOLUME
		add_child(_title_music)
		_title_music.finished.connect(_title_music.play)

	if ResourceLoader.exists(GAMEOVER_MUSIC_PATH):
		_gameover_music = AudioStreamPlayer.new()
		_gameover_music.stream = load(GAMEOVER_MUSIC_PATH)
		_gameover_music.volume_db = MUSIC_VOLUME
		add_child(_gameover_music)
		_gameover_music.finished.connect(_gameover_music.play)

	if ResourceLoader.exists(ENDING_MUSIC_PATH):
		_ending_music = AudioStreamPlayer.new()
		_ending_music.stream = load(ENDING_MUSIC_PATH)
		_ending_music.volume_db = MUSIC_VOLUME
		add_child(_ending_music)
		_ending_music.finished.connect(_ending_music.play)


func _show_title() -> void:
	_fade_out_music(_ending_music)
	_clear_current_scene()
	_current_screen = Screen.TITLE
	var title: Control = TitleScene.instantiate()
	title.start_game.connect(_start_new_game)
	_set_scene(title)
	_play_music(_title_music)


func _start_new_game(player_count: int = 1) -> void:
	_game_state = GameState.new()
	_game_state.setup_players(player_count)
	_fade_out_music(_title_music)
	_fade_out_music(_gameover_music)
	_show_level_intro()


func _show_level_intro() -> void:
	_clear_current_scene()
	_current_screen = Screen.LEVEL_INTRO
	var intro: Control = LevelIntroScene.instantiate()
	intro.setup(_game_state.get_level_data())
	intro.intro_finished.connect(_start_level)
	_set_scene(intro)


func _start_level() -> void:
	_clear_current_scene()
	_current_screen = Screen.PLAYING
	var gameplay: Node2D = GameplayScene.instantiate()
	gameplay.setup(_game_state)
	gameplay.game_over.connect(_show_game_over)
	gameplay.level_cleared.connect(_on_level_cleared)
	_set_scene(gameplay)


func _on_level_cleared() -> void:
	if _game_state.is_final_level():
		_show_victory()
	else:
		_game_state.advance_level()
		_game_state.respawn_dead_players()
		_show_level_transition()


func _show_level_transition() -> void:
	# Overlay on top of gameplay: show next level title, fade to black, then swap
	_current_screen = Screen.TRANSITION
	var level_data: LevelData = _game_state.get_level_data()
	var overlay := CanvasLayer.new()
	overlay.layer = 10

	# Black background that fades in
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.offset_right = 960.0
	bg.offset_bottom = 540.0
	overlay.add_child(bg)

	# Level title text
	var title_label := Label.new()
	title_label.text = "LEVEL " + str(level_data.level_number)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.offset_left = 0.0
	title_label.offset_top = 160.0
	title_label.offset_right = 960.0
	title_label.offset_bottom = 230.0
	title_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var num_settings := LabelSettings.new()
	num_settings.font_size = 48
	num_settings.outline_size = 4
	num_settings.outline_color = Color.BLACK
	title_label.label_settings = num_settings
	overlay.add_child(title_label)

	# Level name text
	var name_label := Label.new()
	name_label.text = level_data.level_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.offset_left = 0.0
	name_label.offset_top = 240.0
	name_label.offset_right = 960.0
	name_label.offset_bottom = 300.0
	name_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var name_settings := LabelSettings.new()
	name_settings.font_size = 36
	name_settings.font_color = Color(0.8, 0.8, 1.0, 1.0)
	name_settings.outline_size = 3
	name_settings.outline_color = Color.BLACK
	name_label.label_settings = name_settings
	overlay.add_child(name_label)

	add_child(overlay)

	# Animate: fade text in, hold, fade bg to black, then transition
	var tween := create_tween()
	# Fade text in
	tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
	tween.parallel().tween_property(name_label, "modulate:a", 1.0, 0.8)
	# Hold
	tween.tween_interval(1.5)
	# Fade background to black
	tween.tween_property(bg, "color:a", 1.0, 0.8)
	# Transition to next level
	tween.tween_callback(overlay.queue_free)
	tween.tween_callback(_show_level_intro)


func _show_victory() -> void:
	_clear_current_scene()
	_current_screen = Screen.VICTORY
	var victory_screen: Control = VictoryScene.instantiate()
	victory_screen.setup(_game_state.score)
	victory_screen.go_to_title.connect(_show_title)
	_set_scene(victory_screen)
	_play_music(_ending_music)


func _show_game_over() -> void:
	_clear_current_scene()
	_current_screen = Screen.GAME_OVER
	var game_over_screen: Control = GameOverScene.instantiate()
	game_over_screen.setup(_game_state.score)
	var saved_count: int = _game_state.player_count
	game_over_screen.retry_game.connect(func() -> void: _start_new_game(saved_count))
	_set_scene(game_over_screen)
	_play_music(_gameover_music)


func _set_scene(scene: Node) -> void:
	_current_scene = scene
	add_child(scene)


func _clear_current_scene() -> void:
	if _current_scene and is_instance_valid(_current_scene):
		_current_scene.queue_free()
		_current_scene = null


func _play_music(player: AudioStreamPlayer) -> void:
	if player:
		player.volume_db = MUSIC_VOLUME
		player.play()


func _fade_out_music(player: AudioStreamPlayer) -> void:
	if player and player.playing:
		var tween := create_tween()
		tween.tween_property(player, "volume_db", -40.0, MUSIC_FADE_DURATION)
		tween.tween_callback(player.stop)

extends Node
## Root scene: manages screen transitions with multi-level support.
## Flow: Title -> Level Intro -> Gameplay -> (Level Clear -> Next Intro... or Game Over)
## Creates GameState and passes it to child scenes — no autoloads.

enum Screen { TITLE, LEVEL_INTRO, PLAYING, GAME_OVER, VICTORY }

const TitleScene: PackedScene = preload("res://scenes/title_screen.tscn")
const LevelIntroScene: PackedScene = preload("res://scenes/level_intro.tscn")
const GameplayScene: PackedScene = preload("res://scenes/gameplay.tscn")
const GameOverScene: PackedScene = preload("res://scenes/game_over.tscn")

var _current_screen: Screen = Screen.TITLE
var _current_scene: Node = null
var _game_state: GameState


func _ready() -> void:
	_show_title()


func _show_title() -> void:
	_clear_current_scene()
	_current_screen = Screen.TITLE
	var title: Control = TitleScene.instantiate()
	title.start_game.connect(_start_new_game)
	_set_scene(title)


func _start_new_game() -> void:
	_game_state = GameState.new()
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
		_show_level_intro()


func _show_victory() -> void:
	_clear_current_scene()
	_current_screen = Screen.VICTORY
	# Reuse GameOver scene but with victory messaging.
	var victory_screen: Control = GameOverScene.instantiate()
	victory_screen.show_victory(_game_state.score)
	victory_screen.retry_game.connect(_start_new_game)
	_set_scene(victory_screen)


func _show_game_over() -> void:
	_clear_current_scene()
	_current_screen = Screen.GAME_OVER
	var game_over_screen: Control = GameOverScene.instantiate()
	game_over_screen.show_score(_game_state.score)
	game_over_screen.retry_game.connect(_start_new_game)
	_set_scene(game_over_screen)


func _set_scene(scene: Node) -> void:
	_current_scene = scene
	add_child(scene)


func _clear_current_scene() -> void:
	if _current_scene and is_instance_valid(_current_scene):
		_current_scene.queue_free()
		_current_scene = null

extends Node
## Root scene: manages screen transitions (Title -> Playing -> GameOver).
## Creates GameState and passes it to child scenes — no autoloads.

enum Screen { TITLE, PLAYING, GAME_OVER }

const TitleScene: PackedScene = preload("res://scenes/title_screen.tscn")
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
	title.start_game.connect(_start_game)
	_set_scene(title)


func _start_game() -> void:
	_clear_current_scene()
	_current_screen = Screen.PLAYING
	_game_state = GameState.new()
	var gameplay: Node2D = GameplayScene.instantiate()
	gameplay.setup(_game_state)
	gameplay.game_over.connect(_show_game_over)
	_set_scene(gameplay)


func _show_game_over() -> void:
	_clear_current_scene()
	_current_screen = Screen.GAME_OVER
	var game_over_screen: Control = GameOverScene.instantiate()
	game_over_screen.show_score(_game_state.score)
	game_over_screen.retry_game.connect(_start_game)
	_set_scene(game_over_screen)


func _set_scene(scene: Node) -> void:
	_current_scene = scene
	add_child(scene)


func _clear_current_scene() -> void:
	if _current_scene and is_instance_valid(_current_scene):
		_current_scene.queue_free()
		_current_scene = null

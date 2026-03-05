extends Control
## Victory screen: shows congratulations, final score, and high score leaderboard.
## Player enters 3-letter initials if they earned a high score.

signal go_to_title

enum State { ENTERING_INITIALS, SHOWING_SCORES }

const ALLOWED_CHARS: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const MAX_INITIALS: int = 3

var _state: State = State.ENTERING_INITIALS
var _final_score: int = 0
var _initials: String = ""
var _input_cooldown: float = 0.5

@onready var _congrats_label: Label = %CongratsLabel
@onready var _score_label: Label = %FinalScoreLabel
@onready var _high_scores_title: Label = %HighScoresTitle
@onready var _score_1_label: Label = %Score1Label
@onready var _score_2_label: Label = %Score2Label
@onready var _score_3_label: Label = %Score3Label
@onready var _initials_label: Label = %InitialsLabel
@onready var _prompt_label: Label = %PromptLabel


func setup(final_score: int) -> void:
	_final_score = final_score


func _ready() -> void:
	if _score_label:
		_score_label.text = "FINAL SCORE: " + str(_final_score)

	var is_touch: bool = DisplayServer.is_touchscreen_available()

	if HighScores.is_high_score(_final_score):
		if is_touch:
			# No keyboard on mobile — auto-submit initials as "ZAK"
			_initials = "ZAK"
			HighScores.insert_score(_initials, _final_score)
			_state = State.SHOWING_SCORES
			_show_leaderboard()
			if _prompt_label:
				_prompt_label.text = "TAP TO CONTINUE"
		else:
			_state = State.ENTERING_INITIALS
			_update_initials_display()
			if _prompt_label:
				_prompt_label.text = "ENTER YOUR INITIALS"
	else:
		_state = State.SHOWING_SCORES
		_show_leaderboard()
		if _initials_label:
			_initials_label.visible = false
		if _prompt_label:
			if is_touch:
				_prompt_label.text = "TAP TO CONTINUE"
			else:
				_prompt_label.text = "PRESS ENTER TO CONTINUE"

	_input_cooldown = 0.5


func _process(delta: float) -> void:
	if _input_cooldown > 0.0:
		_input_cooldown -= delta


func _input(event: InputEvent) -> void:
	if _input_cooldown > 0.0:
		return
	if _is_tap(event) and _state == State.SHOWING_SCORES:
		go_to_title.emit()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _input_cooldown > 0.0:
		return

	if _state == State.ENTERING_INITIALS:
		_handle_initials_input(event)
	elif _state == State.SHOWING_SCORES:
		if event.is_action_pressed("accept"):
			go_to_title.emit()
			get_viewport().set_input_as_handled()


func _handle_initials_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	if event.echo:
		return

	var keycode: int = event.keycode

	# Backspace
	if keycode == KEY_BACKSPACE and _initials.length() > 0:
		_initials = _initials.substr(0, _initials.length() - 1)
		_update_initials_display()
		get_viewport().set_input_as_handled()
		return

	# Enter — submit if we have 3 chars
	if keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
		if _initials.length() == MAX_INITIALS:
			HighScores.insert_score(_initials, _final_score)
			_state = State.SHOWING_SCORES
			_show_leaderboard()
			if _prompt_label:
				_prompt_label.text = "PRESS ENTER TO CONTINUE"
			_input_cooldown = 0.3
		get_viewport().set_input_as_handled()
		return

	# Letter keys
	if _initials.length() < MAX_INITIALS:
		var key_string: String = OS.get_keycode_string(keycode).to_upper()
		if key_string.length() == 1 and ALLOWED_CHARS.contains(key_string):
			_initials += key_string
			_update_initials_display()
			get_viewport().set_input_as_handled()


func _update_initials_display() -> void:
	if not _initials_label:
		return
	var display: String = _initials
	while display.length() < MAX_INITIALS:
		display += "_"
	_initials_label.text = display


func _show_leaderboard() -> void:
	var scores: Array[Dictionary] = HighScores.load_scores()
	var labels: Array[Label] = []
	if _score_1_label:
		labels.append(_score_1_label)
	if _score_2_label:
		labels.append(_score_2_label)
	if _score_3_label:
		labels.append(_score_3_label)

	for i: int in labels.size():
		if i < scores.size():
			var entry: Dictionary = scores[i]
			labels[i].text = str(i + 1) + ". " + str(entry["name"]) + "  " + str(entry["score"])
		else:
			labels[i].text = str(i + 1) + ". ---  0"

	if _initials_label:
		_initials_label.visible = false

	if _high_scores_title:
		_high_scores_title.visible = true


static func _is_tap(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		if DisplayServer.is_touchscreen_available():
			return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	return false

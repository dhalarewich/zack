extends CanvasLayer
## Heads-up display: dynamically built for 1P or 2P.
## Shows per-player health/shield bars, shared score, wave number,
## and a boss health bar (purple, top-right) during boss fights.

const HEALTH_BAR_WIDTH: float = 100.0
const SHIELD_BAR_WIDTH: float = 100.0
const BAR_HEIGHT: float = 12.0
const SHIELD_BAR_HEIGHT: float = 10.0
const BOSS_BAR_WIDTH: float = 144.0
const BOSS_BAR_HEIGHT: float = 12.0
const BOSS_COLOR: Color = Color(0.5, 0.0, 0.7, 1.0)
const BOSS_BG_COLOR: Color = Color(0.2, 0.0, 0.3, 0.8)

const MULTIPLIER_COLOR: Color = Color(1.0, 0.8, 0.2, 1.0)
const BONUS_COLOR: Color = Color(0.4, 1.0, 0.4, 1.0)
const PERFECT_COLOR: Color = Color(1.0, 0.9, 0.2, 1.0)

var _game_state: GameState
var _score_label: Label
var _wave_label: Label
var _multiplier_label: Label
var _bonus_label: Label
var _health_fills: Array[ColorRect] = []
var _shield_bgs: Array[ColorRect] = []
var _shield_fills: Array[ColorRect] = []
var _boss_container: Control
var _boss_fill: ColorRect
var _boss_max_hp: int = 1


func setup(game_state: GameState) -> void:
	_game_state = game_state
	_build_ui()
	_game_state.score_changed.connect(_on_score_changed)
	_game_state.player_hp_changed.connect(_on_player_hp_changed)
	_game_state.player_shield_changed.connect(_on_player_shield_changed)
	_game_state.player_shield_broken.connect(_on_player_shield_broken)
	_game_state.multiplier_changed.connect(_on_multiplier_changed)
	_game_state.wave_bonus_awarded.connect(_on_wave_bonus_awarded)
	_update_all()


func set_wave(wave: int) -> void:
	if _wave_label:
		_wave_label.text = "WAVE " + str(wave)


func set_wave_text(text: String) -> void:
	if _wave_label:
		_wave_label.text = text


func show_boss_health(max_hp: int) -> void:
	_boss_max_hp = maxi(max_hp, 1)
	if _boss_container:
		_boss_container.visible = true
	if _boss_fill:
		_boss_fill.size.x = BOSS_BAR_WIDTH


func update_boss_health(current_hp: int, _max_hp_unused: int) -> void:
	if _boss_fill:
		var ratio: float = float(maxi(current_hp, 0)) / float(_boss_max_hp)
		_boss_fill.size.x = BOSS_BAR_WIDTH * ratio


func hide_boss_health() -> void:
	if _boss_container:
		_boss_container.visible = false


func _build_ui() -> void:
	_health_fills.clear()
	_shield_bgs.clear()
	_shield_fills.clear()

	var count: int = _game_state.player_count if _game_state else 1

	if count == 1:
		_build_single_player_ui()
	else:
		_build_multi_player_ui(count)

	_build_score_label()
	_build_multiplier_label()
	_build_bonus_label()
	_build_wave_label()
	_build_boss_health_bar()


func _build_single_player_ui() -> void:
	# Health bar BG
	var hbg := ColorRect.new()
	_set_rect(hbg, 16.0, 36.0, HEALTH_BAR_WIDTH, BAR_HEIGHT)
	hbg.color = Color(0.3, 0.0, 0.0, 0.8)
	add_child(hbg)

	# Health bar fill
	var hfill := ColorRect.new()
	_set_rect(hfill, 16.0, 36.0, HEALTH_BAR_WIDTH, BAR_HEIGHT)
	hfill.color = Color(0.2, 0.9, 0.2, 1.0)
	add_child(hfill)
	_health_fills.append(hfill)

	# Shield bar BG
	var sbg := ColorRect.new()
	_set_rect(sbg, 16.0, 52.0, SHIELD_BAR_WIDTH, SHIELD_BAR_HEIGHT)
	sbg.color = Color(0.3, 0.3, 0.0, 0.8)
	sbg.visible = false
	add_child(sbg)
	_shield_bgs.append(sbg)

	# Shield bar fill
	var sfill := ColorRect.new()
	_set_rect(sfill, 16.0, 52.0, SHIELD_BAR_WIDTH, SHIELD_BAR_HEIGHT)
	sfill.color = Color(0.9, 0.9, 0.2, 1.0)
	sfill.visible = false
	add_child(sfill)
	_shield_fills.append(sfill)


func _build_multi_player_ui(count: int) -> void:
	var player_labels: Array[String] = ["PLAYER 1", "PLAYER 2"]
	var label_colors: Array[Color] = [
		Color(1.0, 1.0, 1.0, 0.9),
		Color(0.5, 1.0, 1.0, 0.9),
	]
	var y_offsets: Array[float] = [4.0, 50.0]

	for idx: int in count:
		var y_base: float = y_offsets[idx]

		# Player label
		var plabel := Label.new()
		plabel.text = player_labels[idx]
		_set_rect(plabel, 16.0, y_base, 100.0, 14.0)
		var settings := LabelSettings.new()
		settings.font_size = 10
		settings.font_color = label_colors[idx]
		plabel.label_settings = settings
		add_child(plabel)

		# Health bar BG
		var hbg := ColorRect.new()
		_set_rect(hbg, 16.0, y_base + 14.0, HEALTH_BAR_WIDTH, BAR_HEIGHT)
		hbg.color = Color(0.3, 0.0, 0.0, 0.8)
		add_child(hbg)

		# Health bar fill
		var hfill := ColorRect.new()
		_set_rect(hfill, 16.0, y_base + 14.0, HEALTH_BAR_WIDTH, BAR_HEIGHT)
		hfill.color = Color(0.2, 0.9, 0.2, 1.0)
		add_child(hfill)
		_health_fills.append(hfill)

		# Shield bar BG
		var sbg := ColorRect.new()
		_set_rect(sbg, 16.0, y_base + 28.0, SHIELD_BAR_WIDTH, SHIELD_BAR_HEIGHT)
		sbg.color = Color(0.3, 0.3, 0.0, 0.8)
		sbg.visible = false
		add_child(sbg)
		_shield_bgs.append(sbg)

		# Shield bar fill
		var sfill := ColorRect.new()
		_set_rect(sfill, 16.0, y_base + 28.0, SHIELD_BAR_WIDTH, SHIELD_BAR_HEIGHT)
		sfill.color = Color(0.9, 0.9, 0.2, 1.0)
		sfill.visible = false
		add_child(sfill)
		_shield_fills.append(sfill)


func _build_score_label() -> void:
	_score_label = Label.new()
	_score_label.text = "SCORE: 0"
	_set_rect(_score_label, 16.0, 8.0, 200.0, 24.0)
	# In 2P mode, move score to top-center to avoid overlapping player bars
	if _game_state and _game_state.player_count > 1:
		_score_label.offset_left = 380.0
		_score_label.offset_right = 580.0
		_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_score_label)


func _build_multiplier_label() -> void:
	_multiplier_label = Label.new()
	_multiplier_label.text = ""
	_multiplier_label.visible = false
	var settings := LabelSettings.new()
	settings.font_size = 14
	settings.font_color = MULTIPLIER_COLOR
	settings.outline_size = 2
	settings.outline_color = Color.BLACK
	_multiplier_label.label_settings = settings
	# Position on the same row as the score label, to the right
	if _game_state and _game_state.player_count > 1:
		_set_rect(_multiplier_label, 380.0, 28.0, 200.0, 18.0)
		_multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		_set_rect(_multiplier_label, 160.0, 12.0, 120.0, 18.0)
	add_child(_multiplier_label)


func _build_bonus_label() -> void:
	_bonus_label = Label.new()
	_bonus_label.text = ""
	_bonus_label.visible = false
	_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bonus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var settings := LabelSettings.new()
	settings.font_size = 20
	settings.outline_size = 3
	settings.outline_color = Color.BLACK
	_bonus_label.label_settings = settings
	_set_rect(_bonus_label, 280.0, 250.0, 400.0, 40.0)
	add_child(_bonus_label)


func _build_wave_label() -> void:
	_wave_label = Label.new()
	_wave_label.text = "WAVE 1"
	_set_rect(_wave_label, 800.0, 8.0, 144.0, 24.0)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_wave_label)


func _build_boss_health_bar() -> void:
	_boss_container = Control.new()
	_boss_container.visible = false
	add_child(_boss_container)

	# Boss bar BG (wave label already shows "BOSS!" so no separate label needed)
	var bbg := ColorRect.new()
	_set_rect(bbg, 800.0, 28.0, BOSS_BAR_WIDTH, BOSS_BAR_HEIGHT)
	bbg.color = BOSS_BG_COLOR
	_boss_container.add_child(bbg)

	# Boss bar fill
	_boss_fill = ColorRect.new()
	_set_rect(_boss_fill, 800.0, 28.0, BOSS_BAR_WIDTH, BOSS_BAR_HEIGHT)
	_boss_fill.color = BOSS_COLOR
	_boss_container.add_child(_boss_fill)


func _set_rect(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.offset_left = x
	node.offset_top = y
	node.offset_right = x + w
	node.offset_bottom = y + h


func _update_all() -> void:
	if not _game_state:
		return
	_on_score_changed(_game_state.score)
	for i: int in _game_state.player_count:
		_on_player_hp_changed(i, _game_state.player_hp[i])
		_on_player_shield_changed(i, _game_state.player_shield[i])
	set_wave(_game_state.current_wave)


func _on_score_changed(new_score: int) -> void:
	if _score_label:
		_score_label.text = "SCORE: " + str(new_score)


func _on_player_hp_changed(index: int, new_hp: int) -> void:
	if index < 0 or index >= _health_fills.size():
		return
	var fill: ColorRect = _health_fills[index]
	var ratio: float = float(new_hp) / float(GameState.MAX_HP)
	fill.size.x = HEALTH_BAR_WIDTH * ratio
	if ratio > 0.5:
		fill.color = Color(0.2, 0.9, 0.2, 1.0)
	elif ratio > 0.25:
		fill.color = Color(0.9, 0.7, 0.1, 1.0)
	else:
		fill.color = Color(0.9, 0.15, 0.1, 1.0)


func _on_player_shield_changed(index: int, new_shield: int) -> void:
	if index < 0 or index >= _shield_fills.size():
		return
	var has_shield: bool = new_shield > 0
	_shield_bgs[index].visible = has_shield
	_shield_fills[index].visible = has_shield
	if has_shield:
		var ratio: float = float(new_shield) / float(GameState.MAX_SHIELD)
		_shield_fills[index].size.x = SHIELD_BAR_WIDTH * ratio


func _on_player_shield_broken(index: int) -> void:
	if index < 0 or index >= _shield_bgs.size():
		return
	_shield_bgs[index].visible = false
	_shield_fills[index].visible = false


func _on_multiplier_changed(new_multiplier: float) -> void:
	if not _multiplier_label:
		return
	if new_multiplier > 1.0:
		_multiplier_label.text = "x" + str(new_multiplier) + " COMBO"
		_multiplier_label.visible = true
		# Brief scale pop animation
		_multiplier_label.scale = Vector2(1.3, 1.3)
		var tween := _multiplier_label.create_tween()
		tween.tween_property(_multiplier_label, "scale", Vector2.ONE, 0.2)
	else:
		_multiplier_label.visible = false


func _on_wave_bonus_awarded(bonus: int, is_perfect: bool) -> void:
	if not _bonus_label:
		return
	if is_perfect:
		_bonus_label.text = "PERFECT WAVE! +" + str(bonus)
		_bonus_label.label_settings.font_color = PERFECT_COLOR
	else:
		_bonus_label.text = "WAVE CLEAR +" + str(bonus)
		_bonus_label.label_settings.font_color = BONUS_COLOR
	_bonus_label.visible = true
	_bonus_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween := _bonus_label.create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_bonus_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: _bonus_label.visible = false)

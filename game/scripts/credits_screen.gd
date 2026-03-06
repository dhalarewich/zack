extends Control
## Credits roll: scrolls credits text upward. Emits credits_finished when done.
## Music continues from the victory screen — no music changes here.

signal credits_finished

const SCROLL_SPEED: float = 45.0
const START_DELAY: float = 1.0
# Credits data: each entry is [type, text]
# Types: "title", "subtitle", "heading", "body", "spacer", "small"
const CREDITS_DATA: Array = [
	["title", "ZACK'S GALACTIC ADVENTURE"],
	["subtitle", "CREDITS (TOTALLY REAL)"],
	["spacer", ""],
	["spacer", ""],
	["heading", "CREATED BY"],
	["body", "Soren"],
	["small", "Director, Lead Designer, Story Boss,"],
	["small", "Main Hero, Chief Laser Officer"],
	["spacer", ""],
	["heading", "CO-CREATED BY"],
	["body", "Dad"],
	["small", "Bug Fixer, Mechanic Polisher,"],
	["small", "Controller Untangler, Internet Bill Payer,"],
	["small", "Occasional Snack Delivery"],
	["spacer", ""],
	["heading", "SPECIAL THANKS"],
	["body", "Mom"],
	["small", "Producer, House Stability Manager,"],
	["small", '"Go Outside Too" Consultant,'],
	["small", "Big Support Energy"],
	["spacer", ""],
	["heading", "ALSO STARRING"],
	["body", "Stella"],
	["small", "Little Sister, Chaos Consultant,"],
	["small", "Giggle Soundtrack, Surprise Playtester"],
	["spacer", ""],
	["heading", "ART & CREATURE DESIGN"],
	["body", "Soren's Brain"],
	["small", "Source of All Coolness"],
	["body", "Soren's Hands"],
	["small", "Primary Drawing Device"],
	["body", "Dad's Computer"],
	["small", "Pixel Translator and Button Presser"],
	["spacer", ""],
	["heading", "QUALITY ASSURANCE"],
	["body", "Stella"],
	["small", "Found Bugs By Existing Near The Game"],
	["body", "Dad"],
	["small", "Found Bugs By Staring Too Long"],
	["body", "Soren"],
	["small", 'Found Bugs By Saying "That\'s Not Right"'],
	["spacer", ""],
	["heading", "MUSIC & SOUND"],
	["body", "Soren"],
	["small", "Music Taste Director, Vibe Approver"],
	["body", "Dad"],
	["small", "Volume Knob Operator,"],
	["small", '"One More Track" Negotiator'],
	["spacer", ""],
	["heading", "STORY & LORE"],
	["body", "Soren"],
	["small", "Canon Keeper, Plot Twister,"],
	["small", "Boss Name Inventor"],
	["body", "Dad"],
	["small", "Typo Wrangler, Lore Archivist"],
	["spacer", ""],
	["heading", "CAT DIVISION"],
	["body", "Artie"],
	["small", "Senior Keyboard Walker"],
	["body", "Smudge"],
	["small", "Executive Nap Supervisor"],
	["body", "Monty"],
	["small", "Random Button Activation Specialist"],
	["spacer", ""],
	["heading", "TECHNOLOGY"],
	["body", "Godot Engine"],
	["small", "Did The Magic"],
	["body", "Coffee / Tea / Water"],
	["small", "Kept The Humans Running"],
	["body", "Snacks"],
	["small", "Prevented Game Dev Collapse"],
	["spacer", ""],
	["heading", "LEGAL (VERY SERIOUS)"],
	["small", "No aliens were harmed in the making of this game."],
	["small", "Any resemblance to real space villains"],
	["small", "is probably because they deserved it."],
	["spacer", ""],
	["spacer", ""],
	["title", "THANK YOU FOR PLAYING!"],
	["body", "Now go tell Soren he's awesome."],
	["spacer", ""],
	["spacer", ""],
	["spacer", ""],
]

var _container: VBoxContainer
var _can_skip: bool = false
var _scroll_done: bool = false
var _delay_timer: float = 0.0
var _end_hold: float = 0.0


func _ready() -> void:
	_build_ui()
	_delay_timer = START_DELAY


func _process(delta: float) -> void:
	if _delay_timer > 0.0:
		_delay_timer -= delta
		if _delay_timer <= 0.0:
			_can_skip = true
		return

	if _scroll_done:
		_end_hold += delta
		if _end_hold >= 3.0:
			credits_finished.emit()
			set_process(false)
		return

	# Scroll the container upward
	_container.position.y -= SCROLL_SPEED * delta

	# Check if credits have fully scrolled past the top
	var container_bottom: float = _container.position.y + _container.size.y
	if container_bottom < 0.0:
		_scroll_done = true


func _unhandled_input(event: InputEvent) -> void:
	if not _can_skip:
		return
	if event.is_action_pressed("accept") or event.is_action_pressed("back"):
		credits_finished.emit()
		set_process(false)
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not _can_skip:
		return
	if _is_tap(event):
		credits_finished.emit()
		set_process(false)
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	# Black background
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Clip container so credits don't overflow
	var clip := Control.new()
	clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)

	# Credits container — starts below screen
	_container = VBoxContainer.new()
	_container.position = Vector2(0.0, 540.0)
	_container.size = Vector2(960.0, 0.0)
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_theme_constant_override("separation", 2)
	clip.add_child(_container)

	# Build all credit entries
	for entry: Array in CREDITS_DATA:
		var entry_type: String = entry[0]
		var entry_text: String = entry[1]
		_add_credit_entry(entry_type, entry_text)


func _add_credit_entry(entry_type: String, entry_text: String) -> void:
	if entry_type == "spacer":
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0.0, 20.0)
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_container.add_child(spacer)
		return

	var label := Label.new()
	label.text = entry_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var settings := LabelSettings.new()
	settings.outline_size = 3
	settings.outline_color = Color.BLACK

	match entry_type:
		"title":
			settings.font_size = 40
			settings.font_color = Color(1.0, 1.0, 1.0, 1.0)
			settings.outline_size = 4
		"subtitle":
			settings.font_size = 24
			settings.font_color = Color(0.7, 0.7, 0.9, 1.0)
		"heading":
			settings.font_size = 26
			settings.font_color = Color(0.6, 0.8, 1.0, 1.0)
			settings.outline_size = 3
		"body":
			settings.font_size = 22
			settings.font_color = Color(1.0, 1.0, 1.0, 1.0)
			settings.outline_size = 2
		"small":
			settings.font_size = 18
			settings.font_color = Color(0.75, 0.75, 0.85, 1.0)
			settings.outline_size = 2

	label.label_settings = settings
	_container.add_child(label)


static func _is_tap(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		if DisplayServer.is_touchscreen_available():
			return event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	return false

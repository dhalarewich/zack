extends Area2D
## Collectible power-up dropped by enemies: health or shield.
## Bobs gently and auto-destroys after LIFETIME seconds.

signal collected(type: String)

const LIFETIME: float = 10.0
const TARGET_SIZE: float = 40.0
const BOB_AMOUNT: float = 4.0
const BOB_SPEED: float = 2.0

var _type: String = "health"
var _base_y: float = 0.0
var _time: float = 0.0


func setup(pos: Vector2, type: String) -> void:
	global_position = pos
	_base_y = pos.y
	_type = type


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Load sprite based on type
	var sprite: Sprite2D = $Sprite
	if sprite:
		var path: String = ""
		if _type == "health":
			path = "res://assets/sprites/powerup-health.png"
		else:
			path = "res://assets/sprites/powerup-shield.png"
		if ResourceLoader.exists(path):
			sprite.texture = load(path)
			var tex_size: float = maxf(sprite.texture.get_width(), 1.0)
			var s: float = TARGET_SIZE / tex_size
			sprite.scale = Vector2(s, s)

	# Auto-destroy after lifetime
	var timer := Timer.new()
	timer.wait_time = LIFETIME
	timer.one_shot = true
	timer.autostart = true
	timer.timeout.connect(queue_free)
	add_child(timer)


func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * BOB_SPEED) * BOB_AMOUNT


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("collect_power_up"):
		body.collect_power_up(_type)
		collected.emit(_type)
		queue_free()

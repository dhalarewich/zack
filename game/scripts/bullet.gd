extends Area2D
## A bullet that travels in a straight line.
## Player bullets hit enemies; enemy bullets hit the player.

const SPEED: float = 600.0
const ENEMY_BULLET_SPEED: float = 350.0

var direction: Vector2 = Vector2.UP
var _is_enemy_bullet: bool = false
var _move_speed: float = SPEED


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * _move_speed * delta
	# Remove if off-screen.
	var viewport_size: Vector2 = get_viewport_rect().size
	if (
		position.x < -50
		or position.x > viewport_size.x + 50
		or position.y < -50
		or position.y > viewport_size.y + 50
	):
		queue_free()


func setup(
	start_pos: Vector2,
	dir: Vector2,
	enemy_bullet: bool = false,
	bullet_color: Color = Color(1.0, 1.0, 0.2, 1.0),
) -> void:
	global_position = start_pos
	direction = dir.normalized()
	rotation = direction.angle() + PI / 2.0
	_is_enemy_bullet = enemy_bullet

	if enemy_bullet:
		# Enemy bullets: hit player (layer 1), ignore enemies
		collision_layer = 2
		collision_mask = 1
		_move_speed = ENEMY_BULLET_SPEED
	else:
		# Player bullets: hit enemies (layer 2)
		collision_layer = 4
		collision_mask = 2

	# Set bullet color
	var sprite: ColorRect = $Sprite
	if sprite:
		sprite.color = bullet_color


func _on_body_entered(body: Node2D) -> void:
	if _is_enemy_bullet:
		if body.has_method("hit"):
			body.hit()
	else:
		if body.has_method("take_hit"):
			body.take_hit()
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not _is_enemy_bullet:
		if area.has_method("take_hit"):
			area.take_hit()

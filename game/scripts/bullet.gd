extends Area2D
## A bullet that travels in a straight line and destroys enemies on contact.

const SPEED: float = 600.0

var direction: Vector2 = Vector2.UP


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	# Remove if off-screen.
	var viewport_size: Vector2 = get_viewport_rect().size
	if (
		position.x < -50
		or position.x > viewport_size.x + 50
		or position.y < -50
		or position.y > viewport_size.y + 50
	):
		queue_free()


func setup(start_pos: Vector2, dir: Vector2) -> void:
	global_position = start_pos
	direction = dir.normalized()
	rotation = direction.angle() + PI / 2.0


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit()
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_hit"):
		area.take_hit()

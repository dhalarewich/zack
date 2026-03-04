class_name EnemySpawner
extends RefCounted
## Calculates spawn positions along arena edges.
## Uses seeded RNG for deterministic/testable results.

const EDGE_MARGIN: float = 16.0
const MIN_DISTANCE_FROM_PLAYER: float = 150.0

enum Edge { TOP, BOTTOM, LEFT, RIGHT }


static func get_spawn_position(
	arena_size: Vector2,
	rng: RandomNumberGenerator,
	player_pos: Vector2 = Vector2.ZERO
) -> Vector2:
	var pos := Vector2.ZERO
	var attempts: int = 0
	var max_attempts: int = 10

	while attempts < max_attempts:
		var edge: int = rng.randi_range(0, 3)
		match edge:
			Edge.TOP:
				pos = Vector2(rng.randf_range(EDGE_MARGIN, arena_size.x - EDGE_MARGIN), EDGE_MARGIN)
			Edge.BOTTOM:
				pos = Vector2(
					rng.randf_range(EDGE_MARGIN, arena_size.x - EDGE_MARGIN),
					arena_size.y - EDGE_MARGIN,
				)
			Edge.LEFT:
				pos = Vector2(EDGE_MARGIN, rng.randf_range(EDGE_MARGIN, arena_size.y - EDGE_MARGIN))
			Edge.RIGHT:
				pos = Vector2(
					arena_size.x - EDGE_MARGIN,
					rng.randf_range(EDGE_MARGIN, arena_size.y - EDGE_MARGIN),
				)

		if player_pos == Vector2.ZERO or pos.distance_to(player_pos) >= MIN_DISTANCE_FROM_PLAYER:
			return pos
		attempts += 1

	return pos


static func get_random_edge(rng: RandomNumberGenerator) -> Edge:
	return rng.randi_range(0, 3) as Edge

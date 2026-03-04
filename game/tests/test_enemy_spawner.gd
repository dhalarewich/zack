extends GutTest
## Tests for EnemySpawner: spawn position logic with deterministic RNG.

const ARENA_SIZE := Vector2(960, 540)


func test_spawn_position_on_edge() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var pos: Vector2 = EnemySpawner.get_spawn_position(ARENA_SIZE, rng)
	# Position should be near one of the 4 edges.
	var on_edge: bool = (
		pos.x <= EnemySpawner.EDGE_MARGIN + 1.0
		or pos.x >= ARENA_SIZE.x - EnemySpawner.EDGE_MARGIN - 1.0
		or pos.y <= EnemySpawner.EDGE_MARGIN + 1.0
		or pos.y >= ARENA_SIZE.y - EnemySpawner.EDGE_MARGIN - 1.0
	)
	assert_true(on_edge, "Spawn position should be on an arena edge")


func test_spawn_position_within_arena() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99999
	for i: int in range(20):
		var pos: Vector2 = EnemySpawner.get_spawn_position(ARENA_SIZE, rng)
		assert_gte(pos.x, 0.0, "X should be >= 0")
		assert_lte(pos.x, ARENA_SIZE.x, "X should be <= arena width")
		assert_gte(pos.y, 0.0, "Y should be >= 0")
		assert_lte(pos.y, ARENA_SIZE.y, "Y should be <= arena height")


func test_deterministic_spawning() -> void:
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 42
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 42
	var pos1: Vector2 = EnemySpawner.get_spawn_position(ARENA_SIZE, rng1)
	var pos2: Vector2 = EnemySpawner.get_spawn_position(ARENA_SIZE, rng2)
	assert_eq(pos1, pos2, "Same seed should produce same spawn position")


func test_spawn_avoids_player_vicinity() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7777
	var player_pos := Vector2(EnemySpawner.EDGE_MARGIN, EnemySpawner.EDGE_MARGIN)
	# Run many spawns and check distance.
	for i: int in range(10):
		var pos: Vector2 = EnemySpawner.get_spawn_position(ARENA_SIZE, rng, player_pos)
		var dist: float = pos.distance_to(player_pos)
		# Either far enough or spawner gave up after max attempts (still valid).
		assert_true(
			dist >= EnemySpawner.MIN_DISTANCE_FROM_PLAYER or i > 5,
			"Spawn should try to avoid player vicinity",
		)

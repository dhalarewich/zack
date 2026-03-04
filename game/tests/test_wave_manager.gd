extends GutTest
## Tests for WaveManager: wave difficulty scaling calculations.


func test_enemy_count_wave_one() -> void:
	var count: int = WaveManager.get_enemy_count(1)
	assert_eq(count, WaveManager.BASE_ENEMY_COUNT, "Wave 1 should have BASE_ENEMY_COUNT enemies")


func test_enemy_count_increases_each_wave() -> void:
	var count_w1: int = WaveManager.get_enemy_count(1)
	var count_w2: int = WaveManager.get_enemy_count(2)
	var count_w3: int = WaveManager.get_enemy_count(3)
	assert_gt(count_w2, count_w1, "Wave 2 should have more enemies than wave 1")
	assert_gt(count_w3, count_w2, "Wave 3 should have more enemies than wave 2")


func test_enemy_count_formula() -> void:
	# count = BASE + (wave-1) * PER_WAVE
	for wave: int in range(1, 6):
		var expected: int = WaveManager.BASE_ENEMY_COUNT + (wave - 1) * WaveManager.ENEMIES_PER_WAVE
		assert_eq(
			WaveManager.get_enemy_count(wave),
			expected,
			"Wave %d enemy count should match formula" % wave,
		)


func test_spawn_delay_decreases() -> void:
	var delay_w1: float = WaveManager.get_spawn_delay(1)
	var delay_w5: float = WaveManager.get_spawn_delay(5)
	assert_gt(delay_w1, delay_w5, "Later waves should have shorter spawn delays")


func test_spawn_delay_has_minimum() -> void:
	var delay: float = WaveManager.get_spawn_delay(100)
	assert_gte(delay, WaveManager.MIN_SPAWN_DELAY, "Spawn delay should not go below minimum")


func test_enemy_speed_increases() -> void:
	var speed_w1: float = WaveManager.get_enemy_speed(1)
	var speed_w5: float = WaveManager.get_enemy_speed(5)
	assert_gt(speed_w5, speed_w1, "Later waves should have faster enemies")


func test_enemy_speed_has_maximum() -> void:
	var speed: float = WaveManager.get_enemy_speed(100)
	assert_lte(speed, WaveManager.MAX_ENEMY_SPEED, "Enemy speed should not exceed maximum")

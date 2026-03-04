extends GutTest
## Tests for LevelRegistry and LevelData.


func test_level_count_at_least_one() -> void:
	assert_gt(LevelRegistry.get_level_count(), 0, "Should have at least 1 level")


func test_all_levels_have_names() -> void:
	for i: int in range(1, LevelRegistry.get_level_count() + 1):
		var data: LevelData = LevelRegistry.get_level(i)
		assert_ne(data.level_name, "", "Level %d should have a name" % i)


func test_all_levels_have_waves() -> void:
	for i: int in range(1, LevelRegistry.get_level_count() + 1):
		var data: LevelData = LevelRegistry.get_level(i)
		assert_gt(data.wave_count, 0, "Level %d should have at least 1 wave" % i)


func test_level_numbers_are_sequential() -> void:
	for i: int in range(1, LevelRegistry.get_level_count() + 1):
		var data: LevelData = LevelRegistry.get_level(i)
		assert_eq(data.level_number, i, "Level data number should match index")


func test_out_of_bounds_clamps() -> void:
	var data: LevelData = LevelRegistry.get_level(999)
	assert_not_null(data, "Out-of-bounds level should return clamped data")
	var last: LevelData = LevelRegistry.get_level(LevelRegistry.get_level_count())
	assert_eq(data.level_name, last.level_name, "Should clamp to last level")

class_name LevelRegistry
extends RefCounted
## Central registry of all levels in the game.
## Returns LevelData for each level number.


static func get_level_count() -> int:
	return _levels().size()


static func get_level(level_number: int) -> LevelData:
	var levels: Array[LevelData] = _levels()
	var idx: int = clampi(level_number - 1, 0, levels.size() - 1)
	return levels[idx]


static func _levels() -> Array[LevelData]:
	var levels: Array[LevelData] = []

	# Level 1: The Asteroid Belt
	var l1 := LevelData.new()
	l1.level_name = "The Asteroid Belt"
	l1.level_number = 1
	l1.wave_count = 5
	l1.background_color = Color(0.04, 0.02, 0.1, 1)
	l1.music_path = "res://assets/audio/level1.mp3"
	l1.has_boss = true
	l1.boss_hp = 10
	l1.boss_speed = 60.0
	levels.append(l1)

	# Level 2: Nebula Station (placeholder — to be configured later)
	var l2 := LevelData.new()
	l2.level_name = "Nebula Station"
	l2.level_number = 2
	l2.wave_count = 5
	l2.background_color = Color(0.08, 0.02, 0.12, 1)
	l2.music_path = ""
	l2.has_boss = true
	l2.boss_hp = 15
	l2.boss_speed = 70.0
	l2.enemy_speed_bonus = 15.0
	l2.enemy_count_bonus = 1
	levels.append(l2)

	# Level 3: The Dark Void (placeholder — to be configured later)
	var l3 := LevelData.new()
	l3.level_name = "The Dark Void"
	l3.level_number = 3
	l3.wave_count = 5
	l3.background_color = Color(0.02, 0.01, 0.05, 1)
	l3.music_path = ""
	l3.has_boss = true
	l3.boss_hp = 20
	l3.boss_speed = 80.0
	l3.enemy_speed_bonus = 30.0
	l3.enemy_count_bonus = 2
	levels.append(l3)

	return levels

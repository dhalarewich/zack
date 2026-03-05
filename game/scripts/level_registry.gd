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

	# Level 1: Defending Home
	var l1 := LevelData.new()
	l1.level_name = "Defending Home"
	l1.level_number = 1
	l1.wave_count = 3
	l1.background_color = Color(0.04, 0.02, 0.1, 1)
	l1.music_path = "res://assets/audio/level1-new.mp3"
	l1.background_texture_path = "res://assets/sprites/level1-bg.png"
	l1.has_boss = true
	l1.boss_hp = 19
	l1.boss_speed = 60.0
	l1.boss_sprite_path = "res://assets/sprites/boss1-sprite.png"
	l1.boss_bullet_color = Color(1.0, 0.2, 0.2, 1.0)
	l1.boss_fire_interval_min = 1.1
	l1.boss_fire_interval_max = 2.6
	l1.boss_spread_count = 1
	levels.append(l1)

	# Level 2: Pursuing the Eyelians
	var l2 := LevelData.new()
	l2.level_name = "Pursuing the Eyelians"
	l2.level_number = 2
	l2.wave_count = 4
	l2.background_color = Color(0.08, 0.02, 0.12, 1)
	l2.music_path = "res://assets/audio/level2.mp3"
	l2.background_texture_path = "res://assets/sprites/level2-bg.png"
	l2.has_boss = true
	l2.boss_hp = 31
	l2.boss_speed = 77.0
	l2.boss_sprite_path = "res://assets/sprites/boss2-sprite.png"
	l2.enemy_speed_bonus = 15.0
	l2.enemy_count_bonus = 1
	l2.boss_bullet_color = Color(0.2, 1.0, 0.2, 1.0)
	l2.boss_fire_interval_min = 0.9
	l2.boss_fire_interval_max = 2.25
	l2.boss_spread_count = 1
	levels.append(l2)

	# Level 3: Saving our friends
	var l3 := LevelData.new()
	l3.level_name = "Saving our friends"
	l3.level_number = 3
	l3.wave_count = 5
	l3.background_color = Color(0.02, 0.01, 0.05, 1)
	l3.music_path = "res://assets/audio/level3-new.mp3"
	l3.background_texture_path = "res://assets/sprites/level3-bg.png"
	l3.has_boss = true
	l3.boss_hp = 50
	l3.boss_speed = 92.0
	l3.boss_sprite_path = "res://assets/sprites/boss3-sprite.png"
	l3.enemy_speed_bonus = 30.0
	l3.enemy_count_bonus = 2
	l3.boss_bullet_color = Color(0.7, 0.2, 1.0, 1.0)
	l3.boss_fire_interval_min = 1.5
	l3.boss_fire_interval_max = 3.0
	l3.boss_spread_count = 3
	l3.boss_spread_angle = 35.0
	l3.boss_scale = 1.2
	l3.boss_has_particles = true
	l3.boss_particle_color = Color(1.0, 0.2, 0.1, 1.0)
	l3.boss_has_dart_attack = true
	l3.boss_music_path = "res://assets/audio/final-boss-battle.mp3"
	levels.append(l3)

	return levels

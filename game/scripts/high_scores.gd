class_name HighScores
extends RefCounted
## Loads and saves top 3 high scores from user://highscores.json.
## Each entry has "name" (3 chars) and "score" (int).

const SAVE_PATH: String = "user://highscores.json"
const MAX_ENTRIES: int = 3


static func load_scores() -> Array[Dictionary]:
	var scores: Array[Dictionary] = []
	if not FileAccess.file_exists(SAVE_PATH):
		return scores
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return scores
	var text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	var err: Error = json.parse(text)
	if err != OK:
		return scores
	var data: Variant = json.data
	if data is Array:
		for entry: Variant in data:
			if entry is Dictionary and entry.has("name") and entry.has("score"):
				scores.append({"name": str(entry["name"]), "score": int(entry["score"])})
	# Sort descending by score
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	# Cap at max
	if scores.size() > MAX_ENTRIES:
		scores.resize(MAX_ENTRIES)
	return scores


static func save_scores(scores: Array[Dictionary]) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	var data: Array = []
	for entry: Dictionary in scores:
		data.append({"name": entry["name"], "score": entry["score"]})
	file.store_string(JSON.stringify(data))
	file.close()


static func is_high_score(score: int) -> bool:
	var scores: Array[Dictionary] = load_scores()
	if scores.size() < MAX_ENTRIES:
		return true
	return score > scores[scores.size() - 1]["score"]


static func insert_score(player_name: String, score: int) -> Array[Dictionary]:
	var scores: Array[Dictionary] = load_scores()
	scores.append({"name": player_name, "score": score})
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	if scores.size() > MAX_ENTRIES:
		scores.resize(MAX_ENTRIES)
	save_scores(scores)
	return scores

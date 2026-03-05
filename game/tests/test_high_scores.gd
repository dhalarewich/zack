extends GutTest
## Tests for high score sorting, capping, and qualification logic.

const MAX_ENTRIES: int = 3


func test_empty_scores_returns_empty_array() -> void:
	var scores: Array[Dictionary] = []
	assert_eq(scores.size(), 0, "Empty array should have size 0")


func test_insert_score_adds_entry() -> void:
	var scores: Array[Dictionary] = []
	scores.append({"name": "AAA", "score": 500})
	assert_eq(scores.size(), 1, "Should have 1 entry after append")
	assert_eq(scores[0]["name"], "AAA", "Name should be AAA")
	assert_eq(scores[0]["score"], 500, "Score should be 500")


func test_scores_sort_descending() -> void:
	var scores: Array[Dictionary] = []
	scores.append({"name": "AAA", "score": 100})
	scores.append({"name": "BBB", "score": 300})
	scores.append({"name": "CCC", "score": 200})
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	assert_eq(scores[0]["name"], "BBB", "Highest score first")
	assert_eq(scores[1]["name"], "CCC", "Second highest second")
	assert_eq(scores[2]["name"], "AAA", "Lowest score last")


func test_max_three_entries() -> void:
	var scores: Array[Dictionary] = []
	scores.append({"name": "AAA", "score": 100})
	scores.append({"name": "BBB", "score": 200})
	scores.append({"name": "CCC", "score": 300})
	scores.append({"name": "DDD", "score": 400})
	scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
	if scores.size() > MAX_ENTRIES:
		scores.resize(MAX_ENTRIES)
	assert_eq(scores.size(), 3, "Should cap at MAX_ENTRIES")
	assert_eq(scores[0]["name"], "DDD", "Highest score should remain")


func test_is_high_score_with_empty_list() -> void:
	# Any score qualifies when fewer than MAX_ENTRIES exist
	var scores: Array[Dictionary] = []
	var qualifies: bool = scores.size() < MAX_ENTRIES
	assert_true(qualifies, "Score should qualify with empty list")


func test_is_high_score_when_full() -> void:
	var scores: Array[Dictionary] = [
		{"name": "AAA", "score": 300},
		{"name": "BBB", "score": 200},
		{"name": "CCC", "score": 100},
	]
	# Score of 150 should beat the lowest (100)
	var qualifies: bool = 150 > scores[scores.size() - 1]["score"]
	assert_true(qualifies, "150 should beat lowest score of 100")
	# Score of 50 should not qualify
	var too_low: bool = 50 > scores[scores.size() - 1]["score"]
	assert_false(too_low, "50 should not beat lowest score of 100")

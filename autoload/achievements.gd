extends Node
## Achievements (autoload "Achievements"). Definitions in data/achievements.json;
## progress is derived from the save (records, stars, streaks) plus a few
## counters kept here. Stored only on the device (no Game Center).

signal unlocked(def: Dictionary)

const PATH := "res://data/achievements.json"

var defs: Array = []


func _ready() -> void:
	defs = GameMode.load_config(PATH).get("achievements", [])


func is_unlocked(id: String) -> bool:
	return _state().unlocked.has(id)


func unlocked_count() -> int:
	return (_state().unlocked as Dictionary).size()


func counter(key: String) -> int:
	return int(_state().counters.get(key, 0))


func add(key: String, amount := 1) -> void:
	var c: Dictionary = _state().counters
	c[key] = int(c.get(key, 0)) + amount
	SaveData.mark_dirty()
	check()


func raise_to(key: String, value: int) -> void:
	var c: Dictionary = _state().counters
	if value > int(c.get(key, 0)):
		c[key] = value
		SaveData.mark_dirty()


## Call after a finished run with its results dictionary.
func on_run_finished(mode_id: String, r: Dictionary) -> void:
	var c: Dictionary = _state().counters
	c.total_runs = int(c.get("total_runs", 0)) + 1
	if mode_id == "score":
		raise_to("max_combo", int(r.get("best_combo", 0)))
		if float(r.get("accuracy", 0.0)) >= 1.0 and int(r.get("hits", 0)) >= 40:
			c.perfect_runs = int(c.get("perfect_runs", 0)) + 1
	SaveData.mark_dirty()
	check()


## Current value of a stat, read from the save where it already lives.
func stat(key: String) -> int:
	match key:
		"score_best":
			return SaveData.get_best("score")
		"memory_best":
			return SaveData.get_best("memory")
		"reflex_best_avg":
			return SaveData.get_best("reflex")
		"reflex_best_single":
			return int(SaveData.mode_stats("reflex").get("best_single", 0))
		"stage_cleared":
			var n := 0
			for i in range(1, StageLevels.count() + 1):
				if SaveData.get_stars(i) > 0:
					n = i
			return n
		"stage_three_stars":
			var n := 0
			for v in SaveData.section("stage").stars.values():
				if int(v) >= 3:
					n += 1
			return n
		"daily_count":
			var n := 0
			for r: Dictionary in SaveData.section("daily").results.values():
				if not bool(r.get("pending", false)):
					n += 1
			return n
		"streak_best":
			return int(SaveData.section("daily").get("best_streak", 0))
	return counter(key)


## 0..100 progress for a definition.
func percent(def: Dictionary) -> float:
	var v := stat(def.stat)
	var goal := float(def.goal)
	if str(def.get("compare", "gte")) == "lte":
		return 100.0 if v > 0 and v <= goal else 0.0
	return clampf(v / maxf(goal, 1.0) * 100.0, 0.0, 100.0)


## Evaluates all definitions and unlocks what was reached.
func check() -> void:
	var st := _state()
	for def: Dictionary in defs:
		var id: String = def.id
		var p := percent(def)
		if p >= 100.0 and not st.unlocked.has(id):
			st.unlocked[id] = int(Time.get_unix_time_from_system())
			SaveData.mark_dirty()
			unlocked.emit(def)


func _state() -> Dictionary:
	var a := SaveData.section("achievements")
	if not a.has("unlocked"):
		a.unlocked = {}
	if not a.has("counters"):
		a.counters = {}
	return a

class_name StageLevels
extends RefCounted
## Loads data/stages/stages.json and merges each level over "defaults".

const PATH := "res://data/stages/stages.json"

static var _cache: Dictionary = {}


static func data() -> Dictionary:
	if _cache.is_empty():
		_cache = GameMode.load_config(PATH)
	return _cache


static func count() -> int:
	return (data().get("levels", []) as Array).size()


## Full level definition (defaults + overrides). Empty when the id is unknown.
static func get_level(id: int) -> Dictionary:
	for l: Dictionary in data().get("levels", []):
		if int(l.get("id", 0)) == id:
			var merged: Dictionary = (data().get("defaults", {}) as Dictionary).duplicate(true)
			for k in l:
				if k == "difficulty" and merged.has("difficulty"):
					var d: Dictionary = merged.difficulty
					var o: Dictionary = l.difficulty
					for dk in o:
						if dk == "params":
							(d.params as Dictionary).merge(o.params, true)
						else:
							d[dk] = o[dk]
				else:
					merged[k] = l[k]
			return merged
	return {}


## Stars for a finished level: 1 = cleared, 2/3 when both time and mistakes
## are within that tier's thresholds.
static func stars_for(level: Dictionary, time: float, mistakes: int) -> int:
	var s: Dictionary = level.get("stars", {})
	for tier in [3, 2]:
		var t: Dictionary = s.get(str(tier), {})
		if t.is_empty():
			continue
		if time <= float(t.get("time", INF)) and mistakes <= int(t.get("mistakes", 999)):
			return tier
	return 1


static func is_unlocked(id: int) -> bool:
	return id <= 1 or SaveData.get_stars(id - 1) >= 1


## First level without stars (or the last one when everything is cleared).
static func current_level() -> int:
	for i in range(1, count() + 1):
		if SaveData.get_stars(i) == 0:
			return i
	return maxi(count(), 1)

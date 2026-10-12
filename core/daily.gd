class_name Daily
extends RefCounted
## Daily Challenge: one challenge per UTC day, derived from a seed of the date,
## so every player in the world gets the same one. Templates live in
## data/daily.json: a mode plus parameter choices that the seed picks from.
##
## Clock protection: the highest day ever seen is stored; a clock set back
## never yields an earlier (already played or skipped) day, and every day can
## be played officially once.

const PATH := "res://data/daily.json"
const SECONDS_PER_DAY := 86400

static var _templates: Array = []
## Tests / dev scenarios can pin "now" (unix seconds). 0 = system clock.
static var fake_now := 0


static func now_unix() -> int:
	return fake_now if fake_now > 0 else int(Time.get_unix_time_from_system())


## Days since 1970-01-01 (UTC), protected against clocks set back.
static func today() -> int:
	@warning_ignore("integer_division")
	var day := now_unix() / SECONDS_PER_DAY
	var d := SaveData.section("daily")
	var max_day := int(d.get("max_day", 0))
	if day > max_day:
		d.max_day = day
		SaveData.mark_dirty()
		return day
	return max_day


static func seconds_to_next() -> int:
	var n := now_unix()
	@warning_ignore("integer_division")
	var next := (n / SECONDS_PER_DAY + 1) * SECONDS_PER_DAY
	# If the clock was set back, "today" is a later day: count to the day after it.
	next = maxi(next, (today() + 1) * SECONDS_PER_DAY)
	return next - n


static func countdown_text() -> String:
	var s := seconds_to_next()
	@warning_ignore("integer_division")
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


static func seed_for(day: int) -> int:
	return hash("poppulse-daily-%d" % day)


## {day, mode, title, overrides: {path: value}, seed}
static func challenge_for(day: int) -> Dictionary:
	if _templates.is_empty():
		_templates = GameMode.load_config(PATH).get("templates", [])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_for(day)
	var tpl: Dictionary = _templates[rng.randi() % _templates.size()]
	var overrides := {}
	var choices: Dictionary = tpl.get("choices", {})
	var keys := choices.keys()
	keys.sort()  # dictionary order must not influence the seed sequence
	for k in keys:
		var opts: Array = choices[k]
		overrides[k] = opts[rng.randi() % opts.size()]
	var title: String = tpl.get("title", tpl.mode)
	var labels: Dictionary = tpl.get("labels", {})
	for k in overrides:
		title = title.replace("{%s}" % k.get_file(), _num(overrides[k]))
	for label in labels:
		title = title.replace("{%s}" % label, _num(overrides.get(labels[label], "")))
	return {"day": day, "mode": tpl.mode, "title": title, "overrides": overrides, "seed": rng.randi()}


static func _num(v: Variant) -> String:
	if v is float and is_equal_approx(v, roundf(v)):
		return str(int(v))
	return str(v)


static func today_challenge() -> Dictionary:
	return challenge_for(today())


static func result(day: int) -> Dictionary:
	return SaveData.section("daily").results.get(str(day), {})


static func is_played(day: int) -> bool:
	return not result(day).is_empty()


## Extra official attempts granted for a day (rewarded ad, US-32).
static func extra_attempts(day: int) -> int:
	return int(SaveData.section("daily").get("extra_attempts", {}).get(str(day), 0))


static func can_play_official(day: int) -> bool:
	return not is_played(day) or extra_attempts(day) > 0


## Called when an official attempt starts, so quitting halfway still uses it up.
static func begin_official(day: int) -> void:
	var d := SaveData.section("daily")
	var key := str(day)
	if is_played(day):
		var extras: Dictionary = d.get("extra_attempts", {})
		extras[key] = maxi(int(extras.get(key, 0)) - 1, 0)
		d.extra_attempts = extras
	else:
		d.results[key] = {"pending": true, "score": 0, "at": now_unix()}
	SaveData.mark_dirty()


## Stores an official result. With a retry the better value is kept.
static func record(day: int, value: int, lower_is_better: bool, mode_id: String) -> void:
	var d := SaveData.section("daily")
	var key := str(day)
	var prev: Dictionary = d.results.get(key, {})
	if not prev.is_empty() and not bool(prev.get("pending", false)):
		var better := value < int(prev.score) if lower_is_better else value > int(prev.score)
		if not better or value <= 0:
			return
	d.results[key] = {"score": value, "mode": mode_id, "at": now_unix()}
	SaveData.mark_dirty()


## Writes `value` at a slash path ("difficulty/params/max_active/1") into cfg.
static func apply_overrides(cfg: Dictionary, overrides: Dictionary) -> void:
	for path: String in overrides:
		var parts := path.split("/")
		var cur: Variant = cfg
		var ok := true
		for i in parts.size() - 1:
			var p := parts[i]
			if cur is Dictionary:
				if not (cur as Dictionary).has(p):
					cur[p] = {}
				cur = cur[p]
			elif cur is Array and p.is_valid_int():
				cur = cur[int(p)]
			else:
				ok = false
				break
		if not ok:
			continue
		var last := parts[parts.size() - 1]
		var v: Variant = overrides[path]
		if v is Array:
			v = (v as Array).duplicate()
		if cur is Array and last.is_valid_int():
			cur[int(last)] = v
		elif cur is Dictionary:
			cur[last] = v


# --- Streak (US-18) -----------------------------------------------------------------

const STREAK_MILESTONES := [3, 7, 30]


## Days in a row with a completed daily challenge. A missed day resets it.
static func current_streak() -> int:
	var d := SaveData.section("daily")
	var last := int(d.get("last_day", -1))
	if last < 0 or last < today() - 1:
		return 0
	return int(d.get("streak", 0))


## Call when the official daily attempt is completed. Returns the new streak.
static func complete_day(day: int) -> int:
	var d := SaveData.section("daily")
	var last := int(d.get("last_day", -1))
	if last == day:
		return int(d.streak)
	d.streak = int(d.get("streak", 0)) + 1 if last == day - 1 else 1
	d.last_day = day
	d.best_streak = maxi(int(d.get("best_streak", 0)), int(d.streak))
	SaveData.mark_dirty()
	return int(d.streak)


static func is_milestone(streak: int) -> bool:
	return streak in STREAK_MILESTONES

class_name StageMode
extends GameMode
## Level-based mode. A level (data/stages/stages.json) sets the board, a goal
## (hit X targets), a time limit, how many mistakes are allowed, spawn curves,
## optional fixed patterns and optional "don't tap" decoys.
## Win/lose is reported through finished(results) with stars 1–3.

var level_id := 1
var level: Dictionary = {}
var hits := 0
var mistakes := 0

var _active: Array[Bubble] = []
var _next_spawn := 0.0
var _curve: DifficultyCurve
var _pattern_step := 0
var _last_spawned: Array[Bubble] = []


func board_size() -> Vector2i:
	_load_level()
	var b: Array = level.get("board", [4, 5])
	return Vector2i(int(b[0]), int(b[1]))


func get_duration() -> float:
	_load_level()
	var base := float(level.get("time_limit", 0.0))
	return base + _extra_time if base > 0.0 else 0.0


func uses_timer() -> bool:
	return get_duration() > 0.0


func uses_combo() -> bool:
	return false


func uses_score() -> bool:
	return false


func progress_caption() -> String:
	return "TARGETS"


func format_value(v: int) -> String:
	return "%d ★" % v


func goal() -> int:
	return int(level.get("goal", 10))


var _extra_lives := 0
var _extra_time := 0.0
var _lost_on_time := false


func max_mistakes() -> int:
	return int(level.get("max_mistakes", 3)) + _extra_lives


func continue_offer(r: Dictionary) -> String:
	if continued or bool(r.get("won", false)):
		return ""
	return "+10 SECONDS" if _lost_on_time else "+1 LIFE"


func continue_run() -> void:
	continued = true
	if _lost_on_time:
		_extra_time += 10.0
	else:
		_extra_lives += 1
	_announce_lives()
	running = true
	paused = true


func _load_level() -> void:
	var wanted := int(context.get("level_id", level_id))
	if level.is_empty() or wanted != level_id:
		level_id = wanted
		level = StageLevels.get_level(level_id)
		on_tuning_changed()


func on_tuning_changed() -> void:
	_curve = DifficultyCurve.from_dict(level.get("difficulty", {}))


func start() -> void:
	_load_level()
	super.start()
	_extra_lives = 0
	_extra_time = 0.0
	_lost_on_time = false
	hits = 0
	mistakes = 0
	_active.clear()
	_last_spawned.clear()
	_pattern_step = 0
	_next_spawn = 0.4
	progress.emit(0, goal())
	_announce_lives()


func stop() -> void:
	super.stop()
	for b in _active:
		b.expire()
	_active.clear()


func _tick(_delta: float) -> void:
	if uses_timer():
		var total := get_duration()
		var remaining := maxf(total - elapsed, 0.0)
		time_changed.emit(remaining, total)
		if remaining <= 0.0:
			_finish(false, "OUT OF TIME")
			return
	for b: Bubble in _active.duplicate():
		var age := elapsed - b.lit_at
		b.set_time_left(1.0 - age / b.life)
		if age >= b.life:
			_active.erase(b)
			var was_decoy := b.decoy
			b.expire()
			if not was_decoy:  # letting a decoy fade is exactly right
				target_missed.emit(b)
				_mistake()
				if not running:
					return
	var real_active := _active.filter(func(b: Bubble) -> bool: return not b.decoy).size()
	if real_active == 0:
		_next_spawn = minf(_next_spawn, elapsed + 0.15)
	var max_active := int(_curve.value("max_active", elapsed, 1))
	if elapsed >= _next_spawn and real_active < max_active:
		_spawn()
		_next_spawn = elapsed + float(_curve.value("spawn_interval", elapsed, 0.8)) * rng.randf_range(0.85, 1.15)


func _spawn() -> void:
	var life := float(_curve.value("lifetime", elapsed, 1.8))
	var chosen: Array[Bubble] = []
	var pattern: Array = level.get("pattern", [])
	if not pattern.is_empty():
		if _pattern_step >= pattern.size():
			if not bool(level.get("pattern_loop", true)):
				pattern = []
			_pattern_step = 0
		if not pattern.is_empty():
			for idx in pattern[_pattern_step]:
				var b: Bubble = board.bubbles[clampi(int(idx), 0, board.bubbles.size() - 1)]
				if b.state == Bubble.State.IDLE:
					chosen.append(b)
			_pattern_step += 1
	if chosen.is_empty():
		var n := int(_curve.value("simultaneous_targets", elapsed, 1))
		var pool := board.bubbles.filter(func(b: Bubble) -> bool: return b.state == Bubble.State.IDLE and not (b in _last_spawned))
		pool = shuffled(pool)
		for i in mini(n, pool.size()):
			chosen.append(pool[i])
	_last_spawned = chosen
	var decoy_chance := float(level.get("decoy_chance", 0.0))
	for b in chosen:
		var is_decoy := rng.randf() < decoy_chance
		b.lit_at = elapsed
		b.life = life * (0.8 if is_decoy else 1.0)
		b.light_up(false, not is_decoy, is_decoy)
		_active.append(b)
		if not is_decoy:
			target_lit.emit(b)


func on_bubble_pressed(b: Bubble) -> void:
	if not running or paused:
		return
	if b in _active:
		_active.erase(b)
		if b.decoy:
			b.fail()
			b.expire()
			wrong_tap.emit(b, 0)
			announce.emit("DON'T TOUCH!", "bad")
			_mistake()
			return
		hits += 1
		b.pop()
		target_hit.emit(b, 0, elapsed - b.lit_at)
		progress.emit(hits, goal())
		if hits >= goal():
			_finish(true, "")
	elif b.state == Bubble.State.IDLE:
		b.fail()
		wrong_tap.emit(b, 0)
		_mistake()


func _mistake() -> void:
	mistakes += 1
	_announce_lives()
	if max_mistakes() > 0 and mistakes > max_mistakes():
		_finish(false, "TOO MANY MISSES")


func _announce_lives() -> void:
	if max_mistakes() <= 0:
		return
	var left := maxi(max_mistakes() - mistakes, 0)
	announce.emit("LIVES  " + "●".repeat(left) + "○".repeat(max_mistakes() - left), "info" if left > 1 else "bad")


func _finish(won: bool, reason: String) -> void:
	_lost_on_time = not won and reason == "OUT OF TIME"
	running = false
	var stars := StageLevels.stars_for(level, elapsed, mistakes) if won else 0
	finished.emit({
		"title": ("LEVEL %d CLEAR" % level_id) if won else reason,
		"won": won,
		"level_id": level_id,
		"stars": stars,
		"score": stars,
		"hits": hits,
		"mistakes": mistakes,
		"time": elapsed,
		"duration": elapsed,
		"continued": continued,
		"stats": [
			["TARGETS", "%d/%d" % [hits, goal()]],
			["TIME", "%.1fs" % elapsed],
			["MISSES", str(mistakes)],
		],
	})

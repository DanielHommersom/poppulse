class_name ScoreMode
extends GameMode
## Timed mode: pop lit bubbles before their ring runs out. Faster reactions and
## longer combos score more; wrong taps and expired targets break the combo.
## All tuning lives in data/score_mode.json; difficulty via DifficultyCurve.

var best_combo := 0
var hits := 0
var wrong := 0
var expired := 0
var reaction_sum := 0.0

var _active: Array[Bubble] = []
var _next_spawn := 0.0
var _last_popped: Bubble
var _curve: DifficultyCurve


var bonus_time := 0.0


func get_duration() -> float:
	return float(cfg.get("duration", 60.0)) + bonus_time


func continue_offer(_r: Dictionary) -> String:
	return "" if continued else "+10 SECONDS"


func continue_run() -> void:
	continued = true
	bonus_time += float(cfg.get("continue_seconds", 10.0))
	running = true
	paused = true  # main's countdown un-pauses


func start() -> void:
	super.start()
	bonus_time = 0.0
	on_tuning_changed()
	best_combo = 0
	hits = 0
	wrong = 0
	expired = 0
	reaction_sum = 0.0
	_active.clear()
	_last_popped = null
	_next_spawn = 0.3
	score_changed.emit(score)
	combo_changed.emit(0, 1, false)


func stop() -> void:
	super.stop()
	for b in _active:
		b.expire()
	_active.clear()


func _tick(_delta: float) -> void:
	var total := get_duration()
	var remaining := maxf(total - elapsed, 0.0)
	time_changed.emit(remaining, total)
	if remaining <= 0.0:
		_finish()
		return

	var d := _difficulty()

	for b: Bubble in _active.duplicate():
		var age := elapsed - b.lit_at
		b.set_time_left(1.0 - age / b.life)
		if age >= b.life:
			_active.erase(b)
			expired += 1
			b.expire()
			target_missed.emit(b)
			_break_combo()

	if _active.is_empty():
		_next_spawn = minf(_next_spawn, elapsed + _p("empty_gap", 0.12))
	if elapsed >= _next_spawn and _active.size() < int(d.max_active):
		_spawn(float(d.lifetime))
		_next_spawn = elapsed + float(d.interval) * rng.randf_range(0.8, 1.2)


func on_bubble_pressed(b: Bubble) -> void:
	if not running:
		return
	if b in _active:
		_hit(b)
	elif b.state == Bubble.State.IDLE:
		_wrong(b)
	# Taps on a bubble still in its pop cooldown are ignored (no double-tap penalty).


func _hit(b: Bubble) -> void:
	var pts_cfg: Dictionary = cfg.get("points", {})
	var reaction := elapsed - b.lit_at
	_active.erase(b)
	combo += 1
	best_combo = maxi(best_combo, combo)
	var old_mult := multiplier
	@warning_ignore("integer_division")
	multiplier = mini(1 + combo / int(pts_cfg.get("combo_step", 5)), int(pts_cfg.get("max_multiplier", 8)))
	var speed := clampf(1.0 - reaction / float(pts_cfg.get("speed_window", 0.9)), 0.0, 1.0)
	var raw := (float(pts_cfg.get("base", 100)) + float(pts_cfg.get("speed_bonus", 100)) * speed) * multiplier
	var points := int(snappedf(raw, 10.0))
	score += points
	hits += 1
	reaction_sum += reaction
	b.pop()
	_last_popped = b
	target_hit.emit(b, points, reaction)
	score_changed.emit(score)
	combo_changed.emit(combo, multiplier, multiplier > old_mult)
	if multiplier > old_mult:
		multiplier_up.emit(multiplier)


func _wrong(b: Bubble) -> void:
	var penalty := int(cfg.get("points", {}).get("wrong_penalty", 50))
	penalty = mini(penalty, score)
	wrong += 1
	score -= penalty
	b.fail()
	wrong_tap.emit(b, penalty)
	score_changed.emit(score)
	_break_combo()


func _break_combo() -> void:
	if combo == 0:
		return
	var prev := combo
	combo = 0
	multiplier = 1
	combo_broken.emit(prev)
	combo_changed.emit(0, 1, false)


func _spawn(lifetime: float) -> void:
	var candidates: Array[Bubble] = []
	for b in board.bubbles:
		if b.state == Bubble.State.IDLE and b != _last_popped:
			candidates.append(b)
	if candidates.is_empty():
		return
	var b: Bubble = pick(candidates)
	b.lit_at = elapsed
	b.life = lifetime
	b.light_up()
	_active.append(b)
	target_lit.emit(b)


## Current spawn parameters from the data-driven curve (axis = seconds into the run).
func _difficulty() -> Dictionary:
	if _curve == null:
		on_tuning_changed()
	return {
		"interval": _curve.value("spawn_interval", elapsed, 0.9),
		"lifetime": _curve.value("lifetime", elapsed, 1.9),
		"max_active": _curve.value("max_active", elapsed, 1),
	}


func on_tuning_changed() -> void:
	var d: Dictionary = cfg.get("difficulty", {})
	# Very first run ever: a gentler start curve (data: "first_run").
	if bool(context.get("first_run", false)) and cfg.has("first_run"):
		d = d.duplicate(true)
		var fr: Dictionary = cfg.first_run
		for k in fr:
			if k == "params":
				(d.params as Dictionary).merge(fr.params, true)
			else:
				d[k] = fr[k]
	_curve = DifficultyCurve.from_dict(d)


func _p(key: String, fallback: float) -> float:
	return float(cfg.get(key, fallback))


func _finish() -> void:
	stop()
	var attempts := hits + wrong + expired
	var avg_ms := int(reaction_sum / hits * 1000.0) if hits > 0 else 0
	var accuracy := float(hits) / attempts if attempts > 0 else 0.0
	finished.emit({
		"title": "TIME'S UP",
		"score": score,
		"best_combo": best_combo,
		"hits": hits,
		"wrong": wrong,
		"expired": expired,
		"avg_reaction_ms": avg_ms,
		"accuracy": accuracy,
		"duration": elapsed,
		"continued": continued,
		"stats": [
			["BEST COMBO", str(best_combo)],
			["AVG MS", str(avg_ms) if avg_ms > 0 else "-"],
			["ACCURACY", "%d%%" % int(round(accuracy * 100.0))],
		],
	})

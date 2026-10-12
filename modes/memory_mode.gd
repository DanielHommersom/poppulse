class_name MemoryMode
extends GameMode
## Simon-style: watch a pattern, then repeat it. Every cleared round adds one
## step. Each bubble has its own tone (via the `cue` signal), so the pattern is
## readable by position *and* sound — colour is never the only hint.
## Show speed per round comes from the DifficultyCurve in data/memory_mode.json.

enum Phase { GAP, SHOW, INPUT, REPLAY, DONE }

var phase := Phase.GAP
var pattern: Array[int] = []  # bubble indices
var completed := 0  # longest fully repeated pattern
var taps := 0

var _round := 0
var _step := 0
var _next_at := 0.0
var _curve: DifficultyCurve


func uses_timer() -> bool:
	return false


func uses_combo() -> bool:
	return false


func hit_sound() -> bool:
	return false


func progress_caption() -> String:
	return "ROUND"


func start() -> void:
	super.start()
	on_tuning_changed()
	pattern.clear()
	completed = 0
	taps = 0
	_round = 0
	for i in int(cfg.get("start_length", 3)) - 1:
		pattern.append(_random_index())
	score_changed.emit(0)
	_begin_round()


func stop() -> void:
	super.stop()
	input_locked.emit(false)


func on_tuning_changed() -> void:
	_curve = DifficultyCurve.from_dict(cfg.get("difficulty", {}))


## Note per bubble: its index on the board, which climbs the pentatonic scale.
func note_of(b: Bubble) -> int:
	return b.index


func _begin_round() -> void:
	_round += 1
	pattern.append(_random_index())
	progress.emit(_round, 0)
	phase = Phase.GAP
	_next_at = elapsed + float(cfg.get("gap_before_round", 0.7))
	input_locked.emit(true)
	announce.emit("WATCH", "info")


func _random_index() -> int:
	var n := board.bubbles.size()
	var i := rng.randi() % n
	if not pattern.is_empty() and i == pattern[pattern.size() - 1]:
		i = (i + 1 + rng.randi() % (n - 1)) % n  # no immediate repeats: they read as one blink
	return i


func _tick(_delta: float) -> void:
	if elapsed < _next_at:
		return
	match phase:
		Phase.GAP:
			phase = Phase.SHOW
			_step = 0
			_show_step()
		Phase.SHOW, Phase.REPLAY:
			_step += 1
			if _step < pattern.size():
				_show_step()
			elif phase == Phase.SHOW:
				phase = Phase.INPUT
				_step = 0
				input_locked.emit(false)
				announce.emit("YOUR TURN", "good")
			else:
				_finish()


func _show_step() -> void:
	var b: Bubble = board.bubbles[pattern[_step]]
	var show := float(_curve.value("show_time", _round, 0.5))
	if phase == Phase.REPLAY:
		show = 0.4
	b.blink(show)
	cue.emit(b, note_of(b))
	_next_at = elapsed + show + float(_curve.value("show_gap", _round, 0.12)) + 0.18


func on_bubble_pressed(b: Bubble) -> void:
	if not running or paused or phase != Phase.INPUT:
		return
	if b.index == pattern[_step]:
		taps += 1
		b.blink(0.12)
		cue.emit(b, note_of(b))
		_step += 1
		if _step >= pattern.size():
			completed = pattern.size()
			score = completed
			score_changed.emit(score)
			target_hit.emit(b, 0, 0.0)
			announce.emit("NICE!", "good")
			_begin_round()
	else:
		b.fail()
		wrong_tap.emit(b, 0)
		announce.emit("IT WAS…", "bad")
		input_locked.emit(true)
		phase = Phase.REPLAY
		_step = -1
		_next_at = elapsed + 0.9


func _finish() -> void:
	phase = Phase.DONE
	stop()
	finished.emit({
		"title": "PATTERN LENGTH",
		"score": completed,
		"rounds": _round,
		"taps": taps,
		"duration": elapsed,
		"stats": [
			["ROUND", str(_round)],
			["CORRECT TAPS", str(taps)],
		],
	})

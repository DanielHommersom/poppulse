class_name ReflexMode
extends GameMode
## Pure reaction time. A round is N stimuli: after a random wait one bubble
## lights up and the player taps it as fast as possible.
##
## Timing (see docs/reflex-timing.md): the start stamp is taken right after the
## frame that first shows the lit bubble has been submitted
## (RenderingServer.frame_post_draw); the end stamp is the engine clock at the
## moment the touch-down event is handled (Board.last_press_usec), not the
## frame time of the next _process.

enum Phase { WAITING, LIT, DONE }

var phase := Phase.WAITING
var times: Array[int] = []  # ms per successful stimulus
var misses := 0
var early := 0

var _done := 0
var _target: Bubble
var _fire_at := 0.0  # mode time at which the next stimulus lights
var _lit_at_mode := 0.0
var _lit_usec := 0  # 0 = lit but not on screen yet
var _best_single := 0
var _last_target: Bubble


func uses_timer() -> bool:
	return false


func uses_combo() -> bool:
	return false


func uses_score() -> bool:
	return false


func progress_caption() -> String:
	return "TAP"


func lower_is_better() -> bool:
	return true


func format_value(v: int) -> String:
	return "%d ms" % v


func stimuli() -> int:
	return int(cfg.get("stimuli", 10))


func start() -> void:
	super.start()
	times.clear()
	misses = 0
	early = 0
	_done = 0
	_target = null
	_last_target = null
	_best_single = int(context.get("best_single", 0))
	progress.emit(0, stimuli())
	_arm()


func stop() -> void:
	super.stop()
	_clear_target()


## Pausing while a target is lit would add the pause to the reaction: re-arm.
func set_paused(p: bool) -> void:
	super.set_paused(p)
	if p and phase == Phase.LIT:
		_clear_target()
		_arm()


func on_tuning_changed() -> void:
	pass


func _arm(say_wait := true) -> void:
	phase = Phase.WAITING
	var lo := float(cfg.get("wait_min", 1.0))
	var hi := maxf(float(cfg.get("wait_max", 3.0)), lo)
	_fire_at = elapsed + rng.randf_range(lo, hi)
	if say_wait:
		announce.emit("WAIT…", "info")


func _tick(_delta: float) -> void:
	match phase:
		Phase.WAITING:
			if elapsed >= _fire_at:
				_light()
		Phase.LIT:
			if _lit_usec > 0 and elapsed - _lit_at_mode >= float(cfg.get("timeout", 2.0)):
				_target.expire()
				target_missed.emit(_target)
				_resolve_miss("TOO SLOW")


func _light() -> void:
	var candidates := board.bubbles.filter(func(b: Bubble) -> bool: return b.state == Bubble.State.IDLE and b != _last_target)
	if candidates.is_empty():
		_fire_at = elapsed + 0.1
		return
	_target = pick(candidates)
	_last_target = _target
	_target.light_up(true, false)
	phase = Phase.LIT
	_lit_at_mode = elapsed
	_lit_usec = 0
	announce.emit("TAP!", "good")
	target_lit.emit(_target)
	_stamp_when_visible(_target)


func _stamp_when_visible(b: Bubble) -> void:
	await RenderingServer.frame_post_draw
	if phase == Phase.LIT and _target == b and _lit_usec == 0:
		_lit_usec = Time.get_ticks_usec()


func on_bubble_pressed(b: Bubble) -> void:
	if not running or paused:
		return
	match phase:
		Phase.WAITING:
			early += 1
			b.fail()
			wrong_tap.emit(b, 0)
			_arm(false)  # the stimulus is repeated
			announce.emit("TOO EARLY", "bad")
		Phase.LIT:
			if b == _target:
				_hit(b)
			elif b.state == Bubble.State.IDLE:
				b.fail()
				wrong_tap.emit(b, 0)
				_clear_target()
				_resolve_miss("WRONG BUBBLE")


func _hit(b: Bubble) -> void:
	# A tap before the lit frame reached the screen cannot be a reaction to it.
	var start := _lit_usec if _lit_usec > 0 else Time.get_ticks_usec()
	var ms := maxi(int(round((board.last_press_usec - start) / 1000.0)), 1)
	times.append(ms)
	# Only a beaten earlier record counts as a personal best (not the very first tap ever).
	var pb := _best_single > 0 and ms < _best_single
	if pb or _best_single == 0:
		_best_single = ms
	b.pop()
	_target = null
	target_hit.emit(b, 0, ms / 1000.0)
	reaction.emit(b, ms, pb)
	_next()


func _resolve_miss(text: String) -> void:
	misses += 1
	_target = null
	_next()
	announce.emit(text, "bad")


func _next() -> void:
	_done += 1
	progress.emit(_done, stimuli())
	if _done >= stimuli():
		_finish()
	else:
		_arm(false)


func _clear_target() -> void:
	if _target != null:
		_target.expire()
		_target = null


func _finish() -> void:
	phase = Phase.DONE
	stop()
	var avg := 0
	var best := 0
	var worst := 0
	if not times.is_empty():
		var sum := 0
		for t in times:
			sum += t
		avg = int(round(float(sum) / times.size()))
		best = times.min()
		worst = times.max()
	finished.emit({
		"title": "AVERAGE",
		"score": avg,
		"best": best,
		"worst": worst,
		"times": times.duplicate(),
		"misses": misses,
		"early": early,
		"best_single": _best_single,
		"duration": elapsed,
		"stats": [
			["BEST", ("%d ms" % best) if best > 0 else "-"],
			["WORST", ("%d ms" % worst) if worst > 0 else "-"],
			["MISSES", str(misses + early)],
		],
	})

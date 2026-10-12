extends TestCase
## US-09: DifficultyCurve + Score Mode equivalence with the old linear ramp.


## The pre-US-09 Score Mode ramp, kept verbatim as the reference.
static func _old(elapsed: float) -> Dictionary:
	var t := clampf(elapsed / 50.0, 0.0, 1.0)
	return {
		"interval": lerpf(0.9, 0.34, t),
		"lifetime": lerpf(1.9, 0.8, t),
		"max_active": roundi(lerpf(1.0, 4.0, t)),
	}


func test_score_mode_identical_to_old_ramp() -> void:
	var mode := ModeRegistry.create("score")
	mode.on_tuning_changed()
	var x := 0.0
	while x <= 65.0:
		mode.elapsed = x
		var a: Dictionary = mode._difficulty()
		var b := _old(x)
		eq(a.interval, b.interval, "interval @%.1f" % x)
		eq(a.lifetime, b.lifetime, "lifetime @%.1f" % x)
		eq(int(a.max_active), int(b.max_active), "max_active @%.1f" % x)
		x += 0.25
	mode.free()


func test_easing_and_keys() -> void:
	var c := DifficultyCurve.from_dict({
		"axis": "level", "x_start": 1, "x_end": 11, "easing": "ease_in",
		"params": {
			"lifetime": [2.0, 1.0],
			"pattern_length": [3, 9],
			"spawn_interval": {"keys": [[1, 1.0], [5, 0.5], [11, 0.2]]},
			"simultaneous_targets": 2,
		},
	})
	eq(c.value("lifetime", 1), 2.0, "start")
	eq(c.value("lifetime", 11), 1.0, "end")
	eq(c.value("lifetime", 6), 1.75, "ease_in midpoint (t=0.5 -> 0.25)")
	eq(c.value("lifetime", 99), 1.0, "clamped past end")
	check(c.value("pattern_length", 6) is int, "count params are ints")
	eq(c.value("simultaneous_targets", 3), 2, "constant")
	eq(c.value("missing", 3, 7.0), 7.0, "fallback")
	var lin := DifficultyCurve.from_dict({"params": {"spawn_interval": {"keys": [[1, 1.0], [5, 0.5], [11, 0.2]]}}})
	eq(lin.value("spawn_interval", 3), 0.75, "keyframe interpolation")
	eq(lin.value("spawn_interval", 0), 1.0, "before first key")
	eq(lin.sample(5).spawn_interval, 0.5, "sample()")

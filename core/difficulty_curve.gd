class_name DifficultyCurve
extends RefCounted
## Data-driven difficulty: interpolates named parameters along one axis
## (seconds into a run, level number or round number). Every mode builds its
## curve from JSON; see docs/data-format.md for the schema.
##
##   {"axis": "time", "x_start": 0, "x_end": 50, "easing": "linear",
##    "params": {"spawn_interval": [0.9, 0.34],
##               "lifetime": {"keys": [[0, 1.9], [30, 1.2], [50, 0.8]]}}}

## Parameters that are counts and therefore rounded to whole numbers.
const INTEGER_PARAMS := ["max_active", "simultaneous_targets", "pattern_length", "targets"]

var axis := "time"
var x_start := 0.0
var x_end := 1.0
var easing := "linear"
## The source dictionary is kept by reference so live tuning edits apply at once.
var params: Dictionary = {}


static func from_dict(d: Dictionary) -> DifficultyCurve:
	var c := DifficultyCurve.new()
	c.axis = str(d.get("axis", "time"))
	c.x_start = float(d.get("x_start", 0.0))
	c.x_end = float(d.get("x_end", 1.0))
	c.easing = str(d.get("easing", "linear"))
	c.params = d.get("params", {})
	return c


## All parameters at position x.
func sample(x: float) -> Dictionary:
	var out := {}
	for name in params:
		out[name] = value(name, x)
	return out


func value(name: String, x: float, fallback := 0.0) -> Variant:
	if not params.has(name):
		return fallback
	var spec: Variant = params[name]
	var v: float
	if spec is Array and (spec as Array).size() >= 2:
		v = lerpf(float(spec[0]), float(spec[1]), _eased(_progress(x)))
	elif spec is Dictionary and (spec as Dictionary).has("keys"):
		v = _keyed((spec as Dictionary).keys, x)
	else:
		v = float(spec)  # constant
	if name in INTEGER_PARAMS:
		return roundi(v)
	return v


## 0..1 position between x_start and x_end (clamped).
func _progress(x: float) -> float:
	if is_equal_approx(x_end, x_start):
		return 1.0
	return clampf((x - x_start) / (x_end - x_start), 0.0, 1.0)


func _eased(t: float) -> float:
	match easing:
		"ease_in":
			return t * t
		"ease_out":
			return 1.0 - (1.0 - t) * (1.0 - t)
		"ease_in_out", "smooth":
			return t * t * (3.0 - 2.0 * t)
		_:
			return t


## Piecewise-linear keyframes [[x, value], …] in axis units; easing applies per segment.
func _keyed(keys: Array, x: float) -> float:
	if keys.is_empty():
		return 0.0
	if x <= float(keys[0][0]):
		return float(keys[0][1])
	for i in range(1, keys.size()):
		var a: Array = keys[i - 1]
		var b: Array = keys[i]
		if x <= float(b[0]):
			var t := (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.0001)
			return lerpf(float(a[1]), float(b[1]), _eased(t))
	return float(keys[keys.size() - 1][1])

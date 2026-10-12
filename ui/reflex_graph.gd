class_name ReflexGraph
extends Control
## Neon line chart of recent Reflex averages (ms, lower = better), drawn with
## _draw() — no chart library. The y axis is flipped so "up" means faster.

var values: Array = []  # oldest → newest
var best := 0
var line_color := UiStyle.CYAN


func _init(p_values: Array = [], p_best := 0) -> void:
	values = p_values
	best = p_best
	custom_minimum_size = Vector2(0, 170)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_data(p_values: Array, p_best: int) -> void:
	values = p_values
	best = p_best
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2(8, 10), size - Vector2(16, 34))
	# frame + grid
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.03), true)
	for i in 4:
		var y := r.position.y + r.size.y * i / 3.0
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(1, 1, 1, 0.06), 1.0)
	var f := UiStyle.font()
	if values.size() < 2:
		draw_string(f, Vector2(0, size.y * 0.5), "Play a few more rounds to see your trend", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color(1, 1, 1, 0.45))
		return
	var lo := float(values.min())
	var hi := float(values.max())
	if best > 0:
		lo = minf(lo, best)
	var pad := maxf((hi - lo) * 0.15, 10.0)
	lo -= pad
	hi += pad
	var pts := PackedVector2Array()
	for i in values.size():
		var x := r.position.x + r.size.x * i / float(values.size() - 1)
		var t := (float(values[i]) - lo) / (hi - lo)
		pts.append(Vector2(x, r.position.y + r.size.y * t))  # low ms = high on screen
	# best-ever reference line (dashed gold)
	if best > 0:
		var by := r.position.y + r.size.y * (best - lo) / (hi - lo)
		var x := r.position.x
		while x < r.end.x:
			draw_line(Vector2(x, by), Vector2(minf(x + 10, r.end.x), by), Color(UiStyle.GOLD, 0.7), 2.0)
			x += 18
		draw_string(f, Vector2(r.position.x + 4, by - 6), "BEST %d" % best, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(UiStyle.GOLD, 0.9))
	# glow pass + line + dots
	draw_polyline(pts, Color(line_color, 0.18), 12.0, true)
	draw_polyline(pts, line_color, 3.5, true)
	for i in pts.size():
		var last := i == pts.size() - 1
		draw_circle(pts[i], 7.0 if last else 4.0, Color.WHITE if last else line_color, true, -1, true)
	draw_string(f, Vector2(0, size.y - 4), "LAST %d ROUNDS" % values.size(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color(1, 1, 1, 0.4))


## [best ever, mean of last 10, trend ms (negative = faster)] for `values`.
static func summary(p_values: Array, p_best: int) -> Dictionary:
	var last10 := p_values.slice(maxi(p_values.size() - 10, 0))
	var avg10 := 0
	if not last10.is_empty():
		var s := 0.0
		for v in last10:
			s += float(v)
		avg10 = int(round(s / last10.size()))
	var trend := 0
	if p_values.size() >= 4:
		var half := mini(5, p_values.size() / 2)
		var recent := p_values.slice(p_values.size() - half)
		var before := p_values.slice(p_values.size() - half * 2, p_values.size() - half)
		trend = int(round(_mean(recent) - _mean(before)))
	return {"best": p_best, "avg10": avg10, "trend": trend}


static func _mean(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += float(v)
	return s / maxf(a.size(), 1.0)

class_name NeonIcon
extends Control
## Crisp vector icons drawn with _draw(), so the game ships without icon assets
## and every icon scales cleanly from iPhone to iPad.

var icon := "gear":
	set(v):
		icon = v
		queue_redraw()
var color := Color.WHITE:
	set(v):
		color = v
		queue_redraw()
var line := 0.085  # stroke width relative to the icon size


func _init(p_icon := "gear", p_color := Color.WHITE) -> void:
	icon = p_icon
	color = p_color
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) * 0.5
	draw_set_transform(o, 0.0, Vector2(s, s))
	var w := line * s
	match icon:
		"gear": _gear(w)
		"pause": _pause()
		"play": _play()
		"close": _close(w)
		"chart": _chart(w)
		"palette": _palette(w)
		"flame": _flame()
		"star": _star(0.5, 0.52, 0.44, color)
		"star_empty": _star_outline(w)
		"lock": _lock(w)
		"trophy": _trophy(w)
		"share": _share(w)
		"bolt": _bolt()
		"brain": _brain(w)
		"target": _target(w)
		"crown": _crown()
		"sound": _sound(w, true)
		"mute": _sound(w, false)
		"vibrate": _vibrate(w)
		"calendar": _calendar(w)
		"stages": _stages(w)
		"people": _people(w)
		"bubble": _bubble(w)
		"gift": _gift(w)
		"medal": _medal(w)
		"back": _back(w)
		"check": _check(w)
		"menu": _menu(w)
		"next": _next(w)
		"doc": _doc(w)
	draw_set_transform(Vector2.ZERO)


# Coordinates below are in a 0..1 unit square; draw_set_transform scales them.
# Line widths are therefore divided by the scale.

func _lw(w: float) -> float:
	return w / maxf(minf(size.x, size.y), 1.0)


func _gear(w: float) -> void:
	var pts := PackedVector2Array()
	var teeth := 8
	for i in teeth * 4:
		var a := TAU * i / (teeth * 4.0)
		var r := 0.46 if (i % 4) in [1, 2] else 0.36
		pts.append(Vector2(0.5, 0.5) + Vector2.from_angle(a) * r)
	pts.append(pts[0])
	draw_polyline(pts, color, _lw(w), true)
	draw_arc(Vector2(0.5, 0.5), 0.14, 0, TAU, 32, color, _lw(w), true)


func _pause() -> void:
	draw_rect(Rect2(0.24, 0.18, 0.17, 0.64), color)
	draw_rect(Rect2(0.59, 0.18, 0.17, 0.64), color)


func _play() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0.28, 0.16), Vector2(0.84, 0.5), Vector2(0.28, 0.84)]), color)


func _close(w: float) -> void:
	draw_line(Vector2(0.22, 0.22), Vector2(0.78, 0.78), color, _lw(w * 1.2), true)
	draw_line(Vector2(0.78, 0.22), Vector2(0.22, 0.78), color, _lw(w * 1.2), true)


func _back(w: float) -> void:
	draw_polyline(PackedVector2Array([Vector2(0.62, 0.18), Vector2(0.3, 0.5), Vector2(0.62, 0.82)]), color, _lw(w * 1.2), true)


func _check(w: float) -> void:
	draw_polyline(PackedVector2Array([Vector2(0.18, 0.52), Vector2(0.42, 0.76), Vector2(0.84, 0.26)]), color, _lw(w * 1.3), true)


func _chart(w: float) -> void:
	for i in 3:
		var h := [0.3, 0.55, 0.42][i] as float
		draw_rect(Rect2(0.16 + i * 0.25, 0.86 - h, 0.17, h), color)
	draw_line(Vector2(0.1, 0.9), Vector2(0.9, 0.9), color, _lw(w * 0.7), true)


func _palette(w: float) -> void:
	draw_arc(Vector2(0.5, 0.5), 0.38, 0, TAU, 40, color, _lw(w), true)
	var cols := [Color(1, 0.3, 0.6), Color(0.3, 0.9, 1), Color(1, 0.85, 0.3), Color(0.5, 1, 0.5)]
	for i in 4:
		draw_circle(Vector2(0.5, 0.5) + Vector2.from_angle(-PI * 0.8 + i * 0.55) * 0.2, 0.07, cols[i], true, -1, false)


func _flame() -> void:
	var outer := PackedVector2Array([
		Vector2(0.50, 0.04), Vector2(0.60, 0.20), Vector2(0.74, 0.36), Vector2(0.82, 0.54),
		Vector2(0.80, 0.72), Vector2(0.70, 0.86), Vector2(0.50, 0.95), Vector2(0.30, 0.86),
		Vector2(0.20, 0.72), Vector2(0.18, 0.54), Vector2(0.26, 0.38), Vector2(0.34, 0.50),
		Vector2(0.38, 0.30),
	])
	var inner := PackedVector2Array([
		Vector2(0.52, 0.42), Vector2(0.62, 0.58), Vector2(0.66, 0.72), Vector2(0.60, 0.84),
		Vector2(0.50, 0.89), Vector2(0.40, 0.84), Vector2(0.35, 0.72), Vector2(0.40, 0.60),
		Vector2(0.45, 0.66),
	])
	draw_colored_polygon(outer, color)
	draw_colored_polygon(inner, Color(1, 0.92, 0.55))


func _star(cx: float, cy: float, r: float, c: Color) -> void:
	draw_colored_polygon(_star_pts(cx, cy, r), c)


func _star_outline(w: float) -> void:
	var p := _star_pts(0.5, 0.52, 0.44)
	p.append(p[0])
	draw_polyline(p, color, _lw(w * 0.8), true)


func _star_pts(cx: float, cy: float, r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		p.append(Vector2(cx, cy) + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.45))
	return p


func _lock(w: float) -> void:
	draw_rect(Rect2(0.22, 0.44, 0.56, 0.42), color)
	draw_arc(Vector2(0.5, 0.44), 0.18, PI, TAU, 24, color, _lw(w * 1.1), true)
	draw_line(Vector2(0.32, 0.44), Vector2(0.32, 0.36), color, _lw(w * 1.1))
	draw_line(Vector2(0.68, 0.44), Vector2(0.68, 0.36), color, _lw(w * 1.1))


func _trophy(w: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0.28, 0.16), Vector2(0.72, 0.16), Vector2(0.66, 0.46), Vector2(0.5, 0.56), Vector2(0.34, 0.46)]), color)
	draw_arc(Vector2(0.28, 0.3), 0.1, PI * 0.5, PI * 1.5, 12, color, _lw(w * 0.7), true)
	draw_arc(Vector2(0.72, 0.3), 0.1, -PI * 0.5, PI * 0.5, 12, color, _lw(w * 0.7), true)
	draw_rect(Rect2(0.46, 0.55, 0.08, 0.18), color)
	draw_rect(Rect2(0.3, 0.73, 0.4, 0.1), color)


func _share(w: float) -> void:
	draw_polyline(PackedVector2Array([Vector2(0.34, 0.4), Vector2(0.2, 0.4), Vector2(0.2, 0.86), Vector2(0.8, 0.86), Vector2(0.8, 0.4), Vector2(0.66, 0.4)]), color, _lw(w), true)
	draw_line(Vector2(0.5, 0.62), Vector2(0.5, 0.1), color, _lw(w), true)
	draw_polyline(PackedVector2Array([Vector2(0.34, 0.25), Vector2(0.5, 0.1), Vector2(0.66, 0.25)]), color, _lw(w), true)


func _bolt() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0.58, 0.08), Vector2(0.24, 0.56), Vector2(0.48, 0.56), Vector2(0.4, 0.92), Vector2(0.76, 0.42), Vector2(0.52, 0.42)]), color)


func _brain(w: float) -> void:
	for p in [Vector2(0.36, 0.38), Vector2(0.62, 0.36), Vector2(0.32, 0.62), Vector2(0.64, 0.62)]:
		draw_arc(p, 0.17, 0, TAU, 24, color, _lw(w * 0.8), true)
	draw_line(Vector2(0.5, 0.2), Vector2(0.5, 0.82), color, _lw(w * 0.8), true)


func _target(w: float) -> void:
	draw_arc(Vector2(0.5, 0.5), 0.4, 0, TAU, 40, color, _lw(w), true)
	draw_arc(Vector2(0.5, 0.5), 0.24, 0, TAU, 32, color, _lw(w), true)
	draw_circle(Vector2(0.5, 0.5), 0.08, color, true, -1, false)


func _crown() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0.14, 0.32), Vector2(0.34, 0.5), Vector2(0.5, 0.22), Vector2(0.66, 0.5), Vector2(0.86, 0.32), Vector2(0.78, 0.76), Vector2(0.22, 0.76)]), color)


func _sound(w: float, on: bool) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0.12, 0.38), Vector2(0.3, 0.38), Vector2(0.5, 0.2), Vector2(0.5, 0.8), Vector2(0.3, 0.62), Vector2(0.12, 0.62)]), color)
	if on:
		draw_arc(Vector2(0.5, 0.5), 0.16, -0.9, 0.9, 12, color, _lw(w * 0.8), true)
		draw_arc(Vector2(0.5, 0.5), 0.3, -0.9, 0.9, 16, color, _lw(w * 0.8), true)
	else:
		draw_line(Vector2(0.62, 0.36), Vector2(0.88, 0.64), color, _lw(w), true)
		draw_line(Vector2(0.88, 0.36), Vector2(0.62, 0.64), color, _lw(w), true)


func _vibrate(w: float) -> void:
	draw_rect(Rect2(0.34, 0.16, 0.32, 0.68), color, false, _lw(w))
	for x in [0.2, 0.8]:
		draw_line(Vector2(x, 0.34), Vector2(x, 0.66), color, _lw(w * 0.8), true)
	draw_line(Vector2(0.08, 0.42), Vector2(0.08, 0.58), color, _lw(w * 0.8), true)
	draw_line(Vector2(0.92, 0.42), Vector2(0.92, 0.58), color, _lw(w * 0.8), true)


func _calendar(w: float) -> void:
	draw_rect(Rect2(0.16, 0.22, 0.68, 0.62), color, false, _lw(w))
	draw_rect(Rect2(0.16, 0.22, 0.68, 0.16), color)
	draw_line(Vector2(0.34, 0.12), Vector2(0.34, 0.28), color, _lw(w))
	draw_line(Vector2(0.66, 0.12), Vector2(0.66, 0.28), color, _lw(w))
	draw_circle(Vector2(0.5, 0.62), 0.08, color, true, -1, false)


func _stages(w: float) -> void:
	for i in 3:
		var p := Vector2(0.2 + i * 0.3, 0.72 - i * 0.22)
		draw_circle(p, 0.09, color, true, -1, false)
		if i < 2:
			draw_line(p, p + Vector2(0.3, -0.22), color, _lw(w * 0.7), true)


func _people(w: float) -> void:
	for x in [0.33, 0.67]:
		draw_circle(Vector2(x, 0.34), 0.11, color, true, -1, false)
		draw_arc(Vector2(x, 0.86), 0.2, PI, TAU, 16, color, _lw(w), true)


func _bubble(w: float) -> void:
	draw_arc(Vector2(0.5, 0.5), 0.36, 0, TAU, 40, color, _lw(w), true)
	draw_arc(Vector2(0.5, 0.5), 0.22, PI * 1.05, PI * 1.45, 10, color, _lw(w * 0.8), true)


func _gift(w: float) -> void:
	draw_rect(Rect2(0.18, 0.4, 0.64, 0.46), color, false, _lw(w))
	draw_rect(Rect2(0.14, 0.3, 0.72, 0.12), color)
	draw_line(Vector2(0.5, 0.3), Vector2(0.5, 0.86), color, _lw(w))
	draw_arc(Vector2(0.4, 0.24), 0.08, 0, TAU, 12, color, _lw(w * 0.7), true)
	draw_arc(Vector2(0.6, 0.24), 0.08, 0, TAU, 12, color, _lw(w * 0.7), true)


func _medal(w: float) -> void:
	draw_line(Vector2(0.36, 0.1), Vector2(0.48, 0.42), color, _lw(w))
	draw_line(Vector2(0.64, 0.1), Vector2(0.52, 0.42), color, _lw(w))
	draw_circle(Vector2(0.5, 0.62), 0.24, color, true, -1, false)
	_star(0.5, 0.63, 0.13, Color(0, 0, 0, 0.45))


func _menu(w: float) -> void:
	for y in [0.28, 0.5, 0.72]:
		draw_line(Vector2(0.2, y), Vector2(0.8, y), color, _lw(w * 1.1), true)


func _next(w: float) -> void:
	draw_polyline(PackedVector2Array([Vector2(0.38, 0.18), Vector2(0.7, 0.5), Vector2(0.38, 0.82)]), color, _lw(w * 1.2), true)


func _doc(w: float) -> void:
	draw_polyline(PackedVector2Array([Vector2(0.24, 0.12), Vector2(0.6, 0.12), Vector2(0.78, 0.3), Vector2(0.78, 0.88), Vector2(0.24, 0.88), Vector2(0.24, 0.12)]), color, _lw(w), true)
	for y in [0.45, 0.6, 0.75]:
		draw_line(Vector2(0.34, y), Vector2(0.68, y), color, _lw(w * 0.7), true)

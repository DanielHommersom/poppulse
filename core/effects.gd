class_name Effects
extends Node2D
## Fire-and-forget juice: particle bursts, shockwave rings, floating text.
## Everything is pooled: nodes are created once and recycled, so a 50+ combo
## allocates nothing per hit (no GC/allocation spikes, flat memory over time).

const BURST_POOL := 24
const RING_POOL := 32
const TEXT_POOL := 24

static var _dot: Texture2D
var _add_mat := CanvasItemMaterial.new()
var _fade_curve := Curve.new()

var _bursts: Array[CPUParticles2D] = []
var _rings: Array[ShockRing] = []
var _texts: Array[Label] = []
var _burst_next := 0
var _ring_next := 0
var _text_next := 0
var _ring_tweens := {}
var _text_tweens := {}
## Accessibility (US-36): fewer / softer particles and no big flashes.
var reduced := false


func _ready() -> void:
	_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_fade_curve.add_point(Vector2(0.0, 1.0))
	_fade_curve.add_point(Vector2(1.0, 0.0))
	if _dot == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 64
		t.height = 64
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		_dot = t
	for i in BURST_POOL:
		_bursts.append(_make_burst())
	for i in RING_POOL:
		var r := ShockRing.new()
		r.material = _add_mat
		r.visible = false
		add_child(r)
		_rings.append(r)
	for i in TEXT_POOL:
		var l := Label.new()
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.visible = false
		add_child(l)
		_texts.append(l)


func _make_burst() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _dot
	p.material = _add_mat
	p.amount = 20
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2(0, 420)
	p.damping_min = 300.0
	p.damping_max = 600.0
	p.scale_amount_min = 0.2
	p.scale_amount_max = 0.55
	p.scale_amount_curve = _fade_curve
	p.emitting = false
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.2, Color.WHITE)
	p.color_ramp = ramp
	add_child(p)
	return p


func burst(pos: Vector2, color: Color, amount := 20, power := 1.0) -> void:
	var p := _bursts[_burst_next]
	_burst_next = (_burst_next + 1) % _bursts.size()
	if reduced:
		amount = int(amount * 0.4)
		power *= 0.7
	p.amount = clampi(amount, 2, 48)  # resizes the particle buffer only; no node churn
	p.initial_velocity_min = 160.0 * power
	p.initial_velocity_max = 560.0 * power
	# Ramp points (sorted by offset): 0 white @0, 1 colour @0.2, 2 transparent @1.
	p.color_ramp.set_color(1, color)
	p.color_ramp.set_color(2, Color(color, 0.0))
	p.position = pos
	p.restart()
	p.emitting = true


func ring(pos: Vector2, color: Color, from_r: float, to_r: float, dur := 0.35, width := 8.0) -> void:
	var r := _rings[_ring_next]
	_ring_next = (_ring_next + 1) % _rings.size()
	var old: Tween = _ring_tweens.get(r)
	if old != null and old.is_valid():
		old.kill()
	r.position = pos
	r.radius = from_r
	r.width = width * (0.6 if reduced else 1.0)
	r.col = color
	r.modulate.a = 0.7 if reduced else 1.0
	r.visible = true
	var t := r.create_tween().set_parallel(true)
	t.tween_property(r, "radius", to_r, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(r, "width", 1.0, dur)
	t.tween_property(r, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(r.hide)
	_ring_tweens[r] = t


func float_text(pos: Vector2, text: String, color: Color, size := 46) -> void:
	var l := _texts[_text_next]
	_text_next = (_text_next + 1) % _texts.size()
	var old: Tween = _text_tweens.get(l)
	if old != null and old.is_valid():
		old.kill()
	l.text = text
	if l.label_settings == null or l.label_settings.font_size != size:
		l.label_settings = UiStyle.label_settings(size, color)
	else:
		UiStyle.set_label_color(l, color)
	l.size = Vector2(320, size * 1.5)
	l.pivot_offset = l.size * 0.5
	l.position = pos - l.size * 0.5
	l.scale = Vector2(0.5, 0.5)
	l.modulate.a = 1.0
	l.visible = true
	var t := l.create_tween().set_parallel(true)
	t.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "position:y", l.position.y - 110.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.4)
	t.chain().tween_callback(l.hide)
	_text_tweens[l] = t


func pooled_nodes() -> int:
	return get_child_count()


class ShockRing extends Node2D:
	var radius := 10.0:
		set(v):
			radius = v
			queue_redraw()
	var width := 6.0
	var col := Color.WHITE

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, col, width, true)

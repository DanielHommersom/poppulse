class_name Board
extends Node2D
## The play field: builds the bubble grid, lays it out for any screen,
## handles multi-touch hit-testing and the idle "attract" shimmer.

signal bubble_pressed(bubble: Bubble)
signal bubble_released(bubble: Bubble)

var cols := 5
var rows := 6
var bubbles: Array[Bubble] = []
var cell := 100.0
var plate_rect := Rect2()
var input_enabled := true
## Engine clock (µs) at which the latest touch-down was handled. Reflex Mode
## measures reaction time against this instead of the (later) frame time.
var last_press_usec := 0
var attract := true:
	set(v):
		attract = v
		if not v:
			for b in bubbles:
				b.idle_glow = 0.0

var _touches := {}  # touch index -> Bubble
var _t := 0.0
var _plate := StyleBoxFlat.new()
## Animated re-layout (menu ↔ play): from/to snapshots + progress 0..1.
var _anim := 1.0
var _from := {}
var _to := {}


func _ready() -> void:
	_plate.set_border_width_all(3)
	_plate.shadow_size = 36
	_plate.anti_aliasing = true
	ThemeManager.theme_changed.connect(apply_theme)
	ThemeManager.design_changed.connect(func(_d: Dictionary) -> void: _apply_shape())
	apply_theme(ThemeManager.current)


func _apply_shape() -> void:
	for b in bubbles:
		b.set_shape(ThemeManager.shape())


## Recolours plate and bubbles from a theme (live, no rebuild).
func apply_theme(t: ThemeData) -> void:
	_plate.bg_color = t.plate_bg
	_plate.border_color = t.plate_border
	_plate.shadow_color = t.plate_glow
	for b in bubbles:
		b.apply_theme(t.bubble_color(b.index, b.grid.y, cols, rows), t.bubble_params)
	queue_redraw()


func build(p_cols: int, p_rows: int) -> void:
	for b in bubbles:
		b.queue_free()
	bubbles.clear()
	cols = p_cols
	rows = p_rows
	var theme := ThemeManager.current
	for r in rows:
		for c in cols:
			var b := Bubble.new()
			# Palette comes from the theme (Neon: rainbow rows, like the physical toy).
			b.setup(bubbles.size(), Vector2i(c, r), theme.bubble_color(bubbles.size(), r, cols, rows))
			add_child(b)
			bubbles.append(b)
			b.apply_theme(b.color, theme.bubble_params)
			b.set_shape(ThemeManager.shape())


## Fits the grid into `area`. With `animate` the board glides there (menu ↔ play).
func layout(area: Rect2, animate := false) -> void:
	var c := minf(area.size.x / (cols + 0.5), area.size.y / (rows + 0.5))
	c = minf(c, 220.0)
	var grid_size := Vector2(cols, rows) * c
	var origin := area.position + (area.size - grid_size) * 0.5
	var target := {"cell": c, "origin": origin}
	if animate and not bubbles.is_empty() and plate_rect.size != Vector2.ZERO:
		_from = {"cell": cell, "origin": plate_rect.position + Vector2.ONE * cell * 0.2}
		_to = target
		_anim = 0.0
	else:
		_anim = 1.0
		_apply_layout(c, origin)


func _apply_layout(c: float, origin: Vector2) -> void:
	cell = c
	for b in bubbles:
		b.position = origin + (Vector2(b.grid) + Vector2(0.5, 0.5)) * cell
		b.set_radius(cell * 0.37)
	plate_rect = Rect2(origin, Vector2(cols, rows) * cell).grow(cell * 0.2)
	_plate.set_corner_radius_all(int(cell * 0.45))
	queue_redraw()


func reset_all() -> void:
	_touches.clear()
	for b in bubbles:
		b.reset()


## Forget held fingers (pause / overlay): their release would arrive elsewhere.
func release_touches() -> void:
	for b: Bubble in _touches.values():
		b.release()
	_touches.clear()


func sweep() -> void:
	for b in bubbles:
		b.sweep_flash(b.grid.y * 0.04 + b.grid.x * 0.012)


func bubble_at(p: Vector2) -> Bubble:
	var best: Bubble = null
	var best_d := cell * 0.55
	for b in bubbles:
		var d := b.position.distance_to(p)
		if d < best_d:
			best_d = d
			best = b
	return best


func _draw() -> void:
	if bubbles.is_empty():
		return
	draw_style_box(_plate, plate_rect)
	for b in bubbles:  # recessed sockets
		draw_circle(b.position, b.radius * 1.1, Color(0, 0, 0, 0.5), true, -1.0, true)
		draw_arc(b.position, b.radius * 1.1, 0.0, TAU, 48, Color(1, 1, 1, 0.07), 2.0, true)


func _process(delta: float) -> void:
	if _anim < 1.0:
		_anim = minf(_anim + delta / 0.35, 1.0)
		var k := ease(_anim, -2.4)  # ease in-out
		_apply_layout(lerpf(_from.cell, _to.cell, k), (_from.origin as Vector2).lerp(_to.origin, k))
	if not attract:
		return
	_t += delta * (0.4 if Bubble.reduce_motion else 1.0)
	for b in bubbles:
		var v := 0.5 + 0.5 * sin(_t * 2.4 - (b.grid.x + b.grid.y) * 0.6)
		b.idle_glow = v * v * v * (0.18 if Bubble.reduce_motion else 0.35)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch):
		return
	var touch := event as InputEventScreenTouch
	if touch.pressed:
		if not input_enabled:
			return
		last_press_usec = Time.get_ticks_usec()
		var local := (make_input_local(touch) as InputEventScreenTouch).position
		var hit := bubble_at(local)
		if hit == null:
			return
		_touches[touch.index] = hit
		hit.press_down()
		bubble_pressed.emit(hit)  # react on touch-down, never on release
		get_viewport().set_input_as_handled()
	else:
		var held: Bubble = _touches.get(touch.index)
		if held == null:
			return
		_touches.erase(touch.index)
		held.release()
		bubble_released.emit(held)

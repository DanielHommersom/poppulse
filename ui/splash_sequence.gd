class_name SplashSequence
extends CanvasLayer
## Launch splashes, on top of the already-built menu: first the studio
## (Digital Diamonds — same choreography as CombatTimer: blue glow, logo
## springs in, two shimmer pulses, fade out), then the game (Pop Pulse:
## five bubbles light up as a rising chord, the title pulses in).
## A tap skips the current splash. Reduce Motion keeps it to calm fades.

signal finished

const BG_SHADER := preload("res://shaders/background.gdshader")

var _root: Control
var _bg: ColorRect  # the game's own background shader = the iOS launch image
var _shade: ColorRect  # darkens it for the studio logo
var _skip := false
var _reduce := false


func _ready() -> void:
	layer = 90
	_reduce = Bubble.reduce_motion
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_input)
	add_child(_root)
	_bg = ColorRect.new()
	var mat := ShaderMaterial.new()
	mat.shader = BG_SHADER
	var th := ThemeManager.current
	mat.set_shader_parameter("top_color", th.bg_top)
	mat.set_shader_parameter("bottom_color", th.bg_bottom)
	mat.set_shader_parameter("accent", th.bg_accent)
	mat.set_shader_parameter("grid", th.bg_grid)
	mat.set_shader_parameter("vignette", th.bg_vignette)
	_bg.material = mat
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bg)
	_shade = ColorRect.new()
	_shade.color = Color(0.0, 0.0, 0.02, 0.0)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_shade)
	_fit()
	get_viewport().size_changed.connect(_fit)
	_run()


func _fit() -> void:
	var vs := get_viewport().get_visible_rect().size
	_root.position = Vector2.ZERO
	_root.size = vs
	_bg.size = vs
	_shade.size = vs


func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
		_skip = true


## Waits `secs`, returning early when the player tapped to skip.
func _hold(secs: float) -> void:
	var until := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < until and not _skip:
		await get_tree().process_frame


func _run() -> void:
	await _studio()
	_skip = false
	await _game()
	var t := create_tween()
	t.tween_property(_root, "modulate:a", 0.0, 0.35)
	await t.finished
	finished.emit()
	queue_free()


# --- 1. Digital Diamonds ---------------------------------------------------------

func _studio() -> void:
	var vs := _root.size
	var glow := _Glow.new()
	glow.color = Color("#3B82F6")
	glow.size = Vector2(vs.x, vs.x)
	glow.position = Vector2(0, (vs.y - vs.x) * 0.5)
	glow.modulate.a = 0.0
	_root.add_child(glow)
	var logo := DigitalDiamondsLogo.new()
	var w := minf(vs.x * 0.82, 620.0)
	logo.size = Vector2(w, w / DigitalDiamondsLogo.aspect())
	logo.position = (vs - logo.size) * 0.5
	logo.pivot_offset = logo.size * 0.5
	logo.modulate.a = 0.0
	logo.scale = Vector2.ONE * (1.0 if _reduce else 0.85)
	_root.add_child(logo)

	var t := create_tween().set_parallel(true)
	# Starts exactly on the launch-screen image, then dims for the logo.
	t.tween_property(_shade, "color:a", 0.82, 0.45)
	t.tween_property(glow, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)
	t.tween_property(logo, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)
	if not _reduce:
		t.tween_property(logo, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _hold(0.7)
	if not _skip:
		# Two shimmer pulses: opacity dip + a highlight sweeping over the facets.
		var p := create_tween()
		for i in 2:
			p.tween_property(logo, "modulate:a", 0.75, 0.38).set_trans(Tween.TRANS_SINE)
			p.tween_property(logo, "modulate:a", 1.0, 0.38).set_trans(Tween.TRANS_SINE)
		if not _reduce:
			var s := create_tween()
			s.tween_property(logo, "shine", 1.0, 1.2).from(0.0).set_trans(Tween.TRANS_SINE)
		await _hold(1.52 + 0.6)
	var out := create_tween().set_parallel(true)
	out.tween_property(logo, "modulate:a", 0.0, 0.25 if _skip else 0.48).set_ease(Tween.EASE_IN)
	out.tween_property(glow, "modulate:a", 0.0, 0.25 if _skip else 0.48).set_ease(Tween.EASE_IN)
	await out.finished
	logo.queue_free()
	glow.queue_free()


# --- 2. Pop Pulse ---------------------------------------------------------------

func _game() -> void:
	var vs := _root.size
	# Back from the studio's dark to the game's own neon background.
	var t0 := create_tween()
	t0.tween_property(_shade, "color:a", 0.0, 0.35)
	var row := Node2D.new()
	_root.add_child(row)
	var bubbles: Array[Bubble] = []
	var n := 5
	var r := minf(vs.x / (n * 2.7), 70.0)
	var y := vs.y * 0.44
	for i in n:
		var b := Bubble.new()
		var c := ThemeManager.current.bubble_color(i * 6, i, 5, 6)
		b.setup(i, Vector2i(i, 0), c)
		row.add_child(b)
		b.position = Vector2(vs.x * 0.5 + (i - (n - 1) * 0.5) * r * 2.6, y)
		b.set_radius(r)
		b.set_shape(ThemeManager.shape())
		bubbles.append(b)
	var title := UiStyle.label(AppInfo.TITLE, int(minf(vs.x * 0.15, 130.0)), Color.WHITE, true)
	title.size = Vector2(vs.x, 170)
	title.position = Vector2(0, y + r * 1.9)
	title.pivot_offset = title.size * 0.5
	title.modulate.a = 0.0
	_root.add_child(title)
	await _hold(0.25)
	# Bubbles light up left → right on a rising scale.
	for i in n:
		if _skip:
			break
		bubbles[i].light_up(false, false)
		Sfx.play_pop(i * 2)
		Platform.haptic(Platform.Haptic.LIGHT)
		await _hold(0.12)
	for b in bubbles:
		if b.vis_lit < 1.0:
			b.light_up(true, false)
	# Title arrives with a double "pulse" on beat with the bubbles.
	var ti := create_tween().set_parallel(true)
	ti.tween_property(title, "modulate:a", 1.0, 0.25)
	if not _reduce:
		title.scale = Vector2(1.35, 1.35)
		ti.tween_property(title, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not _skip:
		Sfx.play_go()
		for beat in 2:
			for b in bubbles:
				b.body_scale = 1.0 if _reduce else 1.12
				if not _reduce:
					b.create_tween().tween_property(b, "body_scale", 1.0, 0.28).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			await _hold(0.32)
		await _hold(0.55)
	for b in bubbles:
		b.pop()


## Soft radial glow behind the studio logo.
class _Glow extends Control:
	var color := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		for i in 24:
			var k := 1.0 - float(i) / 24.0
			draw_circle(c, r * k, Color(color, 0.022 * (1.0 - k) + 0.006), true, -1.0, false)

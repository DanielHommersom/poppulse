class_name Bubble
extends Node2D
## One poppable, glowing bubble. Owns only its own look and animation;
## gameplay rules live in GameMode subclasses.

enum State { IDLE, LIT, COOLDOWN }

const SHADER := preload("res://shaders/bubble.gdshader")
const BODY_RATIO := 0.6  # body radius relative to half the quad (rest = glow room)
const FAIL_COLOR := Color(1.0, 0.15, 0.2)
const DECOY_COLOR := Color(0.35, 0.35, 0.42)
## Accessibility (US-36), set by main from the settings.
static var reduce_motion := false
static var symbols := false

static var _quad: Texture2D

var index := 0
var grid := Vector2i.ZERO
var color := Color.WHITE
var radius := 50.0
var state := State.IDLE
## Set by the active mode (mode time, seconds).
var lit_at := 0.0
var life := 1.0
## Lit as a "don't tap" bubble (Stage decoys): grey with a cross.
var decoy := false

var vis_lit := 0.0:
	set(v):
		vis_lit = v
		_push_lit()
var idle_glow := 0.0:
	set(v):
		idle_glow = v
		_push_lit()
var vis_press := 0.0:
	set(v):
		vis_press = v
		if _mat:
			_mat.set_shader_parameter("press", v)
var vis_flash := 0.0:
	set(v):
		vis_flash = v
		if _mat:
			_mat.set_shader_parameter("flash", v)
var body_scale := 1.0:
	set(v):
		body_scale = v
		_apply_scale()

var _sprite: Sprite2D
var _mat: ShaderMaterial
var _ring: Node2D
var _time_frac := -1.0
var _tweens := {}


func setup(p_index: int, p_grid: Vector2i, p_color: Color) -> void:
	index = p_index
	grid = p_grid
	color = p_color


func _ready() -> void:
	if _quad == null:
		var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_quad = ImageTexture.create_from_image(img)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("base_color", color)
	_mat.set_shader_parameter("body_ratio", BODY_RATIO)
	_sprite = Sprite2D.new()
	_sprite.texture = _quad
	_sprite.material = _mat
	add_child(_sprite)
	_ring = Node2D.new()
	_ring.draw.connect(_draw_ring)
	add_child(_ring)
	_apply_scale()
	_push_lit()


## Theme switch: new base colour + shader look, keeping the current state.
func apply_theme(c: Color, params: Dictionary) -> void:
	color = c
	if _mat == null:
		return
	if not decoy:
		_mat.set_shader_parameter("base_color", c)
	for k in params:
		_mat.set_shader_parameter(k, params[k])
	if _ring:
		_ring.queue_redraw()


func set_shape(shape: int) -> void:
	if _mat:
		_mat.set_shader_parameter("shape", shape)


func set_radius(r: float) -> void:
	radius = r
	_apply_scale()
	if _ring:
		_ring.queue_redraw()


# --- Animation API -----------------------------------------------------------

## `instant` skips the fade-in so the very next frame shows it fully lit
## (Reflex Mode times reactions from that frame).
func light_up(instant := false, show_ring := true, as_decoy := false) -> void:
	state = State.LIT
	set_decoy(as_decoy)
	_time_frac = 1.0 if show_ring else -1.0
	_mat.set_shader_parameter("pulse", 1.0)
	if instant:
		_chan("lit").kill()
		vis_lit = 1.0
	else:
		_chan("lit").tween_property(self, "vis_lit", 1.0, 0.08) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	body_scale = 0.86
	_chan("scale").tween_property(self, "body_scale", 1.0, 0.35) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_ring.queue_redraw()


## Lights up and fades again on its own (pattern display / echo of a tap).
func blink(hold: float) -> void:
	_mat.set_shader_parameter("pulse", 0.0)
	var t := _chan("lit")
	t.tween_property(self, "vis_lit", 1.0, 0.05)
	t.tween_interval(maxf(hold - 0.05, 0.0))
	t.tween_property(self, "vis_lit", 0.0, 0.18)
	body_scale = 0.88
	_chan("scale").tween_property(self, "body_scale", 1.0, 0.35) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func pop() -> void:
	state = State.COOLDOWN
	_clear_ring()
	_mat.set_shader_parameter("pulse", 0.0)
	_mat.set_shader_parameter("flash_color", Color.WHITE)
	vis_flash = 0.45 if reduce_motion else 1.0
	_chan("flash").tween_property(self, "vis_flash", 0.0, 0.22)
	_chan("lit").tween_property(self, "vis_lit", 0.0, 0.2).set_ease(Tween.EASE_OUT)
	var t := _chan("scale")
	t.tween_property(self, "body_scale", 0.8, 0.05).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "body_scale", 1.0, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var c := _chan("cooldown")
	c.tween_interval(0.18)
	c.tween_callback(_end_cooldown)


func fail() -> void:
	_mat.set_shader_parameter("flash_color", FAIL_COLOR)
	vis_flash = 0.4 if reduce_motion else 0.9
	_chan("flash").tween_property(self, "vis_flash", 0.0, 0.4)
	body_scale = 0.9
	_chan("scale").tween_property(self, "body_scale", 1.0, 0.4) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func set_decoy(on: bool) -> void:
	decoy = on
	if _mat:
		_mat.set_shader_parameter("base_color", DECOY_COLOR if on else color)
	if _ring:
		_ring.queue_redraw()


func expire() -> void:
	state = State.IDLE
	if decoy:
		_fade_decoy()
	_clear_ring()
	_mat.set_shader_parameter("pulse", 0.0)
	_chan("lit").tween_property(self, "vis_lit", 0.0, 0.3)


func sweep_flash(delay: float) -> void:
	_mat.set_shader_parameter("flash_color", color.lightened(0.5))
	var t := _chan("flash")
	t.tween_interval(delay)
	t.tween_property(self, "vis_flash", 0.7, 0.06)
	t.tween_property(self, "vis_flash", 0.0, 0.3)


func press_down() -> void:
	_chan("press").tween_property(self, "vis_press", 1.0, 0.04)


func release() -> void:
	_chan("press").tween_property(self, "vis_press", 0.0, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func reset() -> void:
	for t in _tweens.values():
		if t != null and (t as Tween).is_valid():
			(t as Tween).kill()
	_tweens.clear()
	state = State.IDLE
	set_decoy(false)
	vis_lit = 0.0
	vis_flash = 0.0
	vis_press = 0.0
	body_scale = 1.0
	if _mat:
		_mat.set_shader_parameter("pulse", 0.0)
	_clear_ring()


## Remaining time as 0..1 for the countdown ring around a lit target.
func set_time_left(frac: float) -> void:
	_time_frac = clampf(frac, 0.0, 1.0)
	_ring.queue_redraw()


# --- Internals ---------------------------------------------------------------

func _fade_decoy() -> void:
	var t := _chan("decoy")
	t.tween_interval(0.3)
	t.tween_callback(set_decoy.bind(false))


func _end_cooldown() -> void:
	if state == State.COOLDOWN:
		state = State.IDLE


func _clear_ring() -> void:
	_time_frac = -1.0
	if _ring:
		_ring.queue_redraw()


func _draw_ring() -> void:
	if decoy and state == State.LIT:
		var k := radius * 0.42
		var w := maxf(radius * 0.14, 4.0)
		_ring.draw_line(Vector2(-k, -k), Vector2(k, k), Color(1, 0.35, 0.35, 0.9), w, true)
		_ring.draw_line(Vector2(k, -k), Vector2(-k, k), Color(1, 0.35, 0.35, 0.9), w, true)
		return
	if symbols and state == State.LIT and not decoy:
		# Colour-independent "this one" mark: a bright ring + centre dot.
		_ring.draw_arc(Vector2.ZERO, radius * 0.42, 0.0, TAU, 32, Color(1, 1, 1, 0.95), maxf(radius * 0.09, 3.0), true)
		_ring.draw_circle(Vector2.ZERO, radius * 0.13, Color(1, 1, 1, 0.95))
	if _time_frac < 0.0:
		return
	var r := radius * 1.16
	var w := maxf(radius * 0.07, 3.0)
	_ring.draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(color, 0.12), w, true)
	if _time_frac > 0.002:
		var c := color.lerp(Color(1.0, 0.25, 0.25), clampf(1.0 - _time_frac * 3.0, 0.0, 1.0))
		_ring.draw_arc(Vector2.ZERO, r, -PI / 2.0, -PI / 2.0 + TAU * _time_frac, 64, c, w, true)


func _apply_scale() -> void:
	if _sprite == null:
		return
	var quad_px := 2.0 * radius / BODY_RATIO
	_sprite.scale = Vector2.ONE * (quad_px / _quad.get_width()) * body_scale


func _push_lit() -> void:
	if _mat:
		_mat.set_shader_parameter("lit", maxf(vis_lit, idle_glow))


## One tween per animation channel; starting a new one kills the old one.
func _chan(channel: String) -> Tween:
	var old: Tween = _tweens.get(channel)
	if old != null and old.is_valid():
		old.kill()
	var t := create_tween()
	_tweens[channel] = t
	return t

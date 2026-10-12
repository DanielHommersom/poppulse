class_name Modal
extends Control
## Base for full-screen overlays (settings, stats, themes, premium…):
## dimmed backdrop, neon panel with title + close button, pop-in animation.
## Subclasses fill `body` in `_build()` and may override `_on_open()`.

signal closed

var title := ""
var body: VBoxContainer
var panel: PanelContainer
var scroll: ScrollContainer
var dismiss_on_backdrop := true
## false: no X button (screens that must be answered with their own buttons).
var closable := true
var _dim: ColorRect
var _title_label: Label
var _close: Button
var _width := 600.0
const GLOW_PAD := 26
var _pad: MarginContainer


func _init(p_title := "", p_width := 600.0) -> void:
	title = p_title
	_width = p_width


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.65)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.PANEL_BORDER, 40, 32))
	add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 16)
	panel.add_child(outer)
	var head := HBoxContainer.new()
	outer.add_child(head)
	_title_label = UiStyle.label(title, 44, Color.WHITE, true, HORIZONTAL_ALIGNMENT_LEFT)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title_label)
	_close = UiStyle.icon_button("close", Color(1, 1, 1, 0.8), 72)
	_close.pressed.connect(close)
	_close.visible = closable
	head.add_child(_close)

	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	# The scroll area clips its content; this padding keeps the glow/shadow of
	# filled buttons at the top or bottom of a panel from being cut off.
	_pad = MarginContainer.new()
	_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pad.add_theme_constant_override("margin_top", GLOW_PAD)
	_pad.add_theme_constant_override("margin_bottom", GLOW_PAD)
	scroll.add_child(_pad)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	_pad.add_child(body)
	_build()
	get_viewport().size_changed.connect(_fit)
	ThemeManager.theme_changed.connect(_on_theme)
	hide()


func _on_theme(_t: ThemeData) -> void:
	_switch_on = null  # switch track uses the theme colour
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.PANEL_BORDER, 40, 32))
	refresh()


func set_title(t: String) -> void:
	title = t
	if _title_label:
		_title_label.text = t


var _closing := false


func open() -> void:
	_closing = false
	_on_open()
	show()
	_fit()
	modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a", 1.0, 0.15)
	t.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Wrapped labels only know their height once laid out at the final width.
	await get_tree().process_frame
	if visible:
		_fit()


func close() -> void:
	if not visible or _closing:
		return
	_closing = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.12)
	t.tween_callback(func() -> void:
		hide()
		_closing = false)
	closed.emit()


## False as soon as closing starts (the fade-out is purely cosmetic).
func is_open() -> bool:
	return visible and not _closing


## Rebuilds content (e.g. after entitlements or theme changed).
func refresh() -> void:
	if visible:
		_on_open()
		await get_tree().process_frame
		_fit()


func _build() -> void:
	pass


func _on_open() -> void:
	pass


func _fit() -> void:
	var vs := get_viewport_rect().size
	position = Vector2.ZERO
	size = vs
	_dim.size = vs
	var safe := Platform.safe_margins(vs)
	var w := minf(_width, vs.x - 48.0)
	var max_h: float = vs.y - safe.top - safe.bottom - 80.0
	body.custom_minimum_size.x = w - 64.0
	scroll.custom_minimum_size.y = 0.0  # measure the content, not the last size
	panel.size = Vector2(w, 0)
	var chrome := panel.get_combined_minimum_size().y - scroll.get_combined_minimum_size().y
	var content_h := _pad.get_combined_minimum_size().y + chrome
	var h := minf(content_h, max_h)
	scroll.custom_minimum_size.y = h - chrome
	panel.size = Vector2(w, h)
	panel.position = Vector2((vs.x - w) * 0.5, safe.top + (vs.y - safe.top - safe.bottom - h) * 0.5)
	panel.pivot_offset = panel.size * 0.5


func _on_dim_input(e: InputEvent) -> void:
	if dismiss_on_backdrop and e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
		close()


# --- Row helpers for subclasses ---------------------------------------------

func add_section(text: String) -> Label:
	var l := UiStyle.label(text, 26, UiStyle.DIM_TEXT, false, HORIZONTAL_ALIGNMENT_LEFT)
	body.add_child(l)
	return l


func add_toggle(icon: String, text: String, on: bool, cb: Callable) -> CheckButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var ic := NeonIcon.new(icon, UiStyle.CYAN)
	ic.custom_minimum_size = Vector2(48, 48)
	row.add_child(ic)
	var l := UiStyle.label(text, 34, Color.WHITE, false, HORIZONTAL_ALIGNMENT_LEFT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var t := CheckButton.new()
	t.button_pressed = on
	t.focus_mode = Control.FOCUS_NONE
	t.add_theme_icon_override("checked", _switch_icon(true))
	t.add_theme_icon_override("unchecked", _switch_icon(false))
	t.toggled.connect(cb)
	row.add_child(t)
	body.add_child(row)
	return t


func add_choice(text: String, options: Array, selected: int, cb: Callable) -> OptionButton:
	var row := HBoxContainer.new()
	var l := UiStyle.label(text, 34, Color.WHITE, false, HORIZONTAL_ALIGNMENT_LEFT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var o := OptionButton.new()
	o.add_theme_font_override("font", UiStyle.font())
	o.add_theme_font_size_override("font_size", 30)
	o.get_popup().add_theme_font_override("font", UiStyle.font())
	o.get_popup().add_theme_font_size_override("font_size", 32)
	for opt in options:
		o.add_item(str(opt))
	o.selected = selected
	o.focus_mode = Control.FOCUS_NONE
	o.item_selected.connect(cb)
	row.add_child(o)
	body.add_child(row)
	return o


func add_button(text: String, color: Color, cb: Callable, filled := false) -> Button:
	var b := UiStyle.button(text, color, 36) if filled else UiStyle.ghost_button(text, color, 32)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if filled else Control.SIZE_FILL
	b.pressed.connect(cb)
	body.add_child(b)
	return b


func clear_body() -> void:
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()


static var _switch_on: Texture2D
static var _switch_off: Texture2D


static func _switch_icon(on: bool) -> Texture2D:
	if on and _switch_on:
		return _switch_on
	if not on and _switch_off:
		return _switch_off
	var w := 96
	var h := 54
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var track := UiStyle.CYAN if on else Color(1, 1, 1, 0.22)
	var knob_x := w - h * 0.5 if on else h * 0.5
	for y in h:
		for x in w:
			var c := Color(0, 0, 0, 0)
			# rounded track
			var cx := clampf(x, h * 0.5, w - h * 0.5)
			var d := Vector2(x, y).distance_to(Vector2(cx, h * 0.5))
			if d < h * 0.5:
				c = track
				c.a *= clampf(h * 0.5 - d, 0.0, 1.0)
			var dk := Vector2(x, y).distance_to(Vector2(knob_x, h * 0.5))
			if dk < h * 0.5 - 5:
				var k := Color.WHITE
				k.a = clampf(h * 0.5 - 5 - dk, 0.0, 1.0)
				c = c.blend(k)
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	if on:
		_switch_on = tex
	else:
		_switch_off = tex
	return tex

class_name ResultsPanel
extends Control
## Generic end-of-run card. Modes describe *what* to show via the results
## dictionary; main.gd turns that into a spec for present():
##   title, value_text, value_color, badge (e.g. "NEW BEST!"), stats [[caption, value]],
##   extras [Control] (graph, stars…), primary [text, Callable],
##   actions [[icon, Callable]] (round icon buttons, e.g. share),
##   links [[text, color, Callable]] (ghost buttons: continue, next level…)

signal dismissed

var _dim: ColorRect
var _panel: PanelContainer
var _box: VBoxContainer
var _title: Label
var _value: Label
var _badge: Label
var _stats: HBoxContainer
var _extras: VBoxContainer
var _links: VBoxContainer
var _actions: HBoxContainer
var _primary: Button
var _primary_cb: Callable
var _hint: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.6)
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiStyle.panel_style())
	add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 12)
	_panel.add_child(_box)
	_title = UiStyle.label("", 34, UiStyle.DIM_TEXT)
	_box.add_child(_title)
	_value = UiStyle.label("0", 120, Color.WHITE, true)
	_box.add_child(_value)
	_badge = UiStyle.label("NEW BEST!", 36, UiStyle.GOLD, true)
	_box.add_child(_badge)
	_stats = HBoxContainer.new()
	_stats.add_theme_constant_override("separation", 16)
	_box.add_child(_stats)
	_extras = VBoxContainer.new()
	_extras.add_theme_constant_override("separation", 10)
	_box.add_child(_extras)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	_box.add_child(spacer)
	_primary = UiStyle.button("PLAY AGAIN", UiStyle.ACCENT)
	_primary.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_primary.pressed.connect(func() -> void: _primary_cb.call())
	_box.add_child(_primary)
	_links = VBoxContainer.new()
	_links.add_theme_constant_override("separation", 10)
	_box.add_child(_links)
	_actions = HBoxContainer.new()
	_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_actions.add_theme_constant_override("separation", 22)
	_box.add_child(_actions)
	_hint = UiStyle.label("tap outside to close", 22, Color(1, 1, 1, 0.4))
	_box.add_child(_hint)
	hide()


func restyle() -> void:
	_panel.add_theme_stylebox_override("panel", UiStyle.panel_style())
	UiStyle.restyle_button(_primary, UiStyle.ACCENT)
	UiStyle.set_label_color(_badge, UiStyle.GOLD)


func present(spec: Dictionary) -> void:
	_title.text = str(spec.get("title", ""))
	_value.text = str(spec.get("value_text", ""))
	_value.visible = _value.text != ""
	UiStyle.set_label_color(_value, spec.get("value_color", Color.WHITE))
	_badge.text = str(spec.get("badge", ""))
	_badge.visible = _badge.text != ""
	_clear(_stats)
	for s: Array in spec.get("stats", []):
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var txt := str(s[1])
		col.add_child(UiStyle.label(txt, 44 if txt.length() <= 5 else 34, UiStyle.CYAN, true))
		col.add_child(UiStyle.label(str(s[0]), 20, Color(1, 1, 1, 0.5)))
		_stats.add_child(col)
	_stats.visible = _stats.get_child_count() > 0
	_clear(_extras)
	for c: Control in spec.get("extras", []):
		_extras.add_child(c)
	_extras.visible = _extras.get_child_count() > 0
	var primary: Array = spec.get("primary", [])
	_primary.visible = not primary.is_empty()
	if _primary.visible:
		_primary.text = primary[0]
		_primary_cb = primary[1]
	_clear(_links)
	for l: Array in spec.get("links", []):
		var b := UiStyle.ghost_button(l[0], l[1], 30)
		b.pressed.connect(l[2])
		_links.add_child(b)
	_links.visible = _links.get_child_count() > 0
	_clear(_actions)
	for a: Array in spec.get("actions", []):
		var b := UiStyle.icon_button(a[0], Color(1, 1, 1, 0.85), 80)
		b.pressed.connect(a[1])
		_actions.add_child(b)
	_actions.visible = _actions.get_child_count() > 0

	show()
	_fit()
	_dim.modulate.a = 0.0
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.85, 0.85)
	var t := create_tween().set_parallel(true)
	t.tween_property(_dim, "modulate:a", 1.0, 0.2)
	t.tween_property(_panel, "modulate:a", 1.0, 0.2)
	t.tween_property(_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	hide()


## Swap the value text after presenting (e.g. a rewarded continue result).
func set_badge(text: String) -> void:
	_badge.text = text
	_badge.visible = text != ""


func _fit() -> void:
	var vs := get_viewport_rect().size
	position = Vector2.ZERO
	size = vs
	_dim.size = vs
	var w := minf(600.0, vs.x - 40.0)
	_panel.size = Vector2(w, 0)
	var h := _panel.get_combined_minimum_size().y
	_panel.size = Vector2(w, h)
	_panel.position = (vs - _panel.size) * 0.5
	_panel.pivot_offset = _panel.size * 0.5


func _clear(c: Node) -> void:
	for ch in c.get_children():
		c.remove_child(ch)
		ch.queue_free()


func _on_dim_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
		dismissed.emit()

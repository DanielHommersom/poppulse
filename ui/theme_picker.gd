class_name ThemePicker
extends Control
## "Style" bottom sheet with tabs: THEMES · BUBBLES · SOUNDS.
## Tapping an item previews it live on the fidget board (which stays visible
## and poppable above the sheet); "USE" saves it. Locked items can be
## previewed but not chosen; the buy button emits `locked_tapped` so the
## Premium offer can hook in (US-29).

## kind: "theme" | "design" | "sound"; unlock: premium | achievement
signal locked_tapped(kind: String, id: String, unlock: String, unlock_ref: String)
signal closed
## Rewarded 24 h trial of a premium theme (US-32); main shows the ad.
signal trial_requested(theme_id: String)

const TABS := ["theme", "design", "sound"]
const TAB_NAMES := {"theme": "THEMES", "design": "BUBBLES", "sound": "SOUNDS"}

var tab := "theme"
var _sheet: PanelContainer
var _tabs: HBoxContainer
var _row: HBoxContainer
var _scroll: ScrollContainer
var _status: Label
var _use: Button
var _trial: Button
var _selected := {}  # current item dict
var _chips := {}  # id -> Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet = PanelContainer.new()
	add_child(_sheet)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	_sheet.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 10)
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_tabs)
	for t in TABS:
		var b := UiStyle.ghost_button(TAB_NAMES[t], Color.WHITE, 21)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_set_tab.bind(t))
		b.name = t
		_tabs.add_child(b)
	var x := UiStyle.icon_button("close", Color(1, 1, 1, 0.8), 68)
	x.pressed.connect(close)
	head.add_child(x)
	_scroll = ScrollContainer.new()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(0, 176)
	v.add_child(_scroll)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 14)
	_scroll.add_child(_row)
	_status = UiStyle.label("", 26, UiStyle.DIM_TEXT)
	v.add_child(_status)
	_use = UiStyle.button("USE", UiStyle.ACCENT, 36)
	_use.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_use.pressed.connect(_on_use)
	v.add_child(_use)
	_trial = UiStyle.ghost_button("▶ TRY FOR 24 HOURS", UiStyle.OK, 24)
	_trial.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_trial.pressed.connect(_on_trial)
	_trial.hide()
	v.add_child(_trial)
	ThemeManager.theme_changed.connect(func(_t: ThemeData) -> void: _restyle())
	Platform.entitlements_changed.connect(refresh)
	get_viewport().size_changed.connect(_fit)
	hide()


func open(p_tab := "theme", select_id := "") -> void:
	show()
	_set_tab(p_tab)
	if select_id != "":
		for it in _items():
			if it.id == select_id:
				_select(it, false)
	_fit()
	_sheet.position.y = get_viewport_rect().size.y  # slides up in _process


func close() -> void:
	if not visible:
		return
	ThemeManager.revert_preview()
	ThemeManager.revert_design_preview()
	hide()
	closed.emit()


func is_open() -> bool:
	return visible


## Re-reads availability (e.g. right after a purchase) without closing.
func refresh() -> void:
	if visible:
		var keep: String = _selected.get("id", "")
		_build_chips()
		for it in _items():
			if it.id == keep:
				_select(it, false)


func _set_tab(t: String) -> void:
	# Leaving a tab drops its unsaved preview.
	ThemeManager.revert_preview()
	ThemeManager.revert_design_preview()
	tab = t
	for b: Button in _tabs.get_children():
		b.modulate.a = 1.0 if b.name == t else 0.45
	_build_chips()
	var cur := _current_id()
	for it in _items():
		if it.id == cur:
			_select(it, false)


# --- Item model per tab ------------------------------------------------------------

func _items() -> Array:
	var out := []
	match tab:
		"theme":
			for t in ThemeManager.themes:
				out.append({"id": t.id, "name": t.display_name, "unlock": t.unlock, "ref": t.unlock_ref,
					"available": ThemeManager.is_available(t), "status": ThemeManager.status_text(t), "color": t.ui_accent})
		"design":
			for d: Dictionary in ThemeManager.designs:
				out.append(_gated(d, UiStyle.CYAN))
		"sound":
			for p: Dictionary in Sfx.packs():
				out.append(_gated(p, UiStyle.GOLD))
	return out


func _gated(d: Dictionary, color: Color) -> Dictionary:
	var u := str(d.get("unlock", "free"))
	var r := str(d.get("unlock_ref", ""))
	var ok := ThemeManager.is_unlock_met(u, r)
	return {"id": d.id, "name": d.name, "unlock": u, "ref": r, "shape": int(d.get("shape", 0)),
		"available": ok, "status": "" if ok else ThemeManager.unlock_text(u, r), "color": color}


func _current_id() -> String:
	match tab:
		"design":
			return str(SaveData.get_setting("design"))
		"sound":
			return Sfx.pack_id
	return str(SaveData.get_setting("theme"))


func _preview(it: Dictionary) -> void:
	match tab:
		"theme":
			if it.id != ThemeManager.current.id:
				ThemeManager.apply(it.id, false)
		"design":
			if it.id != ThemeManager.design.get("id", ""):
				ThemeManager.apply_design(it.id, false)
		"sound":
			Sfx.preview_pack(it.id)


func _commit(it: Dictionary) -> void:
	match tab:
		"theme":
			ThemeManager.apply(it.id, true)
		"design":
			ThemeManager.apply_design(it.id, true)
		"sound":
			Sfx.set_pack(it.id, true)


# --- UI ------------------------------------------------------------------------------

func _build_chips() -> void:
	for c in _row.get_children():
		_row.remove_child(c)
		c.queue_free()
	_chips.clear()
	var cur := _current_id()
	for it in _items():
		var b := UiStyle.card_button(it.color, false)
		b.custom_minimum_size = Vector2(150, 168)
		b.pressed.connect(_select.bind(it))
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		v.add_child(_preview_widget(it))
		v.add_child(UiStyle.label(str(it.name), 24, Color.WHITE))
		var status: String = it.status
		var tag := UiStyle.label(status if status != "" else ("✓" if it.id == cur else ""), 18, UiStyle.GOLD if status in ["PREMIUM", "PACK"] else Color(1, 1, 1, 0.5))
		tag.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tag.custom_minimum_size.x = 130
		v.add_child(tag)
		_row.add_child(b)
		_chips[it.id] = b


func _preview_widget(it: Dictionary) -> Control:
	match tab:
		"theme":
			return Swatch.new(ThemeManager.get_theme(it.id))
		"design":
			return ShapeChip.new(int(it.shape))
	var ic := NeonIcon.new("sound", UiStyle.GOLD)
	ic.custom_minimum_size = Vector2(0, 64)
	return ic


func _select(it: Dictionary, sound := true) -> void:
	_selected = it
	for id in _chips:
		UiStyle.set_card_selected(_chips[id], it.color if id == it.id else Color(1, 1, 1, 0.5), id == it.id)
	_preview(it)
	if _chips.has(it.id):
		_scroll_to.call_deferred(_chips[it.id])
	var ok: bool = it.available
	var status: String = it.status
	if ok:
		_status.text = "In use" if it.id == _current_id() else ("Preview — pop the board!" if tab != "sound" else "Tap the board to hear it")
	else:
		_status.text = status if status.begins_with("Unlock") else "%s — preview" % status
	_use.text = "USE" if ok else ("GET PREMIUM" if it.unlock == "premium" else "LOCKED")
	_use.disabled = not ok and it.unlock == "achievement"
	# Rewarded "theme_trial" (US-32): only for locked premium themes, only when an ad is there.
	_trial.visible = tab == "theme" and not ok and it.unlock == "premium" and Platform.can_show_rewarded("theme_trial")
	_refit()
	if sound and tab != "sound":
		Sfx.play_tick()


func _refit() -> void:
	await get_tree().process_frame
	if visible:
		_fit()


func _on_trial() -> void:
	if not _selected.is_empty():
		trial_requested.emit(str(_selected.id))




func _scroll_to(c: Variant) -> void:
	if is_instance_valid(c) and _scroll.is_ancestor_of(c):
		_scroll.ensure_control_visible(c)


func _on_use() -> void:
	if _selected.is_empty():
		return
	if _selected.available:
		_commit(_selected)
		Platform.haptic(Platform.Haptic.MEDIUM)
		close()
	else:
		locked_tapped.emit(tab, str(_selected.id), str(_selected.unlock), str(_selected.ref))


func _restyle() -> void:
	_sheet.add_theme_stylebox_override("panel", UiStyle.panel_style(UiStyle.PANEL_BORDER, 40, 28))
	UiStyle.restyle_button(_use, UiStyle.ACCENT, 36)


func _fit() -> void:
	var vs := get_viewport_rect().size
	var safe := Platform.safe_margins(vs)
	position = Vector2.ZERO
	size = vs
	_restyle()
	var w := minf(760.0, vs.x)
	var sb := _sheet.get_theme_stylebox("panel") as StyleBoxFlat
	sb.content_margin_bottom = 28.0 + safe.bottom
	_sheet.size = Vector2(w, 0)  # shrink to content; the container grows as needed
	_sheet.position.x = (vs.x - w) * 0.5


## Keeps the sheet glued to the bottom edge whatever its (changing) height,
## sliding in from below when opened.
func _process(delta: float) -> void:
	if not visible:
		return
	var target := get_viewport_rect().size.y - _sheet.size.y + 20.0
	_sheet.position.y = lerpf(_sheet.position.y, target, 1.0 - exp(-delta * 14.0))


## Five dots in the theme's bubble colours on its background colour.
class Swatch extends Control:
	var data: ThemeData

	func _init(t: ThemeData) -> void:
		data = t
		custom_minimum_size = Vector2(120, 64)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2((size.x - 120) * 0.5, 4), Vector2(120, 56))
		draw_rect(r, data.bg_top)
		for i in 5:
			var c := data.bubble_color(i * 6, i, 5, 6)
			var p := r.position + Vector2(14 + i * 23, 28)
			draw_circle(p, 13, c.darkened(0.1))
			draw_circle(p + Vector2(-4, -4), 4, Color(1, 1, 1, 0.5))


## A real (shader) bubble in the chip, so designs preview exactly.
class ShapeChip extends Control:
	var _b: Bubble
	var _shape := 0

	func _init(shape: int) -> void:
		_shape = shape
		custom_minimum_size = Vector2(0, 70)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		_b = Bubble.new()
		_b.setup(0, Vector2i.ZERO, UiStyle.ACCENT)
		add_child(_b)
		_b.set_radius(27)
		_b.set_shape(_shape)
		_b.vis_lit = 0.85
		resized.connect(func() -> void: _b.position = size * 0.5)
		_b.position = size * 0.5

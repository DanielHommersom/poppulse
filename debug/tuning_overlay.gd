extends CanvasLayer
## DEBUG ONLY — live tuning of the active mode's JSON config during playtests.
## Loaded by main.gd only when OS.is_debug_build(); the whole debug/ folder is
## excluded from the release export preset, so it never ships.
## Toggle: three-finger tap, or F2 / ` on a keyboard.

## [path in cfg, min, max, step]. Paths that a mode's config lacks are skipped,
## so the same list works for every mode.
const SPEC := [
	["duration", 10.0, 120.0, 1.0],
	["ramp_time", 5.0, 120.0, 1.0],
	["difficulty/params/spawn_interval/0", 0.1, 2.0, 0.01],
	["difficulty/params/spawn_interval/1", 0.1, 2.0, 0.01],
	["difficulty/params/lifetime/0", 0.2, 4.0, 0.05],
	["difficulty/params/lifetime/1", 0.2, 4.0, 0.05],
	["difficulty/params/max_active/0", 1.0, 8.0, 1.0],
	["difficulty/params/max_active/1", 1.0, 8.0, 1.0],
	["difficulty/x_end", 5.0, 120.0, 1.0],
	["start/spawn_interval", 0.1, 2.0, 0.01],
	["end/spawn_interval", 0.1, 2.0, 0.01],
	["start/lifetime", 0.2, 4.0, 0.05],
	["end/lifetime", 0.2, 4.0, 0.05],
	["start/max_active", 1.0, 8.0, 1.0],
	["end/max_active", 1.0, 8.0, 1.0],
	["points/base", 0.0, 500.0, 10.0],
	["points/speed_bonus", 0.0, 500.0, 10.0],
	["points/speed_window", 0.2, 2.0, 0.05],
	["points/combo_step", 1.0, 20.0, 1.0],
	["points/max_multiplier", 1.0, 16.0, 1.0],
	["points/wrong_penalty", 0.0, 300.0, 10.0],
	["wait_min", 0.2, 5.0, 0.1],
	["wait_max", 0.2, 6.0, 0.1],
	["stimuli", 3.0, 30.0, 1.0],
	["goal", 5.0, 80.0, 1.0],
	["time_limit", 0.0, 120.0, 1.0],
	["max_mistakes", 0.0, 10.0, 1.0],
	["decoy_chance", 0.0, 0.6, 0.01],
	["difficulty/params/simultaneous_targets", 1.0, 4.0, 1.0],
	["difficulty/params/show_time/0", 0.1, 1.5, 0.01],
	["difficulty/params/show_time/1", 0.1, 1.5, 0.01],
]

var main: Node
var _panel: PanelContainer
var _list: VBoxContainer
var _fps: Label
var _touches := {}
var _bound_mode: Object


func _ready() -> void:
	layer = 50
	_fps = UiStyle.label("", 22, Color(0.5, 1, 0.6), false, HORIZONTAL_ALIGNMENT_LEFT)
	_fps.position = Vector2(8, 4)
	_fps.hide()
	add_child(_fps)
	_panel = PanelContainer.new()
	var sb := UiStyle.panel_style(Color(0.4, 1, 0.6, 0.6), 18, 16)
	sb.bg_color = Color(0.03, 0.03, 0.06, 0.88)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	var v := VBoxContainer.new()
	_panel.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var t := UiStyle.label("TUNING (debug)", 28, Color(0.5, 1, 0.6), false, HORIZONTAL_ALIGNMENT_LEFT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var exp_btn := UiStyle.ghost_button("EXPORT JSON", Color(0.5, 1, 0.6), 22)
	exp_btn.pressed.connect(_export)
	head.add_child(exp_btn)
	var close := UiStyle.ghost_button("X", Color.WHITE, 22)
	close.pressed.connect(toggle)
	head.add_child(close)
	_mock_row(v)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_panel.hide()


func _process(_delta: float) -> void:
	_fps.text = "%d fps" % Engine.get_frames_per_second()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).keycode
		if k == KEY_F2 or k == KEY_QUOTELEFT:
			toggle()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = true
			if _touches.size() == 3:
				toggle()
		else:
			_touches.erase(st.index)


func toggle() -> void:
	_panel.visible = not _panel.visible
	_fps.visible = _panel.visible
	if _panel.visible:
		_rebuild()


func _rebuild() -> void:
	var vs := get_viewport().get_visible_rect().size
	_panel.position = Vector2(8, 30)
	_panel.size = Vector2(vs.x - 16, vs.y * 0.48)
	for c in _list.get_children():
		c.queue_free()
	var mode: Object = main.mode
	_bound_mode = mode
	var cfg: Dictionary = _tunable(mode)
	_list.add_child(UiStyle.label("mode: %s" % mode.get("mode_id"), 20, Color(1, 1, 1, 0.6), false, HORIZONTAL_ALIGNMENT_LEFT))
	for s in SPEC:
		var got: Array = _get_path(cfg, s[0])
		if got.is_empty():
			continue
		_add_slider(cfg, s[0], float(got[0]), s[1], s[2], s[3])


func _add_slider(cfg: Dictionary, path: String, value: float, lo: float, hi: float, step: float) -> void:
	var row := HBoxContainer.new()
	var name_l := UiStyle.label(path.replace("difficulty/params/", "").replace("/0", " start").replace("/1", " end"), 20, Color.WHITE, false, HORIZONTAL_ALIGNMENT_LEFT)
	name_l.custom_minimum_size.x = 250
	row.add_child(name_l)
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = step
	sl.value = value
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size.y = 44
	row.add_child(sl)
	var val := UiStyle.label(_fmt(value, step), 20, Color(0.5, 1, 0.6), false, HORIZONTAL_ALIGNMENT_RIGHT)
	val.custom_minimum_size.x = 70
	row.add_child(val)
	sl.value_changed.connect(func(x: float) -> void:
		_set_path(cfg, path, x if step < 1.0 else float(int(x)))
		val.text = _fmt(x, step)
		if _bound_mode and _bound_mode.has_method("on_tuning_changed"):
			_bound_mode.on_tuning_changed())
	_list.add_child(row)


## Stage Mode tunes the current level; every other mode its JSON config.
static func _tunable(mode: Object) -> Dictionary:
	var level: Variant = mode.get("level")
	if level is Dictionary and not (level as Dictionary).is_empty():
		return level
	return mode.get("cfg") if mode.get("cfg") is Dictionary else {}


func _export() -> void:
	var cfg: Variant = _tunable(main.mode)
	var text := JSON.stringify(cfg, "  ", false)
	DisplayServer.clipboard_set(text)
	print("--- tuning export (%s) ---\n%s" % [main.mode.mode_id, text])


static func _fmt(x: float, step: float) -> String:
	return str(int(x)) if step >= 1.0 else "%.2f" % x


## Returns [value] or [] when the path does not exist. Path parts index
## dictionaries by key and arrays by integer.
static func _get_path(root: Variant, path: String) -> Array:
	var cur: Variant = root
	for part in path.split("/"):
		if cur is Dictionary and (cur as Dictionary).has(part):
			cur = cur[part]
		elif cur is Array and part.is_valid_int() and int(part) < (cur as Array).size():
			cur = cur[int(part)]
		else:
			return []
	if cur is float or cur is int:
		return [cur]
	return []


static func _set_path(root: Variant, path: String, value: float) -> void:
	var parts := path.split("/")
	var cur: Variant = root
	for i in parts.size() - 1:
		cur = cur[int(parts[i])] if cur is Array else cur[parts[i]]
	var last := parts[parts.size() - 1]
	if cur is Array:
		cur[int(last)] = value
	else:
		cur[last] = value


## Monetization mock toggles (US-27): store outcome, ad fill, skip.
func _mock_row(parent: Control) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	parent.add_child(h)
	var store := Platform.store as MockStore
	var ads := Platform.ads as MockAds
	if store == null or ads == null:
		return
	var outcomes := ["success", "fail", "cancel", "pending"]
	var ob := UiStyle.ghost_button("BUY: " + store.outcome, Color(0.5, 1, 0.6), 18)
	ob.pressed.connect(func() -> void:
		store.outcome = outcomes[(outcomes.find(store.outcome) + 1) % outcomes.size()]
		ob.text = "BUY: " + store.outcome)
	h.add_child(ob)
	var ra := UiStyle.ghost_button("AD FILL: %s" % ads.rewarded_available, Color(0.5, 1, 0.6), 18)
	ra.pressed.connect(func() -> void:
		ads.rewarded_available = not ads.rewarded_available
		ads.interstitial_available = ads.rewarded_available
		ra.text = "AD FILL: %s" % ads.rewarded_available)
	h.add_child(ra)
	var sk := UiStyle.ghost_button("SKIP AD: %s" % ads.skip_rewarded, Color(0.5, 1, 0.6), 18)
	sk.pressed.connect(func() -> void:
		ads.skip_rewarded = not ads.skip_rewarded
		sk.text = "SKIP AD: %s" % ads.skip_rewarded)
	h.add_child(sk)
	var rs := UiStyle.ghost_button("RESET IAP", Color(1, 0.5, 0.5), 18)
	rs.pressed.connect(func() -> void:
		SaveData.section("unlocks").entitlements = {}
		SaveData.mark_dirty()
		Platform.entitlements_changed.emit())
	h.add_child(rs)

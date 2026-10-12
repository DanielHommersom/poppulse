class_name StageSelect
extends Modal
## Scrollable level grid with stars and locks. The current level is
## highlighted and scrolled into view. A press only starts a level when the
## list did not scroll in between, so flicking through never launches one.

signal level_chosen(level_id: int)
## A locked cell was tapped (premium gating hooks in here, US-29).
signal locked_tapped(level_id: int, reason: String)

const COLS := 5

var _grid: GridContainer
var _cells := {}  # id -> Button
var _press_scroll := 0
var _summary: Label


func _init() -> void:
	super("STAGES", 660.0)


func _ready() -> void:
	super._ready()
	Platform.entitlements_changed.connect(refresh)


func _build() -> void:
	_summary = UiStyle.label("", 28, UiStyle.GOLD, true)
	body.add_child(_summary)
	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_grid)
	scroll.scroll_deadzone = 12


func _on_open() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	_cells.clear()
	var current := StageLevels.current_level()
	var n := StageLevels.count()
	_summary.text = "%d / %d ★" % [SaveData.total_stars(), n * 3]
	for i in range(1, n + 1):
		var cell := _make_cell(i, i == current)
		_grid.add_child(cell)
		_cells[i] = cell
	_scroll_to.call_deferred(current)


func _make_cell(id: int, is_current: bool) -> Button:
	var lock := lock_reason(id)
	var stars := SaveData.get_stars(id)
	var col := UiStyle.GOLD if is_current else (UiStyle.CYAN if lock == "" else Color(1, 1, 1, 0.5))
	var b := UiStyle.card_button(col, is_current)
	b.custom_minimum_size = Vector2(104, 112)
	b.button_down.connect(func() -> void: _press_scroll = scroll.scroll_vertical)
	b.pressed.connect(_on_cell.bind(id))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	b.add_child(v)
	if lock == "":
		v.add_child(UiStyle.label(str(id), 40, Color.WHITE, is_current))
		v.add_child(StarsRow.new(stars, 22, false))
	else:
		var ic := NeonIcon.new("crown" if lock == "premium" else "lock", UiStyle.GOLD if lock == "premium" else Color(1, 1, 1, 0.45))
		ic.custom_minimum_size = Vector2(0, 40)
		v.add_child(ic)
		v.add_child(UiStyle.label(str(id), 24, Color(1, 1, 1, 0.45)))
	return b


## "" = playable, "progress" = clear the previous level first, "premium" = gated (US-29).
func lock_reason(id: int) -> String:
	if Premium.stage_level_locked(id):
		return "premium"
	if not StageLevels.is_unlocked(id):
		return "progress"
	return ""


func _scroll_to(id: int) -> void:
	var cell: Control = _cells.get(id)
	if cell == null:
		return
	await get_tree().process_frame
	scroll.ensure_control_visible(cell)


func _on_cell(id: int) -> void:
	if absi(scroll.scroll_vertical - _press_scroll) > 8:
		return  # it was a scroll, not a tap
	var lock := lock_reason(id)
	if lock != "":
		var cell: Control = _cells[id]
		cell.pivot_offset = cell.size * 0.5
		var t := cell.create_tween()
		t.tween_property(cell, "rotation", 0.08, 0.05)
		t.tween_property(cell, "rotation", -0.08, 0.08)
		t.tween_property(cell, "rotation", 0.0, 0.05)
		Sfx.play_miss()
		Platform.haptic(Platform.Haptic.ERROR)
		locked_tapped.emit(id, lock)
		return
	close()
	level_chosen.emit(id)

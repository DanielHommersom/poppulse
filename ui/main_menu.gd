class_name MainMenu
extends Control
## Idle-screen mode picker: one card per available mode with the personal
## record. The selected card is the one PLAY starts (so: app start → PLAY = 1 tap,
## other mode → card + PLAY = 2 taps). The fidget board stays live behind it.

signal mode_selected(mode_id: String)

const CARD_H := 150.0

var selected := ""
var _row: HBoxContainer
var _cards := {}  # id -> Button
var _records := {}  # id -> Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 14)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)


func build(ids: Array[String], p_selected: String) -> void:
	for c in _row.get_children():
		_row.remove_child(c)
		c.queue_free()
	_cards.clear()
	_records.clear()
	for id in ids:
		var info := ModeRegistry.info(id)
		var col: Color = info.get("color", UiStyle.ACCENT)
		var b := UiStyle.card_button(col, false)
		b.pressed.connect(_on_card.bind(id))
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 2)
		b.add_child(v)
		var ic := NeonIcon.new(info.get("icon", "bubble"), col)
		ic.custom_minimum_size = Vector2(0, 44)
		v.add_child(ic)
		# Five cards make each card narrower: smaller type, long names wrap.
		var name_l := UiStyle.label(info.get("name", id), 26 if ids.size() <= 4 else 21, Color.WHITE, false)
		name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(name_l)
		var rec := UiStyle.label(str(info.get("record_text", "-")), 22 if ids.size() <= 4 else 19, UiStyle.GOLD, false)
		v.add_child(rec)
		_row.add_child(b)
		_cards[id] = b
		_records[id] = rec
	select(p_selected)


func select(id: String) -> void:
	selected = id
	for k in _cards:
		var col: Color = ModeRegistry.info(k).get("color", UiStyle.ACCENT)
		UiStyle.set_card_selected(_cards[k], col, k == id)


func set_record(id: String, text: String) -> void:
	if _records.has(id):
		(_records[id] as Label).text = text


func layout_in(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	var n := maxi(_cards.size(), 1)
	var gap := 14.0 if n <= 4 else 10.0
	_row.add_theme_constant_override("separation", int(gap))
	var w := minf(190.0, (rect.size.x - gap * (n - 1)) / n)
	for b: Button in _cards.values():
		b.custom_minimum_size = Vector2(w, CARD_H)
	_row.position = Vector2.ZERO
	_row.size = Vector2(rect.size.x, CARD_H)


func _on_card(id: String) -> void:
	if id != selected:
		select(id)
		mode_selected.emit(id)
	Sfx.play_tick()
	Platform.haptic(Platform.Haptic.LIGHT)

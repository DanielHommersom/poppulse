class_name Toast
extends CanvasLayer
## Neon pill that slides in from the top (achievement unlocks, notices).
## Several toasts queue up and play one after another.

var _queue: Array[Dictionary] = []
var _busy := false


func _ready() -> void:
	layer = 40


## kind: "achievement" (gold, "ACHIEVEMENT UNLOCKED") or "info".
func push(title: String, subtitle: String, icon := "trophy", kind := "achievement") -> void:
	_queue.append({"title": title, "sub": subtitle, "icon": icon, "kind": kind})
	if not _busy:
		_next()


func _next() -> void:
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	var t: Dictionary = _queue.pop_front()
	var vs := get_viewport().get_visible_rect().size
	var safe := Platform.safe_margins(vs)
	var col := UiStyle.GOLD if t.kind == "achievement" else UiStyle.CYAN
	var pill := PanelContainer.new()
	var sb := UiStyle.panel_style(col, 44, 18)
	sb.content_margin_left = 26
	sb.content_margin_right = 30
	pill.add_theme_stylebox_override("panel", sb)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pill)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	pill.add_child(h)
	var ic := NeonIcon.new(t.icon, col)
	ic.custom_minimum_size = Vector2(58, 58)
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -4)
	h.add_child(v)
	v.add_child(UiStyle.label("ACHIEVEMENT UNLOCKED" if t.kind == "achievement" else str(t.title), 20, Color(col, 0.85), false, HORIZONTAL_ALIGNMENT_LEFT))
	v.add_child(UiStyle.label(str(t.title) if t.kind == "achievement" else str(t.sub), 32, Color.WHITE, true, HORIZONTAL_ALIGNMENT_LEFT))
	if t.kind == "achievement" and str(t.sub) != "":
		v.add_child(UiStyle.label(str(t.sub), 20, Color(1, 1, 1, 0.6), false, HORIZONTAL_ALIGNMENT_LEFT))
	await get_tree().process_frame
	var w := pill.get_combined_minimum_size().x
	pill.size = pill.get_combined_minimum_size()
	var y: float = safe.top + 16.0
	pill.position = Vector2((vs.x - w) * 0.5, -pill.size.y - 20)
	Sfx.play_go()
	var tw := create_tween()
	tw.tween_property(pill, "position:y", y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.2)
	tw.tween_property(pill, "position:y", -pill.size.y - 20, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_callback(pill.queue_free)
	tw.tween_callback(_next)

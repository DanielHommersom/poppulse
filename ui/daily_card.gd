class_name DailyCard
extends Button
## Menu strip for the Daily Challenge: what today's challenge is, whether the
## official attempt is used, the score, and a countdown to the next one.

var _title: Label
var _sub: Label
var _tag: Label
var _streak: Label
var _flame: NeonIcon


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	UiStyle.set_card_selected(self, UiStyle.GOLD, false)
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 18
	h.offset_right = -18
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 14)
	add_child(h)
	var ic := NeonIcon.new("calendar", UiStyle.GOLD)
	ic.custom_minimum_size = Vector2(46, 46)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", -2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	_title = UiStyle.label("DAILY CHALLENGE", 24, UiStyle.GOLD, false, HORIZONTAL_ALIGNMENT_LEFT)
	v.add_child(_title)
	_sub = UiStyle.label("", 22, Color(1, 1, 1, 0.8), false, HORIZONTAL_ALIGNMENT_LEFT)
	_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(_sub)
	_flame = NeonIcon.new("flame", Color(1.0, 0.55, 0.15))
	_flame.custom_minimum_size = Vector2(34, 40)
	_flame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_flame)
	_streak = UiStyle.label("0", 30, Color(1.0, 0.7, 0.3), true)
	h.add_child(_streak)
	_tag = UiStyle.label("PLAY", 20, UiStyle.INK, false)
	_tag.custom_minimum_size = Vector2(128, 42)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiStyle.GOLD
	sb.set_corner_radius_all(22)
	_tag.add_theme_stylebox_override("normal", sb)
	_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(_tag)
	set_streak(0)


## `done_text` empty = official attempt still open.
func show_state(challenge_title: String, done_text: String, countdown: String) -> void:
	if done_text == "":
		_sub.text = challenge_title
		_tag.text = "PLAY"
		_tag.modulate.a = 1.0
	else:
		_sub.text = "%s  ·  next in %s" % [done_text, countdown]
		_tag.text = "PRACTICE"
		_tag.modulate.a = 0.75


func set_streak(n: int) -> void:
	_streak.text = str(n)
	_streak.visible = n > 0
	_flame.visible = n > 0

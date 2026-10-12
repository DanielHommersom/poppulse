class_name StarsRow
extends HBoxContainer
## 0–3 stars; earned ones pop in one after another.

var _icons: Array[NeonIcon] = []


func _init(earned := 0, px := 88.0, animate := true) -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", int(px * 0.15))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 3:
		var on := i < earned
		var ic := NeonIcon.new("star" if on else "star_empty", UiStyle.GOLD if on else Color(1, 1, 1, 0.25))
		ic.custom_minimum_size = Vector2(px, px) * (1.15 if i == 1 else 1.0)
		ic.pivot_offset = ic.custom_minimum_size * 0.5
		if on and animate:
			ic.scale = Vector2.ZERO
		add_child(ic)
		_icons.append(ic)
	if animate:
		_pop_in.call_deferred(earned)


func _pop_in(earned: int) -> void:
	for i in earned:
		var ic := _icons[i]
		var t := ic.create_tween()
		t.tween_interval(0.25 + i * 0.22)
		t.tween_property(ic, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_callback(func() -> void: Sfx.play_pop(4 + i * 2))

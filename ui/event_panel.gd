class_name EventPanel
extends Modal
## The current seasonal event (US-41): time left, its challenges with goals
## and best results, and the theme reward.

signal challenge_chosen(index: int)


func _init() -> void:
	super("EVENT", 620.0)


func _on_open() -> void:
	clear_body()
	var e := Events.active_event()
	if e.is_empty():
		body.add_child(UiStyle.label("No event right now — check back soon!", 28, UiStyle.DIM_TEXT))
		return
	set_title(str(e.name).to_upper())
	var n := (e.challenges as Array).size()
	var head := UiStyle.label("%d days left  ·  %d / %d cleared" % [Events.days_left(e), Events.cleared_count(e), n], 26, UiStyle.GOLD, true)
	body.add_child(head)
	var reward := UiStyle.label(str(e.get("reward_text", "")), 22, UiStyle.DIM_TEXT)
	reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(reward)
	for i in n:
		var c: Dictionary = e.challenges[i]
		var card := PanelContainer.new()
		var done := Events.is_cleared(e, i)
		card.add_theme_stylebox_override("panel", UiStyle.card_style(UiStyle.OK if done else UiStyle.ACCENT, done, 22))
		body.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var ic := NeonIcon.new(ModeRegistry.info(c.mode).get("icon", "bubble"), ModeRegistry.info(c.mode).get("color", UiStyle.ACCENT))
		ic.custom_minimum_size = Vector2(44, 44)
		row.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", -2)
		row.add_child(v)
		v.add_child(UiStyle.label(str(c.title), 26, Color.WHITE, false, HORIZONTAL_ALIGNMENT_LEFT))
		var lower := bool(c.get("lower_is_better", false))
		var goal := ModeRegistry.format_record(c.mode, int(c.goal))
		var best := Events.best(e.id, i)
		var line := ("Goal: %s %s" % ["under" if lower else "reach", goal]) + ("   ·   Best: %s" % ModeRegistry.format_record(c.mode, best) if best > 0 else "")
		v.add_child(UiStyle.label(line, 19, UiStyle.DIM_TEXT, false, HORIZONTAL_ALIGNMENT_LEFT))
		if done:
			var ok := NeonIcon.new("check", UiStyle.OK)
			ok.custom_minimum_size = Vector2(40, 40)
			row.add_child(ok)
		var play := UiStyle.ghost_button("PLAY", UiStyle.CYAN, 22)
		play.pressed.connect(func() -> void:
			close()
			challenge_chosen.emit(i))
		row.add_child(play)

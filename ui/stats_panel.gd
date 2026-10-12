class_name StatsPanel
extends Modal
## Records & statistics: per mode record / runs / average / play time, the
## Reflex history graph, Stage stars and Daily streaks.

## A premium-only feature was tapped (US-29).
signal premium_requested


func _ready() -> void:
	super._ready()
	Platform.entitlements_changed.connect(refresh)


func _init() -> void:
	super("RECORDS", 640.0)


func _on_open() -> void:
	clear_body()
	for id in ModeRegistry.ids():
		_mode_block(id)
	_daily_block()
	_achievements_block()


func _achievements_block() -> void:
	add_section("ACHIEVEMENTS  %d / %d" % [Achievements.unlocked_count(), Achievements.defs.size()])
	for def: Dictionary in Achievements.defs:
		var done := Achievements.is_unlocked(def.id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var ic := NeonIcon.new(str(def.get("icon", "trophy")), UiStyle.GOLD if done else Color(1, 1, 1, 0.3))
		ic.custom_minimum_size = Vector2(44, 44)
		row.add_child(ic)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", -4)
		v.add_child(UiStyle.label(str(def.name), 26, Color.WHITE if done else Color(1, 1, 1, 0.6), false, HORIZONTAL_ALIGNMENT_LEFT))
		v.add_child(UiStyle.label(str(def.desc), 19, Color(1, 1, 1, 0.45), false, HORIZONTAL_ALIGNMENT_LEFT))
		row.add_child(v)
		var p := Achievements.percent(def)
		if done:
			var ok := NeonIcon.new("check", UiStyle.OK)
			ok.custom_minimum_size = Vector2(36, 36)
			row.add_child(ok)
		elif str(def.get("compare", "gte")) != "lte" and p > 0.0:
			row.add_child(UiStyle.label("%d%%" % int(p), 22, UiStyle.CYAN))
		body.add_child(row)


func _mode_block(id: String) -> void:
	var info := ModeRegistry.info(id)
	var st := SaveData.mode_stats(id)
	var col: Color = info.get("color", UiStyle.ACCENT)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.card_style(col, false, 24))
	body.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	var ic := NeonIcon.new(info.get("icon", "bubble"), col)
	ic.custom_minimum_size = Vector2(40, 40)
	head.add_child(ic)
	var name_l := UiStyle.label(info.get("name", id), 32, Color.WHITE, false, HORIZONTAL_ALIGNMENT_LEFT)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_l)

	var played := int(st.played)
	var avg := int(round(float(st.total) / maxf(float(played), 1.0)))
	if id == "reflex":  # runs without a valid time are not part of the average
		var r: Array = st.recent
		avg = int(round(ReflexGraph._mean(r))) if not r.is_empty() else 0
	var record := SaveData.total_stars() if id == "stage" else int(st.best)
	var rows := HBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	v.add_child(rows)
	var unit: String = info.get("record_unit", "")
	_stat(rows, "RECORD", ("%d / %d ★" % [record, StageLevels.count() * 3]) if id == "stage" else (Hud.fmt(record) + unit if record > 0 else "-"), UiStyle.GOLD)
	_stat(rows, "RUNS", str(played), UiStyle.CYAN)
	if id != "stage":
		_stat(rows, "AVERAGE", Hud.fmt(avg) + unit if played > 0 and avg > 0 else "-", UiStyle.CYAN)
	_stat(rows, "TIME", _duration(float(st.time_played)), UiStyle.CYAN)

	if id == "reflex":
		var r: Array = st.recent
		var sm := ReflexGraph.summary(r, int(st.best))
		var extra := HBoxContainer.new()
		v.add_child(extra)
		_stat(extra, "FASTEST TAP", ("%d ms" % int(st.get("best_single", 0))) if int(st.get("best_single", 0)) > 0 else "-", UiStyle.GOLD)
		if Premium.reflex_stats_locked():
			var teaser := UiStyle.ghost_button("GRAPH & TREND  ·  PREMIUM", UiStyle.GOLD, 22)
			teaser.pressed.connect(func() -> void: premium_requested.emit())
			v.add_child(teaser)
		else:
			_stat(extra, "LAST 10 AVG", ("%d ms" % int(sm.avg10)) if int(sm.avg10) > 0 else "-", Color.WHITE)
			v.add_child(ReflexGraph.new(r.duplicate(), int(st.best)))


func _daily_block() -> void:
	var d := SaveData.section("daily")
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.card_style(UiStyle.GOLD, false, 24))
	body.add_child(card)
	var v := VBoxContainer.new()
	card.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	var ic := NeonIcon.new("calendar", UiStyle.GOLD)
	ic.custom_minimum_size = Vector2(40, 40)
	head.add_child(ic)
	var t := UiStyle.label("DAILY", 32, Color.WHITE, false, HORIZONTAL_ALIGNMENT_LEFT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var rows := HBoxContainer.new()
	v.add_child(rows)
	_stat(rows, "STREAK", str(Daily.current_streak()), Color(1.0, 0.65, 0.25))
	_stat(rows, "BEST STREAK", str(int(d.get("best_streak", 0))), UiStyle.GOLD)
	_stat(rows, "DAYS PLAYED", str((d.results as Dictionary).size()), UiStyle.CYAN)


func _stat(parent: Control, caption: String, value: String, color: Color) -> void:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", -4)
	col.add_child(UiStyle.label(value, 32 if value.length() < 9 else 26, color, true))
	col.add_child(UiStyle.label(caption, 18, Color(1, 1, 1, 0.5)))
	parent.add_child(col)


static func _duration(seconds: float) -> String:
	var s := int(seconds)
	if s <= 0:
		return "-"
	@warning_ignore("integer_division")
	var h := s / 3600
	@warning_ignore("integer_division")
	var m := (s / 60) % 60
	if h > 0:
		return "%dh %02dm" % [h, m]
	return "%dm %02ds" % [m, s % 60]

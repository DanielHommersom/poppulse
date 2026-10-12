class_name PartyPanels
extends RefCounted
## Pass-and-play screens (US-40): setup, "pass to …" between turns, final ranking.


## 2–4 players, optional names, which mode. Emits start(mode_id, names).
class Setup extends Modal:
	signal start(mode_id: String, names: Array)

	const MODES := ["score", "reflex", "memory"]
	var _count := 2
	var _mode := "score"
	var _names: Array[LineEdit] = []

	func _init() -> void:
		super("PASS & PLAY", 620.0)

	## Opens with the mode that was last played preselected (when it fits).
	func open_with(mode_id := "") -> void:
		if mode_id in MODES:
			_mode = mode_id
		open()

	func _on_open() -> void:
		clear_body()
		body.add_child(UiStyle.label("Same challenge for everyone. Take turns!", 24, UiStyle.DIM_TEXT))
		add_section("MODE")
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		body.add_child(row)
		for id in MODES:
			var info := ModeRegistry.info(id)
			var b := UiStyle.ghost_button(str(info.name), info.color if id == _mode else Color(1, 1, 1, 0.5), 24)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void:
				_mode = id
				refresh())
			row.add_child(b)
		add_section("PLAYERS")
		var crow := HBoxContainer.new()
		crow.add_theme_constant_override("separation", 10)
		body.add_child(crow)
		for n in [2, 3, 4]:
			var b := UiStyle.ghost_button(str(n), UiStyle.CYAN if n == _count else Color(1, 1, 1, 0.5), 30)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.pressed.connect(func() -> void:
				_count = n
				refresh())
			crow.add_child(b)
		var old := _names.map(func(l: LineEdit) -> String: return l.text)
		_names.clear()
		for i in _count:
			var le := LineEdit.new()
			le.placeholder_text = "Player %d (optional name)" % (i + 1)
			le.text = old[i] if i < old.size() else ""
			le.max_length = 14
			le.add_theme_font_override("font", UiStyle.font())
			le.add_theme_font_size_override("font_size", 30)
			le.custom_minimum_size.y = 64
			body.add_child(le)
			_names.append(le)
		add_button("START", UiStyle.ACCENT, _on_start, true)

	func _on_start() -> void:
		var names := []
		for i in _names.size():
			var t := _names[i].text.strip_edges()
			names.append(t if t != "" else "Player %d" % (i + 1))
		close()
		start.emit(_mode, names)


## Full-screen hand-over between turns so nobody sees the next board early.
class PassScreen extends Modal:
	signal ready_pressed

	var _name := ""
	var _last := ""

	func _init() -> void:
		super("", 600.0)
		dismiss_on_backdrop = false
		closable = false

	func show_for(player_name: String, last_result: String) -> void:
		_name = player_name
		_last = last_result
		open()

	func _on_open() -> void:
		clear_body()
		if _last != "":
			body.add_child(UiStyle.label(_last, 28, UiStyle.DIM_TEXT))
		body.add_child(UiStyle.label("PASS TO", 34, UiStyle.DIM_TEXT))
		var n := UiStyle.label(_name, 84, UiStyle.GOLD, true)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(n)
		var ic := NeonIcon.new("people", UiStyle.CYAN)
		ic.custom_minimum_size = Vector2(0, 90)
		body.add_child(ic)
		add_button("I'M READY", UiStyle.ACCENT, func() -> void:
			close()
			ready_pressed.emit(), true)


## Final ranking with a winner animation.
class Ranking extends Modal:
	signal again
	signal done

	var _rows: Array = []  # [{name, value_text, rank}]

	func _init() -> void:
		super("RESULTS", 600.0)
		dismiss_on_backdrop = false
		closable = false

	func show_ranking(rows: Array) -> void:
		_rows = rows
		open()

	func _on_open() -> void:
		clear_body()
		if _rows.is_empty():
			return
		var crown := NeonIcon.new("crown", UiStyle.GOLD)
		crown.custom_minimum_size = Vector2(0, 110)
		crown.pivot_offset = Vector2(300, 55)
		body.add_child(crown)
		var w := UiStyle.label("%s WINS!" % str(_rows[0].name).to_upper(), 52, UiStyle.GOLD, true)
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(w)
		for r: Dictionary in _rows:
			var row := HBoxContainer.new()
			row.add_child(UiStyle.label("%d." % int(r.rank), 34, UiStyle.GOLD if int(r.rank) == 1 else UiStyle.DIM_TEXT, false, HORIZONTAL_ALIGNMENT_LEFT))
			var nl := UiStyle.label(str(r.name), 34, Color.WHITE, false, HORIZONTAL_ALIGNMENT_LEFT)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(nl)
			row.add_child(UiStyle.label(str(r.value_text), 34, UiStyle.CYAN, true, HORIZONTAL_ALIGNMENT_RIGHT))
			body.add_child(row)
		add_button("PLAY AGAIN", UiStyle.ACCENT, func() -> void:
			close()
			again.emit(), true)
		add_button("DONE", Color(1, 1, 1, 0.8), func() -> void:
			close()
			done.emit())
		# Winner animation: the crown drops in and wobbles.
		crown.scale = Vector2(0.2, 0.2)
		var t := crown.create_tween()
		t.tween_property(crown, "scale", Vector2(1.2, 1.2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(crown, "scale", Vector2.ONE, 0.2)
		t.tween_property(crown, "rotation", 0.12, 0.12)
		t.tween_property(crown, "rotation", -0.12, 0.2)
		t.tween_property(crown, "rotation", 0.0, 0.12)

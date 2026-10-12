class_name Hud
extends CanvasLayer
## Score, timer, combo, banners, play button and the results card.
## Built in code so layout adapts to iPhone / iPad / safe areas at runtime.
## Which readouts are visible is decided by the active mode's hooks.

signal play_pressed
signal results_dismissed
signal settings_pressed
signal pause_pressed
signal daily_pressed

const MULT_COLORS := [
	Color(1, 1, 1), Color(0.25, 0.95, 1.0), Color(0.4, 1.0, 0.5), Color(1.0, 0.95, 0.3),
	Color(1.0, 0.6, 0.2), Color(1.0, 0.3, 0.7), Color(0.75, 0.4, 1.0), Color(1.0, 0.25, 0.3),
]

var results: ResultsPanel
var menu: MainMenu
var daily: DailyCard
## Board areas: compact in the menu (room for mode cards), full size in a run.
var play_area := Rect2()
var menu_area := Rect2()

var _root: Control
var _score: Label
var _best: Label
var _best_cap: Label
var _time: Label
var _time_cap: Label
var _combo: Label
var _hint: Label
var _banner: Label
var _bar_bg: ColorRect
var _bar: ColorRect
var _play: Button
var _gear: Button
var _pause: Button
## Top-right in menus: the gear. Everything else (records, style, premium,
## event) lives inside the settings screen.
var _menu_bar: VBoxContainer

## US-36: banners fade instead of zooming; no punch scaling.
var reduce_motion := false
var _uses_timer := true
var _uses_combo := true
var _uses_score := true
var _shown_score := 0.0
var _bar_full := Rect2()
var _score_tw: Tween
var _banner_tw: Tween
var _punches := {}
var _combo_lost_until := 0


func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_time_cap = _label(24, Color(1, 1, 1, 0.5), false, HORIZONTAL_ALIGNMENT_LEFT)
	_time_cap.text = "TIME"
	_time = _label(52, UiStyle.CYAN, true, HORIZONTAL_ALIGNMENT_LEFT)
	_best_cap = _label(24, Color(1, 1, 1, 0.5), false, HORIZONTAL_ALIGNMENT_RIGHT)
	_best_cap.text = "BEST"
	_best = _label(40, UiStyle.GOLD, true, HORIZONTAL_ALIGNMENT_RIGHT)
	_score = _label(110, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	_combo = _label(40, UiStyle.ACCENT, true, HORIZONTAL_ALIGNMENT_CENTER)
	_hint = _label(26, Color(1, 1, 1, 0.6), false, HORIZONTAL_ALIGNMENT_CENTER)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(1, 1, 1, 0.08)
	_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bar_bg)
	_bar = ColorRect.new()
	_bar.color = UiStyle.CYAN
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bar)

	_play = UiStyle.button("PLAY", UiStyle.ACCENT)
	_play.custom_minimum_size = Vector2(380, 110)
	_play.pressed.connect(_emit_play)
	_root.add_child(_play)

	menu = MainMenu.new()
	_root.add_child(menu)
	daily = DailyCard.new()
	daily.pressed.connect(func() -> void: daily_pressed.emit())
	_root.add_child(daily)

	results = ResultsPanel.new()
	results.dismissed.connect(func() -> void: results_dismissed.emit())
	_root.add_child(results)

	# Created after the results card so it stays tappable above the dim.
	_menu_bar = VBoxContainer.new()
	_menu_bar.add_theme_constant_override("separation", 12)
	_root.add_child(_menu_bar)
	_gear = UiStyle.icon_button("gear", Color(1, 1, 1, 0.85), MENU_BTN)
	_gear.pressed.connect(func() -> void: settings_pressed.emit())
	_menu_bar.add_child(_gear)
	_pause = UiStyle.icon_button("pause", Color(1, 1, 1, 0.85), 76)
	_pause.pressed.connect(func() -> void: pause_pressed.emit())
	_pause.hide()
	_root.add_child(_pause)

	_banner = _label(150, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.modulate.a = 0.0
	ThemeManager.theme_changed.connect(_apply_theme)


## Live theme switch: recolour the themed readouts and the CTA.
func _apply_theme(_t: ThemeData) -> void:
	UiStyle.set_label_color(_time, UiStyle.CYAN)
	UiStyle.set_label_color(_best, UiStyle.GOLD)
	_bar.color = UiStyle.CYAN
	UiStyle.restyle_button(_play, UiStyle.ACCENT)
	results.restyle()


## Positions everything and returns the rect the board may use.
func layout(vs: Vector2, safe: Dictionary) -> Rect2:
	var top: float = safe.top + 20.0
	var side: float = 40.0 + maxf(safe.left, safe.right)

	_place(_time_cap, Vector2(side, top), Vector2(240, 30))
	_place(_time, Vector2(side, top + 26), Vector2(240, 64))
	_vs = vs
	_side = side
	_top = top
	_place_best()
	_place(_menu_bar, Vector2(vs.x - side - MENU_BTN, top + 4), Vector2(MENU_BTN, MENU_BTN))
	_place(_pause, Vector2((vs.x - 76) * 0.5, top + 2), Vector2(76, 76))
	_place(_score, Vector2(0, top + 70), Vector2(vs.x, 130))
	_place(_combo, Vector2(0, top + 195), Vector2(vs.x, 54))
	var dw := minf(600.0, vs.x - side * 2.0 + 20.0)
	_place(daily, Vector2((vs.x - dw) * 0.5, top + 200), Vector2(dw, 80))
	_bar_full = Rect2(side, top + 262, vs.x - side * 2.0, 8)
	_place(_bar_bg, _bar_full.position, _bar_full.size)
	_bar.position = _bar_full.position
	_bar.size = Vector2(_bar.size.x if _bar.size.x > 0 else _bar_full.size.x, _bar_full.size.y)
	var top_h := top + 290.0

	var btn := _play.custom_minimum_size
	var btn_y: float = vs.y - safe.bottom - 36.0 - btn.y
	_place(_play, Vector2((vs.x - btn.x) * 0.5, btn_y), btn)
	var cards_y := btn_y - 34.0 - MainMenu.CARD_H
	menu.layout_in(Rect2(side - 16.0, cards_y, vs.x - (side - 16.0) * 2.0, MainMenu.CARD_H))
	_place(_hint, Vector2(side, cards_y - 74), Vector2(vs.x - side * 2.0, 64))
	_place(_banner, Vector2(0, vs.y * 0.5 - 110), Vector2(vs.x, 220))
	_banner.pivot_offset = _banner.size * 0.5
	if results.visible:
		results._fit()

	play_area = Rect2(20, top_h, vs.x - 40, btn_y - 60.0 - top_h)
	menu_area = Rect2(20, top_h, vs.x - 40, cards_y - 60.0 - top_h)
	return play_area


const MENU_BTN := 68.0


## Mode hooks decide which in-run readouts exist (US-06).
func configure_for(mode: GameMode) -> void:
	_uses_timer = mode.uses_timer()
	_uses_combo = mode.uses_combo()
	_uses_score = mode.uses_score()
	_time_cap.text = "TIME" if _uses_timer else mode.progress_caption()


## Top-left readout for modes without a timer: "3/10".
func set_progress(done: int, total: int) -> void:
	if _uses_timer:
		if not _uses_score:  # timer mode without score: progress is the headline
			set_headline("%d/%d" % [done, total])
		return
	_time.text = "%d/%d" % [done, total] if total > 0 else str(done)
	UiStyle.set_label_color(_time, UiStyle.CYAN)


# --- State views -------------------------------------------------------------

func show_idle(best_text: String) -> void:
	results.close()
	_score.text = AppInfo.TITLE
	_score.show()
	_shown_score = 0.0
	_combo.text = ""
	_hint.text = ""
	_play.text = "PLAY"
	_play.show()
	menu.show()
	daily.show()
	_set_menu_chrome(true)
	set_best_text(best_text)


## Theme sheet open: hide the menu chrome below the board.
func set_menu_visible(v: bool) -> void:
	menu.visible = v
	daily.visible = v
	_play.visible = v
	_hint.visible = v
	_menu_bar.visible = v


func show_countdown() -> void:
	results.close()
	_play.hide()
	menu.hide()
	daily.hide()
	_set_menu_chrome(false)
	_hint.text = ""
	_combo.text = ""
	_shown_score = 0.0
	_score.text = "0" if _uses_score else ""
	UiStyle.set_label_color(_score, Color.WHITE)


## Back into the run after a rewarded continue (score etc. stay as they were).
func show_resume() -> void:
	results.close()
	_play.hide()
	menu.hide()
	daily.hide()
	_set_menu_chrome(false)


func show_results(spec: Dictionary) -> void:
	_set_menu_chrome(true)
	_play.hide()
	menu.hide()
	daily.hide()
	results.present(spec)


func hide_results() -> void:
	results.close()


# --- Live values -------------------------------------------------------------

func set_pause_visible(v: bool) -> void:
	_pause.visible = v


func set_best_text(best: String) -> void:
	_best.text = best


func set_score(v: int) -> void:
	if not _uses_score:
		return
	if _score_tw and _score_tw.is_valid():
		_score_tw.kill()
	_score_tw = create_tween()
	_score_tw.tween_method(_show_score, _shown_score, float(v), 0.25)
	_punch(_score, 1.12)


## Big centre readout for modes without a running score (reaction ms, pattern length…).
func set_headline(text: String, color := Color.WHITE) -> void:
	_score.text = text
	UiStyle.set_label_color(_score, color)
	_punch(_score, 1.12)


func set_hint(text: String) -> void:
	_hint.text = text


func set_time(remaining: float, total: float) -> void:
	_time.text = ("%.1f" % remaining) if remaining < 10.0 else str(int(ceil(remaining)))
	var c: Color = UiStyle.CYAN if remaining >= 10.0 else UiStyle.DANGER
	_bar.color = c
	UiStyle.set_label_color(_time, c)
	_bar.size.x = _bar_full.size.x * clampf(remaining / maxf(total, 0.001), 0.0, 1.0)


func set_combo(combo: int, mult: int, bumped: bool) -> void:
	if combo < 2:
		if Time.get_ticks_msec() >= _combo_lost_until:
			_combo.text = ""
		return
	_combo.text = "x%d   %d COMBO" % [mult, combo]
	UiStyle.set_label_color(_combo, MULT_COLORS[mini(mult - 1, MULT_COLORS.size() - 1)])
	_punch(_combo, 1.3 if bumped else 1.08)


## A one-line status under the headline (used by modes without combos).
func set_subline(text: String, color: Color) -> void:
	_combo.text = text
	UiStyle.set_label_color(_combo, color)
	_punch(_combo, 1.1)


## Shown in the combo line (not over the board) so it never hides targets.
func combo_lost() -> void:
	_combo.text = "COMBO LOST"
	UiStyle.set_label_color(_combo, UiStyle.DANGER)
	_punch(_combo, 1.2)
	_combo_lost_until = Time.get_ticks_msec() + 700
	get_tree().create_timer(0.7).timeout.connect(_clear_combo_lost)


func _clear_combo_lost() -> void:
	if _combo.text == "COMBO LOST" and Time.get_ticks_msec() >= _combo_lost_until:
		_combo.text = ""


func mult_color(mult: int) -> Color:
	return MULT_COLORS[mini(mult - 1, MULT_COLORS.size() - 1)]


func banner(text: String, color: Color, size := 150, hold := 0.35) -> void:
	_banner.text = text
	_banner.label_settings.font_size = size
	UiStyle.set_label_color(_banner, color)
	if _banner_tw and _banner_tw.is_valid():
		_banner_tw.kill()
	_banner.modulate.a = 1.0
	_banner.scale = Vector2.ONE if reduce_motion else Vector2(1.6, 1.6)
	_banner_tw = create_tween()
	_banner_tw.tween_property(_banner, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tw.tween_interval(hold)
	_banner_tw.tween_property(_banner, "modulate:a", 0.0, 0.2)


static func fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


# --- Internals ---------------------------------------------------------------

## Menu-only controls (settings) vs. in-run readouts (timer).
var _vs := Vector2.ZERO
var _side := 40.0
var _top := 20.0
var _in_menu := true


## BEST sits top-left in menus (settings + more are top-right); during a run
## the timer owns the top-left, so BEST moves to the right.
func _place_best() -> void:
	var left := _in_menu
	var x := _side if left else _vs.x - _side - 240.0
	var align := HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT
	_place(_best_cap, Vector2(x, _top), Vector2(240, 30))
	_place(_best, Vector2(x, _top + 26), Vector2(240, 64))
	_best_cap.horizontal_alignment = align
	_best.horizontal_alignment = align


func _set_menu_chrome(in_menu: bool) -> void:
	_in_menu = in_menu
	_place_best()
	_menu_bar.visible = in_menu
	_time.visible = not in_menu
	_time_cap.visible = not in_menu
	_bar.visible = _uses_timer and not in_menu
	_bar_bg.visible = _bar.visible
	if in_menu:
		UiStyle.set_label_color(_score, Color.WHITE)


func _emit_play() -> void:
	play_pressed.emit()


func _show_score(x: float) -> void:
	_shown_score = x
	_score.text = fmt(int(round(x)))


func _punch(c: Control, amount: float) -> void:
	if reduce_motion:
		return
	var old: Tween = _punches.get(c)
	if old != null and old.is_valid():
		old.kill()
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2.ONE * amount
	var t := create_tween()
	t.tween_property(c, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_punches[c] = t


func _place(c: Control, pos: Vector2, size: Vector2) -> void:
	c.position = pos
	c.size = size


func _label(size: int, color: Color, glow: bool, align: HorizontalAlignment) -> Label:
	var l := UiStyle.label("", size, color, glow, align)
	_root.add_child(l)
	return l

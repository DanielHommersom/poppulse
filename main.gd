extends Node2D
## Game manager + state machine. Wires the board, the active mode and all
## presentation (effects, audio, haptics, HUD) together.

enum GameState { IDLE, COUNTDOWN, PLAYING, PAUSED, RESULTS }

const BG_SHADER := preload("res://shaders/background.gdshader")
const COUNT_STEP := 0.45  # seconds per 3-2-1 beat
## Debug-only tools; the folder is excluded from the release export preset.
const TUNING_OVERLAY := "res://debug/tuning_overlay.gd"

var state := GameState.IDLE
## Pause automatically when the app / window loses focus (dev scenarios turn it off).
var auto_pause := true
var world: Node2D
var board: Board
var effects: Effects
var hud: Hud
var mode: GameMode
var ui: CanvasLayer  # modal screens above the HUD
var settings: SettingsPanel
var pause_overlay: PauseOverlay
var stage_select: StageSelect
var stats_panel: StatsPanel
var toast: Toast
var theme_picker: ThemePicker
var premium_panel: PremiumPanel
var party_setup: PartyPanels.Setup
var party_pass: PartyPanels.PassScreen
var party_ranking: PartyPanels.Ranking
## Pass-and-play session (US-40): {mode, seed, players: [{name, score}], turn}.
var party := {}
var event_panel: EventPanel
## Active seasonal-event challenge run (US-41): {event, index}.
var event_run := {}
## US-29: at most one unsolicited upsell per session.
var _upsell_shown := false

var _bg_mat: ShaderMaterial
var _shake := 0.0
var _energy := 0.0
var _accent := Color(0.7, 0.25, 1.0)
var _accent_target := Color(0.7, 0.25, 1.0)
var _last_second := -1
## 3-2-1 countdown, driven by _process so it can be paused.
var _count_left := 0.0
var _count_beat := 0
var _count_resumes := false  # true: countdown after a pause, false: fresh run
var _mode_locked := false  # the mode asked for no input (pattern playback)
## Stage Mode: level the next run plays.
var stage_level := 1
var _coach: HintMarker  # first-run "tap the glowing bubble" mark
## Active Daily Challenge run: {day, challenge, official}. Empty = normal run.
var daily := {}
var _daily_tick := 0.0
var _last_results := {}
var _last_is_new := false
var _prev_best := 0  # mode best before the last result (to undo it on a continue)
var _rewarded_this_break := false  # US-33: no interstitial right after a rewarded ad


func _ready() -> void:
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_mat = ShaderMaterial.new()
	_bg_mat.shader = BG_SHADER
	bg.material = _bg_mat
	bg_layer.add_child(bg)
	ThemeManager.theme_changed.connect(_apply_theme)
	_apply_theme(ThemeManager.current)

	world = Node2D.new()  # everything that shakes
	add_child(world)
	board = Board.new()
	world.add_child(board)
	effects = Effects.new()
	world.add_child(effects)
	hud = Hud.new()
	add_child(hud)
	ui = CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	settings = SettingsPanel.new()
	ui.add_child(settings)
	pause_overlay = PauseOverlay.new()
	ui.add_child(pause_overlay)
	pause_overlay.resume_pressed.connect(_resume)
	pause_overlay.quit_pressed.connect(_quit_run)
	stage_select = StageSelect.new()
	ui.add_child(stage_select)
	stage_select.level_chosen.connect(_play_stage)
	stats_panel = StatsPanel.new()
	ui.add_child(stats_panel)
	premium_panel = PremiumPanel.new()
	ui.add_child(premium_panel)
	premium_panel.level_trial_requested.connect(_rewarded_level_trial)
	var att_prompt := AttPrompt.new()
	ui.add_child(att_prompt)
	Platform.tracking_explainer_requested.connect(att_prompt.open)
	att_prompt.continued.connect(func() -> void: Platform.tracking_explainer_closed.emit())
	event_panel = EventPanel.new()
	ui.add_child(event_panel)
	event_panel.challenge_chosen.connect(start_event_challenge)
	Events.event_completed.connect(func(e: Dictionary) -> void:
		var th := ThemeManager.get_theme(str(e.theme))
		toast.push("%s THEME UNLOCKED" % (th.display_name.to_upper() if th else "EVENT"), "Yours to keep — event cleared!", "gift", "info"))
	party_setup = PartyPanels.Setup.new()
	ui.add_child(party_setup)
	party_setup.start.connect(start_party)
	party_pass = PartyPanels.PassScreen.new()
	ui.add_child(party_pass)
	party_pass.ready_pressed.connect(_party_turn)
	party_ranking = PartyPanels.Ranking.new()
	ui.add_child(party_ranking)
	party_ranking.again.connect(func() -> void: start_party(party.mode, party.players.map(func(p: Dictionary) -> String: return p.name)))
	party_ranking.done.connect(func() -> void:
		party = {}
		_enter_idle()
		hud.menu.select("party")
		_party_selected = true
		_update_menu_hint())
	stage_select.locked_tapped.connect(func(id: int, reason: String) -> void:
		if reason == "premium":
			open_premium("locked_item", id))
	stats_panel.premium_requested.connect(open_premium.bind("locked_item"))
	Platform.entitlements_changed.connect(_on_entitlements_changed)
	theme_picker = ThemePicker.new()
	ui.add_child(theme_picker)
	theme_picker.visibility_changed.connect(_on_picker_visibility)
	theme_picker.locked_tapped.connect(_on_style_locked)
	theme_picker.trial_requested.connect(func(kind: String, id: String) -> void:
		if await rewarded_style_trial(kind, id):
			theme_picker.use_selected())
	toast = Toast.new()
	add_child(toast)
	Achievements.unlocked.connect(func(def: Dictionary) -> void:
		toast.push(str(def.name), str(def.desc), str(def.get("icon", "trophy"))))
	for m in ui.get_children():
		if m is Modal:
			(m as Modal).visibility_changed.connect(_sync_board_input)

	board.bubble_pressed.connect(_on_bubble_pressed)
	hud.play_pressed.connect(_on_menu_play)
	hud.results_dismissed.connect(_leave_results.bind(_enter_idle, "results_to_menu"))
	hud.settings_pressed.connect(_open_settings)
	hud.pause_pressed.connect(pause)
	hud.menu.mode_selected.connect(_on_mode_selected)
	hud.daily_pressed.connect(start_daily)
	settings.open_requested.connect(_on_settings_nav)
	stage_level = StageLevels.current_level()
	var last := str(SaveData.get_setting("last_mode"))
	start_mode(last if ModeRegistry.has(last) else ModeRegistry.ids()[0])
	hud.menu.build(ModeRegistry.menu_ids(), mode.mode_id)

	if OS.is_debug_build() and ResourceLoader.exists(TUNING_OVERLAY):
		var tuning: Node = load(TUNING_OVERLAY).new()
		tuning.set("main", self)
		add_child(tuning)

	_apply_access()
	SaveData.setting_changed.connect(func(k: String, _v: Variant) -> void:
		if k in ["reduce_motion", "symbols"]:
			_apply_access())
	get_viewport().size_changed.connect(_layout)
	_layout()
	_enter_idle()
	Events.events_updated.connect(_refresh_event_button)
	_play_splashes()


## Studio + game splash on launch, over the already-built menu. Dev scenarios
## and tests (--test-save / --no-splash) skip it; --force-splash shows it anyway.
func _play_splashes() -> void:
	var args := OS.get_cmdline_user_args()
	var skip := ("--test-save" in args or "--no-splash" in args) and not "--force-splash" in args
	if skip:
		_announce_event.call_deferred()
		return
	var splash := SplashSequence.new()
	splash.finished.connect(_announce_event)
	add_child(splash)


## Swaps the active mode: the old one is disconnected and freed, the new one is
## wired to presentation purely through its signals. The board is rebuilt when
## the grid size differs.
func start_mode(mode_id: String) -> void:
	if not ModeRegistry.has(mode_id):
		push_error("Unknown mode: %s" % mode_id)
		return
	if mode != null:
		mode.stop()
		for link in _mode_links():
			if mode.is_connected(link[0], link[1]):
				mode.disconnect(link[0], link[1])
		remove_child(mode)
		mode.queue_free()
	_mode_locked = false
	mode = ModeRegistry.create(mode_id)
	add_child(mode)
	mode.setup(board)
	for link in _mode_links():
		if mode.has_signal(link[0]):
			mode.connect(link[0], link[1])
	mode.context = _context_for(mode_id)
	_apply_board_size()
	hud.configure_for(mode)


func _apply_board_size() -> void:
	var size := mode.board_size()
	if board.bubbles.is_empty() or size != Vector2i(board.cols, board.rows):
		board.build(size.x, size.y)
		if is_inside_tree() and hud.play_area.size != Vector2.ZERO:
			board.layout(_board_area())


## [signal name, handler] pairs between a mode and the presentation layer.
func _mode_links() -> Array:
	return [
		["score_changed", hud.set_score],
		["combo_changed", hud.set_combo],
		["time_changed", _on_time],
		["target_hit", _on_hit],
		["wrong_tap", _on_wrong],
		["target_missed", _on_missed],
		["multiplier_up", _on_multiplier_up],
		["combo_broken", _on_combo_broken],
		["finished", _on_finished],
		["announce", _on_announce],
		["progress", hud.set_progress],
		["reaction", _on_reaction],
		["cue", _on_cue],
		["target_lit", _on_target_lit],
		["input_locked", _on_input_locked],
	]


## US-36: reduce motion (no screenshake, softer flashes/particles) + symbols.
func _apply_access() -> void:
	var rm := Access.reduce_motion()
	Bubble.reduce_motion = rm
	Bubble.symbols = Access.symbols()
	effects.reduced = rm
	hud.reduce_motion = rm
	for b in board.bubbles:
		b.set_radius(b.radius)  # redraw ring/symbol layer


func _apply_theme(t: ThemeData) -> void:
	_bg_mat.set_shader_parameter("top_color", t.bg_top)
	_bg_mat.set_shader_parameter("bottom_color", t.bg_bottom)
	_bg_mat.set_shader_parameter("grid", t.bg_grid)
	_bg_mat.set_shader_parameter("vignette", t.bg_vignette)
	_accent = t.bg_accent
	_accent_target = t.bg_accent


func _layout() -> void:
	var vs := get_viewport_rect().size
	hud.layout(vs, Platform.safe_margins(vs))
	board.layout(_board_area())


func _board_area() -> Rect2:
	return hud.menu_area if state == GameState.IDLE else hud.play_area


## The Pass & Play card is selected (US-40): PLAY opens its setup.
var _party_selected := false


func _on_mode_selected(mode_id: String) -> void:
	if state != GameState.IDLE:
		return
	_party_selected = mode_id == "party"
	if _party_selected:
		hud.set_best_text("-")
		_update_menu_hint()
		return
	if mode_id == mode.mode_id:
		hud.set_best_text(_best_text())
		_update_menu_hint()
		return
	start_mode(mode_id)
	SaveData.set_setting("last_mode", mode_id)
	hud.set_best_text(_best_text())
	board.attract = true
	_update_menu_hint()


## One line of guidance in the menu, never a tutorial screen: first "pop
## something", then a one-sentence explanation of a mode until it was played.
func _update_menu_hint() -> void:
	if not SaveData.get_flag("hint_fidget_done"):
		hud.set_hint("Tap the bubbles, then hit PLAY")
	elif _party_selected:
		hud.set_hint(str(ModeRegistry.info("party").get("blurb", "")))
	elif int(SaveData.mode_stats(mode.mode_id).played) == 0:
		hud.set_hint(str(ModeRegistry.info(mode.mode_id).get("blurb", "")))
	else:
		hud.set_hint("")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if auto_pause and (state == GameState.PLAYING or state == GameState.COUNTDOWN):
				pause()


## Android back button (US-42): closes what's on top, pauses a run, leaves
## results, and only then exits the app from the menu.
func _on_back() -> void:
	if theme_picker.visible:
		theme_picker.close()
		return
	for c in ui.get_children():
		if c is Modal and (c as Modal).is_open():
			if c == pause_overlay:
				pause_overlay._resume()
			elif (c as Modal).closable:
				(c as Modal).close()
			return
	match state:
		GameState.PLAYING, GameState.COUNTDOWN:
			pause()
		GameState.RESULTS:
			hud.results_dismissed.emit()
		GameState.IDLE:
			get_tree().quit()


func _process(delta: float) -> void:
	if Bubble.reduce_motion:
		_shake = 0.0
	if _shake > 0.3:
		world.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
		_shake *= exp(-delta * 16.0)
	else:
		_shake = 0.0
		world.position = Vector2.ZERO
	var target: float = clampf(mode.combo / 30.0, 0.0, 1.0) if state == GameState.PLAYING else 0.0
	_energy = lerpf(_energy, target, 1.0 - exp(-delta * 4.0))
	_accent = _accent.lerp(_accent_target, 1.0 - exp(-delta * 3.0))
	_bg_mat.set_shader_parameter("energy", _energy)
	_bg_mat.set_shader_parameter("accent", _accent)
	_tick_battery(delta)
	if state == GameState.COUNTDOWN:
		_tick_countdown(delta)
	elif state == GameState.IDLE:
		_daily_tick -= delta
		if _daily_tick <= 0.0:
			_daily_tick = 1.0
			_refresh_daily_card()


# --- State machine -----------------------------------------------------------

func _enter_idle() -> void:
	_refresh_event_button()
	if not daily.is_empty() or not event_run.is_empty():
		# Leave the challenge's tweaked config behind: back to the player's mode.
		daily = {}
		event_run = {}
		var last := str(SaveData.get_setting("last_mode"))
		start_mode(last if ModeRegistry.has(last) else ModeRegistry.ids()[0])
		hud.menu.select(mode.mode_id)
	state = GameState.IDLE
	_mode_locked = false
	_refresh_daily_card()
	board.attract = true
	board.layout(_board_area(), true)
	_sync_board_input()
	for id in ModeRegistry.ids():
		hud.menu.set_record(id, ModeRegistry.format_record(id, _record_value(id)))
	hud.show_idle(_best_text())
	_update_menu_hint()
	hud.set_time(mode.get_duration(), mode.get_duration())


# --- Daily Challenge (US-17) ------------------------------------------------

func start_daily() -> void:
	if state != GameState.IDLE or _modal_open() or theme_picker.visible:
		return
	var ch := Daily.today_challenge()
	start_mode(ch.mode)
	Daily.apply_overrides(mode.cfg, ch.overrides)
	mode.on_tuning_changed()
	daily = {"day": ch.day, "challenge": ch, "official": Daily.can_play_official(ch.day)}
	hud.configure_for(mode)
	_on_play()


func _refresh_daily_card() -> void:
	var ch := Daily.today_challenge()
	var day: int = ch.day
	var done := ""
	if not Daily.can_play_official(day):
		var r := Daily.result(day)
		var has_score := not bool(r.get("pending", false)) and int(r.get("score", 0)) > 0
		done = "DONE  " + (ModeRegistry.format_record(ch.mode, int(r.score)) if has_score else "no score")
	hud.daily.show_state(ch.title, done, Daily.countdown_text())
	hud.daily.set_streak(Daily.current_streak())


func _open_themes() -> void:
	if state == GameState.IDLE and not _modal_open():
		theme_picker.open()


## While the theme sheet is up the menu (cards / PLAY) hides; the board stays live.
func _on_picker_visibility() -> void:
	hud.set_menu_visible(not theme_picker.visible)


# --- Seasonal events (US-41) ----------------------------------------------------------

## Settings ▸ Records / Style / Premium / Event.
func _on_settings_nav(target: String) -> void:
	match target:
		"records":
			_open_stats()
		"style":
			if state == GameState.RESULTS:
				_enter_idle()  # the style sheet previews on the menu board
			_open_themes()
		"premium":
			open_premium("menu")
		"event":
			if state == GameState.RESULTS:
				_enter_idle()
			event_panel.open()


func _refresh_event_button() -> void:
	settings.refresh()  # the Event row appears / disappears with the event


## One "event is live" toast per event.
func _announce_event() -> void:
	var e := Events.active_event()
	if e.is_empty() or SaveData.get_flag("seen_event_" + str(e.id)):
		return
	SaveData.set_flag("seen_event_" + str(e.id))
	toast.push(str(e.name).to_upper() + " IS LIVE", "%d special challenges · %d days" % [(e.challenges as Array).size(), Events.days_left(e)], "gift", "info")


func start_event_challenge(index: int) -> void:
	var e := Events.active_event()
	if e.is_empty() or state != GameState.IDLE:
		return
	var c: Dictionary = e.challenges[index]
	start_mode(c.mode)
	Daily.apply_overrides(mode.cfg, c.get("overrides", {}))
	mode.on_tuning_changed()
	event_run = {"event": e, "index": index}
	hud.configure_for(mode)
	_on_play()


func _event_results_spec(r: Dictionary) -> Dictionary:
	var e: Dictionary = event_run.event
	var i: int = event_run.index
	var c: Dictionary = e.challenges[i]
	var stats: Array = r.get("stats", []).duplicate()
	stats.append(["GOAL", ModeRegistry.format_record(c.mode, int(c.goal))])
	return {
		"title": str(c.title).to_upper(),
		"value_text": mode.format_value(int(r.score)),
		"badge": "CHALLENGE CLEARED!" if Events.is_cleared(e, i) else "",
		"stats": stats,
		"extras": [UiStyle.label("%s · %d / %d cleared" % [e.name, Events.cleared_count(e), (e.challenges as Array).size()], 24, UiStyle.GOLD)],
		"primary": ["TRY AGAIN", _on_play],
		"links": [["ALL CHALLENGES", Color(1, 1, 1, 0.8), func() -> void:
			_leave_results(func() -> void:
				_enter_idle()
				event_panel.open(), "results_to_menu")]],
	}


# --- Pass & play (US-40) ---------------------------------------------------------------
# Everyone plays the same seeded challenge in turn; party runs never touch the
# personal records or the daily.

func start_party(mode_id: String, names: Array) -> void:
	party = {"mode": mode_id, "seed": randi(), "players": [], "turn": 0}
	for n in names:
		party.players.append({"name": n, "score": 0, "done": false})
	start_mode(mode_id)
	party_pass.show_for(party.players[0].name, "")


func _party_turn() -> void:
	board.reset_all()
	state = GameState.IDLE  # _on_play starts from the menu state
	_on_play()


func _party_finished(r: Dictionary) -> void:
	var p: Dictionary = party.players[party.turn]
	p.score = int(r.score)
	p.done = true
	var last := "%s: %s" % [p.name, mode.format_value(int(r.score))]
	party.turn += 1
	await get_tree().create_timer(1.2).timeout
	if party.turn < party.players.size():
		party_pass.show_for(party.players[party.turn].name, last)
	else:
		_party_ranking()


func _party_ranking() -> void:
	var order: Array = party.players.duplicate()
	var lower := mode.lower_is_better()
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var va := int(a.score)
		var vb := int(b.score)
		if lower:  # 0 = no valid time: last
			return (va > 0 and (vb <= 0 or va < vb))
		return va > vb)
	var rows := []
	for i in order.size():
		rows.append({"name": order[i].name, "value_text": mode.format_value(int(order[i].score)), "rank": i + 1})
	for k in 3:
		effects.burst(board.bubbles[randi() % board.bubbles.size()].position, UiStyle.GOLD, 40, 1.6)
	Sfx.play_go()
	Platform.haptic(Platform.Haptic.HEAVY)
	party_ranking.show_ranking(rows)


# --- Interstitials (US-33) -------------------------------------------------------------

var _leaving_results := false

# --- Battery (US-35): idle screens drop to 30 fps until the next touch. ---
const IDLE_FPS := 30
const IDLE_AFTER := 6.0
var _idle_time := 0.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenDrag:
		_idle_time = 0.0
		if Engine.max_fps != 0:
			Engine.max_fps = 0  # back to the display rate (120 Hz on ProMotion)


func _tick_battery(delta: float) -> void:
	var calm := state == GameState.IDLE or state == GameState.RESULTS or state == GameState.PAUSED
	if not calm:
		_idle_time = 0.0
		if Engine.max_fps != 0:
			Engine.max_fps = 0
		return
	_idle_time += delta
	if _idle_time > IDLE_AFTER and Engine.max_fps != IDLE_FPS:
		Engine.max_fps = IDLE_FPS


## Results → menu / next run is the only place an interstitial may appear;
## AdRules (data/ads.json) decides whether it actually does.
func _leave_results(next: Callable, placement: String) -> void:
	if _leaving_results or state != GameState.RESULTS:
		return
	_leaving_results = true
	var st := SaveData.section("ads")
	var cfg: Dictionary = GameMode.load_config("res://data/ads.json").get("interstitial", {})
	var ctx := {
		"sessions": int(SaveData.section("stats").sessions),
		"session_runs": SaveData.session_runs,
		"premium": Platform.ads_disabled(),
		"is_record": _last_is_new,
		"first_run_of_mode": int(SaveData.mode_stats(mode.mode_id).played) <= 1,
		"rewarded": _rewarded_this_break,
		"placement": placement,
		"now": int(Time.get_unix_time_from_system()),
	}
	if AdRules.may_show(cfg, st, ctx) and await Platform.maybe_show_interstitial(placement):
		st.runs_since = 0
		st.last_shown = ctx.now
		SaveData.mark_dirty()
	_rewarded_this_break = false
	next.call()
	_leaving_results = false


# --- Rewarded placements (US-32) --------------------------------------------------------
# Always optional and only shown when an ad is actually available.
# Choice for records (US-32): a run extended with "continue" still counts as a
# personal best, marked "continued".

func _add_rewarded_links(spec: Dictionary) -> void:
	var links: Array = spec.get("links", [])
	var r := _last_results
	if daily.is_empty():
		var offer := mode.continue_offer(r)
		if offer != "" and Platform.can_show_rewarded("continue"):
			links.push_front(["▶ CONTINUE  " + offer, UiStyle.OK, _rewarded_continue])
	elif daily.official and not Daily.can_play_official(int(daily.day)) and Daily.extra_attempts(int(daily.day)) == 0 \
			and not bool(SaveData.section("daily").get("retry_used", {}).get(str(daily.day), false)) \
			and Platform.can_show_rewarded("daily_retry"):
		links.push_front(["▶ ONE MORE OFFICIAL TRY", UiStyle.OK, _rewarded_daily_retry])
	spec.links = links


func _rewarded_continue() -> void:
	if state != GameState.RESULTS:
		return
	var ok: bool = await Platform.show_rewarded("continue")
	_rewarded_this_break = true
	if not ok or state != GameState.RESULTS:
		return
	var r := _last_results
	if mode.mode_id != "stage":
		SaveData.undo_last_result(mode.mode_id, int(r.score), float(r.get("duration", 0.0)), _prev_best)
	else:
		SaveData.undo_last_result("stage", SaveData.total_stars(), float(r.get("duration", 0.0)), SaveData.get_best("stage"))
	mode.continue_run()
	hud.show_resume()
	board.attract = false
	_begin_countdown(true)


func _rewarded_daily_retry() -> void:
	var ok: bool = await Platform.show_rewarded("daily_retry")
	_rewarded_this_break = true
	if not ok:
		return
	var d := SaveData.section("daily")
	var key := str(daily.day)
	var used: Dictionary = d.get("retry_used", {})
	used[key] = true
	d.retry_used = used
	var extras: Dictionary = d.get("extra_attempts", {})
	extras[key] = int(extras.get(key, 0)) + 1
	d.extra_attempts = extras
	SaveData.mark_dirty()
	daily.erase("practice")
	_on_play()


## Premium theme / bubble style / sound pack for 24 h (style sheet).
func rewarded_style_trial(kind: String, id: String) -> bool:
	var ok: bool = await Platform.show_rewarded("style_trial")
	if ok:
		SaveData.section("unlocks").trials[ThemeManager.trial_key(kind, id)] = int(Time.get_unix_time_from_system()) + 86400
		SaveData.mark_dirty()
		Platform.entitlements_changed.emit()
	return ok


## A locked Premium level, played once after a video. The pass covers exactly
## one run: RETRY / NEXT afterwards go through the lock again.
var _level_pass := 0


func _rewarded_level_trial(level_id: int) -> void:
	var ok: bool = await Platform.show_rewarded("level_trial")
	_rewarded_this_break = true  # no interstitial right after this video
	if not ok:
		return
	premium_panel.close()
	_level_pass = level_id
	_play_stage(level_id)


# --- Premium & upsell (US-29) ---------------------------------------------------------

## Solicited: the player tapped something locked or "Premium" — always allowed.
func open_premium(context := "menu", level_id := 0) -> void:
	if state == GameState.PLAYING or state == GameState.COUNTDOWN or state == GameState.PAUSED:
		return
	for m in [stats_panel, stage_select, settings]:
		if (m as Modal).visible:
			(m as Modal).close()
	# Only offer the one-off run when the level is reachable by progress.
	premium_panel.open_for(context, level_id if level_id > 0 and StageLevels.is_unlocked(level_id) else 0)


## Unsolicited offer after a record or level 12: never mid-run, never at start,
## never for Premium owners, and at most once per session.
func _maybe_upsell(context: String) -> void:
	if Premium.active() or _upsell_shown or Platform.product("premium_unlock").is_empty():
		return
	_upsell_shown = true
	await get_tree().create_timer(1.3).timeout
	if state != GameState.RESULTS or _modal_open():
		return
	premium_panel.open_for(context)



func _on_style_locked(kind: String, _id: String, unlock: String, unlock_ref: String) -> void:
	if unlock == "premium":
		theme_picker.close()
		open_premium("locked_item")


## Purchases unlock immediately: refresh whatever is on screen.
func _on_entitlements_changed() -> void:
	if state == GameState.RESULTS and not _last_results.is_empty():
		hud.show_results(_decorate_results(_results_spec(_last_results, _last_is_new)))
	elif state == GameState.IDLE:
		_enter_idle()


func _open_stats() -> void:
	if state == GameState.IDLE or state == GameState.RESULTS:
		stats_panel.open()


func _open_settings() -> void:
	if state == GameState.IDLE or state == GameState.RESULTS:
		settings.open()


## The board never receives touches through an open overlay.
func _sync_board_input() -> void:
	var locked := _mode_locked and state == GameState.PLAYING
	board.input_enabled = not _modal_open() and not locked and state != GameState.RESULTS and state != GameState.PAUSED


func _modal_open() -> bool:
	for c in ui.get_children():
		if c is Modal and (c as Modal).is_open():
			return true
	return false


## PLAY in the menu: Stage Mode first asks which level.
func _on_menu_play() -> void:
	if theme_picker.visible:
		return
	if state == GameState.IDLE and _party_selected and not _modal_open():
		party_setup.open_with(mode.mode_id)
		return
	if state == GameState.IDLE and mode.mode_id == "stage" and not _modal_open():
		stage_select.open()
		return
	_on_play()


func _on_play() -> void:
	if state == GameState.COUNTDOWN or state == GameState.PLAYING or state == GameState.PAUSED or _modal_open():
		return
	if state == GameState.RESULTS and not _leaving_results:
		_leave_results(_on_play, "results_to_next")
		return
	Sfx.play_pop(4)
	Platform.haptic(Platform.Haptic.MEDIUM)
	board.attract = false
	if state == GameState.IDLE and daily.is_empty() and event_run.is_empty():
		SaveData.set_setting("last_mode", mode.mode_id)
	mode.context = _context_for(mode.mode_id)
	_apply_board_size()
	hud.configure_for(mode)
	board.reset_all()
	hud.show_countdown()
	hud.set_time(mode.get_duration(), mode.get_duration())
	_begin_countdown(false)


func _begin_countdown(resumes: bool) -> void:
	state = GameState.COUNTDOWN
	board.layout(_board_area(), true)
	_count_resumes = resumes
	_count_beat = 3
	_count_left = COUNT_STEP
	_sync_board_input()
	_beat(3)


func _tick_countdown(delta: float) -> void:
	_count_left -= delta
	if _count_left > 0.0:
		return
	_count_beat -= 1
	_count_left = COUNT_STEP
	if _count_beat > 0:
		_beat(_count_beat)
		return
	hud.banner("GO!", UiStyle.CYAN, 170, 0.15)
	Sfx.play_go()
	Platform.haptic(Platform.Haptic.MEDIUM)
	state = GameState.PLAYING
	_sync_board_input()
	hud.set_pause_visible(true)
	if _count_resumes:
		mode.set_paused(false)
	else:
		board.sweep()
		_last_second = -1
		if not daily.is_empty():
			daily.official = not daily.get("practice", false) and Daily.can_play_official(int(daily.day))
			if daily.official:
				Daily.begin_official(int(daily.day))
		mode.start()


func _beat(n: int) -> void:
	hud.banner(str(n), Color.WHITE, 170, 0.2)
	Sfx.play_tick()
	Platform.haptic(Platform.Haptic.LIGHT)


func pause() -> void:
	if state != GameState.PLAYING and state != GameState.COUNTDOWN:
		return
	# A countdown interrupted before GO restarts as a fresh run countdown.
	var was_running := state == GameState.PLAYING or _count_resumes
	_count_resumes = was_running
	state = GameState.PAUSED
	mode.set_paused(true)
	hud.set_pause_visible(false)
	for b in board.bubbles:
		b.release()
	board.release_touches()
	pause_overlay.open()
	_sync_board_input()


func _resume() -> void:
	if state != GameState.PAUSED:
		return
	_begin_countdown(_count_resumes)


func _quit_run() -> void:
	if state != GameState.PAUSED:
		return
	party = {}
	mode.stop()
	board.reset_all()
	_clear_coach()
	_enter_idle()


func _on_bubble_pressed(b: Bubble) -> void:
	match state:
		GameState.IDLE:
			_fidget(b)
		GameState.PLAYING:
			mode.on_bubble_pressed(b)


## Outside a game the board is a pure fidget toy: every bubble pops.
func _fidget(b: Bubble) -> void:
	b.pop()
	effects.burst(b.position, b.color, 14, 0.8)
	effects.ring(b.position, b.color, b.radius, b.radius * 1.8, 0.3, 6.0)
	Sfx.play_pop(randi_range(0, 6), 0.03)
	Platform.haptic(Platform.Haptic.LIGHT)
	_accent_target = b.color
	if not SaveData.get_flag("hint_fidget_done"):
		SaveData.set_flag("hint_fidget_done")
		_update_menu_hint()
	Achievements.add("fidget_pops")


# --- Mode events → presentation ---------------------------------------------

func _on_target_lit(b: Bubble) -> void:
	if SaveData.get_flag("hint_tap_done") or _coach != null:
		return
	_coach = HintMarker.new()
	_coach.point_at(b, "TAP THE GLOWING BUBBLE")
	world.add_child(_coach)


## The first successful action ends the coach marks for good.
func _hint_success() -> void:
	if not SaveData.get_flag("hint_tap_done"):
		SaveData.set_flag("hint_tap_done")
	_clear_coach()


func _clear_coach() -> void:
	if _coach != null and is_instance_valid(_coach):
		_coach.dismiss()
	_coach = null


func _on_hit(b: Bubble, points: int, reaction: float) -> void:
	_hint_success()
	var c := mode.combo
	effects.burst(b.position, b.color, 16 + mini(c, 24), 1.0 + minf(c * 0.03, 0.8))
	effects.ring(b.position, b.color, b.radius * 0.9, b.radius * (2.0 + minf(c * 0.05, 1.0)), 0.35, 8.0)
	if points > 0:
		effects.float_text(b.position + Vector2(0, -b.radius * 0.4), "+%d" % points, b.color.lightened(0.35), 44)
	if mode.uses_score() and reaction < 0.4:
		effects.float_text(b.position + Vector2(0, b.radius * 0.9), "%d ms" % int(reaction * 1000.0), Color(1, 1, 1, 0.85), 24)
	# Combos climb the scale; past the top, cycle the upper notes.
	if mode.hit_sound():
		var steps := Sfx.pop_steps()
		var note: int = c - 1 if c <= steps else steps - 5 + (c - 1) % 5
		Sfx.play_pop(note if mode.uses_combo() else 4)
	Platform.haptic(Platform.Haptic.LIGHT)
	_accent_target = b.color


## Facts a mode may need before it starts (it never reads the save itself).
func _context_for(mode_id: String) -> Dictionary:
	var stats := SaveData.mode_stats(mode_id)
	if mode_id == "stage":
		stage_level = clampi(stage_level, 1, StageLevels.count())
	var ctx := {
		"best": int(stats.best),
		"best_single": int(stats.get("best_single", 0)),
		"played": int(stats.played),
		"level_id": stage_level,
		"first_run": int(stats.played) == 0 and daily.is_empty(),
	}
	if not daily.is_empty():
		ctx.seed = int(daily.challenge.seed)  # same spawn sequence for everyone today
	elif not event_run.is_empty():
		ctx.seed = Events.seed_for(event_run.event, int(event_run.index))
		ctx.first_run = false
	elif not party.is_empty():
		ctx.seed = int(party.seed)  # pass & play: every player gets the same run
		ctx.first_run = false
	return ctx


func _on_announce(text: String, kind: String) -> void:
	match kind:
		"bad":
			hud.set_subline(text, UiStyle.DANGER)
			if not mode.uses_combo():
				hud.banner(text, UiStyle.DANGER, 90, 0.35)
		"good":
			hud.set_subline(text, UiStyle.CYAN)
		"best":
			hud.set_subline(text, UiStyle.GOLD)
		_:
			hud.set_subline(text, Color(1, 1, 1, 0.6))


func _on_reaction(b: Bubble, ms: int, personal_best: bool) -> void:
	hud.set_headline("%d ms" % ms, UiStyle.GOLD if personal_best else Color.WHITE)
	effects.float_text(b.position + Vector2(0, -b.radius * 0.5), "%d ms" % ms, Color.WHITE, 46)
	if personal_best:
		hud.banner("PERSONAL BEST", UiStyle.GOLD, 84, 0.5)
		hud.set_subline("FASTEST EVER", UiStyle.GOLD)
		for i in 3:
			effects.ring(b.position, UiStyle.GOLD, b.radius, b.radius * (2.5 + i), 0.5 + i * 0.12, 10.0 - i * 2.0)
		effects.burst(b.position, UiStyle.GOLD, 40, 1.6)
		Sfx.play_go()
		Platform.haptic(Platform.Haptic.HEAVY)
		_shake = maxf(_shake, 9.0)
		SaveData.mode_stats(mode.mode_id)["best_single"] = ms
		SaveData.mark_dirty()
	else:
		hud.set_subline("WAIT…", Color(1, 1, 1, 0.6))


func _on_cue(b: Bubble, note: int) -> void:
	Sfx.play_pop(note)
	effects.ring(b.position, b.color, b.radius, b.radius * 1.6, 0.3, 6.0)
	_accent_target = b.color
	if state == GameState.PLAYING and not _mode_locked:
		Platform.haptic(Platform.Haptic.LIGHT)


func _on_input_locked(locked: bool) -> void:
	_mode_locked = locked
	if locked:
		board.release_touches()
	_sync_board_input()


func _on_multiplier_up(mult: int) -> void:
	hud.banner("x%d" % mult, hud.mult_color(mult), 130, 0.15)
	Sfx.play_go()
	Platform.haptic(Platform.Haptic.MEDIUM)
	_shake = maxf(_shake, 7.0)


func _on_wrong(b: Bubble, penalty: int) -> void:
	effects.float_text(b.position, "-%d" % penalty if penalty > 0 else "MISS", UiStyle.DANGER, 40)
	Sfx.play_miss()
	Platform.haptic(Platform.Haptic.ERROR)
	_shake = maxf(_shake, 12.0)


func _on_missed(b: Bubble) -> void:
	effects.ring(b.position, Color(1, 0.3, 0.3, 0.6), b.radius, b.radius * 1.3, 0.25, 4.0)
	Sfx.play_expire()


func _on_combo_broken(previous: int) -> void:
	if previous >= 5:
		hud.combo_lost()


func _on_time(remaining: float, total: float) -> void:
	hud.set_time(remaining, total)
	var s := int(ceil(remaining))
	if s <= 5 and s > 0 and s != _last_second:
		_last_second = s
		Sfx.play_tick()


func _on_finished(results: Dictionary) -> void:
	state = GameState.RESULTS
	_clear_coach()
	if not party.is_empty():
		hud.set_pause_visible(false)
		_sync_board_input()
		hud.banner(_end_banner(results), Color.WHITE, 150, 0.3)
		Sfx.play_go()
		_party_finished(results)
		return
	hud.set_pause_visible(false)
	_sync_board_input()
	var is_new := false
	if not event_run.is_empty():
		Events.submit(event_run.event, int(event_run.index), int(results.score))
	_prev_best = SaveData.get_best(mode.mode_id)
	if not event_run.is_empty():
		pass  # event challenges have their own progress; no mode records
	elif not daily.is_empty():
		if daily.official:
			Daily.record(int(daily.day), int(results.score), mode.lower_is_better(), mode.mode_id)
			var before := Daily.current_streak()
			var after := Daily.complete_day(int(daily.day))
			daily.streak = after
			daily.milestone = after != before and Daily.is_milestone(after)
	elif mode.mode_id == "stage":
		is_new = _record_stage(results)
	else:
		is_new = SaveData.submit_result(mode.mode_id, int(results.score), mode.lower_is_better(), float(results.get("duration", mode.elapsed)))
		if is_new:
			SaveData.mode_stats(mode.mode_id)["best_continued"] = bool(results.get("continued", false))
	var single := int(results.get("best_single", 0))
	if single > 0:
		var stats := SaveData.mode_stats(mode.mode_id)
		if int(stats.get("best_single", 0)) == 0 or single < int(stats.best_single):
			stats["best_single"] = single
	hud.set_best_text(_best_text())
	Achievements.on_run_finished(mode.mode_id, results)
	Platform.start_ads_after_first_game()  # consent → ATT → ads, once, after the first game
	var ads_state := SaveData.section("ads")
	ads_state.runs_since = int(ads_state.get("runs_since", 0)) + 1
	SaveData.session_runs += 1
	hud.banner(_end_banner(results), Color.WHITE, 150, 0.3)
	Sfx.play_go()
	Platform.haptic(Platform.Haptic.HEAVY)
	_shake = maxf(_shake, 8.0)
	await get_tree().create_timer(0.7).timeout
	if state != GameState.RESULTS:
		return
	board.attract = true
	_last_results = results
	_last_is_new = is_new
	hud.show_results(_decorate_results(_results_spec(results, is_new)))
	# Upsell moments (US-29): a beaten record (not the very first run) or clearing level 12.
	if daily.is_empty() and event_run.is_empty():
		if mode.mode_id == "stage" and bool(results.get("won", false)) and int(results.level_id) == Premium.FREE_STAGE_LEVELS:
			_maybe_upsell("level12")
		elif is_new and int(SaveData.mode_stats(mode.mode_id).played) > 1:
			_maybe_upsell("record")


func _decorate_results(spec: Dictionary) -> Dictionary:
	_add_rewarded_links(spec)
	var actions: Array = spec.get("actions", [])
	actions.append(["share", _share_result])
	spec.actions = actions
	return spec


# --- Share (US-20) ----------------------------------------------------------------

func _share_result() -> void:
	var r := _last_results
	var info := ModeRegistry.info(mode.mode_id)
	var value := mode.format_value(int(r.score))
	var mode_name: String = "DAILY CHALLENGE" if not daily.is_empty() else str(info.get("name", "")) + (" MODE" if mode.mode_id != "stage" else "")
	var caption := str(r.get("title", ""))
	if r.has("won"):
		value = "LEVEL %d" % int(r.level_id)
		caption = "%d ★  ·  %.1fs" % [int(r.stars), float(r.time)]
	var challenge := share_text(mode.mode_id, int(r.score), r)
	var img: Image = await ShareCard.render(self, {
		"mode_name": mode_name,
		"value_text": value,
		"caption": caption,
		"is_record": _last_is_new,
		"color": info.get("color", UiStyle.ACCENT),
		"footer": challenge,
	})
	Platform.share_image(img, challenge + " " + AppInfo.HASHTAG, not _headless_share)


var _headless_share := false  # dev scenarios: don't open Finder


func share_text(mode_id: String, value: int, r: Dictionary) -> String:
	match mode_id:
		"reflex":
			return "Can you beat %d ms?" % value
		"memory":
			return "Can you remember %d steps?" % (value + 1)
		"stage":
			return "Can you clear level %d with 3 stars?" % int(r.get("level_id", 1))
		_:
			return "Can you beat %s points?" % Hud.fmt(value)


func _end_banner(r: Dictionary) -> String:
	if r.has("won"):
		return "CLEAR!" if r.won else "FAILED"
	return "TIME!" if mode.uses_timer() else "DONE!"


## Stage results: best stars + best time per level; the mode record is total stars.
func _record_stage(r: Dictionary) -> bool:
	var improved := false
	if bool(r.won):
		improved = SaveData.set_stars(int(r.level_id), int(r.stars))
		var times: Dictionary = SaveData.section("stage").best_time
		var key := str(r.level_id)
		if not times.has(key) or float(r.time) < float(times[key]):
			times[key] = snappedf(float(r.time), 0.01)
	SaveData.submit_result("stage", SaveData.total_stars(), false, float(r.duration))
	return improved


func _stage_results_spec(r: Dictionary, is_new: bool) -> Dictionary:
	var won := bool(r.won)
	var lvl := int(r.level_id)
	var has_next := won and lvl < StageLevels.count()
	var spec := {
		"title": r.title,
		"value_text": "" if won else "%d/%d" % [int(r.hits), int(StageLevels.get_level(lvl).get("goal", 0))],
		"value_color": UiStyle.DANGER,
		"badge": "NEW BEST!" if is_new and int(r.stars) > 1 else "",
		"stats": r.stats,
		"extras": [StarsRow.new(int(r.stars))] if won else [],
		"links": [],
	}
	if has_next and Premium.stage_level_locked(lvl + 1):
		spec.primary = ["NEXT LEVEL  ♛", open_premium.bind("level12", lvl + 1)]
		spec.links.append(["RETRY", UiStyle.CYAN, _play_stage.bind(lvl)])
	elif has_next:
		spec.primary = ["NEXT LEVEL", _play_stage.bind(lvl + 1)]
		spec.links.append(["RETRY", UiStyle.CYAN, _play_stage.bind(lvl)])
	else:
		spec.primary = ["RETRY", _play_stage.bind(lvl)]
	spec.links.append(["ALL LEVELS", Color(1, 1, 1, 0.8), _open_stage_select])
	return spec


func _open_stage_select() -> void:
	_leave_results(func() -> void:
		_enter_idle()
		stage_select.open(), "results_to_menu")


func _play_stage(level_id: int) -> void:
	if Premium.stage_level_locked(level_id) and _level_pass != level_id:
		open_premium("locked_item", level_id)
		return
	if not StageLevels.is_unlocked(level_id):
		return
	_level_pass = 0  # used up by this run
	stage_level = level_id
	_on_play()


func _daily_results_spec(r: Dictionary) -> Dictionary:
	var official: bool = daily.official
	var stats: Array = r.get("stats", []).duplicate()
	var best := Daily.result(int(daily.day))
	if not official and not best.is_empty() and not bool(best.get("pending", false)):
		stats.append(["OFFICIAL", ModeRegistry.format_record(mode.mode_id, int(best.score))])
	return {
		"title": "DAILY CHALLENGE" if official else "DAILY · PRACTICE",
		"value_text": mode.format_value(int(r.score)),
		"badge": "OFFICIAL SCORE SAVED" if official else "Practice doesn't count",
		"stats": stats,
		"extras": [UiStyle.label(str(daily.challenge.title), 24, Color(1, 1, 1, 0.6)), StreakBurst.new(Daily.current_streak(), official and bool(daily.get("milestone", false)))] if Daily.current_streak() > 0 else [UiStyle.label(str(daily.challenge.title), 24, Color(1, 1, 1, 0.6))],
		"primary": ["PRACTICE", _practice_daily],
	}


func _practice_daily() -> void:
	daily.practice = true
	_on_play()


func _results_spec(r: Dictionary, is_new: bool) -> Dictionary:
	if not event_run.is_empty():
		return _event_results_spec(r)
	if not daily.is_empty():
		return _daily_results_spec(r)
	if r.has("won"):
		return _stage_results_spec(r, is_new)
	return {
		"title": r.get("title", "RESULT"),
		"value_text": mode.format_value(int(r.score)),
		"badge": ("NEW BEST! (continued)" if bool(r.get("continued", false)) else "NEW BEST!") if is_new else "",
		"stats": r.get("stats", []),
		"extras": _result_extras(r),
		"primary": ["PLAY AGAIN", _on_play],
	}


## Mode-specific widgets under the stats (presentation lives here, not in modes).
func _result_extras(_r: Dictionary) -> Array:
	var out := []
	if mode.mode_id == "reflex" and Premium.reflex_stats_locked():
		var teaser := UiStyle.ghost_button("SEE YOUR GRAPH & TREND  ·  PREMIUM", UiStyle.GOLD, 22)
		teaser.pressed.connect(open_premium.bind("locked_item"))
		out.append(teaser)
	elif mode.mode_id == "reflex":
		var stats := SaveData.mode_stats("reflex")
		var recent: Array = stats.recent
		var best := int(stats.best)
		out.append(ReflexGraph.new(recent.duplicate(), best))
		var sm := ReflexGraph.summary(recent, best)
		var trend := int(sm.trend)
		var trend_text := "→ steady"
		var trend_col := Color(1, 1, 1, 0.6)
		if trend < -2:
			trend_text = "↑ %d ms faster" % -trend
			trend_col = UiStyle.OK
		elif trend > 2:
			trend_text = "↓ %d ms slower" % trend
			trend_col = UiStyle.DANGER
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 26)
		row.add_child(UiStyle.label("BEST %s" % mode.format_value(best), 24, UiStyle.GOLD))
		row.add_child(UiStyle.label("LAST 10 %s" % mode.format_value(int(sm.avg10)), 24, Color.WHITE))
		row.add_child(UiStyle.label(trend_text, 24, trend_col))
		out.append(row)
	return out


func _best_text() -> String:
	var best := _record_value(mode.mode_id)
	return mode.format_value(best) if best != 0 else "-"


## The number shown as "record" for a mode (Stage: total stars).
func _record_value(mode_id: String) -> int:
	return SaveData.total_stars() if mode_id == "stage" else SaveData.get_best(mode_id)

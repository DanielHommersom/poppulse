extends Node
## Dev-only scripted scenarios for visual checks. Saves PNGs to res://_capture/.
## Run:  Godot --path . res://tools/scenario.tscn -- --scenario=settings [--fake-notch]

var main: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://_capture"))
	var scenario := "idle"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scenario="):
			scenario = a.get_slice("=", 1)
		if a.begins_with("--size="):
			var wh := a.get_slice("=", 1).split("x")
			get_window().size = Vector2i(int(wh[0]), int(wh[1]))
	# Scenarios run with --test-save (throw-away slot); --fresh wipes it first (SaveData).
	main = load("res://main.tscn").instantiate()
	main.auto_pause = false
	add_child(main)
	await wait(0.05 if scenario == "splash" else 0.8)
	if has_method("s_" + scenario):
		await call("s_" + scenario)
	else:
		push_error("unknown scenario " + scenario)
	get_tree().quit()


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://_capture/%s.png" % label)
	print("captured ", label)


func tap_bubble(b) -> void:
	main.board.last_press_usec = Time.get_ticks_usec()
	b.press_down()
	main._on_bubble_pressed(b)
	b.release()


# --- Scenarios ---------------------------------------------------------------

func s_idle() -> void:
	await shot("idle")


func s_settings() -> void:
	main._open_settings()
	await wait(0.5)
	await shot("settings")


func s_debug_modal() -> void:
	main._open_settings()
	await wait(0.5)
	var m = main.settings
	print("modal size ", m.size, " pos ", m.position, " dim ", m._dim.size, " vis ", m._dim.visible, " a ", m.modulate.a)


func s_pause() -> void:
	main._on_play()
	await wait(2.0)
	for i in 6:
		for b in main.mode._active.duplicate():
			tap_bubble(b)
			break
		await wait(0.15)
	var before: float = main.mode.elapsed
	main.pause()
	await wait(0.4)
	await shot("pause_overlay")
	await wait(1.0)
	print("frozen elapsed: ", is_equal_approx(before, main.mode.elapsed), " state=", main.state)
	main.pause_overlay._resume()
	await wait(0.6)
	await shot("pause_resume_countdown")
	print("during countdown elapsed still frozen: ", is_equal_approx(before, main.mode.elapsed))
	await wait(1.2)
	print("after countdown state=", main.state, " running advances: ", main.mode.elapsed > before)
	main._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	print("focus out -> state=", main.state)
	main.auto_pause = true
	main._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	print("focus out (auto) -> state=", main.state, " (3=PAUSED)")
	main.pause_overlay._quit()
	await wait(0.4)
	print("after quit state=", main.state)
	await shot("pause_quit_idle")


func s_tuning() -> void:
	var tuning: Node = null
	for c in main.get_children():
		if c.get_script() and str(c.get_script().resource_path).ends_with("tuning_overlay.gd"):
			tuning = c
	print("overlay present: ", tuning != null)
	main._on_play()
	await wait(2.0)
	# three-finger tap
	for i in 3:
		var t := InputEventScreenTouch.new()
		t.index = i
		t.position = Vector2(100 + i * 50, 100)
		t.pressed = true
		Input.parse_input_event(t)
	await wait(0.2)
	for i in 3:
		var t := InputEventScreenTouch.new()
		t.index = i
		t.position = Vector2(100 + i * 50, 100)
		t.pressed = false
		Input.parse_input_event(t)
	await wait(0.3)
	print("panel visible: ", tuning._panel.visible)
	var before: float = main.mode.cfg.start.spawn_interval if main.mode.cfg.has("start") else -1.0
	# Move the first slider found
	var sl: HSlider = tuning._list.find_children("*", "HSlider", true, false)[2]
	sl.value = sl.min_value
	print("cfg changed live: ", JSON.stringify(main.mode.cfg).left(160))
	await shot("tuning_overlay")
	tuning._export()
	print("clipboard has json: ", DisplayServer.clipboard_get().begins_with("{"))


## Full Score Mode regression run: combo, wrong tap, results.
func s_score() -> void:
	main.start_mode("score")  # re-entrant: old mode must be cleaned up
	main.start_mode("score")
	print("modes alive: ", main.get_children().filter(func(c): return c is GameMode).size())
	main._on_play()
	await wait(2.0)
	for i in 30:
		for b in main.mode._active.duplicate():
			tap_bubble(b)
			break
		await wait(0.1)
	await shot("score_playing")
	for b in main.board.bubbles:
		if b.state == Bubble.State.IDLE and not (b in main.mode._active):
			tap_bubble(b)
			break
	main.mode.elapsed = main.mode.get_duration() - 0.05
	await wait(1.6)
	await shot("score_results")
	print("state=", main.state, " best=", SaveData.get_best("score"))


func s_reflex() -> void:
	main.hud.menu._on_card("reflex")
	await wait(0.4)
	await shot("reflex_menu")
	main._on_play()
	await wait(1.6)
	# early tap
	tap_bubble(main.board.bubbles[0])
	await wait(0.2)
	await shot("reflex_early")
	var n := 0
	while main.state == main.GameState.PLAYING and n < 3000:
		n += 1
		var m = main.mode
		if m.phase == m.Phase.LIT and m._lit_usec > 0:
			await wait(randf_range(0.18, 0.3))
			if m._target:
				tap_bubble(m._target)
			if m.times.size() == 3:
				await wait(0.05)
				await shot("reflex_hit")
		await wait(0.02)
	await wait(1.2)
	await shot("reflex_results")
	print("times=", main.mode.times, " best=", SaveData.get_best("reflex"), " best_single=", SaveData.mode_stats("reflex").get("best_single"))


## Seeds 14 historic reflex rounds, then shows the results card with graph.
func s_reflex_history() -> void:
	var st: Dictionary = SaveData.mode_stats("reflex")
	st.recent = [330, 318, 322, 301, 296, 305, 288, 279, 284, 270, 266, 271, 259, 252]
	st.best = 252
	st.played = 14
	main.hud.menu._on_card("reflex")
	await wait(0.3)
	main._on_play()
	await wait(1.5)
	var m = main.mode
	var n := 0
	while main.state == main.GameState.PLAYING and n < 3000:
		n += 1
		if m.phase == m.Phase.LIT and m._lit_usec > 0:
			await wait(randf_range(0.2, 0.24))
			if m._target:
				tap_bubble(m._target)
		await wait(0.02)
	await wait(1.3)
	await shot("reflex_history")


## Plays memory perfectly for 3 rounds, then taps wrong.
func s_memory() -> void:
	main.hud.menu._on_card("memory")
	await wait(0.4)
	main._on_play()
	await wait(1.5)
	var m = main.mode
	var rounds := 0
	while main.state == main.GameState.PLAYING and rounds < 4:
		while m.phase != m.Phase.INPUT:
			await wait(0.05)
			if m.phase == m.Phase.SHOW and m._step == 2 and rounds == 1:
				await shot("memory_show")
		print("round ", m._round, " pattern ", m.pattern, " input_enabled=", main.board.input_enabled)
		if rounds == 3:
			await shot("memory_your_turn")
			var wrong = main.board.bubbles[(m.pattern[0] + 1) % 9]
			tap_bubble(wrong)
			break
		for idx in m.pattern:
			tap_bubble(main.board.bubbles[idx])
			await wait(0.15)
		rounds += 1
	await wait(1.0)
	await shot("memory_replay")
	while main.state == main.GameState.PLAYING:
		await wait(0.1)
	await wait(1.0)
	await shot("memory_results")
	print("best memory = ", SaveData.get_best("memory"))


func _play_stage_perfect(level_id: int, shot_name := "", miss_decoys := true) -> void:
	main.stage_level = level_id
	main._on_play()
	await wait(1.5)
	var m = main.mode
	var shot_done := false
	while main.state == main.GameState.PLAYING:
		for b in m._active.duplicate():
			if b.decoy and miss_decoys:
				if shot_name != "" and not shot_done:
					await shot(shot_name)
					shot_done = true
				continue
			tap_bubble(b)
			await wait(0.12)
			break
		await wait(0.05)
	await wait(1.6)


func s_stage() -> void:
	main.hud.menu._on_card("stage")
	await wait(0.4)
	await shot("stage_menu")
	await _play_stage_perfect(1)
	await shot("stage_clear")
	print("stars L1=", SaveData.get_stars(1), " total=", SaveData.total_stars())
	await _play_stage_perfect(3, "stage_decoy")
	await shot("stage3_clear")
	# fail level 2 by tapping wrong bubbles
	main.stage_level = 2
	main._on_play()
	await wait(1.6)
	for i in 6:
		for b in main.board.bubbles:
			if b.state == Bubble.State.IDLE and not (b in main.mode._active):
				tap_bubble(b)
				break
		await wait(0.2)
	await wait(1.6)
	await shot("stage_fail")
	print("stars=", SaveData.section("stage"))


func s_stage_select() -> void:
	for i in range(1, 13):
		SaveData.set_stars(i, 1 + (i % 3))
	main.hud.menu._on_card("stage")
	await wait(0.3)
	main._on_menu_play()
	await wait(0.6)
	await shot("stage_select")
	var sel = main.stage_select
	# simulate a scroll between press and release -> must not start
	sel._press_scroll = -100
	sel._on_cell(1)
	print("after scroll-tap state=", main.state, " open=", sel.visible)
	sel._press_scroll = sel.scroll.scroll_vertical
	sel._on_cell(3)
	await wait(0.3)
	print("after tap on 3: state=", main.state, " level=", main.stage_level)


func s_first_run() -> void:
	await shot("first_idle")
	tap_bubble(main.board.bubbles[7])
	await wait(0.3)
	await shot("first_after_fidget")
	main._on_play()
	await wait(1.7)
	while main.mode._active.is_empty():
		await wait(0.05)
	await wait(0.3)
	await shot("first_coach")
	print("first_run ctx=", main.mode.context.first_run, " interval@0=", main.mode._curve.value("spawn_interval", 0.0))
	tap_bubble(main.mode._active[0])
	await wait(0.4)
	print("coach gone=", main._coach == null, " flag=", SaveData.get_flag("hint_tap_done"))


func s_daily() -> void:
	await shot("daily_menu")
	main.start_daily()
	print("daily mode=", main.mode.mode_id, " title=", main.daily.challenge.title, " cfg dur=", main.mode.cfg.get("duration"))
	await wait(1.6)
	print("official=", main.daily.official, " seed ctx=", main.mode.context.get("seed"))
	# finish quickly
	main.mode.elapsed = 9999.0
	if main.mode.has_method("_finish"):
		if main.mode.mode_id == "score":
			pass
		else:
			main.mode._finish()
	await wait(1.5)
	await shot("daily_results")
	main._enter_idle()
	await wait(0.5)
	main._refresh_daily_card()
	await shot("daily_done_menu")
	print("can play official: ", Daily.can_play_official(Daily.today()), " mode back=", main.mode.mode_id)


func s_streak() -> void:
	var d := SaveData.section("daily")
	d.streak = 2
	d.last_day = Daily.today() - 1
	main._refresh_daily_card()
	await wait(0.2)
	await shot("streak_menu")
	main.start_daily()
	await wait(1.6)
	main.mode.elapsed = 9999.0
	if main.mode.mode_id != "score":
		main.mode._finish()
	await wait(2.4)
	await shot("streak_milestone")
	print("streak=", Daily.current_streak())


func s_stats() -> void:
	var st: Dictionary = SaveData.mode_stats("reflex")
	st.recent = [330, 318, 322, 301, 296, 305, 288, 279, 284, 270, 266, 271, 259, 252]
	st.best = 252
	st.best_single = 198
	st.played = 14
	st.time_played = 260.0
	SaveData.submit_result("score", 8420, false, 60)
	SaveData.submit_result("score", 6120, false, 60)
	SaveData.submit_result("memory", 9, false, 50)
	for i in range(1, 8):
		SaveData.set_stars(i, 2 + i % 2)
	var d := SaveData.section("daily")
	d.streak = 4
	d.best_streak = 9
	d.last_day = Daily.today()
	main._open_stats()
	await wait(0.5)
	await shot("stats")
	main.stats_panel.scroll.scroll_vertical = 2000
	await wait(0.3)
	await shot("stats_bottom")


func s_share() -> void:
	main._headless_share = true
	main.hud.menu._on_card("reflex")
	main._last_results = {"score": 198, "title": "AVERAGE"}
	main._last_is_new = true
	main._share_result()
	await wait(1.0)
	var p := ProjectSettings.globalize_path("user://share/poppulse_result.png")
	var img := Image.load_from_file(p)
	print("share png: ", img.get_size(), " clipboard: ", DisplayServer.clipboard_get())
	img.save_png("res://_capture/share_card.png")


func s_achievements() -> void:
	tap_bubble(main.board.bubbles[3])
	await wait(0.6)
	await shot("ach_toast")
	SaveData.submit_result("score", 12000, false, 60)
	Achievements.on_run_finished("score", {"best_combo": 30, "accuracy": 1.0, "hits": 45})
	print("unlocked: ", Achievements.unlocked_count(), " -> ", SaveData.section("achievements").unlocked.keys())
	await wait(8.0)
	main._open_stats()
	await wait(0.4)
	main.stats_panel.scroll.scroll_vertical = 5000
	await wait(0.3)
	await shot("ach_list")


## Deterministic look reference: attract shimmer frozen, fixed state.
func s_look() -> void:
	main.board.attract = false
	main.board.bubbles[7].light_up(true)
	main.board.bubbles[12].vis_lit = 0.6
	await wait(0.6)
	await shot("look_idle")
	main._open_stats()
	await wait(0.5)
	await shot("look_stats")


func s_themes() -> void:
	main._open_themes()
	await wait(0.6)
	await shot("themes_neon")
	var shots := ["sunset", "ice", "candy", "retro", "aurora", "galaxy"]
	for id in shots:
		for it in main.theme_picker._items():
			if it.id == id:
				main.theme_picker._select(it)
		tap_bubble(main.board.bubbles[8])
		await wait(0.5)
		await shot("themes_" + id)
	for it in main.theme_picker._items():
		if it.id == "sunset":
			main.theme_picker._select(it)
	main.theme_picker._on_use()
	await wait(0.5)
	print("saved theme=", SaveData.get_setting("theme"), " current=", ThemeManager.current.id)
	await shot("themes_applied_menu")


func s_designs() -> void:
	Achievements._state().unlocked["first_run"] = 1
	main._open_themes()
	main.theme_picker._set_tab("design")
	await wait(0.4)
	for d in ThemeManager.designs:
		var it := {}
		for x in main.theme_picker._items():
			if x.id == d.id:
				it = x
		main.theme_picker._select(it)
		main.board.bubbles[8].light_up(true)
		main.board.bubbles[13].vis_lit = 0.7
		main.board.bubbles[2].press_down()
		await wait(0.35)
		await shot("design_" + d.id)
		main.board.bubbles[8].expire()
		main.board.bubbles[2].release()
	# hitbox check: same bubble_at regardless of shape
	var p: Vector2 = main.board.bubbles[8].position + Vector2(main.board.bubbles[8].radius * 0.9, 0)
	print("hit with gem: ", main.board.bubble_at(p) == main.board.bubbles[8])


func s_sounds() -> void:
	for p in Sfx.packs():
		Sfx._load_pack(p.id)
		print(p.id, ": pops=", Sfx.pop_steps(), " len0=", Sfx._pops[0].data.size(), " go=", Sfx._go.data.size())
	# follow theme
	ThemeManager.apply("retro", true)
	print("retro theme -> pack ", Sfx.pack_id, " (retro is premium; arcade free)")
	ThemeManager.apply("neon", true)
	print("neon -> ", Sfx.pack_id)
	Sfx.set_pack("bubblewrap")
	ThemeManager.apply("sunset", true)
	print("explicit bubblewrap kept after theme change: ", Sfx.pack_id)
	main._open_settings()
	await wait(0.5)
	await shot("settings_sound")
	main.settings.close()
	await wait(0.4)
	main._open_themes()
	main.theme_picker._set_tab("sound")
	await wait(0.4)
	await shot("sounds_tab")


func s_premium() -> void:
	SaveData.section("unlocks").entitlements = {}
	for i in range(1, 13):
		SaveData.set_stars(i, 2)
	main.hud.menu._on_card("stage")
	await wait(0.3)
	main._on_menu_play()
	await wait(0.5)
	main.stage_select.scroll.scroll_vertical = 400
	await wait(0.2)
	await shot("premium_stage_locks")
	main.stage_select._press_scroll = main.stage_select.scroll.scroll_vertical
	main.stage_select._on_cell(14)
	await wait(0.6)
	print("premium panel open: ", main.premium_panel.visible)
	await shot("premium_panel")
	(Platform.store as MockStore).delay = 0.2
	main.premium_panel._on_buy()
	await wait(0.6)
	print("after buy: premium=", Premium.active(), " panel open=", main.premium_panel.visible, " level 14 locked=", Premium.stage_level_locked(14))
	main.stage_select.open()
	await wait(0.5)
	await shot("premium_stage_unlocked")
	# upsell once per session
	SaveData.section("unlocks").entitlements = {}
	main.stage_select.close()
	await wait(0.3)
	main._upsell_shown = false
	main.hud.menu._on_card("score")
	SaveData.submit_result("score", 100, false, 60)
	await wait(0.3)
	main._on_play()
	await wait(1.6)
	for i in 10:
		for b in main.mode._active.duplicate():
			tap_bubble(b)
			break
		await wait(0.12)
	main.mode.elapsed = 999
	await wait(2.6)
	print("record upsell shown: ", main.premium_panel.visible, " flag=", main._upsell_shown)
	await shot("premium_upsell_record")



func s_rewarded() -> void:
	SaveData.section("unlocks").entitlements = {}
	Platform.ads_started = true
	(Platform.ads as MockAds).duration = 0.3
	main.hud.menu._on_card("score")
	main._on_play()
	await wait(1.6)
	for i in 8:
		for b in main.mode._active.duplicate():
			tap_bubble(b)
			break
		await wait(0.12)
	var score_before: int = main.mode.score
	main.mode.elapsed = main.mode.get_duration() - 0.02
	await wait(1.4)
	await shot("rewarded_continue_offer")
	var played_before := int(SaveData.mode_stats("score").played)
	main._rewarded_continue()
	await wait(0.5)
	await wait(1.6)
	print("continued: state=", main.state, " remaining=", main.mode.get_duration() - main.mode.elapsed, " score kept=", main.mode.score == score_before, " played undone=", int(SaveData.mode_stats("score").played) == played_before - 1)
	main.mode.elapsed = main.mode.get_duration() - 0.02
	await wait(1.4)
	print("second finish: continued=", main._last_results.get("continued"), " offer again=", main.mode.continue_offer(main._last_results))
	await shot("rewarded_after_continue")
	main._enter_idle()
	await wait(0.3)
	# theme trial
	main._open_themes()
	for it in main.theme_picker._items():
		if it.id == "candy":
			main.theme_picker._select(it)
	await wait(0.3)
	print("trial btn visible=", main.theme_picker._trial.visible, " sheet=", main.theme_picker._sheet.get_rect(), " can=", Platform.can_show_rewarded("style_trial"))
	await shot("rewarded_theme_trial")
	main.theme_picker._on_trial()
	await wait(1.0)
	print("trial theme active: ", SaveData.get_setting("theme"), " available=", ThemeManager.is_available(ThemeManager.get_theme("candy")))


func s_interstitial() -> void:
	SaveData.section("unlocks").entitlements = {}
	SaveData.section("stats").sessions = 5
	Platform.ads_started = true
	(Platform.ads as MockAds).duration = 0.4
	var shown := 0
	for run in 5:
		main.hud.menu._on_card("memory")
		main._on_play()
		await wait(1.5)
		main.mode._finish()
		await wait(1.0)
		var before := int(SaveData.section("ads").get("last_shown", 0))
		main.hud.results_dismissed.emit()
		await wait(0.6)
		if int(SaveData.section("ads").get("last_shown", 0)) != before:
			shown += 1
			print("interstitial after run ", run + 1)
	print("interstitials shown in 5 runs: ", shown, " state=", main.state)


## 20 Score runs at 4x speed with a heavy combo bot; reports node/object/memory growth.
func s_perf() -> void:
	main.hud.menu._on_card("score")
	Engine.time_scale = 4.0
	var base := {}
	var fps_min := 999.0
	for run in 20:
		main._on_play()
		await wait(1.5 * 4.0 / 4.0)
		while main.state == main.GameState.COUNTDOWN:
			await get_tree().process_frame
		var t0 := Time.get_ticks_msec()
		while main.state == main.GameState.PLAYING:
			for b in main.mode._active.duplicate():
				tap_bubble(b)
			await get_tree().process_frame
			if Time.get_ticks_msec() - t0 > 1000:
				fps_min = minf(fps_min, Engine.get_frames_per_second())
		await wait(0.5)
		main._enter_idle()
		await wait(0.2)
		if run == 1:
			base = _perf_snapshot()
	var end := _perf_snapshot()
	Engine.time_scale = 1.0
	print("after run 2: ", base)
	print("after run 20: ", end)
	print("best combo last run: ", main._last_results.get("best_combo"), "  min fps during play: ", fps_min)
	await wait(7.0)
	print("idle max_fps after 7 s: ", Engine.max_fps)


func _perf_snapshot() -> Dictionary:
	return {
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"static_mem_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.01),
	}


func s_access() -> void:
	SaveData.set_setting("symbols", true)
	SaveData.set_setting("reduce_motion", "on")
	ThemeManager.apply("contrast", true)
	main.hud.menu._on_card("score")
	main._on_play()
	await wait(1.7)
	for i in 6:
		for b in main.mode._active.duplicate():
			tap_bubble(b)
			break
		await wait(0.15)
	await wait(0.4)
	print("shake=", main._shake, " effects.reduced=", main.effects.reduced)
	await shot("access_play")
	main.pause()
	main._quit_run()
	await wait(0.4)
	main._open_settings()
	await wait(0.5)
	await shot("access_settings")


## App preview video (US-37): ~22 s combo run. Record with Godot's movie maker:
##   Godot --path . --write-movie store/preview/frames/f.png --fixed-fps 30 \
##     res://tools/scenario.tscn -- --test-save --fresh --scenario=preview --size=443x960
##   swift tools/make_preview.swift store/preview/frames store/preview/app_preview_886x1920.mp4
func s_preview() -> void:
	main.toast.visible = false
	SaveData.set_flag("hint_fidget_done")
	SaveData.set_flag("hint_tap_done")
	for i in [2, 7, 12, 17]:
		tap_bubble(main.board.bubbles[i])
		await wait(0.25)
	await wait(0.6)
	main._on_play()
	await wait(1.5)
	while main.mode.elapsed < 17.0 and main.state == main.GameState.PLAYING:
		for b in main.mode._active.duplicate():
			await wait(randf_range(0.12, 0.2))
			if is_instance_valid(b) and b in main.mode._active:
				tap_bubble(b)
			break
		await get_tree().process_frame
	main.mode.elapsed = main.mode.get_duration() - 0.02
	await wait(3.0)


func s_party() -> void:
	main.party_setup.open()
	await wait(0.5)
	main.party_setup._names[0].text = "Daan"
	await shot("party_setup")
	main.party_setup._count = 3
	main.party_setup.refresh()
	await wait(0.3)
	main.party_setup._names[1].text = "Sam"
	main.party_setup._on_start()
	await wait(0.5)
	await shot("party_pass")
	var seqs := []
	for turn in 3:
		main.party_pass.close()
		main._party_turn()
		await wait(1.6)
		var lit := []
		for i in 6 + turn * 4:
			for b in main.mode._active.duplicate():
				if i < 3:
					lit.append(b.index)
				tap_bubble(b)
				break
			await wait(0.12)
		seqs.append(lit)
		main.mode.elapsed = main.mode.get_duration() - 0.02
		await wait(1.6)
	print("first targets per player (same seed): ", seqs)
	await wait(0.5)
	await shot("party_ranking")
	print("ranking open: ", main.party_ranking.visible, " scores: ", main.party.players.map(func(p): return p.score))


func s_event() -> void:
	Daily.fake_now = int(Time.get_unix_time_from_datetime_string("2026-10-20T12:00:00"))
	main._enter_idle()
	main._announce_event()
	await wait(0.8)
	await shot("event_menu")
	ThemeManager.apply("halloween", false)
	main.event_panel.open()
	await wait(0.6)
	await shot("event_panel")
	main.event_panel.close()
	await wait(0.2)
	main.start_event_challenge(3)
	await wait(1.6)
	print("event run mode=", main.mode.mode_id, " start_length=", main.mode.cfg.get("start_length"), " seed=", main.mode.context.get("seed"))
	main.mode._finish()
	await wait(1.4)
	await shot("event_results")
	main._enter_idle()
	print("mode restored=", main.mode.mode_id, " last_mode=", SaveData.get_setting("last_mode"))
	Daily.fake_now = 0


func s_back() -> void:
	main._open_settings()
	await wait(0.3)
	main._on_back()
	await wait(0.3)
	print("back closes modal: ", not main.settings.is_open())
	main._on_play()
	await wait(1.6)
	main._on_back()
	print("back during play pauses: ", main.state == main.GameState.PAUSED)
	main._on_back()
	await wait(0.2)
	print("back on pause resumes (countdown): ", main.state == main.GameState.COUNTDOWN)
	await wait(1.6)
	main.mode.elapsed = 999
	await wait(1.4)
	main._on_back()
	await wait(0.3)
	print("back on results -> menu: ", main.state == main.GameState.IDLE)


func s_party_card() -> void:
	await shot("party_card_menu")
	main.hud.menu._on_card("party")
	await wait(0.3)
	await shot("party_card_selected")
	main._on_menu_play()
	await wait(0.5)
	print("setup open via PLAY: ", main.party_setup.is_open(), " mode preselected: ", main.party_setup._mode)
	await shot("party_card_setup")
	main.party_setup.close()
	await wait(0.3)
	main.hud.menu._on_card("reflex")
	await wait(0.3)
	print("back to reflex: party_selected=", main._party_selected, " mode=", main.mode.mode_id)


func s_topbar() -> void:
	SaveData.submit_result("score", 10330, false, 60)
	main._enter_idle()
	await wait(0.4)
	await shot("topbar_menu")
	main._open_settings()
	await wait(0.6)
	await shot("topbar_settings")
	main.settings.body.get_child(0).pressed.emit()  # Records row
	await wait(0.6)
	print("records open via settings: ", main.stats_panel.is_open(), " settings closed: ", not main.settings.is_open())
	main.stats_panel.close()
	await wait(0.3)
	main._on_play()
	await wait(1.8)
	await shot("topbar_play")


## Run with -- --force-splash. Captures both splashes mid-animation.
func s_splash() -> void:
	await wait(0.6)
	await shot("splash_dd_in")
	await wait(1.2)
	await shot("splash_dd_shine")
	await wait(1.9)
	await shot("splash_pp_bubbles")
	await wait(1.0)
	await shot("splash_pp_title")
	await wait(2.0)
	await shot("splash_done_menu")


func s_pause_panel() -> void:
	main._on_play()
	await wait(1.8)
	main.pause()
	await wait(0.6)
	await shot("pause_panel")
	main.pause_overlay._resume()
	await wait(2.0)
	main.mode.elapsed = 999
	await wait(1.4)
	main.hud.results_dismissed.emit()
	await wait(0.4)
	main.open_premium("menu")
	await wait(0.6)
	await shot("premium_panel_pad")


func s_settings_links() -> void:
	main._open_settings()
	await wait(0.6)
	main.settings.scroll.scroll_vertical = 5000
	await wait(0.3)
	await shot("settings_links")
	Platform.tell_a_friend()
	print("whatsapp: ", Platform.last_opened_url.left(90))


func s_att_prompt() -> void:
	main.ui.get_children().filter(func(c): return c is AttPrompt)[0].open()
	await wait(0.6)
	await shot("att_prompt")


func s_level_trial() -> void:
	# Rewarded "play this level once": locked level 13 after clearing 1–12.
	SaveData.section("unlocks").entitlements = {}
	Platform.ads_started = true
	for i in range(1, 13):
		SaveData.set_stars(i, 2)
	main.hud.menu._on_card("stage")
	await wait(0.3)
	main._on_menu_play()
	await wait(0.5)
	main.stage_select._press_scroll = main.stage_select.scroll.scroll_vertical
	main.stage_select._on_cell(13)
	await wait(0.6)
	await shot("level_trial_offer")
	main.premium_panel.level_trial_requested.emit(13)
	await wait(4.0)
	print("after trial: state=", main.state, " stage_level=", main.stage_level, " pass=", main._level_pass)
	await shot("level_trial_running")


func s_style_trial() -> void:
	SaveData.section("unlocks").entitlements = {}
	Platform.ads_started = true
	main._open_themes()
	main.theme_picker._set_tab("design")
	await wait(0.3)
	for it in main.theme_picker._items():
		if it.id == "gem":
			main.theme_picker._select(it)
	await wait(0.4)
	await shot("style_trial_offer")
	main.theme_picker._on_trial()
	await wait(3.5)
	print("design now=", SaveData.get_setting("design"), " picker open=", main.theme_picker.visible)

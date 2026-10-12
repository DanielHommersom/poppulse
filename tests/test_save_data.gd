extends TestCase
## US-08: migration, round-trip, atomic writes, per-mode stats.


func test_v1_migration_keeps_highscores() -> void:
	var legacy := tmp_path("legacy.cfg")
	var cfg := ConfigFile.new()
	cfg.set_value("best", "score", 10330)
	cfg.set_value("settings", "sound", false)
	cfg.save(legacy)
	var s := SaveStore.new(tmp_path("migrated.json"), legacy)
	check(s.load_or_create(), "legacy save detected")
	eq(int(s.data.version), SaveStore.VERSION, "version bumped")
	eq(int(s.data.modes.score.best), 10330, "best kept")
	eq(s.data.settings.sound, false, "settings kept")
	check(FileAccess.file_exists(s.path), "migrated file written")
	var again := SaveStore.new(s.path)
	again.load_or_create()
	eq(int(again.data.modes.score.best), 10330, "best survives reload")


func test_roundtrip_and_sections() -> void:
	var s := SaveStore.new(tmp_path("rt.json"))
	check(not s.load_or_create(), "fresh save starts blank")
	for k in ["settings", "modes", "stage", "unlocks", "daily", "flags"]:
		check(s.data.has(k), "section %s exists" % k)
	s.data.stage.stars["3"] = 2
	s.data.unlocks.entitlements["premium_unlock"] = true
	check(s.save(), "save ok")
	var r := SaveStore.new(s.path)
	r.load_or_create()
	eq(int(r.data.stage.stars["3"]), 2, "stars persisted")
	eq(r.data.unlocks.entitlements.premium_unlock, true, "entitlement persisted")


func test_mode_stats_and_recent() -> void:
	var s := SaveStore.new(tmp_path("stats.json"))
	s.load_or_create()
	check(s.submit_result("score", 500, false, 60.0), "first score is a best")
	check(not s.submit_result("score", 300, false, 60.0), "lower score is not")
	check(s.submit_result("score", 900, false, 60.0), "higher score is")
	var m := s.mode("score")
	eq(int(m.played), 3, "played count")
	eq(float(m.time_played), 180.0, "play time")
	eq(int(m.best), 900, "best")
	for i in 30:
		s.submit_result("reflex", 300 - i, true, 10.0)
	var r := s.mode("reflex")
	eq((r.recent as Array).size(), SaveStore.RECENT_MAX, "recent capped")
	eq(int(r.best), 271, "lower-is-better best")
	check(not s.submit_result("reflex", 400, true), "slower is no best")


func test_atomic_write_survives_corruption() -> void:
	var p := tmp_path("atomic.json")
	var s := SaveStore.new(p)
	s.load_or_create()
	s.mode("score").best = 111
	s.save()
	s.mode("score").best = 222
	s.save()  # previous good file is now .bak
	check(not FileAccess.file_exists(p + ".tmp"), "no temp file left behind")
	# Simulate a crash that left a truncated main file.
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string("{\"version\": 2, \"modes\": {")
	f.close()
	var r := SaveStore.new(p)
	check(r.load_or_create(), "falls back to backup")
	eq(int(r.mode("score").best), 111, "backup content restored")


func test_future_fields_merge() -> void:
	var d := SaveStore.migrate({"version": 2, "modes": {"score": {"best": 5}}, "unknown_future": 1})
	check(d.has("daily") and d.has("achievements"), "missing sections filled")
	eq(int(d.modes.score.best), 5, "existing data kept")
	check(d.has("unknown_future"), "unknown keys preserved")


func test_reflex_summary() -> void:
	var sm := ReflexGraph.summary([300, 290, 280, 270, 260, 250, 240, 230, 220, 210], 205)
	eq(int(sm.avg10), 255, "avg of last 10")
	check(int(sm.trend) < 0, "getting faster -> negative trend")
	eq(int(sm.best), 205, "best passthrough")
	var flat := ReflexGraph.summary([250], 250)
	eq(int(flat.trend), 0, "no trend with 1 value")

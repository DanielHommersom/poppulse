extends TestCase
## US-17: deterministic daily challenge, one official attempt, clock rollback.


func _reset() -> void:
	var d := SaveData.section("daily")
	d.results = {}
	d.max_day = 0
	d.extra_attempts = {}


func test_same_challenge_for_same_day() -> void:
	var a := Daily.challenge_for(20000)
	var b := Daily.challenge_for(20000)
	eq(JSON.stringify(a), JSON.stringify(b), "deterministic")
	var differs := false
	for d in range(20001, 20010):
		if JSON.stringify(Daily.challenge_for(d)) != JSON.stringify(a):
			differs = true
	check(differs, "different days give different challenges")
	check(ModeRegistry.has(a.mode), "challenge uses an existing mode")
	check(not str(a.title).contains("{"), "title fully filled: %s" % a.title)


func test_overrides_apply() -> void:
	var cfg := GameMode.load_config("res://data/score_mode.json")
	Daily.apply_overrides(cfg, {"duration": 30, "difficulty/params/max_active/1": 2, "difficulty/params/lifetime": [1.2, 0.75]})
	eq(cfg.duration, 30, "top-level")
	eq(cfg.difficulty.params.max_active[1], 2, "array element")
	eq(cfg.difficulty.params.lifetime[0], 1.2, "array value")


func test_one_official_attempt() -> void:
	_reset()
	var day := 20500
	check(Daily.can_play_official(day), "open at start")
	Daily.begin_official(day)
	check(not Daily.can_play_official(day), "used once started (quit counts)")
	Daily.record(day, 1200, false, "score")
	eq(int(Daily.result(day).score), 1200, "stored")
	check(not Daily.can_play_official(day), "no second official attempt")
	# A granted retry (US-32) keeps the better of both.
	SaveData.section("daily").extra_attempts[str(day)] = 1
	check(Daily.can_play_official(day), "retry granted")
	Daily.begin_official(day)
	Daily.record(day, 900, false, "score")
	eq(int(Daily.result(day).score), 1200, "worse retry does not replace")
	check(not Daily.can_play_official(day), "retry used up")


func test_clock_rollback() -> void:
	_reset()
	Daily.fake_now = 20600 * 86400 + 3600
	eq(Daily.today(), 20600, "today")
	Daily.fake_now = 20598 * 86400 + 3600  # clock set back two days
	eq(Daily.today(), 20600, "never goes back to an earlier day")
	check(Daily.seconds_to_next() > 86400, "countdown counts to the day after the protected day")
	Daily.fake_now = 0


func test_same_seed_same_sequence() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = Daily.challenge_for(20000).seed
	b.seed = Daily.challenge_for(20000).seed
	eq(a.randi(), b.randi(), "seeded runs match")


func test_streak() -> void:
	_reset()
	var d := SaveData.section("daily")
	d.streak = 0
	d.last_day = -1
	d.best_streak = 0
	Daily.fake_now = 21000 * 86400 + 100
	eq(Daily.complete_day(21000), 1, "first day")
	eq(Daily.complete_day(21000), 1, "same day twice doesn't count")
	Daily.fake_now = 21001 * 86400 + 100
	eq(Daily.current_streak(), 1, "still alive the next day before playing")
	eq(Daily.complete_day(21001), 2, "next day +1")
	Daily.fake_now = 21002 * 86400 + 100
	eq(Daily.complete_day(21002), 3, "third")
	check(Daily.is_milestone(3), "3 is a milestone")
	Daily.fake_now = 21004 * 86400 + 100  # missed 21003
	eq(Daily.current_streak(), 0, "missed day resets")
	eq(Daily.complete_day(21004), 1, "starts over")
	eq(int(d.best_streak), 3, "best kept")
	Daily.fake_now = 0

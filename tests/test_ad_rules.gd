extends TestCase
## US-33: interstitial frequency rules (balanced set, build 2).

const CFG := {"min_sessions": 2, "first_session_after_runs": 3, "runs_between": 3, "min_seconds_between": 90,
	"skip_after_record": false, "skip_first_run_per_mode": true, "skip_after_rewarded": true,
	"placements": ["results_to_menu", "results_to_next"]}


func _ctx(extra := {}) -> Dictionary:
	var c := {"sessions": 3, "session_runs": 5, "premium": false, "is_record": false, "first_run_of_mode": false,
		"rewarded": false, "placement": "results_to_menu", "now": 10000}
	c.merge(extra, true)
	return c


func test_rules() -> void:
	var ok_state := {"runs_since": 3, "last_shown": 0}
	check(AdRules.may_show(CFG, ok_state, _ctx()), "allowed when all rules pass")
	check(not AdRules.may_show(CFG, ok_state, _ctx({"sessions": 1, "session_runs": 2})), "first session: not before the 3rd game")
	check(AdRules.may_show(CFG, ok_state, _ctx({"sessions": 1, "session_runs": 3})), "first session: from the 3rd finished game")
	check(not AdRules.may_show(CFG, {"runs_since": 2, "last_shown": 0}, _ctx()), "not within 3 runs")
	check(not AdRules.may_show(CFG, {"runs_since": 5, "last_shown": 9950}, _ctx()), "min 90 s between")
	check(AdRules.may_show(CFG, {"runs_since": 5, "last_shown": 9905}, _ctx()), "allowed after 90 s")
	check(AdRules.may_show(CFG, ok_state, _ctx({"is_record": true})), "records no longer block ads")
	check(not AdRules.may_show(CFG, ok_state, _ctx({"first_run_of_mode": true})), "first game of a mode stays ad-free")
	check(not AdRules.may_show(CFG, ok_state, _ctx({"rewarded": true})), "not after a rewarded ad")
	check(not AdRules.may_show(CFG, ok_state, _ctx({"premium": true})), "never for premium")
	check(not AdRules.may_show(CFG, ok_state, _ctx({"placement": "countdown"})), "only at allowed placements")
	var strict := CFG.duplicate()
	strict.erase("first_session_after_runs")
	check(not AdRules.may_show(strict, ok_state, _ctx({"sessions": 1, "session_runs": 50})), "without the key: never in session 1")


func test_sessions() -> void:
	var s0 := int(SaveData.section("stats").sessions)
	SaveData.session_runs = 4
	SaveData.went_background(1000)
	SaveData.came_foreground(1000 + 600)
	eq(int(SaveData.section("stats").sessions), s0, "10 min away: same session")
	eq(SaveData.session_runs, 4, "session runs kept")
	SaveData.went_background(5000)
	SaveData.came_foreground(5000 + SaveData.session_gap_s)
	eq(int(SaveData.section("stats").sessions), s0 + 1, "30+ min away: new session")
	eq(SaveData.session_runs, 0, "session runs reset")


func test_config_file() -> void:
	var all: Dictionary = GameMode.load_config("res://data/ads.json")
	var cfg: Dictionary = all.interstitial
	for k in ["min_sessions", "first_session_after_runs", "runs_between", "min_seconds_between", "placements"]:
		check(cfg.has(k), "ads.json has %s" % k)
	eq(int(all.get("session_gap_seconds", 0)), 1800, "session gap 30 min")

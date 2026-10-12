extends TestCase
## US-33: interstitial frequency rules.

const CFG := {"min_sessions": 2, "runs_between": 3, "min_seconds_between": 120, "skip_after_record": true, "skip_after_rewarded": true, "placements": ["results_to_menu", "results_to_next"]}


func _ctx(extra := {}) -> Dictionary:
	var c := {"sessions": 3, "premium": false, "is_record": false, "rewarded": false, "placement": "results_to_menu", "now": 10000}
	c.merge(extra, true)
	return c


func test_rules() -> void:
	var ok_state := {"runs_since": 3, "last_shown": 0}
	check(AdRules.may_show(CFG, ok_state, _ctx()), "allowed when all rules pass")
	check(not AdRules.may_show(CFG, ok_state, _ctx({"sessions": 1})), "never in the first session")
	check(not AdRules.may_show(CFG, {"runs_since": 2, "last_shown": 0}, _ctx()), "not within 3 runs")
	check(not AdRules.may_show(CFG, {"runs_since": 5, "last_shown": 9950}, _ctx()), "min 120 s between")
	check(not AdRules.may_show(CFG, ok_state, _ctx({"is_record": true})), "not after a record")
	check(not AdRules.may_show(CFG, ok_state, _ctx({"rewarded": true})), "not after a rewarded ad")
	check(not AdRules.may_show(CFG, ok_state, _ctx({"premium": true})), "never for premium")
	check(not AdRules.may_show(CFG, ok_state, _ctx({"placement": "countdown"})), "only at allowed placements")


func test_config_file() -> void:
	var cfg: Dictionary = GameMode.load_config("res://data/ads.json").interstitial
	for k in ["min_sessions", "runs_between", "min_seconds_between", "placements"]:
		check(cfg.has(k), "ads.json has %s" % k)

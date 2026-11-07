extends TestCase
## Remote interstitial rules: only known keys, right types, within bounds.


func test_sanitize() -> void:
	var s := AdConfig.sanitize({"interstitial": {"runs_between": 2, "min_seconds_between": 60,
		"skip_after_record": true, "evil": 1}, "session_gap_seconds": 3600})
	eq(s.get("runs_between"), 2, "valid number kept")
	eq(s.get("min_seconds_between"), 60, "valid seconds kept")
	eq(s.get("skip_after_record"), true, "valid bool kept")
	eq(s.get("session_gap_seconds"), 3600, "top-level session gap kept")
	check(not s.has("evil"), "unknown keys dropped")
	var bad := AdConfig.sanitize({"interstitial": {"runs_between": 0, "min_seconds_between": 5, "skip_after_rewarded": "no"}})
	check(bad.is_empty(), "out-of-range and wrong types dropped")


func test_apply_and_merge() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(AdConfig.CACHE))
	var base := AdConfig.load_rules()
	eq(int(base.runs_between), 3, "built-in rules without cache")
	check(not AdConfig.apply_remote("{broken"), "broken JSON ignored")
	check(not AdConfig.apply_remote(JSON.stringify({"interstitial": {"runs_between": 2}})), "no version → ignored")
	check(AdConfig.apply_remote(JSON.stringify({"version": 2, "interstitial": {"runs_between": 2}})), "newer valid file used")
	eq(int(AdConfig.load_rules().runs_between), 2, "override applied")
	eq(int(AdConfig.load_rules().min_seconds_between), int(base.min_seconds_between), "other rules stay built-in")
	check(not AdConfig.apply_remote(JSON.stringify({"version": 2, "interstitial": {"runs_between": 5}})), "same version ignored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(AdConfig.CACHE))


func test_online_file_matches_builtin() -> void:
	var online: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://docs/ads-config.json"))
	check(online is Dictionary and int(online.version) >= 1, "docs/ads-config.json is valid")
	var s := AdConfig.sanitize(online)
	eq(s.size(), 8, "every rule in the online file passes the bounds")

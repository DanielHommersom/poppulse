extends TestCase
## AdMob v5 backend: compiles against the installed plugin, picks the right units.


func test_backend() -> void:
	var cfg := GameMode.load_config("res://data/ads.json")
	var a := AdMobAds.new(cfg)
	var want := "ca-app-pub-3940256099942544/1712485313" if OS.is_debug_build() else "ca-app-pub-3366446717708247/3435736524"
	eq(a._units.rewarded, want, "rewarded unit for this build type (test units in debug)")
	check(not AdMobAds.available(), "no native AdMob on desktop -> Platform uses MockAds")
	check(Platform.ads is MockAds, "mock backend active on desktop")
	eq(str(ProjectSettings.get_setting("admob/general/ios/app_id", "")), "ca-app-pub-3366446717708247~4912469721", "iOS app id configured for the plugin")


func test_consent_button_visibility() -> void:
	var st := Platform._ads_state()
	var saved := st.duplicate()
	st.consent_done = false
	check(not Platform.ad_privacy_options_available(), "hidden before the consent flow ran")
	st.consent_done = true
	eq(Platform.ad_privacy_options_available(), OS.is_debug_build() and not Platform.ads_disabled(), "mock: shown in debug after consent")
	st.consent = "denied"
	st.att = "authorized"
	await Platform.show_ad_privacy_options()
	check(not bool(st.personalized), "denied consent -> non-personalised")
	st.clear()
	st.merge(saved)


func test_rewarded_units_per_placement() -> void:
	var cfg := {"units": {"ios": {"rewarded": {"test": "TEST", "release": "ca-app-pub-1/shared",
		"placements": {"continue": "ca-app-pub-1/continue", "daily_retry": "", "level_trial": "ca-app-pub-1/level"}}}}}
	var rel := AdMobAds.new(cfg, true)
	eq(rel.unit_for("continue"), "ca-app-pub-1/continue", "own unit when filled in")
	eq(rel.unit_for("daily_retry"), "ca-app-pub-1/shared", "empty → shared unit")
	eq(rel.unit_for("style_trial"), "ca-app-pub-1/shared", "missing → shared unit")
	eq(rel.rewarded_units().size(), 3, "each distinct unit preloaded once")
	var dbg := AdMobAds.new(cfg, false)
	eq(dbg.unit_for("continue"), "TEST", "debug always uses the test unit")
	eq(dbg.rewarded_units().size(), 1, "debug preloads one test ad")


func test_release_config_has_unit_per_button() -> void:
	var rel := AdMobAds.new(GameMode.load_config("res://data/ads.json"), true)
	var seen := {}
	for p in ["continue", "daily_retry", "level_trial", "style_trial"]:
		var u := rel.unit_for(p)
		check(u.begins_with("ca-app-pub-3366446717708247/") and u != "ca-app-pub-3366446717708247/3435736524", "%s has its own unit" % p)
		seen[u] = true
	eq(seen.size(), 4, "four different rewarded units")

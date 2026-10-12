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

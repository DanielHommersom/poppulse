extends TestCase
## US-32: rewarded 24 h trials for bubble styles / sound packs, and expiry.


func _trials() -> Dictionary:
	return SaveData.section("unlocks").trials


func test_style_trials() -> void:
	SaveData.section("unlocks").entitlements = {}
	_trials().clear()  # the shared test save may hold trials from dev scenarios
	var gem := ThemeManager.get_design("gem")
	var cosmic := Sfx.get_pack("cosmic")
	check(not ThemeManager.item_available("design", gem), "gem locked without Premium")
	check(not ThemeManager.item_available("sound", cosmic), "cosmic locked without Premium")
	var now := int(Time.get_unix_time_from_system())
	_trials()[ThemeManager.trial_key("design", "gem")] = now + 3600
	_trials()[ThemeManager.trial_key("sound", "cosmic")] = now + 3600
	check(ThemeManager.item_available("design", gem), "gem available during trial")
	check(ThemeManager.item_available("sound", cosmic), "cosmic available during trial")
	check(not ThemeManager.item_available("design", ThemeManager.get_design("pearl")), "trial is per item")
	eq(ThemeManager.trial_key("theme", "galaxy"), "galaxy", "themes keep bare ids (older saves)")
	_trials()[ThemeManager.trial_key("design", "gem")] = now - 1
	check(not ThemeManager.item_available("design", gem), "expired trial locks again")
	check(ThemeManager.item_available("design", ThemeManager.get_design("round")), "free styles always available")


func test_expired_pack_falls_back() -> void:
	SaveData.section("unlocks").entitlements = {}
	_trials()[ThemeManager.trial_key("sound", "cosmic")] = int(Time.get_unix_time_from_system()) - 1
	SaveData.set_setting("sound_follows_theme", false)
	SaveData.set_setting("sound_pack", "cosmic")
	Sfx._sync_pack()
	eq(Sfx.pack_id, "classic", "an expired premium pack is not used")
	SaveData.set_setting("sound_pack", "classic")
	SaveData.set_setting("sound_follows_theme", true)

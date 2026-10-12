extends TestCase
## US-27: monetization interface against the mock backends.

var _events: Array = []


func _reset() -> void:
	SaveData.section("unlocks").entitlements = {}
	var store := Platform.store as MockStore
	store.outcome = "success"
	store.delay = 0.01
	var ads := Platform.ads as MockAds
	ads.rewarded_available = true
	ads.skip_rewarded = false
	ads.interstitial_available = true
	ads.duration = 0.05
	Platform.ads_started = true
	_events.clear()


func _wait(s: float) -> void:
	await Engine.get_main_loop().create_timer(s).timeout


func test_products_defined() -> void:
	check(not Platform.product("premium_unlock").is_empty(), "Premium in products.json")
	eq(Platform.products().size(), 1, "Premium is the only product")
	check(Platform.get_price("premium_unlock") != "", "mock price available")


func test_purchase_success_and_bundle() -> void:
	_reset()
	var cb := func(pid: String) -> void: _events.append(pid)
	Platform.purchase_completed.connect(cb)
	check(not Platform.is_entitled("premium_unlock"), "not owned at start")
	Platform.purchase("premium_unlock")
	await _wait(0.1)
	check(Platform.is_entitled("premium_unlock"), "owned after purchase")
	check(Platform.ads_disabled(), "premium disables ads")
	check(ThemeManager.is_available(ThemeManager.get_theme("galaxy")), "former pack theme comes with Premium")
	check(ThemeManager.is_unlock_met("premium", "premium_unlock"), "former pack bubbles/sounds come with Premium")
	eq(_events, ["premium_unlock"], "completed signals")
	Platform.purchase_completed.disconnect(cb)


func test_purchase_failures() -> void:
	_reset()
	var reasons := []
	var cb := func(_pid: String, reason: String) -> void: reasons.append(reason)
	Platform.purchase_failed.connect(cb)
	for o in ["cancel", "fail", "pending"]:
		(Platform.store as MockStore).outcome = o
		Platform.purchase("premium_unlock")
		await _wait(0.08)
	eq(reasons, ["cancelled", "error", "pending"], "failure reasons")
	check(not Platform.is_entitled("premium_unlock"), "nothing granted")
	Platform.purchase_failed.disconnect(cb)


func test_restore() -> void:
	_reset()
	SaveData.set_entitlement("premium_unlock", true)
	var counts := []
	var cb := func(n: int) -> void: counts.append(n)
	Platform.restore_completed.connect(cb)
	Platform.restore_purchases()
	await _wait(0.1)
	eq(counts, [1], "restored count")
	Platform.restore_completed.disconnect(cb)


func test_rewarded() -> void:
	_reset()
	check(Platform.can_show_rewarded("continue"), "available")
	var ok: bool = await Platform.show_rewarded("continue")
	check(ok, "completed ad grants reward")
	(Platform.ads as MockAds).skip_rewarded = true
	ok = await Platform.show_rewarded("continue")
	check(not ok, "skipped ad gives nothing")
	(Platform.ads as MockAds).rewarded_available = false
	check(not Platform.can_show_rewarded("continue"), "no fill -> hidden")
	SaveData.set_entitlement("premium_unlock", true)
	check(Platform.can_show_rewarded("continue"), "premium: perk without ad")
	var shown: bool = await Platform.maybe_show_interstitial("results")
	check(not shown, "premium never sees interstitials")
	_reset()

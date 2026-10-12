extends TestCase
## RevenueCat backend against a fake GodotxRevenueCat singleton.


class FakeRC extends Object:
	signal customer_info_changed(data: Dictionary)
	signal purchase_result(data: Dictionary)
	signal products(data: Dictionary)
	signal restore_finished(data: Dictionary)
	var key := ""
	var bought: Array = []
	var entitled := false

	func initialize(api_key: String, _user: String, _debug: bool) -> void:
		key = api_key

	func fetch_products(_ids: Array) -> void:
		pass

	func get_customer_info() -> void:
		pass

	func purchase(id: String) -> void:
		bought.append(id)

	func restore_purchases() -> void:
		pass

	func has_entitlement(id: String) -> bool:
		return entitled and id == "premium"


func test_flow() -> void:
	var fake := FakeRC.new()
	var s := RevenueCatStore.new(fake, "appl_test")
	s.setup(GameMode.load_config("res://data/products.json").products)
	eq(fake.key, "appl_test", "initialised with the API key")
	var got := []
	s.purchased.connect(func(pid: String) -> void: got.append("ok:" + pid))
	s.failed.connect(func(pid: String, r: String) -> void: got.append(r + ":" + pid))
	fake.products.emit({"error": "", "products": [{"id": "com.digitaldiamonds.poppulse.premium", "price": "€3,99"}]})
	eq(s.price("premium_unlock"), "€3,99", "localised price")
	s.purchase("premium_unlock")
	eq(fake.bought, ["com.digitaldiamonds.poppulse.premium"], "buys the store product")
	fake.purchase_result.emit({"success": false, "cancelled": true, "error": "", "product_id": "com.digitaldiamonds.poppulse.premium"})
	s.purchase("premium_unlock")
	fake.purchase_result.emit({"success": false, "cancelled": false, "error": "Payment is pending (Ask to Buy)"})
	s.purchase("premium_unlock")
	fake.purchase_result.emit({"success": false, "cancelled": false, "error": "network"})
	fake.entitled = true
	s.purchase("premium_unlock")
	fake.purchase_result.emit({"success": true, "product_id": "com.digitaldiamonds.poppulse.premium"})
	eq(got, ["cancelled:premium_unlock", "pending:premium_unlock", "error:premium_unlock", "ok:premium_unlock"], "outcomes")
	got.clear()
	fake.customer_info_changed.emit({})
	eq(got, ["ok:premium_unlock"], "entitlement from customer info (restore / other device)")
	var restored := []
	s.restore_finished.connect(func(n: int) -> void: restored.append(n))
	fake.restore_finished.emit({"success": true, "restored": true, "active_entitlements": 1, "error": ""})
	eq(restored, [1], "restore count")
	fake.free()


func test_release_never_uses_mock() -> void:
	# On desktop the mock is allowed; the guard itself is in Platform._make_store.
	check(Platform.store is MockStore, "desktop/debug uses the mock")
	var u := UnavailableStore.new()
	var reasons := []
	u.failed.connect(func(_p: String, r: String) -> void: reasons.append(r))
	u.purchase("premium_unlock")
	eq(reasons, ["error"], "unavailable store never grants")
	eq(u.price("premium_unlock"), "", "no price -> buy button disabled")

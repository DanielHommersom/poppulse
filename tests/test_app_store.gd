extends TestCase
## US-28: AppStore backend against a fake InAppStore plugin (event queue).


class FakeIAP extends RefCounted:
	var events: Array = []
	var requested: Dictionary = {}
	var bought: Array = []

	func set_auto_finish_transaction(_on: bool) -> void:
		pass

	func request_product_info(d: Dictionary) -> int:
		requested = d
		return OK

	func purchase(d: Dictionary) -> int:
		bought.append(d.product_id)
		return OK

	func restore_purchases() -> int:
		return OK

	func get_pending_event_count() -> int:
		return events.size()

	func pop_pending_event() -> Dictionary:
		return events.pop_front()


func test_events() -> void:
	var fake := FakeIAP.new()
	var s := AppStore.new(fake)
	s.setup(GameMode.load_config("res://data/products.json").products)
	check("com.digitaldiamonds.poppulse.premium" in fake.requested.product_ids, "asks StoreKit for store ids")
	var got := []
	s.purchased.connect(func(pid: String) -> void: got.append("ok:" + pid))
	s.failed.connect(func(pid: String, r: String) -> void: got.append(r + ":" + pid))
	fake.events.append({"type": "product_info", "result": "ok", "ids": ["com.digitaldiamonds.poppulse.premium"], "localized_prices": ["€ 3,99"]})
	s.poll()
	eq(s.price("premium_unlock"), "€ 3,99", "localised price from StoreKit")
	s.purchase("premium_unlock")
	eq(fake.bought, ["com.digitaldiamonds.poppulse.premium"], "buys by store id")
	fake.events.append({"type": "purchase", "result": "ok", "product_id": "com.digitaldiamonds.poppulse.premium"})
	fake.events.append({"type": "purchase", "result": "error", "product_id": "com.digitaldiamonds.poppulse.premium", "error": "Payment cancelled"})
	fake.events.append({"type": "purchase", "result": "error", "product_id": "com.digitaldiamonds.poppulse.premium", "error": "network"})
	fake.events.append({"type": "purchase", "result": "progress", "product_id": "com.digitaldiamonds.poppulse.premium"})
	s.poll()
	eq(got, ["ok:premium_unlock", "cancelled:premium_unlock", "error:premium_unlock", "pending:premium_unlock"], "outcomes")
	var restored := []
	s.restore_finished.connect(func(n: int) -> void: restored.append(n))
	s.restore()
	fake.events.append({"type": "restore", "result": "ok", "product_id": "com.digitaldiamonds.poppulse.premium"})
	fake.events.append({"type": "restore", "result": "completed"})
	s.poll()
	eq(restored, [1], "restore count")

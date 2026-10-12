extends TestCase
## US-42: Play Billing backend against a fake GodotGooglePlayBilling plugin.


class FakePay extends Object:
	signal connected
	signal sku_details_query_completed(details: Array)
	signal purchases_updated(purchases: Array)
	signal purchase_error(code: int, msg: String)
	signal query_purchases_response(result: Dictionary)
	var acked: Array = []
	var bought: Array = []

	func startConnection() -> void:
		pass

	func querySkuDetails(_ids: Array, _type: String) -> void:
		pass

	func queryPurchases(_type: String) -> void:
		pass

	func purchase(sku: String) -> void:
		bought.append(sku)

	func acknowledgePurchase(token: String) -> void:
		acked.append(token)


func test_flow() -> void:
	var fake := FakePay.new()
	var b := PlayBilling.new(fake)
	b.setup(GameMode.load_config("res://data/products.json").products)
	var got := []
	b.purchased.connect(func(pid: String) -> void: got.append("ok:" + pid))
	b.failed.connect(func(pid: String, r: String) -> void: got.append(r + ":" + pid))
	fake.sku_details_query_completed.emit([{"sku": "com.digitaldiamonds.poppulse.premium", "price": "€ 3,99"}])
	eq(b.price("premium_unlock"), "€ 3,99", "Play price")
	b.purchase("premium_unlock")
	eq(fake.bought, ["com.digitaldiamonds.poppulse.premium"], "buy by store id")
	fake.purchases_updated.emit([{"skus": ["com.digitaldiamonds.poppulse.premium"], "purchase_state": 1, "purchase_token": "t1", "is_acknowledged": false}])
	fake.purchases_updated.emit([{"skus": ["com.digitaldiamonds.poppulse.premium"], "purchase_state": 2, "purchase_token": "t2"}])
	fake.purchase_error.emit(1, "user canceled")
	eq(got, ["ok:premium_unlock", "pending:premium_unlock", "cancelled:premium_unlock"], "outcomes")
	eq(fake.acked, ["t1"], "non-consumable acknowledged")
	var restored := []
	b.restore_finished.connect(func(n: int) -> void: restored.append(n))
	b.restore()
	fake.query_purchases_response.emit({"status": OK, "purchases": [{"skus": ["com.digitaldiamonds.poppulse.premium"], "purchase_state": 1, "purchase_token": "t1", "is_acknowledged": true}]})
	eq(restored, [1], "restore count")
	fake.free()

class_name PlayBilling
extends StoreBackend
## Google Play Billing via the official GodotGooglePlayBilling Android plugin
## (singleton "GodotGooglePlayBilling", API as in the Godot docs "Android
## in-app purchases"). Non-consumables must be acknowledged within 3 days,
## otherwise Google refunds them — done for every purchased/restored item.

var _pay: Object
var _prices := {}
var _restoring := false


func _init(singleton: Object) -> void:
	_pay = singleton


func setup(p_products: Array) -> void:
	super.setup(p_products)
	_pay.connected.connect(_on_connected)
	_pay.sku_details_query_completed.connect(_on_details)
	_pay.purchases_updated.connect(_on_purchases)
	_pay.purchase_error.connect(func(code: int, msg: String) -> void:
		# BillingResponseCode 1 = USER_CANCELED
		failed.emit(_last, "cancelled" if code == 1 else "error"))
	_pay.query_purchases_response.connect(_on_query)
	_pay.startConnection()


var _last := ""


func _on_connected() -> void:
	var ids := []
	for p: Dictionary in products:
		ids.append(store_id(p.id))
	_pay.querySkuDetails(ids, "inapp")
	_pay.queryPurchases("inapp")  # silent restore on start (reinstall / new device)


func _on_details(details: Array) -> void:
	for d: Dictionary in details:
		var pid := product_id_for(str(d.get("sku", d.get("product_id", ""))))
		if pid != "":
			_prices[pid] = str(d.get("price", ""))
	prices_updated.emit()


func purchase(product_id: String) -> void:
	_last = product_id
	_pay.purchase(store_id(product_id))


func restore() -> void:
	_restoring = true
	_pay.queryPurchases("inapp")


func price(product_id: String) -> String:
	return str(_prices.get(product_id, ""))


func _on_purchases(purchases: Array) -> void:
	for p: Dictionary in purchases:
		_handle(p)


func _on_query(result: Dictionary) -> void:
	var n := 0
	if int(result.get("status", 0)) == OK:
		for p: Dictionary in result.get("purchases", []):
			if _handle(p):
				n += 1
	if _restoring:
		_restoring = false
		restore_finished.emit(n)


## Purchase state 1 = PURCHASED, 2 = PENDING (e.g. cash / parental approval).
func _handle(p: Dictionary) -> bool:
	var skus: Array = p.get("skus", [p.get("sku", "")])
	var state := int(p.get("purchase_state", 1))
	var ok := false
	for sku in skus:
		var pid := product_id_for(str(sku))
		if pid == "":
			continue
		if state == 2:
			failed.emit(pid, "pending")
		elif state == 1:
			purchased.emit(pid)
			ok = true
	if state == 1 and not bool(p.get("is_acknowledged", false)):
		_pay.acknowledgePurchase(str(p.get("purchase_token", "")))
	return ok

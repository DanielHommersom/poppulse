class_name RevenueCatStore
extends StoreBackend
## In-app purchases via RevenueCat ("Godotx RevenueCat" plugin, singleton
## "GodotxRevenueCat"; iOS + Android). RevenueCat talks to StoreKit / Play
## Billing, validates receipts and tells us whether the `premium` entitlement
## is active. Configuration: data/products.json → "revenuecat".

const SINGLETON := "GodotxRevenueCat"

var _rc: Object
var _api_key := ""
var _prices := {}  # product id -> localised price string
var _pending_purchase := ""


static func available() -> bool:
	return Engine.has_singleton(SINGLETON)


func _init(singleton: Object, api_key: String) -> void:
	_rc = singleton
	_api_key = api_key


func setup(p_products: Array) -> void:
	super.setup(p_products)
	_rc.customer_info_changed.connect(_on_customer_info)
	_rc.purchase_result.connect(_on_purchase_result)
	_rc.products.connect(_on_products)
	_rc.restore_finished.connect(_on_restore_finished)
	_rc.initialize(_api_key, "", OS.is_debug_build())
	var ids := []
	for p: Dictionary in products:
		ids.append(store_id(p.id))
	_rc.fetch_products(ids)
	_rc.get_customer_info()  # silent restore on every start (reinstall / new phone)


func purchase(product_id: String) -> void:
	_pending_purchase = product_id
	_rc.purchase(store_id(product_id))


func restore() -> void:
	_rc.restore_purchases()


func price(product_id: String) -> String:
	return str(_prices.get(product_id, ""))


## Entitlement id configured in RevenueCat for a product (default "premium").
func _entitlement_for(product_id: String) -> String:
	for p: Dictionary in products:
		if p.id == product_id:
			return str(p.get("rc_entitlement", "premium"))
	return "premium"


## Grants every product whose entitlement is active (purchase, restore,
## Family Sharing, a purchase made on another device…).
func _sync_entitlements() -> int:
	var n := 0
	for p: Dictionary in products:
		if bool(_rc.has_entitlement(_entitlement_for(p.id))):
			purchased.emit(p.id)
			n += 1
	return n


func _on_customer_info(_data: Variant) -> void:
	_sync_entitlements()


func _on_purchase_result(data: Dictionary) -> void:
	var pid := product_id_for(str(data.get("product_id", ""))) if data.has("product_id") else _pending_purchase
	if pid == "":
		pid = _pending_purchase
	_pending_purchase = ""
	if bool(data.get("success", false)):
		_sync_entitlements()
		if not bool(_rc.has_entitlement(_entitlement_for(pid))):
			purchased.emit(pid)  # entitlement not refreshed yet; the store said yes
		return
	var err := str(data.get("error", "")).to_lower()
	if bool(data.get("cancelled", false)) or "cancel" in err:
		failed.emit(pid, "cancelled")
	elif "pending" in err or "deferred" in err or "ask to buy" in err:
		failed.emit(pid, "pending")  # Ask to Buy: arrives later via customer_info_changed
	else:
		failed.emit(pid, "error")


func _on_products(data: Dictionary) -> void:
	var raw: Variant = data.get("products", [])
	var list: Array = []
	if raw is Array:
		list = raw
	elif raw is Object and raw.has_method("size"):  # Android: Java ArrayList
		for i in int(raw.call("size")):
			list.append(raw.call("get", i))
	for prod: Variant in list:
		var pid := product_id_for(str(prod.get("id", "")))
		if pid != "":
			_prices[pid] = str(prod.get("price", ""))
	prices_updated.emit()


func _on_restore_finished(data: Dictionary) -> void:
	var n := _sync_entitlements() if bool(data.get("success", false)) else 0
	restore_finished.emit(n)

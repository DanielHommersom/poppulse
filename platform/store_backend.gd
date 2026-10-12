class_name StoreBackend
extends RefCounted
## In-app purchase backend interface. Platform owns one; the UI never talks to
## it directly. Implementations: MockStore (desktop/debug), AppStore (StoreKit
## via the InAppStore plugin, US-28), PlayBilling (US-42).

signal purchased(product_id: String)  # also emitted for restored purchases
signal failed(product_id: String, reason: String)  # reason: cancelled | error | pending
signal prices_updated
signal restore_finished(count: int)

var products: Array = []  # data/products.json entries


func setup(p_products: Array) -> void:
	products = p_products


func poll() -> void:
	pass


func purchase(_product_id: String) -> void:
	pass


func restore() -> void:
	pass


## Localised price string from the store; "" while unknown.
func price(_product_id: String) -> String:
	return ""


func store_id(product_id: String) -> String:
	for p: Dictionary in products:
		if p.id == product_id:
			return str(p.get("store_id", product_id))
	return product_id


func product_id_for(store_product_id: String) -> String:
	for p: Dictionary in products:
		if str(p.get("store_id", "")) == store_product_id or p.id == store_product_id:
			return p.id
	return ""

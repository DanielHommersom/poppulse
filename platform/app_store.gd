class_name AppStore
extends StoreBackend
## StoreKit backend via the official godot-ios-plugins "InAppStore" singleton.
## The plugin is event based: calls return immediately and results arrive as
## pending events, which poll() drains every frame (Platform._process).
## Handles: success, cancel, error, deferred / pending (Ask to Buy), restore.

var _iap: Object
var _prices := {}  # product id -> localised price string from StoreKit
var _restoring := false
var _restored := 0
var _restore_deadline := 0


func _init(singleton: Object) -> void:
	_iap = singleton


func setup(p_products: Array) -> void:
	super.setup(p_products)
	if _iap.has_method("set_auto_finish_transaction"):
		_iap.set_auto_finish_transaction(true)
	var ids := []
	for p: Dictionary in products:
		ids.append(store_id(p.id))
	_iap.request_product_info({"product_ids": ids})


func purchase(product_id: String) -> void:
	var err: int = _iap.purchase({"product_id": store_id(product_id)})
	if err != OK:
		failed.emit(product_id, "error")


func restore() -> void:
	_restoring = true
	_restored = 0
	_restore_deadline = Time.get_ticks_msec() + 8000
	_iap.restore_purchases()


func price(product_id: String) -> String:
	return str(_prices.get(product_id, ""))


func poll() -> void:
	while _iap.get_pending_event_count() > 0:
		_handle(_iap.pop_pending_event())
	# The plugin has no explicit "restore finished" event: settle after a quiet period.
	if _restoring and Time.get_ticks_msec() > _restore_deadline:
		_restoring = false
		restore_finished.emit(_restored)


func _handle(e: Dictionary) -> void:
	var type := str(e.get("type", ""))
	var result := str(e.get("result", ""))
	var pid := product_id_for(str(e.get("product_id", "")))
	match type:
		"product_info":
			var ids: Array = e.get("ids", [])
			var labels: Array = e.get("localized_prices", e.get("prices", []))
			for i in ids.size():
				var p := product_id_for(str(ids[i]))
				if p != "" and i < labels.size():
					_prices[p] = str(labels[i])
			prices_updated.emit()
		"purchase":
			if result == "ok":
				purchased.emit(pid)
			elif result in ["progress", "deferred", "pending"]:
				failed.emit(pid, "pending")  # Ask to Buy: waiting for a parent
			else:
				var msg := str(e.get("error", "")).to_lower()
				failed.emit(pid, "cancelled" if "cancel" in msg else "error")
		"restore":
			if result == "ok" and pid != "":
				_restored += 1
				_restore_deadline = Time.get_ticks_msec() + 1500
				purchased.emit(pid)
			elif result in ["completed", "finished"]:
				_restoring = false
				restore_finished.emit(_restored)
			elif result == "error":
				_restoring = false
				restore_finished.emit(_restored)

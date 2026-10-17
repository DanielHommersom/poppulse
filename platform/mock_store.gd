class_name MockStore
extends StoreBackend
## Desktop / debug store. Toggles (debug overlay): purchases succeed, fail,
## get cancelled or go "pending" (Ask to Buy). Prices come from mock_price.

var outcome := "success"  # success | fail | cancel | pending
var delay := 0.6
var _tree: SceneTree


func _init(tree: SceneTree) -> void:
	_tree = tree


func purchase(product_id: String) -> void:
	await _tree.create_timer(delay).timeout
	match outcome:
		"success":
			purchased.emit(product_id)
		"cancel":
			failed.emit(product_id, "cancelled")
		"pending":
			failed.emit(product_id, "pending")
		_:
			failed.emit(product_id, "error")


func restore() -> void:
	await _tree.create_timer(delay).timeout
	# The mock "account" owns whatever was bought before (entitlements cache).
	var n := 0
	for p: Dictionary in products:
		if SaveData.has_entitlement(p.id):
			purchased.emit(p.id)
			n += 1
	restore_finished.emit(n)


func price(product_id: String) -> String:
	for p: Dictionary in products:
		if p.id == product_id:
			# --store-shot: clean price for App Store screenshots (tools/store_assets).
			var tag := "" if "--store-shot" in OS.get_cmdline_user_args() else " (mock)"
			return str(p.get("mock_price", "")) + tag
	return ""

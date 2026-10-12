class_name UnavailableStore
extends StoreBackend
## Release builds without a working store plugin / API key: purchases are
## impossible (never free). The Premium screen shows no price, so it can't be bought.


func purchase(product_id: String) -> void:
	failed.emit(product_id, "error")


func restore() -> void:
	restore_finished.emit(0)

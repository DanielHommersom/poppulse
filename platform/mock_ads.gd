class_name MockAds
extends AdsBackend
## Desktop / debug ads: a full-screen fake ad with a countdown. Toggles:
## rewarded available, player skips (no reward), interstitials available.

var rewarded_available := true
var skip_rewarded := false
var interstitial_available := true
var duration := 2.0
var _host: Node


func _init(host: Node) -> void:
	_host = host


func rewarded_ready(_placement: String) -> bool:
	return rewarded_available


func interstitial_ready(_placement: String) -> bool:
	return interstitial_available


func show_rewarded(placement: String) -> void:
	await _fake_ad("REWARDED AD (mock)\n%s" % placement, duration)
	rewarded_finished.emit(placement, not skip_rewarded)


func show_interstitial(placement: String) -> void:
	await _fake_ad("INTERSTITIAL AD (mock)\n%s" % placement, duration * 0.6)
	interstitial_closed.emit(placement)


func _fake_ad(text: String, secs: float) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	_host.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.03, 0.97)
	bg.size = _host.get_viewport().get_visible_rect().size
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(bg)
	var l := UiStyle.label(text, 40, Color(1, 1, 1, 0.8))
	l.size = bg.size
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(l)
	await _host.get_tree().create_timer(secs).timeout
	layer.queue_free()

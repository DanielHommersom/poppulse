class_name AdsBackend
extends RefCounted
## Advertising backend interface. Implementations: MockAds (desktop/debug) and
## AdMobAds (US-31). Only Platform talks to it.

## Rewarded result: true = watched to the end (grant the reward).
signal rewarded_finished(placement: String, completed: bool)
signal interstitial_closed(placement: String)


func initialize(_personalized: bool) -> void:
	pass


## Consent changed in Settings: later ad requests use the new choice.
func set_personalized(_personalized: bool) -> void:
	pass


func rewarded_ready(_placement: String) -> bool:
	return false


func show_rewarded(_placement: String) -> void:
	rewarded_finished.emit(_placement, false)


func interstitial_ready(_placement: String) -> bool:
	return false


func show_interstitial(placement: String) -> void:
	interstitial_closed.emit(placement)

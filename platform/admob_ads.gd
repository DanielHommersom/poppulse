class_name AdMobAds
extends AdsBackend
## AdMob via the Poing Studios "godot-admob" plugin v5.1 (addons/admob; iOS
## libraries in addons/admob/ios/bin, Godot 4.4–4.7.2). Only used on a device
## where the native plugin is present; desktop / debug use MockAds.
##
## Consent: Google's User Messaging Platform (UMP) shows the GDPR/TCF form
## where required. Apple's tracking prompt is NOT done here: Platform shows
## our own explainer + the GodotxATT request afterwards (keep AdMob's "IDFA
## explainer" message unpublished). Ad units: data/ads.json (test units in debug).

const SINGLETON := "PoingGodotAdMob"

var _units := {}
## Release builds: placement → its own rewarded ad unit (data/ads.json
## "rewarded.placements"), so AdMob reports per button. Empty / missing → the
## shared rewarded unit. Debug builds always use Google's test unit.
var _placement_units := {}
var _personalized := false
## Loaded rewarded ad per ad unit id.
var _rewarded := {}
var _interstitial: InterstitialAd
var _initialized := false
## Loader objects must stay referenced while they load.
var _loaders: Array = []


static func available() -> bool:
	return Engine.has_singleton(SINGLETON)


func _init(cfg: Dictionary, release := not OS.is_debug_build()) -> void:
	var os_key := "android" if OS.get_name() == "Android" else "ios"
	var which := "release" if release else "test"
	for kind in ["rewarded", "interstitial"]:
		_units[kind] = str(cfg.get("units", {}).get(os_key, {}).get(kind, {}).get(which, ""))
	if which == "release":
		var per: Dictionary = cfg.get("units", {}).get(os_key, {}).get("rewarded", {}).get("placements", {})
		for p in per:
			if str(per[p]).begins_with("ca-app-pub-"):
				_placement_units[p] = str(per[p])


## Ad unit a rewarded placement uses (its own one, else the shared unit).
func unit_for(placement: String) -> String:
	return str(_placement_units.get(placement, _units.rewarded))


## Every distinct rewarded unit, each preloaded once.
func rewarded_units() -> Array:
	var out := [str(_units.rewarded)]
	for u in _placement_units.values():
		if not u in out:
			out.append(u)
	return out


func initialize(personalized: bool) -> void:
	_personalized = personalized
	if _initialized:
		return
	_initialized = true
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		for unit in rewarded_units():
			_load_rewarded(unit)
		_load_interstitial()
	MobileAds.initialize(listener)


func set_personalized(personalized: bool) -> void:
	_personalized = personalized


func _request() -> AdRequest:
	var req := AdRequest.new()
	if not _personalized:
		req.extras = {"npa": "1"}  # non-personalised ads when consent was refused
	return req


func _load_rewarded(unit: String) -> void:
	var loader := RewardedAdLoader.new()
	_loaders.append(loader)
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded[unit] = ad
		_loaders.erase(loader)
	cb.on_ad_failed_to_load = func(_e: LoadAdError) -> void:
		_loaders.erase(loader)
		_retry(_load_rewarded.bind(unit))
	loader.load(unit, _request(), cb)


func _load_interstitial() -> void:
	var loader := InterstitialAdLoader.new()
	_loaders.append(loader)
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial = ad
		_loaders.erase(loader)
	cb.on_ad_failed_to_load = func(_e: LoadAdError) -> void:
		_loaders.erase(loader)
		_retry(_load_interstitial)
	loader.load(_units.interstitial, _request(), cb)


func _retry(fn: Callable) -> void:
	await Engine.get_main_loop().create_timer(30.0).timeout
	fn.call()


func rewarded_ready(placement: String) -> bool:
	return _rewarded.get(unit_for(placement)) != null


func interstitial_ready(_placement: String) -> bool:
	return _interstitial != null


func show_rewarded(placement: String) -> void:
	var unit := unit_for(placement)
	var ad: RewardedAd = _rewarded.get(unit)
	_rewarded.erase(unit)
	if ad == null:
		rewarded_finished.emit(placement, false)
		return
	var earned := [false]
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		# Reward and dismiss both arrive deferred from the native side; give a
		# reward that lands just after the dismiss a moment so it isn't lost.
		var until := Time.get_ticks_msec() + 500
		while not earned[0] and Time.get_ticks_msec() < until:
			await Engine.get_main_loop().process_frame
		rewarded_finished.emit(placement, earned[0])
		ad.destroy()
		_load_rewarded(unit)
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_e: AdError) -> void:
		rewarded_finished.emit(placement, false)
		ad.destroy()
		_load_rewarded(unit)
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void: earned[0] = true
	ad.show(listener)


func show_interstitial(placement: String) -> void:
	var ad := _interstitial
	_interstitial = null
	if ad == null:
		interstitial_closed.emit(placement)
		return
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		interstitial_closed.emit(placement)
		ad.destroy()
		_load_interstitial()
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_e: AdError) -> void:
		interstitial_closed.emit(placement)
		ad.destroy()
		_load_interstitial()
	ad.show()


# --- Consent (UMP) + App Tracking Transparency ----------------------------------------

## Runs Google's UMP flow; where required it shows the GDPR form.
## Resolves to "obtained" | "not_required" | "denied" | "error".
func request_consent() -> String:
	var info := UserMessagingPlatform.consent_information
	var done := [""]
	info.update(ConsentRequestParameters.new(),
		func() -> void: done[0] = "updated",
		func(_e: FormError) -> void: done[0] = "error")
	while done[0] == "":
		await Engine.get_main_loop().process_frame
	if done[0] == "error":
		return "error"
	if info.get_is_consent_form_available() and info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		done[0] = ""
		UserMessagingPlatform.load_consent_form(
			func(form: ConsentForm) -> void:
				form.show(func(_e: FormError) -> void: done[0] = "shown"),
			func(_e: FormError) -> void: done[0] = "shown")
		while done[0] == "":
			await Engine.get_main_loop().process_frame
	match info.get_consent_status():
		ConsentInformation.ConsentStatus.OBTAINED:
			return "obtained"
		ConsentInformation.ConsentStatus.NOT_REQUIRED:
			return "not_required"
	return "denied"


## True when UMP says the player must be able to revisit consent (EEA, UK,
## Switzerland, regulated US states). Known after request_consent() ran this
## session; elsewhere Google's form would simply not appear.
func privacy_options_required() -> bool:
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() \
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


## Settings ▸ "Change ad consent": Google's privacy options form. Resolves
## to the consent status after the form closes (same values as request_consent).
func show_privacy_options() -> String:
	var done := [false]
	UserMessagingPlatform.show_privacy_options_form(func(_e: FormError) -> void: done[0] = true)
	while not done[0]:
		await Engine.get_main_loop().process_frame
	match UserMessagingPlatform.consent_information.get_consent_status():
		ConsentInformation.ConsentStatus.OBTAINED:
			return "obtained"
		ConsentInformation.ConsentStatus.NOT_REQUIRED:
			return "not_required"
	return "denied"

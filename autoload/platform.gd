extends Node
## Platform services boundary (autoload "Platform").
## Every OS-specific call — haptics, IAP, ads, share and
## achievements later — goes through here so gameplay code never touches
## iOS or Android APIs directly. Native plugins are optional: when one is
## missing the call falls back to a portable implementation or a no-op.

enum Haptic { LIGHT, MEDIUM, HEAVY, ERROR }

## Native singleton exposed by ios/plugins/PopPulseNative (haptics + share sheet).
const NATIVE := "PopPulseNative"
## Minimum gap between two haptics. Taptic engines queue pulses; above ~25/s
## they smear into a buzz and start to lag behind the pops, so we drop extras.
const HAPTIC_MIN_GAP_MS := 40
## Per kind: [duration ms, amplitude] for Input.vibrate_handheld (Core Haptics on iOS).
const HAPTIC_FALLBACK := {
	Haptic.LIGHT: [10, 0.35],
	Haptic.MEDIUM: [18, 0.6],
	Haptic.HEAVY: [30, 1.0],
	Haptic.ERROR: [45, 0.8],
}

## Public privacy policy (US-38); see AppInfo for all public URLs.
const PRIVACY_URL := AppInfo.PRIVACY_URL
const SHARE_DIR := "user://share"

var haptics_enabled := true

var _native: Object
var _quiet := "--test-save" in OS.get_cmdline_user_args()
var _last_haptic_ms := -100000
var _last_haptic_kind := Haptic.LIGHT


func _ready() -> void:
	haptics_enabled = bool(SaveData.get_setting("haptics"))
	SaveData.setting_changed.connect(_on_setting)
	if Engine.has_singleton(NATIVE):
		_native = Engine.get_singleton(NATIVE)
		if _native.has_method("prepare_haptics"):
			_native.prepare_haptics()
	_setup_monetization()


func _process(_delta: float) -> void:
	if store:
		store.poll()


func _on_setting(key: String, value: Variant) -> void:
	if key == "haptics":
		haptics_enabled = bool(value)


# --- Haptics -----------------------------------------------------------------

func haptic(kind: Haptic) -> void:
	if not haptics_enabled or not OS.has_feature("mobile"):
		return
	var now := Time.get_ticks_msec()
	# Within the gap only a *stronger* pulse may replace the previous one.
	if now - _last_haptic_ms < HAPTIC_MIN_GAP_MS and kind <= _last_haptic_kind:
		return
	_last_haptic_ms = now
	_last_haptic_kind = kind
	if _native and _native.has_method("haptic"):
		# UIImpactFeedbackGenerator (light/medium/heavy) / UINotificationFeedbackGenerator (error).
		_native.haptic(int(kind))
		return
	var spec: Array = HAPTIC_FALLBACK[kind]
	Input.vibrate_handheld(int(spec[0]), float(spec[1]))


# --- Monetization (US-27) ----------------------------------------------------------
# One interface for purchases and ads; gameplay / UI never see StoreKit or
# AdMob. Backends: MockStore / MockAds on desktop & debug, real ones on device.

signal purchase_completed(product_id: String)
## reason: cancelled | error | pending (Ask to Buy)
signal purchase_failed(product_id: String, reason: String)
signal entitlements_changed
signal restore_completed(count: int)

const PRODUCTS_PATH := "res://data/products.json"

var store: StoreBackend
var ads: AdsBackend
var _products: Array = []


func _setup_monetization() -> void:
	_products = GameMode.load_config(PRODUCTS_PATH).get("products", [])
	store = _make_store()
	store.setup(_products)
	store.purchased.connect(_on_store_purchased)
	store.failed.connect(func(pid: String, reason: String) -> void: purchase_failed.emit(pid, reason))
	store.restore_finished.connect(func(n: int) -> void: restore_completed.emit(n))
	ads = _make_ads()
	SaveData.session_gap_s = int(GameMode.load_config("res://data/ads.json").get("session_gap_seconds", 1800))
	_resume_ads.call_deferred()


## RevenueCat on a device (iOS / Android) when its plugin and API key are
## there; the mock only in debug builds. A release build never falls back to
## the mock store, so Premium can never be "bought" for free.
func _make_store() -> StoreBackend:
	var rc_cfg: Dictionary = GameMode.load_config(PRODUCTS_PATH).get("revenuecat", {})
	var key := str(rc_cfg.get("android_api_key" if OS.get_name() == "Android" else "ios_api_key", ""))
	if RevenueCatStore.available() and key != "":
		return RevenueCatStore.new(Engine.get_singleton(RevenueCatStore.SINGLETON), key)
	if Engine.has_singleton("InAppStore"):
		return AppStore.new(Engine.get_singleton("InAppStore"))
	if OS.is_debug_build() or not OS.has_feature("mobile"):
		return MockStore.new(get_tree())
	push_error("Store unavailable: RevenueCat plugin or API key missing")
	return UnavailableStore.new()


## AdMob when the Poing Studios addon is installed (US-31); mock otherwise.
func _make_ads() -> AdsBackend:
	if OS.has_feature("mobile") and AdMobAds.available():
		return AdMobAds.new(GameMode.load_config("res://data/ads.json"))
	return MockAds.new(self)


# --- Consent: UMP → ATT → ads (US-31) ---------------------------------------------
# Order: (1) Google UMP consent form — shown by Google only in the EEA / UK and
# only after the player's first finished game; (2) Apple's ATT prompt; (3) the
# ads SDK starts, personalised only if both said yes. Never for Premium.

signal ads_initialized(personalized: bool)

var ads_started := false


func _ads_state() -> Dictionary:
	var a := SaveData.section("ads")
	if not a.has("consent_done"):
		a.consent_done = false
		a.personalized = false
	return a


## On launch: players who already went through consent get ads right away.
func _resume_ads() -> void:
	if bool(_ads_state().consent_done):
		start_ads_after_first_game()


## main.gd calls this after every finished run; the flow runs once.
func start_ads_after_first_game() -> void:
	if ads_started or ads_disabled():
		return
	ads_started = true
	var st := _ads_state()
	var consent := "obtained"
	if ads is AdMobAds:
		consent = await (ads as AdMobAds).request_consent()
	var tracking := await _request_tracking()
	st.consent_done = true
	st.consent = consent
	st.att = tracking
	st.personalized = consent in ["obtained", "not_required"] and tracking in ["authorized", "via_ump"]
	SaveData.mark_dirty()
	if ads_disabled():  # bought Premium meanwhile
		return
	ads.initialize(bool(st.personalized))
	ads_initialized.emit(bool(st.personalized))


## Apple ATT, after consent. Denied / restricted → non-personalised ads.
## Asks the UI for the in-game explanation before Apple's dialog; main.gd
## shows AttPrompt and answers with tracking_explainer_closed.
signal tracking_explainer_requested
signal tracking_explainer_closed

const ATT_SINGLETON := "GodotxATT"


func _request_tracking() -> String:
	if Engine.has_singleton(ATT_SINGLETON):
		var att := Engine.get_singleton(ATT_SINGLETON)
		if int(att.get_status()) == 0:  # not determined yet → explain, then ask
			if tracking_explainer_requested.get_connections().size() > 0:
				tracking_explainer_requested.emit()
				await tracking_explainer_closed
			att.request_permission()
			var until := Time.get_ticks_msec() + 120000
			while int(att.get_status()) == 0 and Time.get_ticks_msec() < until:
				await get_tree().create_timer(0.25).timeout
		return ["not_determined", "restricted", "denied", "authorized"][clampi(int(att.get_status()), 0, 3)]
	if ads is AdMobAds:
		# Google's UMP already showed Apple's prompt (IDFA explainer message in
		# AdMob ▸ Privacy & messaging); the Ads SDK reads the ATT answer itself.
		return "via_ump"
	if not (_native and _native.has_method("request_tracking_authorization")):
		return "authorized" if not OS.has_feature("ios") else "unavailable"
	if int(_native.tracking_status()) == 0:
		_native.request_tracking_authorization()
		var until := Time.get_ticks_msec() + 60000
		while int(_native.tracking_status()) == 0 and Time.get_ticks_msec() < until:
			await get_tree().create_timer(0.25).timeout
	return ["not_determined", "restricted", "denied", "authorized"][clampi(int(_native.tracking_status()), 0, 3)]


## Settings ▸ "Ad privacy": reopen Google's consent options.
## Settings shows "Change ad consent" only where Google's form can appear:
## a free player whose consent flow has run and who lives in a region that
## requires it. Debug/desktop builds always show it (mock) for testing.
func ad_privacy_options_available() -> bool:
	if ads_disabled() or not bool(_ads_state().consent_done):
		return false
	if ads is AdMobAds:
		return ads_started and (ads as AdMobAds).privacy_options_required()
	return OS.is_debug_build()


## Opens Google's privacy options and applies the new choice right away
## (the Ads SDK also reads the updated TCF string itself).
func show_ad_privacy_options() -> void:
	var st := _ads_state()
	var consent := str(st.get("consent", "obtained"))
	if ads is AdMobAds:
		consent = await (ads as AdMobAds).show_privacy_options()
	elif OS.is_debug_build():
		print("[Platform] ad privacy options (mock)")
	st.consent = consent
	st.personalized = consent in ["obtained", "not_required"] and str(st.get("att", "")) in ["authorized", "via_ump"]
	SaveData.mark_dirty()
	if ads:
		ads.set_personalized(bool(st.personalized))


func products() -> Array:
	return _products


func product(product_id: String) -> Dictionary:
	for p: Dictionary in _products:
		if p.id == product_id:
			return p
	return {}


## Owned (directly or through a bundle). Cached locally in SaveData, so it
## works offline and before the store answered.
func is_entitled(product_id: String) -> bool:
	return SaveData.has_entitlement(product_id)


func purchase(product_id: String) -> void:
	if is_entitled(product_id):
		purchase_completed.emit(product_id)
		return
	store.purchase(product_id)


func restore_purchases() -> void:
	store.restore()


## Localised price from the store ("" until known — never hardcoded).
func get_price(product_id: String) -> String:
	return store.price(product_id)


func _on_store_purchased(product_id: String) -> void:
	var p := product(product_id)
	var grants: Array = p.get("grants", [product_id])
	for g in grants:
		SaveData.set_entitlement(str(g), true)
	purchase_completed.emit(product_id)
	entitlements_changed.emit()


# --- Ads (US-27 / US-31…33) -----------------------------------------------------------------

## Premium players never see ads; rewarded perks are simply granted to them.
func ads_disabled() -> bool:
	return is_entitled("premium_unlock")


func can_show_rewarded(placement: String) -> bool:
	if ads_disabled():
		return true
	return ads_started and ads != null and ads.rewarded_ready(placement)


## Shows a rewarded ad; resolves true only if it was watched to the end.
func show_rewarded(placement: String) -> bool:
	if ads_disabled():
		return true
	if not can_show_rewarded(placement):
		return false
	ads.show_rewarded(placement)
	while true:
		var r: Array = await ads.rewarded_finished
		if r[0] == placement:
			return bool(r[1])
	return false


## Interstitial at a natural break; the frequency rules decide (US-33).
## Resolves true when an ad was actually shown.
func maybe_show_interstitial(placement: String) -> bool:
	if ads_disabled() or not ads_started or ads == null or not ads.interstitial_ready(placement):
		return false
	ads.show_interstitial(placement)
	await ads.interstitial_closed
	return true


# --- Share (US-20) ------------------------------------------------------------

## Opens the native share sheet with an image + text. Without the native plugin
## (desktop) the PNG is saved and revealed, and the text goes to the clipboard.
## Returns the saved file path.
func share_image(image: Image, text: String, reveal := true) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHARE_DIR))
	var path := ProjectSettings.globalize_path(SHARE_DIR + "/poppulse_result.png")
	image.save_png(path)
	var full := "%s %s" % [text, AppInfo.store_url()]
	if _native and _native.has_method("share_image"):
		_native.share_image(path, full)
	else:
		DisplayServer.clipboard_set(full)
		if reveal:
			OS.shell_show_in_file_manager(path)
	return path


## Settings ▸ Tell a friend: opens WhatsApp with a ready-made message
## (wa.me is a universal link: the app when installed, else WhatsApp Web).
func tell_a_friend() -> void:
	var text := "I'm hooked on %s — pop the glowing bubbles before they fade! Can you beat my score? %s" % [AppInfo.NAME, AppInfo.store_url()]
	open_url("https://wa.me/?text=" + text.uri_encode())


## Last URL opened (tests / dev scenarios check it instead of launching a browser).
var last_opened_url := ""


func open_url(url: String) -> void:
	last_opened_url = url
	if _quiet:
		return
	if _native and _native.has_method("open_url"):
		_native.open_url(url)
	else:
		OS.shell_open(url)


# --- Accessibility (US-36) ---------------------------------------------------------

## iOS Settings ▸ Accessibility ▸ Motion ▸ Reduce Motion.
func system_reduce_motion() -> bool:
	if _native and _native.has_method("system_reduce_motion"):
		return bool(_native.system_reduce_motion())
	return "--reduce-motion" in OS.get_cmdline_user_args()


# --- Screen ------------------------------------------------------------------

## Safe-area insets (notch, home indicator) converted to viewport units.
func safe_margins(viewport_size: Vector2) -> Dictionary:
	var m := {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	if not OS.has_feature("mobile"):
		# Desktop preview of an iPhone notch + home indicator: run with `-- --fake-notch`.
		if "--fake-notch" in OS.get_cmdline_user_args():
			m.top = viewport_size.x * 0.165
			m.bottom = viewport_size.x * 0.09
		return m
	var screen := Vector2(DisplayServer.screen_get_size())
	if screen.x <= 0.0 or screen.y <= 0.0:
		return m
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var k := viewport_size.x / screen.x
	m.top = safe.position.y * k
	m.bottom = (screen.y - safe.end.y) * k
	m.left = safe.position.x * k
	m.right = (screen.x - safe.end.x) * k
	return m

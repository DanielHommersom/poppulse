class_name PremiumPanel
extends Modal
## What Premium gives, the local price from the store, buy + restore.
## Premium is the game's only purchase.

const PRODUCT := "premium_unlock"

var _buy: Button
var _msg: Label
var _context := ""
## Locked Stage level the panel was opened for (0 = none): offers one rewarded run.
var _trial_level := 0

## Rewarded "play this level once" (US-32).
signal level_trial_requested(level_id: int)


func _init() -> void:
	super("PREMIUM", 600.0)


func _build() -> void:
	Platform.purchase_completed.connect(_on_done)
	Platform.purchase_failed.connect(_on_failed)
	Platform.store.prices_updated.connect(refresh)


## `context` = why it opened (record / level12 / locked_item / menu) — picks the headline.
## `level_id` > 0: a locked Stage level that may be played once after a video.
func open_for(context: String, level_id := 0) -> void:
	_context = context
	_trial_level = level_id
	open()


func _on_open() -> void:
	clear_body()
	var crown := NeonIcon.new("crown", UiStyle.GOLD)
	crown.custom_minimum_size = Vector2(0, 90)
	body.add_child(crown)
	var headline: String = {
		"record": "New record! Go further with Premium",
		"level12": "Levels 13–30 are waiting",
		"locked_item": "This is part of Premium",
	}.get(_context, "Unlock everything, once")
	var h := UiStyle.label(headline, 32, Color.WHITE, true)
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(h)
	var p := Platform.product(PRODUCT)
	for line in p.get("unlocks", []):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var ic := NeonIcon.new("check", UiStyle.OK)
		ic.custom_minimum_size = Vector2(36, 36)
		row.add_child(ic)
		row.add_child(UiStyle.label(str(line), 28, Color.WHITE, false, HORIZONTAL_ALIGNMENT_LEFT))
		body.add_child(row)
	body.add_child(UiStyle.label("One-time purchase · no subscription", 22, UiStyle.DIM_TEXT))
	var owned := Platform.is_entitled(PRODUCT)
	var price := Platform.get_price(PRODUCT)
	if owned:
		_buy = add_button("PREMIUM ACTIVE  ✓", UiStyle.OK, func() -> void: close(), true)
	else:
		_buy = add_button(("UNLOCK  " + price) if price != "" else "UNLOCK", UiStyle.GOLD, _on_buy, true)
		_buy.add_theme_font_size_override("font_size", 32)
		_buy.disabled = price == ""  # never sell without the store's real price
	_msg = UiStyle.label("" if price != "" or owned else "Connecting to the App Store…", 22, UiStyle.DIM_TEXT)
	body.add_child(_msg)
	if not owned and _trial_level > 0 and Platform.can_show_rewarded("level_trial"):
		var lvl := _trial_level
		add_button("▶ PLAY LEVEL %d ONCE" % lvl, UiStyle.OK, func() -> void: level_trial_requested.emit(lvl))
	add_button("RESTORE PURCHASES", Color(1, 1, 1, 0.7), _on_restore)


func _on_buy() -> void:
	_purchase(PRODUCT)


func _purchase(pid: String) -> void:
	_msg.text = "Opening the App Store…"
	_buy.disabled = true
	Platform.purchase(pid)


func _on_restore() -> void:
	_msg.text = "Restoring…"
	Platform.restore_purchases()
	var n: int = await Platform.restore_completed
	if is_instance_valid(_msg):
		_msg.text = "Restored %d item%s" % [n, "" if n == 1 else "s"] if n > 0 else "Nothing to restore"


func _on_done(pid: String) -> void:
	if not visible:
		return
	if pid == PRODUCT:
		Sfx.play_go()
		Platform.haptic(Platform.Haptic.HEAVY)
		close()


func _on_failed(_pid: String, reason: String) -> void:
	if not visible:
		return
	_buy.disabled = false
	match reason:
		"pending":
			_msg.text = "Waiting for approval (Ask to Buy)"
		"cancelled":
			_msg.text = ""
		_:
			_msg.text = "Purchase failed — please try again later"

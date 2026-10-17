class_name SettingsPanel
extends Modal
## The one menu behind the gear (top-right): Records / Style / Premium (and
## Event while one runs), then sound, haptics, accessibility, purchases and
## privacy. Only reachable outside a run (IDLE / RESULTS).

## A navigation row was tapped: "records" | "style" | "premium" | "event".
signal open_requested(target: String)


func _init() -> void:
	super("SETTINGS", 600.0)


func _on_open() -> void:
	clear_body()
	_nav_row("chart", "Records", "records")
	_nav_row("palette", "Style", "style")
	_nav_row("crown", "Premium", "premium")
	if not Events.active_event().is_empty():
		_nav_row("gift", str(Events.active_event().name), "event")
	add_section("SOUND")
	add_toggle("sound", "Sound", bool(SaveData.get_setting("sound")), _toggle.bind("sound"))
	add_toggle("vibrate", "Haptics", bool(SaveData.get_setting("haptics")), _toggle.bind("haptics"))
	add_section("SOUND PACK")
	add_toggle("palette", "Match theme", bool(SaveData.get_setting("sound_follows_theme")), _toggle.bind("sound_follows_theme"))
	_pack_ids.clear()
	var names := []
	for p: Dictionary in Sfx.packs():
		if ThemeManager.item_available("sound", p):
			_pack_ids.append(p.id)
			names.append(p.name)
	var sel := maxi(_pack_ids.find(Sfx.pack_id), 0)
	_pack_choice = add_choice("Pack", names, sel, _on_pack)
	_pack_choice.disabled = bool(SaveData.get_setting("sound_follows_theme"))
	add_section("ACCESSIBILITY")
	var rm_opts := ["auto", "on", "off"]
	add_choice("Reduce motion", ["Like iOS", "On", "Off"], maxi(rm_opts.find(str(SaveData.get_setting("reduce_motion"))), 0),
		func(i: int) -> void: SaveData.set_setting("reduce_motion", rm_opts[i]))
	add_toggle("target", "Symbols on lit bubbles", bool(SaveData.get_setting("symbols")), _toggle.bind("symbols"))
	add_section("PURCHASES")
	_restore_btn = add_button("RESTORE PURCHASES", UiStyle.CYAN, _on_restore)
	add_section("SPREAD THE WORD")
	_link_row("share", "Tell a friend", Platform.tell_a_friend, "WhatsApp")
	add_section("PRIVACY & LEGAL")
	if Platform.ad_privacy_options_available():
		add_button("CHANGE AD CONSENT", Color(1, 1, 1, 0.75), Platform.show_ad_privacy_options)
	_link_row("lock", "Privacy Policy", func() -> void: Platform.open_url(AppInfo.PRIVACY_URL))
	_link_row("doc", "Terms of Use", func() -> void: Platform.open_url(AppInfo.TERMS_URL))
	body.add_child(UiStyle.label("%s %s · Digital Diamonds" % [AppInfo.NAME, ProjectSettings.get_setting("application/config/version", "1.0")], 20, UiStyle.DIM_TEXT))


var _restore_btn: Button


func _on_restore() -> void:
	_restore_btn.disabled = true
	_restore_btn.text = "RESTORING…"
	Platform.restore_purchases()
	var n: int = await Platform.restore_completed
	if is_instance_valid(_restore_btn):
		_restore_btn.text = "RESTORED %d ITEM%s" % [n, "" if n == 1 else "S"] if n > 0 else "NOTHING TO RESTORE"
		_restore_btn.disabled = false


## Same row style for actions that leave the app (links, review, share);
## settings stay open behind them.
func _link_row(icon: String, text: String, cb: Callable, note := "") -> void:
	_row(icon, text, note, cb)


## Full-width row: icon, label, chevron. Closes settings and opens the target.
func _nav_row(icon: String, text: String, target: String) -> void:
	_row(icon, text, "", func() -> void:
		close()
		open_requested.emit(target))


func _row(icon: String, text: String, note: String, cb: Callable) -> void:
	var b := UiStyle.card_button(UiStyle.CYAN, false)
	b.custom_minimum_size = Vector2(0, 76)
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 18
	h.offset_right = -14
	h.add_theme_constant_override("separation", 16)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var ic := NeonIcon.new(icon, UiStyle.CYAN)
	ic.custom_minimum_size = Vector2(42, 42)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var l := UiStyle.label(text, 32, Color.WHITE, false, HORIZONTAL_ALIGNMENT_LEFT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	if note != "":
		h.add_child(UiStyle.label(note, 22, UiStyle.DIM_TEXT, false, HORIZONTAL_ALIGNMENT_RIGHT))
	var chev := NeonIcon.new("next", Color(1, 1, 1, 0.5))
	chev.custom_minimum_size = Vector2(30, 30)
	chev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(chev)
	b.pressed.connect(cb)
	body.add_child(b)


var _pack_ids: Array = []
var _pack_choice: OptionButton


func _on_pack(i: int) -> void:
	Sfx.set_pack(_pack_ids[i], true)
	Sfx.preview_pack(_pack_ids[i])


func _toggle(on: bool, key: String) -> void:
	SaveData.set_setting(key, on)
	if key == "sound_follows_theme" and _pack_choice:
		_pack_choice.disabled = on
		_pack_choice.selected = maxi(_pack_ids.find(Sfx.pack_id), 0)
	if key == "haptics" and on:
		Platform.haptic(Platform.Haptic.MEDIUM)
	elif key == "sound" and on:
		Sfx.play_pop(4)

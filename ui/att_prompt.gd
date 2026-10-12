class_name AttPrompt
extends Modal
## Our own explanation right before Apple's App Tracking Transparency dialog
## (shown once, after the first finished game and the consent form). Apple
## allows a pre-prompt as long as it doesn't pressure or reward; the only
## button continues to the system dialog, where the player decides.

signal continued


func _init() -> void:
	super("", 560.0)
	dismiss_on_backdrop = false
	closable = false


func _on_open() -> void:
	clear_body()
	var ic := NeonIcon.new("bubble", UiStyle.CYAN)
	ic.custom_minimum_size = Vector2(0, 96)
	body.add_child(ic)
	var title := UiStyle.label("Keep %s free" % AppInfo.NAME, 40, Color.WHITE, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(title)
	for line in [
		"%s is free to play thanks to ads." % AppInfo.NAME,
		"On the next screen, iOS asks whether ads may use your activity to be more relevant to you.",
		"Either choice is fine — the game plays exactly the same.",
	]:
		var l := UiStyle.label(line, 26, UiStyle.DIM_TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(l)
	add_button("CONTINUE", UiStyle.ACCENT, _on_continue, true)


func _on_continue() -> void:
	close()
	continued.emit()

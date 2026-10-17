extends Node
## Active visual theme (autoload "ThemeManager"). apply(id) swaps the look live:
## UiStyle colours change immediately and everything that draws with theme
## colours listens to `theme_changed` (board, background, HUD, panels).

signal theme_changed(theme: ThemeData)
signal design_changed(design: Dictionary)

## Theme files. Listed explicitly (not scanned) so exported builds — where
## .tres files may be converted/remapped — find them reliably.
const THEMES := [
	"res://themes/neon.tres",
	"res://themes/contrast.tres",
	"res://themes/sunset.tres",
	"res://themes/ice.tres",
	"res://themes/candy.tres",
	"res://themes/retro.tres",
	"res://themes/aurora.tres",
	"res://themes/galaxy.tres",
	"res://themes/ocean.tres",
	"res://themes/halloween.tres",
]

var current: ThemeData
var themes: Array[ThemeData] = []
## Bubble designs (US-25), independent of the theme. data/designs.json.
var designs: Array = []
var design: Dictionary = {}
## Temporary preview (theme picker / shop) without saving the choice.
var previewing := false


func _ready() -> void:
	for p in THEMES:
		var t: ThemeData = load(p)
		if t:
			themes.append(t)
	designs = GameMode.load_config("res://data/designs.json").get("designs", [])
	var saved := str(SaveData.get_setting("theme"))
	var t := get_theme(saved)
	# An expired 24 h trial (or a refunded pack) falls back to the default.
	apply(saved if t and is_available(t) else "neon", false)
	var d := str(SaveData.get_setting("design"))
	apply_design(d if get_design(d).size() > 0 and item_available("design", get_design(d)) else "round", false)


func get_theme(id: String) -> ThemeData:
	for t in themes:
		if t.id == id:
			return t
	return null


## `persist`: remember as the player's choice (false for previews).
func apply(id: String, persist := true) -> void:
	var t := get_theme(id)
	if t == null:
		return
	current = t
	previewing = not persist
	UiStyle.ACCENT = t.ui_accent
	UiStyle.CYAN = t.ui_cyan
	UiStyle.GOLD = t.ui_gold
	UiStyle.DANGER = t.ui_danger
	UiStyle.OK = t.ui_ok
	UiStyle.PANEL_BG = t.panel_bg
	UiStyle.PANEL_BORDER = t.panel_border
	UiStyle.INK = t.ink
	if persist:
		SaveData.set_setting("theme", id)
	theme_changed.emit(t)


## Ends a preview and returns to the saved theme.
func revert_preview() -> void:
	if previewing:
		apply(str(SaveData.get_setting("theme")), false)
		previewing = false


## Whether the player may use a theme. Gating rules: free; unlocked by an
## achievement; part of Premium (the one purchase); seasonal event.
func is_available(t: ThemeData) -> bool:
	match t.unlock:
		"achievement":
			return Achievements.is_unlocked(t.unlock_ref)
		"premium":
			return Platform.is_entitled("premium_unlock") or trial_active(trial_key("theme", t.id))
		"event":
			# Seasonal: free while its event runs, forever once the event is cleared.
			return SaveData.is_unlocked("themes", t.id) or Events.is_active(t.unlock_ref)
	return true


## Short, human status for pickers.
func status_text(t: ThemeData) -> String:
	if is_available(t):
		return "TRIAL" if t.unlock == "premium" and trial_active(trial_key("theme", t.id)) and not Platform.is_entitled("premium_unlock") else ""
	match t.unlock:
		"achievement":
			for d: Dictionary in Achievements.defs:
				if d.id == t.unlock_ref:
					return "Unlock: " + str(d.desc)
			return "Achievement"
		"premium":
			return "PREMIUM"
		"event":
			return "EVENT"
	return ""


## Rewarded "try for 24 h" (US-32): unix expiry per item in unlocks.trials.
## Themes use their bare id (older saves); bubble styles / sound packs "kind:id".
static func trial_key(kind: String, id: String) -> String:
	return id if kind == "theme" else "%s:%s" % [kind, id]


func trial_active(key: String) -> bool:
	return int(SaveData.section("unlocks").trials.get(key, 0)) > int(Time.get_unix_time_from_system())


## Bubble style / sound pack: its unlock rule is met, or a 24 h trial runs.
func item_available(kind: String, d: Dictionary) -> bool:
	var u := str(d.get("unlock", "free"))
	if is_unlock_met(u, str(d.get("unlock_ref", ""))):
		return true
	return u == "premium" and trial_active(trial_key(kind, str(d.get("id", ""))))


# --- Bubble designs (US-25) ---------------------------------------------------------

func get_design(id: String) -> Dictionary:
	for d: Dictionary in designs:
		if d.id == id:
			return d
	return {}


func shape() -> int:
	return int(design.get("shape", 0))


func apply_design(id: String, persist := true) -> void:
	var d := get_design(id)
	if d.is_empty():
		return
	design = d
	if persist:
		SaveData.set_setting("design", id)
	design_changed.emit(d)


func revert_design_preview() -> void:
	var saved := str(SaveData.get_setting("design"))
	if design.get("id", "") != saved:
		apply_design(saved, false)


## Same gating vocabulary as themes: free / achievement / premium.
func is_unlock_met(unlock: String, ref: String) -> bool:
	match unlock:
		"achievement":
			return Achievements.is_unlocked(ref)
		"premium":
			return Platform.is_entitled("premium_unlock")
	return true


func unlock_text(unlock: String, ref: String) -> String:
	match unlock:
		"achievement":
			for a: Dictionary in Achievements.defs:
				if a.id == ref:
					return "Unlock: " + str(a.desc)
			return "Achievement"
		"premium":
			return "PREMIUM"
	return ""

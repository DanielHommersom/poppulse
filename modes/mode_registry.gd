class_name ModeRegistry
extends RefCounted
## Single source of truth for which modes exist. main.gd only knows mode ids;
## adding a mode = one entry here + a GameMode subclass + a data file.

const MODES := {
	"score": {
		"script": "res://modes/score_mode.gd",
		"config": "res://data/score_mode.json",
		"name": "SCORE",
		"icon": "bolt",
		"color": Color(1.0, 0.25, 0.7),
		"blurb": "Pop lit bubbles before they fade. Chain hits for combos!",
	},
	"reflex": {
		"script": "res://modes/reflex_mode.gd",
		"config": "res://data/reflex_mode.json",
		"name": "REFLEX",
		"icon": "target",
		"color": Color(0.25, 0.95, 1.0),
		"record_unit": " ms",
		"blurb": "Wait for the flash, then tap it as fast as you can.",
	},
	"memory": {
		"script": "res://modes/memory_mode.gd",
		"config": "res://data/memory_mode.json",
		"name": "MEMORY",
		"icon": "brain",
		"color": Color(0.4, 1.0, 0.55),
		"blurb": "Watch and listen, then repeat the pattern. It grows each round.",
	},
	"stage": {
		"script": "res://modes/stage_mode.gd",
		"config": "res://data/stages/stages.json",
		"name": "STAGES",
		"icon": "stages",
		"color": Color(1.0, 0.85, 0.3),
		"record_unit": " ★",
		"blurb": "Clear level after level. Fast, clean clears earn stars.",
	},
}

## Menu cards that are not a GameMode of their own (they launch a flow that
## plays the real modes). Shown after the modes, in the same card style.
const MENU_ONLY := {
	"party": {
		"name": "PASS & PLAY",
		"icon": "people",
		"color": Color(0.75, 0.45, 1.0),
		"record_text": "2–4 P",
		"blurb": "2–4 players take turns on the same challenge. Pass the phone!",
	},
}

## Menu order. Ids that are not in MODES are skipped, so unfinished modes stay hidden.
const ORDER := ["score", "reflex", "memory", "stage"]


static func has(mode_id: String) -> bool:
	return MODES.has(mode_id)


static func ids() -> Array[String]:
	var out: Array[String] = []
	for id in ORDER:
		if MODES.has(id):
			out.append(id)
	return out


static func info(mode_id: String) -> Dictionary:
	return MODES.get(mode_id, MENU_ONLY.get(mode_id, {}))


## Every card in the main menu: the playable modes, then the menu-only entries.
static func menu_ids() -> Array[String]:
	var out := ids()
	for id in MENU_ONLY:
		out.append(id)
	return out


static func create(mode_id: String) -> GameMode:
	var entry: Dictionary = MODES[mode_id]
	var mode: GameMode = load(entry.script).new()
	mode.mode_id = mode_id
	mode.cfg = GameMode.load_config(entry.config)
	return mode


## Record text for menus without instantiating the mode ("-" when unplayed).
static func format_record(mode_id: String, value: int) -> String:
	if value == 0:
		return "-"
	var unit: String = info(mode_id).get("record_unit", "")
	return Hud.fmt(value) + unit

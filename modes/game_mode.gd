class_name GameMode
extends Node
@warning_ignore_start("unused_signal")
## Base class for every mode (Score, Reflex, Memory, Stage…).
## A mode owns rules and scoring and talks to the rest of the game only via
## signals, so presentation (effects, audio, haptics, HUD) stays out of it.

signal score_changed(score: int)
signal combo_changed(combo: int, multiplier: int, bumped: bool)
signal multiplier_up(multiplier: int)
signal combo_broken(previous: int)
signal time_changed(remaining: float, total: float)
signal target_hit(bubble: Bubble, points: int, reaction: float)
signal wrong_tap(bubble: Bubble, penalty: int)
signal target_missed(bubble: Bubble)
signal finished(results: Dictionary)
## Short status for the player ("TOO EARLY", "YOUR TURN"…). `kind` lets the
## presentation pick colour / sound: info, good, warn, bad, best.
signal announce(text: String, kind: String)
## Discrete progress (stimulus 3/10, round 4, targets 12/20).
signal progress(done: int, total: int)
## A measured reaction (Reflex). `personal_best` = fastest single reaction ever.
signal reaction(bubble: Bubble, ms: int, personal_best: bool)
## A target just lit up (first-run coach marks attach to it).
signal target_lit(bubble: Bubble)
## A bubble "speaks" (memory patterns): presentation plays its own tone `note`.
signal cue(bubble: Bubble, note: int)
## Mode wants board input on/off (e.g. while a pattern is being shown).
signal input_locked(locked: bool)

var mode_id := "base"
## Facts the game manager hands in before start() (records, first-run flags,
## daily-challenge overrides…), so modes never read the save themselves.
var context: Dictionary = {}
## Tuning loaded from the mode's JSON (see ModeRegistry); the debug overlay edits it live.
var cfg: Dictionary = {}
var board: Board
var running := false
## While paused nothing advances: mode time (and so every bubble lifetime) is frozen.
var paused := false
var elapsed := 0.0
var score := 0
var combo := 0
var multiplier := 1
## Per-run randomness. Seeded from context.seed (daily challenge, pass-and-play)
## so everyone gets the same sequence; random otherwise.
var rng := RandomNumberGenerator.new()


func setup(p_board: Board) -> void:
	board = p_board


# --- Hooks the game manager / HUD query (override per mode) -----------------

func get_duration() -> float:
	return 0.0


## Grid size this mode wants. Data-driven via "board": [cols, rows] in the config.
func board_size() -> Vector2i:
	var b: Variant = cfg.get("board")
	if b is Array and (b as Array).size() == 2:
		return Vector2i(int(b[0]), int(b[1]))
	return Vector2i(5, 6)


func uses_timer() -> bool:
	return true


func uses_combo() -> bool:
	return true


func uses_score() -> bool:
	return true


## False when the mode voices hits itself through `cue` (Memory).
func hit_sound() -> bool:
	return true


## Caption for the top-left readout when the mode has no timer ("STIMULUS", "ROUND"…).
func progress_caption() -> String:
	return "ROUND"


## Records: true when a smaller result is better (e.g. reaction time).
func lower_is_better() -> bool:
	return false


## How a record / result value is written in the UI.
func format_value(v: int) -> String:
	return Hud.fmt(v)


## Rewarded "continue" (US-32): text for the offer, "" when this result can't continue.
func continue_offer(_results: Dictionary) -> String:
	return ""


## Resumes a finished run with the continue bonus. The game manager runs a
## 3-2-1 countdown first and then calls set_paused(false).
func continue_run() -> void:
	pass


## True once the run used its one continue.
var continued := false


## Called by the debug tuning overlay after it edited `cfg`.
func on_tuning_changed() -> void:
	pass


# --- Lifecycle ---------------------------------------------------------------

func start() -> void:
	continued = false
	if context.has("seed"):
		rng.seed = int(context.seed)
	else:
		rng.randomize()
	running = true
	paused = false
	elapsed = 0.0
	score = 0
	combo = 0
	multiplier = 1


func stop() -> void:
	running = false
	paused = false


func set_paused(p: bool) -> void:
	paused = p


func on_bubble_pressed(_bubble: Bubble) -> void:
	pass


func _process(delta: float) -> void:
	if not running or paused:
		return
	elapsed += delta
	_tick(delta)


func _tick(_delta: float) -> void:
	pass


func pick(arr: Array) -> Variant:
	return arr[rng.randi() % arr.size()] if not arr.is_empty() else null


func shuffled(arr: Array) -> Array:
	var out := arr.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp: Variant = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


## Loads a JSON tuning file (exported as a resource, so no export filter needed).
static func load_config(path: String) -> Dictionary:
	var res = load(path)
	if res is JSON and (res as JSON).data is Dictionary:
		return ((res as JSON).data as Dictionary).duplicate(true)
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("Could not load config: %s" % path)
	return {}

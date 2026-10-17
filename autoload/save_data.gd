extends Node
## Local persistence (autoload "SaveData"). The only place that reads or writes
## the save file. Structure + migration live in core/save_store.gd. Progress
## stays on the device (no cloud sync).

signal setting_changed(key: String, value: Variant)
## Emitted after anything in the save changed (records, unlocks, stars…).
signal changed

const PATH := "user://save.json"
const LEGACY_PATH := "user://save.cfg"
const TEST_PATH := "user://test_save.json"
const SETTING_DEFAULTS := {
	"sound": true,
	"haptics": true,
	"last_mode": "score",
	"theme": "neon",
	"design": "round",
	"sound_pack": "classic",
	"sound_follows_theme": true,
	"reduce_motion": "auto",
	"symbols": false,
}

var store: SaveStore
var _dirty := false
## Finished games in the current session (ad rules, US-33).
var session_runs := 0
## A comeback after this long in the background starts a new session (iOS keeps
## apps alive for hours, so cold starts alone undercount sessions).
var session_gap_s := 1800
var _backgrounded_at := 0


## Loaded in _init (not _ready) so other autoloads can read the save no matter
## in which order the editor lists them in project.godot.
func _init() -> void:
	var test := "--test-save" in OS.get_cmdline_user_args()
	if test and "--fresh" in OS.get_cmdline_user_args():
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + suffix))
	store = SaveStore.new(TEST_PATH if test else PATH, "" if test else LEGACY_PATH)
	store.load_or_create()
	var stats: Dictionary = store.data.stats
	stats.sessions = int(stats.sessions) + 1
	if int(stats.first_open) == 0:
		stats.first_open = int(Time.get_unix_time_from_system())
	save_now()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_PREDELETE]:
		if _dirty:
			save_now()
	if what == NOTIFICATION_APPLICATION_PAUSED:
		went_background(int(Time.get_unix_time_from_system()))
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		came_foreground(int(Time.get_unix_time_from_system()))


func went_background(now: int) -> void:
	if _backgrounded_at == 0:
		_backgrounded_at = now


## Back after `session_gap_s` or more counts as a new session.
func came_foreground(now: int) -> void:
	if _backgrounded_at > 0 and now - _backgrounded_at >= session_gap_s:
		var stats: Dictionary = store.data.stats
		stats.sessions = int(stats.sessions) + 1
		session_runs = 0
		mark_dirty()
	_backgrounded_at = 0


## Batches writes (at most one atomic save per 0.5 s); forced on pause / quit.
func mark_dirty() -> void:
	changed.emit()
	if not _dirty:
		_dirty = true
		get_tree().create_timer(0.5, true, false, true).timeout.connect(_flush)


func _flush() -> void:
	if _dirty:
		save_now()


func save_now() -> void:
	_dirty = false
	store.save()


## Live sub-dictionary (e.g. "daily", "stage", "flags"). Call mark_dirty() after editing.
func section(name: String) -> Dictionary:
	if not store.data.has(name):
		store.data[name] = {}
	return store.data[name]


# --- Settings ------------------------------------------------------------------

func get_setting(key: String) -> Variant:
	return section("settings").get(key, SETTING_DEFAULTS.get(key))


func set_setting(key: String, value: Variant) -> void:
	section("settings")[key] = value
	mark_dirty()
	setting_changed.emit(key, value)


# --- Mode records & stats ---------------------------------------------------

func get_best(mode_id: String) -> int:
	return int(store.mode(mode_id).best)


func mode_stats(mode_id: String) -> Dictionary:
	return store.mode(mode_id)


## Records a finished run (best, count, play time, last N). True on a new best.
func submit_result(mode_id: String, value: int, lower_is_better := false, duration := 0.0) -> bool:
	var is_new := store.submit_result(mode_id, value, lower_is_better, duration)
	mark_dirty()
	return is_new


func undo_last_result(mode_id: String, value: int, duration: float, prev_best: int) -> void:
	store.undo_last(mode_id, value, duration, prev_best)
	mark_dirty()


func submit_score(mode_id: String, score: int) -> bool:
	return submit_result(mode_id, score)


# --- Flags (first-run hints etc.) -------------------------------------------

func get_flag(key: String, default: Variant = false) -> Variant:
	return section("flags").get(key, default)


func set_flag(key: String, value: Variant = true) -> void:
	section("flags")[key] = value
	mark_dirty()


# --- Stage progress -----------------------------------------------------------

func get_stars(level_id: int) -> int:
	return int(section("stage").stars.get(str(level_id), 0))


## Keeps the best star count per level. Returns true when it improved.
func set_stars(level_id: int, stars: int) -> bool:
	var s: Dictionary = section("stage").stars
	if stars <= int(s.get(str(level_id), 0)):
		return false
	s[str(level_id)] = stars
	mark_dirty()
	return true


func total_stars() -> int:
	var n := 0
	for v in section("stage").stars.values():
		n += int(v)
	return n


# --- Unlocks & entitlements ---------------------------------------------------

func has_entitlement(product_id: String) -> bool:
	return bool(section("unlocks").entitlements.get(product_id, false))


func set_entitlement(product_id: String, owned: bool) -> void:
	var e: Dictionary = section("unlocks").entitlements
	if bool(e.get(product_id, false)) == owned:
		return
	e[product_id] = owned
	mark_dirty()


## kind: "themes" | "designs" | "sound_packs"
func is_unlocked(kind: String, id: String) -> bool:
	return id in (section("unlocks").get(kind, []) as Array)


func unlock(kind: String, id: String) -> bool:
	var u: Dictionary = section("unlocks")
	if not u.has(kind):
		u[kind] = []
	var arr: Array = u[kind]
	if id in arr:
		return false
	arr.append(id)
	mark_dirty()
	return true


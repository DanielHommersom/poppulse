class_name SaveStore
extends RefCounted
## Versioned, crash-safe save file (pure logic, no autoload) so tests can run it
## against throw-away paths. The SaveData autoload wraps one instance.
##
## Writes are atomic: data goes to `<path>.tmp`, the previous file is kept as
## `<path>.bak`, then the temp file is renamed over the real one. A crash at any
## point leaves either the old or the new file intact; load() falls back to the
## backup when the main file is missing or unreadable.

const VERSION := 2
const RECENT_MAX := 20

var path: String
var legacy_cfg_path: String  # v1 ConfigFile save, migrated on first load
var data: Dictionary = {}


func _init(p_path: String, p_legacy_cfg := "") -> void:
	path = p_path
	legacy_cfg_path = p_legacy_cfg


static func blank() -> Dictionary:
	return {
		"version": VERSION,
		"settings": {},
		"modes": {},
		"stage": {"stars": {}, "best_time": {}},
		"unlocks": {"entitlements": {}, "themes": [], "designs": [], "sound_packs": [], "trials": {}},
		"daily": {"results": {}, "max_day": 0, "streak": 0, "best_streak": 0, "last_day": -1, "extra_attempts": {}},
		"flags": {},
		"achievements": {"unlocked": {}, "counters": {}},
		"cosmetics": {},
		"stats": {"sessions": 0, "first_open": 0},
	}


## Loads (and migrates) the save. Returns true when existing data was found.
func load_or_create() -> bool:
	for p in [path, path + ".bak"]:
		var parsed: Variant = _read_json(p)
		if parsed is Dictionary:
			data = migrate(parsed)
			return true
	if legacy_cfg_path != "" and FileAccess.file_exists(legacy_cfg_path):
		data = migrate(_read_v1(legacy_cfg_path))
		save()
		return true
	data = blank()
	return false


func save() -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveStore: cannot write %s" % tmp)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.flush()
	f.close()
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var bak := ProjectSettings.globalize_path(path + ".bak")
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(bak)
		DirAccess.rename_absolute(abs_path, bak)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), abs_path) == OK


## Brings any older structure up to VERSION and fills missing sections, so new
## fields added in later app versions never crash an old save.
static func migrate(d: Dictionary) -> Dictionary:
	var v := int(d.get("version", 1))
	if v < 2:
		d = _v1_to_v2(d)
	var out := blank()
	for k in d:
		if out.has(k) and out[k] is Dictionary and d[k] is Dictionary:
			var merged: Dictionary = out[k]
			merged.merge(d[k], true)
			out[k] = merged
		else:
			out[k] = d[k]
	out.version = VERSION
	return out


## v1 was a ConfigFile: [best] mode_id=score, [settings] key=value.
static func _v1_to_v2(v1: Dictionary) -> Dictionary:
	var d := blank()
	var best: Dictionary = v1.get("best", {})
	for mode_id in best:
		var m := empty_mode()
		m.best = int(best[mode_id])
		m.played = 1 if m.best > 0 else 0
		d.modes[mode_id] = m
	(d.settings as Dictionary).merge(v1.get("settings", {}), true)
	return d


static func empty_mode() -> Dictionary:
	return {"best": 0, "played": 0, "time_played": 0.0, "total": 0, "recent": [], "best_at": 0}


static func _read_v1(p: String) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(p) != OK:
		return {"version": 1}
	var d := {"version": 1}
	for section in cfg.get_sections():
		var s := {}
		for key in cfg.get_section_keys(section):
			s[key] = cfg.get_value(section, key)
		d[section] = s
	return d


static func _read_json(p: String) -> Variant:
	if not FileAccess.file_exists(p):
		return null
	var text := FileAccess.get_file_as_string(p)
	if text.is_empty():
		return null
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("SaveStore: %s is corrupt (%s)" % [p, json.get_error_message()])
		return null
	return json.data


# --- Mode results -------------------------------------------------------------

func mode(mode_id: String) -> Dictionary:
	var modes: Dictionary = data.modes
	if not modes.has(mode_id):
		modes[mode_id] = empty_mode()
	return modes[mode_id]


## Records one finished run. Returns true when it is a new personal best.
func submit_result(mode_id: String, value: int, lower_is_better := false, duration := 0.0) -> bool:
	var m := mode(mode_id)
	m.played = int(m.played) + 1
	m.time_played = float(m.time_played) + duration
	m.total = int(m.total) + value
	if value > 0:  # a run without any valid result (e.g. all misses) has no value to chart
		var recent: Array = m.recent
		recent.append(value)
		while recent.size() > RECENT_MAX:
			recent.pop_front()
	var best := int(m.best)
	var is_new := value > 0 and (best == 0 or (value < best if lower_is_better else value > best))
	if is_new:
		m.best = value
		m.best_at = int(Time.get_unix_time_from_system())
	return is_new


## Takes back the last submit_result (a run that was continued with a rewarded
## ad is recorded once, when it really ends). The best is only lowered when
## that very run had set it.
func undo_last(mode_id: String, value: int, duration: float, prev_best: int) -> void:
	var m := mode(mode_id)
	m.played = maxi(int(m.played) - 1, 0)
	m.time_played = maxf(float(m.time_played) - duration, 0.0)
	m.total = int(m.total) - value
	var recent: Array = m.recent
	if value > 0 and not recent.is_empty() and int(recent.back()) == value:
		recent.pop_back()
	m.best = prev_best

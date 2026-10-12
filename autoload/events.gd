extends Node
## Seasonal events (autoload "Events", US-41). Definitions come from
## data/events/events.json and can be replaced without an app update by a
## remote JSON (CDN, "remote_url"): it is fetched in the background, validated,
## cached in user:// and only used when its "version" is newer. Any failure
## falls back to the cached or built-in data.

signal events_updated
## All challenges of an event cleared (its theme is now kept for good).
signal event_completed(event: Dictionary)

const BUILTIN := "res://data/events/events.json"
const CACHE := "user://events_cache.json"

var data: Dictionary = {}
var _http: HTTPRequest


func _ready() -> void:
	data = GameMode.load_config(BUILTIN)
	var cached: Variant = JSON.parse_string(FileAccess.get_file_as_string(CACHE)) if FileAccess.file_exists(CACHE) else null
	if cached is Dictionary and valid(cached) and int(cached.get("version", 0)) > int(data.get("version", 0)):
		data = cached
	if str(data.get("remote_url", "")) != "" and not "--test-save" in OS.get_cmdline_user_args():
		_fetch.call_deferred()


func _fetch() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 10.0
	add_child(_http)
	_http.request_completed.connect(_on_fetched)
	if _http.request(str(data.remote_url)) != OK:
		_http.queue_free()


func _on_fetched(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	_http.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	apply_remote(body.get_string_from_utf8())


## Accepts a remote definition when it is valid and newer. Returns true if used.
func apply_remote(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary and valid(parsed)):
		return false
	if int(parsed.get("version", 0)) <= int(data.get("version", 0)):
		return false
	data = parsed
	var f := FileAccess.open(CACHE, FileAccess.WRITE)
	f.store_string(text)
	events_updated.emit()
	return true


static func valid(d: Dictionary) -> bool:
	if not d.has("events") or not d.events is Array:
		return false
	for e in d.events:
		if not (e is Dictionary and e.has("id") and e.has("start") and e.has("end") and e.get("challenges") is Array):
			return false
		for c in e.challenges:
			if not (c is Dictionary and ModeRegistry.has(str(c.get("mode", ""))) and c.has("goal")):
				return false
	return true


static func _today_str() -> String:
	return Time.get_date_string_from_unix_time(Daily.now_unix())


func active_event() -> Dictionary:
	var today := _today_str()
	for e: Dictionary in data.get("events", []):
		if str(e.start) <= today and today <= str(e.end):
			return e
	return {}


func is_active(event_id: String) -> bool:
	return active_event().get("id", "") == event_id


func days_left(e: Dictionary) -> int:
	var end := Time.get_unix_time_from_datetime_string(str(e.end) + "T23:59:59")
	return maxi(int(ceil((end - Daily.now_unix()) / 86400.0)), 0)


# --- Progress -------------------------------------------------------------------------

func _progress(event_id: String) -> Dictionary:
	var s := SaveData.section("events")
	if not s.has(event_id):
		s[event_id] = {}
	return s[event_id]


func best(event_id: String, index: int) -> int:
	return int(_progress(event_id).get(str(index), 0))


func is_cleared(e: Dictionary, index: int) -> bool:
	var c: Dictionary = e.challenges[index]
	var b := best(e.id, index)
	if b <= 0:
		return false
	return b <= int(c.goal) if bool(c.get("lower_is_better", false)) else b >= int(c.goal)


func cleared_count(e: Dictionary) -> int:
	var n := 0
	for i in (e.challenges as Array).size():
		if is_cleared(e, i):
			n += 1
	return n


## Records a run of challenge `index`; unlocks the event theme when all are cleared.
func submit(e: Dictionary, index: int, value: int) -> void:
	if value <= 0:
		return
	var c: Dictionary = e.challenges[index]
	var p := _progress(e.id)
	var prev := int(p.get(str(index), 0))
	var lower := bool(c.get("lower_is_better", false))
	if prev == 0 or (value < prev if lower else value > prev):
		p[str(index)] = value
		SaveData.mark_dirty()
	if cleared_count(e) == (e.challenges as Array).size() and str(e.get("theme", "")) != "":
		if SaveData.unlock("themes", str(e.theme)):
			event_completed.emit(e)


## Same seed for every player of an event challenge.
static func seed_for(e: Dictionary, index: int) -> int:
	return hash("poppulse-event-%s-%d" % [e.id, index])

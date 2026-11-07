class_name AdConfig
extends RefCounted
## Interstitial rules that can be tuned after launch without an app update.
## Built-in values: data/ads.json → "interstitial" + "session_gap_seconds".
## A remote file (docs/ads-config.json on GitHub Pages) may override them when
## its "version" is newer than the cached one; every value is range-checked, and
## anything unknown, missing or out of range keeps the built-in value.

const BUILTIN := "res://data/ads.json"
const CACHE := "user://ads_config_cache.json"
const REMOTE_URL := "https://danielhommersom.github.io/poppulse/ads-config.json"

## key → [min, max] for numbers; bools are listed separately. Bounds keep a typo
## in the remote file from turning the game into an ad wall (or switching ads off).
const NUMBER_BOUNDS := {
	"min_sessions": [1, 10],
	"first_session_after_runs": [1, 20],
	"runs_between": [1, 20],
	"min_seconds_between": [30, 900],
	"session_gap_seconds": [300, 86400],
}
const BOOL_KEYS := ["skip_after_record", "skip_first_run_per_mode", "skip_after_rewarded"]


## Built-in rules with the cached remote overrides applied.
static func load_rules() -> Dictionary:
	var all := GameMode.load_config(BUILTIN)
	var rules: Dictionary = (all.get("interstitial", {}) as Dictionary).duplicate(true)
	rules["session_gap_seconds"] = int(all.get("session_gap_seconds", 1800))
	var cached := read_cache()
	if not cached.is_empty():
		rules.merge(sanitize(cached), true)
	return rules


## Only known keys, right types, inside the bounds.
static func sanitize(remote: Dictionary) -> Dictionary:
	var src: Dictionary = remote.get("interstitial", {}) if remote.get("interstitial") is Dictionary else {}
	var out := {}
	for k in NUMBER_BOUNDS:
		var v: Variant = src.get(k, remote.get(k) if k == "session_gap_seconds" else null)
		if v is float or v is int:
			var b: Array = NUMBER_BOUNDS[k]
			if float(v) >= float(b[0]) and float(v) <= float(b[1]):
				out[k] = int(v)
	for k in BOOL_KEYS:
		if src.get(k) is bool:
			out[k] = src[k]
	return out


static func read_cache() -> Dictionary:
	if not FileAccess.file_exists(CACHE):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CACHE))
	return parsed if parsed is Dictionary else {}


## Stores a fetched file when it is valid and newer than the cache. Returns true if used.
static func apply_remote(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary or not parsed.has("version"):
		return false
	if int(parsed.version) <= int(read_cache().get("version", 0)):
		return false
	if sanitize(parsed).is_empty():
		return false
	var f := FileAccess.open(CACHE, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	return true

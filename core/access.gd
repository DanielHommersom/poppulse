class_name Access
extends RefCounted
## Accessibility switches (US-36), read by presentation code.

## Setting "reduce_motion": "auto" follows iOS Settings ▸ Accessibility ▸ Motion.
static func reduce_motion() -> bool:
	match str(SaveData.get_setting("reduce_motion")):
		"on":
			return true
		"off":
			return false
	return Platform.system_reduce_motion()


## Lit targets get a symbol, so "lit" never depends on colour/brightness alone.
static func symbols() -> bool:
	return bool(SaveData.get_setting("symbols"))

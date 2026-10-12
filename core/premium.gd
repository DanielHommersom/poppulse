class_name Premium
extends RefCounted
## What the one-time Premium unlock gates (US-29). Everything else is free.

const PRODUCT := "premium_unlock"
## Stage levels 1..FREE_STAGE_LEVELS are free; the rest need Premium.
const FREE_STAGE_LEVELS := 12


static func active() -> bool:
	return Platform.is_entitled(PRODUCT)


static func stage_level_locked(id: int) -> bool:
	return id > FREE_STAGE_LEVELS and not active()


## Full Reflex history graph + trend in results and the records screen.
static func reflex_stats_locked() -> bool:
	return not active()

class_name AdRules
extends RefCounted
## Interstitial frequency rules (US-33). Pure function so the rules are unit
## tested; every threshold comes from data/ads.json → "interstitial".

## state: {runs_since: int, last_shown: unix s}  (SaveData "ads" section)
## ctx: {sessions, session_runs, premium, is_record, first_run_of_mode, rewarded, placement, now}
static func may_show(cfg: Dictionary, state: Dictionary, ctx: Dictionary) -> bool:
	if bool(ctx.get("premium", false)):
		return false
	if not str(ctx.get("placement", "")) in (cfg.get("placements", []) as Array):
		return false  # only at results → menu / next run, never mid-game
	if int(ctx.get("sessions", 1)) < int(cfg.get("min_sessions", 2)) \
			and int(ctx.get("session_runs", 0)) < int(cfg.get("first_session_after_runs", 1 << 30)):
		return false  # first session: only after a few finished games
	if int(state.get("runs_since", 0)) < int(cfg.get("runs_between", 3)):
		return false
	if int(ctx.get("now", 0)) - int(state.get("last_shown", 0)) < int(cfg.get("min_seconds_between", 120)):
		return false
	if bool(cfg.get("skip_after_record", true)) and bool(ctx.get("is_record", false)):
		return false
	if bool(cfg.get("skip_first_run_per_mode", false)) and bool(ctx.get("first_run_of_mode", false)):
		return false  # the very first game of a mode stays ad-free
	if bool(cfg.get("skip_after_rewarded", true)) and bool(ctx.get("rewarded", false)):
		return false
	return true

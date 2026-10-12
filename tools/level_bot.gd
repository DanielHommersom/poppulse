extends Node
## Dev-only: plays every Stage level with simulated players to check that
## levels are clearable and star thresholds reachable. Headless, sped up:
##   Godot --headless --path . res://tools/level_bot.tscn -- --test-save [--runs=3]
## Writes res://_capture/level_bot.json.

const PROFILES := {
	# reaction mean/sd (s), travel between taps (s), mis-tap rate, decoy-tap rate
	"casual": {"react": 0.42, "sd": 0.08, "travel": 0.16, "err": 0.03, "decoy": 0.08},
	"skilled": {"react": 0.30, "sd": 0.05, "travel": 0.11, "err": 0.01, "decoy": 0.02},
}

var board: Board
var mode: StageMode
var profile: Dictionary
var _seen := {}
var _busy_until := 0.0
var _result: Dictionary
var _done := false


func _ready() -> void:
	Engine.time_scale = 8.0
	var runs := 3
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--runs="):
			runs = int(a.get_slice("=", 1))
	board = Board.new()
	add_child(board)
	var report := {}
	for pname in PROFILES:
		profile = PROFILES[pname]
		report[pname] = {}
		for id in range(1, StageLevels.count() + 1):
			var rs := []
			for r in runs:
				rs.append(await _play(id))
			report[pname][str(id)] = rs
			var wins := rs.filter(func(x): return x.won).size()
			print("%-8s L%02d wins %d/%d  times %s  mistakes %s" % [pname, id, wins, runs,
				str(rs.map(func(x): return snappedf(x.time, 0.1))), str(rs.map(func(x): return x.mistakes))])
	var f := FileAccess.open("res://_capture/level_bot.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	get_tree().quit()


func _play(id: int) -> Dictionary:
	if mode:
		mode.queue_free()
	mode = StageMode.new()
	mode.cfg = {}
	mode.context = {"level_id": id}
	add_child(mode)
	mode.setup(board)
	var size := mode.board_size()
	board.build(size.x, size.y)
	board.layout(Rect2(0, 0, 700, 800))
	await get_tree().process_frame
	_seen.clear()
	_busy_until = 0.0
	_done = false
	mode.finished.connect(func(r: Dictionary) -> void:
		_result = r
		_done = true)
	mode.start()
	while not _done:
		await get_tree().process_frame
		_bot_step()
	board.reset_all()
	return {"won": _result.won, "stars": _result.stars, "time": _result.time, "mistakes": _result.mistakes, "hits": _result.hits}


func _bot_step() -> void:
	if not mode.running:
		return
	var now := mode.elapsed
	for b: Bubble in mode._active:
		if not _seen.has(b) or _seen[b].lit_at != b.lit_at:
			var tap_decoy := b.decoy and randf() < float(profile.decoy)
			_seen[b] = {"lit_at": b.lit_at, "at": now + maxf(0.15, randfn(profile.react, profile.sd)), "tap": (not b.decoy) or tap_decoy}
	if now < _busy_until:
		return
	var best: Bubble = null
	for b: Bubble in mode._active:
		var s: Dictionary = _seen[b]
		if s.tap and now >= float(s.at) and (best == null or b.lit_at < best.lit_at):
			best = b
	if best == null:
		return
	_busy_until = now + float(profile.travel)
	if randf() < float(profile.err):
		var idle := board.bubbles.filter(func(x: Bubble) -> bool: return x.state == Bubble.State.IDLE and not (x in mode._active))
		if not idle.is_empty():
			mode.on_bubble_pressed(idle.pick_random())
			return
	mode.on_bubble_pressed(best)

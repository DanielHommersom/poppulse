extends Node
## Audio (autoload "Sfx"). All sounds are synthesised, so the game ships
## without audio assets. A sound pack (data/sound_packs.json) is a set of synth
## parameters per category: pop (one per note of the combo scale), miss,
## expire, tick and go. Packs can follow the active theme or be chosen freely.

const MIX_RATE := 44100
const POOL_SIZE := 10
const PACKS_PATH := "res://data/sound_packs.json"
## Major pentatonic: combos climb this scale, so streaks literally sound better.
const SCALE := [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66, 1318.51, 1567.98, 1760.0]

var enabled := true
var pack_id := "classic"

var _packs: Array = []
var _cache := {}  # pack id -> {pops, miss, expire, tick, go}
var _pops: Array[AudioStreamWAV] = []
var _miss: AudioStreamWAV
var _expire: AudioStreamWAV
var _tick: AudioStreamWAV
var _go: AudioStreamWAV
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _preview_until := 0


func _ready() -> void:
	_packs = GameMode.load_config(PACKS_PATH).get("packs", [])
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	enabled = bool(SaveData.get_setting("sound"))
	SaveData.setting_changed.connect(_on_setting)
	ThemeManager.theme_changed.connect(func(_t: ThemeData) -> void: _sync_pack())
	_sync_pack()


func _on_setting(key: String, value: Variant) -> void:
	if key == "sound":
		enabled = bool(value)
	elif key == "sound_follows_theme" or key == "sound_pack":
		_sync_pack()


func packs() -> Array:
	return _packs


func get_pack(id: String) -> Dictionary:
	for p: Dictionary in _packs:
		if p.id == id:
			return p
	return {}


## Pack that should be active now: the theme's pack (when "match theme" is on and
## the player owns it) or the explicitly chosen one.
func _sync_pack() -> void:
	var id := str(SaveData.get_setting("sound_pack"))
	if bool(SaveData.get_setting("sound_follows_theme")) and ThemeManager.current:
		var tp := ThemeManager.current.sfx_pack
		var d := get_pack(tp)
		if not d.is_empty() and ThemeManager.is_unlock_met(str(d.get("unlock", "free")), str(d.get("unlock_ref", ""))):
			id = tp
	_load_pack(id if not get_pack(id).is_empty() else "classic")


## Explicit choice from the style sheet / settings: also stops following the theme.
func set_pack(id: String, persist := true) -> void:
	if persist:
		SaveData.set_setting("sound_follows_theme", false)
		SaveData.set_setting("sound_pack", id)
	_load_pack(id)


## Plays a short phrase in a pack without changing the active one.
func preview_pack(id: String) -> void:
	var prev := pack_id
	_load_pack(id)
	for i in 4:
		get_tree().create_timer(i * 0.11).timeout.connect(play_pop.bind(i * 2))
	get_tree().create_timer(0.5).timeout.connect(play_go)
	if prev != id:
		get_tree().create_timer(0.9).timeout.connect(_load_pack.bind(prev))


func _load_pack(id: String) -> void:
	pack_id = id
	if not _cache.has(id):
		_cache[id] = _build(get_pack(id))
	var c: Dictionary = _cache[id]
	_pops.assign(c.pops)
	_miss = c.miss
	_expire = c.expire
	_tick = c.tick
	_go = c.go


func pop_steps() -> int:
	return _pops.size()


func play_pop(step: int, variation := 0.0) -> void:
	_play(_pops[clampi(step, 0, _pops.size() - 1)], 1.0 + randf_range(-variation, variation))


func play_miss() -> void:
	_play(_miss)


func play_expire() -> void:
	_play(_expire, 1.0, -4.0)


func play_tick() -> void:
	_play(_tick)


func play_go() -> void:
	_play(_go)


func _play(stream: AudioStream, pitch := 1.0, volume_db := 0.0) -> void:
	if not enabled or stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()


# --- Synthesis -----------------------------------------------------------------------

func _build(pack: Dictionary) -> Dictionary:
	var pops: Array[AudioStreamWAV] = []
	var pop: Dictionary = pack.get("pop", {"type": "bloop"})
	var k := float(pop.get("pitch", 1.0))
	for f in SCALE:
		match str(pop.get("type", "bloop")):
			"snap":
				pops.append(_make_snap(f * k))
			"chip":
				pops.append(_make_chip(f * k))
			"bell":
				pops.append(_make_bell(f * k))
			"drop":
				pops.append(_make_drop(f * k))
			_:
				pops.append(_make_pop(f * k))
	return {
		"pops": pops,
		"miss": _tone_from(pack.get("miss", {"freq": 140, "len": 0.22, "wave": "square", "gain": 0.3, "sweep": -40})),
		"expire": _tone_from(pack.get("expire", {"freq": 330, "len": 0.2, "wave": "sine", "gain": 0.22, "sweep": -700})),
		"tick": _tone_from(pack.get("tick", {"freq": 1046.5, "len": 0.07, "wave": "sine", "gain": 0.3, "sweep": 0})),
		"go": _tone_from(pack.get("go", {"freq": 1318.5, "len": 0.28, "wave": "sine", "gain": 0.35, "sweep": 300})),
	}


func _tone_from(d: Dictionary) -> AudioStreamWAV:
	var wave := str(d.get("wave", "sine"))
	if wave in ["sine", "square"] and not d.has("arp"):
		return _make_tone(float(d.freq), float(d.len), wave == "square", float(d.gain), float(d.sweep))
	return _make_wave(float(d.freq), float(d.len), wave, float(d.gain), float(d.sweep), d.get("arp", []))


## Classic short "bloop": sine with a fast downward chirp plus a tiny click transient.
func _make_pop(freq: float) -> AudioStreamWAV:
	var length := 0.16
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / MIX_RATE
		var f := freq * (1.0 + 0.9 * exp(-t * 90.0))
		phase += TAU * f / MIX_RATE
		var env := minf(t / 0.002, 1.0) * exp(-t * 28.0)
		var s := sin(phase) * env * 0.55
		s += sin(phase * 2.0) * env * 0.12 * exp(-t * 60.0)
		if t < 0.004:
			s += (randf() * 2.0 - 1.0) * 0.3 * (1.0 - t / 0.004)
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	return _wav(data)


## Bubble wrap: a sharp filtered-noise crack over a short pitched thump.
func _make_snap(freq: float) -> AudioStreamWAV:
	var length := 0.1
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / MIX_RATE
		phase += TAU * freq * (1.0 + 0.5 * exp(-t * 120.0)) / MIX_RATE
		var noise := randf() * 2.0 - 1.0
		lp += (noise - lp) * 0.55
		var crack := (noise - lp) * exp(-t * 160.0) * 0.6
		var thump := sin(phase) * minf(t / 0.001, 1.0) * exp(-t * 45.0) * 0.45
		data.encode_s16(i * 2, int(clampf(crack + thump, -1.0, 1.0) * 32767.0))
	return _wav(data)


## 8-bit: a pulse wave that hops up an octave after a few ms (chiptune blip).
func _make_chip(freq: float) -> AudioStreamWAV:
	var length := 0.12
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / MIX_RATE
		var f := freq * (2.0 if t > 0.03 else 1.0)
		phase = fmod(phase + f / MIX_RATE, 1.0)
		var w := 1.0 if phase < 0.25 else -1.0
		var env := (1.0 - t / length) * 0.22
		var s := w * env
		s = roundf(s * 16.0) / 16.0  # crude bit-crush
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	return _wav(data)


## Cosmic: soft bell (inharmonic partials, slower decay).
func _make_bell(freq: float) -> AudioStreamWAV:
	var length := 0.45
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / MIX_RATE
		var env := minf(t / 0.004, 1.0) * exp(-t * 7.0)
		var s := sin(TAU * freq * t) * 0.32 + sin(TAU * freq * 2.76 * t) * 0.12 * exp(-t * 14.0) + sin(TAU * freq * 5.4 * t) * 0.05 * exp(-t * 30.0)
		data.encode_s16(i * 2, int(clampf(s * env, -1.0, 1.0) * 32767.0))
	return _wav(data)


## Deep Sea: a water drop — sine that glides *up* quickly, with a soft tail.
func _make_drop(freq: float) -> AudioStreamWAV:
	var length := 0.22
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / MIX_RATE
		var f := freq * (0.55 + 0.6 * (1.0 - exp(-t * 55.0)))
		phase += TAU * f / MIX_RATE
		var env := minf(t / 0.003, 1.0) * exp(-t * 16.0)
		data.encode_s16(i * 2, int(clampf(sin(phase) * env * 0.5, -1.0, 1.0) * 32767.0))
	return _wav(data)


func _make_tone(freq: float, length: float, square: bool, gain: float, sweep: float) -> AudioStreamWAV:
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / MIX_RATE
		var f := maxf(freq + sweep * t, 20.0)
		phase += TAU * f / MIX_RATE
		var w := sin(phase)
		if square:
			w = signf(w) * 0.6 + w * 0.4
		var env := minf(t / 0.003, 1.0) * pow(1.0 - t / length, 2.0)
		data.encode_s16(i * 2, int(clampf(w * env * gain, -1.0, 1.0) * 32767.0))
	return _wav(data)


## Generic tone for the other packs: sine / pulse / noise, optional arpeggio.
func _make_wave(freq: float, length: float, wave: String, gain: float, sweep: float, arp: Array) -> AudioStreamWAV:
	var n := int(MIX_RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / MIX_RATE
		var mult := 1.0
		if not arp.is_empty():
			mult = float(arp[mini(int(t / length * arp.size()), arp.size() - 1)])
		var f := maxf((freq + sweep * t) * mult, 20.0)
		phase = fmod(phase + f / MIX_RATE, 1.0)
		var w := 0.0
		match wave:
			"pulse":
				w = 1.0 if phase < 0.25 else -1.0
			"noise":
				var nz := randf() * 2.0 - 1.0
				lp += (nz - lp) * clampf(f / 4000.0, 0.02, 0.9)
				w = lp * 2.0
			_:
				w = sin(phase * TAU)
		var env := minf(t / 0.003, 1.0) * pow(1.0 - t / length, 2.0)
		data.encode_s16(i * 2, int(clampf(w * env * gain, -1.0, 1.0) * 32767.0))
	return _wav(data)


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = data
	return w

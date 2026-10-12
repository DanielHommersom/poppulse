class_name StreakBurst
extends Control
## Results-card widget: flame + streak count. On a milestone (3 / 7 / 30
## days) the flame bursts in with rays and a gold caption.

var streak := 0
var milestone := false
var _t := 0.0
var _flame: NeonIcon
var _label: Label


func _init(p_streak: int, p_milestone: bool) -> void:
	streak = p_streak
	milestone = p_milestone
	custom_minimum_size = Vector2(0, 176 if milestone else 70)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_flame = NeonIcon.new("flame", Color(1.0, 0.55, 0.15))
	add_child(_flame)
	var txt := ("%d DAY STREAK!" % streak) if milestone else ("%d day streak" % streak)
	_label = UiStyle.label(txt, 40 if milestone else 30, UiStyle.GOLD if milestone else Color(1.0, 0.7, 0.3), milestone)
	add_child(_label)
	resized.connect(_place)
	_place()
	if milestone:
		_flame.scale = Vector2.ZERO
		var t := create_tween()
		t.tween_interval(0.35)
		t.tween_property(_flame, "scale", Vector2(1.25, 1.25), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(_flame, "scale", Vector2.ONE, 0.2)
		t.tween_callback(func() -> void:
			Sfx.play_go()
			Platform.haptic(Platform.Haptic.HEAVY))


func _place() -> void:
	var fs := 96.0 if milestone else 50.0
	_flame.size = Vector2(fs, fs)
	_flame.pivot_offset = _flame.size * 0.5
	if milestone:
		_flame.position = Vector2((size.x - fs) * 0.5, 14)
		_label.position = Vector2(0, fs + 30)
		_label.size = Vector2(size.x, 48)
	else:
		_label.size = Vector2(size.x, 60)
		_label.position = Vector2(fs * 0.5, 4)
		_flame.position = Vector2(size.x * 0.5 - 150, 6)


func _process(delta: float) -> void:
	if not milestone:
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	if not milestone or _t < 0.35:
		return
	var c := Vector2(size.x * 0.5, 62)
	var k := clampf((_t - 0.35) / 0.6, 0.0, 1.0)
	for i in 14:
		var a := TAU * i / 14.0 + _t * 0.6
		var r0 := 52.0 + k * 4.0
		var r1 := r0 + 12.0 + 6.0 * sin(_t * 6.0 + i)
		draw_line(c + Vector2.from_angle(a) * r0, c + Vector2.from_angle(a) * r1, Color(1.0, 0.75, 0.3, 0.55 * k), 4.0, true)

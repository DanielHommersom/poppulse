class_name HintMarker
extends Node2D
## First-run coach mark: a pulsing ring + caption around one bubble.
## Lives in the world layer so it follows the board (and screenshake).

var target: Bubble
var text := "TAP THE GLOWING BUBBLE"
var _t := 0.0
var _label: Label


func _ready() -> void:
	z_index = 5
	_label = UiStyle.label(text, 30, Color.WHITE, true)
	_label.size = Vector2(520, 44)
	add_child(_label)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


func point_at(b: Bubble, caption: String) -> void:
	target = b
	text = caption
	if _label:
		_label.text = caption


func _process(delta: float) -> void:
	_t += delta
	if target == null or not is_instance_valid(target):
		return
	position = target.position
	var above := target.position.y > target.radius * 4.0
	# Keep the caption on screen for bubbles at the board edges.
	var vw := get_viewport_rect().size.x
	var gx := clampf(global_position.x - _label.size.x * 0.5, 12.0, vw - _label.size.x - 12.0)
	_label.position = Vector2(gx - global_position.x, (-target.radius * 2.1 - _label.size.y) if above else target.radius * 2.0)
	queue_redraw()


func _draw() -> void:
	if target == null or not is_instance_valid(target):
		return
	var k := fmod(_t * 1.6, 1.0)
	var r := target.radius
	draw_arc(Vector2.ZERO, r * (1.25 + k * 0.8), 0.0, TAU, 48, Color(1, 1, 1, 0.8 * (1.0 - k)), 5.0, true)
	draw_arc(Vector2.ZERO, r * 1.3, 0.0, TAU, 48, Color(1, 1, 1, 0.35 + 0.25 * sin(_t * 8.0)), 3.0, true)


func dismiss() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.2)
	t.tween_callback(queue_free)

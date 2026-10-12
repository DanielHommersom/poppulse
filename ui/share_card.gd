class_name ShareCard
extends RefCounted
## Renders a 1080×1350 (4:5, the Instagram/Messages-friendly portrait) result
## card in an offscreen SubViewport: game name, mode, the result, a record
## badge and glowing bubbles in the neon style.

const SIZE := Vector2i(1080, 1350)
const BG_SHADER := preload("res://shaders/background.gdshader")


## spec: {mode_name, value_text, caption, is_record, color, footer}
static func render(host: Node, spec: Dictionary) -> Image:
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	host.add_child(vp)
	var accent: Color = spec.get("color", UiStyle.ACCENT)

	var bg := ColorRect.new()
	bg.size = Vector2(SIZE)
	var mat := ShaderMaterial.new()
	mat.shader = BG_SHADER
	mat.set_shader_parameter("accent", accent)
	mat.set_shader_parameter("energy", 0.8)
	bg.material = mat
	vp.add_child(bg)

	# A row of lit bubbles as the "toy" motif.
	var deco := Node2D.new()
	vp.add_child(deco)
	for i in 5:
		var b := Bubble.new()
		b.setup(i, Vector2i(i, 0), Color.from_hsv(float(i) / 5.0 * 0.85, 0.78, 1.0))
		deco.add_child(b)
		b.position = Vector2(180 + i * 180, 1080)
		b.set_radius(62)
		b.vis_lit = 0.25 + 0.75 * float(i % 2 == 0)
	var root := Control.new()
	root.size = Vector2(SIZE)
	vp.add_child(root)
	_add(root, AppInfo.TITLE, 130, Color.WHITE, 110, true)
	_add(root, str(spec.get("mode_name", "")), 64, accent, 300, true)
	_add(root, str(spec.get("value_text", "")), 230, Color.WHITE, 470, true)
	_add(root, str(spec.get("caption", "")), 50, Color(1, 1, 1, 0.75), 730, false)
	if bool(spec.get("is_record", false)):
		_add(root, "★ NEW PERSONAL BEST ★", 62, UiStyle.GOLD, 830, true)
	_add(root, str(spec.get("footer", "Can you beat it?")), 54, UiStyle.CYAN, 1200, true)

	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


static func _add(root: Control, text: String, size: int, color: Color, y: float, glow: bool) -> void:
	if text == "":
		return
	var l := UiStyle.label(text, size, color, glow)
	l.position = Vector2(40, y)
	l.size = Vector2(SIZE.x - 80, size * 1.4)
	root.add_child(l)

extends Node
## Dev-only: renders the App Store assets into res://store/.
##   Godot --path . res://tools/store_assets.tscn -- --test-save --fresh
## • icon in every iOS size (store/icon/)
## • launch images matching the first frame (store/launch/)
## • screenshots for 6.9" iPhone (1320×2868) and 13" iPad (2064×2752) (store/screenshots/)
## The game renders inside an offscreen SubViewport at the exact store size
## while keeping its 720-wide design units (size_2d_override).

const BG_SHADER := preload("res://shaders/background.gdshader")
const ICON_SIZES := [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024]
const DEVICES := {
	"iphone69": Vector2i(1320, 2868),
	"ipad13": Vector2i(2064, 2752),
}

var main: Node


func _ready() -> void:
	for d in ["store/icon", "store/launch", "store/screenshots"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + d))
	await _icon()
	await _launch()
	for dev in DEVICES:
		await _screenshots(dev, DEVICES[dev])
	print("store assets done")
	get_tree().quit()


func _vp(size: Vector2i, design_w := 0.0) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if design_w > 0.0:
		vp.size_2d_override = Vector2i(int(design_w), int(design_w * size.y / size.x))
		vp.size_2d_override_stretch = true
	add_child(vp)
	return vp


func _grab(vp: SubViewport, path: String, no_alpha := true) -> Image:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	if no_alpha:
		img.convert(Image.FORMAT_RGB8)  # App Store icons/screens must be opaque
	img.save_png(path)
	print("saved ", path)
	return img


# --- Icon ------------------------------------------------------------------------

func _icon() -> void:
	var vp := _vp(Vector2i(1024, 1024))
	var bg := ColorRect.new()
	bg.size = Vector2(1024, 1024)
	var mat := ShaderMaterial.new()
	mat.shader = BG_SHADER
	mat.set_shader_parameter("accent", Color(1.0, 0.25, 0.7))
	mat.set_shader_parameter("energy", 1.0)
	mat.set_shader_parameter("grid", 0.0)
	bg.material = mat
	vp.add_child(bg)
	# A 3×3 mini board: one hot target, a pushed-in one, the rest softly lit.
	var root := Node2D.new()
	vp.add_child(root)
	var plate := Panel.new()
	plate.position = Vector2(132, 132)
	plate.size = Vector2(760, 760)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.055, 0.05, 0.1)
	sb.border_color = Color(0.7, 0.45, 1.0, 0.7)
	sb.set_border_width_all(10)
	sb.set_corner_radius_all(150)
	sb.shadow_color = Color(0.6, 0.25, 1.0, 0.45)
	sb.shadow_size = 60
	sb.anti_aliasing = true
	plate.add_theme_stylebox_override("panel", sb)
	root.add_child(plate)
	for i in 9:
		var b := Bubble.new()
		var c := Color.from_hsv(float(i) / 9.0 * 0.9, 0.8, 1.0)
		b.setup(i, Vector2i(i % 3, i / 3), c)
		root.add_child(b)
		b.position = Vector2(292 + (i % 3) * 220, 292 + (i / 3) * 220)
		b.set_radius(82)
		b.vis_lit = 1.0 if i == 4 else 0.32
		if i == 6:
			b.vis_press = 1.0
	await get_tree().process_frame
	var img := await _grab(vp, "res://store/icon/icon_1024.png")
	for s in ICON_SIZES:
		var small := img.duplicate() as Image
		small.resize(s, s, Image.INTERPOLATE_LANCZOS)
		small.save_png("res://store/icon/icon_%d.png" % s)
	vp.queue_free()


# --- Launch screen ---------------------------------------------------------------

## The first frame of the game is the background shader with no UI yet; the
## launch image is exactly that, so the hand-over is invisible.
func _launch() -> void:
	for spec in [["launch@3x", Vector2i(1290, 2796)], ["launch@2x", Vector2i(828, 1792)]]:
		var vp := _vp(spec[1])
		var bg := ColorRect.new()
		bg.size = Vector2(spec[1])
		var mat := ShaderMaterial.new()
		mat.shader = BG_SHADER
		bg.material = mat
		vp.add_child(bg)
		await _grab(vp, "res://store/launch/%s.png" % spec[0])
		vp.queue_free()


# --- Screenshots -------------------------------------------------------------------

func _screenshots(dev: String, size: Vector2i) -> void:
	var vp := _vp(size, 720.0)
	main = load("res://main.tscn").instantiate()
	main.auto_pause = false
	vp.add_child(main)
	main.toast.visible = false  # no achievement pop-ups in store shots
	SaveData.set_flag("hint_fidget_done")
	await _wait(1.0)
	var n := 1
	# 1. Menu with the fidget board
	for i in [3, 8, 13]:
		main._on_bubble_pressed(main.board.bubbles[i])
	await _wait(0.15)
	await _grab(vp, "res://store/screenshots/%s_%d_menu.png" % [dev, n])
	n += 1
	# 2. Score Mode in a big combo
	main.hud.menu._on_card("score")
	main._on_play()
	await _wait(1.6)
	for i in 40:
		for b in main.mode._active.duplicate():
			main.board.last_press_usec = Time.get_ticks_usec()
			main._on_bubble_pressed(b)
			break
		await _wait(0.09)
	await _grab(vp, "res://store/screenshots/%s_%d_combo.png" % [dev, n])
	n += 1
	main.mode.elapsed = main.mode.get_duration() - 0.02
	await _wait(1.4)
	await _grab(vp, "res://store/screenshots/%s_%d_results.png" % [dev, n])
	n += 1
	main._enter_idle()
	# 3. Stage select
	for i in range(1, 9):
		SaveData.set_stars(i, 2 + i % 2)
	main.hud.menu._on_card("stage")
	await _wait(0.3)
	main._on_menu_play()
	await _wait(0.6)
	await _grab(vp, "res://store/screenshots/%s_%d_stages.png" % [dev, n])
	n += 1
	main.stage_select.close()
	await _wait(0.3)
	# 4. Themes
	main._open_themes()
	for it in main.theme_picker._items():
		if it.id == "sunset":
			main.theme_picker._select(it)
	main._on_bubble_pressed(main.board.bubbles[9])
	await _wait(0.8)
	await _grab(vp, "res://store/screenshots/%s_%d_themes.png" % [dev, n])
	main.theme_picker.close()
	vp.queue_free()
	await _wait(0.3)


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

extends Node
## Dev-only: plays a scripted round and saves screenshots to res://_capture/.
## Run this scene directly; not part of the game.

var main: Node


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://_capture"))
	main = load("res://main.tscn").instantiate()
	add_child(main)
	await _wait(1.2)
	_shot("1_idle")
	main.board.bubbles[7].press_down()
	main._on_bubble_pressed(main.board.bubbles[7])
	await _wait(0.06)
	_shot("2_fidget_pop")
	main._on_play()
	await _wait(2.2)
	# Pop every lit target quickly for ~4 seconds to build a combo.
	for i in 40:
		for b in main.mode._active.duplicate():
			main._on_bubble_pressed(b)
			break
		await _wait(0.1)
		if i == 12:
			_shot("3_playing_combo")
	_shot("4_playing_later")
	main._on_bubble_pressed(_find_idle())
	await _wait(0.08)
	_shot("5_wrong_tap")
	main.mode.elapsed = main.mode.get_duration() - 0.05
	await _wait(1.6)
	_shot("6_results")
	get_window().size = Vector2i(600, 800)  # iPad-like 3:4
	await _wait(0.5)
	main._enter_idle()
	await _wait(0.6)
	_shot("7_ipad_idle")
	get_tree().quit()


func _find_idle():
	for b in main.board.bubbles:
		if b.state == 0 and not (b in main.mode._active):
			return b
	return main.board.bubbles[0]


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shot(label: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://_capture/%s.png" % label)
	print("captured ", label)

class_name PauseOverlay
extends Modal
## Shown on the pause button or when the app loses focus mid-run.

signal resume_pressed
signal quit_pressed

var _quitting := false


func _init() -> void:
	super("PAUSED", 520.0)
	dismiss_on_backdrop = false


func _build() -> void:
	var resume := add_button("RESUME", UiStyle.CYAN, _resume, true)
	resume.custom_minimum_size = Vector2(360, 0)
	add_button("QUIT RUN", UiStyle.DANGER, _quit)
	closed.connect(_on_closed)


func _on_open() -> void:
	_quitting = false


func _resume() -> void:
	close()


func _quit() -> void:
	_quitting = true
	close()


## The X button also just resumes.
func _on_closed() -> void:
	if _quitting:
		quit_pressed.emit()
	else:
		resume_pressed.emit()

class_name PauseOverlay
extends ColorRect
## Dims the screen and pauses the game when the pause action is pressed.

signal paused_changed(is_paused: bool)


func _ready() -> void:
	visible = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"pause"):
		toggle()


func toggle() -> void:
	get_tree().paused = not get_tree().paused
	visible = get_tree().paused
	paused_changed.emit(get_tree().paused)

class_name TouchWidget
extends Control
## Base for on-screen controls. Tracks one finger (multi-touch safe) and calls
## _on_press / _on_drag / _on_release. On devices without a touchscreen (desktop and
## browser testing) the left mouse button acts as a finger.

const NO_FINGER := -2
const MOUSE_FINGER := -1

## Extra pixels around the visible shape that still count as a hit.
@export var hit_padding := 6.0

var _finger := NO_FINGER
var _use_mouse := not DisplayServer.is_touchscreen_available()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		_pointer(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_pointer_moved(event.index, event.position)
	elif _use_mouse and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_pointer(MOUSE_FINGER, event.position, event.pressed)
	elif _use_mouse and event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
			_pointer_moved(MOUSE_FINGER, event.position)


func _exit_tree() -> void:
	_release()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_release()


func _on_press(_position: Vector2) -> void:
	pass


func _on_drag(_position: Vector2) -> void:
	pass


func _on_release() -> void:
	pass


func _pointer(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _finger == NO_FINGER and get_global_rect().grow(hit_padding).has_point(pos):
			_finger = index
			_on_press(pos)
			get_viewport().set_input_as_handled()
	elif index == _finger:
		_release()
		get_viewport().set_input_as_handled()


func _pointer_moved(index: int, pos: Vector2) -> void:
	if index == _finger:
		_on_drag(pos)


func _release() -> void:
	if _finger != NO_FINGER:
		_finger = NO_FINGER
		_on_release()

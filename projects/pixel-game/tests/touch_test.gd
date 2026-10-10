extends "res://tests/test_base.gd"
## The on-screen joystick and buttons drive the input actions, including two fingers at once.

const CONTROLS := preload("res://scenes/touch_controls.tscn")


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = pos
	event.pressed = pressed
	root.push_input(event, true)


func _drag(index: int, pos: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = pos
	root.push_input(event, true)


func _centre(node: Control) -> Vector2:
	return node.global_position + node.size / 2.0


func _run() -> void:
	var controls: TouchControls = CONTROLS.instantiate()
	root.add_child(controls)
	await _frames(2)
	_check(not controls.visible, "hidden on a desktop without a touchscreen")
	controls.free()

	controls = CONTROLS.instantiate()
	controls.force_visible = true
	root.add_child(controls)
	await _frames(2)
	_check(controls.visible, "force_visible shows the controls")

	var stick: TouchJoystick = controls.get_node("Joystick")
	var attack: TouchButton = controls.get_node("AttackButton")
	var centre := _centre(stick)

	_touch(0, centre + Vector2(stick.radius, 0), true)
	_check(Input.get_action_strength(&"move_right") > 0.9, "full right push")
	_check(Input.get_action_strength(&"move_left") == 0.0, "no left")
	_drag(0, centre + Vector2(0, -stick.radius))
	_check(Input.get_action_strength(&"move_up") > 0.9, "drag up")
	_check(Input.get_action_strength(&"move_right") == 0.0, "right released after drag")
	_drag(0, centre + Vector2(2, 0))
	_check(not Input.is_action_pressed(&"move_right"), "inside the deadzone does nothing")

	_touch(1, _centre(attack), true)
	_check(Input.is_action_pressed(&"attack"), "second finger presses attack")
	_drag(0, centre + Vector2(-stick.radius, 0))
	_check(Input.is_action_pressed(&"move_left"), "first finger still steers")

	_touch(0, centre, false)
	_check(not Input.is_action_pressed(&"move_left"), "joystick released")
	_check(Input.is_action_pressed(&"attack"), "attack still held")
	_touch(1, _centre(attack), false)
	_check(not Input.is_action_pressed(&"attack"), "attack released")

	_touch(2, Vector2(-500, -500), true)
	_check(not Input.is_action_pressed(&"attack"), "touches outside every control are ignored")
	_finish()

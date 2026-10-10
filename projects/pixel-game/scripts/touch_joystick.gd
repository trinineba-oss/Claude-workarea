class_name TouchJoystick
extends TouchWidget
## Fixed on-screen joystick. Drives the move_* input actions with analogue strength.

const DEADZONE := 0.25
const DIRECTIONS := {
	&"move_left": Vector2.LEFT,
	&"move_right": Vector2.RIGHT,
	&"move_up": Vector2.UP,
	&"move_down": Vector2.DOWN,
}

## Thumb travel from the centre, in pixels, for full speed.
@export var radius := 88.0

var _stick := Vector2.ZERO


func _draw() -> void:
	var centre := size / 2.0
	draw_circle(centre, radius + 24.0, Color(1, 1, 1, 0.1))
	draw_arc(centre, radius + 24.0, 0.0, TAU, 64, Color(1, 1, 1, 0.4), 3.0, true)
	var alpha := 0.75 if _finger != NO_FINGER else 0.45
	draw_circle(centre + _stick * radius, 38.0, Color(1, 1, 1, alpha))
	draw_arc(centre + _stick * radius, 38.0, 0.0, TAU, 48, Color(1, 1, 1, 0.8), 2.0, true)


func _on_press(pos: Vector2) -> void:
	_update(pos)


func _on_drag(pos: Vector2) -> void:
	_update(pos)


func _on_release() -> void:
	_stick = Vector2.ZERO
	_apply()
	queue_redraw()


func _update(pos: Vector2) -> void:
	_stick = ((pos - (global_position + size / 2.0)) / radius).limit_length(1.0)
	_apply()
	queue_redraw()


func _apply() -> void:
	var vector := _stick if _stick.length() > DEADZONE else Vector2.ZERO
	for action: StringName in DIRECTIONS:
		var strength := maxf(vector.dot(DIRECTIONS[action]), 0.0)
		if strength > 0.0:
			Input.action_press(action, strength)
		else:
			Input.action_release(action)

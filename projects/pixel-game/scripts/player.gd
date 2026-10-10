class_name Player
extends CharacterBody2D
## Top-down player. Moves with the arrow keys / d-pad, or toward wherever
## the screen is touched (or the mouse is held) so it works on phones.

const SPEED := 90.0
const ARRIVE_DISTANCE := 2.0

var _target: Variant = null


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_target = _to_world(event.position)
	elif event is InputEventScreenDrag:
		_target = _to_world(event.position)
	elif event is InputEventMouseButton and event.pressed:
		_target = _to_world(event.position)


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		_target = null
	elif _target != null:
		var offset: Vector2 = _target - global_position
		if offset.length() > ARRIVE_DISTANCE:
			direction = offset.normalized()
		else:
			_target = null
	velocity = direction * SPEED
	move_and_slide()


func _to_world(screen_position: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_position

class_name Player
extends CharacterBody2D
## Top-down hero. Moves with the move_* actions (keyboard, joystick or gamepad).

const SPEED := 64.0

## Last cardinal direction the hero moved in (used by attacks later).
var facing := Vector2.DOWN
## While true the hero ignores input (room transitions, cutscenes).
var frozen := false

@onready var _sprite: Sprite2D = $Sprite2D


func _physics_process(_delta: float) -> void:
	if frozen:
		velocity = Vector2.ZERO
		return
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if direction != Vector2.ZERO:
		facing = _cardinal(direction)
		if facing.x != 0.0:
			_sprite.flip_h = facing.x < 0.0
	velocity = direction * SPEED
	move_and_slide()


static func _cardinal(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2(signf(direction.x), 0.0)
	return Vector2(0.0, signf(direction.y))

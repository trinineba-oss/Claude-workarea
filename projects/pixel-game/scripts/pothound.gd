class_name Pothound
extends Enemy
## A stray dog: wanders, then chases the hero when they come close.

const WALK_SPEED := 88.0
const CHASE_SPEED := 168.0
const CHASE_RANGE := 288.0

var _wander := Vector2.ZERO
var _wander_time := 0.0


func _think(delta: float) -> void:
	var player := _player()
	if player != null and global_position.distance_to(player.global_position) < CHASE_RANGE:
		velocity = global_position.direction_to(player.global_position) * CHASE_SPEED
	else:
		_wander_time -= delta
		if _wander_time <= 0.0:
			_wander = (
				[Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN].pick_random()
			)
			_wander_time = randf_range(0.8, 2.0)
		velocity = _wander * WALK_SPEED

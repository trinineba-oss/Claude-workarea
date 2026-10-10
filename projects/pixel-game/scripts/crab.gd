class_name Crab
extends Enemy
## A cave crab: scuttles sideways toward Chad in short bursts, stopping now and then.

const SPEED := 120.0
const NOTICE_RANGE := 420.0

var _burst := 0.0
var _resting := false


func _think(delta: float) -> void:
	_burst -= delta
	if _burst <= 0.0:
		_burst = randf_range(0.5, 1.2)
		_resting = randf() < 0.3
	var player := _player()
	if _resting or player == null:
		velocity = Vector2.ZERO
		return
	var to := player.global_position - global_position
	if to.length() > NOTICE_RANGE:
		velocity = Vector2.ZERO
		return
	# Crabs prefer to go sideways.
	var step := Vector2(
		signf(to.x) if absf(to.x) > 8.0 else 0.0, signf(to.y) * 0.5 if absf(to.y) > 8.0 else 0.0
	)
	velocity = step.normalized() * SPEED


func _animate(_delta: float) -> void:
	var moving := velocity.length() > 1.0
	_sprite.position = Vector2(sin(_age * 40.0) * 2.0 if moving else 0.0, 0.0)
	_sprite.rotation = sin(_age * 20.0) * 0.06 if moving else 0.0

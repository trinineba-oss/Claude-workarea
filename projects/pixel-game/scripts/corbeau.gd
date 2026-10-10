class_name Corbeau
extends Enemy
## A vulture: hovers, warns with a shudder, then swoops at the hero and flies home.
## Its origin is its shadow on the ground; the sprite flies above it.

enum State { HOVER, TELEGRAPH, SWOOP, RECOVER }

const SWOOP_RANGE := 384.0
const SWOOP_SPEED := 440.0
const RECOVER_SPEED := 160.0
const TELEGRAPH_TIME := 0.4
const SWOOP_TIME := 0.55
const RECOVER_TIME := 1.2
const COOLDOWN := 1.0
const FLY_HEIGHT := 40.0

var state := State.HOVER

var _home := Vector2.ZERO
var _timer := COOLDOWN
var _swoop_dir := Vector2.ZERO


func _ready() -> void:
	super()
	_home = position


func _think(delta: float) -> void:
	_timer -= delta
	match state:
		State.HOVER:
			velocity = Vector2(cos(_age * 2.0), sin(_age * 2.6)) * 40.0
			var player := _player()
			if (
				_timer <= 0.0
				and player != null
				and global_position.distance_to(player.global_position) < SWOOP_RANGE
			):
				_enter(State.TELEGRAPH, TELEGRAPH_TIME)
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				var player := _player()
				_swoop_dir = (
					global_position.direction_to(player.global_position)
					if player != null
					else global_position.direction_to(_home)
				)
				_enter(State.SWOOP, SWOOP_TIME)
		State.SWOOP:
			velocity = _swoop_dir * SWOOP_SPEED
			if _timer <= 0.0:
				_enter(State.RECOVER, RECOVER_TIME)
		State.RECOVER:
			velocity = global_position.direction_to(_home) * RECOVER_SPEED
			if _timer <= 0.0 or global_position.distance_to(_home) < 16.0:
				_enter(State.HOVER, COOLDOWN)


func _animate(_delta: float) -> void:
	var low := 0.4 if state == State.SWOOP else 1.0
	_sprite.position = Vector2(
		sin(_age * 60.0) * 4.0 if state == State.TELEGRAPH else 0.0,
		-FLY_HEIGHT * low - sin(_age * 3.0) * 6.0
	)
	_sprite.scale = Vector2(1.0 + sin(_age * 14.0) * 0.1, 1.0)
	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0.0


func _enter(new_state: State, seconds: float) -> void:
	state = new_state
	_timer = seconds

class_name Corbeau
extends Enemy
## A vulture: hovers, warns with a shudder, then swoops at the hero and flies home.

enum State { HOVER, TELEGRAPH, SWOOP, RECOVER }

const SWOOP_RANGE := 96.0
const SWOOP_SPEED := 110.0
const RECOVER_SPEED := 40.0
const TELEGRAPH_TIME := 0.4
const SWOOP_TIME := 0.55
const RECOVER_TIME := 1.2
const COOLDOWN := 1.0

var state := State.HOVER

var _home := Vector2.ZERO
var _timer := COOLDOWN
var _age := 0.0
var _swoop_dir := Vector2.ZERO


func _ready() -> void:
	super()
	_home = position


func _think(delta: float) -> void:
	_age += delta
	_timer -= delta
	match state:
		State.HOVER:
			velocity = Vector2(cos(_age * 2.0), sin(_age * 2.6)) * 10.0
			var player := _player()
			if (
				_timer <= 0.0
				and player != null
				and global_position.distance_to(player.global_position) < SWOOP_RANGE
			):
				_enter(State.TELEGRAPH, TELEGRAPH_TIME)
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			_sprite.offset.x = sin(_age * 60.0)
			if _timer <= 0.0:
				_sprite.offset.x = 0.0
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
			if _timer <= 0.0 or global_position.distance_to(_home) < 4.0:
				_enter(State.HOVER, COOLDOWN)
	if velocity.x != 0.0:
		_sprite.flip_h = velocity.x < 0.0


func _enter(new_state: State, seconds: float) -> void:
	state = new_state
	_timer = seconds

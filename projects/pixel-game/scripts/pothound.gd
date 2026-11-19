class_name Pothound
extends Enemy
## A stray dog: wanders, chases the hero when they come close, and attacks with a lunge it
## telegraphs first (it stops, crouches and flashes), so a quick dodge beats it.
## An `alpha` is the pack leader: bigger, tougher, faster to pounce (the wharf demo's boss).

enum Mode { ROAM, WINDUP, LUNGE, RECOVER }

const WALK_SPEED := 88.0
const CHASE_SPEED := 168.0
const CHASE_RANGE := 288.0
## Close enough to pounce.
const LUNGE_RANGE := 132.0
const WINDUP_TIME := 0.42
const LUNGE_TIME := 0.26
const LUNGE_SPEED := 560.0
const RECOVER_TIME := 0.55

@export var alpha := false

var mode := Mode.ROAM

var _wander := Vector2.ZERO
var _wander_time := 0.0
var _mode_time := 0.0
var _lunge_dir := Vector2.RIGHT


func _ready() -> void:
	if alpha:
		max_health = 36
		contact_damage = 2
		xp = 10
		coin_chance = 1.0
		knockback_speed = 300.0
		_sprite.scale = Vector2.ONE * 1.7
	super()


func _think(delta: float) -> void:
	var player := _player()
	_mode_time -= delta
	match mode:
		Mode.WINDUP:
			velocity = Vector2.ZERO
			if player != null and _mode_time > 0.12:
				_lunge_dir = global_position.direction_to(player.global_position)
			if _mode_time <= 0.0:
				_enter(Mode.LUNGE, LUNGE_TIME)
		Mode.LUNGE:
			velocity = _lunge_dir * LUNGE_SPEED * (1.25 if alpha else 1.0)
			if _mode_time <= 0.0:
				_enter(Mode.RECOVER, RECOVER_TIME * (0.7 if alpha else 1.0))
		Mode.RECOVER:
			velocity = Vector2.ZERO
			if _mode_time <= 0.0:
				_enter(Mode.ROAM, 0.0)
		Mode.ROAM:
			var distance := INF
			if player != null:
				distance = global_position.distance_to(player.global_position)
			if distance < LUNGE_RANGE:
				_enter(Mode.WINDUP, WINDUP_TIME * (0.8 if alpha else 1.0))
			elif distance < CHASE_RANGE * (2.0 if alpha else 1.0):
				velocity = global_position.direction_to(player.global_position) * CHASE_SPEED
			else:
				_wander_time -= delta
				if _wander_time <= 0.0:
					_wander = (
						[Vector2.ZERO, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
						. pick_random()
					)
					_wander_time = randf_range(0.8, 2.0)
				velocity = _wander * WALK_SPEED


func take_hit(damage: int, from_position: Vector2) -> bool:
	var landed := super(damage, from_position)
	# A hit knocks it out of its wind-up (but not the pack leader).
	if landed and health > 0 and mode == Mode.WINDUP and not alpha:
		_enter(Mode.RECOVER, 0.3)
	return landed


func _animate(delta: float) -> void:
	super(delta)
	var base := 1.7 if alpha else 1.0
	match mode:
		Mode.WINDUP:
			# The tell: a low crouch, a shiver and a red flash.
			_sprite.scale = Vector2(base * 1.15, base * 0.8)
			_sprite.position.x = sin(_age * 70.0) * 3.0
			_sprite.modulate = Color(1.0, 0.55, 0.5) if int(_age * 16.0) % 2 == 0 else Color.WHITE
		Mode.LUNGE:
			_sprite.scale = Vector2(base * 1.25, base * 0.85)
			_sprite.position.x = 0.0
			_sprite.modulate = Color.WHITE
		_:
			_sprite.scale = _sprite.scale.lerp(Vector2.ONE * base, minf(delta * 12.0, 1.0))
			_sprite.position.x = 0.0
			_sprite.modulate = Color.WHITE


func _enter(new_mode: Mode, seconds: float) -> void:
	mode = new_mode
	_mode_time = seconds

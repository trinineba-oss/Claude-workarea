class_name Player
extends CharacterBody2D
## Top-down hero: moves with the move_* actions, swings the cutlass with attack, and has
## health in half "doubles" (two halves per heart icon). The node's origin is at the hero's
## feet, which is what depth sorting uses.

signal health_changed(health: int, max_health: int)
signal money_changed(money: int)
signal died
## The hero pressed interact (or attack) while facing something to talk to or read.
signal interact_requested(target: Interactable)

enum State { NORMAL, ATTACK, HURT }

const SPEED := 256.0
const ATTACK_TIME := 0.28
const HURT_TIME := 0.18
const KNOCKBACK_SPEED := 480.0
const INVINCIBLE_SECONDS := 1.0
const REVIVE_INVINCIBLE_SECONDS := 1.5
const STEP_RATE := 11.0
const INTERACT_RANGE := 76.0

var max_health := 6
var health := 6
var money := 0
## Last cardinal direction the hero moved in (the cutlass swings this way).
var facing := Vector2.DOWN
## While true the hero ignores input and cannot be hurt (room transitions, cutscenes).
var frozen := false
var state := State.NORMAL
## Story flags (shared with Game), used to decide who has something to say.
var story_flags: Dictionary = {}
## The thing the hero would talk to right now, if any.
var target: Interactable

var _state_time := 0.0
var _invincible := 0.0
var _knockback := Vector2.ZERO
var _step := 0.0
var _squash := Vector2.ONE

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _cutlass: Cutlass = $Cutlass


func _ready() -> void:
	add_to_group("player")


func _process(delta: float) -> void:
	var walking := state == State.NORMAL and not frozen and velocity.length() > 1.0
	if walking:
		_step += delta * STEP_RATE
	else:
		_step = 0.0
	_squash = _squash.lerp(Vector2.ONE, minf(delta * 12.0, 1.0))
	var breathe := 0.0 if walking else sin(Time.get_ticks_msec() / 1000.0 * 3.0) * 0.02
	_sprite.position.y = -absf(sin(_step)) * 6.0
	_sprite.rotation = 1.4 if health <= 0 else sin(_step) * 0.08
	_sprite.scale = Vector2(1.0 - breathe, 1.0 + breathe) * _squash
	var flash := 0.4 if _invincible > 0.0 and int(_invincible * 14.0) % 2 == 0 else 1.0
	_sprite.modulate.a = 0.45 if health <= 0 else flash


func _physics_process(delta: float) -> void:
	_invincible = maxf(_invincible - delta, 0.0)
	if frozen:
		velocity = Vector2.ZERO
		_set_target(null)
		return
	match state:
		State.NORMAL:
			_move()
			_set_target(_find_target())
			var talk := Input.is_action_just_pressed(&"interact")
			var attack := Input.is_action_just_pressed(&"attack")
			if (talk or attack) and target != null:
				interact_requested.emit(target)
			elif attack:
				_start_attack()
		State.ATTACK:
			velocity = Vector2.ZERO
			_state_time -= delta
			if _state_time <= 0.0:
				state = State.NORMAL
		State.HURT:
			_state_time -= delta
			velocity = _knockback * maxf(_state_time, 0.0) / HURT_TIME
			move_and_slide()
			if _state_time <= 0.0:
				state = State.NORMAL


## Returns true if the hit landed (false while invincible, frozen or already down).
func take_hit(damage: int, from_position: Vector2) -> bool:
	if frozen or _invincible > 0.0 or health <= 0:
		return false
	health = maxi(health - damage, 0)
	_knockback = (global_position - from_position).normalized() * KNOCKBACK_SPEED
	if _knockback == Vector2.ZERO:
		_knockback = -facing * KNOCKBACK_SPEED
	state = State.HURT
	_state_time = HURT_TIME
	_invincible = INVINCIBLE_SECONDS
	_squash = Vector2(0.84, 1.14)
	_cutlass.cancel()
	Effects.burst(get_parent(), position + Vector2(0, -40), "hit")
	health_changed.emit(health, max_health)
	if health == 0:
		frozen = true
		died.emit()
	return true


func heal(amount: int) -> void:
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)


func is_full_health() -> bool:
	return health >= max_health


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


func revive() -> void:
	health = max_health
	frozen = false
	state = State.NORMAL
	_invincible = REVIVE_INVINCIBLE_SECONDS
	health_changed.emit(health, max_health)


func end_invincibility() -> void:
	_invincible = 0.0


func _move() -> void:
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if direction != Vector2.ZERO:
		facing = _cardinal(direction)
		if facing.x != 0.0:
			_sprite.flip_h = facing.x < 0.0
	velocity = direction * SPEED
	move_and_slide()


func _find_target() -> Interactable:
	var best: Interactable = null
	var best_distance := INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("interactables"):
		var thing := node as Interactable
		if thing == null or not thing.can_interact(story_flags):
			continue
		var to := thing.touch_point(global_position) - global_position
		var distance := to.length()
		if distance > best_distance or (distance > 30.0 and to.normalized().dot(facing) < 0.3):
			continue
		best = thing
		best_distance = distance
	return best


func _set_target(thing: Interactable) -> void:
	if thing == target:
		return
	if target != null and is_instance_valid(target):
		target.set_highlighted(false)
	target = thing
	if target != null:
		target.set_highlighted(true)


func _start_attack() -> void:
	state = State.ATTACK
	_state_time = ATTACK_TIME
	_squash = Vector2(1.16, 0.88)
	_cutlass.swing(facing, ATTACK_TIME)


static func _cardinal(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2(signf(direction.x), 0.0)
	return Vector2(0.0, signf(direction.y))

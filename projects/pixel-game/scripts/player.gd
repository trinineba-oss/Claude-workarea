class_name Player
extends CharacterBody2D
## Top-down hero: moves with the move_* actions, swings the cutlass with attack, and has
## health in half "doubles" (two halves per heart icon).

signal health_changed(health: int, max_health: int)
signal money_changed(money: int)
signal died

enum State { NORMAL, ATTACK, HURT }

const SPEED := 64.0
const ATTACK_TIME := 0.28
const HURT_TIME := 0.18
const KNOCKBACK_SPEED := 120.0
const INVINCIBLE_SECONDS := 1.0
const REVIVE_INVINCIBLE_SECONDS := 1.5

var max_health := 6
var health := 6
var money := 0
## Last cardinal direction the hero moved in (the cutlass swings this way).
var facing := Vector2.DOWN
## While true the hero ignores input and cannot be hurt (room transitions, cutscenes).
var frozen := false
var state := State.NORMAL

var _state_time := 0.0
var _invincible := 0.0
var _knockback := Vector2.ZERO

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _cutlass: Cutlass = $Cutlass


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	_invincible = maxf(_invincible - delta, 0.0)
	if health > 0:
		_sprite.modulate.a = 0.4 if _invincible > 0.0 and int(_invincible * 14.0) % 2 == 0 else 1.0
	if frozen:
		velocity = Vector2.ZERO
		return
	match state:
		State.NORMAL:
			_move()
			if Input.is_action_just_pressed(&"attack"):
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
	_cutlass.cancel()
	health_changed.emit(health, max_health)
	if health == 0:
		frozen = true
		_sprite.modulate.a = 0.3
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
	_sprite.modulate.a = 1.0
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


func _start_attack() -> void:
	state = State.ATTACK
	_state_time = ATTACK_TIME
	_cutlass.swing(facing, ATTACK_TIME)


static func _cardinal(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2(signf(direction.x), 0.0)
	return Vector2(0.0, signf(direction.y))

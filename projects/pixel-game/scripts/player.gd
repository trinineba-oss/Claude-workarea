class_name Player
extends CharacterBody2D
## Top-down hero: moves with the move_* actions and has health in half "doubles" (two halves
## per heart icon). The node's origin is at the hero's feet, which is what depth sorting uses.
##
## Combat is built to feel tight:
##   attack  a three-hit cutlass combo (the third is a wide, heavy finisher). Each swing lunges
##           Chad forward, in any of eight directions. Presses are buffered, so a press a
##           moment early still chains.
##   dodge   a quick roll in the direction held (or faced). Chad can't be hurt for most of it,
##           and it cancels a swing at any time.
## Beating enemies gives XP; levels make the cutlass hit harder (the RPG layer).

signal health_changed(health: int, max_health: int)
signal money_changed(money: int)
signal died
## The hero pressed interact (or attack) while facing something to talk to or read.
signal interact_requested(target: Interactable)
signal xp_changed(xp: int, needed: int, level: int)
signal leveled_up(level: int)

enum State { NORMAL, ATTACK, HURT, DODGE }

const SPEED := 256.0
## The first swing's length (kept for code that times the swing animation).
const ATTACK_TIME := 0.22
## The combo: seconds, damage, sweep (degrees), reach, lunge speed, knockback force, hit-stop.
const COMBO := [
	{"time": 0.22, "damage": 1, "sweep": 120.0, "reach": 52.0, "lunge": 260.0, "force": 1.0},
	{"time": 0.22, "damage": 1, "sweep": -120.0, "reach": 52.0, "lunge": 260.0, "force": 1.0},
	{"time": 0.36, "damage": 2, "sweep": 210.0, "reach": 64.0, "lunge": 420.0, "force": 1.9},
]
## A swing can chain into the next once this much of it has played.
const CHAIN_AT := 0.55
## After a swing ends, the combo can still be continued for this long.
const COMBO_GRACE := 0.28
## A press this long before it can act still counts (attack and dodge).
const BUFFER := 0.16
const DODGE_TIME := 0.3
const DODGE_SPEED := 640.0
## Chad can't be hurt for this much of the dodge.
const DODGE_SAFE := 0.24
const DODGE_COOLDOWN := 0.35
const MAX_LEVEL := 10
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

## How long the current swing lasts (for the swing animation).
var attack_time := ATTACK_TIME
## Which hit of the combo is playing (0, 1, 2).
var combo_step := 0
## The way Chad swings or rolls: eight directions.
var aim := Vector2.DOWN
var level: int:
	get:
		return clampi(int(story_flags.get("chad_level", 1)), 1, MAX_LEVEL)
var xp: int:
	get:
		return int(story_flags.get("chad_xp", 0))

var _state_time := 0.0
var _attack_buffer := 0.0
var _dodge_buffer := 0.0
var _combo_grace := 0.0
var _dodge_cooldown := 0.0
var _lunge := Vector2.ZERO
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
	if state == State.DODGE:
		# A low, stretched tumble.
		_squash = Vector2(1.25, 0.72)
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
	if state == State.DODGE:
		flash = 0.6
	_sprite.modulate.a = 0.45 if health <= 0 else flash


func _physics_process(delta: float) -> void:
	_invincible = maxf(_invincible - delta, 0.0)
	_attack_buffer = maxf(_attack_buffer - delta, 0.0)
	_dodge_buffer = maxf(_dodge_buffer - delta, 0.0)
	_combo_grace = maxf(_combo_grace - delta, 0.0)
	_dodge_cooldown = maxf(_dodge_cooldown - delta, 0.0)
	if frozen:
		velocity = Vector2.ZERO
		_attack_buffer = 0.0
		_dodge_buffer = 0.0
		_set_target(null)
		return
	if Input.is_action_just_pressed(&"attack"):
		_attack_buffer = BUFFER
	if Input.is_action_just_pressed(&"dodge"):
		_dodge_buffer = BUFFER
	match state:
		State.NORMAL:
			_move()
			_set_target(_find_target())
			var talk := Input.is_action_just_pressed(&"interact")
			if (talk or _attack_buffer > 0.0) and target != null:
				_attack_buffer = 0.0
				interact_requested.emit(target)
			elif _dodge_buffer > 0.0 and _dodge_cooldown <= 0.0:
				_start_dodge()
			elif _attack_buffer > 0.0:
				_start_attack(combo_step + 1 if _combo_grace > 0.0 else 0)
		State.ATTACK:
			_state_time -= delta
			var played := 1.0 - _state_time / attack_time
			# The lunge is quick at the start of the swing and gone by the middle.
			velocity = _lunge * maxf(1.0 - played * 2.2, 0.0)
			move_and_slide()
			if _dodge_buffer > 0.0 and _dodge_cooldown <= 0.0:
				_cutlass.cancel()
				_start_dodge()
			elif _attack_buffer > 0.0 and played >= CHAIN_AT and combo_step < COMBO.size() - 1:
				_start_attack(combo_step + 1)
			elif _state_time <= 0.0:
				state = State.NORMAL
				_combo_grace = COMBO_GRACE if combo_step < COMBO.size() - 1 else 0.0
		State.DODGE:
			_state_time -= delta
			# Fast out of the blocks, easing off at the end.
			velocity = _lunge * (0.35 + 0.65 * clampf(_state_time / DODGE_TIME * 1.6, 0.0, 1.0))
			move_and_slide()
			if _state_time <= 0.0:
				state = State.NORMAL
				_dodge_cooldown = DODGE_COOLDOWN
		State.HURT:
			_state_time -= delta
			velocity = _knockback * maxf(_state_time, 0.0) / HURT_TIME
			move_and_slide()
			if _state_time <= 0.0:
				state = State.NORMAL


## Returns true if the hit landed (false while invincible, frozen or already down).
func take_hit(damage: int, from_position: Vector2) -> bool:
	if frozen or _invincible > 0.0 or health <= 0 or is_dodge_safe():
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


## True during the part of a dodge in which nothing can hurt Chad.
func is_dodge_safe() -> bool:
	return state == State.DODGE and _state_time > DODGE_TIME - DODGE_SAFE


## The cutlass's damage: the swing's own, plus one for every two levels.
func attack_damage(step: int) -> int:
	return int(COMBO[step]["damage"]) + (level - 1) / 2


func xp_needed() -> int:
	return 4 + level * 4


## XP from a beaten enemy. A new level heals Chad and makes the cutlass hit harder.
func gain_xp(amount: int) -> void:
	if amount <= 0 or level >= MAX_LEVEL:
		return
	var total := xp + amount
	var now := level
	while now < MAX_LEVEL and total >= 4 + now * 4:
		total -= 4 + now * 4
		now += 1
	var gained := now > level
	story_flags["chad_level"] = now
	story_flags["chad_xp"] = total if now < MAX_LEVEL else 0
	if gained:
		heal(max_health)
		_squash = Vector2(0.8, 1.3)
		Effects.burst(get_parent(), position + Vector2(0, -40), "sparkle")
		Effects.flourish(get_parent(), position, "star_burst_gold", 2.6, 0.9)
		Effects.float_text(
			get_parent(), position + Vector2(0, -120), "LEVEL UP!", Color(1, 0.9, 0.4)
		)
		leveled_up.emit(now)
	xp_changed.emit(xp, xp_needed(), level)


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
		aim = _eight_way(direction)
		if facing.x != 0.0:
			_sprite.flip_h = facing.x < 0.0
	velocity = direction * SPEED
	move_and_slide()
	if direction == Vector2.ZERO:
		return
	# Walking into a push block or a locked door does something.
	for i in get_slide_collision_count():
		var body := get_slide_collision(i).get_collider()
		if body != null and body.has_method("bump"):
			body.bump(self, facing)


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


func _start_attack(step := 0) -> void:
	_attack_buffer = 0.0
	_combo_grace = 0.0
	combo_step = clampi(step, 0, COMBO.size() - 1)
	var move: Dictionary = COMBO[combo_step]
	# Swing where the stick points (eight ways), or the way he faces.
	var held := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if held != Vector2.ZERO:
		aim = _eight_way(held)
		facing = _cardinal(held)
	elif aim.dot(facing) < 0.5:
		aim = facing
	state = State.ATTACK
	attack_time = move["time"]
	_state_time = attack_time
	_lunge = aim * float(move["lunge"])
	_squash = Vector2(1.22, 0.84) if combo_step == 2 else Vector2(1.16, 0.88)
	_cutlass.swing(
		aim, attack_time, attack_damage(combo_step), move["sweep"], move["reach"], move["force"]
	)


func _start_dodge() -> void:
	_dodge_buffer = 0.0
	_attack_buffer = 0.0
	_combo_grace = 0.0
	var held := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if held != Vector2.ZERO:
		aim = _eight_way(held)
		facing = _cardinal(held)
	state = State.DODGE
	_state_time = DODGE_TIME
	_lunge = (held.normalized() if held != Vector2.ZERO else aim) * DODGE_SPEED
	Effects.burst(get_parent(), position + Vector2(0, -8), "dust")


static func _eight_way(direction: Vector2) -> Vector2:
	return Vector2.from_angle(snappedf(direction.angle(), PI / 4.0))


static func _cardinal(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2(signf(direction.x), 0.0)
	return Vector2(0.0, signf(direction.y))

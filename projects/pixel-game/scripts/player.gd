class_name Player
extends CharacterBody2D
## Top-down hero: moves with the move_* actions and has health in half "doubles" (two halves
## per heart icon). The node's origin is at the hero's feet, which is what depth sorting uses.
##
## Combat is built to feel tight, open-world style:
##   attack  the equipped weapon's combo (data/weapons.json): the cutlass, a branch, a plank, a
##           cricket bat, a fishing spear, or bare fists (a boxing combo: jab, jab, cross,
##           hook, uppercut). Each move lunges Chad forward, in any of eight directions.
##           Presses are buffered, so a press a moment early still chains. Keep holding attack
##           after a swing to charge a spin attack; let go to unleash it.
##   weapons wear out with every hit and break (Weapons.durability); Chad carries up to five,
##           swaps between them (swap_weapon) and can throw the one in hand (throw_weapon).
##   dodge   a quick roll in the direction held (or faced). Chad can't be hurt for most of it,
##           and it cancels a swing at any time. Dodging an attack at the last moment (a
##           perfect dodge) starts a flurry rush: enemies freeze for a moment while Chad
##           lands a burst of quick hits.
## Beating enemies gives XP; levels make every weapon hit harder (the RPG layer).

signal health_changed(health: int, max_health: int)
signal money_changed(money: int)
signal died
## The hero pressed interact (or attack) while facing something to talk to or read.
signal interact_requested(target: Interactable)
signal xp_changed(xp: int, needed: int, level: int)
signal leveled_up(level: int)
## The weapon in hand changed (equipped, swapped, broke, thrown).
signal weapon_changed(id: String, wear: int, durability: int)

enum State { NORMAL, ATTACK, HURT, DODGE, CHARGE }

const SPEED := 256.0
## The cutlass's first swing (kept for code that times the swing animation).
const ATTACK_TIME := 0.22
## Holding attack this long after a swing starts charging a spin.
const CHARGE_HOLD := 0.3
## A charge is full (and the spin can go) after this long.
const CHARGE_FULL := 0.45
## A dodge this fresh when an attack would have landed is a perfect dodge.
const PERFECT_DODGE := 0.12
## How long (real seconds) a flurry rush lasts, and how much faster its swings are.
const FLURRY_TIME := 1.6
const FLURRY_SPEED := 0.55
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
## Which hit of the combo is playing (0, 1, 2...).
var combo_step := 0
## The move being played ({"time", "damage", "anim"...}; see data/weapons.json).
var current_move: Dictionary = {}
## Real seconds left of a flurry rush (after a perfect dodge).
var flurry := 0.0
## The way Chad swings or rolls: eight directions.
var aim := Vector2.DOWN
var level: int:
	get:
		return clampi(int(story_flags.get("chad_level", 1)), 1, MAX_LEVEL)
var xp: int:
	get:
		return int(story_flags.get("chad_xp", 0))

## A pose the 2.5D view shows while Chad stands still: "hold" (raising a find), "eat" or
## "fish"; it lasts `pose_time` seconds.
var pose := ""
var pose_time := 0.0
var _state_time := 0.0
var _attack_held := 0.0
var _charge := 0.0
var _attack_buffer := 0.0
var _dodge_buffer := 0.0
var _combo_grace := 0.0
var _dodge_cooldown := 0.0
var _lunge := Vector2.ZERO
var _invincible := 0.0
var _knockback := Vector2.ZERO
var _step := 0.0
var _squash := Vector2.ONE
var _flurry_started := 0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _cutlass: Cutlass = $Cutlass


func _ready() -> void:
	add_to_group("player")
	_cutlass.landed.connect(func(_body, _damage): wear_weapon())
	_cutlass.hit_world.connect(func(_cell): wear_weapon())


func _process(delta: float) -> void:
	pose_time = maxf(pose_time - delta, 0.0)
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
	if state == State.CHARGE:
		# Charging: a shiver that grows, and a glow once it is full.
		var full := _charge >= CHARGE_FULL
		_sprite.position.x = sin(Time.get_ticks_msec() * 0.08) * (2.0 if full else 1.0)
		_sprite.self_modulate = Color(1.4, 1.3, 0.9) if full else Color.WHITE
	else:
		_sprite.position.x = 0.0
		_sprite.self_modulate = Color.WHITE


func _physics_process(delta: float) -> void:
	_invincible = maxf(_invincible - delta, 0.0)
	_attack_buffer = maxf(_attack_buffer - delta, 0.0)
	_dodge_buffer = maxf(_dodge_buffer - delta, 0.0)
	_combo_grace = maxf(_combo_grace - delta, 0.0)
	_dodge_cooldown = maxf(_dodge_cooldown - delta, 0.0)
	_attack_held = _attack_held + delta if Input.is_action_pressed(&"attack") else 0.0
	_update_flurry()
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
	if state in [State.NORMAL, State.ATTACK] and Input.is_action_just_pressed(&"swap_weapon"):
		cycle_weapon()
	if state == State.NORMAL and Input.is_action_just_pressed(&"throw_weapon"):
		throw_weapon()
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
			elif _attack_held >= CHARGE_HOLD and not _charge_move().is_empty():
				state = State.CHARGE
				_charge = 0.0
		State.ATTACK:
			_state_time -= delta
			var played := 1.0 - _state_time / attack_time
			# The lunge is quick at the start of the swing and gone by the middle.
			velocity = _lunge * maxf(1.0 - played * 2.2, 0.0)
			move_and_slide()
			if _dodge_buffer > 0.0 and _dodge_cooldown <= 0.0:
				_cutlass.cancel()
				_start_dodge()
			elif _attack_buffer > 0.0 and played >= CHAIN_AT:
				_start_attack(combo_step + 1 if combo_step < _combo().size() - 1 else 0)
			elif _state_time <= 0.0:
				if _attack_held >= CHARGE_HOLD and not _charge_move().is_empty():
					state = State.CHARGE
					_charge = 0.0
				else:
					state = State.NORMAL
					_combo_grace = COMBO_GRACE if combo_step < _combo().size() - 1 else 0.0
		State.CHARGE:
			# Slow steps while charging; letting go spins (or fizzles if not full yet).
			var held := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
			velocity = held * SPEED * 0.35
			move_and_slide()
			_charge += delta
			if _dodge_buffer > 0.0 and _dodge_cooldown <= 0.0:
				_start_dodge()
			elif not Input.is_action_pressed(&"attack"):
				if _charge >= CHARGE_FULL:
					_start_move(_charge_move(), true)
				else:
					state = State.NORMAL
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
	if is_dodge_safe() and _state_time > DODGE_TIME - PERFECT_DODGE and flurry <= 0.0:
		start_flurry()
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
	Sfx.play("hurt")
	Effects.burst(get_parent(), position + Vector2(0, -40), "hit")
	health_changed.emit(health, max_health)
	if health == 0:
		frozen = true
		died.emit()
	return true


## True during the part of a dodge in which nothing can hurt Chad.
func is_dodge_safe() -> bool:
	return state == State.DODGE and _state_time > DODGE_TIME - DODGE_SAFE


## A move's damage with the weapon in hand: the move's own, plus one for every two levels.
func attack_damage(step: int) -> int:
	var moves := _combo()
	return _move_damage(moves[clampi(step, 0, moves.size() - 1)])


func _move_damage(move: Dictionary) -> int:
	return int(move.get("damage", 1)) + (level - 1) / 2


# --- weapons --------------------------------------------------------------------------------


## The weapons Chad carries: [{"id", "wear"}] (kept in the story flags, so it is saved).
func weapons() -> Array:
	if not story_flags.has("weapons"):
		story_flags["weapons"] = []
	return story_flags["weapons"]


## Which carried weapon is in hand: an index into weapons(), or -1 for bare fists.
func _weapon_slot() -> int:
	var slot := int(story_flags.get("weapon_slot", -1))
	return slot if slot >= 0 and slot < weapons().size() else -1


## The id of the weapon in hand ("fists" when none).
func weapon_id() -> String:
	var slot := _weapon_slot()
	return str(weapons()[slot]["id"]) if slot >= 0 else Weapons.FISTS


## Hits left in the weapon in hand (0 for fists, which never break).
func weapon_wear() -> int:
	var slot := _weapon_slot()
	return int(weapons()[slot]["wear"]) if slot >= 0 else 0


## A new game starts with the cutlass in hand.
func give_starting_weapons() -> void:
	if story_flags.has("weapons"):
		return
	story_flags["weapons"] = [{"id": "cutlass", "wear": Weapons.durability("cutlass")}]
	story_flags["weapon_slot"] = 0
	_announce_weapon(false)


## Picks up a weapon (`wear` < 0 = brand new). False if the pouch is full.
func add_weapon(id: String, wear := -1) -> bool:
	if not Weapons.has(id) or id == Weapons.FISTS or weapons().size() >= Weapons.POUCH:
		return false
	weapons().append({"id": id, "wear": wear if wear > 0 else Weapons.durability(id)})
	if _weapon_slot() < 0:
		_equip(weapons().size() - 1)
	else:
		_announce_weapon(false)
	return true


## Takes a weapon in hand (-1 = fists).
func _equip(slot: int) -> void:
	story_flags["weapon_slot"] = slot if slot >= 0 and slot < weapons().size() else -1
	_announce_weapon(true)


## The next weapon in the pouch, then fists, then round again.
func cycle_weapon() -> void:
	var slot := _weapon_slot() + 1
	_equip(slot if slot < weapons().size() else -1)


## One hit's wear on the weapon in hand; at zero it breaks and the next one comes out.
func wear_weapon(amount := 1) -> void:
	var slot := _weapon_slot()
	if slot < 0:
		return
	var entry: Dictionary = weapons()[slot]
	entry["wear"] = int(entry["wear"]) - amount
	if int(entry["wear"]) > 0:
		weapon_changed.emit(weapon_id(), weapon_wear(), Weapons.durability(weapon_id()))
		return
	var broken := str(entry["id"])
	Sfx.play("break_weapon")
	weapons().remove_at(slot)
	Effects.burst(get_parent(), position + Vector2(0, -50), "hit")
	Effects.float_text(
		get_parent(),
		position + Vector2(0, -130),
		"%s broke!" % Weapons.display_name(broken),
		Color(1, 0.6, 0.45)
	)
	_squash = Vector2(1.2, 0.85)
	var evey := get_tree().get_first_node_in_group("companion") as Companion
	if evey != null:
		evey.remark("weapon_broke")
	_equip(mini(slot, weapons().size() - 1))


## Throws the weapon in hand the way Chad aims: it spins away, hits the first enemy for its
## throw damage (wearing it), then drops to the ground to be picked up again.
func throw_weapon() -> WeaponThrow:
	var slot := _weapon_slot()
	if slot < 0 or frozen:
		return null
	var entry: Dictionary = weapons()[slot]
	weapons().remove_at(slot)
	Sfx.play("throw")
	var thrown := WeaponThrow.new()
	thrown.setup(str(entry["id"]), int(entry["wear"]), aim, self)
	get_parent().add_child(thrown)
	thrown.position = position + Vector2(0, -36)
	_squash = Vector2(1.15, 0.88)
	_equip(mini(slot, weapons().size() - 1))
	return thrown


func _announce_weapon(show_name: bool) -> void:
	var id := weapon_id()
	weapon_changed.emit(id, weapon_wear(), Weapons.durability(id))
	if show_name and is_inside_tree():
		Effects.float_text(
			get_parent(), position + Vector2(0, -130), Weapons.display_name(id), Color.WHITE
		)


func _combo() -> Array:
	var moves := Weapons.combo(weapon_id())
	return moves if not moves.is_empty() else Weapons.combo(Weapons.FISTS)


## The spin attack (or haymaker) of the weapon in hand.
func _charge_move() -> Dictionary:
	return Weapons.charge(weapon_id())


# --- flurry rush ----------------------------------------------------------------------------


## A perfect dodge: enemies freeze (tinted blue) for a moment and Chad's swings speed up.
func start_flurry() -> void:
	flurry = FLURRY_TIME
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node
		enemy.set_physics_process(false)
		if enemy is CanvasItem:
			(enemy as CanvasItem).modulate = Color(0.6, 0.75, 1.3)
	Effects.float_text(
		get_parent(), position + Vector2(0, -130), "Perfect dodge!", Color(0.7, 0.9, 1.0)
	)
	Juice.punch(0.06)
	_flurry_started = Time.get_ticks_msec()


func _update_flurry() -> void:
	if flurry <= 0.0:
		return
	flurry = FLURRY_TIME - (Time.get_ticks_msec() - _flurry_started) / 1000.0
	if flurry <= 0.0:
		flurry = 0.0
		for node in get_tree().get_nodes_in_group("enemies"):
			var enemy := node as Node
			enemy.set_physics_process(true)
			if enemy is CanvasItem:
				(enemy as CanvasItem).modulate = Color.WHITE


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
		Sfx.play("level_up", 0.0)
		heal(max_health)
		_squash = Vector2(0.8, 1.3)
		Effects.burst(get_parent(), position + Vector2(0, -40), "sparkle")
		Effects.flourish(get_parent(), position, "star_burst_gold", 2.6, 0.9)
		Effects.float_text(
			get_parent(), position + Vector2(0, -120), "LEVEL UP!", Color(1, 0.9, 0.4)
		)
		leveled_up.emit(now)
	xp_changed.emit(xp, xp_needed(), level)


## Shows a pose (see `pose`) for `seconds`; "" ends it.
func strike_pose(pose_name: String, seconds: float) -> void:
	pose = pose_name
	pose_time = seconds if pose_name != "" else 0.0


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
	var moves := _combo()
	combo_step = clampi(step, 0, moves.size() - 1)
	_start_move(moves[combo_step], false)


## Plays one move: a combo hit or the charged spin.
func _start_move(move: Dictionary, spin: bool) -> void:
	_attack_buffer = 0.0
	_combo_grace = 0.0
	current_move = move
	# Swing where the stick points (eight ways), or the way he faces.
	var held := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if held != Vector2.ZERO:
		aim = _eight_way(held)
		facing = _cardinal(held)
	elif aim.dot(facing) < 0.5:
		aim = facing
	state = State.ATTACK
	attack_time = float(move["time"]) * (FLURRY_SPEED if flurry > 0.0 else 1.0)
	_state_time = attack_time
	_lunge = aim * float(move["lunge"])
	var heavy := float(move["force"]) > 1.5
	_squash = Vector2(1.22, 0.84) if heavy else Vector2(1.16, 0.88)
	var damage := _move_damage(move) + (1 if flurry > 0.0 else 0)
	_cutlass.swing(aim, attack_time, damage, move["sweep"], move["reach"], move["force"])
	_cutlass.set_style(Weapons.look(weapon_id()), Weapons.kind(weapon_id()))
	Sfx.play("swing_heavy" if heavy or spin else ("whoosh" if weapon_id() == "fists" else "swing"))
	if spin:
		Effects.spin_slash(get_parent(), position)
		Effects.burst(get_parent(), position + Vector2(0, -30), "sparkle")
		Juice.shake(0.12)


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
	Sfx.play("roll")
	Effects.burst(get_parent(), position + Vector2(0, -8), "dust")


static func _eight_way(direction: Vector2) -> Vector2:
	return Vector2.from_angle(snappedf(direction.angle(), PI / 4.0))


static func _cardinal(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2(signf(direction.x), 0.0)
	return Vector2(0.0, signf(direction.y))

class_name BigCrab
extends Enemy
## The Big Blue Crab, Callaloo Cave's mini-boss (it has heard what people put in callaloo, and
## it is not happy). Its shell shrugs off the cutlass. It sidles to line up with Chad, raises
## its claws, then charges; if it rams a wall it is stunned on its back, and only then can it
## be hurt. A coconut boomerang stuns it too. Beating it fires its trigger.

signal defeated

enum State { SIDLE, TELEGRAPH, CHARGE, STUNNED, RECOVER }

const SIDLE_SPEED := 150.0
const CHARGE_SPEED := 560.0
const SIDLE_TIME := 1.8
const TELEGRAPH_TIME := 0.6
const CHARGE_TIME := 1.4
const STUN_TIME := 2.2
const BOOMERANG_STUN_TIME := 1.5
const RECOVER_TIME := 0.6
const CHARGE_DAMAGE := 2
const COINS := 5

## Fired (Game.trigger) when it is beaten; shutters open and its chest appears.
var trigger_name := ""
var state := State.SIDLE

var _timer := SIDLE_TIME
var _charge_dir := Vector2.ZERO
var _tink_cooldown := 0.0


func _ready() -> void:
	super()
	add_to_group("bosses")
	var game := get_tree().get_first_node_in_group("game") as Game
	if game != null and game.progress.is_triggered(trigger_name):
		queue_free()


func take_hit(damage: int, from_position: Vector2) -> bool:
	if health <= 0:
		return false
	if state != State.STUNNED:
		if _tink_cooldown <= 0.0:
			_tink_cooldown = 0.5
			Effects.float_text(get_parent(), position + Vector2(0, -130), "Tink!", Color.WHITE)
		return false
	var landed := super(damage, from_position)
	_stun = 0.0  # it is on its back: no knockback
	return landed


## The boomerang flips it over for a moment.
func boomerang_hit() -> void:
	if health > 0 and state != State.STUNNED:
		_enter(State.STUNNED, BOOMERANG_STUN_TIME)


func _think(delta: float) -> void:
	_timer -= delta
	_tink_cooldown = maxf(_tink_cooldown - delta, 0.0)
	var player := _player()
	if not _player_in_my_room():
		velocity = Vector2.ZERO
		return
	match state:
		State.SIDLE:
			velocity = Vector2.ZERO
			if player != null:
				var to := player.global_position - global_position
				velocity = Vector2(clampf(to.x / 40.0, -1.0, 1.0), clampf(to.y / 160.0, -0.4, 0.4))
				velocity *= SIDLE_SPEED
			if _timer <= 0.0:
				_enter(State.TELEGRAPH, TELEGRAPH_TIME)
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_charge_dir = (
					global_position.direction_to(player.global_position)
					if player != null
					else Vector2.DOWN
				)
				_enter(State.CHARGE, CHARGE_TIME)
		State.CHARGE:
			velocity = _charge_dir * CHARGE_SPEED
			var started := _timer < CHARGE_TIME - 0.1
			if started and get_slide_collision_count() > 0:
				Effects.burst(get_parent(), position + Vector2(0, -40), "hit")
				Effects.float_text(get_parent(), position + Vector2(0, -130), "BONK", Color.WHITE)
				_enter(State.STUNNED, STUN_TIME)
			elif _timer <= 0.0:
				_enter(State.RECOVER, RECOVER_TIME)
		State.STUNNED:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_enter(State.RECOVER, RECOVER_TIME)
		State.RECOVER:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				_enter(State.SIDLE, SIDLE_TIME)


func _touch_player(player: Player) -> void:
	if state == State.STUNNED:
		return
	player.take_hit(CHARGE_DAMAGE if state == State.CHARGE else contact_damage, global_position)


func _animate(_delta: float) -> void:
	_sprite.flip_v = state == State.STUNNED
	match state:
		State.TELEGRAPH:
			_sprite.position = Vector2(sin(_age * 70.0) * 4.0, -6.0)
		State.STUNNED:
			_sprite.position = Vector2(sin(_age * 12.0) * 3.0, 0)
		State.CHARGE:
			_sprite.position = Vector2(0, -absf(sin(_age * 30.0)) * 4.0)
		_:
			_sprite.position = Vector2(
				sin(_age * 18.0) * 3.0 if velocity.length() > 1.0 else 0.0, 0
			)


func _die() -> void:
	died.emit()
	defeated.emit()
	var room := get_parent()
	Effects.burst(room, position + Vector2(0, -50), "poof")
	Effects.burst(room, position + Vector2(-30, -30), "poof")
	Effects.burst(room, position + Vector2(30, -30), "poof")
	Effects.float_text(
		room, position + Vector2(0, -150), "The Big Blue Crab retreats!", Color(0.7, 0.9, 1)
	)
	for i in COINS:
		var coin: Pickup = Entities.create("coin")
		coin.position = position + Vector2.from_angle(i * TAU / COINS) * 70.0
		coin.lifetime = Pickup.DROP_LIFETIME
		room.add_child.call_deferred(coin)
	var game := get_tree().get_first_node_in_group("game") as Game
	if game != null:
		game.progress.fire(trigger_name)
	queue_free()


func _enter(new_state: State, seconds: float) -> void:
	state = new_state
	_timer = seconds

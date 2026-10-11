class_name Cauldron
extends Enemy
## The Callaloo Cauldron, Temple 1's boss: a giant iron pot of callaloo that has been simmering
## (and snoring) for a hundred years. With its lid on it shrugs everything off and hops after
## Chad. Then it lifts the lid and spits hot callaloo; while the lid is up, a boomerang knocks
## it off and leaves the pot dizzy, and only then does the cutlass hurt it. At half health it
## gets angry: faster hops and wider spits. Beating it fires its trigger.

enum State { HOP, LIFT, OPEN, DIZZY }

const HOP_SPEED := 170.0
const ANGRY_HOP_SPEED := 240.0
const HOP_TIME := 3.0
const LIFT_TIME := 0.5
const OPEN_TIME := 1.8
const DIZZY_TIME := 2.6
const BLOBS := 3
const ANGRY_BLOBS := 5
const SPREAD := deg_to_rad(18.0)
const COINS := 8
## Where the lid sits on the rim, above the pot's base.
const LID_Y := -128.0

## Fired (Game.progress) when it is beaten: shutters open, the heart and seasoning appear.
var trigger_name := ""
var state := State.HOP

var _timer := HOP_TIME
var _tink_cooldown := 0.0
var _announced := false

@onready var _lid: Sprite2D = $Lid


func _ready() -> void:
	super()
	add_to_group("bosses")
	var game := _game()
	if game != null and game.progress.is_triggered(trigger_name):
		queue_free()


func is_angry() -> bool:
	return health <= max_health / 2


func take_hit(damage: int, from_position: Vector2) -> bool:
	if health <= 0:
		return false
	if state != State.DIZZY:
		_say("Too hot!" if _lid_up() else "Tonk!")
		return false
	var landed := super(damage, from_position)
	_stun = 0.0  # too heavy to knock back
	return landed


## A boomerang into the open pot knocks the lid off.
func boomerang_hit() -> void:
	if health <= 0:
		return
	if _lid_up() and state != State.DIZZY:
		_enter(State.DIZZY, DIZZY_TIME)
		var fall := create_tween()
		fall.tween_property(_lid, "position", Vector2(90, -20), 0.35)
		fall.parallel().tween_property(_lid, "rotation", 2.6, 0.35)
		_say("Dizzy!")
	elif not _lid_up():
		_say("Tonk!")


func _think(delta: float) -> void:
	_timer -= delta
	_tink_cooldown = maxf(_tink_cooldown - delta, 0.0)
	var player := _player()
	velocity = Vector2.ZERO
	if not _player_in_my_room():
		return
	if not _announced:
		_announced = true
		Effects.float_text(
			get_parent(), position + Vector2(0, -200), "WHO DISTURB MY SIMMER?!", Color(0.7, 1, 0.6)
		)
	match state:
		State.HOP:
			# Short hops toward Chad: moving for the first part of each beat.
			var beat := fmod(_age, 0.8)
			if player != null and beat < 0.45:
				var speed := ANGRY_HOP_SPEED if is_angry() else HOP_SPEED
				velocity = global_position.direction_to(player.global_position) * speed
			if _timer <= 0.0:
				_enter(State.LIFT, LIFT_TIME)
		State.LIFT:
			if _timer <= 0.0:
				_spit(player)
				_enter(State.OPEN, OPEN_TIME)
		State.OPEN:
			if is_angry() and _timer <= OPEN_TIME / 2.0 and _timer + delta > OPEN_TIME / 2.0:
				_spit(player)
			if _timer <= 0.0:
				_enter(State.HOP, HOP_TIME)
		State.DIZZY:
			if _timer <= 0.0:
				_enter(State.HOP, HOP_TIME)


func _animate(_delta: float) -> void:
	var squash := 1.0
	match state:
		State.HOP:
			var beat := fmod(_age, 0.8)
			_sprite.position.y = -sin(beat / 0.45 * PI) * 22.0 if beat < 0.45 else 0.0
			squash = 1.0 if beat < 0.45 else 1.0 - (beat - 0.45) * 0.2
		State.LIFT:
			_sprite.position = Vector2(sin(_age * 60.0) * 4.0, 0)
		State.DIZZY:
			_sprite.position = Vector2(0, 0)
			_sprite.rotation = sin(_age * 6.0) * 0.12
		_:
			_sprite.position = Vector2.ZERO
	if state != State.DIZZY:
		_sprite.rotation = 0.0
	_sprite.scale = Vector2(2.0 - squash, squash)
	if state != State.DIZZY:
		var lift := 46.0 if _lid_up() else 0.0
		_lid.rotation = sin(_age * 9.0) * 0.08 if _lid_up() else 0.0
		_lid.position = Vector2(0, _sprite.position.y + LID_Y - lift)


func _touch_player(player: Player) -> void:
	if state != State.DIZZY:
		player.take_hit(contact_damage, global_position)


func _lid_up() -> bool:
	return state == State.OPEN or state == State.LIFT


func _spit(player: Player) -> void:
	var room := get_parent()
	var game := _game()
	if room == null or game == null:
		return
	var aim := (
		global_position.direction_to(player.global_position) if player != null else Vector2.DOWN
	)
	var count := ANGRY_BLOBS if is_angry() else BLOBS
	for i in count:
		var blob := CallalooBlob.new()
		var angle := (i - (count - 1) / 2.0) * SPREAD
		blob.launch(position + aim * 70.0, aim.rotated(angle), game.world)
		room.add_child(blob)


func _die() -> void:
	died.emit()
	var room := get_parent()
	for offset in [Vector2(0, -60), Vector2(-50, -30), Vector2(50, -30), Vector2(0, 0)]:
		Effects.burst(room, position + offset, "poof")
	Effects.float_text(room, position + Vector2(0, -170), "The pot boils over!", Color(0.7, 1, 0.6))
	for i in COINS:
		var coin: Pickup = Entities.create("coin")
		coin.position = position + Vector2.from_angle(i * TAU / COINS) * 110.0
		coin.lifetime = Pickup.DROP_LIFETIME
		room.add_child.call_deferred(coin)
	var game := _game()
	if game != null:
		game.progress.fire(trigger_name)
		game.save_game()
	queue_free()


func _say(text: String) -> void:
	if _tink_cooldown > 0.0:
		return
	_tink_cooldown = 0.5
	Effects.float_text(get_parent(), position + Vector2(0, -190), text, Color.WHITE)


func _enter(new_state: State, seconds: float) -> void:
	if state == State.DIZZY and new_state != State.DIZZY:
		_lid.position = Vector2(0, LID_Y)
	state = new_state
	_timer = seconds


func _game() -> Game:
	return get_tree().get_first_node_in_group("game") as Game
